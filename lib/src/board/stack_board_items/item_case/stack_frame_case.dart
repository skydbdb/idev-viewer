import 'dart:async';
import 'dart:convert';

import 'package:docking/docking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/board/stack_board_item.dart';
import '/src/di/service_locator.dart';
import '/src/board/board/dock_board.dart';
import '/src/repo/home_repo.dart';
import '/src/board/stack_items.dart';
import '/src/repo/app_streams.dart';
import '/src/board/helpers/compact_id_generator.dart';
import '/src/board/board/hierarchical_dock_board_controller.dart';
import '/src/board/flutter_stack_board.dart';

// 커스텀 DividerPainter 정의 (더 정교한 마우스 이벤트 감지)
class MyDividerPainter extends DividerPainter {
  MyDividerPainter({required this.onDividerPainted});
  final VoidCallback onDividerPainted;

  // ★ 인스턴스별 타이머 관리 (정적 변수 제거)
  Timer? _debounceTimer;

  // ★ 분리바 방향 및 위치 추적
  Axis? _lastDividerAxis;
  Size? _lastDividerSize;

  // ★ 분리바별 독립적인 상태 관리
  final Map<String, bool> _dividerStates = {};
  final Map<String, DateTime> _dividerInteractionTimes = {};

  @override
  void paint({
    required Map<int, dynamic> animatedValues,
    required Canvas canvas,
    required Axis dividerAxis,
    required Size dividerSize,
    required bool highlighted,
    required bool resizable,
  }) {
    super.paint(
      animatedValues: animatedValues,
      canvas: canvas,
      dividerAxis: dividerAxis,
      dividerSize: dividerSize,
      highlighted: highlighted,
      resizable: resizable,
    );

    final now = DateTime.now();
    bool isMouseInteraction = false;

    // ★ 분리바 고유 식별자 생성 (방향 + 크기 + 위치 기반)
    // animatedValues에서 분리바의 위치 정보 추출 시도
    String positionInfo = '';
    try {
      if (animatedValues.isNotEmpty) {
        // animatedValues에서 위치 관련 정보 추출
        final values = animatedValues.values.toList();
        if (values.isNotEmpty) {
          positionInfo = '_${values.first.toString().hashCode}';
        }
      }
    } catch (e) {
      // 위치 정보 추출 실패 시 무시
    }

    final dividerKey =
        '${dividerAxis.name}_${dividerSize.width.round()}_${dividerSize.height.round()}$positionInfo';

    // ★ 분리바별 독립적인 상태 관리
    final wasHighlighted = _dividerStates['${dividerKey}_highlighted'] ?? false;
    final wasResizable = _dividerStates['${dividerKey}_resizable'] ?? false;
    final lastInteractionTime = _dividerInteractionTimes[dividerKey];

    // ★ 분리바 방향 변화 감지
    final isAxisChanged = _lastDividerAxis != dividerAxis;
    final isSizeChanged = _lastDividerSize != dividerSize;

    if (isAxisChanged || isSizeChanged) {
      _lastDividerAxis = dividerAxis;
      _lastDividerSize = dividerSize;
    }

    // ★ 실제 마우스 상호작용 감지 (개선된 로직)
    if (lastInteractionTime != null) {
      final timeDiff = now.difference(lastInteractionTime).inMilliseconds;

      // 1. 드래그 종료 감지 (resizable: true → false)
      if (wasResizable && !resizable && timeDiff > 20) {
        isMouseInteraction = true;
      }

      // 2. 마우스 클릭 감지 (highlighted: false → true → false)
      if (!wasHighlighted && highlighted && timeDiff > 20) {
        isMouseInteraction = true;
      }

      // 3. ★ 새로운 조건: 드래그 중 상태 변화 감지
      if (wasResizable != resizable && timeDiff > 5) {
        isMouseInteraction = true;
      }

      // 4. ★ 새로운 조건: 지속적인 드래그 감지
      if (resizable && wasResizable && timeDiff > 100) {
        isMouseInteraction = true;
      }
    }

    // ★ 분리바별 상태 업데이트
    _dividerStates['${dividerKey}_highlighted'] = highlighted;
    _dividerStates['${dividerKey}_resizable'] = resizable;
    _dividerInteractionTimes[dividerKey] = now;

    // ★ 마우스 상호작용이 있을 때만 콜백 호출 (개선된 디바운싱)
    if (isMouseInteraction) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 100), () {
        onDividerPainted();
      });
    }
  }

  // ★ 리소스 정리 메서드 추가
  void dispose() {
    _debounceTimer?.cancel();
    _dividerStates.clear();
    _dividerInteractionTimes.clear();
  }
}

