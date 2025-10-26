import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import 'package:idev_viewer/src/internal/layout/menus/property/property.dart';
import 'package:idev_viewer/src/internal/layout/menus/widget_tree/widget_tree.dart';
import 'package:pluto_layout/pluto_layout.dart';
import '../menus/template/template_menu.dart';

import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_content.dart';

class RightTab extends StatefulWidget {
  const RightTab({super.key});

  @override
  State<RightTab> createState() => _RightTabState();
}

class _RightTabState extends State<RightTab> {
  late PlutoLayoutEventStreamController? eventStreamController;
  StackItem<StackItemContent>? item;

  @override
  void initState() {
    eventStreamController = PlutoLayout.getEventStreamController(context);
    eventStreamController?.listen((tab) {
      if (tab is PlutoToggleTabViewEvent &&
          tab.layoutId == PlutoLayoutId.right) {
        print('listen rightTab: ${tab.layoutId}');
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PlutoLayoutTabs(
      draggable: true,
      mode: PlutoLayoutTabMode.showSelected,
      tabViewSizeResolver:
          const PlutoLayoutTabViewSizeConstrains(minSize: 50, initialSize: 300),
      items: [
        PlutoLayoutTabItem(
          id: 'template',
          title: '템플릿',
          tabViewWidget: const TemplateMenu(),
          sizeResolver: PlutoLayoutTabItemSizeInitial(
              MediaQuery.sizeOf(context).height * 0.3),
        ),
        if (BuildMode.isEditor) ...[
          PlutoLayoutTabItem(
            id: 'widgetTree',
            title: '위젯트리',
            tabViewWidget: const WidgetTree(),
            sizeResolver: PlutoLayoutTabItemSizeInitial(
                MediaQuery.sizeOf(context).height * 0.3),
          ),
          PlutoLayoutTabItem(
            id: 'property',
            title: '속성',
            tabViewWidget: const Property(),
            sizeResolver: PlutoLayoutTabItemSizeInitial(
                MediaQuery.sizeOf(context).height * 0.4),
          ),
        ]
      ],
    );
  }
}
