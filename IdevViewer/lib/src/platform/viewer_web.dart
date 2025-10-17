// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import '../models/viewer_config.dart';
import '../models/viewer_event.dart';

/// Web 플랫폼 구현 (iframe 사용)
///
/// Flutter Web에서 iframe을 통해 IDev Viewer를 렌더링합니다.
/// postMessage API를 사용하여 iframe과 통신합니다.
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
      _updateTemplate(
        template: widget.config.template!,
        templateId: widget.config.templateName ?? 'flutter_template_updated',
        templateName: widget.config.templateName ?? 'Flutter Template Updated',
        commitInfo: 'v1.0.1',
      );
    }
  }

  /// iframe 설정 및 등록
  void _setupIframe() {
    final viewerUrl =
        widget.config.viewerUrl ??
        '/assets/packages/idev_viewer/viewer-app/index.html';

    _iframe =
        html.IFrameElement()
          ..src = viewerUrl
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow =
              'accelerometer; camera; encrypted-media; geolocation; gyroscope; microphone';

    _iframe.onError.listen((_) {
      setState(() {
        _error = 'Failed to load viewer application';
      });
    });

    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      return _iframe;
    });
  }

  /// postMessage 리스너 설정
  void _setupMessageListener() {
    html.window.onMessage.listen((event) {
      try {
        final data = event.data;
        if (data is! Map) return;

        final messageData = Map<String, dynamic>.from(data);
        final type = messageData['type'] as String?;
        if (type == null) return;

        if (type == 'ready') {
          _handleReady();
        } else {
          _handleEvent(messageData);
        }
      } catch (_) {
        // 메시지 처리 실패 시 무시
      }
    });
  }

  /// Viewer 준비 완료 이벤트 처리
  void _handleReady() {
    setState(() {
      _isReady = true;
      _error = null;
    });

    // 템플릿 초기화
    if (widget.config.template != null) {
      _updateTemplate(
        template: widget.config.template!,
        templateId: widget.config.templateName ?? 'flutter_template',
        templateName: widget.config.templateName ?? 'Flutter Template',
        commitInfo: 'v1.0.0',
        messageType: 'init_template',
      );
    }

    // API 키 설정
    if (widget.config.apiKey != null) {
      _sendMessage({
        'type': 'update_config',
        'config': {'apiKey': widget.config.apiKey},
      });
    }

    widget.onReady?.call();
  }

  /// 이벤트 처리
  void _handleEvent(Map<String, dynamic> data) {
    final event = IDevEvent.fromJson(data);
    widget.onEvent?.call(event);
  }

  /// iframe으로 메시지 전송
  void _sendMessage(Map<String, dynamic> message) {
    try {
      message['timestamp'] = DateTime.now().millisecondsSinceEpoch;
      _iframe.contentWindow?.postMessage(message, '*');
    } catch (_) {
      // 메시지 전송 실패 시 무시
    }
  }

  /// 템플릿 메시지 생성 및 전송
  void _updateTemplate({
    required Map<String, dynamic> template,
    required String templateId,
    required String templateName,
    required String commitInfo,
    String messageType = 'update_template',
  }) {
    final script = template['items'] ?? template;

    _sendMessage({
      'type': messageType,
      'template': {
        'script': script is String ? script : jsonEncode(script),
        'templateId': templateId,
        'templateNm': templateName,
        'commitInfo': commitInfo,
      },
    });
  }

  /// 템플릿 업데이트 (외부에서 호출 가능)
  void updateTemplate(Map<String, dynamic> template) {
    _updateTemplate(
      template: template,
      templateId: 'flutter_template_external',
      templateName: 'Flutter Template External Update',
      commitInfo: 'v1.0.2',
    );
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
