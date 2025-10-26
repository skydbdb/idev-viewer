import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:idev_viewer/src/internal/const/code.dart';
import '../../grid/trina_grid/trina_grid.dart';
import '../../board/stack_board_items/common/new_field.dart';
import '../../repo/home_repo.dart';
import 'popup_grid/popup_grid_launcher.dart';
import 'package:idev_viewer/src/internal/board/stack_board_items/common/models/api_config.dart';
import 'package:idev_viewer/src/internal/board/stack_board_items/common/models/menu_config.dart';
import 'icon_selector.dart';

class PopupGrid {
  PopupGrid({
    required this.context,
    required this.homeRepo,
    required this.properties,
    required this.field,
    this.title,
    this.selectedApis,
    this.frameBoards,
  }) {
    initGrid();
  }

  final BuildContext context;
  final dynamic properties;
  final String field;
  String? title;
  final Map<String, dynamic>? selectedApis;
  final List<String>? frameBoards;
  final List<TrinaColumn> columns = [];
  final List<TrinaRow> rows = [];
  final HomeRepo homeRepo;

  void initGrid() {
    final type = properties['type'];

    if (field == 'tabsTitle') {
      title = '프레임 제목 설정';
      boardPopup();
    } else if (type == 'StackDetailItem' && field == 'resApis') {
      title = '레이아웃 컬럼 설정';
      detailPopup(type);
    } else if (field == 'reqApis') {
      reqApisPopup(type);
    } else if (field == 'resApis') {
      resApisPopup(type);
    } else if (field == 'reqMenus') {
      reqMenusPopup(type);
    }
  }

  String defaultTitle() {
    return switch (field) {
      'reqApis' => '요청 API 설정',
      'resApis' => title ?? '응답 API 설정',
      'reqMenus' => '요청 메뉴 설정',
      _ => title ?? ''
    };
  }

