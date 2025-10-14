import 'package:flutter/material.dart';

import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import '/src/board/helpers.dart';

class SideMenuItemContent implements StackItemContent {
  const SideMenuItemContent({
    this.selectedIndex,
    this.directionLtr,
    this.title,
    this.appBar,
    this.actions,
    this.drawer,
    this.topNavigation,
    this.leftNavigation,
    this.rightNavigation,
    this.bottomNavigation,
    this.bodyRatio,
    this.navigationItems,
  });

  final int? selectedIndex;
  final bool? directionLtr;
  final String? title;
  final String? appBar;
  final String? actions;
  final String? drawer;
  final String? topNavigation;
  final String? leftNavigation;
  final String? rightNavigation;
  final String? bottomNavigation;
  final double? bodyRatio;
  final String? navigationItems;

  SideMenuItemContent copyWith({
    int? selectedIndex,
    bool? directionLtr,
    String? title,
    String? appBar,
    String? actions,
    String? drawer,
    String? topNavigation,
    String? leftNavigation,
    String? rightNavigation,
    String? bottomNavigation,
    double? bodyRatio,
    String? navigationItems,
  }) {
    return SideMenuItemContent(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      directionLtr: directionLtr ?? this.directionLtr,
      title: title ?? this.title,
      appBar: appBar ?? this.appBar,
      actions: actions ?? this.actions,
      drawer: drawer ?? this.drawer,
      topNavigation: topNavigation ?? this.topNavigation,
      leftNavigation: leftNavigation ?? this.leftNavigation,
      rightNavigation: rightNavigation ?? this.rightNavigation,
      bottomNavigation: bottomNavigation ?? this.bottomNavigation,
      bodyRatio: bodyRatio ?? this.bodyRatio,
      navigationItems: navigationItems ?? this.navigationItems,
    );
  }

  factory SideMenuItemContent.fromJson(Map<String, dynamic> data) {
    bool parseBool(dynamic v, {bool defaultValue = false}) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return defaultValue;
    }

    return SideMenuItemContent(
      selectedIndex: int.tryParse(data['selectedIndex']?.toString() ?? ''),
      directionLtr: parseBool(data['directionLtr']),
      title: asNullT<String>(data['title']),
      appBar: asNullT<String>(data['appBar']),
      actions: asNullT<String>(data['actions']),
      drawer: asNullT<String>(data['drawer']),
      topNavigation: asNullT<String>(data['topNavigation']),
      leftNavigation: asNullT<String>(data['leftNavigation']),
      rightNavigation: asNullT<String>(data['rightNavigation']),
      bottomNavigation: asNullT<String>(data['bottomNavigation']),
      bodyRatio: double.tryParse(data['bodyRatio']?.toString() ?? ''),
      navigationItems: asNullT<String>(data['navigationItems']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (selectedIndex != null) 'selectedIndex': selectedIndex,
      if (directionLtr != null) 'directionLtr': directionLtr,
      if (title != null) 'title': title,
      if (appBar != null) 'appBar': appBar,
      if (actions != null) 'actions': actions,
      if (drawer != null) 'drawer': drawer,
      if (topNavigation != null) 'topNavigation': topNavigation,
      if (leftNavigation != null) 'leftNavigation': leftNavigation,
      if (rightNavigation != null) 'rightNavigation': rightNavigation,
      if (bottomNavigation != null) 'bottomNavigation': bottomNavigation,
      if (bodyRatio != null) 'bodyRatio': bodyRatio,
      if (navigationItems != null) 'navigationItems': navigationItems,
    };
  }
}

/// StackSideMenuItem
class StackSideMenuItem extends StackItem<SideMenuItemContent> {
  StackSideMenuItem({
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

  factory StackSideMenuItem.fromJson(Map<String, dynamic> data) {
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
    return StackSideMenuItem(
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
      borderRadius: data['borderRadius'] as double? ?? 8.0,
      content: SideMenuItemContent.fromJson(asMap(data['content'])),
    );
  }

  @override
  StackSideMenuItem copyWith({
    String? boardId,
    double? angle,
    Size? size,
    Offset? offset,
    EdgeInsets? padding,
    StackItemStatus? status,
    bool? lockZOrder,
    bool? dock,
    String? permission,
    String? theme,
    double? borderRadius,
    SideMenuItemContent? content,
  }) {
    return StackSideMenuItem(
      boardId: boardId ?? this.boardId,
      id: id,
      angle: angle ?? this.angle,
      size: size ?? this.size,
      offset: offset ?? this.offset,
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
