import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';
import 'package:pluto_layout/pluto_layout.dart';
import '../../board/board/dock_board.dart';
import '../../pms/model/menu.dart';

PlutoInsertTabItemResult newTabResolver(
    {required List<PlutoLayoutTabItem> items, Menu? menu}) {
  Menu tabMenu = Menu.fromJson(menu?.toJson() ?? {});

  // if new
  if (tabMenu.menuId == 0) {
    debugPrint('before newTabResolver: ${tabMenu.toJson()}');
    final foundNew = items
        .where((e) => e.id.toString().startsWith('new_'))
        .map((e) => int.parse(e.id.toString().replaceAll('new_', '')))
        .toList()
      ..sort();

    int newIndex = foundNew.isEmpty ? 1 : ++foundNew.last;
    tabMenu = tabMenu.copyWith(menuId: newIndex, menuNm: 'new_$newIndex');
    debugPrint('after newTabResolver: ${tabMenu.toJson()}');
  }

  // 키 생성 및 로깅 (GlobalKey 충돌 추적)
  final String keyLabel = 'NewTab_${tabMenu.menuId}_${tabMenu.menuNm}';
  final tabKey = GlobalObjectKey(keyLabel);
  debugPrint(
      '[newTabResolver] create tab: id=${tabMenu.menuId}, name=${tabMenu.menuNm}, keyLabel=$keyLabel, keyHash=${identityHashCode(tabKey)}');

  return PlutoInsertTabItemResult(
    item: PlutoLayoutTabItem(
      id: tabMenu.menuNm ?? 'new_${tabMenu.menuId}',
      title: tabMenu.menuNm ?? 'new_${tabMenu.menuId}',
      enabled: false,
      showRemoveButton: true,
      tabViewWidget: NewTab(
        key: tabKey,
        focusNode: FocusNode(),
        menu: tabMenu,
      ),
    ),
  );
}

class NewTab extends StatefulWidget
    implements PlutoLayoutTabViewWidgetHasFocusNode {
  const NewTab({
    required this.focusNode,
    required this.menu,
    super.key,
  });

  final Menu menu;

  @override
  final FocusNode focusNode;

  @override
  State<NewTab> createState() => NewTabState();
}

class NewTabState extends State<NewTab> {
  late HomeRepo homeRepo;

  // 간단한 런타임 중복 키 레지스트리 (디버깅용)
  static final Set<String> _allocatedKeyLabels = <String>{};

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    homeRepo.tabs[widget.menu.menuNm ?? 'new_${widget.menu.menuId}'] =
        widget.menu;

    final keyStr = widget.key?.toString() ?? 'null';
    debugPrint(
        '[NewTab.initState] menuId=${widget.menu.menuId}, menuNm=${widget.menu.menuNm}, key=$keyStr');
    // 중복 키 문자열 감지
    if (keyStr != 'null') {
      if (_allocatedKeyLabels.contains(keyStr)) {
        debugPrint(
            '[NewTab.initState][DUPLICATE-KEY] key=$keyStr already allocated');
      } else {
        _allocatedKeyLabels.add(keyStr);
      }
    }
  }

  @override
  void dispose() {
    final keyStr = widget.key?.toString() ?? 'null';
    if (keyStr != 'null') {
      _allocatedKeyLabels.remove(keyStr);
    }
    debugPrint(
        '[NewTab.dispose] menuId=${widget.menu.menuId}, menuNm=${widget.menu.menuNm}, key=$keyStr');
    widget.focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.menu.menuId) {
      _ => (() {
          final boardId = widget.menu.menuNm ?? 'new_${widget.menu.menuId}';

          // 최상위 컨트롤러 생성 (부모 없음)
          homeRepo.createHierarchicalController(boardId, null);

          return DockBoard(
            id: boardId,
            focusNode: widget.focusNode,
          );
        })()
    };
  }
}
