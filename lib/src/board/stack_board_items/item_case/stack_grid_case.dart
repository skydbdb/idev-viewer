import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
import './stack_grid_case/grid_export_utils.dart';
import './stack_grid_case/grid_renderer_mixin.dart';
import 'package:idev_v1/src/board/stack_board_items/common/models/api_config.dart';

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
  String apiId = '', postApiId = '', putApiId = '', deleteApiId = '';
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
  int pageSize = 30;
  double rowHeight = 25;
  TrinaGridMode mode = TrinaGridMode.normal;
  Map<Key, dynamic> onChanged = {};

  late ValueKey renderKey;
  int _renderCounter = 0;
  bool _initialized = false;

  StreamSubscription? _apiIdResponseSub;
  StreamSubscription? _gridColumnMenuSub;
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
      }
    });

    // grpCols Stream 구독 (List로 받아서 Set으로 변환)
    _grpColsSubscription =
        ColumnStateManager().grpColsStream.listen((newGrpCols) {
      if (mounted) {
        setState(() {
          groupByColumns = Set<String>.from(newGrpCols);
        });
      }
    });
  }

  Future<void> _initStateSettings() async {
    permission = widget.item.permission;
    theme = widget.item.theme;
    boardId = widget.item.boardId;

    final GridItemContent content = widget.item.content!;
    mode = content.mode == 'normal'
        ? TrinaGridMode.normal
        : TrinaGridMode.selectWithOneTap;
    apiId = content.apiId ?? '';
    postApiId = content.postApiId ?? '';
    putApiId = content.putApiId ?? '';
    deleteApiId = content.deleteApiId ?? '';
    headerTitle = content.headerTitle ?? '제목';
    rowHeight = content.rowHeight ?? 25;
    showColumn = content.showColumn ?? true;
    enableColumnFilter = content.enableColumnFilter ?? false;
    enableColumnAggregate = content.enableColumnAggregate ?? false;
    showFooter = content.showFooter ?? true;
    showRowNum = content.showRowNum ?? true;
    enableRowChecked = content.enableRowChecked ?? false;

    reqApis = content.reqApis;
    resApis = content.resApis;
    colGroups = content.colGroups;
    columnAggregate = content.columnAggregate;
    groupByColumns = content.groupByColumns;

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

    if (colGroups.isNotEmpty) {
      resetColumnGroups();
    }
    if (columnAggregate.isNotEmpty || groupByColumns.isNotEmpty) {
      // ColumnStateManager 초기화
      ColumnStateManager().initialize(columnAggregate, groupByColumns);
    }

    _subscribeApiIdResponse();
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

        reqApis = currentContent.reqApis;
        resApis = currentContent.resApis;
        colGroups = currentContent.colGroups;
        columnAggregate = currentContent.columnAggregate;
        groupByColumns = currentContent.groupByColumns;

        if (columnState != apiId) {
          resApis = [];
          columnState = resetColumn(apiId);
        }

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

  void _subscribeGridColumnMenu() {
    _gridColumnMenuSub = appStreams.gridColumnMenuStream.listen((v) {
      if (v != null) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
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
      // touch the late variable; will throw if not initialized
      // ignore: unnecessary_statements
      stateManager.toString();
      return true;
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
      final currentContent = widget.item.content;

      // Create (POST)
      final createEntries =
          onChanged.entries.where((e) => e.value['cud'] == 'C').toList();
      for (final e in createEntries) {
        if (currentContent != null && postApiId.isNotEmpty) {
          final row = selectedRows.firstWhereOrNull((row) => row.key == e.key);
          if (row != null && row.cells.isNotEmpty) {
            final params = _buildCrudParams(postApiId, row);
            homeRepo.addApiRequest(postApiId, params);

            final resp = await _waitForApiResponse(postApiId, params);
            if (resp == null) {
              _showErrorSnackBar('생성 응답 타임아웃 (5초)');
              continue;
            }

            _showSuccessSnackBar('데이터가 생성되었습니다.');
            await _refreshDataWithRetry();
          }
        } else {
          _showErrorSnackBar('POST API가 설정되어 있지 않습니다.');
          break;
        }
      }

      // Update (PUT)
      final updateEntries =
          onChanged.entries.where((e) => e.value['cud'] == 'U').toList();
      for (final e in updateEntries) {
        if (currentContent != null && putApiId.isNotEmpty) {
          final row = selectedRows.firstWhereOrNull((row) => row.key == e.key);
          if (row != null && row.cells.isNotEmpty) {
            final params = _buildCrudParams(putApiId, row);
            homeRepo.addApiRequest(putApiId, params);

            final resp = await _waitForApiResponse(putApiId, params);
            if (resp == null) {
              _showErrorSnackBar('수정 응답 타임아웃 (5초)');
              continue;
            }

            _showSuccessSnackBar('데이터가 수정되었습니다.');
            await _refreshDataWithRetry();
          }
        } else {
          _showErrorSnackBar('PUT API가 설정되어 있지 않습니다.');
          break;
        }
      }

      // Delete (DELETE)
      final deleteEntries =
          onChanged.entries.where((e) => e.value['cud'] == 'D').toList();
      for (final e in deleteEntries) {
        if (currentContent != null && deleteApiId.isNotEmpty) {
          final row = selectedRows.firstWhereOrNull((row) => row.key == e.key);
          if (row != null && row.cells.isNotEmpty) {
            final params = _buildCrudParams(deleteApiId, row);
            homeRepo.addApiRequest(deleteApiId, params);

            final resp = await _waitForApiResponse(deleteApiId, params);
            if (resp == null) {
              _showErrorSnackBar('삭제 응답 타임아웃 (5초)');
              continue;
            }

            _showSuccessSnackBar('데이터가 삭제되었습니다.');
            await _refreshDataWithRetry();
          }
        } else {
          _showErrorSnackBar('DELETE API가 설정되어 있지 않습니다.');
          break;
        }
      }

      setState(() {
        onChanged.forEach((key, value) {
          rows.removeWhere((row) => row.key == key && value['cud'] == 'D');
        });
        onChanged.clear();
        renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
      });
    }
  }

  Map<String, dynamic> _buildCrudParams(String apiId, TrinaRow row) {
    final params = <String, dynamic>{};
    final api = homeRepo.apis[apiId];
    if (api == null) return params;

    List<dynamic> paramDefs = [];
    try {
      final raw = api['parameters'];
      if (raw != null && raw.toString().isNotEmpty) {
        paramDefs = raw is String ? jsonDecode(raw) : (raw as List<dynamic>);
      }
    } catch (_) {}

    final columnMap = <String, ApiConfig>{};
    for (final apiConfig in resApis) {
      if (apiConfig.field != null) {
        columnMap[apiConfig.field!] = apiConfig;
      }
    }

    for (final def in paramDefs) {
      if (def is! Map) continue;
      final key = def['paramKey']?.toString();
      if (key == null || key.isEmpty) continue;

      dynamic value;
      if (columnMap.containsKey(key)) {
        value = row.cells[key]?.value ?? '';
      } else {
        switch (key) {
          case 'id':
            value = row.cells['id']?.value ?? '';
            break;
          case 'data':
            value = row.toJson();
            break;
          case 'created_by':
          case 'user_id':
            value = '1';
            break;
          default:
            value = '';
        }
      }

      value ??= '';
      params[key] = value;
    }

    return params;
  }

  Future<Map<String, dynamic>?> _waitForApiResponse(
      String apiId, Map<String, dynamic> expectedParams) async {
    int attempts = 0;
    const maxAttempts = 50;
    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
      final apiResponse = homeRepo.onApiResponse[apiId];
      if (apiResponse != null && apiResponse['data'] != null) {
        return apiResponse;
      }
    }
    return null;
  }

  Future<void> _refreshDataWithRetry() async {
    const int maxAttempts = 3;
    for (int i = 0; i < maxAttempts; i++) {
      if (apiId.isNotEmpty) {
        reloadApiIdResponse(apiId);
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
          });
        }
        break;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget columnGroupTitle(String title) {
    return Text(
      title,
      style: gridStyle(theme).columnTextStyle,
    );
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
}
