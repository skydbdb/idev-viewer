import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:idev_v1/src/core/api/api_endpoint_ide.dart';
import 'package:idev_v1/src/core/auth/auth_service.dart';
import 'package:idev_v1/src/layout/tabs/new_tab.dart';
import '/src/model/menu.dart';
import 'package:pluto_layout/pluto_layout.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert'; // Added for jsonEncode

import '/src/di/service_locator.dart';
import '/src/board/core/stack_board_item/stack_item.dart';
import '/src/board/core/stack_board_item/stack_item_content.dart';
import '../core/api/api_service.dart';
import '/src/core/api/model/behavior.dart';
import '/src/core/api/model/api_response.dart';
import '/src/core/error/api_error.dart';
import 'app_streams.dart';
import '../board/board/hierarchical_dock_board_controller.dart';
import '../board/core/stack_board_controller.dart';

class HomeRepo {
  String? userId;
  int? domainId;
  int? versionId;
  String? get token => AuthService.token;

  Map<String, dynamic> apis = {};
  Map<String, dynamic> fxs = {};
  Map<String, dynamic> fxsColumn = {}; //key: fxId+field, value: []
  Map<String, dynamic> params = {};
  Map<String, dynamic> selectedApis = {};
  Map<String, GlobalKey<FormBuilderState>> formKey = {};
  dynamic currentProperties = {};
  String selectedTheme = "White";
  String? get selectedBoardId => _appStreams.currentSelectDockBoardValue;
  Menu? get currentLeftMenu => _appStreams.currentLeftMenuValue;
  String? get currentTab => _appStreams.currentChangeTabValue;

  // 개선된 계층 구조 관리 변수들
  Map<String, HierarchicalDockBoardController> hierarchicalControllers = {};

  // 부모-자식 관계를 명확히 추적하는 변수들
  Map<String, String?> parentChildRelations = {}; // childId -> parentId
  Map<String, List<String>> childParentRelations =
      {}; // parentId -> [childId1, childId2, ...]
  Set<String> rootControllers = {}; // 최상위 컨트롤러들의 ID
  Set<String> registeredChildIds = {}; // 등록된 자식 ID들을 추적하는 Set

  // 컨트롤러 생성 순서 추적 (부모가 먼저 생성되어야 함)
  List<String> controllerCreationOrder = [];

  // Frame의 tab 순서 정보 저장
  Map<String, Map<String, int>> frameTabOrders = {};

  PlutoLayoutEventStreamController? eventStreamController;
  Map<String, dynamic> tabs = {};

  Map<String, Map<String, dynamic>> onApiResponse = {};

  late ApiService _apiService;
  late AppStreams _appStreams;

  final StreamController<(String, Map<String, dynamic>)> _requestController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _responseController =
      StreamController.broadcast();
  Stream<Map<String, dynamic>> get responseStream => _responseController.stream;
  Stream<(String, Map<String, dynamic>)> get requestStream =>
      _requestController.stream;
  void addRequest((String, Map<String, dynamic>) requestData) =>
      _requestController.add(requestData);
  void addResponse(Map<String, dynamic> responseData) =>
      _responseController.add(responseData);

  Stream<Map<String, dynamic>> requestWithResponse(
      String apiId, Map<String, dynamic> params) {
    addRequest((apiId, params));
    return responseStream;
  }

  final _getApiRequest = BehaviorSubject<Map<String, dynamic>?>.seeded(null);
  final _getApiIdResponse = BehaviorSubject<dynamic>.seeded(null);
  final _rowRequest = BehaviorSubject<Map<String, dynamic>?>.seeded(null);
  final _rowResponse = BehaviorSubject<Map<String, dynamic>?>.seeded(null);

  Stream<Map<String, dynamic>?> get getApiRequestStream =>
      _getApiRequest.stream;
  Stream<dynamic> get getApiIdResponseStream => _getApiIdResponse.stream;
  Stream<Map<String, dynamic>?> get rowRequestStream => _rowRequest.stream;
  Stream<Map<String, dynamic>?> get rowResponseStream => _rowResponse.stream;

