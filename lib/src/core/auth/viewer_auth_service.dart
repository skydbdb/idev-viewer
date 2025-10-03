import 'dart:convert';
import 'dart:html' as html;

class ViewerAuthService {
  static String? _viewerToken;
  static Map<String, dynamic>? _viewerInfo;
  static bool _isInitialized = false;
  static bool _isAuthenticated = false;
  static String? _userEmail; // 사용자 이메일 저장

  // 뷰어 API 키 (VIEWER_AUTH_GUIDE.md에서 가져온 값)
  static String _viewerApiKey = '';

  static set viewerApiKey(String? value) {
    _viewerApiKey = value ?? '';
  }

  static String get viewerApiKey => _viewerApiKey;

  /// 뷰어 인증 초기화
  static Future<bool> initializeViewerAuth() async {
    if (_isInitialized) {
      return _isAuthenticated;
    }

    try {
      print('ViewerAuthService: 뷰어 인증 초기화 시작');

      // 뷰어 API 키로 인증 시도 (직접 HTTP 요청)
      const url =
          'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com/idev/v1/viewer-api-keys/authenticate';

      try {
        final response = await html.HttpRequest.request(
          url,
          method: 'POST',
          sendData: jsonEncode({
            'apiKey': _viewerApiKey,
          }),
          requestHeaders: {
            'Content-Type': 'application/json',
          },
        );

        print('ViewerAuthService: HTTP 응답 상태 - ${response.status}');
        print('ViewerAuthService: HTTP 응답 텍스트 - ${response.responseText}');

        if (response.status == 200 && response.responseText != null) {
          final responseData = jsonDecode(response.responseText!);
          print('ViewerAuthService: 파싱된 응답 - $responseData');

          if (responseData['result'] == '1' || responseData['result'] == '0') {
            // 인증 성공
            _viewerToken =
                responseData['data']?['token']?.toString() ?? _viewerApiKey;
            _viewerInfo = responseData['data']?['viewerInfo'] ??
                {
                  'type': 'viewer',
                  'apiKey': _viewerApiKey,
                };

            // 사용자 이메일 저장 (테넌트 ID 생성용)
            _userEmail = responseData['data']?['user']?['email']?.toString();

            _isAuthenticated = true;
            _isInitialized = true;

            print('ViewerAuthService: 뷰어 인증 성공');
            print(
                'ViewerAuthService: 뷰어 토큰 - ${_viewerToken?.substring(0, 20)}...');
            print('ViewerAuthService: 사용자 이메일 - $_userEmail');

            return true;
          } else {
            // 인증 실패
            print(
                'ViewerAuthService: 뷰어 인증 실패 - ${responseData['reason']?.toString() ?? '알 수 없는 오류'}');
            _isAuthenticated = false;
            _isInitialized = false;
            return false;
          }
        } else {
          print('ViewerAuthService: HTTP 요청 실패 - 상태 코드: ${response.status}');
          _isAuthenticated = false;
          _isInitialized = false;
          return false;
        }
      } catch (e) {
        print('ViewerAuthService: HTTP 요청 오류 - $e');
        _isAuthenticated = false;
        _isInitialized = false;
        return false;
      }
    } catch (e) {
      print('ViewerAuthService: 뷰어 인증 오류 - $e');
      _isAuthenticated = false;
      _isInitialized = false;
      return false;
    }
  }

  /// 뷰어 토큰 반환
  static String? get viewerToken => _viewerToken;

  /// 뷰어 정보 반환
  static Map<String, dynamic>? get viewerInfo => _viewerInfo;

  /// 뷰어 인증 상태 확인
  static bool get isViewerAuthenticated => _isAuthenticated;

  /// 뷰어 초기화 완료 여부 확인
  static bool get isViewerInitialized => _isInitialized;

  /// 사용자 이메일에서 테넌트 ID 생성
  /// 예: skydbdb@gmail.com -> skydbdbgmail
  static String? get tenantId {
    if (_userEmail == null || _userEmail!.isEmpty) {
      return null;
    }

    try {
      // @ 문자로 분리
      final parts = _userEmail!.split('@');
      if (parts.length != 2) {
        return null;
      }

      final localPart = parts[0]; // @ 앞부분 (예: skydbdb)
      final domainPart = parts[1]; // @ 뒷부분 (예: gmail.com)

      // 도메인 부분을 '.'으로 분리하여 첫 번째 부분만 사용
      final domainParts = domainPart.split('.');
      final firstDomainPart = domainParts.isNotEmpty ? domainParts[0] : '';

      // 조합하여 테넌트 ID 생성
      final tenantId = '$localPart$firstDomainPart';

      print('ViewerAuthService: 이메일 $_userEmail -> 테넌트 ID $tenantId');
      return tenantId;
    } catch (e) {
      print('ViewerAuthService: 테넌트 ID 생성 오류 - $e');
      return null;
    }
  }

