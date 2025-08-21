import 'dart:async';
import 'dart:convert';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:idev_v1/src/board/board/dock_board.dart';
import 'package:idev_v1/src/board/helpers.dart';
import 'package:idev_v1/src/board/stack_board_items/common/new_field.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';
import '/src/di/service_locator.dart';
import 'package:idev_v1/src/theme/theme_table.dart';
import '/src/board/stack_items.dart';
import '/src/repo/home_repo.dart';
import '/src/repo/app_streams.dart';
import '/src/board/stack_board_item.dart';
import 'package:idev_v1/src/board/stack_board_items/common/models/api_config.dart';

/// * Draw object
class StackDetailCase extends StatefulWidget {
  StackDetailCase({
    super.key,
    required this.item,
    this.editItemController,
  });

  /// * StackDetailItem
  final StackDetailItem item;

  EditItemController? editItemController;

  @override
  State<StackDetailCase> createState() =>
      _StackDetailCaseState(editItemController);
}

class _StackDetailCaseState extends State<StackDetailCase> {
  _StackDetailCaseState(EditItemController? editItemController) {
    editItemController?.onMenu = onMenu;
  }

  late HomeRepo homeRepo;
  GlobalKey<FormBuilderState> formKey = GlobalKey();
  String savedValue = '';
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
  late ValueKey renderKey, renderKeyEditing;
  String onPanStatus = '';
  bool isPanStarted = false;
  String onTapCell = '';

  late final StreamSubscription _rowResponseSub;
  late final StreamSubscription _apiIdResponseSub;
  late final StreamSubscription _updateStackItemSub;

  late AppStreams appStreams;
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
      appStreams = sl<AppStreams>();

