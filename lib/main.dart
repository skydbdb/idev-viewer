import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:pluto_layout/pluto_layout.dart';
import 'package:flutter/foundation.dart';
import 'src/core/config/env.dart';
import '/src/layout/home/home_board.dart';
import '/src/di/service_locator.dart';
import '/src/repo/home_repo.dart';
import '/src/layout/tabs/tabs.dart';
import '/src/board/board/viewer/template_viewer_page.dart';
import '/src/auth/auth_page.dart';
import '/src/web/iframe_communication.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.initialize();
  initServiceLocator();

  // iframe 통신 초기화 (임시 비활성화 - 인증 문제 해결 후 활성화)
  // IframeCommunication.initialize();

  runApp(
    RepositoryProvider(
      create: (context) => HomeRepo(),
      child: const IDevViewerApp(),
    ),
  );
}

class IDevViewerApp extends StatelessWidget {
  const IDevViewerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(fontFamily: 'SpoqaHanSansNeo', useMaterial3: false),
      darkTheme: ThemeData.dark(),
      initialRoute: _getInitialRoute(), // 동적으로 초기 라우트 결정
      routes: {
        '/auth': (context) => const AuthPage(),
        '/': (context) => const HomePage(), // HomePage로 변경
      },
      onGenerateRoute: (settings) {
        // 템플릿 뷰어 라우트 처리 (POST 방식)
        if (settings.name?.startsWith('/template/') == true) {
          final templateId = settings.name!.split('/').last;

          // URL 파라미터에서 POST 데이터 추출
          Map<String, dynamic>? postData;

          // 1. settings.arguments에서 확인
          if (settings.arguments is Map<String, dynamic>) {
            postData = settings.arguments as Map<String, dynamic>;
          }

          // 2. URL 쿼리 파라미터에서 확인 (더 강화된 파싱)
          if (settings.name!.contains('?')) {
            try {
              final uri = Uri.parse(settings.name!);
              final queryParams = uri.queryParameters;
              if (queryParams.isNotEmpty) {
                postData = Map<String, dynamic>.from(queryParams);
              }
            } catch (e) {
              // 에러 처리
            }
          }

          // 3. 전체 URL에서 직접 파라미터 파싱
          if (postData == null) {
            try {
              final fullUrl = settings.name!;
              if (fullUrl.contains('?')) {
                final questionIndex = fullUrl.indexOf('?');
                final queryString = fullUrl.substring(questionIndex + 1);
                final params = queryString.split('&');

                postData = <String, dynamic>{};
                for (final param in params) {
                  final parts = param.split('=');
                  if (parts.length == 2) {
                    final key = Uri.decodeComponent(parts[0]);
                    final value = Uri.decodeComponent(parts[1]);
                    postData[key] = value;
                  }
                }
              }
            } catch (e) {
              // 에러 처리
            }
          }

          // 스크립트 데이터 디코딩
          String? decodedScript;
          if (postData?['script'] != null) {
            try {
              final encodedScript = postData!['script'] as String;
              decodedScript = utf8.decode(base64Decode(encodedScript));
            } catch (e) {
              decodedScript = postData!['script'] as String?;
            }
          }

          return MaterialPageRoute(
            builder: (context) => TemplateViewerPage(
              templateId: int.tryParse(templateId) ?? 0,
              templateNm: postData?['templateNm'] as String?,
              script: decodedScript,
              commitInfo: postData?['commitInfo'] as String?,
            ),
          );
        }

        return null;
      },
      builder: EasyLoading.init(),
    );
  }

  /// URL 파라미터를 확인하여 초기 라우트 결정
  String _getInitialRoute() {
    if (kIsWeb) {
      try {
        final uri = Uri.parse(html.window.location.href);
        final token = uri.queryParameters['token'];
        final user = uri.queryParameters['user'];

        // 토큰과 사용자 정보가 있으면 바로 메인 앱으로 이동
        if (token != null && user != null) {
          print('main.dart: URL 파라미터에 토큰과 사용자 정보 발견');
          // AuthService 초기화를 위해 인증 페이지로 이동
          return '/auth';
        }
      } catch (e) {
        print('main.dart: URL 파라미터 파싱 오류: $e');
      }
    }

    // 토큰이 없으면 인증 페이지로 이동
    print('main.dart: 토큰 없음, 인증 페이지로 이동');
    return '/auth';
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
            scrollbars: true,
          ),
          child: const PlutoLayout(
            body: PlutoLayoutContainer(
              child: HomeBoard(),
            ),
            top: PlutoLayoutContainer(
              child: TopTab(),
            ),
            left: PlutoLayoutContainer(
              child: LeftTab(),
            ),
            right: PlutoLayoutContainer(
              child: RightTab(),
            ),
            bottom: PlutoLayoutContainer(
              child: BottomTab(),
            ),
          )),
    );
  }
}
