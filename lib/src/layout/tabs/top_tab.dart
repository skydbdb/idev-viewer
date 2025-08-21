import 'package:flutter/widgets.dart';
import 'package:pluto_layout/pluto_layout.dart';

class TopTab extends StatelessWidget {
  const TopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PlutoLayoutTabs(
      draggable: true,
    );
  }
}