  List<ApiConfig> parseApiConfigs(dynamic setApis) {
    if (setApis == null ||
        setApis.toString().isEmpty ||
        setApis.toString() == '[]') return [];
    if (setApis is String) return apiConfigsFromJsonString(setApis);
    if (setApis is List)
      return setApis
          .map((e) => ApiConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    return [];
  }

  TrinaRow apiConfigToTrinaRow(ApiConfig apiConfig) {
    return TrinaRow(checked: true, cells: {
      'apiId': TrinaCell(value: apiConfig.apiId),
      'field': TrinaCell(value: apiConfig.field ?? ''),
      'type': TrinaCell(value: apiConfig.type ?? ''),
      'fieldNm': TrinaCell(value: apiConfig.fieldNm ?? ''),
      'width': TrinaCell(value: apiConfig.width?.toString() ?? '120'),
      if (properties['type'] == 'StackDetailItem')
        'align': TrinaCell(value: apiConfig.align ?? 'left'),
      'format': TrinaCell(value: apiConfig.format ?? 'default'),
      'enabled': TrinaCell(value: apiConfig.enabled?.toString() ?? 'true'),
      // 'checked': TrinaCell(value: apiConfig.checked?.toString() ?? ''),
    });
  }

  void addApiConfigsToRows(dynamic setApis, List<TrinaRow> rows) {
    final apiConfigs = parseApiConfigs(setApis);

    if (apiConfigs.isNotEmpty) {
      rows.addAll(apiConfigs.map(apiConfigToTrinaRow));
    }
  }

  void detailPopup(type) {
    final setApis = field == 'reqApis'
        ? properties['content']['reqApis']
        : field == 'resApis'
            ? properties['content']['resApis']
            : '';
    List<String> areas = properties['content']['areas'] == null
        ? []
        : properties['content']['areas']
            .toString()
            .trim()
            .replaceAll(RegExp('\n'), '')
            .split(' ')
            .toSet()
            .toList();

    columns
        .addAll(detailColumnSetup(context, type, areas, field, rows, homeRepo));
    addApiConfigsToRows(setApis, rows);

    if (rows.isEmpty && field == 'resApis') {
      for (var e in areas) {
        rows.add(TrinaRow(checked: false, cells: {
          'apiId': TrinaCell(value: ''),
          'field': TrinaCell(value: e),
          'type': TrinaCell(value: FieldType.text.name),
          'fieldNm': TrinaCell(value: e),
          'align': TrinaCell(value: 'left'),
          'format': TrinaCell(value: 'default'),
          'enabled': TrinaCell(value: 'true'),
          // 'checked': TrinaCell(value: ''),
        }));
      }
      selectedApis?.entries.forEach((e) {
        final responseList = e.value['response'];
        if (responseList is List &&
            e.value['apiId'] != '' &&
            e.value['apiId'] != null) {
          rows.addAll([
            ...responseList.map((fld) => TrinaRow(checked: false, cells: {
                  'apiId': TrinaCell(
                      value: '${e.value['apiId']}\n${e.value['apiNm']}'),
                  'field': TrinaCell(value: fld),
                  'type': TrinaCell(value: FieldType.text.name),
                  'fieldNm': TrinaCell(value: areas.first),
                  'align': TrinaCell(value: 'left'),
                  'format': TrinaCell(value: 'default'),
                  'enabled': TrinaCell(value: 'true'),
                  // 'checked': TrinaCell(value: ''),
                }))
          ]);
        }
      });
    }
  }

  void reqApisPopup(type) {
    final setApis = properties['content']['reqApis'];

    columns.addAll(
        gridColumnSetup(context, type, properties, field, rows, homeRepo));
    addApiConfigsToRows(setApis, rows);

    // setApis가 빈 배열/빈 값일 때의 기본 rows 생성
    if (rows.isEmpty) {
      final apiList = homeRepo.hierarchicalControllers.values
          .expand((controller) => controller.innerData)
          .where((item) {
            final contentJson = item.content?.toJson();
            return contentJson != null && contentJson['apiId'] != null;
          })
          .map((item) => item.content!.toJson()['apiId'] as String)
          .where((apiId) => apiId.isNotEmpty) // 빈 문자열 제외
          .toSet() // 중복 제거
          .toList();

      final apis =
          homeRepo.apis.values.where((e) => apiList.contains(e['apiId']));

      for (var e in apis) {
        String safeApiId = e['apiId']?.toString() ?? '';
        String safeApiNm = e['apiNm']?.toString() ?? '';
        String safeWidth = e['width']?.toString() ?? '120';
        List<dynamic> requestList = [];
        if (e['parameters'] != null && e['parameters'] != '') {
          requestList = jsonDecode(e['parameters']);
        }
        rows.addAll([
          ...requestList.map((fld) => TrinaRow(checked: true, cells: {
                'apiId': TrinaCell(value: '$safeApiId\n$safeApiNm'),
                'field': TrinaCell(value: fld['paramKey'] ?? ''),
                'type': TrinaCell(value: FieldType.text.name),
                'fieldNm': TrinaCell(value: fld['paramKey'] ?? ''),
                'width': TrinaCell(value: safeWidth),
                'format': TrinaCell(value: 'default'),
                'enabled': TrinaCell(value: 'true'),
              }))
        ]);
      }
    }
  }

  void resApisPopup(type) {
    final setApis = properties['content']['resApis'];

    columns.addAll(
        gridColumnSetup(context, type, properties, field, rows, homeRepo));
    addApiConfigsToRows(setApis, rows);

    // setApis가 빈 배열/빈 값일 때의 기본 rows 생성
    if (rows.isEmpty) {
      final apiId = properties['content']['apiId'];

      selectedApis?.entries.forEach((e) {
        if ((type == 'StackGridItem' && e.key.toString() == apiId) ||
            type != 'StackGridItem') {
          String safeEntryApiId = e.value['apiId']?.toString() ?? '';
          String safeEntryApiNm = e.value['apiNm']?.toString() ?? '';
          String safeWidth = e.value['width']?.toString() ?? '120';
          final responseList = e.value['response'];
          if (responseList is List) {
            rows.addAll([
              ...responseList.map((fld) => TrinaRow(checked: true, cells: {
                    'apiId':
                        TrinaCell(value: '$safeEntryApiId\n$safeEntryApiNm'),
                    'field': TrinaCell(value: fld),
                    'type': TrinaCell(value: FieldType.text.name),
                    'fieldNm': TrinaCell(value: fld),
                    'width': TrinaCell(value: safeWidth),
                    'format': TrinaCell(value: 'default'),
                    'enabled': TrinaCell(value: 'true'),
                    // 'checked': TrinaCell(value: ''),
                  }))
            ]);
          }
        }
      });
    }
  }

  void boardPopup() {
    final frameTitle = properties['content']['tabsTitle'] ?? '';
    final frameItemId = properties['id'];

    columns.addAll([
      TrinaColumn(
        title: 'BoardId',
        field: 'boardId',
        width: 250,
        readOnly: true,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: 'TabIndex',
        field: 'tabIndex',
        width: 250,
        readOnly: true,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: 'Title',
        field: 'title',
        width: 350,
        type: TrinaColumnType.text(),
      ),
    ]);

    if (frameTitle != '') {
      final List<dynamic> boardJson = jsonDecode(frameTitle!);
      rows.addAll([
        ...boardJson.map((e) {
          final boardId = e['boardId'] as String;
          final tabIndex = e['tabIndex'] as int;
          final title = e['title'] as String;
          return TrinaRow(cells: {
            'boardId': TrinaCell(value: boardId),
            'tabIndex': TrinaCell(value: tabIndex),
            'title': TrinaCell(value: title)
          });
        })
      ]);
    }
  }

  void reqMenusPopup(type) {
    final setMenus = properties['content']['reqMenus'];

    columns.addAll(
        menuColumnSetup(context, type, properties, field, rows, homeRepo));

    addMenuConfigsToRows(setMenus, rows);

    if (rows.isEmpty) {
      final defaultMenus = [
        {'menuId': 'home', 'label': '홈', 'icon': 'home'},
        {'menuId': 'settings', 'label': '설정', 'icon': 'settings'},
        {'menuId': 'profile', 'label': '프로필', 'icon': 'person'},
        {'menuId': 'dashboard', 'label': '대시보드', 'icon': 'dashboard'},
        {'menuId': 'list', 'label': '목록', 'icon': 'list'},
      ];
      for (var menu in defaultMenus) {
        rows.add(TrinaRow(checked: false, cells: {
          'menuId': TrinaCell(value: menu['menuId']),
          'label': TrinaCell(value: menu['label']),
          'icon': TrinaCell(value: menu['icon']),
          'templateId': TrinaCell(value: ''),
          'subTemplateId': TrinaCell(value: ''),
          'script': TrinaCell(value: ''),
          // 'parentId': TrinaCell(value: ''),
          // 'children': TrinaCell(value: '[]'),
        }));
      }
    }
  }

  List<MenuConfig> parseMenuConfigs(dynamic setMenus) {
    if (setMenus == null ||
        setMenus.toString().isEmpty ||
        setMenus.toString() == '[]') {
      return [];
    }
    if (setMenus is String) {
      final result = menuConfigsFromJsonString(setMenus);
      return result;
    }
    if (setMenus is List) {
      final result = setMenus
          .map((e) => MenuConfig.fromJson(e as Map<String, dynamic>))
          .toList();
      return result;
    }
    return [];
  }

  TrinaRow menuConfigToTrinaRow(MenuConfig menuConfig) {
    String iconValue = menuConfig.icon;
    return TrinaRow(checked: true, cells: {
      'menuId': TrinaCell(value: menuConfig.menuId),
      'label': TrinaCell(value: menuConfig.label),
      'icon': TrinaCell(value: iconValue),
      'templateId': TrinaCell(value: menuConfig.templateId ?? ''),
      'subTemplateId': TrinaCell(value: menuConfig.subTemplateId ?? ''),
      'script': TrinaCell(value: menuConfig.script ?? ''),
      // 'parentId': TrinaCell(value: menuConfig.parentId ?? ''),
      // 'children': TrinaCell(value: menuConfig.children?.join(',') ?? ''),
    });
  }

  void addMenuConfigsToRows(dynamic setMenus, List<TrinaRow> rows) {
    final menuConfigs = parseMenuConfigs(setMenus);

    if (menuConfigs.isNotEmpty) {
      rows.addAll(menuConfigs.map(menuConfigToTrinaRow));
    }
  }

  List<TrinaColumn> menuColumnSetup(
      BuildContext context,
      dynamic type,
      dynamic properties,
      String field,
      List<TrinaRow> rows,
      HomeRepo homeRepo) {
    List<TrinaColumn> columns = [];

    columns.addAll([
      TrinaColumn(
        title: '메뉴 ID',
        field: 'menuId',
        width: 150,
        frozen: TrinaColumnFrozen.start,
        enableRowChecked: true,
        enableRowDrag: true,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: '라벨',
        field: 'label',
        width: 150,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: '아이콘',
        field: 'icon',
        width: 200,
        type: TrinaColumnType.text(),
        renderer: (c) {
          return IconSelectorDropdown(
            value: c.cell.value ?? '',
            onChanged: (value) async {
              if (value == 'show_more') {
                // 더보기 선택 시 그리드 다이얼로그 표시
                await showDialog(
                  context: context,
                  builder: (context) => IconGridDialog(
                    initialValue: c.cell.value ?? '',
                    onSelected: (newValue) {
                      c.cell.value = newValue;
                      // 라벨이 비어있으면 아이콘에 맞는 라벨로 자동 설정
                      if (c.row.cells['label']?.value.isEmpty ?? true) {
                        final iconData = icons.firstWhere(
                          (icon) => icon['value'] == newValue,
                          orElse: () => {'label': newValue},
                        );
                        c.row.cells['label']?.value = iconData['label'];
                        c.row.cells['menuId']?.value = newValue;
                      }
                    },
                  ),
                );
              } else {
                // 일반 아이콘 선택 시
                c.cell.value = value;
                // 라벨이 비어있으면 아이콘에 맞는 라벨로 자동 설정
                if (c.row.cells['label']?.value.isEmpty ?? true) {
                  final iconData = icons.firstWhere(
                    (icon) => icon['value'] == value,
                    orElse: () => {'label': value},
                  );
                  c.row.cells['label']?.value = iconData['label'];
                  c.row.cells['menuId']?.value = value;
                }
              }
            },
          );
        },
      ),
      TrinaColumn(
        title: '템플릿 ID',
        field: 'templateId',
        width: 150,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: '서브 템플릿 ID',
        field: 'subTemplateId',
        width: 150,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: '작업 설정',
        field: 'script',
        width: 150,
        type: TrinaColumnType.text(),
      ),
      // TrinaColumn(
      //   title: '부모 ID',
      //   field: 'parentId',
      //   width: 120,
      //   type: TrinaColumnType.text(),
      // ),
      // TrinaColumn(
      //   title: '하위 메뉴',
      //   field: 'children',
      //   width: 200,
      //   type: TrinaColumnType.text(),
      // ),
    ]);

    return columns;
  }

  Future<PopupGridResult?> openGridPopup(BuildContext context) {
    return openPopupGrid(context, defaultTitle(), columns, rows);
  }
}

List<TrinaColumn> fxColumnSetup(BuildContext context) {
  List<TrinaColumn> columns = [];

  columns.addAll([
    TrinaColumn(
      title: 'FxId',
      field: 'fxId',
      width: 150,
      readOnly: true,
      frozen: TrinaColumnFrozen.start,
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: '이름',
      field: 'name',
      width: 130,
      frozen: TrinaColumnFrozen.start,
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: '입력>필드',
      field: 'field',
      width: 130,
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
        title: '출력>연산식',
        field: 'formula',
        width: 200,
        type: TrinaColumnType.text(),
        renderer: (c) {
          return NewField(
              type: FieldType.popup,
              name: 'formula',
              labelText: 'formula',
              initialValue: c.cell.value.toString(),
              format: 'textField',
              widgetName: 'grid',
              callback: (v) {
                c.cell.value = v;
              });
        }),
    TrinaColumn(
      title: '...',
      field: 'menu',
      width: 100,
      type: TrinaColumnType.text(),
      renderer: (c) => menuColumnRenderer(c, context),
    ),
  ]);

  return columns;
}

Widget menuColumnRenderer(TrinaColumnRendererContext c, BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      SizedBox(
        width: 25,
        child: IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            TrinaRow newRow = c.stateManager.getNewRows(count: 1).first;
            c.stateManager.insertRows(c.rowIdx + 1, [newRow]);
            c.stateManager
                .setCurrentSelectingRowsByRange(c.rowIdx, c.rowIdx + 1);
          },
        ),
      ),
      SizedBox(
        width: 25,
        child: IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () {
            c.stateManager.removeRows([c.row]);
          },
        ),
      ),
      SizedBox(
        width: 25,
        child: IconButton(
          icon: const Icon(Icons.save),
          onPressed: () async {
            c.stateManager.setGridMode(TrinaGridMode.select);
            c.stateManager.setGridMode(TrinaGridMode.normal);
            Future.delayed(const Duration(seconds: 1), () {
              final json = {
                ...c.row.toJson(),
                if (c.row.cells['fxId']?.value.isEmpty)
                  'fxId': 'FX-${DateTime.now().millisecondsSinceEpoch}'
              };
              json.remove('menu');
              context.read<HomeRepo>().fxs[json['fxId']] = json;
              c.row.cells['fxId']?.value = json['fxId'];
              c.row.cells['name']?.value = json['name'];
              c.row.cells['field']?.value = json['field'];
              c.stateManager.setShowLoading(true);
              c.stateManager.setPage(1, notify: false);
              c.stateManager.setShowLoading(false);
            });
          },
        ),
      ),
    ],
  );
}

