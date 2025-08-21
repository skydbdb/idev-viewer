import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('🌐 API 요청 시작');
    print('   URL: ${options.uri}');
    print('   Method: ${options.method}');
    print('   Headers: ${options.headers}');
    print('   Data: ${options.data}');
    print('   Query Parameters: ${options.queryParameters}');
    print(
        '   Timeout: ${options.sendTimeout?.inSeconds}초 (전송), ${options.receiveTimeout?.inSeconds}초 (수신)');

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('✅ API 응답 성공');
    print('   Status Code: ${response.statusCode}');
    print('   URL: ${response.requestOptions.uri}');
    print('   Data Type: ${response.data.runtimeType}');
    print(
        '   Data Size: ${response.data is String ? response.data.length : 'N/A'}');

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ API 오류 발생');
    print('   Error Type: ${err.type}');
    print('   Error Message: ${err.message}');
    print('   Status Code: ${err.response?.statusCode}');
    print('   URL: ${err.requestOptions.uri}');
    print('   Response Data: ${err.response?.data}');

    super.onError(err, handler);
  }
}
