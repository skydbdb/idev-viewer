import 'dart:convert';
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/const/code.dart';
import 'package:idev_v1/src/core/api/api_endpoint_ide.dart';
import '/src/di/service_locator.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // MediaType을 위한 import 추가
import '../../../src/core/config/env.dart';
import '../../repo/home_repo.dart';
import '../../repo/app_streams.dart';
import '../flutter_stack_board.dart';
import '../stack_board_item.dart';
import '../stack_case.dart';
import '../stack_items.dart';
import 'hierarchical_dock_board_controller.dart';
import '../helpers/compact_id_generator.dart';
import 'package:flutter/foundation.dart';

// 파일 최상단에 선언
class FrameTabMapping {
  final String frameId;
  final Map<String, String> tabIndexToBoardId = {};
  final Map<String, String> boardIdToTabIndex = {};

  FrameTabMapping(this.frameId);

  void addMapping(int tabIndex, String boardId) {
    tabIndexToBoardId[tabIndex.toString()] = boardId;
    boardIdToTabIndex[boardId] = tabIndex.toString();
  }

  String? getBoardId(int tabIndex) => tabIndexToBoardId[tabIndex.toString()];
  String? getTabIndex(String boardId) => boardIdToTabIndex[boardId];
}

class EditItemController {
  late void Function(String menu) onMenu;
}

// ignore: must_be_immutable
class DockBoard extends StatefulWidget {
  DockBoard({
    super.key,
    required this.id,
    this.parentId,
    this.focusNode,
  });

  String id;
  String? parentId;
  FocusNode? focusNode;

  @override
  State<DockBoard> createState() => _DockBoardState();
}

class _DockBoardState extends State<DockBoard> {
  final GlobalKey _globalKey = GlobalKey();
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  late HierarchicalDockBoardController hierarchicalController;
  String selectedDockBoardId = '';
  bool isCaptured = false;

  late final StreamSubscription _selectDockBoardSub;
  late final StreamSubscription _rightMenuSub;
  late final StreamSubscription _jsonMenuSub;
  late final StreamSubscription _apiMenuSub;
  late final StreamSubscription _apiIdResponseSub;

  @override
  void initState() {
    super.initState();

    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();

    // 키/보드 생성 추적 로그
    debugPrint(
        '[DockBoard.initState] id=${widget.id}, parentId=${widget.parentId}, key=${widget.key}');

    // 컨트롤러 생성 또는 재사용
    if (homeRepo.hierarchicalControllers.containsKey(widget.id)) {
      hierarchicalController = homeRepo.hierarchicalControllers[widget.id]!;
      debugPrint('[DockBoard.initState] reuse controller for ${widget.id}');
    } else {
      hierarchicalController = HierarchicalDockBoardController(
        id: widget.id,
        parentId: null,
        controller: StackBoardController(boardId: widget.id),
      );
      homeRepo.hierarchicalControllers[widget.id] = hierarchicalController;
      debugPrint('[DockBoard.initState] create controller for ${widget.id}');
    }
    _initializeHierarchicalController();
    _subscribeStreams();
  }

  void _initializeHierarchicalController() {
    // 중복 생성 방지
    if (homeRepo.hierarchicalControllers.containsKey(widget.id)) {
      hierarchicalController = homeRepo.hierarchicalControllers[widget.id]!;
      return;
    }

    // 새로운 계층 구조 관리 메서드 사용
    final success = homeRepo.createHierarchicalController(
      widget.id,
      widget.parentId,
    );
    if (success) {
      hierarchicalController = homeRepo.hierarchicalControllers[widget.id]!;
    } else {
      // 실패 시 기본 컨트롤러 생성 (호환성 유지)
      hierarchicalController = HierarchicalDockBoardController(
        id: widget.id,
        parentId: widget.parentId,
        controller: StackBoardController(
          boardId: widget.id,
        ),
      );
      homeRepo.hierarchicalControllers[widget.id] = hierarchicalController;
    }
  }

