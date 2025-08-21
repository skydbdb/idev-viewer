import 'dart:convert';
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/board/core/stack_board_item/stack_item_status.dart';
import 'package:idev_v1/src/board/stack_board_items/common/models/menu_config.dart';
import 'package:idev_v1/src/const/code.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../board/core/stack_board_item/stack_item_content.dart';
import '/src/board/core/stack_board_item/stack_item.dart';

import '/src/board/stack_items.dart';
import 'helper/property_fields.dart';
import 'helper/property_content_renderers.dart';
import '/src/repo/home_repo.dart';
import '/src/repo/app_streams.dart';
import '/src/di/service_locator.dart';
import '/src/board/stack_board_items/common/models/api_config.dart';
import '/src/util/widget/popup_grid.dart';
import '/src/theme/themes.dart';

class PropertyInspector extends StatefulWidget {
  final StackItem? selectedItem;

  const PropertyInspector({super.key, this.selectedItem});

  @override
  State<PropertyInspector> createState() => _PropertyInspectorState();
}

class _PropertyInspectorState extends State<PropertyInspector> {
  Map<String, List<dynamic>> selectProperty = {
    'mode': ['normal', 'select'],
    'color': ['transparent', 'red', 'green', 'blue', 'yellow'],
    'colorBlendMode': ['color', 'xor', 'src', 'clear'],
    'fit': BoxFit.values.map((e) => e.name).toList(),
    'repeat': ['repeat', 'repeatX', 'repeatY'],
    'appBar': breakPoints,
    'actions': breakPoints,
    'drawer': breakPoints,
    'subBody': breakPoints,
    'leftNavigation': breakPoints,
    'rightNavigation': breakPoints,
    'topNavigation': breakPoints,
    'bottomNavigation': breakPoints,
    'bodyOrientation': ['horizontal', 'vertical'],
    'subBodyOptions': ['none', 'vertical', 'detail'],
    'bodyRatio': [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1],
    'chartType': ['column', 'pie', 'line', 'area', 'bar'],
    'primaryXAxisType': ['numeric', 'datetime', 'category'],
    'primaryYAxisType': ['numeric', 'datetime', 'category'],
    'xValueMapper': ['name', 'age'],
    'yValueMapper': ['name', 'age'],
    'xAxisLabelFormat': ['default'],
    'yAxisLabelFormat': ['default'],
    'selectionType': ['point', 'series', 'cluster'],
    'autoScrollingMode': ['start', 'end'],
    'buttonType': ['api', 'url', 'template'],
    'sizeOption': ['Scroll', 'Fit'],
  };

  void _resetXYMapper(List<dynamic> value) {
    if (value.isNotEmpty) {
      final first = value.first;
      if (first is Map<String, dynamic>) {
        selectProperty['xValueMapper'] = first.keys.toList();
      }
      selectProperty['yValueMapper'] =
          first.keys.toList().map((e) => {e: e}).toList();
    }
  }

  Map<String, dynamic> _resetXYFormatMapper(String key, String format) {
    Map<String, List<dynamic>> xyFormat = {
      'datetime': ['yyyy/MM/dd', 'MM/dd', 'yyyy/MM', 'yyyy', 'MM', 'dd'],
      'numeric': [
        '#,###',
        '#,###.00',
        'percentage',
        'currency_kr',
        'currency_us',
        'currency_eu',
      ],
      'category': [
        'default',
      ]
    };

    if (key == 'primaryXAxisType') {
      selectProperty['xAxisLabelFormat'] = xyFormat[format] ?? [];
      return {
        'xAxisLabelFormat': selectProperty['xAxisLabelFormat']?.toList().first,
      };
    } else if (key == 'primaryYAxisType') {
      selectProperty['yAxisLabelFormat'] = xyFormat[format] ?? [];
      return {
        'yAxisLabelFormat': selectProperty['yAxisLabelFormat']?.toList().first,
      };
    }
    return {};
  }

