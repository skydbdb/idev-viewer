// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../models/viewer_config.dart';
import '../models/viewer_event.dart';

/// iframe 안에 있는지 확인
bool _isInsideIframe() {
  try {
    return html.window.self != html.window.top;
  } catch (e) {
    // 크로스 오리진인 경우 에러 발생
    return true;
  }
}

/// Web 플랫폼 구현 (iframe 사용)
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
  final String _viewId = 'idev-viewer-${DateTime.now().millisecondsSinceEpoch}';
  late html.IFrameElement _iframe;
  bool _isReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupIframe();
    _setupMessageListener();
  }

  @override
  void didUpdateWidget(IDevViewerPlatform oldWidget) {
    super.didUpdateWidget(oldWidget);

    // config의 template이 변경되었는지 확인
    if (widget.config.template != oldWidget.config.template &&
        widget.config.template != null) {
      debugPrint('[IDevViewer] Config changed, updating template');

      // React 예제와 동일한 구조로 전송
      final templateData = widget.config.template!;
      final script = templateData['items'] ?? templateData;

      _sendMessage({
        'type': 'update_template',
        'template': {
          'script': script is String ? script : jsonEncode(script),
          'templateId':
              widget.config.templateName ?? 'flutter_template_updated',
          'templateNm':
              widget.config.templateName ?? 'Flutter Template Updated',
          'commitInfo': 'v1.0.1',
        },
      });
    }
  }

  void _setupIframe() {
    // viewer URL 결정 (절대 경로 사용)
    final viewerUrl =
        widget.config.viewerUrl ??
        '/assets/packages/idev_viewer/viewer-app/index.html';

    debugPrint('[IDevViewer] Setting up iframe with URL: $viewerUrl');

    _iframe =
        html.IFrameElement()
          ..src = viewerUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow =
              'accelerometer; camera; encrypted-media; geolocation; gyroscope; microphone';

    // iframe 로드 이벤트 리스너
    _iframe.onLoad.listen((event) {
      debugPrint('[IDevViewer] iframe loaded successfully');
    });

    _iframe.onError.listen((event) {
      debugPrint('[IDevViewer] iframe load error: $event');
      setState(() {
        _error = 'Failed to load viewer application';
      });
    });

    // iframe을 Flutter Web에 등록
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      debugPrint('[IDevViewer] Registering iframe view: $_viewId');
      return _iframe;
    });
  }

  void _setupMessageListener() {
    html.window.onMessage.listen((event) {
      try {
        final data = event.data;
        debugPrint('[IDevViewer] Received message: $data');

        if (data is! Map) {
          debugPrint('[IDevViewer] Message is not a Map, ignoring');
          return;
        }

        final Map<String, dynamic> messageData = Map<String, dynamic>.from(
          data,
        );
        final type = messageData['type'] as String?;

        if (type == null) {
          debugPrint('[IDevViewer] Message type is null, ignoring');
          return;
        }

        debugPrint('[IDevViewer] Processing message type: $type');

        if (type == 'ready') {
          debugPrint('[IDevViewer] Viewer is ready!');
          _handleReady();
        } else {
          _handleEvent(messageData);
        }
      } catch (e) {
        debugPrint('[IDevViewer] Failed to process message from iframe: $e');
      }
    });
  }

  void _handleReady() {
    debugPrint('[IDevViewer] Handling ready event...');

    setState(() {
      _isReady = true;
      _error = null;
    });

    // 템플릿 데이터 전송 (React 예제와 동일한 구조)
    if (widget.config.template != null) {
      debugPrint('[IDevViewer] Sending init_template message');

      // template이 이미 items를 포함한 Map인 경우
      final templateData = widget.config.template!;
      final script = templateData['items'] ?? templateData;

      _sendMessage({
        'type': 'init_template',
        'template': {
          'script': script is String ? script : jsonEncode(script),
          'templateId': widget.config.templateName ?? 'flutter_template',
          'templateNm': widget.config.templateName ?? 'Flutter Template',
          'commitInfo': 'v1.0.0',
        },
      });
    }

    // API 키 설정
    if (widget.config.apiKey != null) {
      debugPrint('[IDevViewer] Sending update_config message');
      _sendMessage({
        'type': 'update_config',
        'config': {'apiKey': widget.config.apiKey},
      });
    }

    debugPrint('[IDevViewer] Calling onReady callback');
    widget.onReady?.call();
  }

  void _handleEvent(Map<String, dynamic> data) {
    final event = IDevEvent.fromJson(data);
    widget.onEvent?.call(event);
  }

  void _sendMessage(Map<String, dynamic> message) {
    try {
      message['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      _iframe.contentWindow?.postMessage(message, '*');
    } catch (e) {
      debugPrint('Failed to send message to iframe: $e');
    }
  }

  /// 템플릿 업데이트 (외부에서 호출 가능)
  void updateTemplate(Map<String, dynamic> template) {
    debugPrint('[IDevViewer] Updating template externally');

    // React 예제와 동일한 구조로 전송
    final script = template['items'] ?? template;

    _sendMessage({
      'type': 'update_template',
      'template': {
        'script': script is String ? script : jsonEncode(script),
        'templateId': 'flutter_template_external',
        'templateNm': 'Flutter Template External Update',
        'commitInfo': 'v1.0.2',
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }

    return Stack(
      children: [
        HtmlElementView(viewType: _viewId),
        if (!_isReady && widget.loadingWidget != null) widget.loadingWidget!,
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
