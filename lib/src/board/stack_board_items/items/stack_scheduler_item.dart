import 'package:flutter/painting.dart';
import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/helpers/as_t.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import 'package:equatable/equatable.dart';

/// SchedulerItemContent
class SchedulerItemContent extends Equatable implements StackItemContent {
  const SchedulerItemContent({
    this.title,
    this.viewType,
    this.schedules,
    this.apiId,
    this.script,
    this.apiParameters,
    this.postApiId,
    this.putApiId,
    this.deleteApiId,
  });

  final String? title;
  final String? viewType; // 'day', 'week', 'month'
  final List<ScheduleData>? schedules;
  final String? apiId;
  final String? script;
  final String? apiParameters; // JSON 형태의 파라미터 정보
  final String? postApiId;
  final String? putApiId;
  final String? deleteApiId;

  SchedulerItemContent copyWith({
    String? title,
    String? viewType,
    List<ScheduleData>? schedules,
    String? apiId,
    String? script,
    String? apiParameters,
    String? postApiId,
    String? putApiId,
    String? deleteApiId,
  }) {
    return SchedulerItemContent(
      title: title ?? this.title,
      viewType: viewType ?? this.viewType,
      schedules: schedules ?? this.schedules,
      apiId: apiId ?? this.apiId,
      script: script ?? this.script,
      apiParameters: apiParameters ?? this.apiParameters,
      postApiId: postApiId ?? this.postApiId,
      putApiId: putApiId ?? this.putApiId,
      deleteApiId: deleteApiId ?? this.deleteApiId,
    );
  }

  factory SchedulerItemContent.fromJson(Map<String, dynamic> data) {
    return SchedulerItemContent(
      title: asNullT<String>(data['title']),
      viewType: asNullT<String>(data['viewType']),
      schedules: data['schedules'] == null
          ? null
          : (data['schedules'] as List)
              .map((e) => ScheduleData.fromJson(asMap(e)))
              .toList(),
      apiId: asNullT<String>(data['apiId']),
      script: asNullT<String>(data['script']),
      apiParameters: asNullT<String>(data['apiParameters']),
      postApiId: asNullT<String>(data['postApiId']),
      putApiId: asNullT<String>(data['putApiId']),
      deleteApiId: asNullT<String>(data['deleteApiId']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (title != null) 'title': title,
      if (viewType != null) 'viewType': viewType,
      if (schedules != null)
        'schedules': schedules!.map((e) => e.toJson()).toList(),
      if (apiId != null) 'apiId': apiId,
      if (script != null) 'script': script,
      if (apiParameters != null) 'apiParameters': apiParameters,
      if (postApiId != null) 'postApiId': postApiId,
      if (putApiId != null) 'putApiId': putApiId,
      if (deleteApiId != null) 'deleteApiId': deleteApiId,
    };
  }

  @override
  List<Object?> get props => [
        title,
        viewType,
        schedules,
        apiId,
        script,
        apiParameters,
        postApiId,
        putApiId,
        deleteApiId,
      ];
}

/// ScheduleData
class ScheduleData extends Equatable {
  const ScheduleData({
    required this.id,
    required this.title,
    required this.date,
    this.startTime,
    this.endTime,
    this.description,
    this.color,
    this.status,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String? description;
  final Color? color;
  final String? status; // '예정', '확정', '완료', '취소'
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ScheduleData copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? description,
    Color? color,
    String? status,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScheduleData(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      color: color ?? this.color,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ScheduleData.fromJson(Map<String, dynamic> data) {
    return ScheduleData(
      id: asT<String>(data['id']),
      title: asT<String>(data['title']),
      date: DateTime.parse(asT<String>(data['date'])),
      startTime: asNullT<String>(data['startTime']),
      endTime: asNullT<String>(data['endTime']),
      description: asNullT<String>(data['description']),
      color: data['color'] == null ? null : Color(asT<int>(data['color'])),
      status: asNullT<String>(data['status']),
      userId: asNullT<String>(data['userId']),
      createdAt: data['createdAt'] == null
          ? null
          : DateTime.parse(asT<String>(data['createdAt'])),
      updatedAt: data['updatedAt'] == null
          ? null
          : DateTime.parse(asT<String>(data['updatedAt'])),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (description != null) 'description': description,
      if (color != null) 'color': color!.value,
      if (status != null) 'status': status,
      if (userId != null) 'userId': userId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        date,
        startTime,
        endTime,
        description,
        color,
        status,
        userId,
        createdAt,
        updatedAt,
      ];
}

/// StackSchedulerItem
class StackSchedulerItem extends StackItem<SchedulerItemContent> {
  StackSchedulerItem({
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

  factory StackSchedulerItem.fromJson(Map<String, dynamic> data) {
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
    return StackSchedulerItem(
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
      content: SchedulerItemContent.fromJson(asMap(data['content'])),
    );
  }

  /// * Override view type
  StackSchedulerItem setViewType(String viewType) {
    return copyWith(content: (content?.copyWith(viewType: viewType)));
  }

  // /// * Override schedules
  // StackSchedulerItem setSchedules(List<ScheduleData> schedules) {
  //   return copyWith(content: (content?.copyWith(schedules: schedules)));
  // }

  /// * Add schedule
  StackSchedulerItem addSchedule(ScheduleData schedule) {
    final currentSchedules = content?.schedules ?? [];
    final newSchedules = [...currentSchedules, schedule];
    return copyWith(content: (content?.copyWith(schedules: newSchedules)));
  }

  /// * Update schedule
  StackSchedulerItem updateSchedule(
      String scheduleId, ScheduleData updatedSchedule) {
    final currentSchedules = content?.schedules ?? [];
    final newSchedules = currentSchedules.map((schedule) {
      return schedule.id == scheduleId ? updatedSchedule : schedule;
    }).toList();
    return copyWith(content: (content?.copyWith(schedules: newSchedules)));
  }

  /// * Remove schedule
  StackSchedulerItem removeSchedule(String scheduleId) {
    final currentSchedules = content?.schedules ?? [];
    final newSchedules = currentSchedules
        .where((schedule) => schedule.id != scheduleId)
        .toList();
    return copyWith(content: (content?.copyWith(schedules: newSchedules)));
  }

  @override
  StackSchedulerItem copyWith({
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
    double? borderRadius,
    SchedulerItemContent? content,
  }) {
    return StackSchedulerItem(
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
      borderRadius: borderRadius ?? this.borderRadius,
      content: content ?? this.content,
    );
  }
}