  T byName<T>(String key, dynamic value) {
    return switch (key) {
      'colorBlendMode' => BlendMode.values.byName(value),
      'fit' => BoxFit.values.byName(value),
      'repeat' => ImageRepeat.values.byName(value),
      'bodyOrientation' => Axis.values.byName(value),
      'bodyRatio' => value is String
          ? double.parse(value)
          : (value is num ? value.toDouble() : 0.5),
      'xValueMapper' =>
        selectProperty['xValueMapper']?.firstWhere((e) => e == value) ??
            selectProperty['xValueMapper']?.first,
      'selectionType' => SelectionType.values.byName(value),
      'autoScrollingMode' => AutoScrollingMode.values.byName(value),
      _ => value
    };
  }

  late HomeRepo homeRepo;
  late AppStreams appStreams;

  // 필수 속성별 TextEditingController (초기화는 이후 build에서 selectedItem 값으로)
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _offsetXController;
  late final TextEditingController _offsetYController;
  late final TextEditingController _angleController;
  late final TextEditingController _paddingAllController;
  late final TextEditingController _paddingLeftController;
  late final TextEditingController _paddingRightController;
  late final TextEditingController _paddingTopController;
  late final TextEditingController _paddingBottomController;
  late final TextEditingController _permissionController;
  late final TextEditingController _themeController;
  // content 속성별 TextEditingController
  final Map<String, TextEditingController> _contentControllers = {};

  // padding 상태 변수 추가
  bool _isPaddingAll = true;
  double _paddingAll = 0;
  double _paddingLeft = 0;
  double _paddingRight = 0;
  double _paddingTop = 0;
  double _paddingBottom = 0;

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();
    // 컨트롤러는 build에서 selectedItem 값으로 초기화
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _offsetXController = TextEditingController();
    _offsetYController = TextEditingController();
    _angleController = TextEditingController();
    _paddingAllController = TextEditingController();
    _paddingLeftController = TextEditingController();
    _paddingRightController = TextEditingController();
    _paddingTopController = TextEditingController();
    _paddingBottomController = TextEditingController();
    _permissionController = TextEditingController();
    _themeController = TextEditingController();
    _syncPaddingFromItem();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _offsetXController.dispose();
    _offsetYController.dispose();
    _angleController.dispose();
    _paddingAllController.dispose();
    _paddingLeftController.dispose();
    _paddingRightController.dispose();
    _paddingTopController.dispose();
    _paddingBottomController.dispose();
    _permissionController.dispose();
    _themeController.dispose();
    for (final c in _contentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PropertyInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // selectedItem이 바뀔 때만 동기화
    if (widget.selectedItem?.id != oldWidget.selectedItem?.id) {
      _syncPaddingFromItem();
    }
  }

  void _syncPaddingFromItem() {
    final item = widget.selectedItem;
    if (item == null) return;
    final padding = item.padding;
    _isPaddingAll = (padding.left == padding.right &&
        padding.left == padding.top &&
        padding.left == padding.bottom);
    _paddingAll = _isPaddingAll ? padding.left : 0;
    _paddingLeft = padding.left;
    _paddingRight = padding.right;
    _paddingTop = padding.top;
    _paddingBottom = padding.bottom;
    _paddingAllController.text = _paddingAll.toString();
    _paddingLeftController.text = _paddingLeft.toString();
    _paddingRightController.text = _paddingRight.toString();
    _paddingTopController.text = _paddingTop.toString();
    _paddingBottomController.text = _paddingBottom.toString();
  }

