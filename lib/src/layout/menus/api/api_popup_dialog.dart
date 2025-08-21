import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart';
import 'package:idev_v1/src/core/api/api_endpoint_ide.dart';
import '/src/grid/trina_grid/trina_grid.dart';
import '/src/repo/home_repo.dart';
import '/src/core/auth/auth_service.dart';

class ApiPopupDialog {
  final BuildContext context;
  final HomeRepo homeRepo;
  final Function(Map<String, dynamic>)? onApiSaved;
  final Function(String, List<Map<String, dynamic>>)? onApiExecuted;

  ApiPopupDialog({
    required this.context,
    required this.homeRepo,
    this.onApiSaved,
    this.onApiExecuted,
  });

  List<TrinaColumn> paramColumns = [];
  List<TrinaRow> paramRows = [];
  TrinaGridStateManager? stateManagerParams;

  Future<void> showApiDialog({String? apiId}) async {
    Map<String, dynamic>? api = homeRepo.apis[apiId];
    _initParamColumns();

    final method = ['get', 'post', 'delete', 'put'];
    bool isExecApi = false;

    // 내부에서 formKey 생성
    final formKey = GlobalKey<FormBuilderState>();

    final result = await showPopupCard<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        return FormBuilder(
          key: formKey,
          child: PopupCard(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: SizedBox(
              width: 640,
              height: 600,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        api != null ? 'API 업데이트' : 'API 등록',
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.blue, thickness: 1),
                  Wrap(
                    children: [
                      SizedBox(
                        width: 200,
                        child: FormBuilderTextField(
                          name: 'API_ID',
                          initialValue:
                              api != null ? api['apiId'] : 'IDEV-TABLE_C',
                          decoration: const InputDecoration(
                              labelText: null,
                              prefixText: 'Id: ',
                              prefixStyle: TextStyle(color: Colors.blue)),
                          textAlignVertical: TextAlignVertical.top,
                          onChanged: (v) {
                            // debugPrint('v-->$v');
                          },
                        ),
                      ),
                      SizedBox(
                        width: 400,
                        child: FormBuilderTextField(
                          name: 'API_NM',
                          initialValue: api != null ? api['apiNm'] : 'api name',
                          decoration: const InputDecoration(
                              labelText: null,
                              contentPadding: EdgeInsets.only(left: 30),
                              prefixText: 'Name: ',
                              prefixStyle: TextStyle(color: Colors.blue)),
                          textAlignVertical: TextAlignVertical.top,
                          onChanged: (v) {
                            // debugPrint('v-->$v');
                          },
                        ),
                      ),
                      SizedBox(
                        width: 600,
                        child: FormBuilderTextField(
                          name: 'DESCRIPTION',
                          initialValue:
                              api != null ? api['description'] ?? ' ' : ' ',
                          decoration: const InputDecoration(
                              labelText: null,
                              prefixText: 'Description: ',
                              prefixStyle: TextStyle(color: Colors.blue)),
                          textAlignVertical: TextAlignVertical.top,
                          onChanged: (v) {
                            // debugPrint('v-->$v');
                          },
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: FormBuilderDropdown<String>(
                          name: 'METHOD',
                          initialValue: api != null
                              ? api['method'].toString().toLowerCase()
                              : method.first,
                          decoration: const InputDecoration(
                              labelText: null,
                              prefixText: 'Method: ',
                              prefixStyle: TextStyle(color: Colors.blue)),
                          items: method
                              .map((v) => DropdownMenuItem<String>(
                                    alignment: AlignmentDirectional.centerStart,
                                    value: v,
                                    child: Text(v),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            // debugPrint('v-->$v');
                          },
                        ),
                      ),
                      SizedBox(
                        width: 400,
                        child: FormBuilderTextField(
                          name: 'URI',
                          initialValue: api != null ? api['uri'] : '/uri',
                          decoration: const InputDecoration(
                              labelText: null,
                              contentPadding: EdgeInsets.only(left: 30),
                              prefixText: 'Uri: ',
                              prefixStyle: TextStyle(color: Colors.blue)),
                          textAlignVertical: TextAlignVertical.top,
                          onChanged: (v) {
                            // debugPrint('v-->$v');
                          },
                        ),
                      ),
                      SizedBox(
                        height: 310,
                        child: Column(
                          children: [
                            _buildParamList(api: api),
                            Expanded(
                              child: FormBuilderTextField(
                                name: 'SQL_QUERY',
                                initialValue:
                                    api != null ? api['sql_query'] ?? ' ' : ' ',
                                maxLines: 10,
                                decoration: const InputDecoration(
                                    labelText: null,
                                    prefixText: 'Sql: ',
                                    prefixStyle: TextStyle(color: Colors.blue)),
                                textAlignVertical: TextAlignVertical.top,
                                onChanged: (v) {
                                  // debugPrint('v-->$v');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                            onTap: () {
                              formKey.currentState?.saveAndValidate();
                              final savedValue =
                                  formKey.currentState?.value ?? {};
                              isExecApi = true;
                              Navigator.pop(context, savedValue);
                            },
                            child: const Row(
                              spacing: 10,
                              children: [Icon(Icons.send), Text('실행')],
                            )),
                        InkWell(
                            onTap: () {
                              formKey.currentState?.saveAndValidate();
                              final savedValue =
                                  formKey.currentState?.value ?? {};
                              Navigator.pop(context, savedValue);
                            },
                            child: const Row(
                              spacing: 10,
                              children: [Icon(Icons.save), Text('확인')],
                            )),
                        InkWell(
                            onTap: () {
                              Navigator.pop(context, null);
                            },
                            child: const Row(
                              spacing: 10,
                              children: [Icon(Icons.cancel), Text('닫기')],
                            )),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
      alignment: Alignment.center,
      useSafeArea: true,
      dimBackground: true,
    );

    if (result != null) {
      List<Map<String, dynamic>> toJson = _validateApi(result);
      if (isExecApi) {
        _execApi(result['API_ID'], toJson);
      } else {
        _saveApi(result, toJson);
      }
    }
  }

  void _initParamColumns() {
    paramColumns = [
      TrinaColumn(
        title: 'Parameter Name',
        field: 'paramKey',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '파라메터'),
        width: 150,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
          title: 'Required',
          field: 'isRequired',
          filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
              filterHintText: '필수'),
          width: 100,
          type: TrinaColumnType.text(),
          renderer: (c) {
            return FormBuilder(
              child: FormBuilderDropdown(
                name: 'required',
                initialValue: c.cell.value,
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.only(top: 0, bottom: 8),
                    border: InputBorder.none),
                elevation: 0,
                items: ['true', 'false']
                    .map((v) => DropdownMenuItem(
                          alignment: AlignmentDirectional.centerStart,
                          value: v,
                          child: Text(v),
                        ))
                    .toList(),
                onChanged: (v) {
                  stateManagerParams?.changeCellValue(c.cell, v, force: true);
                },
              ),
            );
          }),
      TrinaColumn(
          title: 'Type',
          field: 'type',
          filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
              filterHintText: '타입'),
          width: 100,
          readOnly: true,
          type: TrinaColumnType.text(),
          renderer: (c) {
            return FormBuilder(
              child: FormBuilderDropdown(
                name: 'type',
                initialValue: c.cell.value,
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.only(top: 0, bottom: 8),
                    border: InputBorder.none),
                elevation: 0,
                items: ['string', 'integer', 'json']
                    .map((v) => DropdownMenuItem(
                          alignment: AlignmentDirectional.centerStart,
                          value: v,
                          child: Text(v),
                        ))
                    .toList(),
                onChanged: (v) {
                  stateManagerParams?.changeCellValue(c.cell, v, force: true);
                },
              ),
            );
          }),
      TrinaColumn(
        title: 'Description',
        filterWidgetDelegate: TrinaFilterColumnWidgetDelegate.textField(
          filterHintText: '설명',
          filterSuffixIcon: Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('실행값 / 설명'),
                Row(
                  children: [
                    InkWell(
                        onTap: () {
                          _addRowParam();
                        },
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.grey,
                        )),
                    InkWell(
                        onTap: () {
                          _removeRowParam();
                        },
                        child: const Icon(
                          Icons.remove,
                          size: 16,
                          color: Colors.grey,
                        )),
                  ],
                ),
              ],
            ),
          ),
        ),
        field: 'description',
        width: 250,
        type: TrinaColumnType.text(),
      ),
    ];
  }

