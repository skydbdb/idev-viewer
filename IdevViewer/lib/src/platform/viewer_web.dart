import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  String _iframeId = '';

  @override
  void initState() {
    super.initState();
    _iframeId = 'idev-viewer-${DateTime.now().millisecondsSinceEpoch}';

    // iframe 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeIframe();
    });
  }

  @override
  void didUpdateWidget(IDevViewerPlatform oldWidget) {
    super.didUpdateWidget(oldWidget);

    // config 변경 시 iframe 업데이트
    if (widget.config.template != oldWidget.config.template && _iframe != null) {
      _sendConfigToIframe();
    }
  }

  /// iframe 초기화
  void _initializeIframe() {
    try {
      print('🎭 [IDevViewerPlatform] iframe 초기화 시작');

      // config를 JSON으로 변환
      final configJson = jsonEncode(widget.config.toJson());
      final encodedConfig = Uri.encodeComponent(configJson);
      final src = '/assets/idev-app/index.html?config=$encodedConfig';

      print('🎭 [IDevViewerPlatform] iframe src: $src');

      // HTML element 먼저 생성
      final container = html.DivElement()
        ..id = _iframeId
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.margin = '0'
        ..style.padding = '0';

      // iframe 생성
      _iframe = html.IFrameElement()
        ..src = src
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.margin = '0'
        ..style.padding = '0';

      // iframe을 container에 추가
      container.append(_iframe!);

      // iframe 로드 리스너
      _iframe!.onLoad.listen((_) {
        print('✅ iframe 로드 완료');
        if (mounted) {
          setState(() {
            _isReady = true;
            _error = null;
          });
          widget.onReady?.call();
        }
      });

      // iframe 에러 리스너
      _iframe!.onError.listen((e) {
        print('❌ iframe 에러: $e');
        if (mounted) {
          setState(() {
            _error = 'Failed to load viewer iframe';
          });
        }
      });

      // container를 body에 추가 (임시)
      html.document.body?.append(container);
      
      print('✅ iframe 초기화 완료 (container ID: $_iframeId)');
    } catch (e) {
      print('❌ iframe 초기화 실패: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize viewer: $e';
        });
      }
    }
  }

  /// iframe에 config 전송
  void _sendConfigToIframe() {
    if (_iframe == null || !_isReady) return;

    try {
      final configJson = jsonEncode(widget.config.toJson());
      final encodedConfig = Uri.encodeComponent(configJson);
      final newSrc = '/assets/idev-app/index.html?config=$encodedConfig';

      // src를 변경하여 iframe 리로드
      _iframe!.src = newSrc;
      print('🔄 iframe src 업데이트: $newSrc');
    } catch (e) {
      print('❌ iframe config 전송 실패: $e');
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

    // HtmlElementView를 사용하여 iframe을 표시
    return HtmlElementView(
      viewType: _iframeId,
    );
  }

  @override
  void dispose() {
    print('🎭 [IDevViewerPlatform] dispose');
    // iframe 정리
    final container = html.document.getElementById(_iframeId);
    container?.remove();
    super.dispose();
  }
}
