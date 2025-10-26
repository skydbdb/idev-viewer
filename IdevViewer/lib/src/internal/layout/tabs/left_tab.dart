import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/layout/menus/api/api_menu.dart';
import 'package:idev_viewer/src/internal/layout/menus/table_list/table_list.dart';
import 'package:idev_viewer/src/internal/layout/menus/file_explorer/file_explorer.dart';
import 'package:pluto_layout/pluto_layout.dart';

class LeftTab extends StatefulWidget {
  const LeftTab({super.key});

  @override
  State<LeftTab> createState() => _LeftTabState();
}

class _LeftTabState extends State<LeftTab> {
  @override
  Widget build(BuildContext context) {
    return PlutoLayoutTabs(
      draggable: true,
      mode: PlutoLayoutTabMode.showSelected,
      tabViewSizeResolver:
          const PlutoLayoutTabViewSizeConstrains(minSize: 50, initialSize: 300),
      items: [
        PlutoLayoutTabItem(
          id: 'fileExplorer',
          title: '파일서버',
          tabViewWidget: const FileExplorer(),
          sizeResolver: PlutoLayoutTabItemSizeInitial(
              MediaQuery.sizeOf(context).height * 0.3),
        ),
        PlutoLayoutTabItem(
          id: 'tableList',
          title: '데이터베이스',
          tabViewWidget: const TableList(),
          sizeResolver: PlutoLayoutTabItemSizeInitial(
              MediaQuery.sizeOf(context).height * 0.3),
        ),
        PlutoLayoutTabItem(
          id: 'api',
          title: 'API',
          tabViewWidget: const ApiMenu(),
          sizeResolver: PlutoLayoutTabItemSizeInitial(
              MediaQuery.sizeOf(context).height * 0.4),
        )
      ],
    );
  }
}
