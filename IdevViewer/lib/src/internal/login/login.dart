import '../core/api/api_service.dart';
import '../pms/model/behavior.dart';
import '../pms/model/result.dart';
import '../pms/model/api_response.dart';
import '../core/error/api_error.dart';
import 'package:idev_viewer/src/internal/pms/di/service_locator.dart';

Future<Result<dynamic>> login({String? userId, String? password}) async {
  print('Login attempt with userId: $userId');
  final ApiService apiService = sl<ApiService>();
  try {
    final ApiResponse apiResponse = await apiService.requestApi(
      method: Method.post,
      uri: '/univ/login',
      data: {
        "if_id": "IF-LOG01-0001",
        "passwd": password,
        "router": '22n1101',
        "user_no": userId
      },
    );

    if (apiResponse.result == 0 && apiResponse.data != null) {
      return Result.success(apiResponse.data);
    } else {
      print(
          'Login API call logical error or no data. Result: ${apiResponse.result}, Reason: ${apiResponse.reason}');
      return Result.error(
          apiResponse.reason ?? 'Login failed or no data received.');
    }
  } catch (e) {
    print('Login - exception during ApiService.requestApi call: $e');
    if (e is ApiError) {
      return Result.error(e.message);
    }
    return Result.error(e.toString());
  }
}
