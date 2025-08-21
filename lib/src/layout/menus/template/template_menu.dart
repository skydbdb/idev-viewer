import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart';
import 'package:idev_v1/src/board/board/dock_board/board_menu.dart';
import 'package:idev_v1/src/board/board/viewer/template_viewer_page.dart';
import 'package:idev_v1/src/board/stack_board_items/common/new_field.dart';
import 'package:idev_v1/src/core/api/api_endpoint_ide.dart';
import '/src/di/service_locator.dart';
import 'package:idev_v1/src/repo/app_streams.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '/src/grid/trina_grid/trina_grid.dart';
import '/src/repo/home_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class TemplateMenu extends StatefulWidget {
  const TemplateMenu({super.key});

  @override
  State<TemplateMenu> createState() => _TemplateMenuState();
}

class _TemplateMenuState extends State<TemplateMenu> {
  late HomeRepo homeRepo;
  late AppStreams appStreams;
  List<dynamic> templates = [], commits = [], categories = [];
  List<TrinaColumn> columns = [], commitColumns = [];
  List<TrinaRow> rows = [], commitRows = [];
  int? selectedCategoryId;
  TrinaRow? selectedCommitRow;
  TrinaGridStateManager? stateManager, stateManagerCommit;
  ValueKey renderKeyCommit = ValueKey(DateTime.now().millisecondsSinceEpoch);
  final formKey = GlobalKey<FormBuilderState>();
  late StreamSubscription _apiIdResponseSub;
  late StreamSubscription _topMenuSub;

  @override
  void initState() {
    super.initState();
    homeRepo = context.read<HomeRepo>();
    appStreams = sl<AppStreams>();
    _initStateSettings();
    _subscribeStreams();
  }

  void _initStateSettings() {
    _initColumns();
    _initCommitColumns();
    _initCategories();
  }

  void _initCategories() {
    homeRepo.reqIdeApi('get', '${ApiEndpointIDE.categories}/tree',
        params: {'categoryType': 'private'});
  }

  void _initTemplateCategories() {
    if (selectedCategoryId != null) {
      homeRepo.reqIdeApi('get', '${ApiEndpointIDE.templateCategories}/parent',
          params: {'parentId': selectedCategoryId});
    }
  }

  void _subscribeStreams() {
    _subscribeApiIdResponse();
  }

  void _subscribeApiIdResponse() {
    _apiIdResponseSub = homeRepo.getApiIdResponseStream.listen((v) {
      if (v != null) {
        print('_subscribeApiIdResponse: $v');
        _handleApiIdResponse(v);
      }
    });
  }

  void _handleApiIdResponse(dynamic v) async {
    final validApiIds = [
      ApiEndpointIDE.templateCommits,
      '${ApiEndpointIDE.categories}/tree',
      '${ApiEndpointIDE.templateCategories}/parent',
    ];

    if (!validApiIds.contains(v['if_id'])) {
      return;
    }

    dynamic apiResponse = homeRepo.onApiResponse[v['if_id']];
    final type = apiResponse['data']['result'].runtimeType.toString();

    if (v['if_id'] == '${ApiEndpointIDE.templateCategories}/parent') {
      templates = type.contains('JsonMap')
          ? [apiResponse['data']['result']]
          : (apiResponse['data']['result'] as List);

      await loadTemplateList().then((v) {
        setState(() {
          rows.clear();
          rows = v;
        });
      });
    } else if (v['if_id'] == ApiEndpointIDE.templateCommits) {
      commits = type.contains('JsonMap')
          ? [apiResponse['data']['result']]
          : (apiResponse['data']['result'] as List);

      commitRows = await loadCommitList();
      if (!mounted) return;
      setState(() {
        renderKeyCommit = ValueKey(DateTime.now().millisecondsSinceEpoch);
      });
    } else if (v['if_id'] == '${ApiEndpointIDE.categories}/tree') {
      categories = apiResponse['data']['result'] as List;
      categories = categories.map((e) {
        return {
          'categoryId': e['categoryId'],
          'categoryNm': e['categoryNm'],
          'level': e['level'],
          'parentId': e['parentId'],
        };
      }).toList();
      selectedCategoryId =
          categories.where((e) => e['level'] == '1').first['categoryId'];
      if (templates.isEmpty) {
        _initTemplateCategories();
      }
      // print('after categories: $categories');
      // print('selectedCategoryId: $selectedCategoryId');
    }
  }

