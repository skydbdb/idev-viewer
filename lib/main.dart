import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:idev_v1/src/core/auth/viewer_auth_service.dart';
import 'package:pluto_layout/pluto_layout.dart';
import 'src/core/config/env.dart';
import '/src/layout/home/home_board.dart';
import '/src/di/service_locator.dart';
import '/src/repo/home_repo.dart';
import '/src/layout/tabs/tabs.dart';
import '/src/auth/auth_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // AppConfig를 먼저 초기화
  AppConfig.initialize();
  // AppConfig 초기화 완료 후 다른 서비스 초기화
  await Future.delayed(const Duration(milliseconds: 100)); // 초기화 완료 대기
  initServiceLocator();

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

      builder: EasyLoading.init(),
    );
  }

  // 초기 라우트 결정 - 항상 인증 페이지로 이동
  String _getInitialRoute() {
    // test start
    ViewerAuthService.viewerApiKey =
        '7e074a90e6128deeab38d98765e82abe39ec87449f077d7ec85f328357f96b50';
    HomeRepo.isInitialized = true;
    // test end

    // 항상 인증 페이지로 이동
    print('main.dart: 인증 페이지로 이동');
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
          child: // const HomeBoard()
              const PlutoLayout(
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
