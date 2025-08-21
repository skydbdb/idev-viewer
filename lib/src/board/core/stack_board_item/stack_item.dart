import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:idev_v1/src/const/code.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';

import 'stack_item_content.dart';
import 'stack_item_status.dart';

/// * Generate Id for StackItem
String _genId() {
  return DateTime.now().millisecondsSinceEpoch.toRadixString(32);
}

/// * Core class for layout data
@immutable
abstract class StackItem<T extends StackItemContent> {
  StackItem({
    required this.boardId,
    String? id,
    required this.size,
    Offset? offset,
    double? angle = 0,
    EdgeInsets? padding,
    StackItemStatus? status = StackItemStatus.selected,
    bool? lockZOrder = false,
    bool? dock = false,
    String? permission,
    String? theme,
    this.content,
  })  : id = id ?? _genId(),
        offset = offset ?? Offset.zero,
        angle = angle ?? 0,
        lockZOrder = lockZOrder ?? false,
        dock = dock ?? false,
        permission = permission ?? 'read',
        theme = theme ?? 'White',
        padding = padding ?? EdgeInsets.zero,
        status = status ?? StackItemStatus.selected;

  const StackItem.empty({
    required this.boardId,
    required this.size,
    required this.offset,
    required this.angle,
    required this.padding,
    required this.status,
    required this.content,
    required this.lockZOrder,
    required this.dock,
    required this.permission,
    required this.theme,
  }) : id = '';

  /// boardId
  final String boardId;

  /// id
  final String id;

  /// Size
  final Size size;

  /// Offset
  final Offset offset;

  /// Angle
  final double angle;

  /// Status
  final StackItemStatus status;

  /// Padding
  final EdgeInsets padding;

  final bool lockZOrder;

  final bool dock;

  final String permission;

  final String theme;

  /// Content
  final T? content;

  /// Update content and return new instance
  StackItem<T> copyWith({
    String? boardId,
    Size? size,
    Offset? offset,
    double? angle,
    EdgeInsets? padding,
    StackItemStatus? status,
    bool? lockZOrder,
    bool? dock,
    String? permission,
    String? theme,
    T? content,
  });

  /// to json
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'boardId': boardId,
      'id': id,
      'type': convertType(this, isEnglish: true),
      'angle': angle,
      'size': size.toJson(),
      'offset': offset.toJson(),
      'padding': {
        'left': padding.left,
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
      },
      'status': status.index,
      'lockZOrder': lockZOrder,
      'dock': dock,
      'permission': permission,
      'theme': theme,
      if (content != null) 'content': content?.toJson(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  @override
  int get hashCode => Object.hash(
        id,
        boardId,
        size,
        offset,
        angle,
        padding,
        status,
        lockZOrder,
        dock,
        permission,
        theme,
        content,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StackItem &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            boardId == other.boardId &&
            size == other.size &&
            offset == other.offset &&
            angle == other.angle &&
            padding == other.padding &&
            status == other.status &&
            lockZOrder == other.lockZOrder &&
            dock == other.dock &&
            permission == other.permission &&
            theme == other.theme &&
            content == other.content;
  }
}