  final Set<String> _processingRequests = {}; // 처리 중인 요청 추적
  final Map<String, Timer> _requestTimers = {}; // 요청별 타임아웃 타이머

  void reqIdeApi(String method, String apiId,
      {int? versionId,
      int? templateId,
      int? commitId,
      Map<String, dynamic>? params}) {
    // 중복 요청 방지 - 파라미터 JSON 값도 포함
    final paramsJson = params != null ? jsonEncode(params) : '';
    final requestKey =
        '${method}_${apiId}_${versionId}_${templateId}_${commitId}_$paramsJson';
    if (_processingRequests.contains(requestKey)) {
      print('HomeRepo: 중복 API 요청 방지: $requestKey');
      return;
    }
    _processingRequests.add(requestKey);

    // 타임아웃 후 요청 키 자동 제거 (사용자 수동 재요청 허용)
    final timer = Timer(const Duration(milliseconds: 100), () {
      _processingRequests.remove(requestKey);
      _requestTimers.remove(requestKey);
      print('HomeRepo: 요청 키 타임아웃으로 자동 제거: $requestKey');
    });
    _requestTimers[requestKey] = timer;

    print('HomeRepo: API 요청 시작: $requestKey');

    Map<String, dynamic> reqParams = {
      'if_id': apiId,
      'method': method,
      'uri': apiId,
      'domainId': domainId,
      if (versionId != null) 'versionId': versionId,
      if (templateId != null) 'templateId': templateId,
      if (commitId != null) 'commitId': commitId,
      ...params ?? {},
    };
    _getApiRequest.add(reqParams);
  }

  void addApiRequest(String apiId, Map<String, dynamic> params) {
    final api = apis[apiId];
    Map<String, dynamic> reqParams = Map.from(params);
    reqParams['if_id'] = apiId;
    reqParams['method'] = api['method'];
    reqParams['uri'] = api['uri'];
    reqParams['domainId'] = domainId;

    // 중복 요청 방지 - 파라미터 JSON 값도 포함
    final paramsJson = jsonEncode(params);
    final requestKey =
        '${api['method']}_${apiId}_${reqParams['versionId']}_${reqParams['templateId']}_${reqParams['commitId']}_$paramsJson';
    if (_processingRequests.contains(requestKey)) {
      print('HomeRepo: 중복 API 요청 방지 (addApiRequest): $requestKey');
      return;
    }
    _processingRequests.add(requestKey);

    //타임아웃 후 요청 키 자동 제거 (사용자 수동 재요청 허용)
    final timer = Timer(const Duration(milliseconds: 100), () {
      _processingRequests.remove(requestKey);
      _requestTimers.remove(requestKey);
      print('HomeRepo: 요청 키 타임아웃으로 자동 제거 (addApiRequest): $requestKey');
    });
    _requestTimers[requestKey] = timer;

    print('HomeRepo: API 요청 시작 (addApiRequest): $requestKey');

    _getApiRequest.add(reqParams);
  }

  void addRowRequestState(Map<String, dynamic> params) =>
      _rowRequest.add(params);
  void addRowResponseState(Map<String, dynamic> params) =>
      _rowResponse.add(params);

  // Wrapper methods for AppStreams
  void addTabItemState(Menu? state) => _appStreams.addTabItemState(state);
  void addTopMenuState(Map<String, dynamic>? state) =>
      _appStreams.addTopMenuState(state);
  void addLeftMenuState(Menu? state) => _appStreams.addLeftMenuState(state);
  void addRightMenuState(String? state) => _appStreams.addRightMenuState(state);
  void addJsonMenuState(Map<String, dynamic>? state) =>
      _appStreams.addJsonMenuState(state);
  void addSearchApisState(List<String>? state) =>
      _appStreams.addSearchApisState(state);
  void addApiMenuState(Map<String, dynamic>? state) =>
      _appStreams.addApiMenuState(state);
  void addOnTapState(StackItem<StackItemContent>? state) =>
      _appStreams.addOnTapState(state);
  void addOnEditState(StackItem<StackItemContent>? state) =>
      _appStreams.addOnEditState(state);
  void updateStackItemState(StackItem item) =>
      _appStreams.updateStackItemState(item);

