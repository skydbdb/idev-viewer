import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';

import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import '/src/board/helpers.dart';

class ButtonItemContent extends Equatable implements StackItemContent {
  const ButtonItemContent({
    this.buttonName,
    this.url,
    this.options,
    this.icon,
    this.buttonType, // 'api', 'url', 'template'
    this.apiId,
    this.templateId,
    this.templateNm,
    this.versionId,
    this.script,
    this.commitInfo,
    this.apiParameters, // API 호출 시 사용할 파라미터 정보
  });

  final String? buttonName;
  final String? url;
  final String? options;
  final String? icon;
  final String? buttonType; // 'api', 'url', 'template'
  final String? apiId;
  final int? templateId;
  final String? templateNm;
  final int? versionId;
  final String? script;
  final String? commitInfo;
  final String? apiParameters; // JSON 형태의 파라미터 정보

  ButtonItemContent copyWith({
    String? buttonName,
    String? url,
    String? options,
    String? icon,
    String? buttonType,
    String? apiId,
    int? templateId,
    String? templateNm,
    int? versionId,
    String? script,
    String? commitInfo,
    String? apiParameters,
  }) {
    return ButtonItemContent(
      buttonName: buttonName ?? this.buttonName,
      url: url ?? this.url,
      options: options ?? this.options,
      icon: icon ?? this.icon ?? '',
      buttonType: buttonType ?? this.buttonType,
      apiId: apiId ?? this.apiId,
      templateId: templateId ?? this.templateId,
      templateNm: templateNm ?? this.templateNm,
      versionId: versionId ?? this.versionId,
      script: script ?? this.script,
      commitInfo: commitInfo ?? this.commitInfo,
      apiParameters: apiParameters ?? this.apiParameters,
    );
  }

  factory ButtonItemContent.fromJson(Map<String, dynamic> data) {
    debugPrint('🔘 [ButtonItemContent] fromJson 호출 - data: $data');

    final content = ButtonItemContent(
      buttonName: asNullT<String>(data['buttonName']),
      url: asNullT<String>(data['url']),
      options: asNullT<String>(data['options']),
      icon: asNullT<String>(data['icon']),
      buttonType: asNullT<String>(data['buttonType']),
      apiId: asNullT<String>(data['apiId']),
      templateId: asNullT<int>(data['templateId']),
      templateNm: asNullT<String>(data['templateNm']),
      versionId: asNullT<int>(data['versionId']),
      script: asNullT<String>(data['script']),
      commitInfo: asNullT<String>(data['commitInfo']),
      apiParameters: asNullT<String>(data['apiParameters']),
    );

    return content;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      if (buttonName != null) 'buttonName': buttonName,
      if (url != null) 'url': url,
      if (options != null) 'options': options,
      if (icon != null) 'icon': icon,
      if (buttonType != null) 'buttonType': buttonType,
      if (apiId != null) 'apiId': apiId,
      if (templateId != null) 'templateId': templateId,
      if (templateNm != null) 'templateNm': templateNm,
      if (versionId != null) 'versionId': versionId,
      if (script != null) 'script': script,
      if (commitInfo != null) 'commitInfo': commitInfo,
      if (apiParameters != null) 'apiParameters': apiParameters,
    };

    return json;
  }

  @override
  List<Object?> get props => [
        buttonName,
        url,
        options,
        icon,
        buttonType,
        apiId,
        templateId,
        templateNm,
        versionId,
        script,
        commitInfo,
        apiParameters,
      ];
}

/// StackButtonItem
class StackButtonItem extends StackItem<ButtonItemContent> {
  StackButtonItem({
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

  factory StackButtonItem.fromJson(Map<String, dynamic> data) {
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

    final item = StackButtonItem(
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
      borderRadius: data['borderRadius'] as double? ?? 8.0,
      content:
          ButtonItemContent.fromJson(data['content'] as Map<String, dynamic>),
    );

    return item;
  }

  @override
  StackButtonItem copyWith({
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
    ButtonItemContent? content,
  }) {
    final newItem = StackButtonItem(
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

    return newItem;
  }
}
