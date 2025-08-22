import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:idev_v1/src/board/helpers.dart';
import 'package:idev_v1/src/board/stack_board_items/common/new_field.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import 'package:idev_v1/src/theme/theme_table.dart';
import '/src/board/stack_items.dart';
import '/src/repo/home_repo.dart';
import 'package:idev_v1/src/board/stack_board_items/common/models/api_config.dart';

/// * Draw object
class StackDetailCase extends StatefulWidget {
  const StackDetailCase({
    super.key,
    required this.item,
  });

  /// * StackDetailItem
  final StackDetailItem item;

  @override
  State<StackDetailCase> createState() => _StackDetailCaseState();
}

class _StackDetailCaseState extends State<StackDetailCase> {
  late HomeRepo homeRepo;
  GlobalKey<FormBuilderState> formKey = GlobalKey();
  String theme = '';
  List<ApiConfig> reqApis = [];
  List<ApiConfig> resApis = [];
  List<ApiConfig> fields = [];
  Map<String, dynamic> initialValue = {};
  Map<String, dynamic> mapAreas = {};
  String? areas;
  double? columnGap, rowGap;
  List<TrackSize> columnSizes = [];
  List<TrackSize> rowSizes = [];
  late ValueKey renderKey;
  late final StreamSubscription _rowResponseSub;
  late final StreamSubscription _apiIdResponseSub;
  bool _isInitialized = false; // 중복 구독 방지용

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      homeRepo = context.read<HomeRepo>();

      _subscribeRowResponse();
      _subscribeApiIdResponse();
      _initLayoutAndAreas();

      _isInitialized = true;
    }
  }

  // row.json 수신 시 호출
  void _subscribeRowResponse() {
    _rowResponseSub = homeRepo.rowResponseStream.listen((v) {
      if (v != null) {
        setState(() {
          initialValue = {...initialValue, ...v};
          renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
        });
      }
    });
  }

  void _subscribeApiIdResponse() {
    _apiIdResponseSub = homeRepo.getApiIdResponseStream.listen((v) {
      if (v != null) {
        if (widget.item.boardId.split('-').first != homeRepo.currentTab) {
          return;
        }

        setState(() {
          final apiId = v['if_id'];
          initialValue = {
            ...initialValue,
            ...(() {
              final result = homeRepo.onApiResponse[apiId]?['data']?['result'];
              if (result is Map<String, dynamic>) {
                return result;
              } else if (result is List &&
                  result.isNotEmpty &&
                  result.first is Map<String, dynamic>) {
                return result.first as Map<String, dynamic>;
              }
              return <String, dynamic>{};
            })(),
          };
          renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
        });
      }
    });
  }

  void _initLayoutAndAreas() {
    final StackDetailItem item = widget.item;
    final DetailItemContent content = item.content!;
    theme = item.theme;
    columnGap = content.columnGap;
    rowGap = content.rowGap;
    columnSizes = (jsonDecode(content.columnSizes ?? '[]') as List<dynamic>)
        .map((e) => FlexibleTrackSize(e as double))
        .toList();
    rowSizes = (jsonDecode(content.rowSizes ?? '[]') as List<dynamic>)
        .map((e) => FlexibleTrackSize(e as double))
        .toList();
    areas = content.areas;
    if (areas == '' || areas == null) {
      areas = buildAreas(isDefault: true);
    } else {
      final rows =
          areas?.split(RegExp('\n')).map((row) => row.split(' ')).toList();
      mapAreas.clear();
      List.generate(rowSizes.length, (row) {
        List.generate(columnSizes.length, (col) {
          mapAreas['c-$row-$col'] = rows?.elementAt(row)[col];
        });
      });
    }

    reqApis = content.reqApis ?? [];
    resApis = content.resApis ?? [];
    setFields();

    renderKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
  }

  @override
  void dispose() {
    _rowResponseSub.cancel();
    _apiIdResponseSub.cancel();
    super.dispose();
  }

  void setFields() {
    if (resApis.isNotEmpty) {
      fields = [...resApis];
    }
  }

  String buildAreas({bool isDefault = false}) {
    String addArea = '';
    Map<String, dynamic> orgMapAreas = {...mapAreas};

    try {
      if (mapAreas.isNotEmpty) {
        final selected = mapAreas.entries.where((e) => e.value == 'selected');
        if (selected.isNotEmpty) {
          final mergeKey = 'm${selected.first.key}';
          mapAreas = mapAreas.map((key, value) {
            if (value == 'selected') {
              return MapEntry(key, mergeKey);
            } else {
              return MapEntry(key, value);
            }
          });
        }
      }

      List.generate(rowSizes.length, (row) {
        addArea += addArea.isNotEmpty ? '\n' : '';
        List.generate(columnSizes.length, (col) {
          if (isDefault) {
            mapAreas['c-$row-$col'] = 'c-$row-$col';
          }
          addArea += mapAreas['c-$row-$col']! + ' ';
        });
      });
    } catch (e) {
      mapAreas.clear();
      mapAreas = {...orgMapAreas};
    }

    return addArea;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [_buildNormal(context)]);
  }

  Widget _buildNormal(BuildContext context) {
    return FormBuilder(
        key: formKey,
        clearValueOnUnregister: true,
        onChanged: () {},
        child: Container(
          color: tableStyle(theme, 'borderColor'),
          child: LayoutGrid(
            key: renderKey,
            columnGap: columnGap,
            rowGap: rowGap,
            areas: areas,
            columnSizes: columnSizes,
            rowSizes: rowSizes,
            children: mapAreas.isEmpty
                ? [const SizedBox()]
                : [
                    ...mapAreas.entries.map((area) {
                      return gridArea(area.value).containing(_widget(area));
                    })
                  ],
          ),
        ));
  }

  Widget _widget(dynamic area) {
    ApiConfig? field = fields.firstWhereOrNull((e) => e.fieldNm == area.value);

    TextAlign textAlignValue = TextAlign.center; // 기본 정렬
    if (field != null && field.type != null) {
      if (["number", "currency", "percentage"].contains(field.type)) {
        textAlignValue = TextAlign.right;
      }
    }
    String? textAlignString = textAlignValue.name; // .name을 사용하여 문자열로 변환

    return Stack(fit: StackFit.expand, children: [
      Container(
        color: field?.type == "text"
            ? tableStyle(theme, 'fieldBackgroundColor')
            : tableStyle(theme,
                'labelBackgroundColor'), // tableStyle(theme, 'backgroundColor')
        child: FormBuilder(
          key: GlobalKey<FormBuilderState>(), // 고유 Key로 변경
          child: NewField(
            type: field == null
                ? FieldType.text
                : FieldType.values.byName(field.type ?? FieldType.text.name),
            name: field == null
                ? area.value as String
                : field.field ?? area.value as String,
            labelText: field == null
                ? area.value as String
                : field.fieldNm ?? area.value as String,
            initialValue: field == null
                ? area.value as String?
                : initialValue.keys.contains(field.field)
                    ? initialValue[field.field].toString()
                    : area.value as String?,
            textAlign: field == null
                ? textAlignString
                : field.align ?? textAlignString,
            format: field == null ? '' : field.format ?? '',
            enabled: field == null ? true : (field.enabled ?? true),
            callback: (v) {
              setState(() {
                if (field != null && field.field != null) {
                  initialValue[field.field!] = v;
                }
              });
            },
            theme: theme,
            widgetName: 'grid',
            homeRepo: homeRepo,
          ),
        ),
      ),
    ]);
  }
}
