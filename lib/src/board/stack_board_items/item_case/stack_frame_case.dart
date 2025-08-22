import 'dart:async';
import 'dart:convert';

import 'package:docking/docking.dart';
import 'package:flutter/material.dart';
import '/src/board/board/dock_board.dart';
import '/src/board/stack_items.dart';
import '/src/board/helpers/compact_id_generator.dart';

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
  late Map<String, double> weights;
  late List<String> boardIds;
  late TabbedViewThemeData tabbedViewThemeData;
  bool tabsVisible = true;
  double dividerThickness = 6;
  late StackFrameItem currentItem;

  @override
  void initState() {
    super.initState();
    currentItem = widget.item;

    _initializeLayout().then((_) {
      _loadFrameContent();
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
    _updateLayoutAreas();
  }

  void _loadFrameSettings(Map<String, dynamic> itemContent) {
    tabsVisible = bool.tryParse(itemContent['tabsVisible'].toString()) ?? true;
    dividerThickness =
        double.tryParse(itemContent['dividerThickness'].toString()) ?? 6;

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

  void _updateLayoutAreas() {
    try {
      layout.layoutAreas().forEach((e) {
        if (e is DockingItem) {
          final actualBoardId = _getBoardIdForTabIndex(e.id);
          final newTitle = _getTabTitle(actualBoardId);
          if (e.name != newTitle) {
            e.name = newTitle;
          }
        }
      });

      layout.rebuild();
    } catch (e) {
      // 레이아웃 업데이트 실패 시 무시
    }
  }

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

            if (type == 'I' && isTab == '1' && tabIndex != null) {
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

  int _getTabIndexForBoardId(String boardId) {
    if (boardId.startsWith('Frame_')) {
      final parts = boardId.split('_');
      if (parts.length >= 3) {
        final tabIndex = int.tryParse(parts.last);
        if (tabIndex != null) {
          return tabIndex;
        }
      }
    }

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

  String _getBoardIdForTabIndex(int tabIndex) {
    return CompactIdGenerator.generateFrameBoardId(widget.item.id, tabIndex);
  }

  String _getTabTitle(String boardId) {
    final tabIndex = _getTabIndexForBoardId(boardId);
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
    return 'Tab $tabIndex';
  }

  DockingItem _createDockingItem(dynamic id, {bool flag = false}) {
    try {
      final index = id is int ? id : int.tryParse(id.toString());
      if (index == null) {
        throw Exception('Invalid tab index: $id');
      }

      final boardId =
          CompactIdGenerator.generateFrameBoardId(currentItem.id, index);
      final parentId = currentItem.id;

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

      return DockingItem(
        keepAlive: true,
        id: index,
        name: tabTitle,
        widget: KeyedSubtree(
          key: ValueKey('frame_${currentItem.id}_$index'),
          child: DockBoard(
            id: boardId,
            parentId: parentId,
          ),
        ),
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
      );
    }
  }

  @override
  String idToString(dynamic id) {
    if (id == null) {
      return '';
    }

    final result = id.toString();
    return result;
  }

  @override
  dynamic stringToId(String id) {
    if (id.isEmpty) {
      return null;
    }

    try {
      final result = int.parse(id);
      return result;
    } catch (e) {
      return null;
    }
  }

  @override
  DockingItem buildDockingItem({
    required dynamic id,
    required bool maximized,
    required double? weight,
  }) {
    return _createDockingItem(id, flag: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = TabbedViewThemeData.mobile();
    themeData.tabsArea.visible = tabsVisible;

    try {
      return MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
            dividerThickness: dividerThickness,
          ),
          child: TabbedViewTheme(
            data: themeData,
            child: docking,
          ));
    } catch (e) {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