  @override
  void dispose() {
    _topMenuSub.cancel();
    _apiIdResponseSub.cancel();
    super.dispose();
  }

  Future<void> _initColumns() async {
    columns.addAll([
      TrinaColumn(
        title: '카테고리명',
        field: 'categoryNm',
        enableFilterMenuItem: true,
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '카테고리명'),
        width: 140,
        readOnly: true,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: '템플릿명',
        field: 'templateNm',
        enableFilterMenuItem: true,
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '이름'),
        width: 140,
        readOnly: true,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: '카테고리',
        field: 'categoryId',
        enableFilterMenuItem: true,
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '카테고리'),
        width: 100,
        readOnly: true,
        type: TrinaColumnType.number(), //.text(),
      ),
      TrinaColumn(
        title: '템플릿',
        field: 'templateId',
        enableFilterMenuItem: true,
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '템플릿'),
        width: 100,
        readOnly: true,
        type: TrinaColumnType.number(), //.text(),
      ),
      TrinaColumn(
        title: '커밋',
        field: 'commitId',
        enableFilterMenuItem: true,
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '커밋'),
        width: 100,
        readOnly: true,
        type: TrinaColumnType.number(), //.text(),
      ),
    ]);
  }

  Future<void> _initCommitColumns() async {
    commitColumns = [
      TrinaColumn(
        title: '배포',
        field: 'isDeploy',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '배포'),
        width: 50,
        type: TrinaColumnType.boolean(),
        renderer: (c) {
          return Icon(
            c.cell.value ? Symbols.check_circle : Symbols.cancel,
            color: c.cell.value ? Colors.green.shade600 : Colors.red.shade600,
            size: 20,
          );
        },
      ),
      TrinaColumn(
        title: '커밋',
        field: 'commitId',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '커밋'),
        width: 100,
        type: TrinaColumnType.number(), //.text(),
      ),
      TrinaColumn(
        title: '일자',
        field: 'regDt',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '일자'),
        width: 150,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
        title: '메세지',
        field: 'message',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '메세지'),
        width: 250,
        type: TrinaColumnType.text(),
      ),
      TrinaColumn(
          title: '미리보기',
          field: 'imgUrl',
          filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
              filterHintText: '이미지'),
          width: 100,
          readOnly: true,
          type: TrinaColumnType.text(),
          renderer: (c) {
            if (c.cell.value.isEmpty) return const SizedBox.shrink();
            return NewField(
              type: FieldType.imageUrl,
              name: 'imgUrl',
              labelText: 'imageUrl',
              format: 'showPopup',
              initialValue: c.cell.value,
              widgetName: 'grid',
              homeRepo: homeRepo,
            );
          }),
      TrinaColumn(
        title: '스크립트',
        field: 'script',
        filterWidgetDelegate: const TrinaFilterColumnWidgetDelegate.textField(
            filterHintText: '스크립트'),
        width: 100,
        readOnly: true,
        type: TrinaColumnType.text(),
      ),
    ];
  }

  Future<List<TrinaRow>> loadTemplateList() async {
    if (templates.isEmpty) {
      return [];
    }
    return templates.map((e) => templateItem(e)).toList();
  }

  Future<List<TrinaRow>> loadCommitList() async {
    if (commits.isEmpty) {
      return [];
    }
    return commits.map((e) => commitItem(e)).toList();
  }

  TrinaRow templateItem(Map e) {
    return TrinaRow(cells: {
      'categoryId': TrinaCell(value: e['categoryId']),
      'categoryNm': TrinaCell(value: e['category']?['categoryNm'] ?? ''),
      'templateId': TrinaCell(value: e['templateId']),
      'templateNm': TrinaCell(value: e['template']?['templateNm'] ?? ''),
      'commitId': TrinaCell(value: e['commitId']),
    });
  }

  TrinaRow commitItem(Map e) {
    print('commitItem--> $e');

    return TrinaRow(cells: {
      'isDeploy': TrinaCell(value: false),
      'commitId': TrinaCell(value: e['commitId']),
      'regDt': TrinaCell(
          value: DateFormat('yyyy-MM-dd HH:mm')
              .format(DateTime.parse(e['regDt']))),
      'message': TrinaCell(value: e['message']),
      'imgUrl': TrinaCell(value: e['imgUrl'] ?? ''),
      'script': TrinaCell(value: e['script'] ?? ''),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
            width: double.infinity,
            child: Theme(
                data: ThemeData.dark(),
                child: Column(children: [
                  Container(
                      color: ThemeData.dark().dividerColor,
                      height: 20,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('템플릿'),
                            ],
                          ),
                          Positioned(
                              right: 0,
                              bottom: 0,
                              child: Row(
                                children: [
                                  InkWell(
                                      onTap: () async {
                                        if (categories
                                            .where((e) =>
                                                e['parentId'] ==
                                                selectedCategoryId)
                                            .isNotEmpty) {
                                          await popupTemplateBas();
                                        } else {
                                          EasyLoading.showError(
                                              '하위 카테고리를 먼저 등록해주세요.');
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: Tooltip(
                                            message: '템플릿 등록',
                                            child: Icon(Icons.add, size: 16)),
                                      )),
                                  InkWell(
                                      onTap: () {
                                        _initTemplateCategories();
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.only(right: 12),
                                        child: Tooltip(
                                            message: 'Refresh',
                                            child:
                                                Icon(Icons.refresh, size: 16)),
                                      )),
                                ],
                              )),
                        ],
                      )),
                  Container(
                      color: ThemeData.dark().colorScheme.surface,
                      height: 40,
                      child: FormBuilderDropdown<dynamic>(
                        name: 'categoryId',
                        decoration: const InputDecoration(
                          labelText: null,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        initialValue: selectedCategoryId,
                        items:
                            categories.where((e) => e['level'] == '1').map((e) {
                          return DropdownMenuItem<dynamic>(
                            value: e['categoryId'],
                            child: Text(e['categoryNm']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedCategoryId = value;
                          _initTemplateCategories();
                        },
                      ))
                ]))),
        !mounted
            ? const SizedBox()
            : Expanded(
                child: templateList(),
              )
      ],
    );
  }

  Widget templateList() {
    return Theme(
      data: ThemeData.dark(),
      child: TrinaGrid(
        key: ValueKey(rows.hashCode),
        columns: columns,
        rows: rows,
        mode: TrinaGridMode.selectWithOneTap,
        onSelected: (event) {
          homeRepo.reqIdeApi('get', ApiEndpointIDE.templateCommits,
              versionId: homeRepo.versionId,
              templateId: event.row?.toJson()['templateId']);
          Future.delayed(const Duration(milliseconds: 500), () {
            popupTemplateBas(data: event.row?.toJson());
          });
        },
        onLoaded: (TrinaGridOnLoadedEvent event) {
          stateManager = event.stateManager;
          stateManager?.setShowColumnFilter(true);
          stateManager?.setShowColumnTitle(false);
        },
        configuration: const TrinaGridConfiguration.dark(),
      ),
    );
  }

  Widget commitList(Map<String, dynamic>? data) {
    return SizedBox(
      width: 640,
      height: 380,
      child: Theme(
          data: ThemeData.dark(),
          child: TrinaGrid(
            key: ValueKey(commitRows.hashCode),
            columns: commitColumns,
            rows: commitRows,
            mode: TrinaGridMode.selectWithOneTap,
            onLoaded: (TrinaGridOnLoadedEvent event) {
              stateManagerCommit = event.stateManager;
              stateManagerCommit?.setShowColumnFilter(true);
              stateManagerCommit?.setShowColumnTitle(false);
              if (stateManagerCommit?.rows.isNotEmpty ?? false) {
                selectedCommitRow = stateManagerCommit?.rows.first;
              }
            },
            onSelected: (v) {
              // print('param onSelected: ${v.row?.toJson()['commitId']}');
              selectedCommitRow = v.row;
            },
            rowColorCallback: (c) {
              final row = c.row;
              if (row.cells['commitId']?.value == data?['commitId']) {
                c.row.cells['isDeploy']?.value = true;
              } else {
                c.row.cells['isDeploy']?.value = false;
              }
              return stateManagerCommit?.configuration.style.rowColor ??
                  const TrinaGridConfiguration.dark().style.rowColor;
            },
            configuration: const TrinaGridConfiguration.dark(),
          )),
    );
  }

  Future<void> popupTemplateBas({Map<String, dynamic>? data}) async {
    // print('popupTemplateBas json: $data');
    selectedCommitRow = null;
    bool isExecTemplate = false;
    bool isCommitDeploy = false;
    bool isDelete = false;

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
              width: 680,
              height: data != null ? 600 : 350,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        data != null ? '템플릿 상세' : '템플릿 등록',
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (data != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text('${data['templateId']} : ${data['templateNm']}',
                            style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  const Divider(color: Colors.blue, thickness: 1),
                  Wrap(key: renderKeyCommit, children: [
                    SizedBox(
                      width: 640,
                      child: Column(children: [
                        if (data != null) // 템플릿 상세
                          ...[
                          commitList(data),
                          Row(
                            children: [
                              Expanded(
                                child: FormBuilderTextField(
                                  name: 'message',
                                  initialValue: ' ',
                                  decoration: const InputDecoration(
                                      labelText: null,
                                      prefixText: '커밋 메세지: ',
                                      prefixStyle:
                                          TextStyle(color: Colors.blue)),
                                  textAlignVertical: TextAlignVertical.top,
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: FormBuilderSwitch(
                                  name: 'isDeploy',
                                  title: const Text('배포'),
                                  initialValue: true,
                                  onChanged: (value) {
                                    print('value: $value');
                                  },
                                ),
                              ),
                            ],
                          )
                        ],
                        if (data == null) // 템플릿 등록
                          SizedBox(
                              height: 200,
                              child: Column(children: [
                                // FormBuilderTextField(
                                //   name: 'version_id',
                                //   initialValue: '${homeRepo.versionId}',
                                //   readOnly: true,
                                //   decoration: const InputDecoration(
                                //       labelText: null,
                                //       prefixText: '버젼: ',
                                //       prefixStyle:
                                //           TextStyle(color: Colors.blue)),
                                //   textAlignVertical: TextAlignVertical.top,
                                // ),
                                FormBuilderDropdown<dynamic>(
                                  name: 'categoryId',
                                  decoration: const InputDecoration(
                                    labelText: null,
                                    prefixText: '하위 카테고리: ',
                                    prefixStyle: TextStyle(color: Colors.blue),
                                  ),
                                  initialValue: categories
                                      .where((e) =>
                                          e['parentId'] == selectedCategoryId)
                                      .first['categoryId'],
                                  items: categories
                                      .where((e) =>
                                          e['parentId'] == selectedCategoryId)
                                      .map((e) {
                                    return DropdownMenuItem<dynamic>(
                                      value: e['categoryId'],
                                      child: Text(e['categoryNm']),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    print('value: $value');
                                    // selectedCategoryId = value;
                                  },
                                ),
                                FormBuilderTextField(
                                  name: 'templateNm',
                                  initialValue: ' ',
                                  decoration: const InputDecoration(
                                      labelText: null,
                                      prefixText: '이름: ',
                                      prefixStyle:
                                          TextStyle(color: Colors.blue)),
                                  textAlignVertical: TextAlignVertical.top,
                                ),
                                Expanded(
                                  child: FormBuilderTextField(
                                    name: 'description',
                                    initialValue: ' ',
                                    maxLines: 10,
                                    decoration: const InputDecoration(
                                        labelText: null,
                                        prefixText: '설명: ',
                                        prefixStyle:
                                            TextStyle(color: Colors.blue)),
                                    textAlignVertical: TextAlignVertical.top,
                                  ),
                                ),
                              ]))
                      ]),
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (data != null && commitRows.isNotEmpty)
                          InkWell(
                              onTap: () {
                                formKey.currentState?.saveAndValidate();
                                final savedValue =
                                    formKey.currentState?.value ?? {};
                                isExecTemplate = true;
                                Navigator.pop(context, savedValue);
                              },
                              child: const Row(
                                spacing: 4,
                                children: [Icon(Icons.send), Text('불러오기')],
                              )),
                        if (data != null)
                          InkWell(
                            onTap: () async {
                              final templateId = data['templateId'];
                              final templateNm = data['templateNm'];

                              if (templateId != null) {
                                await launchTemplate(
                                  int.parse(templateId.toString()),
                                  templateNm: templateNm,
                                  versionId: homeRepo.versionId,
                                  script: selectedCommitRow
                                      ?.cells['script']?.value as String?,
                                  commitInfo:
                                      '${selectedCommitRow?.cells['commitId']?.value}: ${selectedCommitRow?.cells['message']?.value}',
                                  context: context,
                                );
                              }
                            },
                            child: const Row(
                              spacing: 4,
                              children: [
                                Icon(Icons.remove_red_eye_outlined),
                                Text('미리보기'),
                              ],
                            ),
                          ),
                        InkWell(
                            onTap: () {
                              formKey.currentState?.saveAndValidate();
                              final savedValue =
                                  formKey.currentState?.value ?? {};
                              Navigator.pop(context, {
                                ...savedValue,
                                if (savedValue['isDeploy'] == true)
                                  'categoryId': data?['categoryId'],
                                'templateId': data?['templateId']
                              });
                            },
                            child: Row(
                              spacing: 4,
                              children: [
                                const Icon(Icons.save),
                                Text(data != null ? '커밋 저장' : '템플릿 저장')
                              ],
                            )),
                        if (data != null && commitRows.isNotEmpty)
                          InkWell(
                              onTap: () {
                                isCommitDeploy = true;
                                Navigator.pop(context, {
                                  'versionId': homeRepo.versionId,
                                  'categoryId': data['categoryId'],
                                  'templateId': data['templateId'],
                                  'commitId': selectedCommitRow
                                      ?.cells['commitId']!.value,
                                });
                              },
                              child: const Row(
                                spacing: 4,
                                children: [
                                  Icon(Symbols.cloud_upload),
                                  Text('커밋 배포')
                                ],
                              )),
                        if (data != null)
                          InkWell(
                              onTap: () {
                                isDelete = true;
                                Navigator.pop(context, {
                                  'versionId': homeRepo.versionId,
                                  'categoryId': data['categoryId'],
                                  'templateId': data['templateId'],
                                  'commitId': selectedCommitRow
                                      ?.cells['commitId']!.value,
                                });
                              },
                              child: Row(
                                spacing: 4,
                                children: [
                                  const Icon(Icons.delete),
                                  Text(commitRows.isEmpty ? '템플릿 삭제' : '커밋 삭제')
                                ],
                              )),
                        InkWell(
                            onTap: () {
                              Navigator.pop(context, null);
                            },
                            child: const Row(
                              spacing: 4,
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
      offset: const Offset(-300, 0),
      alignment: Alignment.centerRight,
      useSafeArea: true,
      dimBackground: true,
    );

    print('result: $result');

    if (data == null) {
      await _createTemplateCategory(result!); // 신규 템플릿 등록
    } else if (isExecTemplate && selectedCommitRow != null) {
      execTemplate(
          templateId: data['templateId'],
          templateNm: data['templateNm'],
          commitData: selectedCommitRow?.toJson());
    } else if (isCommitDeploy && selectedCommitRow != null) {
      // 커밋 배포
      await _deployCommit(result!);
    } else if (result != null) {
      if (!isDelete) {
        // 저장버튼 유효성 체크
        List<Map<String, dynamic>> toJson = homeRepo
                .hierarchicalControllers[homeRepo.currentTab]
                ?.getAllData() ??
            [];
        if (toJson.isEmpty) {
          EasyLoading.showInfo('위젯이 존재하지 않습니다.',
              duration: const Duration(seconds: 1));
          return;
        }
        if (result['message'].toString().trim().isEmpty) {
          EasyLoading.showInfo('메세지: 입력 필수입니다.',
              duration: const Duration(seconds: 1));
          return;
        }
      }
      if (commitRows.isNotEmpty && selectedCommitRow == null && isDelete) {
        EasyLoading.showInfo('삭제 대상[커밋]이 선택되지 않았습니다.',
            duration: const Duration(seconds: 1));
        return;
      }

      String deleteTarget = (isDelete && commitRows.isEmpty)
          ? 'template'
          : (isDelete && commitRows.isNotEmpty)
              ? 'commit'
              : '';

      await _handleTemplateUpdate(result, deleteTarget);
    }
  }

  /// 카테고리 템플릿 생성 처리
  Future<void> _createTemplateCategory(
      Map<String, dynamic> templateData) async {
    try {
      // 1) 템플릿 최초 생성
      homeRepo.reqIdeApi('post', ApiEndpointIDE.templates,
          params: templateData);

      // getApiIdResponseStream을 통해 응답 대기
      await homeRepo.getApiIdResponseStream
          .where((response) => response != null)
          .firstWhere(
              (response) => response['if_id'] == ApiEndpointIDE.templates);

      // onApiResponse에서 실제 데이터 가져오기
      final apiResponse = homeRepo.onApiResponse[ApiEndpointIDE.templates];
      if (apiResponse == null) {
        throw Exception('API 응답을 찾을 수 없습니다.');
      }

      final responseData = apiResponse['data'];
      final resultData = responseData['result'];
      final newTemplateId =
          resultData != null ? resultData['templateId'] : null;

      if (newTemplateId == null) {
        throw Exception('템플릿 ID가 응답에 포함되지 않았습니다.');
      }

      // 2) 카테고리 등록
      homeRepo.reqIdeApi('post', ApiEndpointIDE.templateCategories, params: {
        'categoryId': templateData['categoryId'],
        'templateId': newTemplateId,
        'notes': templateData['templateNm'],
      });
    } catch (e) {
      print('템플릿 생성 중 오류 발생: $e');
    }
  }

  /// 템플릿 커밋을 현재 템플릿 카테고리로 배포
  Future<void> _deployCommit(Map<String, dynamic> templateData) async {
    try {
      homeRepo.reqIdeApi('put',
          '${ApiEndpointIDE.templateCategories}/${templateData['templateId']}/${templateData['categoryId']}',
          params: {
            'commitId': templateData['commitId'],
          });
    } catch (e) {
      print('커밋 배포 오류 발생: $e');
    }
  }

  /// 템플릿 업데이트 또는 삭제를 처리하는 메서드
  Future<void> _handleTemplateUpdate(
      Map<String, dynamic> result, String deleteTarget) async {
    try {
      String jsonString = await BoardMenu(context: context, homeRepo: homeRepo)
          .getTemplateJson();

      final params = {
        'script': jsonString,
        ...result,
      };

      if (deleteTarget == 'commit') {
        homeRepo.reqIdeApi('delete', ApiEndpointIDE.templateCommits,
            params: params);
      } else if (deleteTarget == 'template') {
        homeRepo.reqIdeApi('delete', ApiEndpointIDE.templates, params: params);
      } else {
        homeRepo.reqIdeApi('post', ApiEndpointIDE.templateCommits,
            params: params);
      }

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('템플릿 업데이트 오류 발생: $e');
    }
  }

  void execTemplate(
      {dynamic templateId,
      String? templateNm,
      Map<String, dynamic>? commitData}) {
    homeRepo.addJsonMenuState({
      'templateId': int.parse(templateId.toString()),
      'templateNm': templateNm,
      'versionId': homeRepo.versionId,
      'script': commitData?['script'],
      'commitInfo': '${commitData?['commitId']}: ${commitData?['message']}',
    });
  }
}

/// Function to launch template in new window
Future<void> launchTemplate(
  int templateId, {
  String? templateNm,
  int? versionId,
  String? script,
  String? commitInfo,
  BuildContext? context,
}) async {
  if (context != null) {
    // 현재 창에서 다이얼로그로 표시
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Stack(
              children: [
                TemplateViewerPage(
                  templateId: templateId,
                  templateNm: templateNm,
                  script: script,
                  commitInfo: commitInfo,
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  } else if (kIsWeb) {
    // 웹 환경에서는 URL 파라미터로 데이터 전달
    final baseUrl = Uri.base.toString();

    // URL 파라미터로 데이터 전달
    final queryParams = <String, String>{};

    if (templateNm != null && templateNm.isNotEmpty) {
      queryParams['templateNm'] = templateNm;
    }
    if (versionId != null) {
      queryParams['versionId'] = versionId.toString();
    }
    if (script != null && script.isNotEmpty) {
      // 스크립트가 너무 길면 URL 파라미터로 전달하기 어려우므로
      // base64 인코딩을 사용합니다
      queryParams['script'] = base64Encode(utf8.encode(script));
    }
    if (commitInfo != null && commitInfo.isNotEmpty) {
      queryParams['commitInfo'] = commitInfo;
    }

    // URL 생성 - 더 명확한 방식으로
    final templateUrl = '$baseUrl#/template/$templateId';

    // URL에 쿼리 파라미터 추가
    String finalUrl = templateUrl;
    if (queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      finalUrl = '$templateUrl?$queryString';
    }

    try {
      final uri = Uri.parse(finalUrl);
      final canLaunch = await url_launcher.canLaunchUrl(uri);

      if (canLaunch) {
        await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      // 에러 처리
    }
  }
}
