import 'package:flutter/widgets.dart';
import 'package:pluto_layout/pluto_layout.dart';

class LeftTab extends StatelessWidget {
  const LeftTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PlutoLayoutTabs(
      draggable: true,
    );
  }
}
