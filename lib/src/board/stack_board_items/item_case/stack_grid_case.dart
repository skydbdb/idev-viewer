import 'dart:async';
import 'package:flutter/material.dart';
import 'package:idev_v1/src/board/board/stack_board.dart';
import 'package:idev_v1/src/board/core/stack_board_controller.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item_status.dart';
import 'package:idev_v1/src/board/helpers.dart';
import 'package:idev_v1/src/board/stack_board_items/common/new_field.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/board/stack_items.dart';
import 'package:idev_v1/src/fx/formula_parser.dart';
import '/src/di/service_locator.dart';
import 'package:idev_v1/src/theme/config/trina_grid_config.dart';
import 'package:idev_v1/src/theme/theme_grid.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../util/widget/popup_grid/popup_grid_launcher.dart';
import '/src/repo/home_repo.dart';
import '/src/repo/app_streams.dart';
import '/src/settings/grid/column_menu_delegate.dart';
import '/src/grid/trina_grid/trina_grid.dart';
import '/src/grid/test/dummy_data/development.dart';
import 'package:uuid/uuid.dart';
import './stack_grid_case/grid_export_utils.dart';
import './stack_grid_case/grid_renderer_mixin.dart';
import 'package:idev_v1/src/board/stack_board_items/common/models/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:idev_v1/src/core/auth/auth_service.dart';

class StackGridCase extends StatefulWidget {
  const StackGridCase({
    super.key,
    required this.item,
  });

  final StackGridItem item;

  @override
  State<StackGridCase> createState() => StackGridCaseState();
}

class StackGridCaseState extends State<StackGridCase> with GridRendererMixin {
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  late TrinaGridStateManager stateManager;
  late GridExportUtils exportUtils;
  late bool showRowNum,
      enableRowChecked,
      showColumn,
      enableColumnFilter,
      enableColumnAggregate,
      showFooter;
  List<TrinaColumn> columns = [];
  List<TrinaRow> rows = [];
  String boardId = '', permission = '', headerTitle = '';
  String theme = '';
  String apiId = '', saveApiId = '', saveApiParams = '';
  String columnState = '';
  List<ApiConfig> reqApis = [];
  List<ApiConfig> resApis = [];
  List<dynamic> colGroups = [];

  Map<String, bool> columnAggregate = {};
  Set<String> groupByColumns = {};
  Map<String, bool> get currentColumnAggregate => ColumnStateManager().colAggs;
  List<TrinaColumn> get currentGroupByColumns => stateManager.columns
      .where((column) => ColumnStateManager().grpCols.contains(column.field))
      .toList();

  List<TrinaColumnGroup> columnGroups = [];
  List<TrinaColumnGroup> cp = [];
  int pageSize = 30;
  double rowHeight = 25;
  TrinaGridMode mode = TrinaGridMode.normal;
  Map<Key, dynamic> onChanged = {};

  StackBoardController _controller(BuildContext context) =>
      StackBoardConfig.of(context).controller;

  late ValueKey renderKey;
  bool get isWeb => kIsWeb;
  int _renderCounter = 0;
  bool _initialized = false;
  StreamSubscription? _updateStackItemSub;
  StreamSubscription? _apiIdResponseSub;
  StreamSubscription? _gridColumnMenuSub;

  // Stream 구독을 위한 변수들
  StreamSubscription? _colAggsSubscription;
  StreamSubscription? _grpColsSubscription;

