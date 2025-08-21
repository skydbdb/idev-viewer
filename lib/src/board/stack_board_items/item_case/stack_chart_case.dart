import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/repo/home_repo.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '/src/board/flutter_stack_board.dart';
import '/src/di/service_locator.dart';
import '/src/repo/app_streams.dart';
import '/src/board/core/stack_board_item/stack_item_status.dart';
import '/src/board/stack_board_items/items/stack_chart_item.dart';
import '/src/theme/theme_chart.dart';

class StackChartCase extends StatefulWidget {
  const StackChartCase({
    super.key,
    required this.item,
  });

  final StackChartItem item;

  @override
  State<StackChartCase> createState() => _StackChartCaseState();
}

class _StackChartCaseState extends State<StackChartCase> {
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  late StreamSubscription _updateStackItemSub;
  late StreamSubscription _apiIdResponseSub;
  late ChartItemContent content;
  late bool _enableMultiSelect;
  late bool _toggleSelection;
  late List<CartesianSeries<Map<String, dynamic>, dynamic>> cartesianSeries;
  late List<CircularSeries<Map<String, dynamic>, dynamic>> circularSeries;
  Map<String, dynamic>? previousSelectedData;
  SelectionBehavior? _selectionBehavior;
  late String theme;

  StackBoardController _controller(BuildContext context) =>
      StackBoardConfig.of(context).controller;

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();

    content = widget.item.content!;
    cartesianSeries = [];
    circularSeries = [];
    _enableMultiSelect = false;
    _toggleSelection = true;
    theme = widget.item.theme ?? 'White';