  void _addRowParam() {
    int rowIdx = stateManagerParams!.rows.length;
    stateManagerParams?.insertRows(rowIdx, [_paramItem({}, isNew: true)]);
    stateManagerParams?.setCurrentSelectingRowsByRange(rowIdx, rowIdx);
  }

  void _removeRowParam() {
    final currentRow = stateManagerParams?.currentRow;
    if (currentRow != null) {
      stateManagerParams?.removeCurrentRow();
    }
  }

  TrinaRow _paramItem(Map eM, {bool isNew = false}) {
    return isNew
        ? TrinaRow(
            cells: {
              'paramKey': TrinaCell(value: ''),
              'isRequired': TrinaCell(value: 'false'),
              'type': TrinaCell(value: 'string'),
              'description': TrinaCell(value: ''),
            },
          )
        : TrinaRow(
            cells: {
              'paramKey': TrinaCell(value: eM['paramKey']),
              'isRequired': TrinaCell(value: eM['isRequired']),
              'type': TrinaCell(value: eM['type']),
              'description': TrinaCell(value: eM['description']),
            },
          );
  }

  Widget _buildParamList({Map<String, dynamic>? api}) {
    paramRows.clear();
    if (api != null && api['parameters'] != null) {
      List<dynamic> parameters =
          api['parameters'] != '' ? jsonDecode(api['parameters']) : {};
      paramRows.addAll([...parameters.map((e) => _paramItem(e))]);
    }

    return SizedBox(
      width: 600,
      height: 150,
      child: Theme(
          data: ThemeData.dark(),
          child: TrinaGrid(
            columns: paramColumns,
            rows: paramRows,
            mode: TrinaGridMode.normal,
            onLoaded: (TrinaGridOnLoadedEvent event) {
              stateManagerParams = event.stateManager;
              stateManagerParams?.setShowColumnFilter(true);
              stateManagerParams?.setShowColumnTitle(false);
            },
            onChanged: (v) {
              // debugPrint('param onChanged: ${v.row.toJson()}');
            },
            configuration: const TrinaGridConfiguration.dark(),
          )),
    );
  }