      _subscribeRowResponse();
      _subscribeApiIdResponse();
      _subscribeUpdateStackItem();
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
          formKey = GlobalKey();
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
          formKey = GlobalKey();
        });
      }
    });
  }

  void _subscribeUpdateStackItem() {
    _updateStackItemSub = appStreams.updateStackItemStream.listen((v) {
      if (v?.id == widget.item.id &&
          v is StackDetailItem &&
          v.boardId == widget.item.boardId) {
        final StackDetailItem item = v;
        final DetailItemContent content = item.content!;

        setState(() {
          theme = item.theme ?? 'White';
          reqApis = content.reqApis ?? [];
          resApis = content.resApis ?? [];
          areas = content.areas;
          columnGap = content.columnGap;
          rowGap = content.rowGap;
          columnSizes = (content.columnSizes ?? []) as List<TrackSize>;
          rowSizes = (content.rowSizes ?? []) as List<TrackSize>;
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
      final currentContentJson = content.toJson();
      final it = item.copyWith(
          status: StackItemStatus.selected,
          content: DetailItemContent.fromJson({
            ...currentContentJson,
            'areas': areas,
          }));
      homeRepo.updateStackItemState(it);
      homeRepo.addOnTapState(it);
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
    renderKeyEditing = ValueKey(DateTime.now().millisecondsSinceEpoch);
  }

  @override
  void dispose() {
    _rowResponseSub.cancel();
    _apiIdResponseSub.cancel();
    _updateStackItemSub.cancel();
    super.dispose();
  }

  void setFields() {
    if (resApis.isNotEmpty) {
      // fields = [...resApis.where((api) => api.checked ?? false)];
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

  String cancelAreas() {
    String addArea = '';
    if (mapAreas.isNotEmpty) {
      mapAreas = mapAreas.map((key, value) {
        if (value == 'selected') {
          return MapEntry(key, key);
        } else {
          return MapEntry(key, value);
        }
      });
    }

    List.generate(rowSizes.length, (row) {
      addArea += addArea.isNotEmpty ? '\n' : '';
      List.generate(columnSizes.length, (col) {
        addArea += mapAreas['c-$row-$col']! + ' ';
      });
    });

    return addArea;
  }

  void onMenu(String menu) {
    return switch (menu) {
      'merge' => mergeCells(),
      'cancelMerge' => cancelMerge(),
      'addColumnLeft' => addColumnLeft(),
      'addColumnRight' => addColumnRight(),
      'removeColumn' => removeColumn(),
      'addRowAbove' => addRowAbove(),
      'addRowBelow' => addRowBelow(),
      'removeRow' => removeRow(),
      _ => (),
    };
  }

  bool isMergedRow(String row) {
    bool merged = false;
    Map<String, dynamic> orgMapAreas = {...mapAreas};
    Map<String, dynamic> valCnt = {};
    for (var e in orgMapAreas.entries) {
      valCnt[e.value] = (valCnt[e.value] ?? 0) + 1;
    }

    Map<String, dynamic> cnt = {};
    orgMapAreas.entries.where((e) => e.key.split('-')[1] == row).forEach((e) {
      cnt[e.value] = (cnt[e.value] ?? 0) + 1;
    });

    cnt.forEach((key, value) {
      if (valCnt[key] != value) {
        merged = true;
      }
    });

    return merged;
  }

  bool isMergedColumn(String col) {
    Map<String, dynamic> orgMapAreas = {...mapAreas};
    bool merged = false;
    Map<String, dynamic> valCnt = {};
    for (var e in orgMapAreas.entries) {
      valCnt[e.value] = (valCnt[e.value] ?? 0) + 1;
    }

    Map<String, dynamic> cnt = {};
    orgMapAreas.entries.where((e) => e.key.split('-').last == col).forEach((e) {
      cnt[e.value] = (cnt[e.value] ?? 0) + 1;
    });

    cnt.forEach((key, value) {
      if (valCnt[key] != value) {
        merged = true;
      }
    });

    return merged;
  }

  void mergeCells() {
    setState(() {
      areas = buildAreas();
      renderKeyEditing = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  void cancelMerge() {
    setState(() {
      areas = cancelAreas();
      renderKeyEditing = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  void addColumnLeft() {
    if (onTapCell == '') {
      return;
    }
    final cell = onTapCell.split('-');
    final col = int.parse(cell.last);
    if (isMergedColumn(cell.last)) {
      showDialog(
          context: context,
          builder: (context) => const AlertDialog(
              title: Text('병합된 셀이 존재합니다. 병합을 해제하고 다시 시도하세요.')));
      return;
    }

    double? flex = columnSizes[col].flex;
    columnSizes.insert(col, FlexibleTrackSize(flex!));

    // 기존 설정 유지, 업서트
    setState(() {
      insertColumn(col);
      renderKeyEditing = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  void addColumnRight() {
    if (onTapCell == '') {
      return;
    }
    final cell = onTapCell.split('-');
    final col = int.parse(cell.last);
    if (isMergedColumn(cell.last)) {
      showDialog(
          context: context,
          builder: (context) => const AlertDialog(
              title: Text('병합된 셀이 존재합니다. 병합을 해제하고 다시 시도하세요.')));
      return;
    }

    double? flex = columnSizes[col].flex;
    columnSizes.insert(col, FlexibleTrackSize(flex!));

    // 기존 설정 유지, 업서트
    setState(() {
      insertColumn(col + 1);
      renderKeyEditing = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  void insertColumn(int col) {
    Map<String, dynamic> orgAreas = {...mapAreas};

    //1) mapAreas 초기화
    mapAreas.clear();
    buildAreas(isDefault: true);

    //2) copy from orgAreas to mapAreas
    orgAreas.forEach((key, value) {
      List<String> cell = key.split('-');
      final c = int.parse(cell.last);

      if (c < col) {
        mapAreas[key] = value;
      } else if (c >= col && key != value) {
        cell.last = '${c + 1}';
        final newKey = cell.join('-');
        mapAreas[newKey] = value;
      }
    });

    areas = buildAreas();
  }

  void removeColumn() {
    if (onTapCell == '') {
      return;
    }

    final cell = onTapCell.split('-');
    final col = int.parse(cell.last);
    if (isMergedColumn(cell.last)) {
      showDialog(
          context: context,
          builder: (context) => const AlertDialog(
              title: Text('병합된 셀이 존재합니다. 병합을 해제하고 다시 시도하세요.')));
      return;
    }
    columnSizes.removeAt(col);

    // 기존 설정 유지, 업서트
    setState(() {
      _removeColumn(col);
      renderKeyEditing = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  void _removeColumn(int col) {
    Map<String, dynamic> orgAreas = {...mapAreas};

    //1) mapAreas 초기화
    mapAreas.clear();
    buildAreas(isDefault: true);

    //2) copy from orgAreas to mapAreas
    orgAreas.forEach((key, value) {
      List<String> cell = key.split('-');
      final c = int.parse(cell.last);

      if (c < col) {
        mapAreas[key] = value;
      } else if (c > col && key != value) {
        cell.last = '${c - 1}';
        final newKey = cell.join('-');
        mapAreas[newKey] = value;
      }
    });

    areas = buildAreas();
  }

  void removeRow() {
    if (onTapCell == '') {
      return;
    }

    final cell = onTapCell.split('-');
    final row = int.parse(cell[1]);
    if (isMergedRow(cell[1])) {
      showDialog(
          context: context,
          builder: (context) =>
              const AlertDialog(title: Text('머지된 셀 존재하니 해제한 후 삭제합니다.')));
      return;
    }
    rowSizes.removeAt(row);

    // 기존 설정 유지, 업서트
    setState(() {
      _removeRow(row);
      renderKeyEditing = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  void _removeRow(int row) {
    Map<String, dynamic> orgAreas = {...mapAreas};

    //1) mapAreas 초기화
    mapAreas.clear();
    buildAreas(isDefault: true);

    //2) copy from orgAreas to mapAreas
    orgAreas.forEach((key, value) {
      List<String> cell = key.split('-');
      final r = int.parse(cell[1]);

      if (r < row) {
        mapAreas[key] = value;
      } else if (r > row && key != value) {
        cell[1] = '${r - 1}';
        final newKey = cell.join('-');
        mapAreas[newKey] = value;
      }
    });

    areas = buildAreas();
  }

  void addRowAbove() {
    if (onTapCell == '') {
      return;
    }
    final cell = onTapCell.split('-');
    final row = int.parse(cell[1]);
    if (isMergedRow(cell[1])) {
      showDialog(
          context: context,
          builder: (context) =>
              const AlertDialog(title: Text('머지된 셀 존재하니 해제한 후 삭제합니다.')));
      return;
    }

    double? flex = rowSizes[row].flex;
    rowSizes.insert(row, FlexibleTrackSize(flex!));

    // 기존 설정 유지, 업서트
    setState(() {
      insertRow(row);
      renderKeyEditing = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  void addRowBelow() {
    if (onTapCell == '') {
      return;
    }
    final cell = onTapCell.split('-');
    final row = int.parse(cell[1]);
    if (isMergedRow(cell[1])) {
      showDialog(
          context: context,
          builder: (context) =>
              const AlertDialog(title: Text('머지된 셀 존재하니 해제한 후 삭제합니다.')));
      return;
    }

    double? flex = rowSizes[row].flex;
    rowSizes.insert(row, FlexibleTrackSize(flex!));

    // 기존 설정 유지, 업서트
    setState(() {
      insertRow(row + 1);
      renderKeyEditing = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  void insertRow(int row) {
    Map<String, dynamic> orgAreas = {...mapAreas};

    //1) mapAreas 초기화
    mapAreas.clear();
    buildAreas(isDefault: true);

    //2) copy from orgAreas to mapAreas
    orgAreas.forEach((key, value) {
      List<String> cell = key.split('-');
      final r = int.parse(cell[1]);

      if (r < row) {
        mapAreas[key] = value;
      } else if (r >= row && key != value) {
        cell[1] = '${r + 1}';
        final newKey = cell.join('-');
        mapAreas[newKey] = value;
      }
    });

    areas = buildAreas();
  }

  void changeSize({dynamic area}) async {
    final cell = area.key.split('-');
    final result = await showTextInputDialog(
      context: context,
      style: AdaptiveStyle.material,
      textFields: [
        DialogTextField(
          prefixText: '폭: ',
          suffixText: '[fr]',
          initialText: '${columnSizes[int.parse(cell.last)].flex}',
        ),
        DialogTextField(
          prefixText: '높이: ',
          suffixText: '[fr]',
          initialText: '${rowSizes[int.parse(cell[1])].flex}',
        ),
        DialogTextField(
          prefixText: '셀/이름: ',
          hintText: '이름',
          initialText: area.value,
        ),
      ],
    );

    // 동일한 셀 이름이 이미 존재하거나 공백이면 오류처리
    String value = result?[2] ?? '';
    if (area.value != value &&
        (mapAreas.containsValue(value) || value.isEmpty)) {
      await showDialog(
          context: context,
          builder: (context) =>
              const AlertDialog(title: Text('동일한 셀/이름 존재하거나 공백입니다.')));
      return;
    }

    setState(() {
      columnSizes[int.parse(cell.last)] =
          FlexibleTrackSize(double.parse(result![0].toString()));
      rowSizes[int.parse(cell[1])] =
          FlexibleTrackSize(double.parse(result[1].toString()));
      String changedValue = result[2].toString().isEmpty ? '_' : result[2];
      mapAreas = mapAreas.map((key, value) {
        if (value == area.value) {
          return MapEntry(key, changedValue);
        } else {
          return MapEntry(key, value);
        }
      });
      areas = areas?.replaceAll(area.value, changedValue);
      renderKeyEditing = ValueKey(DateTime.now().millisecondsSinceEpoch);
    });
  }

  StackItemStatus changedStatus = StackItemStatus.idle;

  @override
  Widget build(BuildContext context) {
    if (widget.item.status == StackItemStatus.editing) {
      changedStatus = StackItemStatus.editing;
    }
    if (changedStatus == StackItemStatus.editing &&
        widget.item.status != StackItemStatus.editing) {
      changedStatus = StackItemStatus.idle;
      final it = widget.item.copyWith(
          status: StackItemStatus.selected,
          content: DetailItemContent.fromJson({
            ...widget.item.content!.toJson(),
            'areas': areas,
            'columnSizes': jsonEncode(columnSizes.map((e) => e.flex).toList()),
            'rowSizes': jsonEncode(rowSizes.map((e) => e.flex).toList()),
          }));
      homeRepo.updateStackItemState(it);
      homeRepo.addOnTapState(it);
    }

    return Stack(fit: StackFit.expand, children: [
      widget.item.status == StackItemStatus.editing
          ? _buildEditing(context)
          : _buildNormal(context)
    ]);
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

  Widget _buildEditing(BuildContext context) {
    return GestureDetector(
      onPanStart: (DragStartDetails dud) => _onPanStart(dud),
      onPanUpdate: (DragUpdateDetails dud) => _onPanUpdate(dud),
      onPanEnd: (DragEndDetails dud) => _onPanEnd(dud),
      child: Container(
        color: Colors.grey,
        child: LayoutGrid(
          key: renderKeyEditing,
          columnGap: columnGap,
          rowGap: rowGap,
          areas: areas,
          columnSizes: columnSizes,
          rowSizes: rowSizes,
          children: mapAreas.isEmpty
              ? [const SizedBox()]
              : [
                  ...mapAreas.entries.map((area) {
                    return _widgetEditing(area);
                  })
                ],
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails dud) {
    isPanStarted = true;
    onPanStatus = 'start';
  }

  void _onPanUpdate(DragUpdateDetails dud) {
    onPanStatus = 'update';
  }

  void _onPanEnd(DragEndDetails dud) {
    onPanStatus = 'end';
  }

  Widget _widget(dynamic area) {
    ApiConfig? field = fields.firstWhereOrNull((e) => e.fieldNm == area.value);

    TextAlign textAlignValue = TextAlign.center; // 기본 정렬
    if (field != null && field.type != null) {
      // 숫자 타입 등 특정 타입에 대해 오른쪽 정렬 적용 가능
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
      onTapCell == area.key ? _buildSelectedBorder() : const SizedBox.shrink()
    ]);
  }

  Widget _widgetEditing(dynamic area) {
    return MouseRegion(
        onEnter: (PointerEnterEvent e) {
          if (onPanStatus == 'update' && mapAreas[area.key] != 'selected') {
            setState(() {
              mapAreas[area.key] = 'selected';
              renderKeyEditing =
                  ValueKey(DateTime.now().millisecondsSinceEpoch);
            });
          }
        },
        onExit: (PointerExitEvent e) {
          if (isPanStarted &&
              onPanStatus == 'update' &&
              mapAreas[area.key] != 'selected') {
            setState(() {
              mapAreas[area.key] = 'selected';
              renderKeyEditing =
                  ValueKey(DateTime.now().millisecondsSinceEpoch);
            });
          }
          isPanStarted = false;
        },
        child: InkWell(
          onTap: () {
            setState(() {
              if (onTapCell == area.key) {
                onTapCell = '';
              } else {
                onTapCell = area.key;
              }
            });
          },
          child: Stack(fit: StackFit.expand, children: [
            Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(4.0),
                color: mapAreas[area.key] == 'selected'
                    ? Colors.blue.shade100
                    : area.key == onTapCell // 현재 커서 셀
                        ? Colors.grey.shade100
                        : Colors.white,
                child: InkWell(
                  onTap: () {
                    changeSize(area: area);
                  },
                  child: Wrap(
                    children: [
                      Text(area.value,
                          style: TextStyle(
                              color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color ??
                                  Colors.black)),
                      const Icon(
                        Icons.settings,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                )),
          ]),
        ));
  }

  Widget _buildSelectedBorder() {
    // Implementation of _buildSelectedBorder method
    return Container(); // Placeholder, actual implementation needed
  }
}