  void _updatePaddingToItem() {
    final item = widget.selectedItem;
    if (item != null) {
      final newPadding = _isPaddingAll
          ? EdgeInsets.all(_paddingAll)
          : EdgeInsets.fromLTRB(
              _paddingLeft, _paddingTop, _paddingRight, _paddingBottom);
      onChangedProperties({
        'padding': {
          'left': newPadding.left,
          'right': newPadding.right,
          'top': newPadding.top,
          'bottom': newPadding.bottom,
        }
      }, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedItem == null) {
      return Theme(
        data: ThemeData.dark(),
        child: Container(
          color: Colors.black,
          child: const Center(child: Text('항목을 선택하거나 로드 중입니다...')),
        ),
      );
    }
    final item = widget.selectedItem!;
    // 컨트롤러 값 동기화(읽기 전용)
    _widthController.text = item.size.width.toStringAsFixed(0);
    _heightController.text = item.size.height.toStringAsFixed(0);
    _offsetXController.text = item.offset.dx.toStringAsFixed(0);
    _offsetYController.text = item.offset.dy.toStringAsFixed(0);
    // 라디안을 도로 변환하여 표시
    _angleController.text = (item.angle * 180 / Math.pi).toStringAsFixed(1);
    _permissionController.text = item.permission;
    _themeController.text = item.theme;
    return Theme(
      data: ThemeData.dark(),
      child: Container(
        color: Colors.black,
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // Padding(
            //     padding: const EdgeInsets.only(right: 10.0),
            //     child: _buildDropdownProperty(
            //       context,
            //       label: '보드',
            //       value: item.boardId,
            //       items: homeRepo.hierarchicalControllers.keys.toList(),
            //       onChanged: (v) {
            //         if (v != null && v != item.boardId) {
            //           homeRepo.selectDockBoardState(v);
            //           sl<AppStreams>().addOnPropertyState(v);
            //         }
            //       },
            //     )),
            _buildPropertySection(
              context,
              title: '기본 속성',
              content: Column(
                children: [
                  _buildReadonlyPropertyField(
                    context,
                    label: '보드',
                    value: item.boardId,
                  ),
                  _buildReadonlyPropertyField(
                    context,
                    label: '아이디',
                    value: item.id,
                  ),
                  _buildReadonlyPropertyField(
                    context,
                    label: '타입',
                    value: convertType(item),
                  ),
                  _buildDropdownProperty(
                    context,
                    label: '상태',
                    value: item.status.name,
                    items: ['idle', 'selected', 'editing', 'locked'],
                    onChanged: (newValue) {
                      final it = item.copyWith(
                          status: StackItemStatus.values
                              .byName(newValue.toString()));
                      homeRepo.updateStackItemState(it);
                    },
                  ),
                  _buildDimensionProperty(context, item),
                  _buildOffsetProperty(context, item),
                  _buildAngleProperty(context, item),
                  _buildPermissionProperty(context, item),
                  _buildThemeProperty(context, item),
                  _buildPaddingProperty(context, item),
                  _buildBooleanSwitch(
                    context,
                    item,
                    label: '레이어 고정',
                    key: 'lockZOrder',
                    value: item.lockZOrder,
                  ),
                  _buildBooleanSwitch(
                    context,
                    item,
                    label: '도킹',
                    key: 'dock',
                    value: item.dock,
                  ),
                ],
              ),
            ),
            _buildPropertySection(
              context,
              title: '콘텐츠 속성',
              content: _buildContentProperties(context, item),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertySection(
    BuildContext context, {
    required String title,
    required Widget content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF181A1B), // 더 어두운 배경
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(
          dividerColor: Colors.grey[800],
          textTheme: ThemeData.dark().textTheme.copyWith(
                titleMedium: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                labelMedium: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 0.0,
          ),
          title: Text(title),
          collapsedIconColor: Colors.grey[400],
          iconColor: Colors.grey[200],
          childrenPadding: const EdgeInsets.only(left: 0, right: 10),
          textColor: Colors.white,
          collapsedTextColor: Colors.grey[400],
          children: [content],
        ),
      ),
    );
  }

  Widget _buildReadonlyPropertyField(
    BuildContext context, {
    required String label,
    required dynamic value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4.0),
          buildStyledTextField(
            controller: TextEditingController(text: value.toString()),
            onChanged: (_) {},
            readOnly: true,
            enabled: false,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownProperty<T>(
    BuildContext context, {
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4.0),
            buildStyledDropdown<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              context: context,
            ),
          ],
        ));
  }

  Widget _buildCheckboxListProperty<T>(
    BuildContext context, {
    required String label,
    required List<T> selectedValues,
    required List<T> allItems,
    required ValueChanged<List<T>> onChanged,
    int? maxHeight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4.0),
          buildStyledCheckboxList<T>(
            selectedValues: selectedValues,
            allItems: allItems,
            onChanged: onChanged,
            context: context,
            maxHeight: maxHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyField(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: label.isNotEmpty
          ? const EdgeInsets.only(bottom: 8.0)
          : const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          child,
        ],
      ),
    );
  }

  Widget _buildPropertyFieldWithDynamicTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String initialValue,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4.0),
          DynamicTextField(
            fieldKey: label,
            initialValue: initialValue,
            onChanged: onChanged,
            onSubmitted: onChanged,
            decoration: buildInputDecoration(hintText: label, isDense: true),
            readOnly: readOnly,
            enabled: enabled,
            keyboardType: keyboardType,
          ),
        ],
      ),
    );
  }

  // Size(X=Width, Y=Height) 속성 (Offset과 동일한 구조)
  Widget _buildDimensionProperty(BuildContext context, StackItem item) {
    _widthController.text = item.size.width.toString();
    _heightController.text = item.size.height.toString();
    return Row(
      children: [
        Expanded(
          child: _buildPropertyFieldWithDynamicTextField(
            context: context,
            label: '너비',
            controller: _widthController,
            initialValue: item.size.width.toString(),
            onChanged: (v) {
              final width = double.tryParse(v) ?? item.size.width;
              onChangedProperties({
                'size': {'width': width, 'height': item.size.height}
              }, item);
            },
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: _buildPropertyFieldWithDynamicTextField(
            context: context,
            label: '높이',
            controller: _heightController,
            initialValue: item.size.height.toString(),
            onChanged: (v) {
              final height = double.tryParse(v) ?? item.size.height;
              onChangedProperties({
                'size': {'width': item.size.width, 'height': height}
              }, item);
            },
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  // my_app.dart 스타일의 OffsetProperty
  Widget _buildOffsetProperty(BuildContext context, StackItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('위치', style: Theme.of(context).textTheme.labelMedium),
        Row(
          children: [
            Expanded(
              child: _buildPropertyFieldWithDynamicTextField(
                context: context,
                label: '왼쪽에서',
                controller: _offsetXController,
                initialValue: item.offset.dx.toString(),
                onChanged: (v) {
                  final x = double.tryParse(v) ?? item.offset.dx;
                  onChangedProperties({
                    'offset': {'dx': x, 'dy': item.offset.dy}
                  }, item);
                },
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: _buildPropertyFieldWithDynamicTextField(
                context: context,
                label: '위쪽에서',
                controller: _offsetYController,
                initialValue: item.offset.dy.toString(),
                onChanged: (v) {
                  final y = double.tryParse(v) ?? item.offset.dy;
                  onChangedProperties({
                    'offset': {'dx': item.offset.dx, 'dy': y}
                  }, item);
                },
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // my_app.dart 스타일의 AngleProperty
  Widget _buildAngleProperty(BuildContext context, StackItem item) {
    // 라디안을 도로 변환하여 표시
    final angleInDegrees = (item.angle * 180 / Math.pi).toStringAsFixed(1);

    return _buildPropertyFieldWithDynamicTextField(
      context: context,
      label: '각도 (도)',
      controller: _angleController,
      initialValue: angleInDegrees,
      onChanged: (v) {
        // 도를 라디안으로 변환
        final angleInRadians = (double.tryParse(v) ?? 0) * Math.pi / 180;
        onChangedProperties({'angle': angleInRadians}, item);
      },
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildPermissionProperty(BuildContext context, StackItem item) {
    return _buildPropertyFieldWithDynamicTextField(
      context: context,
      label: '권한',
      controller: _permissionController,
      initialValue: item.permission,
      onChanged: (v) {
        onChangedProperties({'permission': v}, item);
      },
      keyboardType: TextInputType.text,
    );
  }

  Widget _buildThemeProperty(BuildContext context, StackItem item) {
    final themeKeys = themes.keys.toList();
    return _buildDropdownProperty(
      context,
      label: '테마',
      value: item.theme,
      items: themeKeys,
      onChanged: (v) {
        if (v != null && v != item.theme) {
          onChangedProperties({'theme': v}, item);
        }
      },
    );
  }

  // Padding 속성: all/left/right/top/bottom 세부 항목 UI 복원
  Widget _buildPaddingProperty(BuildContext context, StackItem item) {
    _paddingAllController.text = _paddingAll.toString();
    _paddingLeftController.text = _paddingLeft.toString();
    _paddingRightController.text = _paddingRight.toString();
    _paddingTopController.text = _paddingTop.toString();
    _paddingBottomController.text = _paddingBottom.toString();

    final showDetail = !_isPaddingAll;
    return _buildPropertyField(
      context,
      label: '여백',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPropertyFieldWithDynamicTextField(
                  context: context,
                  label: '전체',
                  controller: _paddingAllController,
                  initialValue: _paddingAll.toString(),
                  onChanged: _isPaddingAll
                      ? (v) {
                          setState(() {
                            _paddingAll = double.tryParse(v) ?? 0;
                            _paddingLeft = _paddingAll;
                            _paddingRight = _paddingAll;
                            _paddingTop = _paddingAll;
                            _paddingBottom = _paddingAll;
                            _updatePaddingToItem();
                          });
                        }
                      : (v) {},
                  keyboardType: TextInputType.number,
                  readOnly: !_isPaddingAll,
                  enabled: _isPaddingAll,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Row(
                  children: [
                    const Expanded(child: Text(' ')),
                    const Text('전체'),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _isPaddingAll,
                        onChanged: (v) {
                          setState(() {
                            _isPaddingAll = v;
                            if (v) {
                              // All로 전환 시 4방향 동기화
                              _paddingLeft = _paddingAll;
                              _paddingRight = _paddingAll;
                              _paddingTop = _paddingAll;
                              _paddingBottom = _paddingAll;
                            }
                            _updatePaddingToItem();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showDetail)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildPropertyFieldWithDynamicTextField(
                        context: context,
                        label: '왼쪽',
                        controller: _paddingLeftController,
                        initialValue: _paddingLeft.toString(),
                        onChanged: (v) {
                          setState(() {
                            _paddingLeft = double.tryParse(v) ?? 0;
                            _updatePaddingToItem();
                          });
                        },
                        keyboardType: TextInputType.number,
                        readOnly: false,
                        enabled: true,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: _buildPropertyFieldWithDynamicTextField(
                        context: context,
                        label: '오른쪽',
                        controller: _paddingRightController,
                        initialValue: _paddingRight.toString(),
                        onChanged: (v) {
                          setState(() {
                            _paddingRight = double.tryParse(v) ?? 0;
                            _updatePaddingToItem();
                          });
                        },
                        keyboardType: TextInputType.number,
                        readOnly: false,
                        enabled: true,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildPropertyFieldWithDynamicTextField(
                        context: context,
                        label: '위쪽',
                        controller: _paddingTopController,
                        initialValue: _paddingTop.toString(),
                        onChanged: (v) {
                          setState(() {
                            _paddingTop = double.tryParse(v) ?? 0;
                            _updatePaddingToItem();
                          });
                        },
                        keyboardType: TextInputType.number,
                        readOnly: false,
                        enabled: true,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: _buildPropertyFieldWithDynamicTextField(
                        context: context,
                        label: '아래쪽',
                        controller: _paddingBottomController,
                        initialValue: _paddingBottom.toString(),
                        onChanged: (v) {
                          setState(() {
                            _paddingBottom = double.tryParse(v) ?? 0;
                            _updatePaddingToItem();
                          });
                        },
                        keyboardType: TextInputType.number,
                        readOnly: false,
                        enabled: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBooleanSwitch(
    BuildContext context,
    StackItem item, {
    required String label,
    required String key,
    required bool value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: buildStyledSwitch(
        value: value,
        onChanged: (v) {
          onChangedProperties({key: v}, item);
        },
        label: label,
        context: context,
      ),
    );
  }

  // 콘텐츠 속성 렌더링: itemType별로 분기하여 모든 속성명을 맞춤 위젯으로 노출
  Widget _buildContentProperties(BuildContext context, StackItem item) {
    final content = item.content;
    if (content == null) {
      return const Text('콘텐츠 속성이 없습니다.');
    }
    final contentMap = content.toJson();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentMap.entries.map((entry) {
        final key = entry.key;
        final value = entry.value;

        if (key == 'reqApis' || key == 'resApis') {
          bool enabledSettings = true;
          bool cancelSettings =
              value.isNotEmpty && value != '[]' ? true : false;

          if ((item is StackDetailItem || item is StackSearchItem) &&
              key == 'reqApis' &&
              homeRepo.selectedApis.isNotEmpty) {
            enabledSettings = true;
          } else if (item is StackDetailItem && key == 'resApis') {
            enabledSettings = true;
          } else if (cancelSettings) {
            enabledSettings = true;
          } else if (contentMap['apiId'] == null ||
              contentMap['apiId'].isEmpty) {
            enabledSettings = false;
          }

          return ListTile(
            title: Text(convertContentKey(key)),
            subtitle: Text(value?.toString() ?? '', maxLines: 1),
            leading: cancelSettings
                ? IconButton(
                    onPressed: () {
                      List<ApiConfig> emp = [];
                      final newContent = copyWithDynamic(content, key, emp);
                      onChangedProperties(
                          {'content': newContent.toJson()}, item);
                    },
                    icon: const Icon(Icons.delete))
                : null,
            trailing: IconButton(
              icon: Icon(
                  enabledSettings ? Icons.settings : Icons.not_accessible,
                  color: Colors.white70),
              onPressed: () async {
                if (!enabledSettings) {
                  return;
                }
                final result = await PopupGrid(
                  context: context,
                  homeRepo: homeRepo,
                  properties: item.toJson(),
                  field: key,
                  title: null,
                  selectedApis: homeRepo.selectedApis,
                  frameBoards: homeRepo.hierarchicalControllers.keys
                      .where((k) => k.contains(
                          homeRepo.currentProperties?.toJson()?['id'] ?? ''))
                      .toList(),
                ).openGridPopup(context);
                if (result != null && result.selectedRows != null) {
                  List<ApiConfig> configs = result.selectedRows!
                      .map((row) => ApiConfig.fromJson(row.toJson()))
                      .toList();
                  setState(() {
                    final newContent = copyWithDynamic(content, key, configs);
                    onChangedProperties({'content': newContent.toJson()}, item);
                  });
                }
              },
            ),
          );
        } else if (key == 'reqMenus') {
          return ListTile(
            title: Text(convertContentKey(key)),
            subtitle: Text(value?.toString() ?? '', maxLines: 1),
            trailing: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: () async {
                final result = await PopupGrid(
                  context: context,
                  homeRepo: homeRepo,
                  properties: item.toJson(),
                  field: key,
                  title: null,
                  selectedApis: homeRepo.selectedApis,
                  frameBoards: homeRepo.hierarchicalControllers.keys
                      .where((k) => k.contains(
                          homeRepo.currentProperties?.toJson()?['id'] ?? ''))
                      .toList(),
                ).openGridPopup(context);
                if (result != null && result.selectedRows != null) {
                  List<MenuConfig> configs = result.selectedRows!
                      .map((row) => MenuConfig.fromJson(row.toJson()))
                      .toList();
                  setState(() {
                    final newContent = copyWithDynamic(content, key, configs);
                    onChangedProperties({'content': newContent.toJson()}, item);
                  });
                }
              },
            ),
          );
        } else if (key == 'tabsTitle') {
          return ListTile(
            title: Text(convertContentKey(key)),
            subtitle: Text(value?.toString() ?? '',
                maxLines: 3, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: () async {
                final result = await PopupGrid(
                  context: context,
                  homeRepo: homeRepo,
                  properties: item.toJson(),
                  field: key,
                  title: null,
                  selectedApis: homeRepo.selectedApis,
                  frameBoards:
                      homeRepo.childParentRelations[item.boardId] ?? [],
                ).openGridPopup(context);
                if (result != null && result.selectedRows != null) {
                  List<dynamic> configs =
                      result.selectedRows!.map((row) => row.toJson()).toList();
                  setState(() {
                    var newContent = item.content as FrameItemContent;
                    newContent =
                        newContent.copyWith(tabsTitle: jsonEncode(configs));
                    final json = item.copyWith(content: newContent).toJson();
                    onChangedProperties(json, item);
                  });
                }
              },
            ),
          );
        } else if (key == 'dataSource') {
          _resetXYMapper(value);
          return _buildReadonlyPropertyField(context,
              label: convertContentKey(key), value: value);
        } else if (['primaryXAxisType', 'primaryYAxisType'].contains(key)) {
          _resetXYFormatMapper(key, value);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildDropdownProperty(
              context,
              label: convertContentKey(key),
              value: (selectProperty[key]?.contains(value) ?? false)
                  ? value
                  : null,
              items: selectProperty[key]?.toList() ?? [],
              onChanged: (v) {
                if (v == null) return;
                Map<String, dynamic> formatMapper = {};
                if (['primaryXAxisType', 'primaryYAxisType'].contains(key)) {
                  formatMapper = _resetXYFormatMapper(key, v);
                }

                final newContent =
                    copyWithDynamic(content, key, byName(key, v));
                onChangedProperties({
                  'content': {...newContent.toJson(), ...formatMapper}
                }, item);
              },
            ),
          );
        } else if (key == 'yValueMapper') {
          List<Map<String, String>> selectedValues = [];
          if (value is List) {
            selectedValues = value.map((item) {
              if (item is Map<String, dynamic>) {
                final key = item.keys.first;
                final val = item[key]?.toString() ?? key;
                return {key: val};
              } else if (item is String) {
                return {item: item};
              }
              return {item.toString(): item.toString()};
            }).toList();
          } else if (value is String && value.isNotEmpty) {
            final keys = value.split(',').map((e) => e.trim()).toList();
            selectedValues = keys.map((key) => {key: key}).toList();
          }

          return _buildCheckboxListWithTextFieldProperty(
            context,
            label: convertContentKey(key),
            selectedValues: selectedValues,
            allItems: selectProperty[key]
                    ?.toList()
                    .map((e) => e.keys.first.toString())
                    .toList() ??
                [],
            onChanged: (v) {
              final newContent = copyWithDynamic(content, key, v);
              onChangedProperties({'content': newContent.toJson()}, item);
            },
          );
        } else if (selectProperty.containsKey(key)) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _buildDropdownProperty(
              context,
              label: convertContentKey(key),
              value: (selectProperty[key]?.contains(value) ?? false)
                  ? value
                  : null,
              items: selectProperty[key]?.toList() ?? [],
              onChanged: (v) {
                if (v == null) return;
                final newContent =
                    copyWithDynamic(content, key, byName(key, v));
                onChangedProperties({'content': newContent.toJson()}, item);
              },
            ),
          );
        } else if (value is bool) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: buildStyledSwitch(
              value: value,
              onChanged: (v) {
                final newContent = copyWithDynamic(content, key, v);
                onChangedProperties({'content': newContent.toJson()}, item);
              },
              label: convertContentKey(key),
              context: context,
            ),
          );
        } else if (value is num ||
            (value is String && double.tryParse(value) != null)) {
          // 숫자형(실제 num이거나, 숫자 문자열) 속성
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(convertContentKey(key),
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4.0),
                DynamicTextField(
                  fieldKey: key,
                  initialValue: value.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = double.tryParse(v);
                    final newContent = copyWithDynamic(content, key, parsed);
                    onChangedProperties({'content': newContent.toJson()}, item);
                  },
                  onSubmitted: (v) {
                    final parsed = double.tryParse(v);
                    final newContent = copyWithDynamic(content, key, parsed);
                    onChangedProperties({'content': newContent.toJson()}, item);
                  },
                  decoration: buildInputDecoration(
                      hintText: convertContentKey(key), isDense: true),
                ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(convertContentKey(key),
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4.0),
                DynamicTextField(
                  fieldKey: key,
                  initialValue: value?.toString() ?? '',
                  onChanged: (v) {
                    final newContent = copyWithDynamic(content, key, v);
                    onChangedProperties({'content': newContent.toJson()}, item);
                  },
                  onSubmitted: (v) {
                    final newContent = copyWithDynamic(content, key, v);
                    onChangedProperties({'content': newContent.toJson()}, item);
                  },
                  decoration: buildInputDecoration(
                      hintText: convertContentKey(key), isDense: true),
                ),
              ],
            ),
          );
        }
      }).toList(),
    );
  }

  // 필수 속성 확인, 업데이트
  Map<String, dynamic> requiredCheckProperty(
      StackItem item, Map<String, dynamic> json) {
    if (item is StackGridItem && json.containsKey('reqApis')) {
      if (json['reqApis'] != '[]') {
        json = {...json, 'mode': 'select'};
      }
    }

    return json;
  }

  // properties.dart 스타일의 업데이트 함수
  StackItem updateItem(StackItem item, Map<String, dynamic> json) {
    Map<String, dynamic>? newContent = item.content?.toJson();

    if (json.containsKey('content')) {
      json['content'] = requiredCheckProperty(item, json['content']);
      newContent = {...?newContent, ...json['content']};
    }

    // StackItem 직접 속성 추출
    Size? newSize;
    if (json.containsKey('size')) {
      final s = json['size'];
      newSize = Size(
        (s['width'] ?? item.size.width).toDouble(),
        (s['height'] ?? item.size.height).toDouble(),
      );
    }
    Offset? newOffset;
    if (json.containsKey('offset')) {
      final o = json['offset'];
      newOffset = Offset(
        (o['dx'] ?? item.offset.dx).toDouble(),
        (o['dy'] ?? item.offset.dy).toDouble(),
      );
    }
    double? newAngle;
    if (json.containsKey('angle')) {
      newAngle = (json['angle'] ?? item.angle).toDouble();
    }
    String? newPermission;
    if (json.containsKey('permission')) {
      newPermission = json['permission'] as String?;
    }
    String? newTheme;
    if (json.containsKey('theme')) {
      newTheme = json['theme'] as String?;
    }
    bool? newLockZOrder;
    if (json.containsKey('lockZOrder')) {
      newLockZOrder = json['lockZOrder'] as bool?;
    }
    bool? newDock;
    if (json.containsKey('dock')) {
      newDock = json['dock'] as bool?;
    }
    EdgeInsets? newPadding;
    if (json.containsKey('padding')) {
      final p = json['padding'];
      newPadding = EdgeInsets.fromLTRB(
        (p['left'] ?? item.padding.left).toDouble(),
        (p['top'] ?? item.padding.top).toDouble(),
        (p['right'] ?? item.padding.right).toDouble(),
        (p['bottom'] ?? item.padding.bottom).toDouble(),
      );
    }

    final itemUpdated = item.copyWith(
      size: newSize ?? item.size,
      offset: newOffset ?? item.offset,
      angle: newAngle ?? item.angle,
      permission: newPermission ?? item.permission,
      theme: newTheme ?? item.theme,
      lockZOrder: newLockZOrder ?? item.lockZOrder,
      dock: newDock ?? item.dock,
      padding: newPadding ?? item.padding,
      content: getItemContent(item, newContent!),
    );

    return itemUpdated;
  }

  StackItemContent getItemContent(
      StackItem item, Map<String, dynamic> content) {
    if (item is StackTextItem) {
      return TextItemContent.fromJson(content);
    } else if (item is StackImageItem) {
      return ImageItemContent.fromJson(content);
    } else if (item is StackGridItem) {
      return GridItemContent.fromJson(content);
    } else if (item is StackFrameItem) {
      return FrameItemContent.fromJson(content);
      // } else if (item is StackSideMenuItem) {
      //   return SideMenuItemContent.fromJson(content);
    } else if (item is StackTemplateItem) {
      return TemplateItemContent.fromJson(content);
    } else if (item is StackLayoutItem) {
      return LayoutItemContent.fromJson(content);
    } else if (item is StackSearchItem) {
      return SearchItemContent.fromJson(content);
    } else if (item is StackButtonItem) {
      return ButtonItemContent.fromJson(content);
    } else if (item is StackDetailItem) {
      return DetailItemContent.fromJson(content);
    } else if (item is StackChartItem) {
      return ChartItemContent.fromJson(content);
    } else {
      return content as StackItemContent;
    }
  }

  void onChangedProperties(
      Map<String, dynamic> newJson, StackItem currentItem) {
    final updatedItem = updateItem(currentItem, newJson);
    homeRepo.updateStackItemState(updatedItem);
    appStreams.addOnTapState(updatedItem);
  }

  Widget _buildCheckboxListWithTextFieldProperty(
    BuildContext context, {
    required String label,
    required List<Map<String, String>> selectedValues,
    required List<String> allItems,
    required ValueChanged<List<Map<String, String>>> onChanged,
    int? maxHeight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4.0),
          buildStyledCheckboxListWithTextField(
            selectedValues: selectedValues,
            allItems: allItems,
            onChanged: onChanged,
            context: context,
            maxHeight: maxHeight,
          ),
        ],
      ),
    );
  }
}
