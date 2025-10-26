import 'package:flutter/material.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_controller.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_content.dart';
import 'package:idev_viewer/src/internal/board/board/stack_board.dart';
import 'package:idev_viewer/src/internal/board/widgets/ex_builder.dart';

export '/src/internal/board/core/stack_board_controller.dart';

/// Config Builder
class ConfigBuilder extends StatelessWidget {
  const ConfigBuilder({
    super.key,
    this.shouldRebuild,
    this.childBuilder,
    required this.child,
  });

  final bool Function(StackConfig p, StackConfig n)? shouldRebuild;
  final Widget Function(StackConfig sc, Widget c)? childBuilder;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExBuilder<StackConfig>.child(
      valueListenable: StackBoardConfig.of(context).controller,
      shouldRebuild: shouldRebuild,
      childBuilder: childBuilder,
      child: child,
    );
  }

  static Widget withItem(
    String id, {
    required Widget child,
    bool Function(StackItem<StackItemContent> p, StackItem<StackItemContent> n)?
        shouldRebuild,
    Widget Function(StackItem<StackItemContent> item, Widget c)? childBuilder,
  }) {
    return ConfigBuilder(
      shouldRebuild: (StackConfig p, StackConfig n) {
        try {
          // 아이템이 존재하는지 안전하게 확인
          if (!p.indexMap.containsKey(id) || !n.indexMap.containsKey(id)) {
            return true; // 아이템이 존재하지 않으면 리빌드
          }
          final StackItem<StackItemContent> pI = p[id];
          final StackItem<StackItemContent> nI = n[id];
          return shouldRebuild?.call(pI, nI) ?? true;
        } catch (e) {
          return true;
        }
      },
      childBuilder: (StackConfig sc, Widget c) {
        // 아이템이 존재하는지 안전하게 확인
        if (!sc.indexMap.containsKey(id)) {
          return const SizedBox.shrink(); // 아이템이 존재하지 않으면 아무것도 렌더링하지 않음
        }
        final StackItem<StackItemContent> item = sc[id];
        return childBuilder?.call(item, c) ?? c;
      },
      child: child,
    );
  }
}
