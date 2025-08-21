import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/layout/menus/api/api_popup_dialog.dart';
import 'package:idev_v1/src/repo/home_repo.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item_status.dart';
import 'package:idev_v1/src/board/stack_items.dart';
import 'package:idev_v1/src/board/helpers/compact_id_generator.dart';
import '/src/di/service_locator.dart';
import 'package:idev_v1/src/repo/app_streams.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({super.key});

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  bool isLoaded = false;
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  String? selectedItemId;
  String? selectedBoardId;
  List<String> _sortedBoardList = [];
  final Map<String, bool> _expandedBoards = {};
  final Map<String, bool> _expandedItems = {};

  @override
  void initState() {
    isLoaded = true;
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();
    _updateBoardList();
    _subscribeToUpdates();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _subscribeToUpdates() {
    appStreams.topMenuStream.listen((v) {
      if (v != null && v['removed'] == true) {
        if (mounted) {
          setState(() {
            _updateBoardList();
          });
        }
      }
    });

    appStreams.onTapStream.listen((item) {
      if (mounted && item != null && item.id != selectedItemId) {
        setState(() {
          selectedItemId = item.id;
          _updateBoardList();
        });
      }
    });

    appStreams.selectDockBoardStream.listen((boardId) {
      if (mounted && boardId != null && boardId != selectedBoardId) {
        setState(() {
          _updateBoardList();
          selectedBoardId = boardId;
        });
      }
    });
  }

  void _updateBoardList() {
    setState(() {
      _sortedBoardList = homeRepo.hierarchicalControllers.keys
          .where((boardId) => boardId.startsWith('new_'))
          .toList();
      _sortedBoardList.sort((a, b) => a.compareTo(b));
      _debugHierarchyStructure(); // 계층 구조 디버그 출력
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeRepo = context.read<HomeRepo>();
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Theme(
              data: ThemeData.dark(),
              child: Container(
                  color: ThemeData.dark().dividerColor,
                  height: 20,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('위젯 탐색기'),
                        ],
                      ),
                      Positioned(
                          right: 0,
                          bottom: 0,
                          child: Row(
                            children: [
                              InkWell(
                                  onTap: (selectedBoardId != null &&
                                          homeRepo
                                                  .hierarchicalControllers[
                                                      selectedBoardId]
                                                  ?.controller
                                                  .history
                                                  .isNotEmpty ==
                                              true)
                                      ? () {
                                          final controller = homeRepo
                                              .hierarchicalControllers[
                                                  selectedBoardId!]
                                              ?.controller;
                                          controller?.undo();
                                          if (mounted) {
                                            setState(() {}); // UI 갱신
                                          }
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Tooltip(
                                        message: 'Undo',
                                        child: Icon(Icons.undo,
                                            size: 16,
                                            color: (selectedBoardId != null &&
                                                    homeRepo
                                                            .hierarchicalControllers[
                                                                selectedBoardId]
                                                            ?.controller
                                                            .history
                                                            .isNotEmpty ==
                                                        true)
                                                ? Colors.white
                                                : Colors.grey)),
                                  )),
                              InkWell(
                                  onTap: (selectedBoardId != null &&
                                          homeRepo
                                                  .hierarchicalControllers[
                                                      selectedBoardId]
                                                  ?.controller
                                                  .redoHistory
                                                  .isNotEmpty ==
                                              true)
                                      ? () {
                                          final controller = homeRepo
                                              .hierarchicalControllers[
                                                  selectedBoardId!]
                                              ?.controller;
                                          controller?.redo();
                                          if (mounted) {
                                            setState(() {});
                                          }
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Tooltip(
                                        message: 'Redo',
                                        child: Icon(Icons.redo,
                                            size: 16,
                                            color: (selectedBoardId != null &&
                                                    homeRepo
                                                            .hierarchicalControllers[
                                                                selectedBoardId]
                                                            ?.controller
                                                            .redoHistory
                                                            .isNotEmpty ==
                                                        true)
                                                ? Colors.white
                                                : Colors.grey)),
                                  )),
                            ],
                          )),
                    ],
                  ))),
        ),
        Expanded(
          child: _buildTreeView(),
        ),
      ],
    );
  }

  Widget _buildTreeView() {
    // _sortedBoardList는 이미 루트 보드만 포함하므로 추가 필터링 불필요
    final rootBoards = _sortedBoardList;

    if (rootBoards.isEmpty) {
      return Container(
        color: const Color(0xFF2D2D30),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 48,
                color: Color(0xFF6A6A6A),
              ),
              SizedBox(height: 16),
              Text(
                '표시할 위젯이 없습니다.',
                style: TextStyle(
                  color: Color(0xFF6A6A6A),
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '새 탭을 생성하여 위젯을 추가해보세요.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6A6A6A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF2D2D30),
      child: ListView.builder(
        itemCount: rootBoards.length,
        itemBuilder: (context, index) {
          final boardId = rootBoards[index];
          return _buildBoardNode(boardId, 0);
        },
      ),
    );
  }

  Widget _buildBoardNode(String boardId, int depth) {
    final controller = homeRepo.hierarchicalControllers[boardId];
    if (controller == null) return const SizedBox.shrink();

    // 컨트롤러가 dispose되었는지 확인
    try {
      // 컨트롤러의 상태를 확인하기 위해 간단한 접근 시도
      final _ = controller.controller.innerData;
    } catch (e) {
      debugPrint(
          '[WidgetTree][_buildBoardNode] 컨트롤러가 dispose됨: $boardId, 오류: $e');
      return const SizedBox.shrink();
    }

    // body_~, subBody_~로 시작하는 보드는 레이아웃 하위에서만 렌더링
    if (boardId.startsWith('body_') || boardId.startsWith('subBody_')) {
      return const SizedBox.shrink();
    }

    // Frame_로 시작하는 보드는 프레임 하위에서만 렌더링 (루트 레벨에서는 표시하지 않음)
    if (boardId.startsWith('Frame_')) {
      return const SizedBox.shrink();
    }

    final isExpanded = _expandedBoards[boardId] ?? false;
    final children = homeRepo.childParentRelations[boardId] ?? [];
    final items = controller.controller.innerData;
    final hasChildren = children.isNotEmpty || items.isNotEmpty;
    final isSelected = selectedBoardId == boardId;
    final hasApis = controller.controller.innerApi.isNotEmpty;

    // 표시할 이름 결정
    String displayName = boardId;
    if (boardId.startsWith('Frame_')) {
      displayName = '프레임';
    } else if (boardId.startsWith('Layout_')) {
      displayName = '레이아웃';
    }

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 16.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedBoardId = boardId;
                });
                homeRepo.selectDockBoardState(boardId);
              },
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF094771) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    if (hasChildren)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedBoards[boardId] = !isExpanded;
                          });
                        },
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: const Color(0xFFCCCCCC),
                          size: 16,
                        ),
                      )
                    else
                      const SizedBox(width: 16),
                    Icon(
                      isExpanded ? Icons.folder_open : Icons.folder,
                      color: Colors.blue.shade400,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                    if (hasApis)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'API',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E3E42),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          // 자식 위젯들(아이템) 표시
          ...items.map((item) => _buildItemNode(item, depth + 1)),
          // Layout 타입: childParentRelations 기반 하위 보드(children) 표시
          if (controller.controller is StackLayoutItem)
            ...children.map((childId) => _buildBoardNode(childId, depth + 1)),
          // Frame 타입: tabsTitle 기반 tab_ 보드만 표시
          if (controller.controller is StackFrameItem)
            ..._buildFrameTabBoards(
                controller.controller as StackFrameItem, depth + 1),
          if (hasApis) ..._buildApiList(boardId, depth + 1),
        ],
      ],
    );
  }

  /// 전체 계층 구조 시각화 (디버깅용)
  void _debugHierarchyStructure() {
    // 디버깅 로그 제거
  }

  /// FrameItem의 tabsTitle에서 하위 보드들을 추출해서 표시 (새로운 ID 시스템 지원)
  List<Widget> _buildFrameTabBoards(StackFrameItem item, int depth) {
    List<Map<String, String>> tabBoards = []; // boardId와 title을 함께 저장

    // tabsTitle이 있으면 파싱하여 보드 생성 (boardId 기반 매칭)
    if (item.content?.toJson()['tabsTitle']?.isNotEmpty == true) {
      try {
        final List<dynamic> tabs =
            jsonDecode(item.content!.toJson()['tabsTitle']!);

        for (final tab in tabs) {
          final boardId = tab['boardId'] as String;
          final tabTitle = tab['title'] as String;

          tabBoards.add({
            'boardId': boardId,
            'title': tabTitle,
          });
        }

        // tabIndex 순서대로 정렬 (표시 순서용)
        tabBoards.sort((a, b) {
          final aIndex = _extractTabIndexFromFrameBoardId(a['boardId']!);
          final bIndex = _extractTabIndexFromFrameBoardId(b['boardId']!);
          return (aIndex ?? 0).compareTo(bIndex ?? 0);
        });
      } catch (e) {
        // tabsTitle 파싱 오류 처리
      }
    }

    // tabsTitle이 비어있으면 childParentRelations에서 추출
    if (tabBoards.isEmpty) {
      // Frame 아이템의 ID를 사용하여 하위 보드들 찾기
      final childBoards = homeRepo.childParentRelations[item.id] ?? [];

      // Frame_xxx_tabIndex 패턴의 보드들만 필터링
      final frameBoards = childBoards.where((boardId) {
        return boardId.startsWith('Frame_');
      }).toList();

      // childParentRelations에서 찾지 못한 경우 hierarchicalControllers에서 직접 검색
      if (frameBoards.isEmpty) {
        final allBoards = homeRepo.hierarchicalControllers.keys.toList();
        final frameChildBoards = allBoards.where((boardId) {
          return boardId.startsWith('Frame_') &&
              boardId.contains('_${item.id.split('_').last}_');
        }).toList();

        for (final boardId in frameChildBoards) {
          // tabIndex 추출하여 제목 생성
          final tabIndex = _extractTabIndexFromFrameBoardId(boardId);
          final title = tabIndex != null ? 'Tab $tabIndex' : boardId;

          tabBoards.add({
            'boardId': boardId,
            'title': title,
          });
        }
      } else {
        for (final boardId in frameBoards) {
          // tabIndex 추출하여 제목 생성
          final tabIndex = _extractTabIndexFromFrameBoardId(boardId);
          final title = tabIndex != null ? 'Tab $tabIndex' : boardId;

          tabBoards.add({
            'boardId': boardId,
            'title': title,
          });
        }
      }
    }

    // Frame 하위 탭 보드들이 실제로 존재하는지 확인
    final existingTabBoards = tabBoards.where((tabInfo) {
      final exists =
          homeRepo.hierarchicalControllers.containsKey(tabInfo['boardId']!);
      return exists;
    }).toList();

    return existingTabBoards.map((tabInfo) {
      return _buildFrameTabBoardNode(
          tabInfo['boardId']!, tabInfo['title']!, depth); // 타이틀 정보 전달
    }).toList();
  }

  /// Frame 탭 보드 전용 노드 빌더 (Frame_id_tabIndex 보드 표시)
  Widget _buildFrameTabBoardNode(
      String boardId, String displayTitle, int depth) {
    final controller = homeRepo.hierarchicalControllers[boardId];
    if (controller == null) return const SizedBox.shrink();

    // 컨트롤러가 dispose되었는지 확인
    try {
      // 컨트롤러의 상태를 확인하기 위해 간단한 접근 시도
      final _ = controller.controller.innerData;
    } catch (e) {
      debugPrint(
          '[WidgetTree][_buildFrameTabBoardNode] 컨트롤러가 dispose됨: $boardId, 오류: $e');
      return const SizedBox.shrink();
    }

    final isExpanded = _expandedBoards[boardId] ?? false;
    final children = homeRepo.childParentRelations[boardId] ?? [];
    final items = controller.controller.innerData;
    final hasChildren = children.isNotEmpty || items.isNotEmpty;
    final isSelected = selectedBoardId == boardId;
    final hasApis = controller.controller.innerApi.isNotEmpty;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 16.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedBoardId = boardId;
                });
                homeRepo.selectDockBoardState(boardId);
              },
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF094771) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    if (hasChildren)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedBoards[boardId] = !isExpanded;
                          });
                        },
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: const Color(0xFFCCCCCC),
                          size: 16,
                        ),
                      )
                    else
                      const SizedBox(width: 16),
                    Icon(
                      isExpanded ? Icons.tab : Icons.tab_unselected,
                      color: Colors.orange.shade400, // Frame 탭 보드는 주황색으로 구분
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        displayTitle, // boardId 대신 displayTitle 사용
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                    if (hasApis)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'API',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E3E42),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          ...items.map((item) => _buildItemNode(item, depth + 1)),
          ...children.map((childId) => _buildBoardNode(childId, depth + 1)),
          if (hasApis) ..._buildApiList(boardId, depth + 1),
        ],
      ],
    );
  }

  Widget _buildItemNode(StackItem item, int depth) {
    final isSelected = selectedItemId == item.id;
    final isExpanded = _expandedItems[item.id] ?? false;
    final hasChildren = _hasChildBoards(item);

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 16.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectItem(item),
              onDoubleTap: () => _editItem(item),
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF094771) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    if (hasChildren)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedItems[item.id] = !isExpanded;
                          });
                        },
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: const Color(0xFFCCCCCC),
                          size: 16,
                        ),
                      )
                    else
                      const SizedBox(width: 16),
                    _getItemIcon(item),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getItemDescription(item),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                    if (hasChildren)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '보드',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 레이아웃 아이템의 경우 하위 보드들을 표시
        if (isExpanded && item is StackLayoutItem) ...[
          ..._buildLayoutChildBoards(item, depth + 1),
        ],
        // 프레임 아이템의 경우 하위 보드들을 표시 (중복 방지: _buildFrameChildBoards 제거)
        if (isExpanded && item is StackFrameItem)
          ..._buildFrameTabBoards(item, depth + 1),
      ],
    );
  }

  List<Widget> _buildLayoutChildBoards(StackLayoutItem item, int depth) {
    final List<Widget> childBoards = [];
    final content = item.content;

    if (content?.reqMenus != null) {
      for (final menu in content!.reqMenus!) {
        // body 보드
        final bodyBoardId = CompactIdGenerator.generateLayoutBoardId(
            item.id, 'body', menu.menuId);
        childBoards.add(
            _buildChildBoardNode(bodyBoardId, depth, '${menu.label}_body'));

        // subBody 보드 (subBody가 'none'이 아닌 경우에만)
        if (content.subBody != null && content.subBody != 'none') {
          final subBodyBoardId = CompactIdGenerator.generateLayoutBoardId(
              item.id, 'subBody', menu.menuId);
          childBoards.add(_buildChildBoardNode(
              subBodyBoardId, depth, '${menu.label}_subBody'));
        }
      }
    }

    return childBoards;
  }

  // 프레임 하위의 탭 보드 리스트를 tabsTitle 기준으로만 추출
  List<String> _getTabBoardIds(StackFrameItem item) {
    final tabsTitle = item.content?.toJson()['tabsTitle'] ?? '';
    if (tabsTitle.isNotEmpty) {
      try {
        List<dynamic> frameTitle = jsonDecode(tabsTitle);
        return frameTitle.map((tab) => tab['boardId'] as String).toList();
      } catch (e) {}
    }
    return [];
  }

  /// 새로운 ID 시스템을 사용한 Frame 보드 ID 생성
  String _generateFrameBoardId(String frameId, int tabIndex) {
    return CompactIdGenerator.generateFrameBoardId(frameId, tabIndex);
  }

  /// Frame_xxx_tabIndex 형태의 boardId에서 tabIndex 추출
  int? _extractTabIndexFromFrameBoardId(String boardId) {
    if (boardId.startsWith('Frame_')) {
      final parts = boardId.split('_');
      if (parts.length >= 3) {
        // 마지막 부분이 tabIndex
        return int.tryParse(parts.last);
      }
    }
    return null;
  }

  Widget _buildFrameChildBoards(StackFrameItem item, int depth) {
    final boardIds = _getTabBoardIds(item);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: boardIds.map((boardId) {
        final controller = homeRepo.hierarchicalControllers[boardId];
        if (controller == null) return const SizedBox.shrink();
        return _buildBoardNode(boardId, depth);
      }).toList(),
    );
  }

  Widget _buildChildBoardNode(String boardId, int depth, String displayName) {
    final controller = homeRepo.hierarchicalControllers[boardId];
    if (controller == null) return const SizedBox.shrink();

    final isExpanded = _expandedBoards[boardId] ?? false;
    final children = homeRepo.childParentRelations[boardId] ?? [];
    final items = controller.controller.innerData;
    final hasChildren = children.isNotEmpty || items.isNotEmpty;
    final isSelected = selectedBoardId == boardId;
    final hasApis = controller.controller.innerApi.isNotEmpty;

    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 16.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedBoardId = boardId;
                });
                homeRepo.selectDockBoardState(boardId);
              },
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color:
                      isSelected ? const Color(0xFF094771) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    if (hasChildren)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedBoards[boardId] = !isExpanded;
                          });
                        },
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_right,
                          color: const Color(0xFFCCCCCC),
                          size: 16,
                        ),
                      )
                    else
                      const SizedBox(width: 16),
                    Icon(
                      isExpanded ? Icons.folder_open : Icons.folder,
                      color: Colors.green.shade400,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? const Color(0xFFFFFFFF)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                    if (hasApis)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'API',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E3E42),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFCCCCCC),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          ...items.map((item) => _buildItemNode(item, depth + 1)),
          ...children.map((childId) => _buildBoardNode(childId, depth + 1)),
          if (hasApis) ..._buildApiList(boardId, depth + 1),
        ],
      ],
    );
  }

  bool _hasChildBoards(StackItem item) {
    if (item is StackLayoutItem) {
      // 레이아웃 아이템의 경우 reqMenus가 있으면 하위 보드가 있음
      final content = item.content;
      return content?.reqMenus != null && content!.reqMenus!.isNotEmpty;
    } else if (item is StackFrameItem) {
      // 프레임 아이템의 경우 하위 보드가 있을 수 있음
      // Frame 아이템의 boardId를 키로 사용해야 함
      final childBoards = homeRepo.childParentRelations[item.boardId] ?? [];
      // Frame_xxx_tabIndex 패턴의 보드들만 필터링
      final frameTabBoards = childBoards.where((boardId) {
        return boardId.startsWith('Frame_');
      }).toList();
      return frameTabBoards.isNotEmpty;
    }
    return false;
  }

  Widget _getItemIcon(StackItem item) {
    IconData iconData;
    Color iconColor;

    if (item is StackTextItem) {
      iconData = Icons.text_fields;
      iconColor = Colors.blue.shade400;
    } else if (item is StackImageItem) {
      iconData = Icons.image;
      iconColor = Colors.green.shade400;
    } else if (item is StackButtonItem) {
      iconData = Icons.smart_button;
      iconColor = Colors.orange.shade400;
    } else if (item is StackSearchItem) {
      iconData = Icons.search;
      iconColor = Colors.purple.shade400;
    } else if (item is StackGridItem) {
      iconData = Icons.grid_on;
      iconColor = Colors.red.shade400;
    } else if (item is StackLayoutItem) {
      iconData = Icons.view_agenda;
      iconColor = Colors.indigo.shade400;
    } else if (item is StackFrameItem) {
      iconData = Icons.crop_square;
      iconColor = Colors.teal.shade400;
    } else if (item is StackChartItem) {
      iconData = Icons.bar_chart;
      iconColor = Colors.amber.shade400;
    } else if (item is StackDetailItem) {
      iconData = Icons.details;
      iconColor = Colors.cyan.shade400;
    } else if (item is StackTemplateItem) {
      iconData = Icons.description;
      iconColor = Colors.brown.shade400;
    } else {
      iconData = Icons.widgets;
      iconColor = const Color(0xFFCCCCCC);
    }

    return Icon(iconData, color: iconColor, size: 14);
  }

  String _getItemDescription(StackItem item) {
    if (item is StackTextItem) {
      final data = item.content?.data ?? '';
      return data.isNotEmpty
          ? data.substring(0, data.length > 20 ? 20 : data.length)
          : '빈 텍스트';
    }
    if (item is StackImageItem) {
      final url = item.content?.url ?? '';
      final assetName = item.content?.assetName ?? '';
      return (url.isNotEmpty || assetName.isNotEmpty) ? '이미지' : '빈 이미지';
    }
    if (item is StackButtonItem) {
      final buttonName = item.content?.buttonName ?? '';
      return buttonName.isNotEmpty ? buttonName : '버튼';
    }
    if (item is StackSearchItem) {
      final buttonName = item.content?.buttonName ?? '';
      return buttonName.isNotEmpty ? buttonName : '검색';
    }
    if (item is StackGridItem) {
      final headerTitle = item.content?.headerTitle ?? '';
      return headerTitle.isNotEmpty ? headerTitle : '그리드';
    }
    if (item is StackLayoutItem) {
      final title = item.content?.title ?? '';
      return title.isNotEmpty ? title : '레이아웃';
    }
    if (item is StackFrameItem) {
      return '프레임';
    }
    if (item is StackChartItem) {
      return '차트';
    }
    if (item is StackDetailItem) {
      return '상세';
    }
    if (item is StackTemplateItem) {
      final templateNm = item.content?.templateNm ?? '';
      return templateNm.isNotEmpty ? templateNm : '템플릿';
    }
    return '위젯';
  }

  void _selectItem(StackItem item) {
    setState(() {
      selectedItemId = item.id;
    });

    homeRepo.selectDockBoardState(item.boardId);

    final controller = homeRepo.hierarchicalControllers[item.boardId];
    if (controller != null) {
      controller.controller.selectOne(item.id);
      homeRepo.addOnTapState(item);
    }
  }

  void _editItem(StackItem item) {
    homeRepo.selectDockBoardState(item.boardId);
    final controller = homeRepo.hierarchicalControllers[item.boardId];
    if (controller != null) {
      controller.controller.selectOne(item.id);
      final updatedItem = item.copyWith(status: StackItemStatus.editing);
      controller.controller.updateItem(updatedItem);
    }
  }

  List<Widget> _buildApiList(String boardId, int depth) {
    final controller = homeRepo.hierarchicalControllers[boardId];
    if (controller == null || controller.controller.innerApi.isEmpty) {
      return [];
    }

    return controller.controller.innerApi.entries.map((entry) {
      final apiId = entry.key;
      final apiData = entry.value;
      final apiName = apiData['apiNm'] ?? apiId;

      return Container(
        margin: EdgeInsets.only(left: depth * 16.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final dialog = ApiPopupDialog(
                context: context,
                homeRepo: homeRepo,
              );

              await dialog.showApiDialog(apiId: apiId);
            },
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.api,
                    color: Colors.orange.shade400,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'API / $apiName',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      apiId,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