  void _subscribeStreams() {
    _subscribeSelectDockBoard();
    _subscribeRightMenu();
    _subscribeJsonMenu();
    // _subscribeApiMenu();
    _subscribeApiIdResponse();
  }

  void _subscribeSelectDockBoard() {
    _selectDockBoardSub = appStreams.selectDockBoardStream.listen((v) {
      if (v != null && widget.id == v) {
        setState(() => selectedDockBoardId = v);
      } else {
        setState(() => selectedDockBoardId = '');
      }
    });
  }

  void _subscribeRightMenu() {
    _rightMenuSub = appStreams.rightMenuStream.listen((v) {
      if (v != null) {
        final menu = v.split('#');
        final boardId = menu.first;
        final itemId = CompactIdGenerator.generateItemId(menu.last);

        final item = homeRepo.hierarchicalControllers[boardId]?.getById(itemId);
        if (item == null && boardId == widget.id) {
          if ((boardId.contains('Frame_') && menu.last == 'Frame') ||
              (boardId.contains('body_') || boardId.contains('subBody_')) &&
                  menu.last == 'Layout') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '${menu.last} 내부에는 ${menu.last} 위젯을 중복 생성할 수 없습니다.')),
            );
            return;
          }

          createStackItem(menu.last, itemId).then((value) {
            if (hierarchicalController.controller.innerData.isNotEmpty) {
              final lastItem = hierarchicalController.controller.innerData.last;
              homeRepo.addOnTapState(lastItem);
            }
          });

          homeRepo.addRightMenuState(null);
        }
      }
    });
  }

  void _subscribeJsonMenu() {
    _jsonMenuSub = appStreams.jsonMenuStream.listen((v) async {
      if (v != null && homeRepo.selectedBoardId == widget.id) {
        final dynamic rawScript = v['script'];

        for (var e in hierarchicalController.controller.innerData) {
          if (isStackItemType(e, 'StackTemplateItem') &&
              e.status == StackItemStatus.selected) {
            return;
          }
        }
        await generateFromJson(json: rawScript).then((value) {
          homeRepo.addJsonMenuState(null);
        });
      }
    });
  }

  void _subscribeApiIdResponse() {
    _apiIdResponseSub = homeRepo.getApiIdResponseStream.listen((v) async {
      if (v != null) {
        await _handleApiIdResponse(v);
      }
    });
  }

  Future<void> _handleApiIdResponse(Map<String, dynamic> v) async {
    if (!(ApiEndpointIDE.templateCommits.contains(v['if_id']) &&
        v['method'] == 'post')) {
      return;
    }

    if (homeRepo.currentTab == null || homeRepo.currentTab != widget.id) {
      return;
    }
    final apiId = v['if_id'];
    final result = homeRepo.onApiResponse[apiId]?['data']['result'];

    if (result['templateId'] != null && result['commitId'] != null) {
      Uint8List? imageBytes = await _captureWidgetToImage();
      if (imageBytes != null) {
        Future.delayed(const Duration(milliseconds: 500)).then((value) async {
          await _uploadImage(
              imageBytes, result['templateId'], result['commitId']);
        });
      }
    }
  }

  @override
  void dispose() {
    // Layout 내부 DockBoard의 경우 dispose 방지
    if (widget.id.contains('body_') || widget.id.contains('subBody_')) {
      // 스트림 구독만 취소하고 컨트롤러는 유지
      _selectDockBoardSub.cancel();
      _rightMenuSub.cancel();
      _jsonMenuSub.cancel();
      _apiMenuSub.cancel();
      _apiIdResponseSub.cancel();
      super.dispose();
      return;
    }

    // Frame 내부 DockBoard의 경우 컨트롤러 제거 방지 (중복 체크)
    if (widget.id.contains('Frame_')) {
      _selectDockBoardSub.cancel();
      _rightMenuSub.cancel();
      _jsonMenuSub.cancel();
      _apiMenuSub.cancel();
      _apiIdResponseSub.cancel();
      super.dispose();
      return;
    }

    // 일반적인 dispose 처리
    _selectDockBoardSub.cancel();
    _rightMenuSub.cancel();
    _jsonMenuSub.cancel();
    _apiMenuSub.cancel();
    _apiIdResponseSub.cancel();

    // 컨트롤러가 존재하는 경우에만 dispose
    if (homeRepo.hierarchicalControllers.containsKey(widget.id)) {
      homeRepo.disposeHierarchicalController(widget.id);
    }

    super.dispose();
  }

  String generateItemId(String itemType) {
    return CompactIdGenerator.generateItemId(itemType);
  }

  /// 위젯을 이미지로 변환하는 함수
  Future<Uint8List?> _captureWidgetToImage() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;

      setState(() {
        isCaptured = true;
        hierarchicalController.controller.unSelectAll();
      });
      await Future.delayed(const Duration(milliseconds: 100));

      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      setState(() => isCaptured = false);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing widget: $e");
      return null;
    }
  }

  String getFileExtension(String filePath) {
    final fileName = filePath.split('/').last;
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }

  /// 이미지를 서버로 업로드하는 함수
  Future<void> _uploadImage(
      Uint8List imageBytes, dynamic templateId, dynamic commitId) async {
    try {
      final url = Uri.parse("${AppConfig.instance.apiHostAws}/upload");
      final request = http.MultipartRequest("POST", url)
        ..headers.addAll({'templateId': '$templateId', 'commitId': '$commitId'})
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: '$templateId-$commitId.png', // ✅ 파일명 고정 유지
            contentType: MediaType('image', 'png'), // ✅ PNG로 고정
          ),
        );

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        debugPrint("📄 오류 응답: ${responseData.body}");
      } else {
        debugPrint("❌ 업로드 예외 발생");
      }
    } catch (e) {
      debugPrint("❌ 업로드 예외 발생: $e");
    }
  }

  /// Dock intercept
  Future<void> _onDock(StackItem<StackItemContent> item) async {
    final it = item.copyWith(
      dock: true,
    );

    hierarchicalController.controller.updateItem(it);
  }

  EditItemController editItemController = EditItemController();

  /// Menu intercept, When Edit mode
  Future<void> _onMenu(String menu) async {
    editItemController.onMenu(menu);
  }

  /// Widget Menu
  Future<void> createStackItem(String itemType, String id) async {
    switch (itemType) {
      case 'Text':
        addTextItem(id);
      case 'Image':
        addImageItem(id);
      case 'Search':
        addSearchItem(id);
      case 'Button':
        addButtonItem(id);
      case 'Template':
        addTemplateItem(id);
      case 'Detail':
        addDetailItem(id);
      case 'Chart':
        addChartItem(id);
      case 'Grid':
        addGridItem(id);
      case 'Frame':
        addDockItem(id);
      case 'Layout':
        addLayoutItem(id);
    }
  }

  /// Add text item
  void addTextItem(String id) {
    final item = StackTextItem(
      boardId: widget.id,
      id: id,
      size: const Size(120, 50),
      offset: Offset(hierarchicalController.controller.innerData.length * 20,
          hierarchicalController.controller.innerData.length * 20),
      theme: homeRepo.selectedTheme,
      content: const TextItemContent(data: 'Text'),
    );
    hierarchicalController.controller.addItem(item);
  }

  /// Add search item
  void addSearchItem(String id) {
    final item = StackSearchItem(
        boardId: widget.id,
        id: id,
        size: const Size(200, 50),
        offset: Offset(hierarchicalController.controller.innerData.length * 20,
            hierarchicalController.controller.innerData.length * 20),
        permission: 'all',
        theme: homeRepo.selectedTheme,
        content: SearchItemContent(buttonName: '조회', reqApis: const []),
        status: StackItemStatus.selected);
    hierarchicalController.controller.addItem(item);
  }

  /// Add button item
  void addButtonItem(String id) {
    hierarchicalController.controller.addItem(
      StackButtonItem(
        boardId: widget.id,
        size: const Size(100, 40),
        offset: Offset(hierarchicalController.controller.innerData.length * 20,
            hierarchicalController.controller.innerData.length * 20),
        id: id,
        theme: homeRepo.selectedTheme,
        content: ButtonItemContent(
            buttonName: '실행',
            url: 'https://naver.com',
            buttonType: 'url',
            templateId: 0,
            templateNm: '',
            versionId: homeRepo.versionId,
            script: 'test',
            apiId: '',
            commitInfo: ''),
      ),
    );
  }

  /// Add template item
  void addTemplateItem(String id) {
    hierarchicalController.controller.addItem(StackTemplateItem(
        boardId: widget.id,
        id: id,
        size: const Size(400, 300),
        offset: Offset(hierarchicalController.controller.innerData.length * 20,
            hierarchicalController.controller.innerData.length * 20),
        theme: homeRepo.selectedTheme,
        content: const TemplateItemContent(
            templateId: null,
            templateNm: '',
            versionId: null,
            script: '',
            commitInfo: '',
            sizeOption: 'Scroll')));
  }

  /// Add Detail item
  void addDetailItem(String id) {
    final item = StackDetailItem(
        boardId: widget.id,
        id: id,
        size: const Size(400, 300),
        offset: Offset(hierarchicalController.controller.innerData.length * 20,
            hierarchicalController.controller.innerData.length * 20),
        permission: 'all',
        theme: homeRepo.selectedTheme,
        content: const DetailItemContent(
            columnGap: 1,
            rowGap: 1,
            areas: '',
            columnSizes: '[1,1,1]',
            rowSizes: '[1,1,1]',
            reqApis: [],
            resApis: []),
        status: StackItemStatus.selected);
    hierarchicalController.controller.addItem(item);
  }

  /// Add Chart item
  void addChartItem(String id) {
    final item = StackChartItem(
        boardId: widget.id,
        id: id,
        size: const Size(400, 400),
        offset: Offset(hierarchicalController.controller.innerData.length * 20,
            hierarchicalController.controller.innerData.length * 20),
        theme: homeRepo.selectedTheme,
        content: const ChartItemContent(
          chartType: 'column',
          dataSource: [
            {'name': '이름A', 'age': 30},
            {'name': '이름B', 'age': 25},
            {'name': '이름C', 'age': 45},
          ],
          xValueMapper: 'name',
          yValueMapper: [],
          title: '차트 제목',
          showLegend: false,
          showTooltip: true,
          enableZoom: true,
          enablePan: true,
          showDataLabels: false,
          primaryXAxisType: 'category',
          primaryYAxisType: 'category',
          xAxisLabelFormat: 'default',
          yAxisLabelFormat: 'default',
        ),
        status: StackItemStatus.selected);
    hierarchicalController.controller.addItem(item);
  }

  /// Add image item
  void addImageItem(String id) {
    final item = StackImageItem(
      boardId: widget.id,
      id: id,
      size: const Size(200, 50),
      offset: Offset(hierarchicalController.controller.innerData.length * 20,
          hierarchicalController.controller.innerData.length * 20),
      theme: homeRepo.selectedTheme,
      content: const ImageItemContent(
        url: '',
        // 'https://files.flutter-io.cn/images/branding/flutterlogo/flutter-cn-logo.png',
        assetName: 'assets/images/idev.jpeg',
        fit: BoxFit.scaleDown,
        repeat: ImageRepeat.repeat,
        color: 'transparent',
        colorBlendMode: BlendMode.color,
      ),
    );
    hierarchicalController.controller.addItem(item);
  }

  /// Add Grid item
  void addGridItem(String id) {
    final item = StackGridItem(
        boardId: widget.id,
        id: id,
        size: const Size(800, 500),
        offset: Offset(hierarchicalController.controller.innerData.length * 20,
            hierarchicalController.controller.innerData.length * 20),
        padding: EdgeInsets.zero,
        status: StackItemStatus.selected,
        lockZOrder: false,
        dock: false,
        permission: 'read',
        theme: homeRepo.selectedTheme,
        content: const GridItemContent(
            mode: 'normal', headerTitle: '그리드 제목', apiId: ''));
    hierarchicalController.controller.addItem(item);
  }

  /// Add Dock item
  void addDockItem(String id) {
    // Frame 아이템 생성
    hierarchicalController.controller.addItem(StackFrameItem(
        boardId: widget.id,
        id: id,
        theme: homeRepo.selectedTheme,
        content: const FrameItemContent(
            tabsVisible: true,
            dividerThickness: 6,
            tabsTitle: '',
            lastStringify: ''),
        size: const Size(800, 500)));
  }

  void addSideMenuItem(String id) {
    hierarchicalController.controller.addItem(StackSideMenuItem(
        boardId: widget.id,
        id: id,
        dock: false,
        size: const Size(800, 500),
        content: const SideMenuItemContent()));
  }

  /// Add Layout item
  void addLayoutItem(String id) {
    hierarchicalController.controller.addItem(StackLayoutItem(
        boardId: widget.id,
        id: id,
        dock: false,
        size: const Size(900, 600),
        theme: homeRepo.selectedTheme,
        content: const LayoutItemContent(
          directionLtr: true,
          title: '레이아웃 제목',
          profile: 'IDEV 시스템',
          appBar: 'smallAndUp',
          actions: 'none',
          drawer: 'smallAndUp',
          subBody: 'mediumAndUp',
          topNavigation: 'none',
          leftNavigation: 'smallAndUp',
          rightNavigation: 'none',
          bottomNavigation: 'none',
          bodyOrientation: Axis.horizontal,
          subBodyOptions: 'detail',
          bodyRatio: 0.5,
          reqMenus: [],
          selectedIndex: 0,
        )));
  }

  /// Generate From Json
  Future<void> generateFromJson({String? json}) async {
    if (json == null || json.trim().isEmpty) {
      debugPrint('[DockBoard.generateFromJson][ERROR] 빈 스크립트');
      return;
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(json);
    } catch (e) {
      debugPrint('[DockBoard.generateFromJson][ERROR] JSON 파싱 실패: $e');
      return;
    }

    // 래핑된 포맷 지원: { items: [...] }
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('items') && decoded['items'] is List) {
        decoded = decoded['items'];
      } else {
        debugPrint(
            '[DockBoard.generateFromJson][ERROR] 예상치 못한 객체 포맷: keys=${decoded.keys}');
        return;
      }
    }

    if (decoded is! List) {
      debugPrint(
          '[DockBoard.generateFromJson][ERROR] List 포맷이 아님: type=${decoded.runtimeType}');
      return;
    }

    final List<dynamic> allItems = decoded;

    // minified 포맷 탐지
    final hasMinified = allItems.any((e) {
      try {
        if (e is Map) {
          final t = e['type']?.toString() ?? '';
          return t.startsWith('minified:');
        }
      } catch (_) {}
      return false;
    });
    if (hasMinified) {
      debugPrint(
          '[DockBoard.generateFromJson][ERROR] minified 포맷 감지 - 디코더 필요. 처리 중단');
      return;
    }

    // boardId를 현재 보드 ID로 대체
    final processedItems = allItems.map((item) {
      final processedItem = Map<String, dynamic>.from(item);
      if (processedItem['boardId'] == '#TEMPLATE#') {
        processedItem['boardId'] = widget.id;
      }
      return processedItem;
    }).toList();

    // 중복 제거 (동일한 ID의 아이템이 여러 번 있는 경우)
    final uniqueItems = <Map<String, dynamic>>[];
    final seenIds = <String>{};
    for (final item in processedItems) {
      final itemId = item['id'];
      if (!seenIds.contains(itemId)) {
        seenIds.add(itemId);
        uniqueItems.add(item);
      }
    }

    // Frame 아이템을 먼저 처리하기 위해 정렬
    final sortedItems = <Map<String, dynamic>>[];
    final layoutItems =
        uniqueItems.where((item) => item['type'] == 'StackLayoutItem').toList();
    final frameItems =
        uniqueItems.where((item) => item['type'] == 'StackFrameItem').toList();
    final nonFrameItems = uniqueItems
        .where((item) =>
            (item['type'] != 'StackFrameItem') &&
            (item['type'] != 'StackLayoutItem'))
        .toList();

    sortedItems.addAll(layoutItems);
    sortedItems.addAll(frameItems);
    sortedItems.addAll(nonFrameItems);

    // 아이템 생성
    for (final item in sortedItems) {
      if (item['type'] == null) {
        debugPrint('[DockBoard.generateFromJson][WARN] type 누락 항목 건너뜀: $item');
        continue;
      }
      final itemType = item['type'].toString();
      if (!itemType.startsWith('Stack') || !itemType.endsWith('Item')) {
        debugPrint(
            '[DockBoard.generateFromJson][WARN] 알 수 없는 type "$itemType" 항목 건너뜀');
        continue;
      }

      final boardId = item['boardId'];
      final itemId = item['id'];
      await _generateSingleItem(boardId, itemId, itemType, item);
    }
  }

  /// 단일 아이템 생성 - JSON 복원 시에는 하위 보드만 신규로 생성
  Future<void> _generateSingleItem(
      String boardId, String itemId, String itemType, dynamic item) async {
    // 컨트롤러 생성 또는 재사용
    HierarchicalDockBoardController controller;
    if (homeRepo.hierarchicalControllers.containsKey(boardId)) {
      controller = homeRepo.hierarchicalControllers[boardId]!;

      // Frame 탭 컨트롤러의 경우 기존 아이템 확인
      if (boardId.startsWith('Frame_') &&
          boardId.contains('_') &&
          boardId.split('_').length > 2) {
        final parts = boardId.split('_');
        final tabIndex = parts.last;
        if (RegExp(r'^\d+$').hasMatch(tabIndex)) {
          // Frame 탭 컨트롤러의 경우 기존 아이템이 있으면 건너뛰기
          final existingItems = controller.controller.innerData
              .where((item) => isStackItemType(item, itemType))
              .toList();
          if (existingItems.isNotEmpty) {
            return;
          }
        }
      }
    } else {
      controller = HierarchicalDockBoardController(
        id: boardId,
        parentId: _getParentBoardId(boardId),
        controller: StackBoardController(boardId: boardId),
      );
      homeRepo.hierarchicalControllers[boardId] = controller;
    }

    // 기존 아이템 확인
    final existingItem =
        controller.controller.innerData.firstWhereOrNull((e) => e.id == itemId);
    if (existingItem != null) {
      return;
    }

    // 아이템 생성
    await _createItemByType(item, controller, boardId, itemId);

    // Layout 아이템이 생성된 경우, 해당 아이템의 ID로 컨트롤러도 생성
    if (itemType == 'StackLayoutItem') {
      final layoutControllerId = itemId; // Layout 아이템의 ID

      // 기존 Layout 컨트롤러가 있는지 확인
      if (!homeRepo.hierarchicalControllers.containsKey(layoutControllerId)) {
        final layoutController = HierarchicalDockBoardController(
          id: layoutControllerId,
          parentId: homeRepo.selectedBoardId,
          controller: StackBoardController(
            boardId: layoutControllerId,
          ),
        );
        homeRepo.hierarchicalControllers[layoutControllerId] = layoutController;

        // 최상위 보드의 자식으로 설정
        final rootController =
            homeRepo.hierarchicalControllers[homeRepo.selectedBoardId!];
        if (rootController != null) {
          rootController.addChild(layoutController);
          homeRepo.addChildController(
              homeRepo.selectedBoardId!, layoutControllerId);
        }
      }
    }

    // Frame 컨트롤러가 이미 존재하는지 확인
    if (itemType == 'StackFrameItem') {
      final frameControllerId = itemId;
      if (homeRepo.hierarchicalControllers.containsKey(frameControllerId)) {
        // 기존 Frame 컨트롤러 재사용
      } else {
        final frameController = HierarchicalDockBoardController(
          id: frameControllerId,
          parentId: boardId,
          controller: StackBoardController(boardId: frameControllerId),
        );
        homeRepo.hierarchicalControllers[frameControllerId] = frameController;

        // Frame의 부모-자식 관계 설정
        final parentController = homeRepo.hierarchicalControllers[boardId];
        if (parentController != null) {
          final isChildAlready =
              parentController.children.contains(frameController);
          if (!isChildAlready) {
            parentController.addChild(frameController);
            homeRepo.addChildController(boardId, frameControllerId);
          }
        }
      }
    }
  }

  /// boardId에서 부모 보드 ID 추출 - 새로운 ID 시스템만 사용 (개선된 버전)
  String? _getParentBoardId(String boardId) {
    // 최상위 보드인 경우 null 반환 (자체 참조 방지)
    if (boardId == homeRepo.selectedBoardId) {
      return null;
    }

    // CompactIdGenerator 매핑에서 찾기
    final parentInfo = CompactIdGenerator.getParentInfo(boardId);
    if (parentInfo != null) {
      final parentId = parentInfo.split(':')[0];
      return parentId;
    }

    // Frame_ 보드인 경우 Frame 찾기
    if (boardId.startsWith('Frame_')) {
      // HomeRepo의 frameTabOrders에서 해당 Frame_ 보드가 속한 Frame 찾기
      for (final frameEntry in homeRepo.frameTabOrders.entries) {
        final frameId = frameEntry.key;
        final tabOrderMap = frameEntry.value;

        if (tabOrderMap.containsKey(boardId)) {
          return frameId;
        }
      }
      return 'new_1';
    }

    // 기존 로직
    final parts = boardId.split('_');
    if (parts.length >= 2) {
      final parentId = parts.sublist(0, parts.length - 1).join('_');
      return parentId;
    }

    return null;
  }

  /// 아이템 타입에 따라 적절한 아이템 생성
  Future<void> _createItemByType(
      dynamic item,
      HierarchicalDockBoardController hierarchicalController,
      String boardId,
      String itemId) async {
    // 최종 중복 확인
    final finalCheck = hierarchicalController.controller.innerData
        .firstWhereOrNull((e) => e.id == itemId);
    if (finalCheck != null) {
      return;
    }

    try {
      // item을 Map<String, dynamic>으로 변환
      final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);

      switch (itemMap['type']) {
        case 'StackTextItem':
          hierarchicalController.controller.addItem(
            StackTextItem.fromJson(itemMap).copyWith(
                boardId: boardId, id: itemId, status: StackItemStatus.idle),
          );
          break;
        case 'StackImageItem':
          hierarchicalController.controller.addItem(
            StackImageItem.fromJson(itemMap).copyWith(
                boardId: boardId, id: itemId, status: StackItemStatus.idle),
          );
          break;
        case 'StackGridItem':
          hierarchicalController.controller.addItem(
            StackGridItem.fromJson(itemMap).copyWith(
                boardId: boardId, id: itemId, status: StackItemStatus.idle),
          );
          break;
        case 'StackFrameItem':
          hierarchicalController.controller.addItem(
            StackFrameItem.fromJson(itemMap).copyWith(
                boardId: boardId, id: itemId, status: StackItemStatus.idle),
          );
          break;
        case 'StackLayoutItem':
          hierarchicalController.controller.addItem(
            StackLayoutItem.fromJson(itemMap).copyWith(
                boardId: boardId, id: itemId, status: StackItemStatus.idle),
          );
          break;
        case 'StackSearchItem':
          hierarchicalController.controller.addItem(
            StackSearchItem.fromJson(itemMap).copyWith(
                boardId: boardId, id: itemId, status: StackItemStatus.idle),
          );
          break;
        case 'StackButtonItem':
          hierarchicalController.controller.addItem(
            StackButtonItem.fromJson(itemMap).copyWith(
                boardId: boardId, id: itemId, status: StackItemStatus.idle),
          );
          break;
        case 'StackDetailItem':
          hierarchicalController.controller.addItem(
            StackDetailItem.fromJson(itemMap).copyWith(
                boardId: boardId, id: itemId, status: StackItemStatus.idle),
          );
          break;
        case 'StackChartItem':
          hierarchicalController.controller.addItem(
            StackChartItem.fromJson(itemMap).copyWith(
                boardId: boardId, id: itemId, status: StackItemStatus.idle),
          );
          break;
        case 'StackTemplateItem':
          hierarchicalController.controller.addItem(
            StackTemplateItem.fromJson(itemMap).copyWith(
                boardId: boardId, id: itemId, status: StackItemStatus.idle),
          );
          break;
        default:
          debugPrint('[ERROR] Unknown item type: ${itemMap['type']}');
          return;
      }
    } catch (e) {
      debugPrint('[ERROR] Failed to create item: $itemId - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 컨트롤러가 유효한지 확인
    try {
      // 컨트롤러의 상태를 확인하기 위해 간단한 접근 시도
      final _ = hierarchicalController.controller.innerData;
    } catch (e) {
      return const Center(child: CircularProgressIndicator());
    }

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        if (focused) {
          // Layout/Frame 내부 DockBoard는 focus 이벤트 완전 차단
          if (widget.id.contains('body_') ||
              widget.id.contains('subBody_') ||
              widget.id.contains('Frame_')) {
            return;
          }

          // 이미 선택된 boardId와 같으면 emit하지 않음
          if (homeRepo.selectedBoardId != widget.id) {
            homeRepo.selectDockBoardState(widget.id);
            homeRepo.changeTabState(widget.id);
          }
        }
      },
      child: RepaintBoundary(
          key: _globalKey,
          child: Theme(
            data: ThemeData.light(),
            child: StackBoard(
              id: widget.id,
              onMenu: _onMenu,
              onDock: _onDock,
              // onDel: _onDel,
              controller: hierarchicalController.controller,
              caseStyle: const CaseStyle(
                buttonBorderColor: Colors.grey,
                buttonIconColor: Colors.grey,
              ),
              background: isCaptured
                  ? const ColoredBox(
                      color: Colors.transparent,
                    )
                  : ColoredBox(
                      key: ValueKey(ThemeData.light().dialogBackgroundColor),
                      color: selectedDockBoardId == widget.id
                          ? ThemeData.light().colorScheme.secondaryContainer
                          : ThemeData.light().colorScheme.surface,
                    ),
              customBuilder: (StackItem<StackItemContent> item) {
                // 각 아이템 렌더링 시 추적 로그 (필요 시 주석 해제)
                // debugPrint('[DockBoard.builder] boardId=${widget.id}, item=${item.runtimeType}, id=${item.id}');
                if (item is StackTextItem) {
                  return StackTextCase(item: item);
                } else if (item is StackImageItem) {
                  return StackImageCase(item: item);
                } else if (item is StackSearchItem) {
                  return StackSearchCase(
                    item: item,
                  );
                } else if (item is StackButtonItem) {
                  return StackButtonCase(item: item);
                } else if (item is StackDetailItem) {
                  return StackDetailCase(
                      item: item, editItemController: editItemController);
                } else if (item is StackChartItem) {
                  return StackChartCase(item: item);
                } else if (item is StackGridItem) {
                  return StackGridCase(item: item);
                } else if (item is StackFrameItem) {
                  return StackFrameCase(item: item);
                } else if (item is StackTemplateItem) {
                  return StackTemplateCase(item: item);
                } else if (item is StackLayoutItem) {
                  return StackLayoutCase(item: item);
                }
                return const SizedBox.shrink();
              },
            ),
          )),
    );
  }
}
