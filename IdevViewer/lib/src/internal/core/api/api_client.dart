import 'package:dio/dio.dart';
import '../config/env.dart';
import '../error/api_error.dart';
import '../interceptors/logging_interceptor.dart';
import '../interceptors/error_interceptor.dart';
import '../interceptors/retry_interceptor.dart';
import '../monitoring/api_monitor.dart';
import '../../pms/model/api_response.dart';

class ApiClient {
  final Dio _dio;

  ApiClient() : _dio = Dio() {
    _dio.interceptors.addAll([
      LoggingInterceptor(),
      RetryInterceptor(), // 재시도 인터셉터를 먼저 추가
      ErrorInterceptor(), // 에러 인터셉터를 마지막에 추가
    ]);

    // 기본 타임아웃 설정
    _dio.options.connectTimeout =
        const Duration(seconds: 60); // 연결 타임아웃 60초로 증가
    _dio.options.sendTimeout = const Duration(seconds: 60); // 전송 타임아웃 60초로 증가
    _dio.options.receiveTimeout =
        const Duration(seconds: 60); // 수신 타임아웃 60초로 증가

    _dio.options.headers = {
      'Content-Type': 'application/json;charset=utf-8',
    };
  }

  Future<ApiResponse> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? ifId,
  }) async {
    final apiId = ifId ?? path;
    final url = AppConfig.instance.getApiHost(path, ifId: ifId) +
        (path.startsWith('/') ? path : '/$path');

    // API 호출 모니터링 시작
    ApiMonitor().startApiCall(apiId, url);

    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: options,
      );

      if (response.data == null) {
        // API 호출 모니터링 완료 (실패)
        ApiMonitor().endApiCall(apiId, false,
            errorMessage: '서버로부터 응답 데이터가 없습니다.',
            statusCode: response.statusCode);

        throw ApiError(
            message: '서버로부터 응답 데이터가 없습니다.', statusCode: response.statusCode);
      }

      if (response.data is Map<String, dynamic>) {
        // API 호출 모니터링 완료 (성공)
        ApiMonitor().endApiCall(apiId, true, statusCode: response.statusCode);

        return ApiResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        // API 호출 모니터링 완료 (실패)
        ApiMonitor().endApiCall(apiId, false,
            errorMessage: '서버로부터 예상치 못한 응답 데이터 형식입니다.',
            statusCode: response.statusCode);

        throw ApiError(
            message: '서버로부터 예상치 못한 응답 데이터 형식입니다.',
            statusCode: response.statusCode,
            data: response.data);
      }
    } on DioException catch (e) {
      // API 호출 모니터링 완료 (실패)
      ApiMonitor().endApiCall(apiId, false,
          errorMessage: e.message ?? 'API GET 요청 Dio 오류',
          statusCode: e.response?.statusCode);

      if (e.error is ApiError) {
        throw e.error as ApiError;
      }
      throw ApiError(
          message: e.message ?? 'API GET 요청 Dio 오류',
          statusCode: e.response?.statusCode,
          data: e.response?.data ?? e.error);
    } catch (e, s) {
      // API 호출 모니터링 완료 (실패)
      ApiMonitor()
          .endApiCall(apiId, false, errorMessage: 'API GET 요청 중 알 수 없는 오류: $e');

      if (e is ApiError) rethrow;
      throw ApiError(message: 'API GET 요청 중 알 수 없는 오류: $e');
    }
  }

  Future<ApiResponse> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? ifId,
  }) async {
    try {
      final url = AppConfig.instance.getApiHost(path, ifId: ifId) +
          (path.startsWith('/') ? path : '/$path');
      final response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ApiError(
            message: '서버로부터 유효하지 않은 응답 데이터 형식입니다.',
            statusCode: response.statusCode,
            data: response.data);
      }
    } on DioException catch (e) {
      if (e.error is ApiError) throw e.error as ApiError;
      throw ApiError(
          message: e.message ?? 'API POST 요청 Dio 오류',
          statusCode: e.response?.statusCode,
          data: e.response?.data);
    } catch (e, s) {
      if (e is ApiError) rethrow;
      throw ApiError(message: 'API POST 요청 중 알 수 없는 오류: $e');
    }
  }

  Future<ApiResponse> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? ifId,
  }) async {
    try {
      final url = AppConfig.instance.getApiHost(path, ifId: ifId) +
          (path.startsWith('/') ? path : '/$path');
      final response = await _dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ApiError(
            message: '서버로부터 유효하지 않은 응답 데이터 형식입니다.',
            statusCode: response.statusCode,
            data: response.data);
      }
    } on DioException catch (e) {
      if (e.error is ApiError) throw e.error as ApiError;
      throw ApiError(
          message: e.message ?? 'API PUT 요청 Dio 오류',
          statusCode: e.response?.statusCode,
          data: e.response?.data);
    } catch (e, s) {
      if (e is ApiError) rethrow;
      throw ApiError(message: 'API PUT 요청 중 알 수 없는 오류: $e');
    }
  }

  Future<ApiResponse> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? ifId,
  }) async {
    try {
      final url = AppConfig.instance.getApiHost(path, ifId: ifId) +
          (path.startsWith('/') ? path : '/$path');
      final response = await _dio.delete(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.data == null) {
        return ApiResponse(result: 0, reason: '삭제 성공 (내용 없음)');
      }
      if (response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ApiError(
            message: '서버로부터 유효하지 않은 응답 데이터 형식입니다.',
            statusCode: response.statusCode,
            data: response.data);
      }
    } on DioException catch (e) {
      if (e.error is ApiError) throw e.error as ApiError;
      throw ApiError(
          message: e.message ?? 'API DELETE 요청 Dio 오류',
          statusCode: e.response?.statusCode,
          data: e.response?.data);
    } catch (e, s) {
      if (e is ApiError) rethrow;
      throw ApiError(message: 'API DELETE 요청 중 알 수 없는 오류: $e');
    }
  }

  Future<ApiResponse> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    String? ifId,
  }) async {
    try {
      final url = AppConfig.instance.getApiHost(path, ifId: ifId) +
          (path.startsWith('/') ? path : '/$path');
      final response = await _dio.patch(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      if (response.data != null && response.data is Map<String, dynamic>) {
        return ApiResponse.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ApiError(
            message: '서버로부터 유효하지 않은 응답 데이터 형식입니다.',
            statusCode: response.statusCode,
            data: response.data);
      }
    } on DioException catch (e) {
      if (e.error is ApiError) throw e.error as ApiError;
      throw ApiError(
          message: e.message ?? 'API PATCH 요청 Dio 오류',
          statusCode: e.response?.statusCode,
          data: e.response?.data);
    } catch (e, s) {
      if (e is ApiError) rethrow;
      throw ApiError(message: 'API PATCH 요청 중 알 수 없는 오류: $e');
    }
  }
}
