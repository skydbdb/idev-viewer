import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart';
import 'package:idev_viewer/src/internal/core/api/api_endpoint_ide.dart';
import 'package:idev_viewer/src/internal/grid/trina_grid/trina_grid.dart';
import 'package:idev_viewer/src/internal/repo/home_repo.dart';

class ApiPopupDialog {
  final BuildContext context;
  final HomeRepo homeRepo;
  final Function(Map<String, dynamic>)? onApiSaved;
  final Function(String, List<Map<String, dynamic>>)? onApiExecuted;

  // 실시간으로 저장되는 값들
  String _currentMethod = '';
  String _currentUri = '';
  String _currentSqlQuery = '';

  ApiPopupDialog({
    required this.context,
    required this.homeRepo,
    this.onApiSaved,
    this.onApiExecuted,
  });

  List<TrinaColumn> paramColumns = [];
  List<TrinaRow> paramRows = [];
  TrinaGridStateManager? stateManagerParams;

  Future<void> showApiDialog(
      {String? apiId, List<Map<String, dynamic>>? predefinedParams}) async {
    bool isInject = false;
    bool isNew = false;
    final targetRuntimeTypes = homeRepo
        .hierarchicalControllers[homeRepo.selectedBoardId]?.innerDataSelected
        .map((e) => e.runtimeType.toString())
        .toList();
    if (targetRuntimeTypes!.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '위젯이 1개 이상 선택되어 있습니다.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    } else if (targetRuntimeTypes.length == 1 &&
        (targetRuntimeTypes.first == 'StackButtonItem' ||
            targetRuntimeTypes.first == 'StackSchedulerItem')) {
      isInject = true;
      debugPrint('isInject: $isInject');
    }

    Map<String, dynamic>? api = homeRepo.apis[apiId];
    isNew = api == null;
    _initParamColumns();

    final method = ['get', 'post', 'delete', 'put'];
    bool isExecInject = false, isExecApi = false;

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
                        api != null ? 'API 정보' : 'API 등록',
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
                          initialValue: api != null
                              ? api['api_id'] ?? api['apiId']
                              : 'IDEV-TABLE_C',
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
                          initialValue: api != null
                              ? api['api_nm'] ?? api['apiNm']
                              : 'api name',
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
                              api != null ? api['description'] ?? '' : '',
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
                          initialValue: _getMethod(api, method.first),
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
                            _currentMethod = v ?? '';
                          },
                        ),
                      ),
                      SizedBox(
                        width: 400,
                        child: FormBuilderTextField(
                          name: 'URI',
                          initialValue: _getUri(api),
                          decoration: const InputDecoration(
                              labelText: null,
                              contentPadding: EdgeInsets.only(left: 30),
                              prefixText: 'Uri: ',
                              prefixStyle: TextStyle(color: Colors.blue)),
                          textAlignVertical: TextAlignVertical.top,
                          onChanged: (v) {
                            _currentUri = v ?? '';
                          },
                        ),
                      ),
                      SizedBox(
                        height: 310,
                        child: Column(
                          children: [
                            _buildParamList(
                                api: api, predefinedParams: predefinedParams),
                            Expanded(
                              child: FormBuilderTextField(
                                name: 'SQL_QUERY',
                                initialValue: _getSqlQuery(api),
                                maxLines: 10,
                                decoration: const InputDecoration(
                                    labelText: null,
                                    prefixText: 'Sql: ',
                                    prefixStyle: TextStyle(color: Colors.blue)),
                                textAlignVertical: TextAlignVertical.top,
                                onChanged: (v) {
                                  print(
                                      'ApiPopupDialog: SQL_QUERY changed = $v');
                                  _currentSqlQuery = v ?? '';
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
                        if (isInject)
                          InkWell(
                              onTap: () {
                                formKey.currentState?.saveAndValidate();
                                final savedValue =
                                    formKey.currentState?.value ?? {};
                                isExecInject = true;
                                Navigator.pop(context, savedValue);
                              },
                              child: const Row(
                                spacing: 10,
                                children: [Icon(Icons.input), Text('주입')],
                              ))
                        else
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
      if (isExecInject) {
        _injectApi(result);
      } else if (isExecApi) {
        debugPrint('execApi toJson: $toJson');
        _execApi(result['API_ID'], toJson);
      } else {
        debugPrint('saveApi toJson: $toJson');
        _saveApi(isNew, result, toJson, formKey);
      }
    }
  }

  // SQL 쿼리 값을 안전하게 가져오는 헬퍼 메서드
  String _getSqlQuery(Map<String, dynamic>? api) {
    if (api == null) return '';

    // 다양한 가능한 키들을 확인
    String? sqlQuery = api['sql_query'] ??
        api['sqlQuery'] ??
        api['SQL_QUERY'] ??
        api['query'] ??
        api['Query'];

    return sqlQuery ?? '';
  }

  // Method 값을 안전하게 가져오는 헬퍼 메서드
  String _getMethod(Map<String, dynamic>? api, String defaultValue) {
    if (api == null) return defaultValue;

    String? method =
        api['method'] ?? api['METHOD'] ?? api['api_method'] ?? api['apiMethod'];

    if (method == null) return defaultValue;

    return method.toString().toLowerCase();
  }

  // URI 값을 안전하게 가져오는 헬퍼 메서드
  String _getUri(Map<String, dynamic>? api) {
    if (api == null) return '/uri';

    String? uri = api['uri'] ?? api['URI'] ?? api['api_uri'] ?? api['apiUri'];

    return uri ?? '/uri';
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

  Widget _buildParamList(
      {Map<String, dynamic>? api,
      List<Map<String, dynamic>>? predefinedParams}) {
    paramRows.clear();

    // 미리 정의된 파라미터가 있으면 우선 사용
    if (predefinedParams != null && predefinedParams.isNotEmpty) {
      paramRows.addAll([...predefinedParams.map((e) => _paramItem(e))]);
    } else if (api != null && api['parameters'] != null) {
      // API에 정의된 파라미터 사용
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
    debugPrint('validateApi before result: $result');

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

    debugPrint('validateApi after result toJson: $toJson');

    return toJson;
  }

  void _saveApi(bool isNew, Map<String, dynamic> result,
      List<Map<String, dynamic>> toJson, GlobalKey<FormBuilderState>? formKey) {
    debugPrint('saveApi before result: $result');

    String json = jsonEncode(toJson);

    // FormBuilder의 최신 상태에서 값 가져오기
    Map<String, dynamic> createApi = Map.from(result);

    debugPrint('saveApi before createApi: $createApi');

    // FormBuilder의 currentState에서 최신 값 가져오기
    if (formKey?.currentState != null) {
      final formData = formKey!.currentState!.value;

      // METHOD와 URI 값을 최신 값으로 업데이트
      if (formData['API_ID'] != null) {
        createApi['API_ID'] = formData['API_ID'];
      }
      if (formData['API_NM'] != null) {
        createApi['API_NM'] = formData['API_NM'];
      }
      if (formData['METHOD'] != null) {
        createApi['METHOD'] = formData['METHOD'];
      }
      if (formData['URI'] != null) {
        createApi['URI'] = formData['URI'];
      }
      if (formData['SQL_QUERY'] != null) {
        createApi['SQL_QUERY'] = formData['SQL_QUERY'];
      }
      if (formData['DESCRIPTION'] != null) {
        createApi['DESCRIPTION'] = formData['DESCRIPTION'];
      }
    }

    debugPrint('saveApi before createApi 2: $createApi');

    // 실시간 저장된 값들도 확인
    if (_currentMethod.isNotEmpty) {
      createApi['METHOD'] = _currentMethod;
    }
    if (_currentUri.isNotEmpty) {
      createApi['URI'] = _currentUri;
    }
    if (_currentSqlQuery.isNotEmpty) {
      createApi['SQL_QUERY'] = _currentSqlQuery;
    }
    if (result['DESCRIPTION'].toString().trim().isEmpty) {
      createApi = result.map((key, value) {
        if (key == 'DESCRIPTION') {
          return MapEntry(key, '[${result['API_ID']}] ${result['API_NM']}');
        }
        return MapEntry(key, value);
      });
    }

    debugPrint('saveApi before createApi 3: $createApi');

    // addApiRequest 대신 reqIdeApi를 직접 사용하여 method/uri 덮어쓰기 방지
    if (isNew) {
      // API 생성 요청 body 데이터만 추출 (TENANT-API-GUIDE.md 스펙에 맞춤)
      Map<String, dynamic> bodyData = {
        'api_id': createApi['API_ID'],
        'api_nm': createApi['API_NM'],
        'description': createApi['DESCRIPTION'],
        'method': createApi['METHOD'].toString().toUpperCase(),
        'uri': '${createApi['URI']}',
        'sql_query': createApi['SQL_QUERY'],
        'parameters': json,
        'request': '{}',
        'response': '{}',
      };

      debugPrint('saveApi bodyData: $bodyData');

      // reqIdeApi를 직접 사용하여 API 생성 요청
      homeRepo.reqIdeApi('post', ApiEndpointIDE.apis, params: bodyData);

      // API 목록 새로고침 - 생성된 API를 즉시 반영
      Future.delayed(const Duration(milliseconds: 1000), () {
        ApiUtils._initializeApiRequests(homeRepo);
      });
    } else {
      // API 수정 모드 - reqIdeApi 직접 사용하여 덮어쓰기 방지
      // TENANT-API-GUIDE.md 스펙에 맞는 API 수정 요청 body 데이터
      debugPrint('saveApi before parameters toJson: $toJson');
      Map<String, dynamic> bodyData = {
        'api_nm': createApi['API_NM'],
        'description': createApi['DESCRIPTION'],
        'method': createApi['METHOD'].toString().toUpperCase(),
        'uri': createApi['URI'],
        'sql_query': createApi['SQL_QUERY'],
        'parameters': json
      };

      debugPrint('saveApi bodyData: $bodyData');

      // API 수정은 PUT /apis/{apiId} 사용 (TENANT-API-GUIDE.md 스펙 준수)
      String apiId = createApi['API_ID'];
      homeRepo.reqIdeApi('put', '${ApiEndpointIDE.apis}/$apiId',
          params: bodyData);

      // API 목록 새로고침 - 수정된 API를 즉시 반영
      Future.delayed(const Duration(milliseconds: 1000), () {
        ApiUtils._initializeApiRequests(homeRepo);
      });
    }
  }

  void _execApi(String apiId, List<Map<String, dynamic>> apiParams) {
    onApiExecuted == null
        ? ApiUtils.handleApiExecuted(homeRepo, apiId, apiParams)
        : onApiExecuted?.call(apiId, apiParams);
  }

  /// 주입 버튼 클릭 시 동작
  void _injectApi(Map<String, dynamic> savedValue) {
    try {
      // 현재 폼 데이터를 검증하고 저장
      final apiId = savedValue['API_ID'] ?? '';
      final apiName = savedValue['API_NM'] ?? '';
      final description = savedValue['DESCRIPTION'] ?? '';
      final method = savedValue['METHOD'] ?? '';
      final uri = savedValue['URI'] ?? '';
      final sqlQuery = savedValue['SQL_QUERY'] ?? '';
      final targetWidgetIds = homeRepo
          .hierarchicalControllers[homeRepo.selectedBoardId]?.innerDataSelected
          .map((e) => e.id)
          .toList();

      // 주입할 데이터 구성
      Map<String, dynamic> injectData = {
        'targetWidgetIds': targetWidgetIds,
        'apiId': apiId,
        'apiName': apiName,
        'description': description,
        'method': method,
        'uri': uri,
        'sqlQuery': sqlQuery,
        'parameters': _getCurrentParameters(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 주입 액션 실행 (실제 구현은 필요에 따라 수정)
      _performInjection(injectData);

      // 성공 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API 정보가 주입되었습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('주입 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 현재 파라미터 정보를 가져오는 메서드
  List<Map<String, dynamic>> _getCurrentParameters() {
    List<Map<String, dynamic>> parameters = [];

    if (stateManagerParams?.rows.isNotEmpty ?? false) {
      stateManagerParams?.rows.forEach((row) {
        parameters.add(row.toJson());
      });
    }

    return parameters;
  }

  /// 실제 주입을 수행하는 메서드
  void _performInjection(Map<String, dynamic> injectData) {
    debugPrint('주입 데이터: $injectData');
    homeRepo.addApiIdInjection(injectData['apiId'], injectData);
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
        title: 'Description',
        field: 'description',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: 'Description'),
        width: 200,
        readOnly: true,
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
        // 올바른 필드명 사용: apiId → api_id, apiNm → api_nm
        'apiId': TrinaCell(
            value:
                '${eM['api_id'] ?? eM['apiId']}\n${eM['api_nm'] ?? eM['apiNm']}'),
        'method': TrinaCell(value: '${eM['method']}'),
        // description 필드로 변경
        'description': TrinaCell(value: '${eM['description'] ?? ''}'),
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
      'targetWidgetIds': targetWidgetIds ?? [],
      'apiNm': api['apiNm'],
      'request': api['request'],
      'parameters': api['parameters'],
      ...reqParams
    };

    // debugPrint('api param: $params');
    homeRepo.addApiRequest(api['apiId'], params);
  }
}
