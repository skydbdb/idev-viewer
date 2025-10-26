import 'package:dio/dio.dart'; // Options를 위해 필요할 수 있음
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';

import '../error/api_error.dart';
import '../../pms/model/api_response.dart'; // ApiResponse 모델
import '../../pms/model/behavior.dart'; // Method enum 사용
import '../auth/auth_service.dart'; // AuthService import 추가
import '../../util/network_utils.dart'; // NetworkUtils import 추가
import 'api_client.dart';
import 'package:idev_viewer/src/internal/config/build_mode.dart';

class ApiService {
  final ApiClient _apiClient;

  // GetIt을 통해 ApiClient 주입받거나, 직접 생성하여 주입 가능
  ApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? sl<ApiClient>();

  Future<ApiResponse> requestApi({
    required String uri, // API의 path 부분 (예: /univ/login)
    required Method method,
    Map<String, dynamic>?
        data, // POST, PUT, PATCH 등의 body. GET, DELETE에서는 queryParams로 사용될 수 있음.
    Map<String, String>? headers, // 추가적인 헤더
    String? ifId, // URL 구성 시 사용될 수 있음
  }) async {
    // AuthService 초기화 보장
    await AuthService.ensureInitialized();

    // 네트워크 연결 상태 확인
    final isConnected = await NetworkUtils.isInternetConnected();
    if (!isConnected) {
      print('ApiService: 네트워크 연결 없음');
      return ApiResponse(
          result: -1,
          reason: '네트워크 연결을 확인해주세요.',
          data: {'network_status': 'disconnected'});
    }

    Options? dioOptions;
    Map<String, dynamic> headerMap = {};

    // 1. 기본 Content-Type 헤더 설정
    headerMap['Content-Type'] = 'application/json;charset=utf-8';

    // 2. 추가 헤더가 있으면 병합
    if (headers != null) {
      headerMap.addAll(headers);
    }

    // 3. 토큰 우선순위 설정
    String? tokenValue;

    // 우선순위 1: AuthService에서 가져온 토큰 (실제 토큰 우선)
    if (AuthService.token != null && AuthService.token!.isNotEmpty) {
      tokenValue = AuthService.token;
    }
    // 우선순위 2: data에서 직접 전달된 토큰 (테스트용)
    else if (data?['token'] != null && data!['token'].toString().isNotEmpty) {
      tokenValue = data['token'].toString();
    }
    // 우선순위 3: AuthService에서 토큰 가져오기 시도
    else {
      try {
        if (AuthService.token != null && AuthService.token!.isNotEmpty) {
          tokenValue = AuthService.token;
        }
      } catch (e) {
        // 토큰 가져오기 실패 시 무시
      }
    }

    // 4. 토큰이 비어있으면 인증 오류
    if (tokenValue == null || tokenValue.isEmpty) {
      print('ApiService: 유효한 토큰을 찾을 수 없음');
      return ApiResponse(
          result: 1, // 인증 실패
          reason: '인증 토큰이 설정되지 않았습니다. 다시 로그인해주세요.',
          data: {'auth_status': 'no_token'});
    }

    // 5. 뷰어 모드인 경우 기존 뷰어와 동일한 헤더 설정
    if (BuildMode.isViewer && AuthService.isViewerMode) {
      // 뷰어 모드: X-Viewer-Token + Authorization Bearer 헤더 사용 (기존 뷰어 방식)
      headerMap['X-Viewer-Token'] = tokenValue;
      headerMap['Authorization'] = 'Bearer $tokenValue';
      print('ApiService: 뷰어 모드 - X-Viewer-Token + Authorization Bearer 헤더 추가됨');

      // 뷰어 모드에서 동적 테넌트 ID 생성 (기존 뷰어 방식)
      final tenantId = AuthService.tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        headerMap['X-Tenant-Id'] = tenantId;
        print('ApiService: 뷰어 모드 - X-Tenant-Id 헤더 추가됨 = $tenantId');
      } else {
        // 테넌트 ID 생성 실패 시 기본값 사용
        headerMap['X-Tenant-Id'] = '10001';
        print('ApiService: 뷰어 모드 - 기본 X-Tenant-Id 사용 = 10001');
      }
    } else {
      // 편집 모드: 기존 Bearer 토큰 사용
      headerMap['Authorization'] = 'Bearer $tokenValue';

      // 편집 모드에서도 테넌트 ID 설정
      final tenantId = AuthService.tenantId;
      if (tenantId != null && tenantId.isNotEmpty) {
        headerMap['X-Tenant-Id'] = tenantId;
        print('ApiService: 편집 모드 - X-Tenant-Id 헤더 추가됨 = $tenantId');
      } else {
        print('ApiService: 편집 모드 - tenantId가 없어서 X-Tenant-Id 헤더 추가 안됨');
      }
    }

