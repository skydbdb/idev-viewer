import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryDelay;
  final List<int> retryStatusCodes;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryStatusCodes = const [500, 502, 503, 504],
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = _getRetryCount(err.requestOptions);

    if (_shouldRetry(err) && retryCount < maxRetries) {
      print('🔄 RetryInterceptor: 재시도 시도 ${retryCount + 1}/$maxRetries');

      // 재시도 횟수 증가
      _incrementRetryCount(err.requestOptions);

      // 지수 백오프로 대기 시간 증가
      final delay = Duration(
          milliseconds: (retryDelay.inMilliseconds * (1 << retryCount)));
      await Future.delayed(delay);

      try {
        // 요청 재시도
        final response = await _retryRequest(err.requestOptions);
        handler.resolve(response);
        return;
      } catch (retryError) {
        // 재시도 실패 시 원래 에러 전달
        handler.next(err);
        return;
      }
    }

    // 재시도하지 않을 경우 원래 에러 전달
    handler.next(err);
  }

  /// 재시도 가능한 에러인지 확인
  bool _shouldRetry(DioException err) {
    // 연결 오류나 타임아웃은 재시도
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    // 특정 상태 코드는 재시도
    if (err.type == DioExceptionType.badResponse &&
        err.response?.statusCode != null &&
        retryStatusCodes.contains(err.response!.statusCode)) {
      return true;
    }

    return false;
  }

  /// 현재 재시도 횟수 가져오기
  int _getRetryCount(RequestOptions options) {
    return options.extra['retryCount'] ?? 0;
  }

  /// 재시도 횟수 증가
  void _incrementRetryCount(RequestOptions options) {
    final currentCount = _getRetryCount(options);
    options.extra['retryCount'] = currentCount + 1;
  }

  /// 요청 재시도
  Future<Response> _retryRequest(RequestOptions options) async {
    final dio = Dio();

    // 원본 요청과 동일한 설정으로 재시도
    final response = await dio.request(
      options.path,
      data: options.data,
      queryParameters: options.queryParameters,
      options: Options(
        method: options.method,
        headers: options.headers,
        contentType: options.contentType,
        responseType: options.responseType,
        validateStatus: options.validateStatus,
        receiveTimeout: options.receiveTimeout,
        sendTimeout: options.sendTimeout,
      ),
    );

    return response;
  }
}
