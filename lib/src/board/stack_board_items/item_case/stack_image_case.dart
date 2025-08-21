import 'dart:async';

import 'package:flutter/material.dart';
import '/src/board/flutter_stack_board.dart';
import '/src/di/service_locator.dart';
import '/src/repo/app_streams.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/stack_board_items/items/stack_image_item.dart';

class StackImageCase extends StatefulWidget {
  const StackImageCase({
    super.key,
    required this.item,
  });

  final StackImageItem item;

  @override
  State<StackImageCase> createState() => _StackImageCaseState();
}

class _StackImageCaseState extends State<StackImageCase> {
  late AppStreams appStreams;
  late StreamSubscription _updateStackItemSub;
  late ImageItemContent content;
  StackBoardController _controller(BuildContext context) =>
      StackBoardConfig.of(context).controller;

  @override
  void initState() {
    super.initState();
    appStreams = sl<AppStreams>();
    content = widget.item.content!;
    _subscribeUpdateStackItem();
  }

  void _subscribeUpdateStackItem() {
    _updateStackItemSub = appStreams.updateStackItemStream.listen((v) {
      if (v?.id == widget.item.id &&
          v is StackImageItem &&
          v.boardId == widget.item.boardId) {
        final StackImageItem item = v;
        setState(() {
          content = item.content!;
        });
      }
    });
  }

  @override
  void dispose() {
    _updateStackItemSub.cancel();
    super.dispose();
  }

  Color colorByName(String value) {
    return switch (value) {
      'transparent' => Colors.transparent,
      'red' => Colors.red,
      'green' => Colors.green,
      'blue' => Colors.blue,
      'yellow' => Colors.yellow,
      _ => Colors.transparent
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.item.status == StackItemStatus.editing
        ? TextFormField(
            initialValue: widget.item.content?.url,
            onChanged: (String url) {
              final item = widget.item
                  .copyWith(content: widget.item.content?.copyWith(url: url));
              _controller(context).updateItem(item);
            },
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: content.image,
                fit: content.fit,
                color: colorByName(content.color!),
                colorBlendMode: content.colorBlendMode,
                repeat: content.repeat,
              ),
            ],
          );
  }
}
