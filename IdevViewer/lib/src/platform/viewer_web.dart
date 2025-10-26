import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/viewer_config.dart';
import '../models/viewer_event.dart';
import '../internal/board/board/viewer/template_viewer_page.dart';
import '../internal/pms/di/service_locator.dart';
import '../internal/repo/home_repo.dart';
import '../internal/core/api/api_endpoint_ide.dart';
import '../internal/core/auth/auth_service.dart';
import '../internal/core/config/env.dart';
import 'dart:convert';

/// Web 플랫폼 구현 (internal 코드 직접 사용)
///
/// Flutter Web에서 internal 코드를 직접 사용하여 IDev Viewer를 렌더링합니다.
/// TemplateViewerPage를 사용하여 100% 동일한 렌더링을 보장합니다.
class IDevViewerPlatform extends StatefulWidget {
  final IDevConfig config;
  final VoidCallback? onReady;
  final Function(IDevEvent)? onEvent;
  final Widget? loadingWidget;
  final Widget Function(String error)? errorBuilder;

  const IDevViewerPlatform({
    super.key,
    required this.config,
    this.onReady,
    this.onEvent,
    this.loadingWidget,
    this.errorBuilder,
  });

  @override
  State<IDevViewerPlatform> createState() => IDevViewerPlatformState();
}

class IDevViewerPlatformState extends State<IDevViewerPlatform> {
  bool _isReady = false;
  String? _error;
  String? _currentScript;
  bool _apisInitialized = false;
  bool _paramsInitialized = false;
  static const int versionId = 7;
  static const int domainId = 10001;

  @override
  void initState() {
    super.initState();

    // 위젯 트리 빌드 완료 후 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeViewer();
    });
  }

  /// 뷰어 초기화
  Future<void> _initializeViewer() async {
    try {
      // AppConfig 초기화
      AppConfig.initialize();

      // Service Locator 초기화
      initViewerServiceLocator();

      // 뷰어 API 키 설정
      const apiKey =
          '7e074a90e6128deeab38d98765e82abe39ec87449f077d7ec85f328357f96b50';
      AuthService.setViewerApiKey(apiKey);

      // 뷰어 인증 초기화
      await AuthService.initializeViewerAuth();

      // API 및 파라미터 초기화
      final homeRepo = sl<HomeRepo>();

      homeRepo.versionId = versionId;
      homeRepo.domainId = domainId;

      // API 초기화
      homeRepo.reqIdeApi('get', ApiEndpointIDE.apis);
      homeRepo.reqIdeApi('get', ApiEndpointIDE.params);

      // API 응답 스트림 구독
      homeRepo.getApiIdResponseStream.listen((response) {
        if (response != null) {
          final apiId = response['if_id']?.toString();

          if (apiId == ApiEndpointIDE.apis && !_apisInitialized) {
            _apisInitialized = true;
            _checkAndLoadTemplate();
          } else if (apiId == ApiEndpointIDE.params && !_paramsInitialized) {
            _paramsInitialized = true;
            _checkAndLoadTemplate();
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize viewer: $e';
      });
    }
  }

  /// APIs와 Params 초기화가 완료되면 템플릿 로드
  void _checkAndLoadTemplate() {
    if (_apisInitialized && _paramsInitialized) {
      setState(() {
        _isReady = true;
        _error = null;
      });

      // 준비 완료 콜백 호출
      widget.onReady?.call();
    }
  }

  @override
  void didUpdateWidget(IDevViewerPlatform oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 초기화가 완료된 후에만 템플릿 업데이트 처리
    if (!_isReady) return;

    // 템플릿이 null이고 _currentScript가 null이면 업데이트 건너뛰기
    if (widget.config.template == null && _currentScript == null) return;

    // config의 template이 실제로 변경되었는지 확인
    final templateChanged = widget.config.template != oldWidget.config.template;

    if (templateChanged && widget.config.template != null) {
      _updateTemplate(widget.config.template!);
    }
  }

  /// 템플릿 업데이트 - 템플릿 데이터를 JSON 스크립트로 변환
  void _updateTemplate(Map<String, dynamic> template) {
    try {
      // 템플릿 데이터에서 items 배열 추출
      final items = template['items'] as List<dynamic>? ?? [];

      // items 배열만 JSON으로 변환
      final script = jsonEncode(items);

      setState(() {
        _currentScript = script;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to update template: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }

    if (_error != null) {
      return Container(
        color: Colors.red[50],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, color: Colors.red[600], size: 48),
              const SizedBox(height: 16),
              Text(
                '뷰어 로드 실패',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.red[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isReady || _currentScript == null) {
      return widget.loadingWidget ??
          Container(
            color: Colors.grey[100],
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('뷰어 로딩 중...'),
                ],
              ),
            ),
          );
    }

    // TemplateViewerPage를 사용하여 100% 동일한 렌더링 보장
    // GetIt에서 등록된 싱글톤 HomeRepo를 사용 (apis 맵 공유)
    return Provider<HomeRepo>(
      create: (_) => sl<HomeRepo>(),
      child: TemplateViewerPage(
        templateId: 0,
        templateNm: widget.config.templateName ?? 'viewer',
        script: _currentScript!,
        commitInfo: 'viewer-mode',
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
