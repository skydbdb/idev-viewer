import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/viewer_config.dart';
import '../models/viewer_event.dart';

/// Web 플랫폼 구현 (iframe 기반)
///
/// idev-app을 iframe으로 로드하여 렌더링합니다.
/// Internal 코드는 assets/idev-app에 컴파일된 형태로만 포함됩니다.
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
  html.IFrameElement? _iframe;

  @override
  void initState() {
    super.initState();

    // iframe 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeIframe();
    });
  }

  /// iframe 초기화
  void _initializeIframe() {
    try {
      // config를 JSON으로 변환
      final configJson = jsonEncode(widget.config.toJson());
      final encodedConfig = Uri.encodeComponent(configJson);

      // iframe 생성
      _iframe = html.IFrameElement()
        ..src = '/assets/idev-app/index.html?config=$encodedConfig'
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..id = 'idev-viewer-iframe';

      // iframe 로드 리스너
      _iframe!.onLoad.listen((_) {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
          widget.onReady?.call();
        }
      });

      // iframe 에러 리스너
      _iframe!.onError.listen((e) {
        if (mounted) {
          setState(() {
            _error = 'Failed to load viewer: $e';
          });
        }
      });

      print('✅ iframe 초기화 완료');
    } catch (e) {
      print('❌ iframe 초기화 실패: $e');
      setState(() {
        _error = 'Failed to initialize viewer: $e';
      });
    }
  }

  @override
  void didUpdateWidget(IDevViewerPlatform oldWidget) {
    super.didUpdateWidget(oldWidget);

    // config가 변경되면 iframe 재로드
    if (widget.config.template != oldWidget.config.template) {
      _updateIframeConfig();
    }
  }

  /// iframe 설정 업데이트
  void _updateIframeConfig() {
    if (_iframe == null) return;

    final configJson = jsonEncode(widget.config.toJson());
    final encodedConfig = Uri.encodeComponent(configJson);

    _iframe!.src = '/assets/idev-app/index.html?config=$encodedConfig';
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

    // iframe 뷰
    return HtmlElementView(
      viewType: 'idev-viewer',
      onPlatformViewCreated: (int viewId) {
        // iframe을 DOM에 추가
        if (_iframe != null) {
          html.document.getElementById('idev-viewer')?.append(_iframe!);
        }
      },
    );
  }

  @override
  void dispose() {
    // iframe 정리
    _iframe?.remove();
    super.dispose();
  }
}