List<TrinaColumn> detailColumnSetup(BuildContext context, dynamic type,
    List<String> areas, String field, List<TrinaRow> rows, HomeRepo homeRepo) {
  final align = ['left', 'center', 'right'];
  final types = FieldType.values.map((e) => e.name).toList();
  final apiTypes = FieldType.values
      .where((e) => e != FieldType.formula)
      .map((e) => e.name)
      .toList();
  List<TrinaColumn> columns = [];

  columns.addAll([
    TrinaColumn(
      title: 'Api/Fx',
      field: 'apiId',
      width: 180,
      readOnly: true,
      frozen: TrinaColumnFrozen.start,
      enableRowChecked: true,
      enableRowDrag: true,
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: '필드',
      field: 'field',
      width: 130,
      readOnly: true,
      frozen: TrinaColumnFrozen.start,
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
        title: '이름',
        field: 'fieldNm',
        type: TrinaColumnType.text(),
        width: 130,
        renderer: (c) {
          final formKey = ValueKey('${c.row.key}-${c.column.field}');
          return SizedBox(
            height: 50,
            child: FormBuilder(
                key: formKey,
                child: FormBuilderDropdown<String>(
                  name: 'fieldNm',
                  initialValue: c.cell.value,
                  elevation: 0,
                  items: areas
                      .map(
                        (v) => DropdownMenuItem(
                          alignment: AlignmentDirectional.centerStart,
                          value: v,
                          child: Text(v),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    final old = rows.firstWhere((e) => e.key == c.row.key);
                    old.cells['fieldNm']?.value = v;
                  },
                )),
          );
        }),
    TrinaColumn(
        title: '타입',
        field: 'type',
        width: 130,
        type: TrinaColumnType.text(),
        renderer: (c) {
          final formKey = ValueKey('${c.row.key}-${c.column.field}');
          return SizedBox(
            height: 50,
            child: FormBuilder(
                key: formKey,
                child: FormBuilderDropdown<String>(
                  name: 'type',
                  initialValue: c.cell.value,
                  elevation: 0,
                  items: ((c.row.cells['apiId']?.value?.contains('FX-') ||
                              c.row.cells['apiId']?.value.isEmpty)
                          ? types
                          : apiTypes)
                      .map(
                        (v) => DropdownMenuItem(
                          alignment: AlignmentDirectional.centerStart,
                          value: v,
                          child: Text(v),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    final old = rows.firstWhere((e) => e.key == c.row.key);
                    old.cells['type']?.value = v;
                    old.cells['format']?.value = typeFormat(
                        FieldType.values.firstWhere((e) => e.name == v)).first;
                    if (v == 'formula' &&
                        !old.cells['apiId']?.value.contains('IF-')) {
                      final fxColumns = fxColumnSetup(context);
                      List<TrinaRow> fxRows = [
                        ...homeRepo.fxs.entries.map((e) => TrinaRow.fromJson({
                              'fxId': e.value['fxId'],
                              'name': e.value['name'],
                              'field': e.value['field'],
                              'formula': e.value['formula'],
                              'menu': '',
                            }))
                      ];
                    } else {
                      if (old.cells['apiId']?.value.contains('FX-')) {
                        old.cells['apiId']?.value = '';
                      }
                    }
                  },
                )),
          );
        }),
    TrinaColumn(
        title: '정렬',
        field: 'align',
        width: 120,
        type: TrinaColumnType.text(),
        renderer: (c) {
          final formKey = ValueKey('${c.row.key}-${c.column.field}');
          return SizedBox(
            height: 50,
            child: FormBuilder(
                key: formKey,
                child: FormBuilderDropdown<String>(
                  name: 'align',
                  initialValue: c.cell.value,
                  elevation: 0,
                  items: align
                      .map(
                        (v) => DropdownMenuItem(
                          alignment: AlignmentDirectional.centerStart,
                          value: v,
                          child: Text(v),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    final old = rows.firstWhere((e) => e.key == c.row.key);
                    old.cells['align']?.value = v;
                  },
                )),
          );
        }),
    TrinaColumn(
        title: '포멧',
        field: 'format',
        width: 100,
        type: TrinaColumnType.text(),
        renderer: (c) {
          final formKey = ValueKey('${c.row.key}-${c.column.field}');
          FieldType type = FieldType.values
              .firstWhere((e) => e.name == c.row.toJson()['type']);
          return SizedBox(
            height: 50,
            child: FormBuilder(
                key: formKey,
                child: FormBuilderDropdown<String>(
                  name: 'format',
                  initialValue: typeFormat(type).contains(c.cell.value)
                      ? c.cell.value
                      : typeFormat(type).first,
                  elevation: 0,
                  items: typeFormat(type)
                      .map(
                        (v) => DropdownMenuItem(
                          alignment: AlignmentDirectional.centerStart,
                          value: v,
                          child: Text(v),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    final old = rows.firstWhere((e) => e.key == c.row.key);
                    old.cells['format']?.value = v;
                  },
                )),
          );
        }),
    TrinaColumn(
        title: '노출',
        field: 'enabled',
        width: 80,
        type: TrinaColumnType.text(),
        renderer: (c) {
          final formKey = ValueKey('${c.row.key}-${c.column.field}');
          return SizedBox(
            height: 50,
            child: FormBuilder(
                key: formKey,
                child: FormBuilderDropdown<String>(
                  name: 'enabled',
                  initialValue: c.cell.value,
                  elevation: 0,
                  items: ['true', 'false']
                      .map(
                        (v) => DropdownMenuItem(
                          alignment: AlignmentDirectional.centerStart,
                          value: v,
                          child: Text(v),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    final old = rows.firstWhere((e) => e.key == c.row.key);
                    old.cells['enabled']?.value = v;
                  },
                )),
          );
        })
  ]);

  return columns;
}

List<TrinaColumn> gridColumnSetup(BuildContext context, dynamic type,
    dynamic properties, String field, List<TrinaRow> rows, HomeRepo homeRepo) {
  final types = FieldType.values.map((e) => e.name).toList();
  final apiTypes = FieldType.values
      .where((e) => e != FieldType.formula)
      .map((e) => e.name)
      .toList();
  List<TrinaColumn> columns = [];

  columns.addAll([
    TrinaColumn(
      title: 'Api/Fx',
      field: 'apiId',
      width: 180,
      readOnly: true,
      frozen: TrinaColumnFrozen.start,
      enableRowChecked: true,
      enableRowDrag: true,
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
      title: '필드',
      field: 'field',
      width: 130,
      readOnly: true,
      frozen: TrinaColumnFrozen.start,
      type: TrinaColumnType.text(),
    ),
    TrinaColumn(
        title: '이름',
        field: 'fieldNm',
        width: 130,
        type: TrinaColumnType.text()),
    if (field == 'resApis' || type == 'StackSearchItem') ...[
      TrinaColumn(
          title: '타입',
          field: 'type',
          width: 130,
          type: TrinaColumnType.select(types),
          renderer: (c) {
            final formKey = ValueKey('${c.row.key}-${c.column.field}');
            return SizedBox(
              height: 50,
              child: FormBuilder(
                  key: formKey,
                  child: FormBuilderDropdown<String>(
                    name: 'type',
                    initialValue: c.cell.value,
                    elevation: 0,
                    items: ((c.row.cells['apiId']?.value?.contains('FX-') ||
                                c.row.cells['apiId']?.value.isEmpty)
                            ? types
                            : apiTypes)
                        .map(
                          (v) => DropdownMenuItem(
                            alignment: AlignmentDirectional.centerStart,
                            value: v,
                            child: Text(v),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      final old = rows.firstWhere((e) => e.key == c.row.key);
                      old.cells['type']?.value = v;
                      old.cells['format']?.value = typeFormat(
                              FieldType.values.firstWhere((e) => e.name == v))
                          .first;
                      if (v == 'formula' &&
                          !old.cells['apiId']?.value.contains('IF-')) {
                        final fxColumns = fxColumnSetup(context);
                        List<TrinaRow> fxRows = [
                          ...homeRepo.fxs.entries.map((e) => TrinaRow.fromJson({
                                'fxId': e.value['fxId'],
                                'name': e.value['name'],
                                'field': e.value['field'],
                                'formula': e.value['formula'],
                                'menu': '',
                              }))
                        ];

                        await openPopupGrid(context, 'Fx 설정', fxColumns, fxRows,
                                mode: TrinaGridMode.selectWithOneTap,
                                autoFitColumn: false,
                                darkMode: true)
                            .then((result) {
                          if (result != null) {
                            if (result.row != null) {
                              String json = jsonEncode(result.row?.toJson());
                              old.cells['apiId']?.value =
                                  result.row?.cells['fxId']?.value;
                            }
                          }
                        });
                      } else {
                        if (old.cells['apiId']?.value.contains('FX-')) {
                          old.cells['apiId']?.value = '';
                        }
                      }
                    },
                  )),
            );
          }),
      TrinaColumn(
        title: '폭',
        field: 'width',
        width: 60,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
          title: '포멧',
          field: 'format',
          width: 100,
          type: TrinaColumnType.text(),
          renderer: (c) {
            final formKey = ValueKey('${c.row.key}-${c.column.field}');
            FieldType type = FieldType.values
                .firstWhere((e) => e.name == c.row.toJson()['type']);
            return SizedBox(
              height: 50,
              child: FormBuilder(
                  key: formKey,
                  child: FormBuilderDropdown<String>(
                    name: 'format',
                    initialValue: typeFormat(type).contains(c.cell.value)
                        ? c.cell.value
                        : typeFormat(type).first,
                    elevation: 0,
                    items: typeFormat(type)
                        .map(
                          (v) => DropdownMenuItem(
                            alignment: AlignmentDirectional.centerStart,
                            value: v,
                            child: Text(v),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      final old = rows.firstWhere((e) => e.key == c.row.key);
                      old.cells['format']?.value = v;
                    },
                  )),
            );
          }),
      TrinaColumn(
          title: '노출',
          field: 'enabled',
          width: 80,
          type: TrinaColumnType.text(),
          renderer: (c) {
            final formKey = ValueKey('${c.row.key}-${c.column.field}');
            return SizedBox(
              height: 50,
              child: FormBuilder(
                  key: formKey,
                  child: FormBuilderDropdown<String>(
                    name: 'enabled',
                    initialValue: c.cell.value,
                    elevation: 0,
                    items: ['true', 'false']
                        .map(
                          (v) => DropdownMenuItem(
                            alignment: AlignmentDirectional.centerStart,
                            value: v,
                            child: Text(v),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      final old = rows.firstWhere((e) => e.key == c.row.key);
                      old.cells['enabled']?.value = v;
                    },
                  )),
            );
          }),
    ]
  ]);

  return columns;
}
