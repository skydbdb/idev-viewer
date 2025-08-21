import 'package:flutter/material.dart';
import '/src/board/stack_board_item.dart';
import '/src/board/stack_item_case/config_builder.dart';

class StackItemCase extends StatefulWidget {
  const StackItemCase(
      {super.key, required this.stackItem, required this.childBuilder});

  /// * StackItemData
  final StackItem<StackItemContent> stackItem;

  /// * Child builder, update when item status changed
  final Widget? Function(StackItem<StackItemContent> item)? childBuilder;

  @override
  State<StatefulWidget> createState() {
    return _StackItemCaseState();
  }
}

class _StackItemCaseState extends State<StackItemCase> {
  String get itemId => widget.stackItem.id;

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
    return ConfigBuilder.withItem(
      itemId,
      shouldRebuild:
          (StackItem<StackItemContent> p, StackItem<StackItemContent> n) {
        return p.offset != n.offset ||
            p.angle != n.angle ||
            p.size != n.size ||
            p.dock != n.dock ||
            p.padding != n.padding ||
            p.content != n.content ||
            p.status != n.status;
      },
      childBuilder: (StackItem<StackItemContent> item, Widget c) {
        return item.dock
            ? Positioned.fill(
                child: Padding(
                    padding: item.padding,
                    child: widget.childBuilder?.call(item) ??
                        const SizedBox.shrink()),
              )
            : Positioned(
                key: ValueKey<String>(
                    '${item.id}${item.padding.hashCode}${item.dock}'),
                top: item.offset.dy,
                left: item.offset.dx,
                child: Transform.rotate(angle: item.angle, child: c),
              );
      },
      child: ConfigBuilder.withItem(
        itemId,
        shouldRebuild:
            (StackItem<StackItemContent> p, StackItem<StackItemContent> n) =>
                p.status != n.status || p.content != n.content,
        childBuilder: (StackItem<StackItemContent> item, Widget c) {
          return _content(context, item);
        },
        child: const SizedBox.shrink(),
      ),
    );
  }

  /// * Child component
  Widget _content(BuildContext context, StackItem<StackItemContent> item) {
    final Widget content = Padding(
        padding: item.padding,
        child: widget.childBuilder?.call(item) ?? const SizedBox.shrink());

    return ConfigBuilder.withItem(
      itemId,
      shouldRebuild:
          (StackItem<StackItemContent> p, StackItem<StackItemContent> n) {
        return p.size != n.size ||
            p.padding != n.padding ||
            p.status != n.status ||
            p.content?.toJson().toString() != n.content?.toJson().toString();
      },
      childBuilder: (StackItem<StackItemContent> item, Widget c) {
        return Padding(
            padding: EdgeInsets.zero, // status와 무관하게 항상 0
            child: SizedBox.fromSize(size: item.size, child: c));
      },
      child: content,
    );
  }
}
