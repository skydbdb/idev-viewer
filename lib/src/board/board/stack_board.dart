import 'package:flutter/material.dart';
import 'package:idev_v1/src/board/stack_item_case/config_builder.dart';
import '/src/board/stack_item_case/stack_item_case.dart';
import '/src/board/widgets/ex_builder.dart';

import '/src/board/core/case_style.dart';
import '/src/board/core/stack_board_controller.dart';
import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/core/alignment_guide_painter.dart';

class StackBoardConfig extends InheritedWidget {
  const StackBoardConfig({
    super.key,
    required this.controller,
    this.caseStyle,
    required super.child,
  });

  final StackBoardController controller;
  final CaseStyle? caseStyle;

  static StackBoardConfig of(BuildContext context) {
    final StackBoardConfig? result =
        context.dependOnInheritedWidgetOfExactType<StackBoardConfig>();
    assert(result != null, 'No StackBoardConfig found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(covariant StackBoardConfig oldWidget) =>
      oldWidget.controller != controller || oldWidget.caseStyle != caseStyle;
}

class StackBoard extends StatefulWidget {
  const StackBoard({
    super.key,
    required this.id,
    required this.controller,
    this.background,
    this.caseStyle,
    this.customBuilder,
    this.onMenu,
    this.onDock,
    this.onDel,
    this.onTap,
    this.onSizeChanged,
    this.onOffsetChanged,
    this.onAngleChanged,
    this.onStatusChanged,
    this.actionsBuilder,
    this.borderBuilder,
  });

  final String id;
  final StackBoardController controller;
  final Widget? background;
  final CaseStyle? caseStyle;

  final Widget? Function(StackItem<StackItemContent> item)? customBuilder;
  final void Function(String menu)? onMenu;
  final void Function(StackItem<StackItemContent> item)? onDock;
  final void Function(StackItem<StackItemContent> item)? onDel;
  final void Function(StackItem<StackItemContent> item)? onTap;
  final bool? Function(StackItem<StackItemContent> item, Size size)?
      onSizeChanged;

  final bool? Function(StackItem<StackItemContent> item, Offset offset)?
      onOffsetChanged;

  final bool? Function(StackItem<StackItemContent> item, double angle)?
      onAngleChanged;

  final bool? Function(
          StackItem<StackItemContent> item, StackItemStatus operatState)?
      onStatusChanged;

  final Widget Function(StackItemStatus operatState, CaseStyle caseStyle)?
      actionsBuilder;

  final Widget Function(StackItemStatus operatState)? borderBuilder;

  @override
  State<StackBoard> createState() => _StackBoardState();
}

class _StackBoardState extends State<StackBoard> {
  StackBoardController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StackBoardConfig(
      controller: _controller,
      caseStyle: widget.caseStyle,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ExBuilder<StackConfig>(
            valueListenable: _controller,
            shouldRebuild: (StackConfig p, StackConfig n) =>
                p.indexMap != n.indexMap || p.data.asMap() != n.data.asMap(),
            builder: (StackConfig sc) {
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const SizedBox.expand(),
                  if (widget.background != null) widget.background!,
                  ...sc.data.map((item) => _itemBuilder(item)),
                  ..._controller.currentGuides.map((g) => Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: AlignmentGuidePainter(guide: g),
                          ),
                        ),
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _itemBuilder(StackItem<StackItemContent> item) {
    return StackItemCase(stackItem: item, childBuilder: widget.customBuilder);
  }
}
