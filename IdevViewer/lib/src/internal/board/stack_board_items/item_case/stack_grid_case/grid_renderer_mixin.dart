import 'package:idev_viewer/src/internal/theme/theme_grid.dart';

import '../stack_grid_case.dart';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:idev_viewer/src/internal/board/stack_board_items/common/new_field.dart'; // For FieldType
import 'package:idev_viewer/src/internal/board/stack_board_items/common/models/api_config.dart';
import 'package:collection/collection.dart'; // firstWhereOrNull 사용을 위해 추가

mixin GridRendererMixin on State<StackGridCase> {
  // Dependencies accessed via 'this.' or 'widget.'
  // Helper getter using the public class name
  StackGridCaseState get state => this as StackGridCaseState;

  String resetColumn(String? apiId) {
    if (state.resApis.isNotEmpty) {
      state.columns = [
        rowNumColumn(),
        ...state.resApis.map((ApiConfig apiConfig) {
          final col = TrinaColumn(
              title: apiConfig.fieldNm ?? '',
              field: apiConfig.field ?? '',
              type: TrinaColumnType.text(),
              editCellRenderer: (defaultEditCellWidget, cell, controller,
                      focusNode, handleSelected) =>
                  editCellRenderer(
                    defaultEditCellWidget,
                    cell,
                    controller,
                    focusNode,
                    handleSelected,
                    typeName: apiConfig.type,
                  ));

          if (apiConfig.width != null) {
            col.width = (apiConfig.width)!.toDouble();
          }
          col.title = apiConfig.fieldNm ?? '';
          col.hide = !(apiConfig.enabled ?? true);
          col.enableEditingMode = true;
          // col.enableEditingMode = (apiConfig.enabled ?? true) &&
          //     !['textLabel', 'popup'].contains(apiConfig.type);

          col.type = gridType(apiConfig.field ?? '', apiConfig.type ?? '',
              format: apiConfig.format);

          col.renderer = (c) {
            if (isNumericType(apiConfig.type ?? '')) {
              return numberRenderer(c, jsonColumn: apiConfig.toJson());
            } else if (apiConfig.type == 'select') {
              return selectRenderer(c);
            } else if (apiConfig.type == 'imageUrl') {
              return imageUrlRenderer(c);
            } else if (apiConfig.type == 'checkGroup') {
              return checkGroupRenderer(c);
            } else if (apiConfig.type == 'radioGroup') {
              return radioGroupRenderer(c);
            } else if (apiConfig.type == 'popup') {
              return popupRenderer(c, apiConfig.format ?? '');
            } else {
              return Text(
                c.cell.value.toString(),
                style: gridStyle(state.theme).cellTextStyle,
              );
            }
          };
          col.footerRenderer = footerRenderer;

          return col;
        })
      ];
      return apiId ?? '';
    }

    /// 컬럼 초기화
    if (state.resApis.isEmpty && apiId != null && apiId.isNotEmpty) {
      final api = state.homeRepo.selectedApis[apiId];

      if (api == null || api.isEmpty) {
        return '';
      }
      List<dynamic>? response = api['response'];

      if (response != null) {
        state.columns = [
          rowNumColumn(),
          ...response.map((field) => TrinaColumn(
                title: field.toString(),
                field: field.toString(),
                width: 100,
                type: TrinaColumnType.text(),
                footerRenderer: footerRenderer,
              ))
        ];
      } else {
        state.columns = [rowNumColumn()];
      }

      for (var column in state.columns) {
        final managedColumn =
            state.stateManager.refColumns.originalList.firstWhereOrNull(
          (c) => c.field == column.field,
        );
        if (managedColumn != null) {
          state.stateManager.autoFitColumn(context, managedColumn);
          state.stateManager.notifyResizingListeners();
        }
      }
      return apiId;
    }

    return '';
  }

  TrinaColumn rowNumColumn() {
    return TrinaColumn(
      title: 'N',
      field: 'rowNum',
      width: 90,
      enableEditingMode: false,
      enableRowChecked: state.enableRowChecked,
      enableRowDrag: true,
      type: TrinaColumnType.text(),
      renderer: (c) {
        final sm = c.stateManager.refRows;
        final idx = c.stateManager.pageSize * (c.stateManager.page - 1) +
            sm.indexOf(c.row) +
            1;

        c.cell.value = idx;
        return Text(NumberFormat("#,###").format(idx),
            style: gridStyle(state.theme).cellTextStyle);
      },
      footerRenderer: footerRenderer,
    );
  }

  bool isNumericType(String typeName) {
    try {
      FieldType type = FieldType.values.byName(typeName);
      return type == FieldType.number ||
          type == FieldType.percentage ||
          type == FieldType.currency ||
          type == FieldType.formula ||
          type == FieldType.stepper;
    } catch (e) {
      return false;
    }
  }

  Widget editCellRenderer(
      Widget defaultEditCellWidget,
      TrinaCell cell,
      TextEditingController controller,
      FocusNode focusNode,
      Function(dynamic value)? handleSelected,
      {String? typeName}) {
    if (cell.column.type.isSelect) {
      final field = cell.column.field;
      final paramKey = 'haksa/$field';
      final items = state.homeRepo.params.keys.contains(paramKey)
          ? (state.homeRepo.params[paramKey]['children']
                  as Map<String, dynamic>)
              .entries
              .map((e) => {'code': e.key, 'value': e.value})
              .toList()
          : [];

      final matchingItem = items.firstWhere((e) => e['code'] == cell.value,
          orElse: () => {'value': ''});
      controller.text = matchingItem['value'] ?? '';

      return defaultEditCellWidget;
    }

    if (cell.column.type.isNumber && typeName == 'stepper') {
      return Row(
        children: [
          Expanded(child: defaultEditCellWidget),
          const SizedBox(width: 4),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  final currentValue = int.tryParse(controller.text) ?? 0;
                  controller.text = (currentValue + 1).toString();
                  focusNode.requestFocus();
                  handleSelected?.call(controller.text);
                },
                child:
                    const Icon(Symbols.stat_1, color: Colors.indigo, size: 12),
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: () {
                  final currentValue = int.tryParse(controller.text) ?? 0;
                  controller.text = (currentValue - 1).toString();
                  focusNode.requestFocus();
                  handleSelected?.call(controller.text);
                },
                child: const Icon(Symbols.stat_minus_1,
                    color: Colors.indigo, size: 12),
              ),
            ],
          )
        ],
      );
    }

    return defaultEditCellWidget;
  }

  TrinaColumnType gridType(String field, String typeName, {String? format}) {
    FieldType type = FieldType.text;
    try {
      type = FieldType.values.byName(typeName);
    } catch (e) {
      print(
          "Warning: Invalid FieldType name '$typeName' for field '$field'. Defaulting to text.");
    }

    final paramKey = 'haksa/$field';
    final items = state.homeRepo.params.keys.contains(paramKey)
        ? (state.homeRepo.params[paramKey]['children'] as Map<String, dynamic>)
            .entries
            .map((e) => {'code': e.key, 'value': e.value})
            .toList()
        : [];

    return switch (type) {
      FieldType.number =>
        format == null || format.isEmpty || format == 'default'
            ? TrinaColumnType.number()
            : TrinaColumnType.number(format: format),
      FieldType.stepper =>
        format == null || format.isEmpty || format == 'default'
            ? TrinaColumnType.number()
            : TrinaColumnType.number(format: format),
      FieldType.formula =>
        format == null || format.isEmpty || format == 'default'
            ? TrinaColumnType.number()
            : TrinaColumnType.number(format: format),
      FieldType.currency => TrinaColumnType.currency(),
      FieldType.percentage => TrinaColumnType.percentage(),
      FieldType.boolean => TrinaColumnType.boolean(),
      FieldType.date => format == null || format.isEmpty
          ? TrinaColumnType.date()
          : TrinaColumnType.date(format: format),
      FieldType.time => TrinaColumnType.time(),
      FieldType.dateTime =>
        format == null || format.isEmpty || format == 'default'
            ? TrinaColumnType.dateTime()
            : TrinaColumnType.dateTime(format: format),
      FieldType.select =>
        TrinaColumnType.select(items.map((e) => e['code']).toList(),
            onItemSelected: (itemSelected) {
          setState(() {
            state.stateManager.resetCurrentState();
          });
        }, builder: (item) {
          final matchingItem = items.firstWhere((e) => e['code'] == item,
              orElse: () => {'value': ''});
          return Text(matchingItem['value'] ?? '');
        }),
      _ => TrinaColumnType.text()
    };
  }

  Widget checkGroupRenderer(TrinaColumnRendererContext c) {
    final field = c.column.field;
    final paramKey = 'haksa/$field';
    final items = state.homeRepo.params.keys.contains(paramKey)
        ? (state.homeRepo.params[paramKey]['children'] as Map<String, dynamic>)
            .entries
            .map((e) => {'code': e.key, 'value': e.value})
            .toList()
        : [];

    List<dynamic>? initialVal = c.cell.value is List
        ? c.cell.value
        : (c.cell.value != null ? [c.cell.value] : null);

    return FormBuilderCheckboxGroup(
      key: ValueKey('${c.row.key.toString()}-${c.column.field}'),
      name: field,
      initialValue: initialVal,
      onChanged: (v) {
        final currentList = initialVal ?? [];
        final newList = v ?? [];
        bool changed = currentList.length != newList.length ||
            !currentList.every((item) => newList.contains(item));

        if (!changed) {
          return;
        }
        setState(() {
          c.cell.value = v;
          c.row.cells[c.column.field] = c.cell;
          state.stateManager.onChanged?.call(TrinaGridOnChangedEvent(
            column: c.column,
            columnIdx: state.stateManager.columns.indexOf(c.column),
            row: c.row,
            rowIdx: state.stateManager.rows.indexOf(c.row),
            oldValue: initialVal,
          ));
        });
      },
      decoration: const InputDecoration(
          constraints: BoxConstraints.expand(height: 25),
          contentPadding: EdgeInsets.only(top: -25),
          border: InputBorder.none),
      options: items
          .map((v) => FormBuilderFieldOption(
              value: v['code'],
              child: Text(v['value'],
                  style: gridStyle(state.theme).cellTextStyle)))
          .toList(),
      wrapDirection: Axis.horizontal,
      wrapAlignment: WrapAlignment.start,
      controlAffinity: ControlAffinity.leading,
    );
  }

  Widget radioGroupRenderer(TrinaColumnRendererContext c) {
    final field = c.column.field;
    final paramKey = 'haksa/$field';
    final items = state.homeRepo.params.keys.contains(paramKey)
        ? (state.homeRepo.params[paramKey]['children'] as Map<String, dynamic>)
            .entries
            .map((e) => {'code': e.key, 'value': e.value})
            .toList()
        : [];

    return FormBuilderRadioGroup(
      key: ValueKey('${c.row.key.toString()}-${c.column.field}'),
      name: field,
      initialValue: c.cell.value,
      onChanged: (v) {
        if (c.cell.value?.toString() == v?.toString()) {
          return;
        }
        setState(() {
          final oldValue = c.cell.value;
          c.cell.value = v;
          c.row.cells[c.column.field] = c.cell;
          state.stateManager.onChanged?.call(TrinaGridOnChangedEvent(
            column: c.column,
            columnIdx: state.stateManager.columns.indexOf(c.column),
            row: c.row,
            rowIdx: c.rowIdx,
            oldValue: oldValue,
          ));
        });
      },
      decoration: const InputDecoration(
          constraints: BoxConstraints.expand(height: 25),
          contentPadding: EdgeInsets.only(top: -25),
          border: InputBorder.none),
      options: items
          .map((v) => FormBuilderFieldOption(
              value: v['code'],
              child: Text(v['value'],
                  style: gridStyle(state.theme).cellTextStyle)))
          .toList(),
      wrapDirection: Axis.horizontal,
      wrapAlignment: WrapAlignment.start,
      controlAffinity: ControlAffinity.leading,
    );
  }

  Widget imageUrlRenderer(TrinaColumnRendererContext c) {
    final initialValue = c.cell.value?.toString() ?? '';
    if (initialValue.isEmpty) {
      return const SizedBox.shrink();
    }

    String finalUrl = _getProxiedImageUrl(initialValue);
    // print('🖼️ 이미지 로딩 시도: 원본=$initialValue, 프록시=$finalUrl');

    return Image.network(
      finalUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // print('❌ 이미지 로딩 실패: $error - URL: $finalUrl');

        // 프록시 서버 오류 시 원본 URL로 재시도
        if (error.toString().contains('CORS') ||
            error.toString().contains('Access-Control-Allow-Origin') ||
            error.toString().contains('corsproxy.io')) {
          //print('🔄 원본 URL로 재시도: $initialValue');
          return Image.network(
            initialValue, // 원본 URL로 재시도
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // 원본 URL도 실패하면 기본 이미지
              return Image.network(
                'https://via.placeholder.com/150x150/cccccc/666666?text=Image',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, color: Colors.grey);
                },
              );
            },
          );
        }
        return const Icon(Icons.broken_image, color: Colors.grey);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
    );
  }

  String _getProxiedImageUrl(String originalUrl) {
    // 모든 외부 이미지 URL에 대해 CORS 문제를 해결하기 위한 프록시 URL 생성
    if (originalUrl.startsWith('http://') ||
        originalUrl.startsWith('https://')) {
      // 더 안정적인 프록시 서버 사용
      return 'https://corsproxy.io/?${Uri.encodeComponent(originalUrl)}';
    }

    // 상대 경로인 경우 기존 로직 사용
    Uri? parsedUri = Uri.tryParse(originalUrl);
    Uri finalUri;
    final baseUri = Uri.parse('http://210.123.228.102');

    if (parsedUri != null && parsedUri.hasScheme && parsedUri.hasAuthority) {
      finalUri = parsedUri;
    } else {
      finalUri = baseUri.resolve(originalUrl);
    }

    return finalUri.toString();
  }

  Widget formulaRenderer(TrinaColumnRendererContext c, {dynamic jsonColumn}) {
    if (state.resApis.isNotEmpty &&
        jsonColumn != null &&
        jsonColumn['apiId'] != null) {
      try {
        final value = state.fxMath(jsonColumn['apiId'], c.row.toJson());
        c.cell.value = value;

        String formattedValue = value?.toString() ?? '';
        if (value is num) {
          formattedValue = NumberFormat('#,###.##').format(value);
        }

        return Text(formattedValue,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: gridStyle(state.theme).cellTextStyle);
      } catch (e) {
        return const Text("Error",
            textAlign: TextAlign.right, style: TextStyle(color: Colors.red));
      }
    } else {
      return Text(c.cell.value?.toString() ?? '',
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: gridStyle(state.theme).cellTextStyle);
    }
  }

  Widget selectRenderer(TrinaColumnRendererContext c) {
    final field = c.column.field;
    final paramKey = 'haksa/$field';
    final items = state.homeRepo.params.keys.contains(paramKey)
        ? (state.homeRepo.params[paramKey]['children'] as Map<String, dynamic>)
            .entries
            .map((e) => {'code': e.key, 'value': e.value})
            .toList()
        : [];

    final matchingItem = items.firstWhere((e) => e['code'] == c.cell.value,
        orElse: () => {'value': c.cell.value?.toString() ?? ''});

    return Text(matchingItem['value'] ?? '',
        textAlign: TextAlign.left,
        overflow: TextOverflow.ellipsis,
        style: gridStyle(state.theme).cellTextStyle);
  }

  Widget numberRenderer(TrinaColumnRendererContext c, {dynamic jsonColumn}) {
    if (c.row.type.isGroup ?? false) {
      return footerRenderer(
          TrinaColumnFooterRendererContext(
              column: c.column, stateManager: state.stateManager),
          columnRendererContext: c,
          filterGroupBy: groupByColumnFilter);
    } else {
      if (jsonColumn != null && jsonColumn['type'] == 'formula') {
        return formulaRenderer(c, jsonColumn: jsonColumn);
      }
      return Text(columnFormatter(c, jsonColumn ?? {}),
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          style: gridStyle(state.theme).cellTextStyle);
    }
  }

  Widget popupRenderer(TrinaColumnRendererContext c, String format) {
    String displayValue = c.cell.value?.toString() ?? '';
    return InkWell(
      onTap: () => popupOnTap(
        displayValue,
        format,
        callback: (v) {
          if (displayValue == v) {
            return;
          }
          setState(() {
            final oldValue = c.cell.value;
            c.cell.value = v;
            c.row.cells[c.column.field] = c.cell;
            state.stateManager.onChanged?.call(TrinaGridOnChangedEvent(
              column: c.column,
              columnIdx: state.stateManager.columns.indexOf(c.column),
              row: c.row,
              rowIdx: c.rowIdx,
              oldValue: oldValue,
            ));
          });
        },
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(
            displayValue,
            overflow: TextOverflow.ellipsis,
            style: gridStyle(state.theme).cellTextStyle,
          )),
          if (format.contains('showAlert') || format.contains('textField'))
            const SizedBox(width: 4),
          if (format.contains('showAlert'))
            const Icon(Icons.message_outlined, color: Colors.grey, size: 16),
          if (format.contains('textField'))
            const Icon(Icons.edit_note_outlined, color: Colors.grey, size: 16)
        ],
      ),
    );
  }

  Future<void> popupOnTap(String initValue, String format,
      {Function(String)? callback, int? maxLines, String? url}) async {
    if (format.contains('showAlert')) {
      await showOkAlertDialog(
          message: initValue,
          context: context,
          style: AdaptiveStyle.material,
          title: '내용 확인');
    }

    if (format.contains('textField')) {
      final result = await showTextInputDialog(
        context: context,
        style: AdaptiveStyle.material,
        title: '내용 입력',
        textFields: [
          DialogTextField(initialText: initValue, maxLines: maxLines ?? 4),
        ],
      );

      if (result != null && result.isNotEmpty && callback != null) {
        callback.call(result.first);
      }
    }
  }

  String columnFormatter(TrinaColumnRendererContext c, dynamic e) {
    if (e == null ||
        e is! Map ||
        !(e.containsKey('type') && e.containsKey('format'))) {
      return c.cell.value?.toString() ?? '';
    }

    final valueStr = c.cell.value?.toString() ?? '';
    final double? value = double.tryParse(valueStr);

    if (value == null) {
      return valueStr;
    }

    final symbol = {
      'us': '\$',
      'eu': '€',
      'jp': '¥',
      'cn': '¥',
      'da': 'DKK',
      'kr': '₩'
    };

    FieldType type = FieldType.text;
    try {
      type = FieldType.values.byName(e['type']);
    } catch (err) {
      print(
          "Warning: Invalid FieldType name '${e['type']}' in columnFormatter.");
    }

    final String formatPattern = e['format'] ?? 'default';

    try {
      return switch (type) {
        FieldType.number ||
        FieldType.stepper ||
        FieldType.formula =>
          formatPattern == 'default' || formatPattern.isEmpty
              ? formatNumber(value)
              : NumberFormat(formatPattern).format(value),
        FieldType.currency => switch (formatPattern) {
            'kr' ||
            'da' =>
              '${NumberFormat('#,###.##').format(value)} ${symbol[formatPattern] ?? ''}',
            'us' ||
            'eu' ||
            'jp' ||
            'cn' =>
              '${symbol[formatPattern] ?? ''} ${NumberFormat('#,###.##').format(value)}',
            _ => formatNumber(value)
          },
        FieldType.percentage =>
          NumberFormat.percentPattern().format(value / 100.0),
        _ => valueStr
      };
    } catch (formatError) {
      return valueStr;
    }
  }

  String formatNumber(num value) {
    if (value == value.toInt()) {
      return NumberFormat('#,##0').format(value);
    } else {
      return NumberFormat('#,##0.###').format(value);
    }
  }

  Widget footerRenderer(TrinaColumnFooterRendererContext c,
      {TrinaColumnRendererContext? columnRendererContext,
      bool Function(TrinaColumnRendererContext, TrinaCell)? filterGroupBy}) {
    final field = c.column.field;

    final Map<String, bool> currentColumnAggregate =
        state.currentColumnAggregate;

    if (currentColumnAggregate.keys.any((key) => key.startsWith(field))) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        children: [
          if (currentColumnAggregate['$field-onSum'] ?? false)
            TrinaAggregateColumnFooter(
              rendererContext: c,
              type: TrinaAggregateColumnType.sum,
              format: '#,###.###',
              alignment: Alignment.centerRight,
              filter: (cell) =>
                  columnRendererContext == null || filterGroupBy == null
                      ? true
                      : filterGroupBy.call(columnRendererContext, cell),
              titleSpanBuilder: (text) {
                columnRendererContext?.cell.value = text;
                return [
                  TextSpan(
                      text: '합계: $text',
                      style: gridStyle(state.theme).cellTextStyle)
                ];
              },
            ),
          if (currentColumnAggregate['$field-onAvg'] ?? false)
            TrinaAggregateColumnFooter(
              rendererContext: c,
              type: TrinaAggregateColumnType.average,
              format: '#,###.###',
              alignment: Alignment.centerRight,
              filter: (cell) =>
                  columnRendererContext == null || filterGroupBy == null
                      ? true
                      : filterGroupBy.call(columnRendererContext, cell),
              titleSpanBuilder: (text) {
                columnRendererContext?.cell.value = text;
                return [
                  TextSpan(
                      text: '평균: $text',
                      style: gridStyle(state.theme).cellTextStyle)
                ];
              },
            ),
          if (currentColumnAggregate['$field-onMin'] ?? false)
            TrinaAggregateColumnFooter(
              rendererContext: c,
              type: TrinaAggregateColumnType.min,
              format: '#,###.###',
              alignment: Alignment.centerRight,
              filter: (cell) =>
                  columnRendererContext == null || filterGroupBy == null
                      ? true
                      : filterGroupBy.call(columnRendererContext, cell),
              titleSpanBuilder: (text) {
                columnRendererContext?.cell.value = text;
                return [
                  TextSpan(
                      text: '최소: $text',
                      style: gridStyle(state.theme).cellTextStyle)
                ];
              },
            ),
          if (currentColumnAggregate['$field-onMax'] ?? false)
            TrinaAggregateColumnFooter(
              rendererContext: c,
              type: TrinaAggregateColumnType.max,
              format: '#,###.###',
              alignment: Alignment.centerRight,
              filter: (cell) =>
                  columnRendererContext == null || filterGroupBy == null
                      ? true
                      : filterGroupBy.call(columnRendererContext, cell),
              titleSpanBuilder: (text) {
                columnRendererContext?.cell.value = text;
                return [
                  TextSpan(
                      text: '최대: $text',
                      style: gridStyle(state.theme).cellTextStyle)
                ];
              },
            ),
          if (currentColumnAggregate['$field-onCount'] ?? false)
            TrinaAggregateColumnFooter(
              rendererContext: c,
              type: TrinaAggregateColumnType.count,
              format: '#,###',
              alignment: Alignment.centerRight,
              filter: (cell) =>
                  columnRendererContext == null || filterGroupBy == null
                      ? true
                      : filterGroupBy.call(columnRendererContext, cell),
              titleSpanBuilder: (text) {
                columnRendererContext?.cell.value = text;
                return [
                  TextSpan(
                      text: '건수: $text',
                      style: gridStyle(state.theme).cellTextStyle)
                ];
              },
            ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  bool groupByColumnFilter(TrinaColumnRendererContext context, TrinaCell cell) {
    if (state.currentGroupByColumns.isEmpty ||
        context.row.depth >= state.currentGroupByColumns.length) {
      return true;
    }

    List<String> groupRowValues = [];
    for (int i = 0; i <= context.row.depth; i++) {
      groupRowValues.add(context
              .row.cells[state.currentGroupByColumns[i].field]?.value
              .toString() ??
          '');
    }

    for (int i = 0; i < groupRowValues.length; i++) {
      final cellValue = cell
              .row.cells[state.currentGroupByColumns[i].field]?.value
              .toString() ??
          '';
      if (cellValue != groupRowValues[i]) {
        return false;
      }
    }

    return true;
  }
}
