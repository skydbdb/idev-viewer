import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/viewer_config.dart';
import '../models/viewer_event.dart';
import '../internal/board/board/viewer/template_viewer_page.dart';
import '../internal/pms/di/service_locator.dart';
import '../internal/repo/home_repo.dart';
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

  @override
  void initState() {
    super.initState();
    print('🎭 [IDevViewerPlatform] initState 시작');

    // 위젯 트리 빌드 완료 후 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeViewer();
    });
  }

  /// 뷰어 초기화
  Future<void> _initializeViewer() async {
    print('🎭 [IDevViewerPlatform] 뷰어 초기화 시작');

    try {
      // Service Locator 초기화
      initViewerServiceLocator();

      // 템플릿 데이터가 있으면 스크립트로 변환
      if (widget.config.template != null) {
        print('🎭 [IDevViewerPlatform] 초기 템플릿 로드');
        _updateTemplate(widget.config.template!);
      }

      setState(() {
        _isReady = true;
        _error = null;
      });

      // 준비 완료 콜백 호출
      widget.onReady?.call();

      print('🎭 [IDevViewerPlatform] 뷰어 초기화 완료');
    } catch (e) {
      print('❌ [IDevViewerPlatform] 뷰어 초기화 실패: $e');
      setState(() {
        _error = 'Failed to initialize viewer: $e';
      });
    }
  }

  @override
  void didUpdateWidget(IDevViewerPlatform oldWidget) {
    super.didUpdateWidget(oldWidget);

    print('🔄 didUpdateWidget 호출됨');
    print('🔄 이전 템플릿: ${oldWidget.config.template}');
    print('🔄 새 템플릿: ${widget.config.template}');
    print(
        '🔄 템플릿 변경 감지: ${widget.config.template != oldWidget.config.template}');

    // config의 template이 변경되었는지 확인
    if (widget.config.template != oldWidget.config.template &&
        widget.config.template != null) {
      print('🔄 템플릿 업데이트 시작');
      _updateTemplate(widget.config.template!);
    }
  }

  /// 템플릿 업데이트 - 템플릿 데이터를 JSON 스크립트로 변환
  void _updateTemplate(Map<String, dynamic> template) {
    print('🔄 _updateTemplate 호출됨');
    print('🔄 템플릿 데이터: $template');

    try {
      // 템플릿 데이터에서 items 배열 추출
      final items = template['items'] as List<dynamic>? ?? [];
      print('🔄 아이템 개수: ${items.length}');

      // items 배열만 JSON으로 변환
      final script = jsonEncode(items);
      print('🔄 스크립트 변환 완료: ${script.length} 문자');

      setState(() {
        _currentScript = script;
      });

      print('🔄 setState 호출 완료');
    } catch (e) {
      print('❌ 템플릿 업데이트 실패: $e');
      setState(() {
        _error = 'Failed to update template: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🎭 [IDevViewerPlatform] build 호출 - _isReady: $_isReady');

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

    if (!_isReady) {
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
    return Provider<HomeRepo>(
      create: (_) => HomeRepo(),
      child: TemplateViewerPage(
        templateId: 0,
        templateNm: widget.config.templateName ?? 'viewer',
        script: _currentScript,
        commitInfo: 'viewer-mode',
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
