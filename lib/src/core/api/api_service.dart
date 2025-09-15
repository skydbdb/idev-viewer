import 'package:dio/dio.dart'; // Options를 위해 필요할 수 있음
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '/src/di/service_locator.dart';

import '../error/api_error.dart';
import './model/api_response.dart'; // ApiResponse 모델
import './model/behavior.dart'; // Method enum 사용
import '../auth/auth_service.dart'; // AuthService import 추가
import '../auth/viewer_auth_service.dart'; // ViewerAuthService import 추가
import '../../util/network_utils.dart'; // NetworkUtils import 추가
import 'api_client.dart';

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
    // AuthService 초기화는 호출하는 쪽에서 처리하도록 변경
    // await AuthService.ensureInitialized();

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
    // 우선순위 3: ViewerAuthService에서 뷰어 토큰 가져오기
    else if (ViewerAuthService.isViewerAuthenticated &&
        ViewerAuthService.viewerToken != null) {
      tokenValue = ViewerAuthService.viewerToken;
    }
    // 우선순위 4: AuthService에서 토큰 가져오기 시도
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

    // 5. 토큰을 헤더에 설정
    if (ViewerAuthService.isViewerAuthenticated &&
        ViewerAuthService.viewerToken == tokenValue) {
      // 뷰어 토큰인 경우 X-Viewer-Token 헤더 사용
      headerMap['X-Viewer-Token'] = tokenValue;
      // 뷰어 토큰은 Authorization 헤더도 함께 설정 (서버 호환성)
      headerMap['Authorization'] = 'Bearer $tokenValue';

      // 뷰어 인증 시 동적으로 생성된 테넌트 ID 사용
      final tenantId = ViewerAuthService.tenantId;
      if (tenantId != null) {
        headerMap['X-Tenant-Id'] = tenantId;
        print('ApiService: 뷰어 인증 - X-Tenant-Id 헤더 추가 - $tenantId');
      } else {
        // 테넌트 ID 생성 실패 시 기본값 사용
        headerMap['X-Tenant-Id'] = '10001';
        print('ApiService: 뷰어 인증 - 기본 X-Tenant-Id 사용 - 10001');
      }
    } else {
      // 일반 토큰인 경우 Bearer 토큰 사용
      headerMap['Authorization'] = 'Bearer $tokenValue';
      // 일반 인증 시에도 기본 테넌트 ID 사용
      headerMap['X-Tenant-Id'] = '10001';
      print('ApiService: 일반 인증 - 기본 X-Tenant-Id 사용 - 10001');
    }

    // 6. data에서 token 제거하여 중복 방지
    final cleanData = Map<String, dynamic>.from(data ?? {});
    cleanData.remove('token');

    // 7. Dio 옵션 설정 (타임아웃 추가)
    dioOptions = Options(
      headers: headerMap,
      sendTimeout: const Duration(seconds: 60), // 전송 타임아웃 60초로 증가
      receiveTimeout: const Duration(seconds: 60), // 수신 타임아웃 60초로 증가
    );

    // 8. 최종 페이로드 구성 (API 키 제거, response_format만 유지)
    final Map<String, dynamic> finalPayload = {
      "response_format": "json",
      ...cleanData, // token이 제거된 data
    };

    EasyLoading.show(status: 'loading...');
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

      // 9. 토큰 만료 시 자동 갱신 시도
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
      EasyLoading.dismiss();
    }
  }
}