  /// 뷰어 인증 강제 초기화
  static Future<void> ensureViewerInitialized() async {
    if (!_isInitialized) {
      await initializeViewerAuth();
    }
  }

  /// 뷰어 토큰 유효성 검증
  static Future<bool> isViewerTokenValid() async {
    if (_viewerToken == null) return false;

    try {
      const url =
          'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com/idev/v1/viewer-api-keys/validate';

      final response = await html.HttpRequest.request(
        url,
        method: 'GET',
        requestHeaders: {
          'X-Viewer-Token': _viewerToken!,
          'Content-Type': 'application/json',
        },
      );

      if (response.status == 200 && response.responseText != null) {
        final responseData = jsonDecode(response.responseText!);
        return responseData['result'] == '0' || responseData['result'] == '1';
      }

      return false;
    } catch (e) {
      print('ViewerAuthService: 뷰어 토큰 유효성 검증 오류 - $e');
      return false;
    }
  }

  /// 뷰어 전용 API 호출 (X-Viewer-Token 헤더 사용)
  static Future<dynamic> callViewerApi({
    required String uri,
    required String method,
    Map<String, dynamic>? data,
    Map<String, String>? additionalHeaders,
  }) async {
    if (!_isAuthenticated || _viewerToken == null) {
      throw Exception('뷰어 인증이 필요합니다.');
    }

    try {
      final url =
          'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com$uri';

      // 기본 뷰어 헤더 - X-Viewer-Token을 우선으로 설정
      final headers = <String, String>{
        'X-Viewer-Token': _viewerToken!,
        'Authorization': 'Bearer ${_viewerToken!}', // 서버 호환성을 위해 함께 설정
        'Content-Type': 'application/json',
        ...?additionalHeaders,
      };

      // 동적으로 생성된 테넌트 ID 추가
      final tenantId = ViewerAuthService.tenantId;
      if (tenantId != null) {
        headers['X-Tenant-Id'] = tenantId;
        print('ViewerAuthService: X-Tenant-Id 헤더 추가 - $tenantId');
      }

      final response = await html.HttpRequest.request(
        url,
        method: method.toUpperCase(),
        sendData: data != null ? jsonEncode(data) : null,
        requestHeaders: headers,
      );

      if (response.status == 200 && response.responseText != null) {
        return jsonDecode(response.responseText!);
      } else {
        throw Exception('API 호출 실패: ${response.status}');
      }
    } catch (e) {
      print('ViewerAuthService: 뷰어 API 호출 오류 - $e');
      rethrow;
    }
  }

  /// 뷰어 API 호출 예시
  ///
  /// 템플릿 목록 조회:
  /// ```dart
  /// final templates = await ViewerAuthService.callViewerApi(
  ///   uri: '/idev/v1/templates',
  ///   method: Method.get,
  /// );
  /// ```
  ///
  /// 특정 템플릿 조회:
  /// ```dart
  /// final template = await ViewerAuthService.callViewerApi(
  ///   uri: '/idev/v1/templates/123',
  ///   method: Method.get,
  /// );
  /// ```

  /// 뷰어 인증 정보 초기화
  static void resetViewerAuth() {
    _viewerToken = null;
    _viewerInfo = null;
    _userEmail = null;
    _isAuthenticated = false;
    _isInitialized = false;
    print('ViewerAuthService: 뷰어 인증 정보 초기화됨');
  }

  /// 디버그 정보 출력
  static void printDebugInfo() {
    print('=== ViewerAuthService 디버그 정보 ===');
    print('Viewer Token: ${_viewerToken != null ? '존재' : '없음'}');
    print('Viewer Info: ${_viewerInfo != null ? '존재' : '없음'}');
    print('Is Viewer Authenticated: $_isAuthenticated');
    print('Is Viewer Initialized: $_isInitialized');
    if (_viewerInfo != null) {
      print('Viewer Details: ${_viewerInfo.toString()}');
    }
    if (_viewerToken != null) {
      print('헤더 사용 방식: X-Viewer-Token + Authorization Bearer');
      print('토큰 값: ${_viewerToken!.substring(0, 20)}...');
    }
    print('=====================================');
  }
}