  void selectRectState((double, double, double, double)? state) =>
      _appStreams.selectRectState(state);
  void selectDockBoardState(String? state) {
    if (_appStreams.currentSelectDockBoardValue == state) return; // 중복 방지
    _appStreams.selectDockBoardState(state);
  }

  void changeTabState(String? state) => _appStreams.changeTabState(state);
  void dockStackItemState(StackItem<StackItemContent>? state) =>
      _appStreams.dockStackItemState(state);
  void addGridColumnMenuState(Map<String, dynamic>? state) =>
      _appStreams.addGridColumnMenuState(state);
  // End of Wrapper methods

  final Map<String, StreamController<Map<String, dynamic>>> _topicControllers =
      {};

  Stream<Map<String, dynamic>> subscribe(String topic) {
    _topicControllers.putIfAbsent(topic, () => StreamController.broadcast());
    return _topicControllers[topic]!.stream;
  }

  void addChildController(String parentId, String childId) {
    // 자기 자신을 자식으로 추가하려는 경우 방지
    if (parentId == childId) {
      return;
    }

    final parent = hierarchicalControllers[parentId];
    final child = hierarchicalControllers[childId];
    if (parent != null && child != null) {
      // 동일한 객체 참조인지 확인 (실제 중복만 방지)
      if (parent.children.contains(child)) {
        return;
      }

      // parentChildRelations에서도 중복 확인
      final existingParentId = parentChildRelations[childId];
      if (existingParentId == parentId) {
        return;
      }

      // 순환 호출 방지를 위해 직접 children 리스트에 추가
      parent.children.add(child);

      // childParentRelations 업데이트 (중복 방지)
      final existingChildren = childParentRelations[parentId];
      if (existingChildren == null || !existingChildren.contains(childId)) {
        childParentRelations.putIfAbsent(parentId, () => []).add(childId);
      }
      parentChildRelations[childId] = parentId;
    }
  }

  // 새로운 계층 구조 관리 메서드들
  bool createHierarchicalController(String id, String? parentId) {
    // 이미 존재하는 컨트롤러인지 확인
    final existed = hierarchicalControllers.containsKey(id);
    if (existed) {
      debugPrint(
          '[HomeRepo.createHierarchicalController] SKIP existed id=$id parentId=$parentId');
      return false;
    }

    // 부모 컨트롤러 존재 여부 검증
    if (parentId != null && !hierarchicalControllers.containsKey(parentId)) {
      return false;
    }

    // 컨트롤러 생성
    debugPrint(
        '[HomeRepo.createHierarchicalController] CREATE id=$id parentId=$parentId');
    final controller = HierarchicalDockBoardController(
      id: id,
      parentId: parentId,
      controller: StackBoardController(
        boardId: id,
      ),
    );

    hierarchicalControllers[id] = controller;
    controllerCreationOrder.add(id);

    // 부모-자식 관계 설정
    if (parentId != null) {
      parentChildRelations[id] = parentId;
      childParentRelations.putIfAbsent(parentId, () => []).add(id);

      // 부모 컨트롤러에 자식 추가
      final parentController = hierarchicalControllers[parentId];
      if (parentController != null) {
        parentController.addChild(controller);
        debugPrint(
            '[HomeRepo.createHierarchicalController] addChild parent=$parentId child=$id');
      }
    } else {
      // 최상위 컨트롤러로 등록
      rootControllers.add(id);
      parentChildRelations[id] = null;
      debugPrint('[HomeRepo.createHierarchicalController] root add id=$id');
    }

    return true;
  }