/// * Draw object
class StackFrameCase extends StatefulWidget {
  const StackFrameCase({super.key, required this.item});

  /// * StackFrameItem
  final StackFrameItem item;

  @override
  State<StackFrameCase> createState() => _StackFrameCaseState();
}

class _StackFrameCaseState extends State<StackFrameCase>
    with LayoutParserMixin, AreaBuilderMixin {
  late DockingLayout layout;
  late Docking docking;
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  late Map<String, double> weights;
  late List<String> boardIds;
  late TabbedViewThemeData tabbedViewThemeData;
  bool tabsVisible = true;
  double dividerThickness = 6;
  String prevLastStringify = '';
  List<dynamic> prevTabsTitle = [];
  List<String> prevBoardIds = [];
  Map<String, double> prevWeights = {};
  late StackFrameItem currentItem;
  late StreamSubscription _updateStackItemSub;
  late StreamSubscription _selectDockBoardSub;

  // ★ MyDividerPainter 인스턴스 관리
  MyDividerPainter? _dividerPainter;

  // ★ 안정적인 키 생성을 위한 변수
  late final String _stableKey;

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();
    currentItem = widget.item;

    // ★ 안정적인 키 초기화
    _stableKey = '${widget.item.id}-$dividerThickness-$tabsVisible';

    _initializeFrame();
  }

  // ★ 통합된 컨트롤러 관리 메소드
  void _setupControllersAndRelationships() {
    // Frame 컨트롤러는 이미 _initializeFrame에서 생성되었으므로 여기서는 생성하지 않음

    // 부모-자식 관계 설정 (이미 설정되었을 수 있으므로 확인만)
    final parentController =
        homeRepo.hierarchicalControllers[widget.item.boardId];
    if (parentController != null) {
      final frameController = homeRepo.hierarchicalControllers[widget.item.id];
      if (frameController != null) {
        final isChildAlready =
            parentController.children.contains(frameController);
        if (!isChildAlready) {
          parentController.addChild(frameController);
          homeRepo.addChildController(widget.item.boardId, widget.item.id);
        }
      }
    }

    // 기본 탭 컨트롤러 생성 (한 번만)
    _createDefaultTabsOnce();
  }

  // ★ 기본 탭 생성 (한 번만 실행)
  void _createDefaultTabsOnce() {
    final boardId = CompactIdGenerator.generateFrameBoardId(widget.item.id, 1);
    final parentId = widget.item.id;

    // 기존 탭 컨트롤러가 있는지 확인
    if (!homeRepo.hierarchicalControllers.containsKey(boardId)) {
      debugPrint(
          '[StackFrameCase] create default tab controller boardId=$boardId parentId=$parentId');
      // 새 컨트롤러 생성
      final tabController = HierarchicalDockBoardController(
        id: boardId,
        parentId: parentId,
        controller: StackBoardController(boardId: boardId),
      );
      homeRepo.hierarchicalControllers[boardId] = tabController;

      // Frame의 자식으로 설정
      final frameController = homeRepo.hierarchicalControllers[parentId];
      if (frameController != null) {
        final isChildAlready = frameController.children.contains(tabController);
        if (!isChildAlready) {
          frameController.addChild(tabController);
          homeRepo.addChildController(parentId, boardId);
        }
      }

      // tabsTitle 업데이트 (기본 탭 1개)
      final tabsTitle = jsonEncode([
        {'tabIndex': 1, 'title': 'Tab 1', 'boardId': boardId}
      ]);

      // Frame 아이템의 content 업데이트
      final updatedItem = widget.item.copyWith(
        content: widget.item.content?.copyWith(tabsTitle: tabsTitle),
      );

      // 부모 컨트롤러에 업데이트된 아이템 적용
      final parentController =
          homeRepo.hierarchicalControllers[widget.item.boardId];
      if (parentController != null) {
        parentController.controller.updateItem(updatedItem);
      }
    } else {
      // 기존 컨트롤러가 있으면 부모-자식 관계만 확인
      debugPrint(
          '[StackFrameCase] default tab controller exists boardId=$boardId parentId=$parentId');
      _ensureParentChildRelationship(parentId, boardId);
    }
  }

  // ★ 부모-자식 관계 설정 (중복 방지)
  void _ensureParentChildRelationship(String parentId, String childId) {
    final parentController = homeRepo.hierarchicalControllers[parentId];
    final childController = homeRepo.hierarchicalControllers[childId];

    if (parentController != null && childController != null) {
      final isChildAlready =
          parentController.children.contains(childController);
      if (!isChildAlready) {
        parentController.addChild(childController);
        homeRepo.addChildController(parentId, childId);
      }
    }
  }

  // ★ 기존 탭 컨트롤러들 확인 및 관계 설정
  void _setupExistingTabControllers(List<String> boardIds) {
    for (final boardId in boardIds) {
      // 이미 관계가 설정되어 있는지 확인
      final frameController = homeRepo.hierarchicalControllers[widget.item.id];
      final tabController = homeRepo.hierarchicalControllers[boardId];

      if (frameController != null && tabController != null) {
        final isChildAlready = frameController.children.contains(tabController);
        if (!isChildAlready) {
          frameController.addChild(tabController);
          homeRepo.addChildController(widget.item.id, boardId);
        }
      }
    }
  }

  void _initializeFrame() {
    // lastStringify 정보 로깅
    final lastStringify = widget.item.content?.lastStringify ?? '';

    // Frame 컨트롤러는 항상 생성 (Frame은 보드가 아니므로 존재 여부 체크 불필요)
    final frameController = HierarchicalDockBoardController(
      id: widget.item.id,
      parentId: widget.item.boardId,
      controller: StackBoardController(boardId: widget.item.id),
    );
    homeRepo.hierarchicalControllers[widget.item.id] = frameController;

    // 부모-자식 관계 설정
    final parentController =
        homeRepo.hierarchicalControllers[widget.item.boardId];
    if (parentController != null) {
      parentController.addChild(frameController);
      homeRepo.addChildController(widget.item.boardId, widget.item.id);
    }

    // lastStringify가 있으면 예상 탭 보드들을 확인
    if (lastStringify.isNotEmpty) {
      final expectedBoardIds = <String>[];
      try {
        // lastStringify에서 탭 보드 ID들 추출
        final parts = lastStringify.split(',');
        for (final part in parts) {
          if (part.contains('(I;')) {
            final tabIndex = part.split(';')[2];
            final boardId = CompactIdGenerator.generateFrameBoardId(
                widget.item.id, int.parse(tabIndex));
            expectedBoardIds.add(boardId);
          }
        }
      } catch (e) {
        // 파싱 오류 무시
      }

      // 모든 예상 탭 보드가 존재하는지 확인
      final allTabsExist = expectedBoardIds.every(
          (boardId) => homeRepo.hierarchicalControllers.containsKey(boardId));

      if (allTabsExist) {
        // 기존 탭 컨트롤러들의 부모-자식 관계 설정 (한 번에 처리)
        _setupExistingTabControllers(expectedBoardIds);

        // 모든 초기화가 완료된 것으로 간주하고 레이아웃만 초기화
        _initializeLayout().then((_) {
          _loadFrameContent();
          _applyLayoutWeights();
          _subscribeUpdateStackItem();
          _subscribeSelectDockBoard();
        });
        return;
      } else {
        // 일부 탭 보드가 없으면 기존 탭 보드들을 삭제하고 신규 생성
        for (final boardId in expectedBoardIds) {
          if (homeRepo.hierarchicalControllers.containsKey(boardId)) {
            final existingController =
                homeRepo.hierarchicalControllers[boardId];
            if (existingController != null) {
              // 부모에서 제거
              final parentController =
                  homeRepo.hierarchicalControllers[widget.item.id];
              if (parentController != null) {
                parentController.removeChild(existingController);
              }
            }
            homeRepo.hierarchicalControllers.remove(boardId);
          }
        }
      }
    } else {
      // lastStringify가 없으면 기존 방식으로 확인
      final existingTabControllers = <String>[];
      homeRepo.hierarchicalControllers.forEach((key, controller) {
        if (key.startsWith('${widget.item.id}_') && key != widget.item.id) {
          existingTabControllers.add(key);
        }
      });

      if (existingTabControllers.isNotEmpty) {
        // 기존 탭 컨트롤러들의 부모-자식 관계 설정 (한 번에 처리)
        _setupExistingTabControllers(existingTabControllers);

        // 모든 초기화가 완료된 것으로 간주하고 레이아웃만 초기화
        _initializeLayout().then((_) {
          _loadFrameContent();
          _applyLayoutWeights();
          _subscribeUpdateStackItem();
          _subscribeSelectDockBoard();
        });
        return;
      }
    }

    // 통합된 컨트롤러 설정 (한 번에 처리)
    _setupControllersAndRelationships();

    // 레이아웃 초기화
    _initializeLayout().then((_) {
      _loadFrameContent();
      _applyLayoutWeights();
      _subscribeUpdateStackItem();
      _subscribeSelectDockBoard();
    });
  }

  Future<void> _initializeLayout() async {
    // layout과 docking을 먼저 초기화
    layout = DockingLayout(
        root: DockingItem(
      keepAlive: true,
      id: 1,
      name: 'Tab 1',
      widget: KeyedSubtree(
        key: ValueKey('frame_${widget.item.id}_1'),
        child: DockBoard(
          id: CompactIdGenerator.generateFrameBoardId(widget.item.id, 1),
          parentId: widget.item.id,
        ),
      ),
      buttons: [],
    ));
    docking = Docking(layout: layout);
    tabbedViewThemeData = TabbedViewThemeData.mobile();
    tabbedViewThemeData.tabsArea.visible = true;
  }

  void _loadFrameContent() {
    final itemContent = widget.item.content?.toJson();
    if (itemContent == null) {
      return;
    }

    _loadFrameSettings(itemContent);
    _loadFrameLayout(itemContent);

    // 레이아웃 즉시 업데이트
    _updateLayoutAreas();
  }

  void _loadFrameSettings(Map<String, dynamic> itemContent) {
    tabsVisible = bool.tryParse(itemContent['tabsVisible'].toString()) ?? true;
    dividerThickness =
        double.tryParse(itemContent['dividerThickness'].toString()) ?? 6;

    if (itemContent['lastStringify'].toString().isEmpty) {
      itemContent['lastStringify'] = onChangedTabs();
    }
    if (itemContent['lastStringify'] != null &&
        itemContent['lastStringify'].toString().isNotEmpty) {
      final tabs = parseStringify(itemContent['lastStringify']);
      boardIds = tabs['boardIds'];
      weights = tabs['weights'];
    }
  }

  void _loadFrameLayout(Map<String, dynamic> itemContent) {
    try {
      if (itemContent['lastStringify'] != null &&
          itemContent['lastStringify'].toString().isNotEmpty) {
        final lastStringify = itemContent['lastStringify'];

        layout.load(layout: lastStringify, parser: this, builder: this);
      }
    } catch (e) {
      // layout 로딩 실패 시 기본 layout 사용
    }
  }

  void _subscribeSelectDockBoard() {
    _selectDockBoardSub = appStreams.selectDockBoardStream.listen((v) {
      if (v != null && v.startsWith('Frame_')) {
        final tabIndex = _getTabIndexForBoardId(v);
        final boardId = _getBoardIdForTabIndex(tabIndex);
        if (boardId == v) {
          onChangedTabs();
        }
      }
    });
  }

  void _subscribeUpdateStackItem() {
    _updateStackItemSub =
        appStreams.updateStackItemStream.listen(_handleUpdateStackItem);
  }

  void _handleUpdateStackItem(StackItem<StackItemContent>? v) {
    if (v?.id == widget.item.id &&
        v is StackFrameItem &&
        v.boardId == widget.item.boardId) {
      final StackFrameItem item = v;

      if (mounted) {
        setState(() {
          currentItem = item;
          _loadFrameSettings(item.content?.toJson() ?? {});
          _loadFrameLayout(item.content?.toJson() ?? {});
          _updateLayoutAreas();
        });
      }
    }
  }

  void _updateLayoutAreas() {
    try {
      // 기존 레이아웃의 탭 이름 업데이트
      layout.layoutAreas().forEach((e) {
        if (e is DockingItem) {
          final actualBoardId = _getBoardIdForTabIndex(e.id);
          final newTitle = _getTabTitle(actualBoardId);
          if (e.name != newTitle) {
            e.name = newTitle;
          }
        }
      });

      // 레이아웃 재구성
      layout.rebuild();
    } catch (e) {
      // 레이아웃 업데이트 실패 시 무시
    }
  }

  String onChangedTabs() {
    final curStringify = layout.stringify(parser: this);

    // boardId별 title과 tabIndex 동기화
    final tabs = parseStringify(curStringify);
    final List<String> curBoardIds = tabs['boardIds'];
    final Map<String, double> curWeights = tabs['weights'];

    // 첫 호출 시 이전 상태 초기화
    if (prevBoardIds.isEmpty && prevWeights.isEmpty) {
      prevBoardIds = List<String>.from(curBoardIds);
      prevWeights = Map<String, double>.from(curWeights);
    }

    // boardId와 title을 직접 매핑하여 tabsTitle 생성 (tabIndex 기반)
    final List<dynamic> curBoardTitles = [];
    for (int i = 0; i < curBoardIds.length; i++) {
      final boardId = curBoardIds[i];
      final title = _getTabTitle(boardId);
      final tabIndex = _getTabIndexForBoardId(boardId);

      curBoardTitles.add({
        'tabIndex': tabIndex, // tabIndex를 주요 키로 사용
        'title': title,
        'boardId': boardId // 참고용으로 유지
      });
    }

    final curTabsTitle =
        curBoardTitles.isNotEmpty ? jsonEncode(curBoardTitles) : '';

    // 1. 탭 개수 변경 확인
    final isTabBarChanged = curBoardIds.length != prevBoardIds.length;

    // 2. 탭 ID 변경 확인 (순서 무관)
    final isTabIdsChanged =
        !curBoardIds.every((id) => prevBoardIds.contains(id)) ||
            !prevBoardIds.every((id) => curBoardIds.contains(id));

    // 3. 탭 제목 변경 확인 (tabIndex 기반으로 정확한 매칭)
    bool isTabsTitleChanged = false;
    try {
      final prevTabsTitle = widget.item.content?.tabsTitle ?? '';

      if (prevTabsTitle.isNotEmpty) {
        final prevTabs = jsonDecode(prevTabsTitle);
        final curTabs = jsonDecode(curTabsTitle);

        // tabIndex와 title 매핑 생성
        final prevTabMap = <int, String>{};
        final curTabMap = <int, String>{};

        // prevTabs에서 tabIndex와 title 매핑 생성
        for (final tab in prevTabs) {
          final tabIndex = tab['tabIndex'] as int;
          final title = tab['title'] as String;
          prevTabMap[tabIndex] = title;
        }

        // curTabs에서 tabIndex와 title 매핑 생성
        for (final tab in curTabs) {
          final tabIndex = tab['tabIndex'] as int;
          final title = tab['title'] as String;
          curTabMap[tabIndex] = title;
        }

        // tabIndex와 title이 모두 일치하는지 확인
        isTabsTitleChanged = !curTabMap.entries
            .every((entry) => prevTabMap[entry.key] == entry.value);
      } else {
        isTabsTitleChanged = curTabsTitle.isNotEmpty;
      }
    } catch (e) {
      isTabsTitleChanged = true;
    }

    // 4. weight 변경 확인 - 더 엄격한 임계값 사용
    bool isWeightChanged = false;
    if (prevWeights.keys.length != curWeights.keys.length) {
      isWeightChanged = true;
    } else if (curWeights.isNotEmpty && prevWeights.isNotEmpty) {
      for (final id in curBoardIds) {
        final prevW = prevWeights[id] ?? 0.0;
        final currW = curWeights[id] ?? 0.0;

        // ★ 더 엄격한 임계값 사용 (부동소수점 오차 무시)
        final diff = ((prevW * 10000).round() - (currW * 10000).round()).abs();
        final isSignificantlyDifferent = diff > 100; // 임계값을 1000으로 증가

        if (isSignificantlyDifferent) {
          isWeightChanged = true;
          break;
        }
      }
    }

    // 실제 변경사항이 있는지 확인 (순서 변경은 무시)
    final hasRealChanges = isTabBarChanged ||
        isTabIdsChanged ||
        isTabsTitleChanged ||
        isWeightChanged;

    // 실제 변경사항이 있을 때만 updateItem 호출
    if (hasRealChanges) {
      final updatedItem = widget.item.copyWith(
          content: widget.item.content
              ?.copyWith(lastStringify: curStringify, tabsTitle: curTabsTitle));

      // 동기화 호출
      final controller =
          homeRepo.hierarchicalControllers[widget.item.boardId]?.controller;
      if (controller != null) {
        controller.updateItem(updatedItem);
      }

      homeRepo.addOnTapState(updatedItem);

      // widget.item을 업데이트된 아이템으로 교체
      if (mounted) {
        setState(() {
          // widget.item을 업데이트하기 위해 currentItem을 업데이트
          currentItem = updatedItem;

          // 레이아웃 즉시 업데이트
          _updateLayoutAreas();
        });
      }

      // 현재 상태를 이전 상태로 업데이트 (다음 호출을 위해)
      prevLastStringify = curStringify;
      prevBoardIds = List<String>.from(curBoardIds);
      prevWeights = Map<String, double>.from(curWeights);
    }

    return curStringify;
  }

  /// Frame의 tab 순서를 보장하기 위한 기본 메서드들
  @override
  String idToString(dynamic id) {
    if (id == null) {
      return '';
    }

    // 기본값: 단순 변환
    final result = id.toString();
    return result;
  }

  @override
  dynamic stringToId(String id) {
    if (id.isEmpty) {
      return null;
    }

    // 기본값: 단순 변환
    try {
      final result = int.parse(id);
      return result;
    } catch (e) {
      return null;
    }
  }

  /// lastStringify에서 (I;1;tabIndex;weight;F) 패턴을 찾아 새로운 ID 시스템으로 boardId 생성
  Map<String, dynamic> parseStringify(String lastStringify) {
    final Map<String, double> tabWeights = {};
    final List<String> tabBoardIds = [];

    try {
      final parts = lastStringify.split(':');

      if (parts.length >= 3) {
        final layoutData = parts[2];
        final areas = layoutData.split('),');

        for (int i = 0; i < areas.length; i++) {
          String area = areas[i];
          if (area.trim().isEmpty) continue;

          final openParenIndex = area.indexOf('(');
          if (openParenIndex == -1) continue;

          final areaIndex = int.tryParse(area.substring(0, openParenIndex));
          if (areaIndex == null) continue;

          final areaContent = area.substring(openParenIndex + 1);
          final components = areaContent.split(';');

          if (components.length >= 4) {
            final type = components[0];
            final isTab = components[1]; // 1이면 tab
            final tabIndex = int.tryParse(components[2]);
            final weight = double.tryParse(components[3]) ?? 0.0;

            // I 타입이고 isTab이 1인 경우가 tab을 나타냄
            if (type == 'I' && isTab == '1' && tabIndex != null) {
              // 새로운 ID 시스템 사용
              final tabBoardId = CompactIdGenerator.generateFrameBoardId(
                  widget.item.id, tabIndex);

              tabBoardIds.add(tabBoardId);
              tabWeights[tabBoardId] = weight;
            }
          }
        }
      }
    } catch (e) {
      // 오류 처리
    }

    return {
      'boardIds': tabBoardIds,
      'weights': tabWeights,
    };
  }

  // Frame_id_tabIndex 패턴에서 tabIndex 추출
  int _getTabIndexForBoardId(String boardId) {
    // Frame_id_tabIndex 패턴에서 tabIndex 추출
    if (boardId.startsWith('Frame_')) {
      final parts = boardId.split('_');
      if (parts.length >= 3) {
        // 마지막 부분이 tabIndex
        final tabIndex = int.tryParse(parts.last);
        if (tabIndex != null) {
          return tabIndex;
        }
      }
    }

    // fallback: lastStringify에서 찾기
    final lastStringify = widget.item.content?.lastStringify ?? '';
    if (lastStringify.isNotEmpty) {
      final tabs = parseStringify(lastStringify);
      final boardIds = tabs['boardIds'];
      for (int i = 0; i < boardIds.length; i++) {
        if (boardIds[i] == boardId) {
          return i + 1; // 1-based index
        }
      }
    }

    return 1; // 최종 fallback
  }

  // tabIndex로 새로운 ID 시스템의 boardId 생성
  String _getBoardIdForTabIndex(int tabIndex) {
    return CompactIdGenerator.generateFrameBoardId(widget.item.id, tabIndex);
  }

  String _getTabTitle(String boardId) {
    // tabIndex 추출
    final tabIndex = _getTabIndexForBoardId(boardId);

    // 기존 값이 존재하면 그 값을 사용 (tabIndex 기반 매칭)
    final json = currentItem.content?.toJson() ?? {};

    if (json['tabsTitle'] != null && json['tabsTitle'].toString().isNotEmpty) {
      final tabsTitle = jsonDecode(json['tabsTitle']);
      for (final tab in tabsTitle) {
        if (tab['tabIndex'] == tabIndex) {
          final title = tab['title'];
          return title;
        }
      }
    }

    // 기본 제목 생성
    return 'Tab $tabIndex';
  }

  // 레이아웃 가중치 적용 (기본 구현)
  void _applyLayoutWeights() {
    try {
      layout.layoutAreas().forEach((e) {
        if (e is DockingItem) {
          // weight 반영은 stringify/parse 경로로 처리 (패키지 내부 멤버 직접 호출 회피)
          // final DockingItem? item = layout.findDockingItem(e.id);
          // final boardId = _getBoardIdForTabIndex(e.id);
        }
      });
      layout.rebuild();
    } catch (e) {
      // layout weights application 실패 시 무시
    }
  }

  // DockingItem 생성 (id: int index) - 새로운 ID 시스템 사용
  DockingItem _createDockingItem(dynamic id, {bool flag = false}) {
    try {
      final index = id is int ? id : int.tryParse(id.toString());
      if (index == null) {
        throw Exception('Invalid tab index: $id');
      }

      // 새로운 ID 시스템 사용
      final boardId =
          CompactIdGenerator.generateFrameBoardId(currentItem.id, index);
      final parentId = currentItem.id; // Frame의 boardId를 parentId로 전달

      debugPrint(
          '[StackFrameCase] build DockingItem index=$index boardId=$boardId parentId=$parentId flag=$flag');

      // 탭 제목 생성 (boardId 기반 매칭)
      String tabTitle = 'Tab $index';
      final tabsTitle = currentItem.content?.tabsTitle;
      if (tabsTitle != null && tabsTitle.isNotEmpty) {
        try {
          final List<dynamic> frameTitle = jsonDecode(tabsTitle);
          for (final tabInfo in frameTitle) {
            if (tabInfo is Map<String, dynamic> &&
                tabInfo['boardId'] == boardId &&
                tabInfo.containsKey('title')) {
              tabTitle = tabInfo['title'] as String;
              break;
            }
          }
        } catch (e) {
          // JSON 파싱 실패 시 기본 제목 사용
        }
      }

      // 컨트롤러 생성 및 관계 설정 (통합된 로직)
      _setupTabController(boardId, parentId, flag);

      return DockingItem(
        keepAlive: true,
        id: index,
        name: tabTitle,
        widget: KeyedSubtree(
          key: ValueKey('frame_${currentItem.id}_$index'),
          child: DockBoard(
            id: boardId,
            parentId: parentId, // Frame의 boardId를 parentId로 전달
          ),
        ),
        buttons: listTabButton(index),
      );
    } catch (e) {
      debugPrint('[StackFrameCase][ERROR] _createDockingItem id=$id e=$e');
      // 기본값 설정
      final fallbackIndex = id is int ? id : 1;
      final fallbackBoardId = CompactIdGenerator.generateFrameBoardId(
          currentItem.id, fallbackIndex);
      final fallbackParentId = currentItem.id;

      return DockingItem(
        keepAlive: true,
        id: fallbackIndex,
        name: 'Tab $fallbackIndex',
        widget: KeyedSubtree(
          key: ValueKey('frame_${currentItem.id}_$fallbackIndex'),
          child: DockBoard(
            id: fallbackBoardId,
            parentId: fallbackParentId,
          ),
        ),
        buttons: listTabButton(fallbackIndex),
      );
    }
  }

  // ★ 탭 컨트롤러 설정 (통합된 로직)
  void _setupTabController(String boardId, String parentId, bool flag) {
    if (flag && homeRepo.hierarchicalControllers.containsKey(boardId)) {
      // flag==true인 경우: 기존 컨트롤러의 관계만 확인
      _ensureParentChildRelationship(parentId, boardId);
    } else if (!flag) {
      // flag==false인 경우: 컨트롤러 생성 또는 관계 설정
      if (!homeRepo.hierarchicalControllers.containsKey(boardId)) {
        // 새 컨트롤러 생성
        debugPrint(
            '[StackFrameCase] create tab controller boardId=$boardId parentId=$parentId');
        final tabController = HierarchicalDockBoardController(
          id: boardId,
          parentId: parentId,
          controller: StackBoardController(boardId: boardId),
        );
        homeRepo.hierarchicalControllers[boardId] = tabController;
        _ensureParentChildRelationship(parentId, boardId);
      } else {
        // 기존 컨트롤러의 관계만 확인
        debugPrint(
            '[StackFrameCase] reuse tab controller boardId=$boardId parentId=$parentId');
        _ensureParentChildRelationship(parentId, boardId);
      }
    }
  }

  // 탭 버튼 생성 (삭제/추가) - index 기반, 내부에서 boardId 계산
  List<TabButton> listTabButton(int index) {
    return [
      TabButton(
        icon: IconProvider.data(Icons.add),
        onPressed: () {
          final newId = maxItemId() + 1;
          final newBoardId =
              CompactIdGenerator.generateFrameBoardId(currentItem.id, newId);

          // 기존 탭 보드가 존재하면 컨트롤러 초기화
          if (homeRepo.hierarchicalControllers.containsKey(newBoardId)) {
            // 기존 컨트롤러가 있는 경우 부모-자식 관계만 확인
            final existingController =
                homeRepo.hierarchicalControllers[newBoardId];
            final parentController =
                homeRepo.hierarchicalControllers[currentItem.id];

            if (parentController != null && existingController != null) {
              final isChildAlready =
                  parentController.children.contains(existingController);
              if (!isChildAlready) {
                parentController.addChild(existingController);
                homeRepo.addChildController(currentItem.id, newBoardId);
              }
            }
          } else {
            // 기존 탭 보드가 존재하지 않는 경우에만 새로 생성

            // 신규 컨트롤러 생성
            final newController = HierarchicalDockBoardController(
              id: newBoardId,
              parentId: currentItem.id,
              controller: StackBoardController(boardId: newBoardId),
            );
            homeRepo.hierarchicalControllers[newBoardId] = newController;

            // 부모-자식 관계 설정
            final parentController =
                homeRepo.hierarchicalControllers[currentItem.id];
            if (parentController != null) {
              parentController.addChild(newController);
              homeRepo.addChildController(currentItem.id, newBoardId);
            }
          }

          final newItem = _createDockingItem(newId, flag: true);
          final targetArea = layout.findDockingItem(index);
          if (targetArea != null) {
            layout.addItemOn(
              newItem: newItem,
              targetArea: targetArea,
              dropPosition: DropPosition.right,
            );
            // new weight 적용은 stringify/parse 경로에서 관리 (패키지 내부 멤버 호출 회피)
            layout.rebuild();
          }
        },
      ),
    ];
  }

  int maxItemId() {
    int maxId = 0;
    try {
      layout.layoutAreas().forEach((e) {
        if (e is DockingItem) {
          final idx = e.id is int
              ? e.id
              : int.tryParse(e.id.toString().split('_').last);
          if (idx != null && maxId < idx) {
            maxId = idx;
          }
        }
      });
    } catch (e) {
      maxId = 1; // 기본값
    }
    return maxId;
  }

  @override
  void dispose() {
    _updateStackItemSub.cancel();
    _selectDockBoardSub.cancel();
    // ★ MyDividerPainter 리소스 정리
    _dividerPainter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = TabbedViewThemeData.mobile();
    themeData.tabsArea.visible = tabsVisible;

    // docking이 초기화되지 않았으면 로딩 위젯 반환
    try {
      _dividerPainter ??= MyDividerPainter(onDividerPainted: () {
        onChangedTabs();
      });

      return MultiSplitViewTheme(
          key: ValueKey(_stableKey),
          data: MultiSplitViewThemeData(
            dividerThickness: dividerThickness,
            dividerPainter: _dividerPainter!,
          ),
          child: TabbedViewTheme(
            data: themeData,
            child: docking,
          ));
    } catch (e) {
      return const Center(child: CircularProgressIndicator());
    }
  }

  // @override
  @override
  DockingItem buildDockingItem({
    required dynamic id,
    required bool maximized,
    required double? weight,
  }) {
    return _createDockingItem(id, flag: false);
  }
}
