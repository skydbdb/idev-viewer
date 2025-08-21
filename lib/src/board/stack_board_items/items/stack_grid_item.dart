import 'package:flutter/cupertino.dart';
import 'package:idev_v1/src/board/helpers/json_list.dart';
import '/src/grid/trina_grid/trina_grid.dart';
import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/widget_style_extension/ex_offset.dart';
import '/src/board/widget_style_extension/ex_size.dart';
import '/src/board/helpers.dart';
import '/src/board/stack_board_items/common/models/api_config.dart';
import 'package:equatable/equatable.dart';

class GridItemContent extends Equatable implements StackItemContent {
  const GridItemContent({
    this.headerTitle,
    this.apiId,
    this.saveApiId,
    this.saveApiParams,
    this.reqApis = const [],
    this.resApis = const [],
    this.colGroups = const [],
    this.columnAggregate = const {},
    this.groupByColumns = const {},
    this.columns,
    this.rows,
    this.rowHeight,
    this.mode,
    this.showRowNum,
    this.enableRowChecked,
    this.showColumn,
    this.enableColumnFilter,
    this.enableColumnAggregate,
    this.showFooter,
  });

  final String? headerTitle;
  final String? apiId;
  final String? saveApiId;
  final String? saveApiParams;
  final List<ApiConfig> reqApis;
  final List<ApiConfig> resApis;
  final List<dynamic> colGroups;
  final Map<String, bool> columnAggregate;
  final Set<String> groupByColumns;
  final List<TrinaColumn>? columns;
  final List<TrinaRow>? rows;
  final double? rowHeight;
  final String? mode;
  final bool? showRowNum;
  final bool? enableRowChecked;
  final bool? showColumn;
  final bool? showFooter;
  final bool? enableColumnAggregate;
  final bool? enableColumnFilter;

  GridItemContent copyWith({
    String? headerTitle,
    String? apiId,
    String? saveApiId,
    String? saveApiParams,
    List<ApiConfig>? reqApis,
    List<ApiConfig>? resApis,
    List<dynamic>? colGroups,
    Map<String, bool>? columnAggregate,
    Set<String>? groupByColumns,
    List<TrinaColumn>? columns,
    List<TrinaRow>? rows,
    double? rowHeight,
    String? mode,
    bool? showRowNum,
    bool? enableRowChecked,
    bool? showColumn,
    bool? showFooter,
    bool? enableColumnAggregate,
    bool? enableColumnFilter,
  }) {
    return GridItemContent(
      headerTitle: headerTitle ?? this.headerTitle,
      apiId: apiId ?? this.apiId,
      saveApiId: saveApiId ?? this.saveApiId,
      saveApiParams: saveApiParams ?? this.saveApiParams,
      reqApis: reqApis ?? this.reqApis,
      resApis: resApis ?? this.resApis,
      colGroups: colGroups ?? this.colGroups,
      columnAggregate: columnAggregate ?? this.columnAggregate,
      groupByColumns: groupByColumns ?? this.groupByColumns,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      rowHeight: rowHeight ?? this.rowHeight,
      mode: mode ?? this.mode,
      showRowNum: showRowNum ?? this.showRowNum,
      enableRowChecked: enableRowChecked ?? this.enableRowChecked,
      showColumn: showColumn ?? this.showColumn,
      showFooter: showFooter ?? this.showFooter,
      enableColumnAggregate:
          enableColumnAggregate ?? this.enableColumnAggregate,
      enableColumnFilter: enableColumnFilter ?? this.enableColumnFilter,
    );
  }

  factory GridItemContent.fromJson(Map<String, dynamic> data) {
    bool parseBool(dynamic v, {bool defaultValue = false}) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return defaultValue;
    }

    final resApisRaw = data['resApis'];
    final resApis = apiConfigsFromJsonString(asNullT<String>(resApisRaw));
    final reqApisRaw = data['reqApis'];
    final reqApis = apiConfigsFromJsonString(asNullT<String>(reqApisRaw));
    final colGroupsRaw = data['colGroups'];
    final List<dynamic> colGroups = colGroupsRaw is String
        ? jsonList(colGroupsRaw)
        : colGroupsRaw is List
            ? colGroupsRaw
            : [];

    final columnAggregateRaw = data['columnAggregate'];
    final Map<String, bool> columnAggregate = columnAggregateRaw is Map
        ? Map<String, bool>.from(columnAggregateRaw)
        : {};