  bool removeHierarchicalController(String id) {
    final controller = hierarchicalControllers[id];
    if (controller == null) {
      return false;
    }

    // 모든 자식 컨트롤러들도 함께 제거
    final childrenToRemove = controller.getAllChildren();
    for (final child in childrenToRemove) {
      _removeControllerFromHierarchy(child.id);
    }

    // 현재 컨트롤러 제거
    _removeControllerFromHierarchy(id);

    return true;
  }

  void _removeControllerFromHierarchy(String id) {
    final parentId = parentChildRelations[id];

    // 부모에서 자식 제거
    if (parentId != null) {
      childParentRelations[parentId]?.remove(id);
      if (childParentRelations[parentId]?.isEmpty == true) {
        childParentRelations.remove(parentId);
      }

      final parentController = hierarchicalControllers[parentId];
      final childController = hierarchicalControllers[id];
      if (parentController != null && childController != null) {
        parentController.removeChild(childController);
      }
    } else {
      rootControllers.remove(id);
    }

    // 관계 정보 제거
    parentChildRelations.remove(id);
    hierarchicalControllers.remove(id);
    controllerCreationOrder.remove(id);
  }

  bool isParentController(String id) {
    return childParentRelations.containsKey(id);
  }

  bool isChildController(String id) {
    return parentChildRelations.containsKey(id);
  }

  bool isRootController(String id) {
    return rootControllers.contains(id);
  }

  String? getParentId(String childId) {
    return parentChildRelations[childId];
  }

  List<String> getChildIds(String parentId) {
    return childParentRelations[parentId] ?? [];
  }

  List<String> getAllDescendantIds(String parentId) {
    List<String> descendants = [];
    final children = getChildIds(parentId);

    for (final childId in children) {
      descendants.add(childId);
      descendants.addAll(getAllDescendantIds(childId));
    }

    return descendants;
  }

  // 모든 컨트롤러 초기화 (디버깅용)
  void clearAllControllers() {
    hierarchicalControllers.clear();
    parentChildRelations.clear();
    childParentRelations.clear();
    rootControllers.clear();
    controllerCreationOrder.clear();
  }

  // 아이템 ID 컨트롤러 정리 (잘못 생성된 컨트롤러 제거)
  void cleanupItemControllers() {
    final controllersToRemove = <String>[];

    for (final entry in hierarchicalControllers.entries) {
      final controllerId = entry.key;

      // 아이템 ID 패턴 확인 (Layout_1, Frame_1 등)
      if (controllerId.contains('_Layout_') ||
          (controllerId.contains('_Frame_') &&
              !controllerId.contains('_Frame_1_') &&
              !controllerId.contains('_Frame_2_'))) {
        controllersToRemove.add(controllerId);
      }
    }

    for (final controllerId in controllersToRemove) {
      removeHierarchicalController(controllerId);
    }
  }

  // 중복 탭 컨트롤러 정리 (새로운 규칙: 프레임.id_tabIndex)
  void cleanupDuplicateTabControllers() {
    final controllersToRemove = <String>[];
    final frameControllers = <String>[];

    // 모든 프레임 관련 컨트롤러 수집
    for (final entry in hierarchicalControllers.entries) {
      final controllerId = entry.key;
      if (controllerId.contains('Frame_') && controllerId.contains('_')) {
        frameControllers.add(controllerId);
      }
    }

    // 해시 기반 컨트롤러 식별 (tab_로 시작하는 해시 기반 ID)
    for (final controllerId in frameControllers) {
      if (controllerId.startsWith('Frame_') && controllerId.length > 8) {
        // tab_로 시작하는 해시 기반 ID
        final controller = hierarchicalControllers[controllerId];
        if (controller != null) {
          final itemCount = controller.controller.innerData.length;

          // 아이템이 없는 컨트롤러만 제거
          if (itemCount == 0) {
            controllersToRemove.add(controllerId);
          }
        }
      }
    }

    for (final controllerId in controllersToRemove) {
      removeHierarchicalController(controllerId);
    }
  }

