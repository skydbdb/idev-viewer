import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/const/code.dart';
import 'package:idev_viewer/src/internal/core/api/api_endpoint_ide.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:idev_viewer/src/internal/core/auth/auth_service.dart';
import 'package:idev_viewer/src/internal/core/config/env.dart';
// import 'package:idev_viewer/src/internal/core/auth/auth_service.dart';
import '../../repo/home_repo.dart';
import '../../repo/app_streams.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import '../flutter_stack_board.dart';
import '../stack_board_item.dart';
import '../stack_case.dart';
import '../stack_items.dart';
import 'hierarchical_dock_board_controller.dart';
import 'package:idev_viewer/src/internal/board/helpers/compact_id_generator.dart';
import 'package:flutter/foundation.dart';
import 'package:idev_viewer/src/internal/board/core/item_generator.dart';

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
  AppStreams? appStreams;
  late HierarchicalDockBoardController hierarchicalController;
  String selectedDockBoardId = '';
  bool isCaptured = false;

  late final StreamSubscription _selectDockBoardSub;
  late final StreamSubscription _widgetSub;
  late final StreamSubscription _jsonMenuSub;
  // late final StreamSubscription _apiMenuSub; // 사용하지 않아서 주석 처리
  late final StreamSubscription _apiIdResponseSub;

  @override
  void initState() {
    super.initState();

    homeRepo = context.read<HomeRepo>();
    // 뷰어 모드에서는 AppStreams 사용하지 않음
    if (BuildMode.isEditor) {
      appStreams = sl<AppStreams>();
    } else {}

    // 컨트롤러 생성 또는 재사용
    if (homeRepo.hierarchicalControllers.containsKey(widget.id)) {
      hierarchicalController = homeRepo.hierarchicalControllers[widget.id]!;
      //debugPrint('[DockBoard.initState] reuse controller for ${widget.id}');
    } else {
      hierarchicalController = HierarchicalDockBoardController(
        id: widget.id,
        parentId: null,
        controller: StackBoardController(boardId: widget.id),
      );
      homeRepo.hierarchicalControllers[widget.id] = hierarchicalController;
      //debugPrint('[DockBoard.initState] create controller for ${widget.id}');
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
    _subscribeWidgetMenu();
    _subscribeJsonMenu();
    // _subscribeApiMenu(); // 메서드가 정의되지 않아서 주석 처리
    _subscribeApiIdResponse();
  }

  void _subscribeSelectDockBoard() {
    // 뷰어 모드에서는 구독하지 않음
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }

    _selectDockBoardSub = appStreams!.selectDockBoardStream.listen((v) {
      if (v != null && widget.id == v) {
        setState(() => selectedDockBoardId = v);
      } else {
        setState(() => selectedDockBoardId = '');
      }
    });
  }

  void _subscribeWidgetMenu() {
    // 뷰어 모드에서는 구독하지 않음
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }

    _widgetSub = appStreams!.widgetStream.listen((v) {
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

          homeRepo.addWidgetState(null);
        }
      }
    });
  }

  void _subscribeJsonMenu() {
    _jsonMenuSub = homeRepo.jsonMenuStream.listen((v) async {
      if (v != null) {
        // 템플릿 상세 팝업(template_viewer 보드)이거나 현재 선택된 보드인 경우에만 처리
        // 뷰어 모드에서는 AppStreams가 없으므로 현재 보드 ID를 직접 사용
        String? currentSelectedBoardId =
            BuildMode.isViewer ? widget.id : homeRepo.selectedBoardId;

        // 템플릿 상세 팝업인지 확인
        bool isTemplateViewer = widget.id == 'template_viewer';

        // 미리보기인지 불러오기인지 구분 (versionId로 판단)
        final versionId = v['versionId'];
        bool isPreview =
            versionId == 1; // TemplateViewerPage는 항상 versionId: 1 사용

        // 처리 조건 결정
        bool shouldProcess;
        if (isPreview) {
          // 미리보기: template_viewer 보드에서만 처리
          shouldProcess = isTemplateViewer;
        } else {
          // 불러오기: 현재 선택된 보드에서 처리
          shouldProcess = currentSelectedBoardId == widget.id;
        }

        if (!shouldProcess) {
          return;
        }

        final dynamic rawScript = v['script'];

        // 템플릿 상세 팝업이 아닌 경우에만 템플릿 위젯 선택 상태 확인
        bool hasSelectedTemplate = false;
        //String? selectedTemplateId;

        if (widget.id != 'template_viewer') {
          for (var controller in homeRepo.hierarchicalControllers.values) {
            // 템플릿 상세 팝업 보드는 제외
            if (controller.controller.innerData.isNotEmpty &&
                controller.controller.innerData.first.boardId ==
                    'template_viewer') {
              continue;
            }

            for (var e in controller.controller.innerData) {
              if (e is StackTemplateItem) {
                if (e.status == StackItemStatus.selected) {
                  hasSelectedTemplate = true;
                  break;
                }
              }
            }
            if (hasSelectedTemplate) break;
          }

          // 템플릿 위젯이 선택되어 있으면 보드에서 처리하지 않음
          if (hasSelectedTemplate) {
            return;
          }
        } else {}

        // 템플릿 상세 팝업인지 확인 (template_viewer 보드이거나 템플릿 위젯이 선택되지 않은 상태에서 templateId가 있는 경우)
        final templateId = v['templateId'];
        bool isTemplateViewerForProcessing = widget.id == 'template_viewer' ||
            (templateId != null && !hasSelectedTemplate);

        if (isTemplateViewerForProcessing) {
          await generateFromJson(json: rawScript).then((value) {
            homeRepo.addJsonMenuState(null);
          });
          return;
        }

        // 추가 검증: 현재 보드에 템플릿 아이템이 있는지 확인
        bool hasTemplateItems = hierarchicalController.controller.innerData
            .any((e) => isStackItemType(e, 'StackTemplateItem'));

        if (hasTemplateItems) {
          return;
        }

        // 템플릿 ID 기반 분기: 템플릿 실행이면 보드에서 처리하지 않음
        // 단, 템플릿 상세 팝업(template_viewer 보드)에서는 처리해야 함
        if (templateId != null) {
          if (widget.id == 'template_viewer') {
          } else {
            return;
          }
        }

        // 일반 보드 아이템 생성
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
      // 뷰어 모드에서는 구독이 없을 수 있음
      if (BuildMode.isEditor && appStreams != null) {
        _selectDockBoardSub.cancel();
        _widgetSub.cancel();
      }
      _jsonMenuSub.cancel();
      // _apiMenuSub.cancel(); // _apiMenuSub이 초기화되지 않아서 주석 처리
      _apiIdResponseSub.cancel();
      super.dispose();
      return;
    }

    // Frame 내부 DockBoard의 경우 컨트롤러 제거 방지 (중복 체크)
    if (widget.id.contains('Frame_')) {
      // 뷰어 모드에서는 구독이 없을 수 있음
      if (BuildMode.isEditor && appStreams != null) {
        _selectDockBoardSub.cancel();
        _widgetSub.cancel();
      }
      _jsonMenuSub.cancel();
      // _apiMenuSub.cancel(); // _apiMenuSub이 초기화되지 않아서 주석 처리
      _apiIdResponseSub.cancel();
      super.dispose();
      return;
    }

    // 일반적인 dispose 처리
    // 뷰어 모드에서는 구독이 없을 수 있음
    if (BuildMode.isEditor && appStreams != null) {
      _selectDockBoardSub.cancel();
      _widgetSub.cancel();
    }
    _jsonMenuSub.cancel();
    // _apiMenuSub.cancel(); // _apiMenuSub이 초기화되지 않아서 주석 처리
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

  /// 이미지를 서버로 업로드하는 함수 (가이드 v1.1.0 기준)
  Future<void> _uploadImage(
      Uint8List imageBytes, dynamic templateId, dynamic commitId) async {
    try {
      final url = Uri.parse("${AppConfig.instance.apiHostAws}/idev/v1/upload");

      // 가이드에 따른 MultipartRequest 구성
      final request = http.MultipartRequest("POST", url);

      // 인증/테넌트 헤더 추가
      await AuthService.ensureInitialized();
      final token = AuthService.token;
      final tenantId = AuthService.tenantId;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (tenantId != null && tenantId.isNotEmpty) {
        request.headers['X-Tenant-Id'] = tenantId;
      }

      // 가이드(v1.1.0): templateId, commitId는 FormData 필드로 전송
      request.fields['templateId'] = '$templateId';
      request.fields['commitId'] = '$commitId';

      // 파일 추가 (가이드에 따르면 필드명은 'image'여야 함)
      request.files.add(
        http.MultipartFile.fromBytes(
          'image', // 가이드에 명시된 필드명
          imageBytes,
          filename: '$templateId-$commitId.png',
          contentType: MediaType('image', 'png'),
        ),
      );

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);
      final responseBody = responseData.body;

      if (response.statusCode == 200) {
        try {
          final jsonResponse = jsonDecode(responseBody);

          if (jsonResponse['result'] == '0') {
            final data = jsonResponse['data'];
            final imageUrl = data['result']; // 가이드 v1.1.0: data.result에 서명된 URL

            // 서명된 URL을 사용하여 이미지 표시 (필요시)
            // Image.network(imageUrl);
          } else {
            if (jsonResponse['error'] != null) {
              debugPrint("❌ 오류 상세: ${jsonResponse['error']}");
            }
          }
        } catch (e) {
          debugPrint("❌ JSON 파싱 실패: $e");
        }
      } else {
        debugPrint("❌ HTTP 오류 - Status: ${response.statusCode}");
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
      case 'Scheduler':
        addSchedulerItem(id);
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
        size: const Size(120, 50),
        offset: Offset(hierarchicalController.controller.innerData.length * 20,
            hierarchicalController.controller.innerData.length * 20),
        id: id,
        theme: homeRepo.selectedTheme,
        content: ButtonItemContent(
            buttonName: '실행',
            icon: '',
            url: '',
            buttonType: 'api',
            templateId: 0,
            templateNm: '',
            versionId: homeRepo.versionId,
            script: '',
            apiId: '',
            commitInfo: '',
            apiParameters: ''),
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

  /// Add scheduler item
  void addSchedulerItem(String id) {
    final item = StackSchedulerItem(
        boardId: widget.id,
        id: id,
        size: const Size(400, 400),
        offset: Offset(hierarchicalController.controller.innerData.length * 20,
            hierarchicalController.controller.innerData.length * 20),
        theme: homeRepo.selectedTheme,
        content: const SchedulerItemContent(
          viewType: 'month',
          title: '',
          apiId: '',
          script: '',
          apiParameters: '',
          schedules: [
            // ScheduleData(
            //   id: '1',
            //   title: '팀 미팅',
            //   date: DateTime.now(),
            //   startTime: '09:00:00',
            //   endTime: '10:00:00',
            //   description: '주간 팀 미팅',
            //   color: Colors.blue,
            //   status: '확정',
            //   userId: 'user1',
            // ),
            // ScheduleData(
            //   id: '2',
            //   title: '프로젝트 리뷰',
            //   date: DateTime.now().add(const Duration(days: 1)),
            //   startTime: '14:00:00',
            //   endTime: '15:30:00',
            //   description: '프로젝트 진행 상황 리뷰',
            //   color: Colors.green,
            //   status: '예정',
            //   userId: 'user1',
            // )
          ],
          postApiId: '',
          putApiId: '',
          deleteApiId: '',
        ));
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
            mode: 'normal',
            headerTitle: '그리드 제목',
            apiId: '',
            postApiId: '',
            putApiId: '',
            deleteApiId: '',
            reqApis: [],
            resApis: []));
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
        size: const Size(800, 700),
        // size: Size(MediaQuery.of(context).size.width,
        //     MediaQuery.of(context).size.height - 90),
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
          bodyRatio: 1,
          reqMenus: [],
          selectedIndex: 0,
        )));
  }

  /// Generate From Json
  Future<void> generateFromJson({String? json}) async {
    if (json == null || json.isEmpty) {
      return;
    }

    try {
      await BoardItemGenerator.generateFromJson(
        json: json,
        boardId: widget.id,
        controller: hierarchicalController,
        hierarchicalControllers: homeRepo.hierarchicalControllers,
        lockItems: false, // 템플릿의 경우 항상 잠금
      );
    } catch (e) {}
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
                } else if (item is StackSchedulerItem) {
                  return StackSchedulerCase(item: item);
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
