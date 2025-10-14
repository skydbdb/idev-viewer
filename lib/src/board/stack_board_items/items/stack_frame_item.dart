import 'package:flutter/cupertino.dart';
import 'package:equatable/equatable.dart';

import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import '/src/board/helpers.dart';

class FrameItemContent extends Equatable implements StackItemContent {
  const FrameItemContent({
    this.tabsVisible,
    this.dividerThickness,
    this.tabsTitle,
    this.lastStringify,
  });

  final bool? tabsVisible;
  final double? dividerThickness;
  final String? tabsTitle;
  final String? lastStringify;

  FrameItemContent copyWith({
    bool? tabsVisible,
    double? dividerThickness,
    String? tabsTitle,
    String? lastStringify,
  }) {
    return FrameItemContent(
      tabsVisible: tabsVisible ?? this.tabsVisible,
      dividerThickness: dividerThickness ?? this.dividerThickness,
      tabsTitle: tabsTitle ?? this.tabsTitle,
      lastStringify: lastStringify ?? this.lastStringify,
    );
  }

  factory FrameItemContent.fromJson(Map<String, dynamic> data) {
    bool parseBool(dynamic v, {bool defaultValue = false}) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return defaultValue;
    }

    return FrameItemContent(
      tabsVisible: parseBool(data['tabsVisible'], defaultValue: true),
      dividerThickness:
          double.tryParse(data['dividerThickness']?.toString() ?? '') ?? 6,
      tabsTitle: asNullT<String>(data['tabsTitle']),
      lastStringify: asNullT<String>(data['lastStringify']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (tabsVisible != null) 'tabsVisible': tabsVisible,
      if (dividerThickness != null) 'dividerThickness': dividerThickness,
      if (tabsTitle != null) 'tabsTitle': tabsTitle,
      if (lastStringify != null) 'lastStringify': lastStringify,
    };
  }

  @override
  List<Object?> get props => [
        tabsVisible,
        dividerThickness,
        tabsTitle,
        lastStringify,
      ];
}

/// StackFrameItem
class StackFrameItem extends StackItem<FrameItemContent> {
  StackFrameItem({
    super.content,
    required super.boardId,
    super.id,
    super.angle = null,
    required super.size,
    super.offset,
    super.lockZOrder = null,
    super.dock = null,
    super.permission,
    super.padding,
    super.status = null,
    super.theme,
    super.borderRadius,
  });

  factory StackFrameItem.fromJson(Map<String, dynamic> data) {
    final paddingJson = data['padding'];
    EdgeInsets padding;
    if (paddingJson is Map) {
      padding = EdgeInsets.fromLTRB(
        (paddingJson['left'] ?? 0).toDouble(),
        (paddingJson['top'] ?? 0).toDouble(),
        (paddingJson['right'] ?? 0).toDouble(),
        (paddingJson['bottom'] ?? 0).toDouble(),
      );
    } else if (paddingJson is num) {
      padding = EdgeInsets.all(paddingJson.toDouble());
    } else {
      padding = EdgeInsets.zero;
    }
    return StackFrameItem(
      boardId: asT<String>(data['boardId']),
      id: data['id'] as String?,
      angle: data['angle'] as double?,
      size: jsonToSize(data['size'] as Map<String, dynamic>),
      offset: jsonToOffset(data['offset'] as Map<String, dynamic>),
      padding: padding,
      status: StackItemStatus.values[data['status'] as int],
      lockZOrder: asNullT<bool>(data['lockZOrder']) ?? false,
      dock: asNullT<bool>(data['dock']) ?? false,
      permission: data['permission'] as String,
      theme: data['theme'] as String?,
      borderRadius: data['borderRadius'] as double? ?? 8.0,
      content:
          FrameItemContent.fromJson(data['content'] as Map<String, dynamic>),
    );
  }

  @override
  StackFrameItem copyWith({
    String? boardId,
    String? id,
    Size? size,
    Offset? offset,
    double? angle,
    EdgeInsets? padding,
    StackItemStatus? status,
    bool? lockZOrder,
    bool? dock,
    String? permission,
    String? theme,
    double? borderRadius,
    FrameItemContent? content,
  }) {
    return StackFrameItem(
      boardId: boardId ?? this.boardId,
      id: id ?? this.id,
      size: size ?? this.size,
      offset: offset ?? this.offset,
      angle: angle ?? this.angle,
      padding: padding ?? this.padding,
      status: status ?? this.status,
      lockZOrder: lockZOrder ?? this.lockZOrder,
      dock: dock ?? this.dock,
      permission: permission ?? this.permission,
      theme: theme ?? this.theme,
      borderRadius: borderRadius ?? this.borderRadius,
      content: content ?? this.content,
    );
  }
}
