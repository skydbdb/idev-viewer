import 'dart:async';
import 'dart:convert';

import 'package:docking/docking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/board/stack_board_item.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'package:idev_viewer/src/internal/board/board/dock_board.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:idev_viewer/src/internal/board/stack_items.dart';
import 'package:idev_viewer/src/internal/repo/app_streams.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import 'package:idev_viewer/src/internal/board/helpers/compact_id_generator.dart';
import 'package:idev_viewer/src/internal/board/board/hierarchical_dock_board_controller.dart';
import 'package:idev_viewer/src/internal/board/flutter_stack_board.dart';

// 커스텀 DividerPainter 정의 (더 정교한 마우스 이벤트 감지)
class MyDividerPainter extends DividerPainter {
  MyDividerPainter({required this.onDividerPainted});
  final VoidCallback onDividerPainted;

  Timer? _debounceTimer;

  Axis? _lastDividerAxis;
  Size? _lastDividerSize;

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

    // 분리바 고유 식별자 생성
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

    final wasHighlighted = _dividerStates['${dividerKey}_highlighted'] ?? false;
    final wasResizable = _dividerStates['${dividerKey}_resizable'] ?? false;
    final lastInteractionTime = _dividerInteractionTimes[dividerKey];

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
  AppStreams? appStreams;
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

  MyDividerPainter? _dividerPainter;

  late final String _stableKey;

  String _cachedLastStringify = '';
  Map<String, dynamic>? _cachedParseResult;

  Timer? _onChangedTabsDebounceTimer;

  bool _isLoadingLayout = false;

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    // 뷰어 모드에서는 AppStreams 사용하지 않음
    if (BuildMode.isEditor) {
      appStreams = sl<AppStreams>();
    }
    currentItem = widget.item;

    // ★ 안정적인 키 초기화
    _stableKey = '${widget.item.id}-$dividerThickness-$tabsVisible';

