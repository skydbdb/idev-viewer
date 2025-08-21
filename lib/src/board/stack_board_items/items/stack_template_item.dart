import 'package:flutter/cupertino.dart';
import 'package:equatable/equatable.dart';

import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import '/src/board/helpers.dart';

class TemplateItemContent extends Equatable implements StackItemContent {
  const TemplateItemContent({
    this.templateNm,
    this.templateId,
    this.versionId,
    this.script,
    this.commitInfo,
    this.sizeOption,
  });

  final String? templateNm;
  final int? templateId;
  final int? versionId;
  final String? script;
  final String? commitInfo;
  final String? sizeOption;

  TemplateItemContent copyWith({
    String? templateNm,
    int? templateId,
    int? versionId,
    String? script,
    String? commitInfo,
    String? sizeOption,
  }) {
    return TemplateItemContent(
      templateNm: templateNm ?? this.templateNm,
      templateId: templateId ?? this.templateId,
      versionId: versionId ?? this.versionId,
      script: script ?? this.script,
      commitInfo: commitInfo ?? this.commitInfo,
      sizeOption: sizeOption ?? this.sizeOption,
    );
  }

  factory TemplateItemContent.fromJson(Map<String, dynamic> data) {
    return TemplateItemContent(
      templateNm: asNullT<String>(data['templateNm']),
      templateId: asNullT<int>(data['templateId']),
      versionId: asNullT<int>(data['versionId']),
      script: asNullT<String>(data['script']),
      commitInfo: asNullT<String>(data['commitInfo']),
      sizeOption: asNullT<String>(data['sizeOption']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (templateNm != null) 'templateNm': templateNm,
      if (templateId != null) 'templateId': templateId,
      if (versionId != null) 'versionId': versionId,
      if (script != null) 'script': script,
      if (commitInfo != null) 'commitInfo': commitInfo,
      if (sizeOption != null) 'sizeOption': sizeOption,
    };
  }

  @override
  List<Object?> get props => [
        templateNm,
        templateId,
        versionId,
        script,
        commitInfo,
        sizeOption,
      ];
}

/// StackTemplateItem
class StackTemplateItem extends StackItem<TemplateItemContent> {
  StackTemplateItem({
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

  factory StackTemplateItem.fromJson(Map<String, dynamic> data) {
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
    return StackTemplateItem(
      boardId: asT<String>(data['boardId']),
      id: data['id'] as String,
      angle: data['angle'] as double,
      size: jsonToSize(data['size'] as Map<String, dynamic>),
      offset: jsonToOffset(data['offset'] as Map<String, dynamic>),
      padding: padding,
      status: StackItemStatus.values[data['status'] as int],
      lockZOrder: asNullT<bool>(data['lockZOrder']) ?? false,
      dock: asNullT<bool>(data['dock']) ?? false,
      permission: data['permission'] as String,
      theme: data['theme'] as String?,
      content:
          TemplateItemContent.fromJson(data['content'] as Map<String, dynamic>),
    );
  }

  @override
  StackTemplateItem copyWith({
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
    TemplateItemContent? content,
  }) {
    return StackTemplateItem(
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
      content: content ?? this.content,
    );
  }
}