  @override
  void initState() {
    super.initState();
    _renderCounter = 0;
    renderKey = ValueKey('${widget.item.id}_$_renderCounter');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      homeRepo = context.read<HomeRepo>();
      appStreams = sl<AppStreams>();

      _initStateSettings();
      updateJsonFromColumnGroups();
      updateJsonFromColumnAggregate();
      updateJsonFromGroupByColumns();

      // Stream 구독 설정
      _setupStreamSubscriptions();

      _initialized = true;
    }
  }

  void _setupStreamSubscriptions() {
    _colAggsSubscription =
        ColumnStateManager().colAggsStream.listen((newColAggs) {
      if (mounted) {
        setState(() {
          columnAggregate = Map.from(newColAggs);
        });
        updateJsonFromColumnAggregate();
      }
    });

    // grpCols Stream 구독 (List로 받아서 Set으로 변환)
    _grpColsSubscription =
        ColumnStateManager().grpColsStream.listen((newGrpCols) {
      if (mounted) {
        setState(() {
          groupByColumns = Set<String>.from(newGrpCols);
        });
        updateJsonFromGroupByColumns();
      }
    });
  }

  Future<void> _initStateSettings() async {
    permission = widget.item.permission ?? '';
    theme = widget.item.theme ?? '';
    boardId = widget.item.boardId ?? '';

    final GridItemContent content = widget.item.content!;
    mode = content.mode == 'normal'
        ? TrinaGridMode.normal
        : TrinaGridMode.selectWithOneTap;
    apiId = content.apiId ?? '';
    saveApiId = content.saveApiId ?? '';
    saveApiParams = content.saveApiParams ?? '';
    headerTitle = content.headerTitle ?? '제목';
    rowHeight = content.rowHeight ?? 25;
    showColumn = content.showColumn ?? true;
    enableColumnFilter = content.enableColumnFilter ?? false;
    enableColumnAggregate = content.enableColumnAggregate ?? false;
    showFooter = content.showFooter ?? true;
    showRowNum = content.showRowNum ?? true;
    enableRowChecked = content.enableRowChecked ?? false;

    reqApis = content.reqApis ?? [];
    resApis = content.resApis ?? [];
    colGroups = content.colGroups ?? [];
    columnAggregate = content.columnAggregate ?? {};
    groupByColumns = content.groupByColumns ?? {};

    if (resApis.isNotEmpty) {
      columnState = resetColumn(apiId);
    } else {
      columns = content.columns ??
          [
            TrinaColumn(
                title: 'title', field: 'field', type: TrinaColumnType.text())
          ];
      rows = content.rows ?? [];
    }
    saveResApis(columns);

    if (colGroups.isNotEmpty) {
      resetColumnGroups();
    }
    if (columnAggregate.isNotEmpty || groupByColumns.isNotEmpty) {
      // ColumnStateManager 초기화
      ColumnStateManager().initialize(columnAggregate, groupByColumns);
    }

    // _subscribeApiMenu();
    _subscribeApiIdResponse();
    _subscribeUpdateStackItem();
    _subscribeGridColumnMenu();
  }

  void reloadApiIdResponse(String apiId) {
    dynamic apiResponse = homeRepo.onApiResponse[apiId];
    if (apiResponse != null) {
      final type = apiResponse['data']?['result']?.runtimeType.toString() ?? '';
      final resultData = apiResponse['data']?['result'];
      final list = resultData == null
          ? []
          : (type.contains('JsonMap') ? [resultData] : (resultData as List));

      if (mounted) {
        setState(() {
          rows.clear();
          if (list.isNotEmpty) {
            rows = [
              ...list.map((e) {
                final eM = asMap(e);
                Map<String, dynamic> m = {};
                for (var c in columns) {
                  m.addAll({c.field: eM[c.field] ?? ''});
                }
                return TrinaRow.fromJson(m);
              })
            ];
            print('StackGridCase: rows 생성 완료 - ${rows.length}개 행');
          }
        });
      }

      // mode==selectWithOneTap 이면 첫번째 행 선택
      // if (mode == TrinaGridMode.selectWithOneTap) {
      //   onSelected(TrinaGridOnSelectedEvent(row: rows.first));
      // }
    }
  }

  void _subscribeApiIdResponse() {
    _apiIdResponseSub = homeRepo.getApiIdResponseStream.listen((v) {
      if (v != null) {
        final controller =
            homeRepo.hierarchicalControllers[widget.item.boardId];
        final item = controller?.getById(widget.item.id);
        final currentContent = item?.content as GridItemContent;
        final String receivedApiId = v['if_id'];
        // print('StackGridCase: _subscribeApiIdResponse v = $v');
        // print('StackGridCase: receivedApiId = $receivedApiId');
        // print('StackGridCase: content toJson = ${currentContent.toJson()}');

        // 기설정된 API ID이거나 강제 주입 요청인지 검사
        if ((widget.item.status == StackItemStatus.selected &&
                v['targetWidgetIds'].contains(widget.item.id)) ||
            receivedApiId == currentContent.apiId) {
          fetchResponseData(currentContent, receivedApiId);
        }
      }
    });
  }

  void fetchResponseData(final currentContent, final receivedApiId) {
    apiId = receivedApiId;
    dynamic apiResponse = homeRepo.onApiResponse[apiId];

    if (apiResponse != null &&
        apiResponse.keys.contains('if_id') &&
        apiResponse['if_id'] == apiId) {
      try {
        mode = currentContent.mode == 'normal'
            ? TrinaGridMode.normal
            : TrinaGridMode.selectWithOneTap;
        headerTitle = currentContent.headerTitle ?? '제목';
        rowHeight = currentContent.rowHeight ?? 25;
        showColumn = currentContent.showColumn ?? true;
        showRowNum = currentContent.showRowNum ?? true;
        enableRowChecked = currentContent.enableRowChecked ?? false;
        enableColumnFilter = currentContent.enableColumnFilter ?? false;
        enableColumnAggregate = currentContent.enableColumnAggregate ?? false;
        showFooter = currentContent.showFooter ?? true;

        reqApis = currentContent.reqApis ?? [];
        resApis = currentContent.resApis ?? [];
        colGroups = currentContent.colGroups ?? [];
        columnAggregate = currentContent.columnAggregate ?? {};
        groupByColumns = currentContent.groupByColumns ?? {};

        if (columnState != apiId) {
          resApis = [];
          columnState = resetColumn(apiId);
        }
        saveResApis(columns).then((it) => homeRepo.addOnTapState(it));

        if (colGroups.isNotEmpty) {
          resetColumnGroups();
        }
        if (columnAggregate.isNotEmpty) {
          // ColumnStateManager 업데이트
          ColumnStateManager().updateColAggs(columnAggregate);
        }
        if (groupByColumns.isNotEmpty) {
          ColumnStateManager().updateGrpCols(groupByColumns);
        }

        reloadApiIdResponse(apiId);
        _renderCounter++;
        renderKey = ValueKey('${widget.item.id}_$_renderCounter');
      } catch (e) {
        print('StackGridCase: fetchResponseData error = $e');
      }
    }
  }

  void _subscribeUpdateStackItem() {
    _updateStackItemSub = appStreams.updateStackItemStream.listen((v) {
      if (v?.id == widget.item.id &&
          v is StackGridItem &&
          v.boardId == widget.item.boardId) {
        final StackGridItem item = v;
        final GridItemContent content = item.content!;

        setState(() {
          permission = item.permission;
          theme = item.theme;
          mode = content.mode == 'normal'
              ? TrinaGridMode.normal
              : TrinaGridMode.selectWithOneTap;
          apiId = content.apiId ?? '';
          saveApiId = content.saveApiId ?? '';
          saveApiParams = content.saveApiParams ?? '';
          headerTitle = content.headerTitle ?? '';
          rowHeight = content.rowHeight ?? 25;
          showColumn = content.showColumn ?? true;
          enableColumnFilter = content.enableColumnFilter ?? false;
          enableColumnAggregate = content.enableColumnAggregate ?? false;
          showFooter = content.showFooter ?? true;
          showRowNum = content.showRowNum ?? true;
          enableRowChecked = content.enableRowChecked ?? false;

          reqApis = content.reqApis ?? [];
          resApis = content.resApis ?? [];
          colGroups = content.colGroups ?? [];
          columnAggregate = content.columnAggregate ?? {};
          groupByColumns = content.groupByColumns ?? {};

          if (apiId != columnState && resApis.isNotEmpty) {
            resApis = [];
            columnState = resetColumn(apiId);
            reloadApiIdResponse(apiId);
          }

          if (colGroups.isNotEmpty) {
            resetColumnGroups();
          }
          if (columnAggregate.isNotEmpty || groupByColumns.isNotEmpty) {
            ColumnStateManager().initialize(columnAggregate, groupByColumns);
          }
        });
      }
    });
  }

  void _subscribeGridColumnMenu() {
    _gridColumnMenuSub = appStreams.gridColumnMenuStream.listen((v) {
      if (v != null) {
        setState(() {});
      }
    });
  }

  StackGridItem saveItemContent(Map<String, dynamic> updateJson) {
    final currentItem = _controller(context).getById(widget.item.id);
    final itemContent = currentItem?.content?.toJson() ?? {};
    final updateContent = {...itemContent, ...updateJson};
    final it = currentItem?.copyWith(
        content: GridItemContent.fromJson(updateContent)) as StackGridItem;

    _controller(context).updateItem(it);
    // homeRepo.addOnTapState(it);
    return it;
  }

  @override
  void dispose() {
    _updateStackItemSub?.cancel();
    _apiIdResponseSub?.cancel();
    _gridColumnMenuSub?.cancel();

    // Stream 구독 해제
    _colAggsSubscription?.cancel();
    _grpColsSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isStateManagerReady() && apiId != columnState) {
      resApis = [];
      columnState = resetColumn(apiId);
      reloadApiIdResponse(apiId);
      renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
    }

    return Scaffold(
        appBar: widget.item.status == StackItemStatus.editing
            ? gridEditMenu()
            : null,
        body: Stack(
          fit: StackFit.expand,
          children: [
            TrinaGrid(
              key: renderKey,
              columns: columns,
              rows: rows,
              columnGroups: columnGroups,
              mode: mode,
              onLoaded: (TrinaGridOnLoadedEvent event) {
                stateManager = event.stateManager;
                stateManager.setSelectingMode(TrinaGridSelectingMode.cell);
                stateManager.setShowColumnTitle(showColumn);
                stateManager.setShowColumnFilter(enableColumnFilter);
                stateManager.setShowColumnFooter(enableColumnAggregate);
                stateManager.setAutoEditing(true);
                showRowNumColumn(show: showRowNum);
                enableRowCheck(enable: enableRowChecked);

                // 그룹바이 컬럼 설정
                if (groupByColumns.isNotEmpty) {
                  final groupColumns = columns
                      .where((col) => groupByColumns.contains(col.field))
                      .toList();

                  stateManager.setRowGroup(
                    TrinaRowGroupByColumnDelegate(
                      columns: groupColumns,
                      showFirstExpandableIcon: false,
                    ),
                  );
                } else {
                  stateManager.setRowGroup(
                    TrinaRowGroupByColumnDelegate(
                      columns: [],
                      showFirstExpandableIcon: false,
                    ),
                  );
                }

                stateManager.addListener(() {
                  if (stateManager.currentCell != null) {
                    final column = stateManager.currentColumn;
                    if (column!.type.isSelect) {}
                  }
                });
              },
              columnMenuDelegate: IdevColumnMenuDelegate(),
              onSelected: (event) {
                if (!_isStateManagerReady()) {
                  return;
                }
                onSelected(event);
              },
              onChanged: (event) {
                if (!_isStateManagerReady()) {
                  return;
                }
                onChangedRow(event);
              },
              rowColorCallback: (context) {
                if (!_isStateManagerReady()) {
                  return Colors.transparent;
                }
                return rowColorContext(context);
              },
              configuration: configuration(),
              createHeader: gridHeader,
              createFooter: (v) =>
                  showFooter ? gridFooter(v) : const SizedBox.shrink(),
            ),
          ],
        ));
  }

  bool _isStateManagerReady() {
    try {
      return stateManager != null;
    } catch (e) {
      return false;
    }
  }

  TrinaGridConfiguration configuration() {
    return trinaGridConfig.copyWith(
        style: gridStyle(theme).copyWith(
      rowHeight: rowHeight,
      columnFilterHeight: rowHeight < 30 ? 30 : rowHeight,
    ));
  }

  dynamic fxMath(String apiId, dynamic jsonRow) {
    var exp = FormulaParser(homeRepo.fxs[apiId]['formula'], jsonRow);
    var result = exp.parse;
    return result['value'];
  }

  void onSelected(TrinaGridOnSelectedEvent event) {
    Map<String, dynamic> fields = {};
    Map<String, dynamic> apis = {};

    for (var apiConfig in reqApis) {
      fields[apiConfig.fieldNm ?? ''] = apiConfig.field ?? '';
      final id = apiConfig.apiId.toString().split(RegExp('\\n')).first;
      if (homeRepo.apis.containsKey(id)) {
        apis[id] = homeRepo.apis[id];
      }
    }

    Map<String, dynamic> values = {};
    event.row?.toJson().forEach((key, value) {
      if (fields.keys.contains(key)) {
        values[fields[key]] = value;
      }
    });

    final rowJson = {...event.row!.toJson(), 'apiId': apiId};
    homeRepo.addRowRequestState(rowJson);

    if (apis.isNotEmpty) {
      apis.forEach((key, value) {
        // Map<String, dynamic> params = {
        //   'if_id': key,
        //   'method': value['method'],
        //   'uri': value['uri'],
        //   'token': AuthService.token,
        //   ...values,
        // };
        homeRepo.addApiRequest(key, values);
      });
    }
  }

  void onChangedRow(TrinaGridOnChangedEvent event) {
    if (onChanged.containsKey(event.row.key) &&
        onChanged[event.row.key]['cud'] == 'C') {
      onChanged[event.row.key] = {
        ...onChanged[event.row.key],
        ...event.row.toJson()
      };
    } else {
      if (onChanged.containsKey(event.row.key)) {
        onChanged[event.row.key] = {
          ...onChanged[event.row.key],
          ...event.row.toJson()
        };
      } else {
        TrinaRow orgRow = TrinaRow.fromJson(event.row.toJson());
        orgRow.cells[event.column.field] = TrinaCell(value: event.oldValue);
        onChanged[event.row.key] = {
          'cud': 'U',
          'row': orgRow,
          ...event.row.toJson()
        };
      }
    }

    onChangedFx(event);
  }

  void onChangedFx(TrinaGridOnChangedEvent event) {
    if (resApis.isNotEmpty) {
      resApis
          .where((apiConfig) => apiConfig.apiId.contains('FX-'))
          .forEach((apiConfig) {
        if (homeRepo.fxs.containsKey(apiConfig.apiId) &&
            (homeRepo.fxs[apiConfig.apiId]?['field'] as List?)
                    ?.contains(event.column.field) ==
                true) {
          var exp = FormulaParser(
              homeRepo.fxs[apiConfig.apiId]?['formula'] as String? ?? '',
              event.row.toJson());
          var result = exp.parse;
          event.row.cells[apiConfig.field ?? '']?.value =
              result['value']?.toString();
        }
      });
    }
  }

  Future<void> initRowGroup() async {
    void expandRowGroup(TrinaRow row) {
      if ((row.type.isGroup ?? false) && !row.type.group.expanded) {
        stateManager.toggleExpandedRowGroup(
          rowGroup: row,
        );
      }

      if (row.type.isGroup ?? false) {
        for (final child in row.type.group.children) {
          expandRowGroup(child);
        }
      }
    }

    for (final row in stateManager.refRows.originalList) {
      expandRowGroup(row);
    }
  }

  Future<void> initRowNum() async {
    if (stateManager.columns
            .firstWhereOrNull((e) => e.field == 'rowNum')
            ?.hide ??
        true) {
      return;
    }

    void expandRow(TrinaRow row) {
      row.cells['rowNum']?.value = formatNumber(rows.indexOf(row) + 1);
      if (row.type.isGroup ?? false) {
        for (final child in row.type.group.children) {
          expandRow(child);
        }
      }
    }

    for (final row in stateManager.refRows.originalList) {
      expandRow(row);
    }
  }

  Future<void> initRowFx() async {
    if (resApis.isEmpty) {
      return;
    }
    List<ApiConfig> fxApis =
        resApis.where((apiConfig) => apiConfig.type == 'formula').toList();
    if (fxApis.isEmpty) {
      return;
    }

    void expandRow(TrinaRow row) {
      if (row.type.isGroup ?? false) {
        for (final child in row.type.group.children) {
          expandRow(child);
        }
      } else {
        for (final fxApiConfig in fxApis) {
          row.cells[fxApiConfig.field ?? '']?.value =
              fxMath(fxApiConfig.apiId, row.toJson());
        }
      }
    }

    for (final row in stateManager.refRows.originalList) {
      expandRow(row);
    }
  }

  Future<void> aggregateRowRenderer() async {
    final List<TrinaColumn> visibleColumns = columns.isNotEmpty
        ? stateManager.refColumns.where((column) => !column.hide).toList()
        : stateManager.columns;

    final List<TrinaRow> rows = stateManager.refRows.originalList;
    for (final row in rows) {
      for (final column in visibleColumns) {
        if ((column.type.isNumber ||
                column.type.isCurrency ||
                column.type.isPercentage) &&
            (row.type.isGroup ?? false)) {
          List<num?> values = [
            if (currentColumnAggregate['${column.field}-onSum'] ?? false)
              TrinaAggregateHelper.sum(
                rows: rows,
                column: column,
                filter: (cell) => groupByColumnFilter(
                  TrinaColumnRendererContext(
                    column: column,
                    rowIdx: rows.indexOf(row),
                    row: row,
                    cell: cell,
                    stateManager: stateManager,
                  ),
                  cell,
                ),
              ),
            if (currentColumnAggregate['${column.field}-onAvg'] ?? false)
              TrinaAggregateHelper.average(
                rows: rows,
                column: column,
                filter: (cell) => groupByColumnFilter(
                  TrinaColumnRendererContext(
                    column: column,
                    rowIdx: rows.indexOf(row),
                    row: row,
                    cell: cell,
                    stateManager: stateManager,
                  ),
                  cell,
                ),
              ),
            if (currentColumnAggregate['${column.field}-onMin'] ?? false)
              TrinaAggregateHelper.min(
                rows: rows,
                column: column,
                filter: (cell) => groupByColumnFilter(
                  TrinaColumnRendererContext(
                    column: column,
                    rowIdx: rows.indexOf(row),
                    row: row,
                    cell: cell,
                    stateManager: stateManager,
                  ),
                  cell,
                ),
              ),
            if (currentColumnAggregate['${column.field}-onMax'] ?? false)
              TrinaAggregateHelper.max(
                rows: rows,
                column: column,
                filter: (cell) => groupByColumnFilter(
                  TrinaColumnRendererContext(
                    column: column,
                    rowIdx: rows.indexOf(row),
                    row: row,
                    cell: cell,
                    stateManager: stateManager,
                  ),
                  cell,
                ),
              ),
            if (currentColumnAggregate['${column.field}-onCount'] ?? false)
              TrinaAggregateHelper.count(
                rows: rows,
                column: column,
                filter: (cell) => groupByColumnFilter(
                  TrinaColumnRendererContext(
                    column: column,
                    rowIdx: rows.indexOf(row),
                    row: row,
                    cell: cell,
                    stateManager: stateManager,
                  ),
                  cell,
                ),
              ),
          ];

          row.cells[column.field]?.value = values.first;
        }
      }
    }
  }

  Future<void> initExportUtils() async {
    await initRowGroup();
    await initRowNum();
    await initRowFx();
    await aggregateRowRenderer().then((v) {
      stateManager.resetCurrentState();
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          stateManager.setShowLoading(false);
        }
      });
      exportUtils = GridExportUtils(
        context: context,
        stateManager: stateManager,
        initialTitle: headerTitle,
        onExportStatusUpdate: (exporting, status) {},
      );
    });
  }

  Widget gridPermission(TrinaGridStateManager stateManager) {
    if (permission == 'read') {
      return const SizedBox();
    }

    return Wrap(
      spacing: 10,
      children: [
        if (permission.contains('write') || permission == 'all') ...[
          Tooltip(
            message: '추가',
            child: InkWell(
              onTap: () {
                addRows(stateManager);
              },
              child: Icon(Icons.add, color: gridStyle(theme).iconColor),
            ),
          ),
        ],
        if (permission.contains('delete') || permission == 'all')
          Tooltip(
            message: '삭제',
            child: InkWell(
              onTap: () {
                removeRows(stateManager);
              },
              child: Icon(Icons.remove, color: gridStyle(theme).iconColor),
            ),
          ),
        Tooltip(
          message: '취소',
          child: InkWell(
            onTap: () {
              cancelRows();
            },
            child: Icon(Icons.undo, color: gridStyle(theme).iconColor),
          ),
        ),
        Tooltip(
          message: '저장',
          child: InkWell(
            onTap: () {
              saveRows();
            },
            child: Icon(Icons.save, color: gridStyle(theme).iconColor),
          ),
        ),
        if (permission.contains('pdf') || permission == 'all')
          Tooltip(
            message: 'PDF',
            child: InkWell(
              onTap: () async {
                await initExportUtils();

                exportUtils.showExportOptionsDialog(GridExportUtils.formatPdf);
              },
              child: Icon(Symbols.picture_as_pdf,
                  color: gridStyle(theme).iconColor),
            ),
          ),
        if (permission.contains('csv') || permission == 'all')
          Tooltip(
            message: '엑셀',
            child: InkWell(
              onTap: () async {
                await initExportUtils();
                exportUtils.showExportOptionsDialog(GridExportUtils.formatCsv);
              },
              child: Icon(Symbols.csv, color: gridStyle(theme).iconColor),
            ),
          ),
        if (permission.contains('json') || permission == 'all')
          Tooltip(
            message: 'JSON',
            child: InkWell(
              onTap: () async {
                await initExportUtils();
                exportUtils.showExportOptionsDialog(GridExportUtils.formatJson);
              },
              child: Icon(Symbols.file_json, color: gridStyle(theme).iconColor),
            ),
          ),
        const SizedBox.shrink(),
      ],
    );
  }

  Widget gridHeader(TrinaGridStateManager stateManager) {
    return headerTitle.isEmpty
        ? const SizedBox()
        : SizedBox(
            height: 30,
            child: Row(
              children: [
                Expanded(
                    child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(headerTitle,
                            style: TextStyle(
                                color: gridStyle(theme).columnTextStyle.color ??
                                    Colors.black)))),
                gridPermission(stateManager)
              ],
            ));
  }

  AppBar gridEditMenu() {
    return AppBar(
      toolbarHeight: 30,
      title: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Tooltip(
              message: showRowNum ? '순번 감추기' : '순번 보이기',
              child: IconButton(
                icon: showRowNum
                    ? const Icon(
                        Symbols.format_list_numbered,
                        color: Colors.blueAccent,
                        size: 20,
                      )
                    : const Icon(Symbols.format_list_numbered,
                        color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    showRowNumColumn();
                    saveItemContent({"showRowNum": showRowNum});
                  });
                },
              ),
            ),
            Tooltip(
              message: '체크 박스',
              child: IconButton(
                icon: enableRowChecked
                    ? const Icon(
                        Symbols.check_box,
                        color: Colors.blueAccent,
                        size: 20,
                      )
                    : const Icon(Symbols.check_box,
                        color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    enableRowCheck();
                    saveItemContent({"enableRowChecked": enableRowChecked});
                  });
                },
              ),
            ),
            Tooltip(
              message: '폭 자동 조정',
              child: IconButton(
                icon: enableRowChecked
                    ? const Icon(
                        Symbols.fit_width,
                        color: Colors.blueAccent,
                        size: 20,
                      )
                    : const Icon(Symbols.fit_width,
                        color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    sampleGrid();
                    renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
                  });
                },
              ),
            ),
            Tooltip(
              message: showColumn ? '컬럼 전체 감추기' : '컬럼 전체 보이기',
              child: IconButton(
                icon: showColumn
                    ? const Icon(
                        Symbols.toolbar,
                        color: Colors.blueAccent,
                        size: 20,
                      )
                    : const Icon(Symbols.toolbar, color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    showColumn = !showColumn;
                    stateManager.setShowColumnTitle(showColumn);
                    saveItemContent({"showColumn": showColumn});
                  });
                },
              ),
            ),
            Tooltip(
              message: enableColumnFilter ? '필터 전체 감추기' : '필터 전체 보이기',
              child: IconButton(
                icon: enableColumnFilter
                    ? const Icon(
                        Symbols.manage_search,
                        color: Colors.blueAccent,
                        size: 20,
                      )
                    : const Icon(Symbols.manage_search,
                        color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    enableColumnFilter = !enableColumnFilter;
                    stateManager.setShowColumnFilter(enableColumnFilter);
                    saveItemContent({"enableColumnFilter": enableColumnFilter});
                  });
                },
              ),
            ),
            Tooltip(
              message: enableColumnAggregate ? '컬럼 집계 불가' : '컬럼 집계 가능',
              child: IconButton(
                icon: enableColumnAggregate
                    ? const Icon(
                        Symbols.calculate,
                        color: Colors.blueAccent,
                        size: 20,
                      )
                    : const Icon(Symbols.calculate,
                        color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    enableColumnAggregate = !enableColumnAggregate;
                    stateManager.setShowColumnFooter(enableColumnAggregate);
                    saveItemContent(
                        {"enableColumnAggregate": enableColumnAggregate});
                  });
                },
              ),
            ),
            Tooltip(
              message: showFooter ? '풋터 감추기' : '풋터 보이기',
              child: IconButton(
                icon: showFooter
                    ? const Icon(
                        Symbols.bottom_navigation,
                        color: Colors.blueAccent,
                        size: 20,
                      )
                    : const Icon(Symbols.bottom_navigation,
                        color: Colors.grey, size: 20),
                onPressed: () {
                  setState(() {
                    showFooter = !showFooter;
                    saveItemContent({"showFooter": showFooter});
                    renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
                  });
                },
              ),
            ),
            Tooltip(
              message: '컬럼그룹 추가',
              child: IconButton(
                icon: const Icon(Symbols.add_row_above, size: 20),
                onPressed: () {
                  addColumnGroup();
                },
              ),
            ),
            Tooltip(
              message: '컬럼그룹 삭제',
              child: IconButton(
                icon: const Icon(Symbols.variable_remove, size: 20),
                onPressed: () {
                  removeColumnGroup();
                },
              ),
            ),
            Tooltip(
              message: '컬럼 추가',
              child: IconButton(
                icon: const Icon(Symbols.add_column_right, size: 20),
                onPressed: () {
                  addColumn();
                  saveResApis(stateManager.columns);
                },
              ),
            ),
            Tooltip(
              message: '컬럼 삭제',
              child: IconButton(
                icon: const Icon(Symbols.remove_road, size: 20),
                onPressed: () {
                  removeColumn();
                  saveResApis(stateManager.columns);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget gridFooter(TrinaGridStateManager stateManager) {
    stateManager.setPageSize(
      pageSize,
      notify: false,
    );

    return !showFooter
        ? const SizedBox()
        : LayoutBuilder(
            builder: (_, size) {
              return SizedBox(
                  height: rowHeight < 30 ? 30 : rowHeight,
                  child: Row(
                    children: [
                      Expanded(child: TrinaPagination(stateManager)),
                      if (size.maxWidth > 300)
                        SizedBox(
                          width: 50,
                          child: NewField(
                              type: FieldType.select,
                              name: 'pageSize',
                              labelText: 'pageSize',
                              initialValue: pageSize.toString(),
                              items: const ['10', '30', '50', '100', '500'],
                              widgetName: 'grid',
                              theme: theme,
                              callback: (v) {
                                setState(() {
                                  pageSize = int.tryParse(v) ?? pageSize;
                                  stateManager.setPageSize(pageSize);
                                  stateManager.resetPage(
                                      resetCurrentState: true);
                                });
                              }),
                        )
                    ],
                  ));
            },
          );
  }

  Color rowColorContext(TrinaRowColorContext rowColorContext) {
    final row = rowColorContext.row;
    if (onChanged.containsKey(row.key) &&
        onChanged[row.key].containsKey('cud')) {
      if (onChanged[row.key]['cud'] == 'C') {
        return Colors.yellowAccent;
      } else if (onChanged[row.key]['cud'] == 'U') {
        return Colors.lightGreenAccent;
      } else {
        return Colors.red.shade100;
      }
    } else {
      return rowColorContext.rowIdx % 2 == 0
          ? stateManager.configuration.style.oddRowColor ??
              stateManager.configuration.style.rowColor
          : stateManager.configuration.style.evenRowColor ??
              stateManager.configuration.style.rowColor;
    }
  }

  void addRows(TrinaGridStateManager stateManager) async {
    TrinaRow newRow = stateManager.getNewRows(count: 1).first;
    int rowIdx = stateManager.currentRowIdx ?? stateManager.rows.length;
    stateManager.insertRows(rowIdx, [newRow]);
    stateManager.setCurrentSelectingRowsByRange(rowIdx, rowIdx);

    onChanged[newRow.key] = {'cud': 'C', ...newRow.toJson()};
  }

  void removeRows(TrinaGridStateManager stateManager) async {
    for (var row in stateManager.checkedRows) {
      if (onChanged.containsKey(row.key) && onChanged[row.key]['cud'] == 'C') {
        onChanged.remove(row.key);
        stateManager.removeRows([row]);
      } else {
        onChanged[row.key] = {'cud': 'D', ...row.toJson()};
      }
      row.setChecked(false);
    }

    stateManager.setShowLoading(true);
    stateManager.setPage(1, notify: false);
    stateManager.setShowLoading(false);
  }

  void cancelRows() async {
    for (var row in stateManager.checkedRows) {
      if (onChanged.containsKey(row.key)) {
        if (onChanged[row.key]['cud'] == 'C') {
          onChanged.remove(row.key);
          stateManager.removeRows([row]);
        } else if (onChanged[row.key]['cud'] == 'U') {
          TrinaRow orgRow = onChanged[row.key]['row'];
          stateManager.insertRows(row.sortIdx - 1, [orgRow]);
          stateManager.removeRows([row], notify: false);
          onChanged.remove(row.key);
        } else if (onChanged[row.key]['cud'] == 'D') {
          onChanged.remove(row.key);
        }
      }

      row.setChecked(false);
    }

    stateManager.setShowLoading(true);
    stateManager.setPage(1, notify: false);
    stateManager.setShowLoading(false);
  }

  Future<void> saveRows() async {
    final selectedRows =
        rows.where((row) => onChanged.containsKey(row.key)).toList();
    final cCnt = onChanged.entries.where((e) => e.value['cud'] == 'C').length;
    final uCnt = onChanged.entries.where((e) => e.value['cud'] == 'U').length;
    final dCnt = onChanged.entries.where((e) => e.value['cud'] == 'D').length;
    final title = '$headerTitle\n변경 내역> 신규: $cCnt건 / 수정: $uCnt건 / 삭제: $dCnt건';

    final PopupGridResult? result = await openPopupGrid(
        context, title, columns, selectedRows,
        rowColorCallback: rowColorContext);

    if (result != null && result.buttonKey == 'ok') {
      List<Map> json = selectedRows.map((e) {
        Map<String, dynamic> em = {
          ...e.toJson(),
          'crud_gb': onChanged[e.key]['cud'],
          'CUD': onChanged[e.key]['cud'],
        };
        em.removeWhere((key, value) => value.toString().isEmpty);
        return em;
      }).toList();

      final currentContent = widget.item.content;
      final saveApiId = currentContent?.saveApiId;
      final saveApiParams = currentContent?.saveApiParams;

      if (currentContent != null && saveApiId != null && saveApiId.isNotEmpty) {
        final apiParams = saveApiParams != null ? asMap(saveApiParams) : {};
        apiParams['data'] = json;

        final api = homeRepo.apis[saveApiId];
        if (api != null) {
          Map<String, dynamic> params = {
            // 'if_id': api['apiId'],
            // 'method': api['method'],
            // 'uri': api['uri'],
            // 'token': AuthService.token,
            ...apiParams
          };

          homeRepo.addApiRequest(saveApiId, params);

          setState(() {
            onChanged.forEach((key, value) {
              rows.removeWhere((row) => row.key == key && value['cud'] == 'D');
            });
            renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
            onChanged.clear();
          });
        } else {}
      } else {}
    } else {}
  }

  void updateJsonFromColumnGroups() {
    colGroups = columnGroups.map((group) => group.toJson()).toList();
    saveItemContent({"colGroups": colGroups});
  }

  void updateJsonFromColumnAggregate() {
    columnAggregate = ColumnStateManager().colAggs;
    saveItemContent({"columnAggregate": columnAggregate});
  }

  void updateJsonFromGroupByColumns() {
    // Set을 List로 변환하여 저장 (JSON 직렬화 가능)
    final groupByColumnsList = ColumnStateManager().grpColsList;
    saveItemContent({"groupByColumns": groupByColumnsList});
  }

  void resetColumnGroups() {
    TrinaColumnGroup assignTitle(TrinaColumnGroup group) {
      final inkWell = group.title as InkWell;
      final title = (inkWell.child as Text).data ?? '';
      group.setTitle(columnGroupTitle(title));
      return group;
    }

    columnGroups = colGroups.map((json) {
      TrinaColumnGroup group = TrinaColumnGroup.fromJson(json);
      if (group.hasChildren) {
        for (var child in group.children!) {
          assignTitle(child);
        }
      }
      return assignTitle(group);
    }).toList();
  }

  TrinaColumnGroup? getGroupByTitle(String title) {
    TrinaColumnGroup? findGroupRecursively(List<TrinaColumnGroup> groups) {
      for (var group in groups) {
        if (group.title is InkWell) {
          final inkWell = group.title as InkWell;
          if (inkWell.child is Text && (inkWell.child as Text).data == title) {
            return group;
          }
        }

        if (group.hasChildren) {
          final foundInChildren = findGroupRecursively(group.children!);
          if (foundInChildren != null) {
            return foundInChildren;
          }
        }
      }
      return null;
    }

    return findGroupRecursively(columnGroups);
  }

  void processGroups(int maxLevel) {
    for (var topGroup in columnGroups) {
      final processedGroup = processGroup(topGroup, maxLevel);
      if (processedGroup != null) {
        cp.add(processedGroup);
      }
    }
  }

  TrinaColumnGroup? processGroup(TrinaColumnGroup group, int maxLevel) {
    if (group.expandedColumn == true) {
      return group;
    }

    if (group.hasChildren) {
      return processGroupWithChildren(group, maxLevel);
    }

    return group;
  }

  TrinaColumnGroup? processGroupWithChildren(
      TrinaColumnGroup group, int maxLevel) {
    final newChildren = <TrinaColumnGroup>[];
    final mergedFields = <String>[];
    var hasOnlyLeafChildren = true;

    for (var child in group.children!) {
      if (child.level == maxLevel) {
        if (child.hasFields) {
          mergedFields.addAll(child.fields!);
        }
      } else {
        hasOnlyLeafChildren = false;
        final processedChild = processGroup(child, maxLevel);
        if (processedChild != null) {
          newChildren.add(processedChild);
        }
      }
    }

    if (hasOnlyLeafChildren && mergedFields.isNotEmpty) {
      return createFieldGroup(group, mergedFields);
    }

    if (newChildren.isEmpty && mergedFields.isEmpty) {
      return null;
    }

    return createGroupWithChildren(group, newChildren);
  }

  TrinaColumnGroup createFieldGroup(
      TrinaColumnGroup group, List<String> fields) {
    return TrinaColumnGroup(
      title: group.title,
      fields: fields,
      backgroundColor: group.backgroundColor,
      expandedColumn: group.expandedColumn,
      level: group.level,
    );
  }

  TrinaColumnGroup createGroupWithChildren(
      TrinaColumnGroup group, List<TrinaColumnGroup> children) {
    return TrinaColumnGroup(
      title: group.title,
      children: children,
      backgroundColor: group.backgroundColor,
      expandedColumn: group.expandedColumn,
      level: group.level,
    );
  }

  int findMaxLevel() {
    int maxLevel = 0;

    void findMaxLevelRecursive(TrinaColumnGroup group) {
      if (group.level > maxLevel) {
        maxLevel = group.level;
      }
      if (group.hasChildren) {
        for (var child in group.children!) {
          findMaxLevelRecursive(child);
        }
      }
    }

    for (var group in columnGroups) {
      findMaxLevelRecursive(group);
    }

    return maxLevel;
  }

  void onExpandedColumnGroup(String title, bool isExpanded) {
    if (title.isEmpty) {
      return;
    }

    bool isFinished = false;

    void updateGroupRecursive(List<TrinaColumnGroup> groups) {
      for (var i = 0; i < groups.length; i++) {
        if (groups[i].title is InkWell) {
          final inkWell = groups[i].title as InkWell;
          if (inkWell.child is Text && (inkWell.child as Text).data == title) {
            if (isExpanded) {
              TrinaColumnGroup newGroup = TrinaColumnGroup(
                title: groups[i].title,
                fields: groups[i].children?.first.fields,
                backgroundColor: groups[i].backgroundColor,
                expandedColumn: true,
                level: groups[i].level,
              );
              groups.remove(groups[i].children?.first);
              groups.replaceRange(i, i, [newGroup]);
            } else {
              TrinaColumnGroup newGroup = TrinaColumnGroup(
                title: groups[i].title,
                fields: groups[i].fields,
                backgroundColor: groups[i].backgroundColor,
                expandedColumn: true,
                level: groups[i].level,
              );
              groups.remove(groups[i]);
              groups.replaceRange(i, i, [newGroup]);
            }

            isFinished = true;
          }
        }

        if (isFinished) {
          return;
        }

        if (groups[i].hasChildren) {
          updateGroupRecursive(groups[i].children!);
        }
      }
    }

    updateGroupRecursive(columnGroups);

    updateJsonFromColumnGroups();

    setState(() {
      columnGroups;
    });
  }

  void onSplitColumnGroups(String title) {
    if (title.isEmpty) {
      return;
    }

    bool isSplited = false;

    void updateGroupRecursive(List<TrinaColumnGroup> groups) {
      for (var i = 0; i < groups.length; i++) {
        if (groups[i].title is InkWell) {
          final inkWell = groups[i].title as InkWell;
          if (inkWell.child is Text && (inkWell.child as Text).data == title) {
            final parentGroup = groups[i].parent;
            final currentFields = groups[i].fields;
            final currentChildren = groups[i].children;

            List<TrinaColumnGroup> newChildren = [];
            int index = 0;
            if (currentChildren != null) {
              for (var newChild in currentChildren) {
                newChildren.add(TrinaColumnGroup(
                  title: columnGroupTitle('$title - ${++index}'),
                  children: [newChild],
                  backgroundColor: groups[i].backgroundColor,
                  expandedColumn: groups[i].expandedColumn,
                  level: groups[i].level,
                ));
              }
            }
            if (currentFields != null) {
              for (var newField in currentFields) {
                newChildren.add(TrinaColumnGroup(
                  title: columnGroupTitle('$title - ${++index}'),
                  fields: [newField],
                  backgroundColor: groups[i].backgroundColor,
                  expandedColumn: groups[i].expandedColumn,
                  level: groups[i].level,
                ));
              }
            }

            if (parentGroup != null) {
              groups.remove(groups[i]);
              parentGroup.children?.addAll(newChildren);
            } else {
              groups.replaceRange(i, i, newChildren);
            }

            isSplited = true;
          }
        }

        if (isSplited) {
          return;
        }

        if (groups[i].hasChildren) {
          updateGroupRecursive(groups[i].children!);
        }
      }
    }

    updateGroupRecursive(columnGroups);

    updateJsonFromColumnGroups();

    setState(() {
      columnGroups;
    });
  }

  void onGroupTitleChanged(String oldTitle, String newTitle) {
    if (newTitle.isEmpty) {
      return;
    }

    void updateGroupRecursive(List<TrinaColumnGroup> groups) {
      for (var i = 0; i < groups.length; i++) {
        if (groups[i].title is InkWell) {
          final inkWell = groups[i].title as InkWell;
          if (inkWell.child is Text &&
              (inkWell.child as Text).data == oldTitle) {
            final currentFields = groups[i].fields;
            final currentChildren = groups[i].children;

            TrinaColumnGroup? sameTitleGroup;
            for (var j = 0; j < groups.length; j++) {
              if (i != j && groups[j].title is InkWell) {
                final neighborInkWell = groups[j].title as InkWell;
                if (neighborInkWell.child is Text &&
                    (neighborInkWell.child as Text).data == newTitle) {
                  sameTitleGroup = groups[j];
                  break;
                }
              }
            }

            if (sameTitleGroup != null) {
              final mergedFields = [
                ...?currentFields,
                ...?sameTitleGroup.fields,
              ];
              final mergedChildren = [
                ...?currentChildren,
                ...?sameTitleGroup.children,
              ];

              groups[i] = TrinaColumnGroup(
                title: columnGroupTitle(newTitle),
                fields: mergedFields.isNotEmpty ? mergedFields : null,
                children: mergedChildren.isNotEmpty ? mergedChildren : null,
                backgroundColor: groups[i].backgroundColor,
                expandedColumn: groups[i].expandedColumn,
                level: groups[i].level,
              );

              groups.remove(sameTitleGroup);
            } else {
              groups[i] = TrinaColumnGroup(
                title: columnGroupTitle(newTitle),
                fields: currentFields,
                children: currentChildren,
                backgroundColor: groups[i].backgroundColor,
                expandedColumn: groups[i].expandedColumn,
                level: groups[i].level,
              );
            }
          }
        }

        if (groups[i].hasChildren) {
          updateGroupRecursive(groups[i].children!);
        }
      }
    }

    updateGroupRecursive(columnGroups);

    updateJsonFromColumnGroups();

    setState(() {
      columnGroups;
    });
  }

  Widget columnGroupTitle(String title) {
    return InkWell(
      onTap: () {
        final group = getGroupByTitle(title);
        final fieldsLength = group?.fields?.length ?? 0;
        final childrenLength = group?.children?.length ?? 0;
        final isExpanded = group?.expandedColumn ?? false;
        final isChildExpanded = (childrenLength != 1)
            ? false
            : (group?.children?.first.expandedColumn ?? false);

        if (StackItemStatus.editing == widget.item.status) {
          showDialog(
            context: context,
            builder: (context) {
              final controller = TextEditingController(text: title);
              return AlertDialog(
                title: Text(title),
                content: TextField(
                  controller: controller,
                  onChanged: (value) {},
                ),
                actions: [
                  if ((fieldsLength == 1 && childrenLength == 0) ||
                      isExpanded ||
                      isChildExpanded)
                    TextButton(
                      onPressed: () {
                        onExpandedColumnGroup(
                            title, isExpanded || isChildExpanded);
                        Navigator.of(context).pop();
                      },
                      child: const Text('컬럼확장'),
                    ),
                  if (fieldsLength > 1 || childrenLength > 1)
                    TextButton(
                      onPressed: () {
                        onSplitColumnGroups(title);
                        Navigator.of(context).pop();
                      },
                      child: const Text('머지해제'),
                    ),
                  TextButton(
                    onPressed: () {
                      final newTitle = controller.text.trim();
                      if (newTitle.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('그룹명은 최소 1글자 이상이어야 합니다.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }
                      onGroupTitleChanged(title, newTitle);
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      },
      child: Text(
        title,
        style: gridStyle(theme).columnTextStyle,
      ),
    );
  }

  TrinaColumnGroup? addChildGroup(String field, int level, int maxLevel) {
    return level == maxLevel
        ? TrinaColumnGroup(
            title: columnGroupTitle('$field - $level'),
            fields: [field],
            backgroundColor: gridStyle(theme).evenRowColor,
            expandedColumn: false,
            level: level,
          )
        : null;
  }

  void showRowNumColumn({bool? show}) {
    showRowNum = show ?? !showRowNum;

    // 안전하게 컬럼 찾기
    final col = stateManager.refColumns.originalList
        .where((column) => column.field == 'rowNum')
        .firstOrNull;

    if (col != null) {
      stateManager.hideColumn(col, !showRowNum);
    }
  }

  void enableRowCheck({bool? enable}) {
    enableRowChecked = enable ?? !enableRowChecked;

    // 안전하게 컬럼 찾기
    final col =
        stateManager.columns.where((e) => e.field == 'rowNum').firstOrNull;

    if (col != null) {
      col.enableRowChecked = enableRowChecked;
      col.width = enableRowChecked ? 120 : 90;
    }
  }

  void addColumnGroup() {
    cp.clear();
    if (columnGroups.isEmpty) {
      List<TrinaColumnGroup> newGroups = [];
      for (var field in columns.map((e) => e.field)) {
        final newGroup = TrinaColumnGroup(
          title: columnGroupTitle(field),
          fields: [field],
          backgroundColor: gridStyle(theme).columnTextStyle.backgroundColor,
          expandedColumn: false,
          level: 0,
        );
        newGroups.add(newGroup);
      }
      columnGroups.addAll(newGroups);
    } else {
      for (var topGroup in columnGroups) {
        TrinaColumnGroup processGroup(TrinaColumnGroup group) {
          if (group.hasFields) {
            if (group.expandedColumn == true) {
              return group;
            } else {
              String parentTitle = '';
              if (group.title is InkWell) {
                final inkWell = group.title as InkWell;
                if (inkWell.child is Text) {
                  parentTitle = (inkWell.child as Text).data ?? '';
                }
              }

              List<TrinaColumnGroup> children = [];
              for (var field in group.fields ?? []) {
                final childGroup = TrinaColumnGroup(
                  title: columnGroupTitle('$parentTitle - $field'),
                  fields: [field],
                  backgroundColor:
                      gridStyle(theme).columnTextStyle.backgroundColor,
                  level: group.level + 1,
                );
                children.add(childGroup);
              }

              return TrinaColumnGroup(
                title: group.title,
                children: children,
                backgroundColor:
                    gridStyle(theme).columnTextStyle.backgroundColor,
                expandedColumn: group.expandedColumn,
                level: group.level,
              );
            }
          } else if (group.hasChildren) {
            List<TrinaColumnGroup> newChildren = group.children!.map((child) {
              return processGroup(child);
            }).toList();

            return TrinaColumnGroup(
              title: group.title,
              children: newChildren,
              backgroundColor: gridStyle(theme).columnTextStyle.backgroundColor,
              expandedColumn: group.expandedColumn,
              level: group.level,
            );
          }
          return group;
        }

        cp.add(processGroup(topGroup));
      }

      columnGroups.clear();
      columnGroups.addAll(cp);
    }

    updateJsonFromColumnGroups();

    setState(() {
      columnGroups;
      stateManager.setShowColumnGroups(false);
      stateManager.setShowColumnGroups(true);
    });
  }

  void removeColumnGroup() {
    cp.clear();
    final maxLevel = findMaxLevel();

    if (maxLevel == 0) {
      columnGroups.clear();
      setState(() {
        columnGroups;
      });
      return;
    }

    processGroups(maxLevel);

    columnGroups.clear();
    if (cp.isNotEmpty) {
      columnGroups.addAll(cp);
    }

    updateJsonFromColumnGroups();

    setState(() {
      columnGroups;
    });
  }

  String generateFieldId() {
    final fields = stateManager.columns.map((c) => c.field).toList();
    while (true) {
      final id = 'f_${const Uuid().v1().substring(0, 2)}';
      if (!fields.contains(id)) {
        return id;
      }
    }
  }

  void addColumn() {
    final currentColumn = stateManager.currentColumn;
    int colIdx = stateManager.columns.length;
    if (currentColumn != null) {
      colIdx = stateManager.columnIndex(currentColumn) ?? 0;
      colIdx++;
    }
    final List<TrinaColumn> addedColumns = [];
    final field = generateFieldId();
    addedColumns.add(
      TrinaColumn(
        title: field,
        field: field,
        type: TrinaColumnType.text(),
        width: 100,
        footerRenderer: footerRenderer,
      ),
    );
    stateManager.insertColumns(colIdx, addedColumns);

    if (columnGroups.isNotEmpty) {
      final maxLevel = findMaxLevel();

      Map<int, TrinaColumnGroup?> groupMap = {};
      for (int level = 0; level <= maxLevel; level++) {
        groupMap[level] = addChildGroup(field, level, maxLevel);
      }

      for (int level = maxLevel; level > 0; level--) {
        if (groupMap[level - 1] == null) {
          groupMap[level - 1] = TrinaColumnGroup(
            title: columnGroupTitle('$field - ${level - 1}'),
            children: [groupMap[level]!],
            backgroundColor: gridStyle(theme).evenRowColor,
            expandedColumn: false,
            level: level - 1,
          );
        }
      }
      TrinaColumnGroup parentGroup = groupMap[0]!;

      columnGroups.add(parentGroup);
    }

    updateJsonFromColumnGroups();

    setState(() {
      columnGroups;
    });
  }

  void removeColumn() {
    final currentColumn = stateManager.currentColumn;
    if (currentColumn == null) {
      if (columns.isNotEmpty) {
        stateManager.removeColumns([columns.last]);
      }
      return;
    }
    stateManager.removeColumns([currentColumn]);
  }

  String? getColumnType(String columnType) {
    final result = FieldType.values
        .firstWhereOrNull((e) => columnType.toLowerCase().contains(e.name));
    return result?.name ?? 'text';
  }

  Future<StackGridItem> saveResApis(List<TrinaColumn> columns,
      {String? apiId}) async {
    List<ApiConfig> updatedApiConfigs = [];

    for (var col in columns) {
      if (col.field != 'rowNum') {
        final oldJson = resApis.firstWhereOrNull((e) => e.field == col.field);
        updatedApiConfigs.add(ApiConfig.fromJson({
          'apiId': oldJson?.apiId ?? apiId ?? '',
          'field': col.field,
          'type': oldJson?.type ?? getColumnType(col.type.toString()),
          'fieldNm': col.title,
          'width': oldJson?.width ?? col.width.toInt(),
          'format': oldJson?.format ?? 'default',
          'enabled': oldJson?.enabled.toString(),
          'checked': 'true'
        }));
      }
    }

    return saveItemContent(
        {'resApis': apiConfigsToJsonString(updatedApiConfigs)});
  }

  void sampleGrid() {
    columns = [
      rowNumColumn(),
      ...[1, 2, 3, 4].map((e) => TrinaColumn(
            title: 'field$e',
            field: e == 1 ? 'grade' : 'field$e',
            width: e == 1 ? 200 : 140,
            type: switch (e) {
              1 => gridType('grade', 'select'),
              2 => TrinaColumnType.text(),
              3 => TrinaColumnType.number(),
              4 => TrinaColumnType.number(),
              _ => TrinaColumnType.text(),
            },
            editCellRenderer: (defaultEditCellWidget, cell, controller,
                    focusNode, handleSelected) =>
                editCellRenderer(
              defaultEditCellWidget,
              cell,
              controller,
              focusNode,
              handleSelected,
              typeName: e == 1
                  ? 'select'
                  : e > 1
                      ? 'number'
                      : '',
            ),
            renderer: e == 1
                ? selectRenderer
                : e > 1
                    ? numberRenderer
                    : null,
            footerRenderer: footerRenderer,
          ))
    ];

    rows = DummyData.rowsByColumns(length: 50, columns: columns);
  }
}