    _initializeFrame();
  }

  // ★ 공통 완료 루틴: 콘텐츠/레이아웃 로드 + 구독 등록
  void _finishInitialize() {
    _loadFrameContent();
    _applyLayoutWeights();
    _subscribeUpdateStackItem();
    _subscribeSelectDockBoard();
    // ★ 초기화 루틴의 가장 마지막 단계에서 가중치 최종 적용
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFinalWeightsAndVerify();
    });
  }

  void _initializeFrame() {
    _createAndSetupController(widget.item.id, widget.item.boardId);

    // 1) 항상 기본 레이아웃으로 시작
    _createInitialLayout();

    // 2) 기본 초기화 완료 후 가중치 적용
    _finishInitialize();
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

    final lastStringifyValue = itemContent['lastStringify']?.toString() ?? '';

    if (lastStringifyValue.isEmpty) {
      itemContent['lastStringify'] = onChangedTabs();
    } else {}

    if (itemContent['lastStringify'] != null &&
        itemContent['lastStringify'].toString().isNotEmpty) {
      final tabs = parseStringify(itemContent['lastStringify']);
      boardIds = tabs['boardIds'];
      weights = tabs['weights'];
    }
  }

  // ★ lastStringify에서 tabIndex → weight 맵 추출
  Map<int, double> _extractWeightsByTabIndexFromStringify(
      String lastStringify) {
    final Map<int, double> weightsByTab = {};
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
          final areaContent = area.substring(openParenIndex + 1);
          final components = areaContent.split(';');
          if (components.length >= 4) {
            final type = components[0];
            final isTab = components[1];
            final tabIndex = int.tryParse(components[2]);
            final weight = double.tryParse(components[3]) ?? 0.0;
            if (type == 'I' && isTab == '1' && tabIndex != null) {
              weightsByTab[tabIndex] = weight;
            }
          }
        }
      }
    } catch (_) {}
    return weightsByTab;
  }

  // ★ target stringify에 tabIndex 기반 weight를 주입하여 병합
  String _mergeWeightsIntoStringify(
      String targetStringify, Map<int, double> sourceWeightsByTab) {
    try {
      // 패턴: I;1;<tabIndex>;<weight>;F)
      final reg = RegExp(r'(I;1;)(\d+)(;)([^;]*)(;F\))');
      final merged = targetStringify.replaceAllMapped(reg, (m) {
        final tabIndex = int.tryParse(m.group(2) ?? '');
        if (tabIndex != null && sourceWeightsByTab.containsKey(tabIndex)) {
          final w = sourceWeightsByTab[tabIndex]!;
          return '${m.group(1)}${m.group(2)}${m.group(3)}$w${m.group(5)}';
        }
        return m.group(0) ?? '';
      });
      return merged;
    } catch (_) {
      return targetStringify;
    }
  }

  void _loadFrameLayout(Map<String, dynamic> itemContent) {
    try {
      if (itemContent['lastStringify'] != null &&
          itemContent['lastStringify'].toString().isNotEmpty) {
        final lastStringify = itemContent['lastStringify'];
        _isLoadingLayout = true;
        layout.load(layout: lastStringify, parser: this, builder: this);
        _isLoadingLayout = false;

        // load 이후 layout.stringify로 실제 반영 상태 재확인
        try {
          final s = layout.stringify(parser: this);
          final parsed = parseStringify(s);
          final Map<String, double> afterWeights = parsed['weights'];

          // ★ 가중치가 소실(빈 값이나 0들)된 것으로 보이면 즉시 보정 stringify 생성 후 재적용
          final bool looksMissing = afterWeights.isEmpty ||
              afterWeights.values.every((w) => (w == 0 || w.isNaN));
          if (looksMissing) {
            final srcByTab =
                _extractWeightsByTabIndexFromStringify(lastStringify);
            final merged = _mergeWeightsIntoStringify(s, srcByTab);
            try {
              _isLoadingLayout = true;
              layout.load(layout: merged, parser: this, builder: this);
              _isLoadingLayout = false;
            } catch (e) {
              _isLoadingLayout = false;
            }
          }
        } catch (e) {}
      } else {}
    } catch (e) {
      _isLoadingLayout = false;
    }
  }

  void _subscribeSelectDockBoard() {
    // 뷰어 모드에서는 구독하지 않음
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }

    _selectDockBoardSub = appStreams!.selectDockBoardStream.listen((v) {
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
    // 뷰어 모드에서는 구독하지 않음
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }

    _updateStackItemSub =
        appStreams!.updateStackItemStream.listen(_handleUpdateStackItem);
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
    if (_isLoadingLayout) {
      try {
        return layout.stringify(parser: this);
      } catch (_) {
        return '';
      }
    }

    try {
      final curStringify = layout.stringify(parser: this);

      // 디바운스 타이머 재설정
      _onChangedTabsDebounceTimer?.cancel();
      _onChangedTabsDebounceTimer =
          Timer(const Duration(milliseconds: 100), () {
        _performOnChangedTabs(curStringify);
      });

      return curStringify;
    } catch (e) {
      return '';
    }
  }

  void _performOnChangedTabs(String curStringify) {
    final tabs = parseStringify(curStringify);
    final List<String> curBoardIds = tabs['boardIds'];
    final Map<String, double> curWeights = tabs['weights'];

    // 초기 상태 설정
    if (prevBoardIds.isEmpty && prevWeights.isEmpty) {
      prevBoardIds = List<String>.from(curBoardIds);
      prevWeights = Map<String, double>.from(curWeights);
    }

    // boardId별 title과 tabIndex 동기화
    final List<dynamic> curBoardTitles = [];
    for (int i = 0; i < curBoardIds.length; i++) {
      final boardId = curBoardIds[i];
      final title = _getTabTitle(boardId);
      final tabIndex = _getTabIndexForBoardId(boardId);

      curBoardTitles
          .add({'tabIndex': tabIndex, 'title': title, 'boardId': boardId});
    }

    final curTabsTitle =
        curBoardTitles.isNotEmpty ? jsonEncode(curBoardTitles) : '';

    // 변경사항 확인
    final isTabBarChanged = curBoardIds.length != prevBoardIds.length;
    final isTabIdsChanged =
        !curBoardIds.every((id) => prevBoardIds.contains(id)) ||
            !prevBoardIds.every((id) => curBoardIds.contains(id));

    // 탭 제목 변경 확인
    bool isTabsTitleChanged = false;
    try {
      final prevTabsTitle = widget.item.content?.tabsTitle ?? '';
      if (prevTabsTitle.isNotEmpty) {
        final prevTabs = jsonDecode(prevTabsTitle);
        final curTabs = jsonDecode(curTabsTitle);

        final prevTabMap = <int, String>{};
        final curTabMap = <int, String>{};

        for (final tab in prevTabs) {
          prevTabMap[tab['tabIndex'] as int] = tab['title'] as String;
        }
        for (final tab in curTabs) {
          curTabMap[tab['tabIndex'] as int] = tab['title'] as String;
        }

        isTabsTitleChanged =
            !curTabMap.entries.every((e) => prevTabMap[e.key] == e.value);
      } else {
        isTabsTitleChanged = curTabsTitle.isNotEmpty;
      }
    } catch (e) {
      isTabsTitleChanged = true;
    }

    // weight 변경 확인
    bool isWeightChanged = false;
    if (prevWeights.keys.length != curWeights.keys.length) {
      isWeightChanged = true;
    } else if (curWeights.isNotEmpty && prevWeights.isNotEmpty) {
      for (final id in curBoardIds) {
        final prevW = prevWeights[id] ?? 0.0;
        final currW = curWeights[id] ?? 0.0;
        final diff = ((prevW * 10000).round() - (currW * 10000).round()).abs();
        if (diff > 100) {
          isWeightChanged = true;
          break;
        }
      }
    }

    final hasRealChanges = isTabBarChanged ||
        isTabIdsChanged ||
        isTabsTitleChanged ||
        isWeightChanged;

    if (hasRealChanges) {
      // 항상 lastStringify는 업데이트
      final updatedItem = widget.item.copyWith(
          content: widget.item.content
              ?.copyWith(lastStringify: curStringify, tabsTitle: curTabsTitle));

      // 컨트롤러 업데이트
      final controller =
          homeRepo.hierarchicalControllers[widget.item.boardId]?.controller;
      if (controller != null) {
        controller.updateItem(updatedItem);
      }
      homeRepo.addOnTapState(updatedItem);

      // 상태 업데이트
      if (mounted) {
        setState(() {
          currentItem = updatedItem;
          // lastStringify가 있으면 레이아웃 업데이트는 건너뜀
          if (!_shouldUpdateLayout()) {
          } else {
            _updateLayoutAreas();
          }
        });
      }

      // 이전 상태 업데이트
      prevLastStringify = curStringify;
      prevBoardIds = List<String>.from(curBoardIds);
      prevWeights = Map<String, double>.from(curWeights);
    } else {}
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
  /// 캐싱 기능이 추가된 버전
  Map<String, dynamic> parseStringify(String lastStringify) {
    // ★ 캐싱된 결과가 있고 lastStringify가 동일하면 캐시된 결과 반환
    if (_cachedLastStringify == lastStringify && _cachedParseResult != null) {
      // debugPrint('[StackFrameCase.parseStringify] 캐시된 결과 사용: "$lastStringify"');
      return _cachedParseResult!;
    }

    // debugPrint('[StackFrameCase.parseStringify] 파싱 시작 - lastStringify: "$lastStringify"');
    final Map<String, double> tabWeights = {};
    final List<String> tabBoardIds = [];

    try {
      final parts = lastStringify.split(':');
      // debugPrint('[StackFrameCase.parseStringify] split 결과 - parts: $parts');

      if (parts.length >= 3) {
        final layoutData = parts[2];
        // debugPrint('[StackFrameCase.parseStringify] layoutData: "$layoutData"');
        final areas = layoutData.split('),');
        // debugPrint('[StackFrameCase.parseStringify] areas: $areas');

        for (int i = 0; i < areas.length; i++) {
          String area = areas[i];
          if (area.trim().isEmpty) continue;

          final openParenIndex = area.indexOf('(');
          if (openParenIndex == -1) continue;

          final areaIndex = int.tryParse(area.substring(0, openParenIndex));
          if (areaIndex == null) continue;

          final areaContent = area.substring(openParenIndex + 1);
          final components = areaContent.split(';');
          // debugPrint('[StackFrameCase.parseStringify] area $i - areaIndex: $areaIndex, components: $components');

          if (components.length >= 4) {
            final type = components[0];
            final isTab = components[1]; // 1이면 tab
            final tabIndex = int.tryParse(components[2]);
            final weight = double.tryParse(components[3]) ?? 0.0;

            // debugPrint('[StackFrameCase.parseStringify] area $i - type: $type, isTab: $isTab, tabIndex: $tabIndex, weight: $weight');

            // I 타입이고 isTab이 1인 경우가 tab을 나타냄
            if (type == 'I' && isTab == '1' && tabIndex != null) {
              // 새로운 ID 시스템 사용
              final tabBoardId = CompactIdGenerator.generateFrameBoardId(
                  widget.item.id, tabIndex);

              tabBoardIds.add(tabBoardId);
              tabWeights[tabBoardId] = weight;
              // debugPrint('[StackFrameCase.parseStringify] 탭 보드 추가 - tabIndex: $tabIndex, boardId: $tabBoardId, weight: $weight');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[StackFrameCase.parseStringify] 파싱 오류: $e');
    }

    final result = {
      'boardIds': tabBoardIds,
      'weights': tabWeights,
    };

    // ★ 결과를 캐시에 저장
    _cachedLastStringify = lastStringify;
    _cachedParseResult = result;

    // debugPrint('[StackFrameCase.parseStringify] 파싱 결과 - boardIds: $tabBoardIds, weights: $tabWeights');
    return result;
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

  // ★ 초기화 마지막 단계에서 가중치 최종 적용 (lastStringify 없으면 등분, 있으면 설정값 적용)
  bool _applyFinalWeights() {
    try {
      final last = currentItem.content?.lastStringify?.toString() ?? '';
      final before = layout.stringify(parser: this);

      // 1. 현재 레이아웃 구조 파악
      final beforeParsed = parseStringify(before);
      final List<String> boardIds = beforeParsed['boardIds'];
      if (boardIds.isEmpty) {
        return false;
      }

      // 2. 적용할 가중치 결정
      Map<String, double> targetWeights = {};
      if (last.isEmpty) {
        // 등분 가중치 계산
        final w = 1.0 / boardIds.length;
        for (final id in boardIds) {
          targetWeights[id] = w;
        }
      } else {
        // 설정 가중치 추출
        final lastParsed = parseStringify(last);
        targetWeights = Map<String, double>.from(lastParsed['weights']);
      }

      // 3. 가중치가 포함된 새 레이아웃 생성
      final parts = before.split(':');
      if (parts.length < 3) {
        return false;
      }

      // 레이아웃 데이터 추출
      final version = parts[0];
      final areaCount = parts[1];
      final areas = parts[2]
          .split('),')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();

      // 새 레이아웃 조립
      final newAreas = <String>[];
      bool hasChanges = false;

      for (final area in areas) {
        if (area.contains('(I;1;')) {
          // 탭 영역인 경우
          final match = RegExp(r'(\d+)\(I;1;(\d+);[^;]*;F').firstMatch(area);
          if (match != null) {
            final areaIndex = match.group(1);
            final tabIndex = int.tryParse(match.group(2) ?? '');
            if (tabIndex != null) {
              final boardId = CompactIdGenerator.generateFrameBoardId(
                  currentItem.id, tabIndex);
              final weight = targetWeights[boardId];
              if (weight != null && weight > 0) {
                // 가중치 포함하여 새 영역 생성
                final newArea = '$areaIndex(I;1;$tabIndex;$weight;F)';
                newAreas.add(newArea);
                hasChanges = true;
                continue;
              }
            }
          }
        }
        newAreas.add(area);
      }

      if (!hasChanges) {
        return false;
      }

      // 4. 새 레이아웃 적용
      try {
        final newLayout = '$version:$areaCount:${newAreas.join(',')}';

        _isLoadingLayout = true;
        layout.load(layout: newLayout, parser: this, builder: this);
        _isLoadingLayout = false;

        return true;
      } catch (e) {
        _isLoadingLayout = false;
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // ★ 최종 가중치 적용 후 렌더링까지 검증
  void _applyFinalWeightsAndVerify() {
    final applied = _applyFinalWeights();
    if (applied) {
      try {
        layout.rebuild();
      } catch (_) {}
      if (mounted) {
        setState(() {});
      }
    }

    // 다음 프레임에서 stringify 검증
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        layout.stringify(parser: this);
      } catch (e) {}

      // 두 번째 프레임에서도 한 번 더 검증
      WidgetsBinding.instance.addPostFrameCallback((__) {
        try {
          layout.stringify(parser: this);
        } catch (e) {}
      });
    });
  }

  // DockingItem 생성 (id: int index) - 새로운 ID 시스템 사용
  DockingItem _createDockingItem(dynamic id,
      {bool flag = false, double? weight}) {
    try {
      final index = id is int ? id : int.tryParse(id.toString());
      if (index == null) {
        throw Exception('Invalid tab index: $id');
      }

      // 새로운 ID 시스템 사용
      final boardId =
          CompactIdGenerator.generateFrameBoardId(currentItem.id, index);
      final parentId = currentItem.id; // Frame의 boardId를 parentId로 전달

      // debugPrint('[StackFrameCase] build DockingItem index=$index boardId=$boardId parentId=$parentId flag=$flag weight=$weight');

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
        weight: weight, // ★ weight 직접 전달
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
      // debugPrint('[StackFrameCase][ERROR] _createDockingItem id=$id e=$e');
      // 기본값 설정
      final fallbackIndex = id is int ? id : 1;
      final fallbackBoardId = CompactIdGenerator.generateFrameBoardId(
          currentItem.id, fallbackIndex);
      final fallbackParentId = currentItem.id;

      return DockingItem(
        keepAlive: true,
        id: fallbackIndex,
        name: 'Tab $fallbackIndex',
        weight: weight ?? 0.5, // ★ fallback에도 weight 설정
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

  void _setupTabController(String boardId, String parentId, bool flag) {
    if (flag && homeRepo.hierarchicalControllers.containsKey(boardId)) {
      _ensureParentChildRelationship(parentId, boardId);
    } else if (!flag) {
      if (!homeRepo.hierarchicalControllers.containsKey(boardId)) {
        _createAndSetupController(boardId, parentId);
      } else {
        _ensureParentChildRelationship(parentId, boardId);
      }
    }
  }

  void _createAndSetupController(String boardId, String parentId) {
    final controller = HierarchicalDockBoardController(
      id: boardId,
      parentId: parentId,
      controller: StackBoardController(boardId: boardId),
    );
    homeRepo.hierarchicalControllers[boardId] = controller;
    _ensureParentChildRelationship(parentId, boardId);
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
            _ensureParentChildRelationship(currentItem.id, newBoardId);
          } else {
            // 기존 탭 보드가 존재하지 않는 경우에만 새로 생성

            _createAndSetupController(newBoardId, currentItem.id);
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
    // ★ 디바운싱 타이머 정리
    _onChangedTabsDebounceTimer?.cancel();
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
  // ★ 레이아웃 업데이트 가드 (lastStringify가 있으면 업데이트 방지)
  bool _shouldUpdateLayout() {
    final hasLastStringify =
        currentItem.content?.lastStringify?.isNotEmpty ?? false;
    return !hasLastStringify;
  }

  // ★ 초기 레이아웃 생성 (lastStringify 있으면 그대로 사용, 없으면 기본값)
  void _createInitialLayout() {
    // debugPrint('레이아웃 초기화 시작');
    try {
      _isLoadingLayout = true;

      // 1. 필수 필드 초기화
      weights = {};
      boardIds = [];

      // 2. 레이아웃 소스 결정
      final lastStringify =
          widget.item.content?.lastStringify?.toString() ?? '';
      final hasLastStringify = lastStringify.isNotEmpty;

      // 3. 기본 DockingLayout 생성 (weight 포함)
      if (hasLastStringify) {
        // lastStringify에서 weight 추출
        final parsed = parseStringify(lastStringify);
        weights = Map<String, double>.from(parsed['weights']);
        boardIds = List<String>.from(parsed['boardIds']);

        // 첫 번째 탭으로 시작
        final firstTabId = boardIds.isNotEmpty
            ? boardIds[0]
            : CompactIdGenerator.generateFrameBoardId(widget.item.id, 1);
        final firstTabWeight = weights[firstTabId] ?? 1.0;

        layout = DockingLayout(
          root: DockingItem(
            keepAlive: true,
            id: 1,
            name: 'Tab 1',
            weight: firstTabWeight, // ★ weight 설정
            widget: KeyedSubtree(
              key: ValueKey('frame_${widget.item.id}_1'),
              child: DockBoard(
                id: firstTabId,
                parentId: widget.item.id,
              ),
            ),
            buttons: [],
          ),
        );
      } else {
        // 기본 레이아웃 (등분 가중치)
        layout = DockingLayout(
          root: DockingItem(
            keepAlive: true,
            id: 1,
            name: 'Tab 1',
            weight: 0.5, // ★ 기본 등분 가중치
            widget: KeyedSubtree(
              key: ValueKey('frame_${widget.item.id}_1'),
              child: DockBoard(
                id: CompactIdGenerator.generateFrameBoardId(widget.item.id, 1),
                parentId: widget.item.id,
              ),
            ),
            buttons: [],
          ),
        );
      }

      // 4. Docking 인스턴스 생성
      docking = Docking(layout: layout);

      // 5. 탭 영역 설정
      tabbedViewThemeData = TabbedViewThemeData.mobile();
      tabbedViewThemeData.tabsArea.visible = tabsVisible;

      // 6. 레이아웃 로드
      if (hasLastStringify) {
        layout.load(layout: lastStringify, parser: this, builder: this);
      } else {
        const defaultLayout = 'V1:3:1(R;0;;;2,3),2(I;1;1;0.5;F),3(I;1;2;0.5;F)';
        layout.load(layout: defaultLayout, parser: this, builder: this);
      }
    } finally {
      _isLoadingLayout = false;
    }
  }

  @override
  DockingItem buildDockingItem({
    required dynamic id,
    required bool maximized,
    required double? weight,
  }) {
    final index = id is int ? id : int.tryParse(id.toString());
    double? resolvedWeight;
    if (index != null) {
      final boardId =
          CompactIdGenerator.generateFrameBoardId(currentItem.id, index);
      // 우선순위: 1) 전달된 weight 2) 저장된 weights 3) 기본값 0.5
      resolvedWeight = weight ?? weights[boardId] ?? 0.5;
    } else {
      resolvedWeight = weight ?? 0.5;
    }

    // weight를 DockingItem 생성 시 직접 전달
    return _createDockingItem(id, flag: false, weight: resolvedWeight);
  }
}
