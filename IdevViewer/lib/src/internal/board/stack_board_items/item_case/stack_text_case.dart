import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';
import 'package:idev_viewer/src/internal/board/flutter_stack_board.dart';
import 'package:idev_viewer/src/internal/repo/app_streams.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import 'package:idev_viewer/src/internal/theme/theme_field.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_status.dart';
import 'package:idev_viewer/src/internal/board/stack_board_items/items/stack_text_item.dart';

class StackTextCase extends StatefulWidget {
  const StackTextCase({
    super.key,
    required this.item,
    this.decoration,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.textAlignVertical,
    this.controller,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onTap,
    this.readOnly = false,
    this.autofocus = true,
    this.obscureText = false,
    this.maxLines,
    this.inputFormatters,
    this.focusNode,
    this.enabled = true,
  });

  final StackTextItem item;
  final InputDecoration? decoration;
  final TextEditingController? controller;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final TextAlignVertical? textAlignVertical;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final Function()? onEditingComplete;
  final Function()? onTap;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool enabled;

  final TextCapitalization textCapitalization;

  TextItemContent? get content => item.content;

  @override
  State<StackTextCase> createState() => _StackTextCaseState();
}

class _StackTextCaseState extends State<StackTextCase> {
  AppStreams? appStreams;
  late StreamSubscription _updateStackItemSub;
  late TextItemContent content;
  StackBoardController _controller(BuildContext context) =>
      StackBoardConfig.of(context).controller;

  @override
  void initState() {
    super.initState();
    // 뷰어 모드에서는 AppStreams 사용하지 않음
    if (BuildMode.isEditor) {
      appStreams = sl<AppStreams>();
    }
    content = widget.item.content!;
    _subscribeUpdateStackItem();
  }

  void _subscribeUpdateStackItem() {
    // 뷰어 모드에서는 구독하지 않음
    if (BuildMode.isViewer || appStreams == null) {
      return;
    }

    _updateStackItemSub = appStreams!.updateStackItemStream.listen((v) {
      if (v?.id == widget.item.id &&
          v is StackTextItem &&
          v.boardId == widget.item.boardId) {
        final StackTextItem item = v;
        setState(() {
          content = item.content!;
        });
      }
    });
  }

  @override
  void dispose() {
    // 뷰어 모드에서는 구독이 없을 수 있음
    if (BuildMode.isEditor && appStreams != null) {
      _updateStackItemSub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.item.status == StackItemStatus.editing
            ? _buildEditing(context)
            : _buildNormal(context),
      ],
    );
  }

  /// * Text
  Widget _buildNormal(BuildContext context) {
    return FittedBox(
      child: Text(
        content.data ?? '',
        style: fieldStyle(widget.item.theme, 'textStyle'),
        strutStyle: content.strutStyle?.style,
        textAlign: content.textAlign,
        textDirection: content.textDirection,
        softWrap: content.softWrap,
        overflow: content.overflow,
        textScaler: content.textScaleFactor != null
            ? TextScaler.linear(content.textScaleFactor!)
            : TextScaler.noScaling,
        maxLines: content.maxLines,
        semanticsLabel: content.semanticsLabel,
        textWidthBasis: content.textWidthBasis,
      ),
    );
  }

  /// * TextFormField
  Widget _buildEditing(BuildContext context) {
    return Center(
      child: TextFormField(
        initialValue: content.data,
        style: fieldStyle(widget.item.theme, 'textStyle'),
        strutStyle: content.strutStyle?.style,
        textAlign: content.textAlign ?? TextAlign.start,
        textDirection: content.textDirection,
        maxLines: content.maxLines,
        decoration: widget.decoration,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction,
        textAlignVertical: widget.textAlignVertical,
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        readOnly: widget.readOnly,
        obscureText: widget.obscureText,
        maxLength: widget.maxLength,
        onChanged: (String str) {
          content = content.copyWith(data: str);
          final item = widget.item.copyWith(content: content);
          _controller(context).updateItem(item);
        },
        onTap: widget.onTap,
        onEditingComplete: widget.onEditingComplete,
        inputFormatters: widget.inputFormatters,
        enabled: widget.enabled,
      ),
    );
  }
}
