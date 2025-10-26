import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../api/api_service.dart';
import '../../pms/model/behavior.dart';

class AuthService {
  static String? _token;
  static String? _tenantId;
  static Map<String, dynamic>? _userInfo;
  static bool _isInitialized = false;

  /// 토큰 변경 시 콜백 등록
  static final List<Function(String?)> _tokenChangeCallbacks = [];

  /// 인증 초기화 - URL 파라미터에서 토큰 추출
  static Future<bool> initializeAuth() async {
    if (_isInitialized) {
      return _token != null;
    }

    try {
      if (kIsWeb) {
        // 뷰어 모드인 경우 뷰어 인증 시도
        if (_viewerApiKey != null) {
          print('AuthService: 뷰어 모드 인증 시도');
          return await initializeViewerAuth();
        }

        // 웹 환경에서 URL 파라미터 추출
        final uri = Uri.parse(html.window.location.href);
        final token = uri.queryParameters['token'];
        final userStr = uri.queryParameters['user'];

        print('AuthService: URL 파라미터 확인');
        print('전체 URL: ${html.window.location.href}');
        print('Token: ${token != null ? '존재' : '없음'}');
        print('User: ${userStr != null ? '존재' : '없음'}');

        if (token != null) {
          print('Token 값: ${token.substring(0, 20)}...');
        }

        if (userStr != null) {
          print('User 값 (원본): $userStr');
          try {
            // 이미 JSON 형태인지 확인
            String decodedUser;
            if (userStr.startsWith('{') && userStr.endsWith('}')) {
              // 이미 디코딩된 JSON 문자열
              decodedUser = userStr;
            } else {
              // URL 인코딩된 문자열이므로 디코딩
              decodedUser = Uri.decodeComponent(userStr);
            }

            // JSON 파싱 시도
            final userMap = jsonDecode(decodedUser);
            // User 파싱 성공

            setToken(token); // 토큰 설정 및 콜백 실행
            _userInfo = userMap;

            // URL 파라미터에서 받은 사용자 정보로 tenantId 설정
            if (userMap['email'] != null) {
              final parsedEmail = userMap['email'].toString().split('@');
              _tenantId = '${parsedEmail[0]}${parsedEmail[1].split('.').first}';
              print('AuthService: URL 파라미터에서 tenantId 설정됨 = $_tenantId');
            }

            _isInitialized = true;
            print('AuthService: 실제 토큰과 사용자 정보로 인증 성공');
            return true;
          } catch (e) {
            print('AuthService: User 파싱 실패 - $e');
            print('AuthService: 파싱 실패로 인해 인증 실패');
          }
        }

        // 모든 환경에서 실제 토큰과 사용자 정보가 있어야만 인증 성공
        print('AuthService: 인증 실패 - 토큰 또는 사용자 정보 없음');
        _isInitialized = true;
        return false;
      }
    } catch (e) {
      print('AuthService: 초기화 오류 - $e');
      setToken(null); // 토큰 제거 및 콜백 실행
      setTenantId(null); // 테넌트 ID 제거
      _userInfo = null;
    }

    _isInitialized = true;
    return false;
  }

  /// 토큰 유효성 검증 - /auth/profile API 사용
  static Future<bool> _verifyToken(String token) async {
    try {
      print('AuthService: 토큰 검증 시작 - /auth/profile API 호출');

      final response = await ApiService().requestApi(
        uri: '/auth/profile',
        method: Method.get,
        data: {'token': token}, // 토큰을 data에 포함하여 전달
      );

      final isValid = response.result == '1' || response.result == '0';
      print('AuthService: 토큰 검증 결과 - ${isValid ? '성공' : '실패'}');
      print('Response: ${response.toString()}');

      if (isValid && response.data != null) {
        // 서버에서 받은 사용자 정보로 업데이트
        _userInfo = response.data['user'] as Map<String, dynamic>?;
        final parsedEmail = _userInfo?['email'].toString().split('@');
        _tenantId =
            '${parsedEmail?[0] ?? ''}${parsedEmail?[1].split('.').first ?? ''}';
        print('AuthService: 서버에서 받은 사용자 정보로 업데이트');
        print('AuthService: 설정된 tenantId = $_tenantId');
      }

      return isValid;
    } catch (e) {
      print('AuthService: 토큰 검증 오류 - $e');
      return false;
    }
  }

  /// 토큰 변경 콜백 등록
  static void addTokenChangeCallback(Function(String?) callback) {
    _tokenChangeCallbacks.add(callback);
    print('AuthService: 토큰 변경 콜백 등록됨');
  }

  /// 토큰 변경 시 콜백 실행
  static void _notifyTokenChange(String? newToken) {
    print('AuthService: 토큰 변경 알림 - ${newToken?.substring(0, 20) ?? 'null'}...');
    for (final callback in _tokenChangeCallbacks) {
      try {
        callback(newToken);
      } catch (e) {
        print('토큰 변경 콜백 실행 오류: $e');
      }
    }
  }

  /// 토큰 설정 (동기화 포함)
  static void setToken(String? token) {
    _token = token;
    _notifyTokenChange(token);
    print('AuthService: 토큰 설정됨 - ${token?.substring(0, 20) ?? 'null'}...');
  }

  /// 테넌트 ID 설정
  static void setTenantId(String? tenantId) {
    _tenantId = tenantId;
    print('AuthService: 테넌트 ID 설정됨 - $tenantId');
  }

  /// 현재 토큰 반환
  static String? get token => _token;