    _subscribeApiIdResponse();
    _subscribeUpdateStackItem();
  }

  void _subscribeApiIdResponse() {
    _apiIdResponseSub = homeRepo.getApiIdResponseStream.listen((v) {
      if (v != null) {
        final item =
            _controller(context).getById(widget.item.id) as StackChartItem? ??
                widget.item;
        if (v['if_id'] != item.content?.apiId) {
          return;
        }

        final apiId = v['if_id'];
        final result = homeRepo.onApiResponse[apiId]?['data']?['result'];
        if (result is Map<String, dynamic>) {
          setState(() {
            content = item.content!.copyWith(dataSource: [result]);
          });
        } else if (result is List &&
            result.isNotEmpty &&
            result.first is Map<String, dynamic>) {
          try {
            final List<Map<String, dynamic>> dataSource =
                result.cast<Map<String, dynamic>>();
            final it = item.copyWith(
              content: item.content!.copyWith(dataSource: dataSource),
            );
            _controller(context).updateItem(it);
            homeRepo.addOnTapState(it);
            setState(() {
              content = it.content!;
            });
          } catch (e) {
            debugPrint(
                '[StackChartCase][_subscribeApiIdResponse] dataSource JSON parse error: $e');
          }
        }
      }
    });
  }

  void _subscribeUpdateStackItem() {
    _updateStackItemSub = appStreams.updateStackItemStream.listen((v) {
      if (v?.id == widget.item.id &&
          v is StackChartItem &&
          v.boardId == widget.item.boardId) {
        final StackChartItem item = v;
        setState(() {
          content = item.content!;
          theme = item.theme;
        });
      }
    });
  }

  @override
  void dispose() {
    _updateStackItemSub.cancel();
    _apiIdResponseSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chartConfig = chartStyle(theme);

    return Scaffold(
        appBar: widget.item.status == StackItemStatus.editing
            ? chartEditMenu(chartConfig)
            : null,
        body: Stack(
          fit: StackFit.expand,
          children: [_buildChartWidget(chartConfig)],
        ));
  }

  AppBar chartEditMenu(ChartThemeConfig chartConfig) {
    return AppBar(
      toolbarHeight: 150,
      backgroundColor: chartConfig.appBarBackgroundColor,
      title: TextFormField(
        initialValue: _formatDataSource(content.dataSource),
        style: chartConfig.appBarTextStyle,
        decoration: InputDecoration(
          labelText: '데이터 (JSON)',
          labelStyle: chartConfig.appBarTextStyle,
          border: const OutlineInputBorder(),
          helperText: '예: [{"x": "A", "y": 10}, {"x": "B", "y": 20}]',
          helperStyle: chartConfig.appBarTextStyle,
        ),
        maxLines: 3,
        onChanged: (String value) {
          try {
            final List<dynamic> parsed = jsonDecode(value);
            final List<Map<String, dynamic>> dataSource =
                parsed.cast<Map<String, dynamic>>();
            final item = widget.item.copyWith(
              content: content.copyWith(dataSource: dataSource),
            );
            _controller(context).updateItem(item);
            homeRepo.addOnTapState(item);
            setState(() {
              content = item.content!;
            });
          } catch (e) {
            debugPrint('[StackChartCase] dataSource JSON parse error: \\$e');
          }
        },
      ),
    );
  }

  Widget _buildChartWidget(ChartThemeConfig chartConfig) {
    if (content.dataSource == null || content.dataSource!.isEmpty) {
      return Container(
        color: chartConfig.chartBackgroundColor,
        child: Center(
          child: Text('데이터가 없습니다',
              style: chartConfig.titleTextStyle.copyWith(fontSize: 16)),
        ),
      );
    }

    _selectionBehavior = SelectionBehavior(
      enable: true,
      toggleSelection: _toggleSelection,
      selectedColor: chartConfig.selectionColor,
    );

    return Container(
      color: chartConfig.chartBackgroundColor,
      child: _buildChartByType(chartConfig),
    );
  }

  Widget _buildChartByType(ChartThemeConfig chartConfig) {
    switch (content.chartType) {
      case 'column':
        return _buildColumnChart(chartConfig);
      case 'pie':
        return _buildPieChart(chartConfig);
      case 'line':
        return _buildLineChart(chartConfig);
      case 'area':
        return _buildAreaChart(chartConfig);
      case 'bar':
        return _buildBarChart(chartConfig);
      default:
        return _buildColumnChart(chartConfig);
    }
  }

  Widget _buildColumnChart(ChartThemeConfig chartConfig) {
    if (content.yValueMapper is List && content.yValueMapper!.isNotEmpty) {
      cartesianSeries.clear();
      for (dynamic yField in content.yValueMapper!) {
        if (yField != null) {
          cartesianSeries.add(
            ColumnSeries<Map<String, dynamic>, dynamic>(
              dataSource: content.dataSource!,
              xValueMapper: _xValueMapper,
              yValueMapper: (data, _) {
                return _yValueMapper(data, yKey: yField.keys.first);
              },
              name: yField.values.first,
              selectionBehavior: _selectionBehavior,
              dataLabelSettings: content.showDataLabels
                  ? DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: chartConfig.dataLabelTextStyle,
                    )
                  : const DataLabelSettings(isVisible: false),
            ),
          );
        }
      }
    }

    return SfCartesianChart(
      title: ChartTitle(
        text: content.title!,
        textStyle: chartConfig.titleTextStyle,
      ),
      legend: content.showLegend
          ? Legend(
              isVisible: true,
              textStyle: chartConfig.legendTextStyle,
            )
          : const Legend(isVisible: false),
      tooltipBehavior: _buildTooltip(chartConfig),
      zoomPanBehavior: content.enableZoom || content.enablePan
          ? ZoomPanBehavior(
              enablePinching: content.enableZoom,
              enablePanning: content.enablePan,
            )
          : null,
      onSelectionChanged: _onSelectionChanged,
      primaryXAxis: _buildXAxis(chartConfig),
      primaryYAxis: _buildYAxis(chartConfig),
      selectionType: content.selectionType,
      enableMultiSelection: _enableMultiSelect,
      series: cartesianSeries,
    );
  }

  Widget _buildPieChart(ChartThemeConfig chartConfig) {
    if (content.yValueMapper is List && content.yValueMapper!.isNotEmpty) {
      circularSeries.clear();
      dynamic yField = content.yValueMapper!.first;
      if (yField != null) {
        circularSeries.add(
          PieSeries<Map<String, dynamic>, dynamic>(
            dataSource: content.dataSource!,
            xValueMapper: (data, _) {
              final valueX = _xValueMapper(data, _);
              return _formatValue(valueX, content.xAxisLabelFormat);
            },
            yValueMapper: (data, _) {
              return _yValueMapper(data, yKey: yField.keys.first);
            },
            dataLabelMapper: (data, _) {
              final valueY = _yValueMapper(data, yKey: yField.keys.first);
              return _formatValue(valueY, content.yAxisLabelFormat);
            },
            name: yField.values.first,
            selectionBehavior: _selectionBehavior,
            dataLabelSettings: content.showDataLabels
                ? DataLabelSettings(
                    isVisible: true,
                    labelPosition: ChartDataLabelPosition.outside,
                    textStyle: chartConfig.dataLabelTextStyle,
                  )
                : const DataLabelSettings(isVisible: false),
          ),
        );
      }
    }

    return SfCircularChart(
      title: ChartTitle(
        text: content.title!,
        textStyle: chartConfig.titleTextStyle,
      ),
      legend: content.showLegend
          ? Legend(
              isVisible: true,
              textStyle: chartConfig.legendTextStyle,
            )
          : const Legend(isVisible: false),
      tooltipBehavior: _buildTooltip(chartConfig),
      onSelectionChanged: _onSelectionChangedCircular,
      enableMultiSelection: _enableMultiSelect,
      series: circularSeries,
    );
  }

  Widget _buildLineChart(ChartThemeConfig chartConfig) {
    if (content.yValueMapper is List && content.yValueMapper!.isNotEmpty) {
      cartesianSeries.clear();
      for (dynamic yField in content.yValueMapper!) {
        if (yField != null) {
          cartesianSeries.add(
            LineSeries<Map<String, dynamic>, dynamic>(
              dataSource: content.dataSource!,
              xValueMapper: _xValueMapper,
              yValueMapper: (data, _) {
                return _yValueMapper(data, yKey: yField.keys.first);
              },
              name: yField.values.first,
              selectionBehavior: _selectionBehavior,
              dataLabelSettings: content.showDataLabels
                  ? DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: chartConfig.dataLabelTextStyle,
                    )
                  : const DataLabelSettings(isVisible: false),
            ),
          );
        }
      }
    }

    return SfCartesianChart(
      title: ChartTitle(
        text: content.title!,
        textStyle: chartConfig.titleTextStyle,
      ),
      legend: content.showLegend
          ? Legend(
              isVisible: true,
              textStyle: chartConfig.legendTextStyle,
            )
          : const Legend(isVisible: false),
      tooltipBehavior: _buildTooltip(chartConfig),
      zoomPanBehavior: content.enableZoom || content.enablePan
          ? ZoomPanBehavior(
              enablePinching: content.enableZoom,
              enablePanning: content.enablePan,
            )
          : null,
      onSelectionChanged: _onSelectionChanged,
      primaryXAxis: _buildXAxis(chartConfig),
      primaryYAxis: _buildYAxis(chartConfig),
      selectionType: content.selectionType,
      enableMultiSelection: _enableMultiSelect,
      series: cartesianSeries,
    );
  }

  Widget _buildAreaChart(ChartThemeConfig chartConfig) {
    if (content.yValueMapper is List && content.yValueMapper!.isNotEmpty) {
      cartesianSeries.clear();
      for (dynamic yField in content.yValueMapper!) {
        if (yField != null) {
          cartesianSeries.add(
            AreaSeries<Map<String, dynamic>, dynamic>(
              dataSource: content.dataSource!,
              xValueMapper: _xValueMapper,
              yValueMapper: (data, _) {
                return _yValueMapper(data, yKey: yField.keys.first);
              },
              name: yField.values.first,
              selectionBehavior: _selectionBehavior,
              dataLabelSettings: content.showDataLabels
                  ? DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: chartConfig.dataLabelTextStyle,
                    )
                  : const DataLabelSettings(isVisible: false),
            ),
          );
        }
      }
    }

    return SfCartesianChart(
      title: ChartTitle(
        text: content.title!,
        textStyle: chartConfig.titleTextStyle,
      ),
      legend: content.showLegend
          ? Legend(
              isVisible: true,
              textStyle: chartConfig.legendTextStyle,
            )
          : const Legend(isVisible: false),
      tooltipBehavior: _buildTooltip(chartConfig),
      zoomPanBehavior: content.enableZoom || content.enablePan
          ? ZoomPanBehavior(
              enablePinching: content.enableZoom,
              enablePanning: content.enablePan,
            )
          : null,
      onSelectionChanged: _onSelectionChanged,
      primaryXAxis: _buildXAxis(chartConfig),
      primaryYAxis: _buildYAxis(chartConfig),
      selectionType: content.selectionType,
      enableMultiSelection: _enableMultiSelect,
      series: cartesianSeries,
    );
  }

  Widget _buildBarChart(ChartThemeConfig chartConfig) {
    if (content.yValueMapper is List && content.yValueMapper!.isNotEmpty) {
      cartesianSeries.clear();
      for (dynamic yField in content.yValueMapper!) {
        if (yField != null) {
          cartesianSeries.add(
            BarSeries<Map<String, dynamic>, dynamic>(
              dataSource: content.dataSource!,
              xValueMapper: _xValueMapper,
              yValueMapper: (data, _) {
                return _yValueMapper(data, yKey: yField.keys.first);
              },
              name: yField.values.first,
              selectionBehavior: _selectionBehavior,
              dataLabelSettings: content.showDataLabels
                  ? DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      textStyle: chartConfig.dataLabelTextStyle,
                    )
                  : const DataLabelSettings(isVisible: false),
            ),
          );
        }
      }
    }

    return SfCartesianChart(
      title: ChartTitle(
        text: content.title!,
        textStyle: chartConfig.titleTextStyle,
      ),
      legend: content.showLegend
          ? Legend(
              isVisible: true,
              textStyle: chartConfig.legendTextStyle,
            )
          : const Legend(isVisible: false),
      tooltipBehavior: _buildTooltip(chartConfig),
      zoomPanBehavior: content.enableZoom || content.enablePan
          ? ZoomPanBehavior(
              enablePinching: content.enableZoom,
              enablePanning: content.enablePan,
            )
          : null,
      onSelectionChanged: _onSelectionChanged,
      primaryXAxis: _buildXAxis(chartConfig),
      primaryYAxis: _buildYAxis(chartConfig),
      selectionType: content.selectionType,
      enableMultiSelection: _enableMultiSelect,
      series: cartesianSeries,
    );
  }

  TooltipBehavior _buildTooltip(ChartThemeConfig chartConfig) {
    return TooltipBehavior(
      enable: content.showTooltip,
      header: '',
      canShowMarker: false,
      color: chartConfig.tooltipBackgroundColor,
      textStyle: chartConfig.tooltipTextStyle,
    );
  }

  void _onSelectionChanged(SelectionArgs args) {
    final selectedSeries = cartesianSeries[args.seriesIndex];
    final selectedData = selectedSeries.dataSource?[args.pointIndex];
    if (previousSelectedData == selectedData) {
      return;
    }

    if (selectedData != null) {
      previousSelectedData = selectedData;

      Map<String, dynamic> fields = {};
      Map<String, dynamic> apis = {};

      for (var apiConfig in content.reqApis) {
        fields[apiConfig.fieldNm ?? ''] = apiConfig.field ?? '';
        final id = apiConfig.apiId.toString().split(RegExp('\\n')).first;
        if (homeRepo.apis.containsKey(id)) {
          apis[id] = homeRepo.apis[id];
        }
      }

      Map<String, dynamic> values = {};
      selectedData.forEach((key, value) {
        if (fields.keys.contains(key)) {
          values[fields[key]] = value;
        }
      });

      final rowJson = {...selectedData, 'apiId': content.apiId};
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
  }

  void _onSelectionChangedCircular(SelectionArgs args) {
    final selectedSeries = circularSeries[args.seriesIndex];
    final selectedData = selectedSeries.dataSource?[args.pointIndex];
    debugPrint('args: ${args.pointIndex} ${args.seriesIndex}');
    if (selectedData != null) {
      debugPrint('selectedData: $selectedData');
    }
  }

  String _getLabelFormat(String? format) {
    switch (format) {
      case 'percentage':
        return '{value}%';
      case 'currency_kr':
        return '₩{value}';
      case 'currency_us':
        return '\${value}';
      case 'currency_eu':
        return '€{value}';
      default:
        return '{value}';
    }
  }

  NumberFormat? _getNumberFormat(String? format) {
    if (format == null) return null;
    if (format == 'percentage') {
      return NumberFormat('#,##0.0');
    }
    if (format.startsWith('currency_')) {
      return NumberFormat('#,###');
    }
    // 숫자 포맷(예: #,###, 0.0 등)만 허용
    if (format.contains('#') || format.contains('0')) {
      return NumberFormat(format);
    }
    // 날짜 등은 null 반환
    return null;
  }

  ChartAxis _buildXAxis(ChartThemeConfig chartConfig) {
    switch (content.primaryXAxisType) {
      case 'datetime':
        return DateTimeAxis(
          dateFormat: DateFormat(content.xAxisLabelFormat),
          labelFormat: '{value}',
          labelStyle: chartConfig.axisTextStyle,
          majorGridLines: MajorGridLines(color: chartConfig.gridLineColor),
          autoScrollingMode: content.autoScrollingMode,
          autoScrollingDelta: content.autoScrollingDelta <= 0
              ? null
              : content.autoScrollingDelta,
        );
      case 'numeric':
        return NumericAxis(
          axisLine: AxisLine(width: 0, color: chartConfig.chartBorderColor),
          labelFormat: _getLabelFormat(content.yAxisLabelFormat),
          numberFormat: _getNumberFormat(content.yAxisLabelFormat),
          labelStyle: chartConfig.axisTextStyle,
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: MajorGridLines(color: chartConfig.gridLineColor),
          autoScrollingMode: content.autoScrollingMode,
          autoScrollingDelta: content.autoScrollingDelta <= 0
              ? null
              : content.autoScrollingDelta,
        );
      case 'category':
      default:
        return CategoryAxis(
          labelStyle: chartConfig.axisTextStyle,
          majorGridLines:
              MajorGridLines(width: 0, color: chartConfig.gridLineColor),
          autoScrollingMode: content.autoScrollingMode,
          autoScrollingDelta: content.autoScrollingDelta <= 0
              ? null
              : content.autoScrollingDelta,
        );
    }
  }

  ChartAxis _buildYAxis(ChartThemeConfig chartConfig) {
    switch (content.primaryYAxisType) {
      case 'datetime':
        return DateTimeAxis(
          dateFormat: DateFormat(content.yAxisLabelFormat),
          labelFormat: '{value}',
          labelStyle: chartConfig.axisTextStyle,
          majorGridLines: MajorGridLines(color: chartConfig.gridLineColor),
        );
      case 'numeric':
        return NumericAxis(
          axisLine: AxisLine(width: 0, color: chartConfig.chartBorderColor),
          labelFormat: _getLabelFormat(content.yAxisLabelFormat),
          numberFormat: _getNumberFormat(content.yAxisLabelFormat),
          labelStyle: chartConfig.axisTextStyle,
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: MajorGridLines(color: chartConfig.gridLineColor),
        );
      case 'category':
      default:
        return CategoryAxis(
          labelStyle: chartConfig.axisTextStyle,
          majorGridLines:
              MajorGridLines(width: 0, color: chartConfig.gridLineColor),
        );
    }
  }

  dynamic _xValueMapper(Map<String, dynamic> data, _) {
    final xKey = content.xValueMapper ?? 'x';
    final xValue = data[xKey];
    switch (content.primaryXAxisType) {
      case 'datetime':
        if (xValue is String) {
          return DateTime.tryParse(xValue);
        }
        return xValue;
      case 'numeric':
        if (xValue is String) {
          return num.tryParse(xValue);
        }
        return xValue;
      case 'category':
      default:
        return xValue;
    }
  }

  num? _yValueMapper(Map<String, dynamic> data, {String? yKey}) {
    final yValue = data[yKey];

    // 타입 안전성 강화
    switch (content.primaryYAxisType) {
      case 'datetime':
        if (yValue is String) {
          final date = DateTime.tryParse(yValue);
          if (date != null) {
            return date.millisecondsSinceEpoch;
          }
          return null;
        } else if (yValue is DateTime) {
          return yValue.millisecondsSinceEpoch;
        }
        return null;

      case 'numeric':
        if (yValue is num) {
          return yValue;
        } else if (yValue is String) {
          return num.tryParse(yValue);
        }
        return null; // String이나 num이 아닌 경우 null 반환

      case 'category':
      default:
        // category 타입의 경우 String 값을 숫자로 변환하거나 인덱스 사용
        if (yValue is num) {
          return yValue;
        } else if (yValue is String) {
          // String을 숫자로 변환 시도
          final parsed = num.tryParse(yValue);
          if (parsed != null) {
            return parsed;
          }
          // 숫자로 변환할 수 없는 경우 인덱스 사용
          return null;
        }
        return null;
    }
  }

  String _formatDataSource(List<Map<String, dynamic>>? dataSource) {
    if (dataSource == null) return '';
    return jsonEncode(dataSource);
  }

  // 포맷 헬퍼 메서드들
  dynamic _formatValue(dynamic value, String? format) {
    if (value == null || format == null || format.isEmpty) {
      return value?.toString() ?? '';
    }
    try {
      if (format.contains('yyyy') ||
          format.contains('MM') ||
          format.contains('dd')) {
        final date = DateTime.tryParse(value.toString());
        if (date != null) {
          final result = DateFormat(format).format(date);
          return result;
        }
      }
      if (format.contains('#') || format.contains('0')) {
        final numValue = num.tryParse(value.toString());
        if (numValue != null) {
          final result = NumberFormat(format).format(numValue);
          return result;
        }
      }
      if (format.startsWith('currency_')) {
        final currency = format.substring(9);
        final numValue = num.tryParse(value.toString());
        if (numValue != null) {
          String result;
          switch (currency) {
            case 'kr':
              result = '₩${NumberFormat('#,###').format(numValue)}';
              break;
            case 'us':
              result = '\$${NumberFormat('#,###').format(numValue)}';
              break;
            case 'eu':
              result = '€${NumberFormat('#,###').format(numValue)}';
              break;
            default:
              result = NumberFormat('#,###').format(numValue);
          }
          return result;
        }
      }
      if (format == 'percentage') {
        final numValue = num.tryParse(value.toString());
        if (numValue != null) {
          final result = '${NumberFormat('#,##0.0').format(numValue)}%';
          return result;
        }
      }
      return value.toString();
    } catch (e) {
      debugPrint('[포맷 트래킹] 예외: $e');
      return value.toString();
    }
  }
}
