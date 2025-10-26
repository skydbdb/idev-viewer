import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:idev_viewer/src/internal/core/api/api_endpoint_ide.dart';
import 'package:idev_viewer/src/internal/core/auth/auth_service.dart';
import 'package:idev_viewer/src/internal/layout/tabs/new_tab.dart';
import 'package:idev_viewer/src/internal/pms/model/menu.dart';
import 'package:pluto_layout/pluto_layout.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert'; // Added for jsonEncode

import '../pms/di/service_locator.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';
import 'package:idev_viewer/src/internal/config/external_bridge.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item.dart';
import 'package:idev_viewer/src/internal/board/core/stack_board_item/stack_item_content.dart';
import '../core/api/api_service.dart';
import '../pms/model/behavior.dart';
import '../pms/model/api_response.dart';
import '../core/error/api_error.dart';
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
  String? get selectedBoardId => _appStreams?.currentSelectDockBoardValue;
  String? get currentTab => _appStreams?.currentChangeTabValue;

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

  ApiService? _apiService;
  AppStreams? _appStreams;

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

  final _tabItem = BehaviorSubject<Menu?>.seeded(null);
  Stream<Menu?> get tabItemStream => _tabItem.stream;
  Menu? get currentTabItemValue => _tabItem.value;
  void addTabItemState(Menu? state) => _tabItem.add(state);

  final _jsonMenu = BehaviorSubject<Map<String, dynamic>?>.seeded(null);
  Stream<Map<String, dynamic>?> get jsonMenuStream => _jsonMenu.stream;
  Map<String, dynamic>? get currentJsonMenuValue => _jsonMenu.value;
  void addJsonMenuState(Map<String, dynamic>? state) {
    debugPrint('📡 [HomeRepo] addJsonMenuState 호출됨');
    debugPrint('📡 [HomeRepo] 전송할 데이터: $state');
    _jsonMenu.add(state);
    debugPrint('📡 [HomeRepo] _jsonMenu.add() 호출 완료');
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
    final timer = Timer(const Duration(milliseconds: 500), () {
      _processingRequests.remove(requestKey);
      _requestTimers.remove(requestKey);
      print('HomeRepo: 요청 키 타임아웃으로 자동 제거: $requestKey');
    });
    _requestTimers[requestKey] = timer;

    print('HomeRepo: API 요청 시작: $requestKey');

    Map<String, dynamic> reqParams = {
      'if_id': apiId,
      'method': method, // api 등록시, 동일 파라미터 덮어쓰기 발생
      'uri': apiId, // api 등록시, 동일 파라미터 덮어쓰기 발생
      'domainId': domainId,
      if (versionId != null) 'versionId': versionId,
      if (templateId != null) 'templateId': templateId,
      if (commitId != null) 'commitId': commitId,
    };

    // params가 있으면 추가하되, method와 uri는 덮어쓰지 않음
    if (params != null) {
      Map<String, dynamic> paramsCopy = Map.from(params);

      // API 수정 요청의 경우 사용자 입력 method, uri를 별도로 보존
      if (apiId.contains('/idev/v1/apis') &&
          (method == 'put' || method == 'post')) {
        // method, uri를 reqParams에 추가하지 않고 별도로 보존
        final userMethod = paramsCopy.remove('method');
        final userUri = paramsCopy.remove('uri');
        // 나중에 bodyData에서 사용할 수 있도록 별도 저장
        paramsCopy['_user_method'] = userMethod;
        paramsCopy['_user_uri'] = userUri;
      } else {
        // 일반 요청의 경우 HTTP 메타데이터 제거
        paramsCopy.remove('method');
        paramsCopy.remove('uri');
      }

      reqParams.addAll(paramsCopy);
    }

    debugPrint('reqIdeApi reqParams: $reqParams');
    _getApiRequest.add(reqParams);
  }

  void addApiIdInjection(String apiId, Map<String, dynamic> params) {
    _getApiIdResponse.add({'if_id': apiId, ...params});
  }

  void addApiRequest(String apiId, Map<String, dynamic> params) {
    final api = apis[apiId];

    Map<String, dynamic> reqParams = Map.from(params);
    reqParams['if_id'] = apiId;
    
    // 뷰어 모드에서 API 메타데이터가 없을 때 기본값 사용
    if (api != null) {
      reqParams['method'] = api['method'];
      reqParams['uri'] = api['uri'];
    } else {
      // 뷰어 모드에서 API 메타데이터가 없을 때 기본값 설정
      reqParams['method'] = 'get'; // 기본값
      reqParams['uri'] = apiId; // API ID를 URI로 사용
      print('HomeRepo: 뷰어 모드 - API 메타데이터 없음, 기본값 사용: $apiId');
    }
    
    reqParams['domainId'] = domainId;

    // reqParams에서 값이 비어있는 항목을 제거 (단, domainId, method, uri는 유지)
    debugPrint('addApiRequest before reqParams: $reqParams');
    reqParams.removeWhere((key, value) =>
        !['domainId', 'method', 'uri'].contains(key) &&
        (value == null || (value is String && value.isEmpty)));
    debugPrint('addApiRequest after reqParams: $reqParams');

    // 중복 요청 방지 - 정리된 파라미터를 사용하여 requestKey 생성
    final cleanedParams = Map<String, dynamic>.from(reqParams);
    cleanedParams.remove('if_id'); // API ID는 requestKey에 이미 포함됨
    cleanedParams.remove('method'); // method는 requestKey에 이미 포함됨
    cleanedParams.remove('uri'); // uri는 requestKey에 이미 포함됨
    cleanedParams.remove('domainId'); // domainId는 requestKey에 포함하지 않음

    final paramsJson = jsonEncode(cleanedParams);
    final requestKey =
        '${reqParams['method']}_${apiId}_${reqParams['versionId']}_${reqParams['templateId']}_${reqParams['commitId']}_$paramsJson';
    if (_processingRequests.contains(requestKey)) {
      print('HomeRepo: 중복 API 요청 방지 (addApiRequest): $requestKey');
      return;
    }
    _processingRequests.add(requestKey);

    //타임아웃 후 요청 키 자동 제거 (사용자 수동 재요청 허용)
    final timer = Timer(const Duration(seconds: 5), () {
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
  //void addTabItemState(Menu? state) => _appStreams?.addTabItemState(state);
  void addTopMenuState(Map<String, dynamic>? state) =>
      _appStreams?.addTopMenuState(state);
  void addWidgetState(String? state) => _appStreams?.addWidgetState(state);
  void addOnTapState(StackItem<StackItemContent>? state) =>
      _appStreams?.addOnTapState(state);
  void updateStackItemState(StackItem item) =>
      _appStreams?.updateStackItemState(item);
  void selectRectState((double, double, double, double)? state) =>
      _appStreams?.selectRectState(state);
  void selectDockBoardState(String? state) {
    if (_appStreams?.currentSelectDockBoardValue == state) return;
    _appStreams?.selectDockBoardState(state);
  }

  void changeTabState(String? state) => _appStreams?.changeTabState(state);
  void addGridColumnMenuState(Map<String, dynamic>? state) =>
      _appStreams?.addGridColumnMenuState(state);
  // End of Wrapper methods

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
    // 뷰어 모드에서는 AppStreams 사용하지 않음
    if (BuildMode.isEditor) {
      _appStreams = sl<AppStreams>();
    }
    _apiService = sl<ApiService>();

    // 전역적으로 리스너는 한 번만 설정
    if (!_globalListenersSetup) {
      if (BuildMode.isEditor) {
        listenerEditor();
      } else {
        listenerViewer();
      }
      _globalListenersSetup = true;
    }

    // 외부 템플릿 스트림 구독 (뷰어 모드 전용)
    _setupExternalTemplateListener();
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

  void listenerViewer() {
    _setupFxRequestListeners();
    _setupApiRequestListeners();
    // 외부(iframe parent 등)에서 주입되는 템플릿 구독
    ExternalBridge.templateStream.listen((template) {
      if (template != null) {
        addJsonMenuState(template);
      }
    });
  }

  void listenerEditor() {
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
    tabItemStream.listen((menu) {
      if (menu != null) {
        eventStreamController?.add(
          PlutoInsertTabItemEvent(
            layoutId: PlutoLayoutId.body,
            itemResolver: ({required items}) =>
                newTabResolver(items: items, menu: menu),
          ),
        );
        final tabMenu = currentTabItemValue;
        eventStreamController?.add(PlutoToggleTabViewEvent(
            layoutId: PlutoLayoutId.body,
            itemId: tabMenu?.menuId == 0
                ? tabMenu?.menuNm
                : 'menu_${tabMenu?.menuId}'));
      }
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
        debugPrint('getApiRequestStream event: $event');
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
    debugPrint('_handleGetApiRequestEvent event: $apiCallParams');

    final String? uri = apiCallParams['uri'] as String?;
    final String? methodString = apiCallParams['method'] as String?;
    final String? ifIdFromParams = apiCallParams['if_id'] as String?;

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

    // body 데이터 준비 (POST/PUT 요청인 경우)
    Map<String, dynamic>? bodyData;
    if (apiMethod == Method.post || apiMethod == Method.put) {
      // POST/PUT 요청인 경우: params를 body로 전송
      bodyData = Map.from(apiCallParams);

      // HTTP 메타데이터 제거 및 사용자 입력값 복원
      if (uri.contains('/idev/v1/apis')) {
        // API 수정 요청의 경우: 사용자 입력 method, uri 복원
        final userMethod = bodyData.remove('_user_method');
        final userUri = bodyData.remove('_user_uri');
        if (userMethod != null) bodyData['method'] = userMethod;
        if (userUri != null) bodyData['uri'] = userUri;

        debugPrint('reqIdeApi $apiMethod bodyData--> $bodyData');
      } else {
        // 일반 요청의 경우: method, uri 제거
        bodyData.remove('method');
        bodyData.remove('uri');
      }

      bodyData.remove('if_id');
      bodyData.remove('domainId');
      bodyData.remove('versionId');

      // templateId는 /template-categories, /template-commits API에서 실제 요청 데이터이므로 제거하지 않음
      if (!uri.contains('/idev/v1/template-categories') &&
          !uri.contains('/idev/v1/template-commits')) {
        bodyData.remove('templateId');
      }

      // commitId는 /template-categories PUT 요청과 /template-commits DELETE 요청에서 실제 요청 데이터이므로 제거하지 않음
      if (!uri.contains('/idev/v1/template-categories') &&
          !uri.contains('/idev/v1/template-commits')) {
        bodyData.remove('commitId');
      }
      bodyData.remove('response_format'); // API 요청 메타데이터 제거
      bodyData.removeWhere((key, value) => value == null);
    } else {
      // GET/DELETE 요청인 경우: params를 query parameter로 전송
      bodyData = Map.from(apiCallParams);

      // HTTP 메타데이터 제거
      bodyData.remove('method');
      bodyData.remove('uri');
      bodyData.remove('if_id');
      bodyData.remove('domainId');
      bodyData.remove('versionId');

      // templateId는 /template-categories, /template-commits API에서 실제 요청 데이터이므로 제거하지 않음
      if (!uri.contains('/idev/v1/template-categories') &&
          !uri.contains('/idev/v1/template-commits')) {
        bodyData.remove('templateId');
      }

      // commitId는 /template-categories PUT 요청과 /template-commits DELETE 요청에서 실제 요청 데이터이므로 제거하지 않음
      if (!uri.contains('/idev/v1/template-categories') &&
          !uri.contains('/idev/v1/template-commits')) {
        bodyData.remove('commitId');
      }
      bodyData.remove('response_format');
      bodyData.removeWhere((key, value) => value == null);

      print('HomeRepo: GET 요청 query parameters = $bodyData');
    }

    try {
      final ApiResponse apiResponse = await _apiService!.requestApi(
        uri: uri,
        method: apiMethod,
        data: bodyData,
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
      // 요청 완료 후 처리 중인 요청 목록에서 제거 - 정리된 파라미터 사용
      final cleanedParams = Map<String, dynamic>.from(apiCallParams);
      cleanedParams.remove('if_id');
      cleanedParams.remove('method');
      cleanedParams.remove('uri');
      cleanedParams.remove('domainId');

      final paramsJson = jsonEncode(cleanedParams);
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

    // 요청 완료 후 처리 중인 요청 목록에서 제거 - 정리된 파라미터 사용
    if (reqParams != null) {
      final cleanedParams = Map<String, dynamic>.from(reqParams);
      cleanedParams.remove('if_id');
      cleanedParams.remove('method');
      cleanedParams.remove('uri');
      cleanedParams.remove('domainId');

      final paramsJson = jsonEncode(cleanedParams);
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
        if (e is Map<String, dynamic>) {
          // apiId 또는 api_id 키 확인
          String? apiId = e['apiId'] ?? e['api_id'];
          if (apiId != null && apiId.isNotEmpty) {
            apis[apiId] = e;
          }
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
      selectedApis[apiId] = {...apis[apiId] ?? {}, 'response': childrenKeys};
    }
  }

  // iframe 통신 관련 메소드들 (기존 뷰어 방식 참고)
  void handleIframeMessage(Map<String, dynamic> data) {
    try {
      switch (data['type']) {
        case 'init_template':
          _handleIframeTemplateInit(data);
          break;
        case 'update_template':
          _handleIframeTemplateUpdate(data);
          break;
        case 'update_config':
          _handleIframeConfigUpdate(data);
          break;
      }
    } catch (e) {
      // 메시지 처리 실패 시 무시
    }
  }

  void _handleIframeInit(Map<String, dynamic> data) {
    try {
      print('🚀 HomeRepo: iframe 초기화 메시지 처리');

      final config = data['config'] ?? {};
      final template = data['template'];

      // API 키 설정
      if (config.containsKey('apiKey')) {
        final apiKey = config['apiKey'] as String?;
        print('🔑 HomeRepo: API 키 설정: ${apiKey?.substring(0, 20)}...');

        ExternalBridge.apiKey = apiKey;
        AuthService.setViewerApiKey(apiKey);

        // 뷰어 인증 초기화
        AuthService.initializeViewerAuth().then((success) {
          if (success) {
            print('✅ HomeRepo: 뷰어 인증 성공');
          } else {
            print('❌ HomeRepo: 뷰어 인증 실패');
          }
        });
      }

      // 초기 템플릿 전달
      if (template != null && template is Map<String, dynamic>) {
        print('📄 HomeRepo: 초기 템플릿 전달');
        ExternalBridge.pushTemplate(Map<String, dynamic>.from(template));
      }

      print('✅ HomeRepo: iframe 초기화 완료');
    } catch (e) {
      print('❌ HomeRepo: iframe 초기화 오류: $e');
    }
  }

  void _handleIframeTemplateInit(Map<String, dynamic> data) {
    try {
      print('🚀 HomeRepo: init_template 메시지 처리 시작');

      final template = data['template'];
      final config = data['config'] ?? {};

      // API 키 설정 (config에서)
      if (config.containsKey('apiKey')) {
        final apiKey = config['apiKey'] as String?;
        print('🔑 HomeRepo: API 키 설정: ${apiKey?.substring(0, 20)}...');

        ExternalBridge.apiKey = apiKey;
        AuthService.setViewerApiKey(apiKey);

        // 뷰어 인증 초기화
        AuthService.initializeViewerAuth().then((success) {
          if (success) {
            print('✅ HomeRepo: 뷰어 인증 성공');
          } else {
            print('❌ HomeRepo: 뷰어 인증 실패');
          }
        });
      }

      // 템플릿 전달 (template에서)
      if (template != null && template is Map<String, dynamic>) {
        print('📄 HomeRepo: 템플릿 전달');
        addJsonMenuState({
          'script': template['script'],
          'templateId': template['templateId'],
          'templateNm': template['templateNm'],
          'commitInfo': template['commitInfo']
        });
      }

      // 기타 설정 업데이트
      if (config.isNotEmpty) {
        _updateIframeConfig(config);
      }

      print('✅ HomeRepo: init_template 처리 완료');
    } catch (e) {
      print('❌ HomeRepo: init_template 처리 실패: $e');
    }
  }

  void _handleIframeTemplateUpdate(Map<String, dynamic> data) {
    try {
      final template = data['template'];

      // AppStreams를 통해 템플릿 업데이트
      final jsonMenuData = {
        'script': template['script'],
        'templateId': template['templateId'],
        'templateNm': template['templateNm'],
        'commitInfo': template['commitInfo']
      };

      addJsonMenuState(jsonMenuData);
      print('✅ HomeRepo: 템플릿 업데이트 성공');
    } catch (e) {
      print('❌ HomeRepo: 템플릿 업데이트 실패: $e');
    }
  }

  void _handleIframeConfigUpdate(Map<String, dynamic> data) {
    try {
      final config = data['config'];
      print('⚙️ HomeRepo: 설정 업데이트 시작 - config: $config');

      _updateIframeConfig(config);

      // README 가이드: API 키 설정 후 인증 상태 업데이트
      if (config != null && config is Map && config.containsKey('apiKey')) {
        final apiKey = config['apiKey'] as String?;
        if (apiKey != null && apiKey.isNotEmpty) {
          print('🔑 HomeRepo: API 키 설정 완료: ${apiKey.substring(0, 20)}...');
          // 인증 상태는 main.dart에서 이미 처리됨
        }
      }

      print('✅ HomeRepo: 설정 업데이트 성공');
    } catch (e) {
      print('❌ HomeRepo: 설정 업데이트 실패: $e');
    }
  }

  // iframe 설정 업데이트
  void _updateIframeConfig(Map<String, dynamic> config) async {
    // 뷰어 인증키 설정
    if (config.containsKey('apiKey')) {
      final apiKey = config['apiKey'] as String?;
      if (apiKey != null) {
        ExternalBridge.apiKey = apiKey;
        AuthService.setViewerApiKey(apiKey);
        print('🔑 HomeRepo: API 키 업데이트: ${apiKey.substring(0, 20)}...');
      }
    }

    // 테마 설정
    if (config.containsKey('theme')) {
      selectedTheme = config['theme'];
      print('🎨 HomeRepo: 테마 설정 변경: $selectedTheme');
    }

    // 로케일 설정
    if (config.containsKey('locale')) {
      // 로케일 설정 로직
    }
  }

  // 외부 템플릿 스트림 구독 (뷰어 모드 전용)
  void _setupExternalTemplateListener() {
    if (BuildMode.isViewer) {
      print('HomeRepo: 외부 템플릿 스트림 구독 시작');
      ExternalBridge.templateStream.listen((template) {
        if (template != null) {
          print('HomeRepo: 외부 템플릿 수신: ${template.toString()}');
          addJsonMenuState(template);
        }
      });
    }
  }
}