  /// 현재 테넌트 ID 반환
  static String? get tenantId => _tenantId;

  /// 현재 사용자 정보 반환
  static Map<String, dynamic>? get userInfo => _userInfo;

  /// 로그인 상태 확인
  static bool get isAuthenticated => _token != null;

  /// 로그아웃
  static void logout() {
    print('AuthService: 로그아웃 실행');
    setToken(null); // 토큰 제거 및 콜백 실행
    setTenantId(null); // 테넌트 ID 제거
    _userInfo = null;
    _isInitialized = false;
  }

  /// 토큰 갱신
  static Future<bool> refreshToken() async {
    if (_token == null) {
      print('AuthService: 갱신할 토큰이 없음');
      return false;
    }

    try {
      print('AuthService: 토큰 갱신 시작');

      final response = await ApiService().requestApi(
        uri: '/auth/refresh',
        method: Method.post,
        data: {'token': _token},
      );

      if (response.result == '1' && response.data['token'] != null) {
        setToken(response.data['token']); // 토큰 설정 및 콜백 실행
        print('AuthService: 토큰 갱신 성공');
        return true;
      } else {
        print('AuthService: 토큰 갱신 실패 - ${response.reason}');
      }
    } catch (e) {
      print('AuthService: 토큰 갱신 오류 - $e');
    }

    return false;
  }

  /// 토큰 유효성 검증
  static Future<bool> isTokenValid() async {
    if (_token == null) return false;

    try {
      final response = await ApiService().requestApi(
        uri: '/auth/profile',
        method: Method.get,
        data: {'token': _token},
      );

      return response.result == '0' || response.result == '1';
    } catch (e) {
      print('토큰 유효성 검증 오류: $e');
      return false;
    }
  }

  /// 토큰 만료 시 자동 갱신
  static Future<bool> ensureValidToken() async {
    if (await isTokenValid()) return true;

    print('토큰이 만료되었습니다. 갱신을 시도합니다.');
    return await refreshToken();
  }

  /// 토큰 만료 시간 확인
  static bool get isTokenExpired {
    if (_userInfo == null) return true;
    // 임시 토큰은 만료 시간이 없으므로 false 반환
    return false;
  }

  /// 디버그 정보 출력
  static void printDebugInfo() {
    print('=== AuthService 디버그 정보 ===');
    print('Token: ${_token != null ? '존재' : '없음'}');
    print('User Info: ${_userInfo != null ? '존재' : '없음'}');
    print('Is Authenticated: $isAuthenticated');
    print('Is Initialized: $_isInitialized');
    print('Is Token Expired: $isTokenExpired');
    print('Token Change Callbacks: ${_tokenChangeCallbacks.length}개');
    if (_userInfo != null) {
      print('User Details: ${_userInfo.toString()}');
    }
    print('==============================');
  }

  /// 초기화 완료 여부 확인
  static bool get isInitialized => _isInitialized;

  /// 강제로 AuthService 초기화
  static Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await initializeAuth();
    }
  }

  /// 뷰어 모드용 API 키
  static String? _viewerApiKey;

  /// 뷰어 API 키 설정 (외부에서 주입)
  static void setViewerApiKey(String? apiKey) {
    _viewerApiKey = apiKey;
    print(
        'AuthService: 뷰어 API 키 설정됨 - ${apiKey?.substring(0, 20) ?? 'null'}...');
  }

  /// 뷰어 API 키 반환
  static String? get viewerApiKey => _viewerApiKey;

  /// 뷰어 모드 인증 초기화
  static Future<bool> initializeViewerAuth() async {
    if (_isInitialized) {
      return _token != null;
    }

    if (_viewerApiKey == null) {
      return false;
    }

    if (!_processViewerApiKey(_viewerApiKey!)) {
      return false;
    }

    try {
      const url =
          'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com/idev/v1/viewer-api-keys/authenticate';

      final response = await html.HttpRequest.request(
        url,
        method: 'POST',
        sendData: jsonEncode({'apiKey': _viewerApiKey}),
        requestHeaders: {'Content-Type': 'application/json'},
      );

      if (response.status == 200 && response.responseText != null) {
        final responseData = jsonDecode(response.responseText!);

        if (responseData['result'] == '0' || responseData['result'] == '1') {
          final token =
              responseData['data']?['token']?.toString() ?? _viewerApiKey;
          final userInfo = responseData['data']?['viewerInfo'] ??
              {
                'type': 'viewer',
                'apiKey': _viewerApiKey,
              };

          setToken(token);
          _userInfo = userInfo;

          // 테넌트 ID 설정
          final userEmail = responseData['data']?['user']?['email']?.toString();
          if (userEmail != null) {
            final parsedEmail = userEmail.split('@');
            if (parsedEmail.length == 2) {
              final localPart = parsedEmail[0];
              final domainPart = parsedEmail[1];
              final domainParts = domainPart.split('.');
              final firstDomainPart =
                  domainParts.isNotEmpty ? domainParts[0] : '';
              _tenantId = '$localPart$firstDomainPart';
            }
          }

          _isInitialized = true;
          return true;
        }
      }

      _isInitialized = true;
      return false;
    } catch (e) {
      _isInitialized = true;
      return false;
    }
  }

  /// API 키 검증 로직
  static bool _processViewerApiKey(String apiKey) {
    if (apiKey.isNotEmpty) {
      _viewerApiKey = apiKey;
      return true;
    }
    return false;
  }

  /// 뷰어 모드 여부 확인
  static bool get isViewerMode => _viewerApiKey != null;
}
