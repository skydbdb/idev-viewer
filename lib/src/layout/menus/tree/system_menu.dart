import 'package:flutter/material.dart';
import 'package:animated_tree_view/animated_tree_view.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pluto_layout/pluto_layout.dart';
import '/src/model/menu.dart';
import '../../../repo/home_repo.dart';

class SystemMenu extends StatefulWidget {
  const SystemMenu({required this.menuTree, super.key});

  final TreeNode menuTree;

  @override
  State<SystemMenu> createState() => _SystemMenuState();
}

class _SystemMenuState extends State<SystemMenu> {
  bool isLoaded = false;
  Map<String, dynamic> isSelected = {};
  late Menu menu;
  late TreeNode menuTree;
  late HomeRepo homeRepo;

  @override
  void initState() {
    homeRepo = context.read<HomeRepo>();
    menuTree = widget.menuTree;
    setState(() => isLoaded = true);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !isLoaded
        ? const SizedBox()
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 300,
              height: 900,
              child: Theme(
                  data: ThemeData.dark(),
                  child: Container(
                    color: ThemeData.dark().highlightColor,
                    child: TreeView.simple(
                        tree: menuTree,
                        showRootNode: false,
                        padding: const EdgeInsets.all(0),
                        expansionIndicatorBuilder: (context, node) =>
                            ChevronIndicator.upDown(
                              tree: node,
                              alignment: Alignment.topLeft,
                              padding: const EdgeInsets.only(left: 0),
                            ),
                        indentation:
                            const Indentation(style: IndentStyle.roundJoint),
                        onItemTap: (item) {
                          // if (kDebugMode)
                          // print("Item tapped: ${item.key}");
                          setState(() {
                            isSelected.clear();
                            isSelected[item.key] = true;
                          });

                          if (item.children.isNotEmpty) return;

                          menu = item.data as Menu;
                          if (homeRepo.tabs.keys
                              .contains('menu_${menu.menuId}')) {
                            print('exist menu-->');
                            homeRepo.eventStreamController?.add(
                                PlutoToggleTabViewEvent(
                                    layoutId: PlutoLayoutId.body,
                                    itemId: 'menu_${menu.menuId}'));
                          } else {
                            homeRepo.addTabItemState(menu);
                          }

                          homeRepo.addLeftMenuState(menu);
                        },
                        onTreeReady: (controller) {
                          controller.expandNode(menuTree); //최상위 메뉴 열기 초기 상태
                        },
                        builder: (context, node) => Padding(
                              padding: const EdgeInsets.only(
                                  left: 25, top: 0, bottom: 0, right: 0),
                              child: Tooltip(
                                message: 'id: ${node.key}',
                                waitDuration: const Duration(seconds: 3),
                                child: Row(
                                  children: [
                                    Icon(
                                        node.children.isEmpty
                                            ? Icons.text_snippet_outlined
                                            : node.isExpanded
                                                ? Icons.folder_open
                                                : Icons.folder,
                                        color: isSelected[node.key] ?? false
                                            ? ThemeData.dark()
                                                .primaryIconTheme
                                                .color
                                            : ThemeData.dark()
                                                .unselectedWidgetColor),
                                    Text(
                                      node.level == 0
                                          ? '전체 메뉴'
                                          : '${(node.data as Menu).menuNm}',
                                      style: TextStyle(
                                          fontWeight:
                                              isSelected[node.key] ?? false
                                                  ? FontWeight.bold
                                                  : null,
                                          color: isSelected[node.key] ?? false
                                              ? ThemeData.dark()
                                                  .textSelectionTheme
                                                  .selectionColor
                                              : null),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                  )),
            ));
  }
}