  List<Map<String, dynamic>> _validateApi(Map<String, dynamic> result) {
    List<Map<String, dynamic>> toJson = [];
    final regex = RegExp(r':(\w+)');
    final paramKeys = regex
        .allMatches(result['SQL_QUERY'])
        .map((e) => e.group(1))
        .toSet()
        .toList();

    if (stateManagerParams?.rows.isNotEmpty ?? false) {
      stateManagerParams?.rows.forEach((row) {
        final inParams = ['get', 'delete'].contains(result['METHOD'])
            ? {'in': 'query'}
            : {'in': 'body'};
        toJson = [
          ...toJson,
          {...row.toJson(), ...inParams}
        ];
      });
    } else if (result['SQL_QUERY'] != null &&
        result['SQL_QUERY'].toString().contains(':')) {
      for (final paramKey in paramKeys) {
        final inParams = ['get', 'delete'].contains(result['METHOD'])
            ? {'in': 'query'}
            : {'in': 'body'};
        toJson.addAll([
          {
            'paramKey': paramKey,
            'type': 'string',
            'isRequired': 'false',
            'description': '',
            ...inParams
          }
        ]);
      }
    }

    return toJson;
  }

  void _saveApi(
      Map<String, dynamic> result, List<Map<String, dynamic>> toJson) {
    String json = jsonEncode(toJson);
    Map<String, dynamic> createApi = result;
    if (result['DESCRIPTION'].toString().trim().isEmpty) {
      createApi = result.map((key, value) {
        if (key == 'DESCRIPTION') {
          return MapEntry(key, '[${result['API_ID']}] ${result['API_NM']}');
        }
        return MapEntry(key, value);
      });
    }

    const String apiId = 'IDEV-API_C';
    final api = homeRepo.apis[apiId];
    Map<String, dynamic> params = {
      'if_id': api['apiId'],
      'method': api['method'],
      'uri': api['uri'],
      'token': AuthService.token,
      'PARAMETERS': json,
      ...createApi
    };

    onApiSaved == null
        ? ApiUtils.handleApiSaved(homeRepo, params)
        : onApiSaved?.call(params);
  }

