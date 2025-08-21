import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/board/board/viewer/template_viewer.dart';
import 'package:idev_v1/src/repo/home_repo.dart';
import 'package:pluto_layout/pluto_layout.dart';
import '/src/model/menu.dart';

PlutoInsertTabItemResult newTabResolver(
    {required List<PlutoLayoutTabItem> items, Menu? menu}) {
  Menu tabMenu = Menu.fromJson(menu?.toJson() ?? {});

  // if new
  if (tabMenu.menuId == 0) {
    final foundNew = items
        .where((e) => e.id.toString().startsWith('new_'))
        .map((e) => int.parse(e.id.toString().replaceAll('new_', '')))
        .toList()
      ..sort();

    int newIndex = foundNew.isEmpty ? 1 : ++foundNew.last;
    tabMenu = tabMenu.copyWith(menuId: newIndex, menuNm: 'new_$newIndex');
  }

  // 키 생성 및 로깅 (GlobalKey 충돌 추적)
  final tabKey = GlobalObjectKey('NewTab_${tabMenu.menuId}_${tabMenu.menuNm}');

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

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    homeRepo.tabs[widget.menu.menuNm ?? 'new_${widget.menu.menuId}'] =
        widget.menu;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.menu.menuId) {
      _ => (() {
          final boardId = widget.menu.menuNm ?? 'new_${widget.menu.menuId}';

          // 최상위 컨트롤러 생성 (부모 없음)
          homeRepo.createHierarchicalController(boardId, null);

          return TemplateViewer(
            boardId: boardId,
          );
        })()
    };
  }
}