  HierarchicalDockBoardController? getHierarchicalController(String id) {
    return hierarchicalControllers[id];
  }

  void disposeHierarchicalController(String id) {
    if (!hierarchicalControllers.containsKey(id)) {
      return;
    }
    removeHierarchicalController(id);
  }

  static bool _globalListenersSetup = false; // 전역 리스너 설정 상태

  HomeRepo() {
    _appStreams = sl<AppStreams>();
    _apiService = sl<ApiService>();

    // 전역적으로 리스너는 한 번만 설정
    if (!_globalListenersSetup) {
      listener();
      _globalListenersSetup = true;
    }
  }

  void dispose() {
    // 모든 타이머 정리
    for (final timer in _requestTimers.values) {
      timer.cancel();
    }
    _requestTimers.clear();
    _processingRequests.clear();
    print('HomeRepo: 모든 타이머와 요청 상태 정리 완료');
  }

  void listener() {
    _initializeFxs();
    _setupUiEventListeners();
    _setupFxRequestListeners();
    _setupApiRequestListeners();
  }

  void _initializeFxs() {
    List.generate(
        2,
        (index) => fxs['FX-$index'] = {
              'fxId': 'FX-$index',
              'name': 'name-$index',
              'field': 'field3, field4',
              'formula': index == 0 ? 'field3+field4' : 'field3*field4'
            });
  }

  void _setupUiEventListeners() {
    _appStreams.tabItemStream.listen((menu) {
      if (menu != null) {
        eventStreamController?.add(
          PlutoInsertTabItemEvent(
            layoutId: PlutoLayoutId.body,
            itemResolver: ({required items}) =>
                newTabResolver(items: items, menu: menu),
          ),
        );
        final tabMenu = _appStreams.currentTabItemValue;
        eventStreamController?.add(PlutoToggleTabViewEvent(
            layoutId: PlutoLayoutId.body,
            itemId: tabMenu?.menuId == 0
                ? tabMenu?.menuNm
                : 'menu_${tabMenu?.menuId}'));
      }
    });

    _appStreams.leftMenuStream.listen((menu) {
      if (menu != null) {}
    });
  }

  void _setupFxRequestListeners() {
    rowRequestStream.listen((params) {
      if (params != null) {
        addRowResponseState(params);
      }
    });
  }

  Map<String, dynamic> lastRequestEvent = {};
  bool _apiRequestListenersSetup = false; // API 요청 리스너 설정 상태

  void _setupApiRequestListeners() {
    // 중복 설정 방지
    if (_apiRequestListenersSetup) {
      print('HomeRepo: API 요청 리스너가 이미 설정되어 있음');
      return;
    }
    _apiRequestListenersSetup = true;

    print('HomeRepo: API 요청 리스너 설정 시작');

    getApiRequestStream.listen((event) {
      if (event != null && lastRequestEvent.toString() != event.toString()) {
        lastRequestEvent = event;
        _handleGetApiRequestEvent(event);
      }
    });
  }

  Future<void> _handleGetApiRequestEvent(
      Map<String, dynamic>? apiCallParams) async {
    if (apiCallParams == null) {
      return;
    }

    final String? uri = apiCallParams['uri'] as String?;
    final String? methodString = apiCallParams['method'] as String?;
    final String? ifIdFromParams = apiCallParams['if_id'] as String?;
    Map<String, dynamic> payloadData = Map.from(apiCallParams);

    if (uri == null || methodString == null) {
      return;
    }
    Method? apiMethod;
    try {
      apiMethod = Method.values.firstWhere(
          (e) => e.name.toLowerCase() == methodString.toLowerCase());
    } catch (e) {
      return;
    }

    payloadData.removeWhere((key, value) => value == null);

    try {
      final ApiResponse apiResponse = await _apiService.requestApi(
        uri: uri,
        method: apiMethod,
        data: payloadData,
        ifId: ifIdFromParams,
      );

      _processSuccessfulApiResponse({
        'if_id': ifIdFromParams,
        'reqParams': apiCallParams,
        'data': apiResponse.data
      });
    } catch (e) {
      String reason = (e is ApiError) ? e.message : e.toString();
      dynamic errorData = (e is ApiError) ? e.data : null;
      processFailedApiResponse(
          ifIdFromParams, apiCallParams, reason, errorData);
    } finally {
      // 요청 완료 후 처리 중인 요청 목록에서 제거 - 파라미터 JSON 값도 포함
      final paramsJson = jsonEncode(apiCallParams);
      final requestKey =
          '${methodString}_${ifIdFromParams}_${apiCallParams['versionId']}_${apiCallParams['templateId']}_${apiCallParams['commitId']}_$paramsJson';

      // 기존 타이머 취소
      final timer = _requestTimers[requestKey];
      if (timer != null) {
        timer.cancel();
        _requestTimers.remove(requestKey);
      }

      _processingRequests.remove(requestKey);
    }
  }