  void _execApi(String apiId, List<Map<String, dynamic>> apiParams) {
    onApiExecuted == null
        ? ApiUtils.handleApiExecuted(homeRepo, apiId, apiParams)
        : onApiExecuted?.call(apiId, apiParams);
  }
}

// API 관련 유틸리티 클래스들
class ApiUtils {
  static List<TrinaColumn> getApiColumns() {
    return [
      TrinaColumn(
        title: 'API',
        field: 'apiId',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: 'API'),
        width: 200,
        readOnly: true,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: 'Method',
        field: 'method',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: 'Method'),
        width: 100,
        readOnly: true,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: 'Required',
        field: 'required',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: 'Required'),
        width: 100,
        readOnly: true,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: 'Request',
        field: 'request',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: 'Request'),
        width: 200,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: 'Uri',
        field: 'uri',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: 'URI'),
        width: 200,
        readOnly: true,
        type: TrinaColumnType.text(),
      ),
    ];
  }

  static TrinaRow createApiRow(Map eM) {
    return TrinaRow(
      cells: {
        'apiId': TrinaCell(value: '${eM['apiId']}\n${eM['apiNm']}'),
        'method': TrinaCell(value: '${eM['method']}'),
        'required': TrinaCell(value: '${eM['required']}'),
        'request': TrinaCell(value: '${eM['request']}'),
        'uri': TrinaCell(value: '${eM['uri']}'),
      },
    );
  }

  static List<TrinaRow> createApiRows(Map<String, dynamic> apis) {
    return apis.values.map((e) => createApiRow(e)).toList();
  }

  static void handleApiSaved(HomeRepo homeRepo, Map<String, dynamic> params,
      {VoidCallback? onRefresh}) {
    homeRepo.addApiRequest(params['if_id'], params);
    homeRepo.getApiIdResponseStream
        .where((response) => response != null)
        .firstWhere((response) => response['if_id'] == params['if_id'])
        .then((response) {
      Future.delayed(const Duration(milliseconds: 500), () {
        onRefresh == null ? _initializeApiRequests(homeRepo) : onRefresh.call();
      });
    });
  }

  static void _initializeApiRequests(HomeRepo homeRepo) {
    // homeRepo.addApiRequest({
    //   'method': 'get',
    //   'uri': '/apis',
    //   'if_id': 'apis',
    // });
    homeRepo.reqIdeApi('get', ApiEndpointIDE.apis);
  }

  static void handleApiExecuted(
      HomeRepo homeRepo, String apiId, List<Map<String, dynamic>> apiParams) {
    Map<String, dynamic> reqParams = {};
    for (var e in apiParams) {
      if (e['description'] != null && e['description'].toString().isNotEmpty) {
        reqParams.addAll({e['paramKey']: e['description']});
      }
    }

    final api = homeRepo.apis[apiId];
    final targetWidgetIds = homeRepo
        .hierarchicalControllers[homeRepo.selectedBoardId]?.innerDataSelected
        .map((e) => e.id)
        .toList();

    Map<String, dynamic> params = {
      // 'boardId': homeRepo.selectedBoardId,
      'targetWidgetIds': targetWidgetIds ?? [],
      // 'if_id': api['apiId'],
      // 'method': api['method'],
      // 'uri': api['uri'],
      'apiNm': api['apiNm'],
      'request': api['request'],
      // 'token': AuthService.token,
      'parameters': api['parameters'],
      ...reqParams
    };

    // debugPrint('api param: $params');
    // homeRepo.addApiMenuState(params);
    homeRepo.addApiRequest(api['apiId'], params);
  }
}
