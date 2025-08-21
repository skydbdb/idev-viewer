import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_response.freezed.dart';
part 'api_response.g.dart';

/// result
/// 0 = 성공
/// 5000 = alert, server driven message 노출
/// 5001 = confirm, message 노출 및 ok 시 파라미터 변경 후 재전송
@freezed
class ApiResponse with _$ApiResponse {
  ApiResponse._();
  factory ApiResponse({
    dynamic result,
    String? reason,
    String? field,
    String? txid,
    @JsonKey(name: 'server_time') String? serverTime,
    @JsonKey(name: 'response_time') String? responseTime,
    dynamic data,
  }) = _ApiResponse;

  bool get isTokenExpired => _getResultString() == '4006';

  bool get isTokenError => switch (_getResultString()) {
        '4004' => true,
        '4005' => true,
        '4007' => true,
        '4008' => true,
        '4009' => true,
        '4010' => true,
        '4011' => true,
        '4012' => true,
        '4013' => true,
        '4015' => true,
        '4017' => true,
        _ => false
      };

  bool get isError => _getResultString() != '0' && _getResultString() != '5001';

  bool get isValid {
    final resultStr = _getResultString();
    return resultStr == '1000' ||
        resultStr == '1001' ||
        resultStr == '1002' ||
        resultStr == '1003' ||
        resultStr == '1004';
  }

  /// result 필드를 안전하게 문자열로 변환하는 헬퍼 메서드
  String _getResultString() {
    if (result == null) return '';
    return result.toString();
  }

  dynamic get dataResult {
    if (data is Map<String, dynamic>) {
      return (data as Map<String, dynamic>)['result'];
    }
    return null;
  }

  List? get code {
    if (data is Map<String, dynamic>) {
      return (data as Map<String, dynamic>)['code'];
    }
    return null;
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseFromJson(json);
}