  void _processSuccessfulApiResponse(Map<String, dynamic> successData) {
    final apiId = successData['if_id']?.toString();
    final reqParams = successData['reqParams'] as Map<String, dynamic>?;

    print('HomeRepo: API 응답 처리 시작 apiId = $apiId');

    if (apiId == null || apiId.isEmpty) {
      print('HomeRepo: apiId가 null이므로 처리 중단');
      return;
    }

    if (apiId == ApiEndpointIDE.apis) {
      initApis(successData['data']['result']);
    } else if (apiId == ApiEndpointIDE.params) {
      initParams(successData['data']['result']);
    }

    printResponseLog(successData['data']);
    onApiResponse[apiId] = successData;
    updateSelectedApisFromResponse(apiId, successData['data']);

    // 요청 완료 후 처리 중인 요청 목록에서 제거 - 파라미터 JSON 값도 포함
    if (reqParams != null) {
      final paramsJson = jsonEncode(reqParams);
      final requestKey =
          '${reqParams['method']}_${reqParams['if_id']}_${reqParams['versionId']}_${reqParams['templateId']}_${reqParams['commitId']}_$paramsJson';

      // 기존 타이머 취소
      final timer = _requestTimers[requestKey];
      if (timer != null) {
        timer.cancel();
        _requestTimers.remove(requestKey);
      }

      _processingRequests.remove(requestKey);
      print('HomeRepo: 요청 완료, 처리 중 목록에서 제거: $requestKey');
    }

    if (reqParams != null) {
      _getApiIdResponse.add(reqParams);
    } else {
      _getApiIdResponse
          .add({'if_id': apiId, 'status': 'success_no_req_params'});
    }
  }

  void initApis(dynamic dataList) {
    if (dataList is List && dataList.isNotEmpty) {
      apis.clear();
      for (var e in dataList) {
        if (e is Map<String, dynamic> &&
            e.containsKey('apiId') &&
            e['apiId'] != null &&
            e['apiId'].isNotEmpty) {
          apis[e['apiId'].toString()] = e;
        }
      }
    }
  }

  void initParams(dynamic dataList) {
    if (dataList is List) {
      if (dataList.isNotEmpty &&
          dataList.first is Map &&
          dataList.first['json_tree'] != null) {
        final jsonTree = dataList.first['json_tree'];
        if (jsonTree is Map && jsonTree['result'] is List) {
          final List<dynamic> paramBas = jsonTree['result'];
          final Map<String, dynamic> resultCode = {};
          final Map<String, dynamic> rootCode = {};
          for (var e in paramBas) {
            if (e['level'] == 0) {
              if (e['params'] != null) {
                for (var c in e['params']) {
                  rootCode[c['paramId'].toString()] = c['paramKey'];
                }
              }
            }
            if (e['level'] == 1) {
              if (e['params'] != null) {
                for (var c in e['params']) {
                  final paramKey = c['paramKey'];
                  final paramValue = c['paramValue'];
                  resultCode[
                      '${rootCode[c['parentId'].toString()]}/$paramKey'] = {
                    'paramKey':
                        '${rootCode[c['parentId'].toString()]}/$paramKey',
                    'paramValue': paramValue
                  };
                }
              }
            }
            if (e['level'] == 2) {
              final Map<String, dynamic> children = {};
              if (e['params'] != null) {
                for (var c in e['params']) {
                  children[c['paramKey'].toString()] = c['paramValue'];
                }
              }
              resultCode[
                  '${rootCode[e['parentId'].toString()]}/${e['paramKey']}'] = {
                'paramKey':
                    '${rootCode[e['parentId'].toString()]}/${e['paramKey']}',
                'paramValue': e['paramValue'],
                'children': children
              };
            }
          }
          params = resultCode;
        }
      }
    }
  }

