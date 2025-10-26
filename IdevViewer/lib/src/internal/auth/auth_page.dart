import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import '../core/auth/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // print('AuthPage: 인증 초기화 시작');

      // URL 파라미터 확인
      if (kIsWeb) {
        final uri = Uri.parse(html.window.location.href);
        print('AuthPage: 현재 URL - ${html.window.location.href}');
        print('AuthPage: URL 파라미터 - ${uri.queryParameters}');
      }

      final isAuthenticated = await AuthService.initializeAuth();

      // 디버그 정보 출력
      AuthService.printDebugInfo();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isAuthenticated = isAuthenticated;
        });

        if (isAuthenticated) {
          // 토큰을 HomeRepo와 동기화
          final token = AuthService.token;
          if (token != null) {
            print('AuthPage: 인증 성공 - ${token.substring(0, 20)}...');
          }

          // print('AuthPage: 인증 성공! 메인 앱으로 이동');
          // 메인 앱으로 이동
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/');
          });
        } else {
          setState(() {
            _errorMessage = '인증에 실패했습니다. 다시 시도해주세요.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '인증 중 오류가 발생했습니다: $e';
        });
      }
    }
  }

  // void _openIdevWebsite() {
  //   HapticFeedback.lightImpact();
  //   if (kIsWeb) {
  //     html.window.open('https://idev.biz', '_blank');
  //   }
  // }

  // void _retryAuth() {
  //   HapticFeedback.lightImpact();
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = '';
  //   });
  //   _initializeAuth();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading) ...[
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 20),
              const Text(
                '인증 확인 중...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ] else if (_isAuthenticated) ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 20),
              const Text(
                '인증 성공!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ] else ...[
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = '';
                  });
                  _initializeAuth();
                },
                child: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
