import 'package:flutter/material.dart';
import 'package:idev_v1/src/board/stack_board_items/common/models/api_config.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '/src/board/helpers.dart';
import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import 'package:equatable/equatable.dart';

class ChartItemContent extends Equatable implements StackItemContent {
  const ChartItemContent({
    this.chartType = 'column',
    this.dataSource,
    this.apiId,
    this.reqApis = const [],
    this.xValueMapper,
    this.yValueMapper,
    this.title,
    this.showLegend = true,
    this.showTooltip = true,
    this.enableZoom = false,
    this.enablePan = false,
    this.showDataLabels = false,
    this.primaryXAxisType = 'category',
    this.xAxisLabelFormat,
    this.primaryYAxisType = 'numeric',
    this.yAxisLabelFormat,
    this.selectionType = SelectionType.cluster,
    this.autoScrollingMode = AutoScrollingMode.start,
    this.autoScrollingDelta = 0,
  });

  final String chartType;
  final List<Map<String, dynamic>>? dataSource;
  final String? apiId;
  final List<ApiConfig> reqApis;
  final String? xValueMapper;
  final List<dynamic>? yValueMapper;
  final String? title;
  final bool showLegend;
  final bool showTooltip;
  final bool enableZoom;
  final bool enablePan;
  final String primaryXAxisType;
  final String? xAxisLabelFormat;
  final String primaryYAxisType;
  final String? yAxisLabelFormat;
  final bool showDataLabels;
  final SelectionType selectionType;
  final AutoScrollingMode autoScrollingMode;
  final int autoScrollingDelta;

  ChartItemContent copyWith({
    String? chartType,
    List<Map<String, dynamic>>? dataSource,
    String? apiId,
    List<ApiConfig>? reqApis,
    String? xValueMapper,
    List<dynamic>? yValueMapper,
    String? title,
    bool? showLegend,
    bool? showTooltip,
    bool? enableZoom,
    bool? enablePan,
    bool? showDataLabels,
    String? primaryXAxisType,
    String? xAxisLabelFormat,
    String? primaryYAxisType,
    String? yAxisLabelFormat,
    SelectionType? selectionType,
    AutoScrollingMode? autoScrollingMode,
    int? autoScrollingDelta,
  }) {
    return ChartItemContent(
      chartType: chartType ?? this.chartType,
      dataSource: dataSource ?? this.dataSource,
      apiId: apiId ?? this.apiId,
      reqApis: reqApis ?? this.reqApis,
      xValueMapper: xValueMapper ?? this.xValueMapper,
      yValueMapper: yValueMapper ?? this.yValueMapper,
      title: title ?? this.title,
      showLegend: showLegend ?? this.showLegend,
      showTooltip: showTooltip ?? this.showTooltip,
      enableZoom: enableZoom ?? this.enableZoom,
      enablePan: enablePan ?? this.enablePan,
      showDataLabels: showDataLabels ?? this.showDataLabels,
      primaryXAxisType: primaryXAxisType ?? this.primaryXAxisType,
      xAxisLabelFormat: xAxisLabelFormat ?? this.xAxisLabelFormat,
      primaryYAxisType: primaryYAxisType ?? this.primaryYAxisType,
      yAxisLabelFormat: yAxisLabelFormat ?? this.yAxisLabelFormat,
      selectionType: selectionType ?? this.selectionType,
      autoScrollingMode: autoScrollingMode ?? this.autoScrollingMode,
      autoScrollingDelta: autoScrollingDelta ?? this.autoScrollingDelta,
    );
  }