  void printResponseLog(dynamic responsePayload) {
    // 응답 데이터 건 수만 출력
    if (responsePayload != null && responsePayload is Map<String, dynamic>) {
      if (responsePayload.containsKey('result')) {
        final result = responsePayload['result'];
        if (result is List) {
          print('HomeRepo: 응답 데이터 건 수 = ${result.length}건');
        } else if (result is Map<String, dynamic>) {
          print('HomeRepo: 응답 데이터 = 단일 객체');
        } else {
          print('HomeRepo: 응답 데이터 = ${result.runtimeType}');
        }
      } else {
        print('HomeRepo: 응답 데이터 = ${responsePayload.keys.join(', ')}');
      }
    }
  }

  void processFailedApiResponse(String? ifId, Map<String, dynamic>? reqParams,
      String reason, dynamic errorData) {
    print('HomeRepo: API 요청 실패 - ifId: $ifId, reason: $reason');

    // 실패한 요청도 처리 중인 요청 목록에서 제거 - 파라미터 JSON 값도 포함
    if (reqParams != null) {
      final paramsJson = jsonEncode(reqParams);
      final requestKey =
          '${reqParams['method']}_${reqParams['if_id']}_${reqParams['versionId']}_${reqParams['templateId']}_${reqParams['commitId']}_$paramsJson';

      // 기존 타이머 취소
      final timer = _requestTimers[requestKey];
      if (timer != null) {
        timer.cancel();
        _requestTimers.remove(requestKey);
      }

      _processingRequests.remove(requestKey);
      print('HomeRepo: 요청 실패, 처리 중 목록에서 제거: $requestKey');
    }

    final responseData = {
      'result': '-1',
      'reason': reason,
      'error_details': errorData
    };
    if (ifId != null && ifId.isNotEmpty) {
      onApiResponse[ifId] = {
        'if_id': ifId,
        'reqParams': reqParams,
        'data': responseData
      };
    }
    _getApiIdResponse
        .add({'if_id': ifId, 'reqParams': reqParams, 'error': responseData});
  }

  void updateSelectedApisFromResponse(String apiId, dynamic responsePayload) {
    if (responsePayload == null) return;

    final Map<String, dynamic> dataToParse;
    if (responsePayload is Map<String, dynamic>) {
      dataToParse = responsePayload;
    } else if (responsePayload is Map) {
      dataToParse = Map<String, dynamic>.from(responsePayload);
    } else {
      return;
    }

    final actualDataPayload = dataToParse['payload'] ?? dataToParse;

    if (actualDataPayload != null && actualDataPayload is Map) {
      List<String> childrenKeys = [];
      if (actualDataPayload['result'] is List &&
          (actualDataPayload['result'] as List).isNotEmpty) {
        final firstItem = (actualDataPayload['result'] as List).first;
        if (firstItem is Map) {
          childrenKeys = List<String>.from(firstItem.keys);
        }
      } else if (actualDataPayload['result'] is Map) {
        childrenKeys =
            List<String>.from((actualDataPayload['result'] as Map).keys);
      } else {
        childrenKeys = List<String>.from(actualDataPayload.keys);
      }
      selectedApis[apiId] = {
        ...selectedApis[apiId] ?? {},
        'response': childrenKeys
      };
    }
  }
}
