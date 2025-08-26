import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../api/api_service.dart';
import '../api/model/behavior.dart';
import 'viewer_auth_service.dart';

class AuthService {
  static String? _token;
  static Map<String, dynamic>? _userInfo;
  static bool _isInitialized = false;

  /// 토큰 변경 시 콜백 등록
  static final List<Function(String?)> _tokenChangeCallbacks = [];

  /// 인증 초기화 - 뷰어 인증 또는 로컬 개발 환경 인증
  static Future<bool> initializeAuth() async {
    if (_isInitialized) {
      return _token != null;
    }

    try {
      if (kIsWeb) {
        // 뷰어 인증 시도 (ViewerAuthService가 이미 초기화되어 있으면 재사용)
        print('AuthService: 뷰어 인증 상태 확인');

        // ViewerAuthService가 이미 초기화되어 있으면 그 결과 사용
        if (ViewerAuthService.isViewerInitialized) {
          if (ViewerAuthService.isViewerAuthenticated) {
            final viewerToken = ViewerAuthService.viewerToken;
            final viewerInfo = ViewerAuthService.viewerInfo;

            if (viewerToken != null) {
              setToken(viewerToken);
              _userInfo = viewerInfo ??
                  {
                    'name': 'IDEV 뷰어',
                    'id': 'viewer_user',
                    'role': 'viewer',
                    'type': 'viewer'
                  };
              _isInitialized = true;
              print('AuthService: 기존 뷰어 인증 사용');
              return true;
            }
          }
        } else {
          // ViewerAuthService 초기화가 안 되어 있으면 초기화
          print('AuthService: 뷰어 인증 초기화');
          final viewerAuthResult =
              await ViewerAuthService.initializeViewerAuth();

          if (viewerAuthResult) {
            // 뷰어 인증 성공
            final viewerToken = ViewerAuthService.viewerToken;
            final viewerInfo = ViewerAuthService.viewerInfo;

            if (viewerToken != null) {
              setToken(viewerToken);
              _userInfo = viewerInfo ??
                  {
                    'name': 'IDEV 뷰어',
                    'id': 'viewer_user',
                    'role': 'viewer',
                    'type': 'viewer'
                  };
              _isInitialized = true;
              print('AuthService: 뷰어 인증으로 인증 성공');
              return true;
            }
          }
        }

        // local 환경에서는 임시 인증 허용
        const environment =
            String.fromEnvironment('ENVIRONMENT', defaultValue: 'local');
        print('AuthService: 현재 환경 - $environment');

        // localhost 또는 개발 환경에서 임시 인증 허용
        final currentUrl = html.window.location.href;
        final isLocalhost = currentUrl.contains('localhost') ||
            currentUrl.contains('127.0.0.1') ||
            currentUrl.contains(':49516'); // Flutter 웹 기본 포트

        print('AuthService: 현재 URL - $currentUrl');
        print('AuthService: localhost 감지 - $isLocalhost');

        if (environment == 'local' || isLocalhost) {
          print('AuthService: 개발 환경에서 임시 인증 허용');
          setToken(
              'local_temp_token_${DateTime.now().millisecondsSinceEpoch}'); // 토큰 설정 및 콜백 실행
          _userInfo = {
            'name': '로컬 개발자',
            'id': 'local_user',
            'role': 'developer'
          };
          _isInitialized = true;
          return true;
        }

        // 다른 환경에서는 뷰어 인증이 실패하면 인증 실패
        print('AuthService: 뷰어 인증 실패');
        _isInitialized = true;
        return false;
      }
    } catch (e) {
      print('AuthService: 초기화 오류 - $e');
      setToken(null); // 토큰 제거 및 콜백 실행
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
        print('AuthService: 서버에서 받은 사용자 정보로 업데이트');
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

  /// 현재 토큰 반환
  static String? get token => _token;

  /// 현재 사용자 정보 반환
  static Map<String, dynamic>? get userInfo => _userInfo;

  /// 로그인 상태 확인
  static bool get isAuthenticated => _token != null;

  /// 로그아웃
  static void logout() {
    print('AuthService: 로그아웃 실행');
    setToken(null); // 토큰 제거 및 콜백 실행
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
}
