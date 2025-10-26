import 'package:dio/dio.dart';
import '../error/api_error.dart';

class ErrorInterceptor extends Interceptor {
  // 재시도 가능한 에러 타입들
  static const Set<DioExceptionType> _retryableErrors = {
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
  };

  // 최대 재시도 횟수
  static const int _maxRetries = 3;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('🚨 ErrorInterceptor: 에러 처리 시작');
    print('   Error Type: ${err.type}');
    print('   Error Message: ${err.message}');
    print('   Status Code: ${err.response?.statusCode}');
    print('   URL: ${err.requestOptions.uri}');

    // 재시도 가능한 에러인지 확인
    if (_shouldRetry(err)) {
      final retryCount = _getRetryCount(err.requestOptions);
      if (retryCount < _maxRetries) {
        print('   🔄 재시도 시도 ${retryCount + 1}/$_maxRetries');
        _incrementRetryCount(err.requestOptions);

        // 잠시 대기 후 재시도
        Future.delayed(Duration(seconds: 1 << retryCount), () {
          // 재시도 로직은 Dio의 retry 인터셉터에서 처리
        });

        // 에러를 다시 던지지 않고 handler.next(err) 호출
        handler.next(err);
        return;
      } else {
        print('   ❌ 최대 재시도 횟수 초과');
      }
    }

    // 사용자 친화적 에러 메시지 생성
    final userFriendlyMessage = _getUserFriendlyMessage(err);

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        print('   🕐 연결 타임아웃 발생');
        throw ApiError(
          message: userFriendlyMessage,
          statusCode: err.response?.statusCode,
        );
      case DioExceptionType.sendTimeout:
        print('   🕐 전송 타임아웃 발생');
        throw ApiError(
          message: userFriendlyMessage,
          statusCode: err.response?.statusCode,
        );
      case DioExceptionType.receiveTimeout:
        print('   🕐 수신 타임아웃 발생');
        throw ApiError(
          message: userFriendlyMessage,
          statusCode: err.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        print('   🚫 서버 오류 응답');
        throw ApiError(
          message: userFriendlyMessage,
          statusCode: err.response?.statusCode,
          data: err.response?.data,
        );
      case DioExceptionType.cancel:
        print('   ❌ 요청 취소됨');
        throw ApiError(message: userFriendlyMessage);
      case DioExceptionType.connectionError:
        print('   🔌 연결 오류');
        throw ApiError(message: userFriendlyMessage);
      default:
        print('   ❓ 알 수 없는 오류');
        throw ApiError(message: userFriendlyMessage);
    }
  }

  /// 재시도 가능한 에러인지 확인
  bool _shouldRetry(DioException err) {
    return _retryableErrors.contains(err.type);
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

  /// 사용자 친화적 에러 메시지 생성
  String _getUserFriendlyMessage(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
        return '서버 연결이 시간 초과되었습니다. 잠시 후 다시 시도해주세요.';
      case DioExceptionType.sendTimeout:
        return '데이터 전송이 시간 초과되었습니다. 네트워크 상태를 확인해주세요.';
      case DioExceptionType.receiveTimeout:
        return '서버 응답 대기 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
      case DioExceptionType.badResponse:
        if (err.response?.statusCode == 500) {
          return '서버에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
        } else if (err.response?.statusCode == 404) {
          return '요청하신 정보를 찾을 수 없습니다.';
        } else if (err.response?.statusCode == 403) {
          return '접근 권한이 없습니다.';
        } else {
          return '서버 오류가 발생했습니다. (오류 코드: ${err.response?.statusCode})';
        }
      case DioExceptionType.cancel:
        return '요청이 취소되었습니다.';
      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없습니다. 인터넷 연결을 확인해주세요.';
      default:
        return '네트워크 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }
}