    // 7. data에서 token 제거하여 중복 방지
    final cleanData = Map<String, dynamic>.from(data ?? {});
    cleanData.remove('token');

    // 8. Dio 옵션 설정 (타임아웃 추가)
    dioOptions = Options(
      headers: headerMap,
      sendTimeout: const Duration(seconds: 60), // 전송 타임아웃 60초로 증가
      receiveTimeout: const Duration(seconds: 60), // 수신 타임아웃 60초로 증가
    );

    // 9. 최종 페이로드 구성 (API 키 제거, response_format은 GET/DELETE만 유지)
    final Map<String, dynamic> finalPayload;
    if (method == Method.get || method == Method.delete) {
      // GET/DELETE 요청: response_format을 query parameter로 사용
      finalPayload = {
        "response_format": "json",
        ...cleanData, // token이 제거된 data
      };
    } else {
      // POST/PUT/PATCH 요청: response_format 제외하고 body 데이터만 사용
      finalPayload = cleanData; // token이 제거된 data만 사용
    }

    // 뷰어 모드에서는 EasyLoading 사용하지 않음
    if (BuildMode.isEditor) {
      EasyLoading.show(status: 'loading...');
    }

    try {
      ApiResponse response;

      switch (method) {
        case Method.get:
          response = await _apiClient.get(uri,
              queryParameters: finalPayload, options: dioOptions, ifId: ifId);
          break;
        case Method.post:
          response = await _apiClient.post(uri,
              data: finalPayload, options: dioOptions, ifId: ifId);
          break;
        case Method.put:
          response = await _apiClient.put(uri,
              data: finalPayload, options: dioOptions, ifId: ifId);
          break;
        case Method.delete:
          response = await _apiClient.delete(uri,
              data: finalPayload, options: dioOptions, ifId: ifId);
          break;
        case Method.patch:
          response = await _apiClient.patch(uri,
              data: finalPayload, options: dioOptions, ifId: ifId);
          break;
      }

      // 10. 토큰 만료 시 자동 갱신 시도
      if (response.result == '-1' &&
          (response.reason?.contains('token') == true ||
              response.reason?.contains('unauthorized') == true ||
              response.reason?.contains('expired') == true ||
              response.reason?.contains('JWT_TOKEN_EXPIRED') == true)) {
        final refreshed = await AuthService.refreshToken();
        if (refreshed) {
          // 토큰 갱신 성공 시 원래 요청 재시도
          return await requestApi(
            uri: uri,
            method: method,
            data: data,
            headers: headers,
            ifId: ifId,
          );
        }
      }

      // print('ApiService: headerMap: $headerMap');
      // print(
      //     'ApiService: response data is List ?: ${response.data['result'] is List ? response.data['result'].length : response.data['result'].runtimeType}');

      return response;
    } on ApiError catch (apiError) {
      return ApiResponse(result: -1, reason: apiError.message, data: {
        'original_error': apiError.data,
        'status_code': apiError.statusCode
      });
    } catch (e) {
      return ApiResponse(
          result: -1,
          reason: e.toString(),
          data: {'exception_type': e.runtimeType.toString()});
    } finally {
      // 뷰어 모드에서는 EasyLoading dismiss하지 않음
      if (BuildMode.isEditor) {
        EasyLoading.dismiss();
      }
    }
  }
}
