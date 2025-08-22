import 'package:flutter/material.dart';
import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import '/src/board/helpers.dart';
import '../common/models/api_config.dart';
import 'package:equatable/equatable.dart';

class DetailItemContent extends Equatable implements StackItemContent {
  const DetailItemContent({
    this.columnGap,
    this.rowGap,
    this.areas,
    this.columnSizes,
    this.rowSizes,
    this.reqApis = const [],
    this.resApis = const [],
  });

  final double? columnGap;
  final double? rowGap;
  final String? areas;
  final String? columnSizes;
  final String? rowSizes;
  final List<ApiConfig> reqApis;
  final List<ApiConfig> resApis;

  factory DetailItemContent.fromJson(Map<String, dynamic> data) {
    bool parseBool(dynamic v, {bool defaultValue = false}) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return defaultValue;
    }

    return DetailItemContent(
      columnGap: double.parse(data['columnGap'].toString()),
      rowGap: double.parse(data['rowGap'].toString()),
      areas: asNullT<String>(data['areas']) ?? '',
      columnSizes: asNullT<String>(data['columnSizes']) ?? '',
      rowSizes: asNullT<String>(data['rowSizes']) ?? '',
      reqApis: apiConfigsFromJsonString(asNullT<String>(data['reqApis'])),
      resApis: apiConfigsFromJsonString(asNullT<String>(data['resApis'])),
    );
  }

  DetailItemContent copyWith({
    double? columnGap,
    double? rowGap,
    String? areas,
    String? columnSizes,
    String? rowSizes,
    List<ApiConfig>? reqApis,
    List<ApiConfig>? resApis,
  }) {
    return DetailItemContent(
      columnGap: columnGap ?? this.columnGap,
      rowGap: rowGap ?? this.rowGap,
      areas: areas ?? this.areas,
      columnSizes: columnSizes ?? this.columnSizes,
      rowSizes: rowSizes ?? this.rowSizes,
      reqApis: reqApis ?? this.reqApis,
      resApis: resApis ?? this.resApis,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (columnGap != null) 'columnGap': columnGap,
      if (rowGap != null) 'rowGap': rowGap,
      if (areas != null) 'areas': areas,
      if (columnSizes != null) 'columnSizes': columnSizes,
      if (rowSizes != null) 'rowSizes': rowSizes,
      'reqApis': apiConfigsToJsonString(reqApis),
      'resApis': apiConfigsToJsonString(resApis),
    };
  }

  @override
  List<Object?> get props => [
        columnGap,
        rowGap,
        areas,
        columnSizes,
        rowSizes,
        reqApis,
        resApis,
      ];
}

/// StackDetailItem
class StackDetailItem extends StackItem<DetailItemContent> {
  StackDetailItem({
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

  factory StackDetailItem.fromJson(Map<String, dynamic> data) {
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
    return StackDetailItem(
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
      content: DetailItemContent.fromJson(asMap(data['content'])),
    );
  }

  @override
  StackDetailItem copyWith({
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
    DetailItemContent? content,
  }) {
    return StackDetailItem(
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
