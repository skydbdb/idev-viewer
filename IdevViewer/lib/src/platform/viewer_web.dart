import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:convert';
import '../models/viewer_config.dart';
import '../models/viewer_event.dart';

/// Web 플랫폼 구현 (iframe 기반)
///
/// idev-app을 iframe으로 로드하여 렌더링합니다.
/// vanilla-example의 접근 방식을 따라 구성합니다.
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
  late String _containerId;

  @override
  void initState() {
    super.initState();
    _containerId =
        'idev-viewer-container-${DateTime.now().millisecondsSinceEpoch}';

    // iframe 생성 및 마운트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createAndMountIframe();
    });
  }

  @override
  void didUpdateWidget(IDevViewerPlatform oldWidget) {
    super.didUpdateWidget(oldWidget);

    // config 변경 시 iframe 업데이트
    if (widget.config.template != oldWidget.config.template && _isReady) {
      _updateTemplate();
    }
  }

  /// iframe 생성 및 마운트
  void _createAndMountIframe() {
    try {
      print('🎭 [IDevViewer] iframe 생성 시작');
      html.window.console.log('Current URL: ${html.window.location.href}');

      // iframe 생성 (vanilla-example 방식)
      // Flutter web 개발 서버에서는 flutter_assets/ 경로 사용
      // 프로덕션 빌드에서는 assets/ 경로 사용
      final idevAppPath = 'flutter_assets/packages/idev_viewer/assets/idev-app/index.html';

      print('🎭 [IDevViewer] idev-app 경로: $idevAppPath');
      print('🎭 [IDevViewer] 현재 URL: ${html.window.location.href}');
      html.window.console.log('IDev app path: $idevAppPath');

      _iframe = html.IFrameElement()
        ..src = idevAppPath
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..style.margin = '0'
        ..style.padding = '0'
        ..allow = 'clipboard-write'
        ..title = 'IDev Viewer'
        ..setAttribute('scrolling', 'no');

      // iframe 로드 리스너
      _iframe!.onLoad.listen((_) {
        print('✅ iframe 로드 완료');
        Future.delayed(const Duration(milliseconds: 500), () {
          _postMessageToIframe('init', widget.config.toJson());
        });
      });

      // iframe 로드 체크 (5초 타임아웃)
      Future.delayed(const Duration(seconds: 5), () {
        if (!_isReady && mounted) {
          print('⏰ iframe 로드 타임아웃');
          html.window.console
              .error('Iframe load timeout. Check src: ${_iframe?.src}');
        }
      });

      // iframe 에러 리스너
      _iframe!.onError.listen((e) {
        print('❌ iframe 에러: $e');
        html.window.console.error('Iframe error: $e');
        if (mounted) {
          setState(() {
            _error = 'Failed to load viewer iframe';
          });
        }
      });

      // 메시지 리스너 등록
      html.window.onMessage.listen(_handleMessage);

      print('✅ iframe 생성 완료');
    } catch (e) {
      print('❌ iframe 생성 실패: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to create iframe: $e';
        });
      }
    }
  }

  /// iframe에 메시지 전송
  void _postMessageToIframe(String type, [Map<String, dynamic>? data]) {
    if (_iframe == null) return;

    try {
      final message = {
        'type': type,
        'data': data,
      };
      _iframe!.contentWindow?.postMessage(jsonEncode(message), '*');
      print('📤 iframe에 메시지 전송: $type');
    } catch (e) {
      print('❌ 메시지 전송 실패: $e');
    }
  }

  /// 메시지 수신 처리
  void _handleMessage(html.MessageEvent event) {
    try {
      if (event.source != _iframe?.contentWindow) return;

      final data = jsonDecode(event.data as String);
      final type = data['type'] as String?;

      print('📥 iframe 메시지 수신: $type');

      switch (type) {
        case 'ready':
          _handleReady(data['data']);
          break;
        case 'error':
          _handleError(data['data']);
          break;
        default:
          print('⚠️ 알 수 없는 메시지 타입: $type');
      }
    } catch (e) {
      print('❌ 메시지 처리 실패: $e');
    }
  }

  /// ready 메시지 처리
  void _handleReady(dynamic data) {
    print('✅ iframe ready 수신');
    if (mounted) {
      setState(() {
        _isReady = true;
        _error = null;
      });
      widget.onReady?.call();

      // 초기 템플릿 설정
      if (widget.config.template != null) {
        _updateTemplate();
      }
    }
  }

  /// error 메시지 처리
  void _handleError(dynamic data) {
    print('❌ iframe error 수신: $data');
    if (mounted) {
      setState(() {
        _error = data?.toString() ?? 'Viewer error';
      });
    }
    widget.onEvent?.call(IDevEvent(
      type: 'error',
      data: data,
    ));
  }

  /// 템플릿 업데이트
  void _updateTemplate() {
    if (_iframe == null || widget.config.template == null) return;

    try {
      final template = {
        'script': jsonEncode(widget.config.template!['items'] ?? []),
        'templateId': 0,
        'templateNm': widget.config.templateName ?? 'viewer',
        'commitInfo': 'viewer-mode',
      };

      _postMessageToIframe('updateTemplate', template);
      print('📝 템플릿 업데이트 전송');
    } catch (e) {
      print('❌ 템플릿 업데이트 실패: $e');
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

    // iframe을 표시할 HTML element view
    return HtmlElementView(
      viewType: _containerId,
      onPlatformViewCreated: (int viewId) {
        // iframe을 DOM에 추가
        final container =
            html.document.getElementById(_containerId) ?? html.DivElement()
              ..id = _containerId;

        if (_iframe != null && container.children.isEmpty) {
          container.append(_iframe!);
          html.document.body?.append(container);
          print('✅ iframe DOM에 추가됨');
        }
      },
    );
  }

  @override
  void dispose() {
    print('🎭 [IDevViewer] dispose');

    // 메시지 리스너 제거
    html.window.onMessage.drain();

    // iframe 제거
    final container = html.document.getElementById(_containerId);
    container?.remove();

    super.dispose();
  }
}
