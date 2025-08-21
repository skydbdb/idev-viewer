import 'package:flutter/material.dart';
import 'package:pluto_layout/pluto_layout.dart';
import '../menus/template/template_menu.dart';

class RightTab extends StatefulWidget {
  const RightTab({super.key});

  @override
  State<RightTab> createState() => _RightTabState();
}

class _RightTabState extends State<RightTab> {
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
        )
      ],
    );
  }
}