    // groupByColumns 처리 개선 - List와 Set 모두 지원
    final groupByColumnsRaw = data['groupByColumns'];
    Set<String> groupByColumns = {};

    if (groupByColumnsRaw is Set) {
      groupByColumns = Set<String>.from(groupByColumnsRaw);
    } else if (groupByColumnsRaw is List) {
      groupByColumns = Set<String>.from(groupByColumnsRaw.cast<String>());
    } else if (groupByColumnsRaw is String) {
      // JSON 문자열로 저장된 경우 파싱
      try {
        final List<dynamic> parsed = jsonList(groupByColumnsRaw);
        groupByColumns = Set<String>.from(parsed.cast<String>());
      } catch (e) {
        groupByColumns = {};
      }
    }

    return GridItemContent(
      headerTitle: asNullT<String>(data['headerTitle']),
      apiId: asNullT<String>(data['apiId']),
      saveApiId: asNullT<String>(data['saveApiId']),
      saveApiParams: asNullT<String>(data['saveApiParams']),
      reqApis: reqApis,
      resApis: resApis,
      colGroups: colGroups,
      columnAggregate: columnAggregate,
      groupByColumns: groupByColumns,
      columns: null,
      rows: null,
      rowHeight: double.tryParse(data['rowHeight']?.toString() ?? ''),
      mode: asNullT<String>(data['mode']),
      showRowNum: parseBool(data['showRowNum'], defaultValue: true),
      enableRowChecked: parseBool(data['enableRowChecked']),
      showColumn: parseBool(data['showColumn'], defaultValue: true),
      enableColumnFilter: parseBool(data['enableColumnFilter']),
      enableColumnAggregate: parseBool(data['enableColumnAggregate']),
      showFooter: parseBool(data['showFooter'], defaultValue: true),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (headerTitle != null) 'headerTitle': headerTitle,
      if (apiId != null) 'apiId': apiId,
      if (saveApiId != null) 'saveApiId': saveApiId,
      if (saveApiParams != null) 'saveApiParams': saveApiParams,
      'reqApis': apiConfigsToJsonString(reqApis),
      'resApis': apiConfigsToJsonString(resApis),
      'colGroups': jsonListToString(colGroups),
      'columnAggregate': columnAggregate,
      // Set을 List로 변환하여 JSON 직렬화 가능하게 함
      'groupByColumns': groupByColumns.toList(),
      if (rowHeight != null) 'rowHeight': rowHeight,
      if (mode != null) 'mode': mode,
      if (showRowNum != null) 'showRowNum': showRowNum,
      if (enableRowChecked != null) 'enableRowChecked': enableRowChecked,
      if (showColumn != null) 'showColumn': showColumn,
      if (enableColumnFilter != null) 'enableColumnFilter': enableColumnFilter,
      if (enableColumnAggregate != null)
        'enableColumnAggregate': enableColumnAggregate,
      if (showFooter != null) 'showFooter': showFooter,
    };
  }

  @override
  List<Object?> get props => [
        headerTitle,
        apiId,
        saveApiId,
        saveApiParams,
        reqApis,
        resApis,
        colGroups,
        columnAggregate,
        groupByColumns,
        columns,
        rows,
        rowHeight,
        mode,
        showRowNum,
        enableRowChecked,
        showColumn,
        showFooter,
        enableColumnAggregate,
        enableColumnFilter,
      ];
}

/// StackGridItem
class StackGridItem extends StackItem<GridItemContent> {
  StackGridItem({
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

  factory StackGridItem.fromJson(Map<String, dynamic> data) {
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
    return StackGridItem(
      boardId: asT<String>(data['boardId']),
      id: asT<String>(data['id']),
      angle: asNullT<double>(data['angle']),
      padding: padding,
      size: jsonToSize(data['size'] as Map<String, dynamic>),
      offset: jsonToOffset(data['offset'] as Map<String, dynamic>),
      status: data['status'] != null
          ? StackItemStatus.values[data['status'] as int]
          : null,
      lockZOrder: asNullT<bool>(data['lockZOrder']) ?? false,
      dock: asNullT<bool>(data['dock']) ?? false,
      permission: asT<String>(data['permission']),
      theme: data['theme'] as String?,
      content:
          GridItemContent.fromJson(data['content'] as Map<String, dynamic>),
    );
  }

  @override
  StackGridItem copyWith({
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
    GridItemContent? content,
  }) {
    return StackGridItem(
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
