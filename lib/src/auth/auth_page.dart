import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:idev_v1/src/repo/home_repo.dart';
import '../core/auth/auth_service.dart';
import '../core/auth/viewer_auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late HomeRepo homeRepo;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String _errorMessage = '';

  @override
  void initState() {
    homeRepo = context.read<HomeRepo>();
    super.initState();
    _initializeHomeRepo();
  }

  Future<void> _initializeHomeRepo() async {
    while (!HomeRepo.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
      print('AuthPage: 인증 초기화 중...${HomeRepo.isInitialized}');
    }
    await initializeAuth();
  }

  Future<void> initializeAuth() async {
    try {
      // print('AuthPage: 인증 초기화 시작');

      final isAuthenticated = await AuthService.initializeAuth();

      // 디버그 정보 출력
      AuthService.printDebugInfo();
      ViewerAuthService.printDebugInfo();

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

          // 뷰어 인증 상태 확인
          if (ViewerAuthService.isViewerAuthenticated) {
            print('AuthPage: 뷰어 인증으로 로그인됨');
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
              if (ViewerAuthService.isViewerAuthenticated) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue, width: 1),
                  ),
                  child: const Text(
                    'IDEV 뷰어로 인증됨',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
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
                  initializeAuth();
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
