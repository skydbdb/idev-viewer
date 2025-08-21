import 'package:flutter/material.dart';
import 'package:idev_v1/src/board/stack_board_items/common/models/menu_config.dart';

import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import '/src/board/helpers.dart';
import 'package:equatable/equatable.dart';

class LayoutItemContent extends Equatable implements StackItemContent {
  const LayoutItemContent({
    this.directionLtr,
    this.bodyOrientation = Axis.horizontal,
    this.title,
    this.profile,
    this.appBar,
    this.actions,
    this.drawer,
    this.topNavigation,
    this.leftNavigation,
    this.rightNavigation,
    this.bottomNavigation,
    this.subBody,
    this.subBodyOptions,
    this.bodyRatio,
    this.reqMenus,
    this.selectedIndex,
  });

  final int? selectedIndex;
  final bool? directionLtr;
  final Axis? bodyOrientation;
  final String? subBodyOptions;
  final String? title;
  final String? profile;
  final String? appBar;
  final String? actions;
  final String? drawer;
  final String? subBody;
  final String? topNavigation;
  final String? leftNavigation;
  final String? rightNavigation;
  final String? bottomNavigation;
  final double? bodyRatio;
  final List<MenuConfig>? reqMenus;

  LayoutItemContent copyWith({
    int? selectedIndex,
    bool? directionLtr,
    Axis? bodyOrientation,
    String? subBodyOptions,
    String? title,
    String? profile,
    String? appBar,
    String? actions,
    String? drawer,
    String? subBody,
    String? topNavigation,
    String? leftNavigation,
    String? rightNavigation,
    String? bottomNavigation,
    double? bodyRatio,
    List<MenuConfig>? reqMenus,
  }) {
    return LayoutItemContent(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      directionLtr: directionLtr ?? this.directionLtr,
      bodyOrientation: bodyOrientation ?? this.bodyOrientation,
      subBodyOptions: subBodyOptions ?? this.subBodyOptions,
      title: title ?? this.title,
      profile: profile ?? this.profile,
      appBar: appBar ?? this.appBar,
      actions: actions ?? this.actions,
      drawer: drawer ?? this.drawer,
      subBody: subBody ?? this.subBody,
      topNavigation: topNavigation ?? this.topNavigation,
      leftNavigation: leftNavigation ?? this.leftNavigation,
      rightNavigation: rightNavigation ?? this.rightNavigation,
      bottomNavigation: bottomNavigation ?? this.bottomNavigation,
      bodyRatio: bodyRatio ?? this.bodyRatio,
      reqMenus: reqMenus ?? this.reqMenus,
    );
  }

  factory LayoutItemContent.fromJson(Map<String, dynamic> data) {
    bool parseBool(dynamic v, {bool defaultValue = false}) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return defaultValue;
    }

    final reqMenusRaw = data['reqMenus'];
    final reqMenus = menuConfigsFromJsonString(asNullT<String>(reqMenusRaw));
    return LayoutItemContent(
      directionLtr: parseBool(data['directionLtr']),
      bodyOrientation: (() {
        final v = data['bodyOrientation'];
        if (v == null) return Axis.horizontal;
        if (v is String) return Axis.values.byName(v);
        if (v is Axis) return v;
        return Axis.horizontal;
      })(),
      title: asNullT<String>(data['title']),
      profile: asNullT<String>(data['profile']),
      appBar: asNullT<String>(data['appBar']),
      actions: asNullT<String>(data['actions']),
      drawer: asNullT<String>(data['drawer']),
      topNavigation: asNullT<String>(data['topNavigation']),
      leftNavigation: asNullT<String>(data['leftNavigation']),
      rightNavigation: asNullT<String>(data['rightNavigation']),
      bottomNavigation: asNullT<String>(data['bottomNavigation']),
      subBody: asNullT<String>(data['subBody']),
      subBodyOptions: asNullT<String>(data['subBodyOptions']),
      bodyRatio: (() {
        final v = data['bodyRatio'];
        if (v == null) return 0.5;
        if (v is String) return double.parse(v);
        if (v is num) return v.toDouble();
        return 0.5;
      })(),
      reqMenus: reqMenus,
      selectedIndex: int.tryParse(data['selectedIndex']?.toString() ?? ''),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (directionLtr != null) 'directionLtr': directionLtr,
      if (bodyOrientation != null) 'bodyOrientation': bodyOrientation!.name,
      if (bodyRatio != null) 'bodyRatio': bodyRatio,
      if (title != null) 'title': title,
      if (profile != null) 'profile': profile,
      if (appBar != null) 'appBar': appBar,
      if (actions != null) 'actions': actions,
      if (drawer != null) 'drawer': drawer,
      if (topNavigation != null) 'topNavigation': topNavigation,
      if (leftNavigation != null) 'leftNavigation': leftNavigation,
      if (rightNavigation != null) 'rightNavigation': rightNavigation,
      if (bottomNavigation != null) 'bottomNavigation': bottomNavigation,
      if (subBody != null) 'subBody': subBody,
      if (subBodyOptions != null) 'subBodyOptions': subBodyOptions,
      'reqMenus': menuConfigsToJsonString(reqMenus),
      if (selectedIndex != null) 'selectedIndex': selectedIndex,
    };
  }

  @override
  List<Object?> get props => [
        selectedIndex,
        directionLtr,
        bodyOrientation,
        subBodyOptions,
        title,
        profile,
        appBar,
        actions,
        drawer,
        subBody,
        topNavigation,
        leftNavigation,
        rightNavigation,
        bottomNavigation,
        bodyRatio,
        reqMenus,
      ];
}

/// StackLayoutItem
class StackLayoutItem extends StackItem<LayoutItemContent> {
  StackLayoutItem({
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

  factory StackLayoutItem.fromJson(Map<String, dynamic> data) {
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
    return StackLayoutItem(
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
      content: LayoutItemContent.fromJson(asMap(data['content'])),
    );
  }

  @override
  StackLayoutItem copyWith({
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
    LayoutItemContent? content,
  }) {
    return StackLayoutItem(
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
