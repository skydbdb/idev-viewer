// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../models/viewer_config.dart';
import '../models/viewer_event.dart';

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
  State<IDevViewerPlatform> createState() => _IDevViewerPlatformState();
}

class _IDevViewerPlatformState extends State<IDevViewerPlatform> {
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

  void _setupIframe() {
    // viewer URL 결정
    final viewerUrl = widget.config.viewerUrl ?? 
        'assets/packages/idev_viewer/viewer-app/index.html';

    _iframe = html.IFrameElement()
      ..src = viewerUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'accelerometer; camera; encrypted-media; geolocation; gyroscope; microphone';

    // iframe을 Flutter Web에 등록
    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _iframe,
    );
  }

  void _setupMessageListener() {
    html.window.onMessage.listen((event) {
      try {
        final data = event.data;
        if (data is! Map) return;

        final Map<String, dynamic> messageData = Map<String, dynamic>.from(data);
        final type = messageData['type'] as String?;

        if (type == null) return;

        if (type == 'ready') {
          _handleReady();
        } else {
          _handleEvent(messageData);
        }
      } catch (e) {
        debugPrint('Failed to process message from iframe: $e');
      }
    });
  }

  void _handleReady() {
    setState(() {
      _isReady = true;
      _error = null;
    });

    // 템플릿 데이터 전송
    if (widget.config.template != null) {
      _sendMessage({
        'type': 'init_template',
        'data': widget.config.template,
      });
    }

    // API 키 설정
    if (widget.config.apiKey != null) {
      _sendMessage({
        'type': 'update_config',
        'config': {
          'apiKey': widget.config.apiKey,
        },
      });
    }

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

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }

    return Stack(
      children: [
        HtmlElementView(viewType: _viewId),
        if (!_isReady && widget.loadingWidget != null)
          widget.loadingWidget!,
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

