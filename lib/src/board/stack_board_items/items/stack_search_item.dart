import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import '/src/board/helpers.dart';
import '../common/models/api_config.dart';

class SearchItemContent extends Equatable implements StackItemContent {
  SearchItemContent({
    this.buttonName,
    List<ApiConfig>? reqApis,
  }) : reqApis = reqApis ?? const [];

  String? buttonName;
  final List<ApiConfig> reqApis;

  SearchItemContent copyWith({
    String? buttonName,
    List<ApiConfig>? reqApis,
  }) {
    return SearchItemContent(
      buttonName: buttonName ?? this.buttonName,
      reqApis: reqApis ?? this.reqApis,
    );
  }

  factory SearchItemContent.fromJson(Map<String, dynamic> data) {
    return SearchItemContent(
      buttonName: asNullT<String>(data['buttonName']),
      reqApis: apiConfigsFromJsonString(asNullT<String>(data['reqApis'])),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (buttonName != null) 'buttonName': buttonName,
      'reqApis': apiConfigsToJsonString(reqApis),
    };
  }

  @override
  List<Object?> get props => [
        buttonName,
        reqApis,
      ];
}

/// StackSearchItem
class StackSearchItem extends StackItem<SearchItemContent> {
  StackSearchItem({
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
  });

  factory StackSearchItem.fromJson(Map<String, dynamic> data) {
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
    return StackSearchItem(
      boardId: asT<String>(data['boardId']),
      id: asT<String>(data['id']),
      angle: asT<double>(data['angle']),
      size: jsonToSize(asMap(data['size'])),
      offset:
          data['offset'] == null ? null : jsonToOffset(asMap(data['offset'])),
      padding: padding,
      status: StackItemStatus.values[data['status'] as int],
      lockZOrder: asNullT<bool>(data['lockZOrder']) ?? false,
      dock: asNullT<bool>(data['dock']) ?? false,
      permission: data['permission'] as String,
      theme: data['theme'] as String?,
      content: SearchItemContent.fromJson(asMap(data['content'])),
    );
  }

  @override
  StackSearchItem copyWith({
    String? boardId,
    String? id,
    double? angle,
    Size? size,
    Offset? offset,
    EdgeInsets? padding,
    StackItemStatus? status,
    bool? lockZOrder,
    bool? dock,
    String? permission,
    String? theme,
    SearchItemContent? content,
  }) {
    return StackSearchItem(
      boardId: boardId ?? this.boardId,
      id: id ?? this.id,
      angle: angle ?? this.angle,
      size: size ?? this.size,
      offset: offset ?? this.offset,
      padding: padding ?? this.padding,
      status: status ?? this.status,
      lockZOrder: lockZOrder ?? this.lockZOrder,
      dock: dock ?? this.dock,
      permission: permission ?? this.permission,
      theme: theme ?? this.theme,
      content: content ?? this.content,
    );
  }
}