  factory ChartItemContent.fromJson(Map<String, dynamic> json) {
    List<dynamic>? yValueMapper;
    final yValueMapperRaw = json['yValueMapper'];
    if (yValueMapperRaw is List) {
      yValueMapper = yValueMapperRaw;
    } else if (yValueMapperRaw is String && yValueMapperRaw.isNotEmpty) {
      final keys = yValueMapperRaw.split(',').map((e) => e.trim()).toList();
      yValueMapper = keys.map((key) => {key: key}).toList();
    }

    return ChartItemContent(
      chartType: asT<String>(json['chartType']),
      dataSource: json['dataSource'] != null
          ? List<Map<String, dynamic>>.from(json['dataSource'])
          : null,
      apiId: asNullT<String>(json['apiId']),
      reqApis: apiConfigsFromJsonString(asNullT<String>(json['reqApis'])),
      xValueMapper: asNullT<String>(json['xValueMapper']),
      yValueMapper: yValueMapper,
      title: asNullT<String>(json['title']),
      showLegend: asT<bool>(json['showLegend']),
      showTooltip: asT<bool>(json['showTooltip']),
      enableZoom: asT<bool>(json['enableZoom']),
      enablePan: asT<bool>(json['enablePan']),
      showDataLabels: asT<bool>(json['showDataLabels']),
      primaryXAxisType: asT<String>(json['primaryXAxisType']),
      xAxisLabelFormat: asNullT<String>(json['xAxisLabelFormat']),
      primaryYAxisType: asT<String>(json['primaryYAxisType']),
      yAxisLabelFormat: asNullT<String>(json['yAxisLabelFormat']),
      selectionType: json['selectionType'] != null
          ? SelectionType.values.byName(json['selectionType'])
          : SelectionType.cluster,
      autoScrollingMode: json['autoScrollingMode'] != null
          ? AutoScrollingMode.values.byName(json['autoScrollingMode'])
          : AutoScrollingMode.start,
      autoScrollingDelta: asT<int>(json['autoScrollingDelta']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'chartType': chartType,
      if (dataSource != null) 'dataSource': dataSource,
      if (apiId != null) 'apiId': apiId,
      'reqApis': apiConfigsToJsonString(reqApis),
      if (xValueMapper != null) 'xValueMapper': xValueMapper,
      if (yValueMapper != null) 'yValueMapper': yValueMapper,
      if (title != null) 'title': title,
      'showLegend': showLegend,
      'showTooltip': showTooltip,
      'enableZoom': enableZoom,
      'enablePan': enablePan,
      'showDataLabels': showDataLabels,
      'primaryXAxisType': primaryXAxisType,
      if (xAxisLabelFormat != null) 'xAxisLabelFormat': xAxisLabelFormat,
      'primaryYAxisType': primaryYAxisType,
      if (yAxisLabelFormat != null) 'yAxisLabelFormat': yAxisLabelFormat,
      'selectionType': selectionType.name,
      'autoScrollingMode': autoScrollingMode.name,
      'autoScrollingDelta': autoScrollingDelta,
    };
  }

  @override
  List<Object?> get props => [
        chartType,
        dataSource,
        apiId,
        reqApis,
        xValueMapper,
        yValueMapper,
        title,
        showLegend,
        showTooltip,
        enableZoom,
        enablePan,
        showDataLabels,
        primaryXAxisType,
        xAxisLabelFormat,
        primaryYAxisType,
        yAxisLabelFormat,
        selectionType,
        autoScrollingMode,
        autoScrollingDelta,
      ];
}

class StackChartItem extends StackItem<ChartItemContent> {
  StackChartItem({
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

  factory StackChartItem.fromJson(Map<String, dynamic> data) {
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

    return StackChartItem(
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
      content: ChartItemContent.fromJson(asMap(data['content'])),
    );
  }

  @override
  StackChartItem copyWith({
    String? boardId,
    String? id,
    double? angle,
    Size? size,
    Offset? offset,
    bool? lockZOrder,
    bool? dock,
    String? permission,
    EdgeInsets? padding,
    StackItemStatus? status,
    String? theme,
    ChartItemContent? content,
  }) {
    return StackChartItem(
      boardId: boardId ?? this.boardId,
      id: id ?? this.id,
      angle: angle ?? this.angle,
      size: size ?? this.size,
      offset: offset ?? this.offset,
      lockZOrder: lockZOrder ?? this.lockZOrder,
      dock: dock ?? this.dock,
      permission: permission ?? this.permission,
      padding: padding ?? this.padding,
      status: status ?? this.status,
      theme: theme ?? this.theme,
      content: content ?? this.content,
    );
  }
}
