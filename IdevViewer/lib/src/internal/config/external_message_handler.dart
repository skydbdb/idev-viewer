import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'external_bridge.dart';
import 'package:idev_viewer/src/internal/core/auth/auth_service.dart';

/// 외부 메시지 타입 정의
enum ExternalMessageType {
  initTemplate('init_template'),
  updateTemplate('update_template'),
  updateConfig('update_config');

  const ExternalMessageType(this.value);
  final String value;
}

/// 외부 메시지 데이터 클래스
class ExternalMessage {
  final ExternalMessageType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  ExternalMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ExternalMessage.fromRawData(dynamic rawData) {
    Map<String, dynamic> data;

    if (rawData is String) {
      data = jsonDecode(rawData);
    } else if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else {
      throw ArgumentError('Invalid message data type: ${rawData.runtimeType}');
    }

    final typeString = data['type']?.toString();
    final type = ExternalMessageType.values
        .where((t) => t.value == typeString)
        .firstOrNull;

    if (type == null) {
      throw ArgumentError('Unknown message type: $typeString');
    }

    return ExternalMessage(
      type: type,
      data: data,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

/// 외부 메시지 핸들러 클래스
class ExternalMessageHandler {
  static PackageInfo? _packageInfo;

  static const Map<String, dynamic> _baseMessageData = {
    'status': 'initialized',
    'capabilities': [
      'template',
      'config',
      'resize',
      'state',
      'api_request',
      'stream_subscription'
    ],
    'availableStreams': [
      'json_menu',
      'api_menu',
      'on_tap',
      'on_edit',
      'api_response'
    ]
  };

  static Map<String, dynamic> get _readyMessageData => {
        ..._baseMessageData,
        'version': _packageInfo?.version ?? '1.0.0',
      };

  static Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      _packageInfo = null;
    }
  }

  /// 외부 메시지 리스너 설정
  static void setupMessageListener() {
    html.window.onMessage.listen(_handleMessage);

    // 뷰어 준비 완료 메시지 전송
    Future.delayed(const Duration(milliseconds: 100), () {
      _sendReadyMessage();
    });
  }

  /// 메시지 처리 메인 로직
  static void _handleMessage(html.MessageEvent event) {
    try {
      final message = ExternalMessage.fromRawData(event.data);
      _processMessage(message);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to process external message: $e');
      }
    }
  }

  /// 메시지 타입별 처리
  static void _processMessage(ExternalMessage message) {
    switch (message.type) {
      case ExternalMessageType.initTemplate:
        _handleInitTemplate(message.data);
        break;
      case ExternalMessageType.updateTemplate:
        _handleTemplateUpdate(message.data);
        break;
      case ExternalMessageType.updateConfig:
        _handleConfigUpdate(message.data);
        break;
    }
  }

  /// 템플릿 초기화 메시지 처리
  static void _handleInitTemplate(Map<String, dynamic> data) {
    _delegateToHomeRepo(data);
  }

  /// 템플릿 업데이트 메시지 처리
  static void _handleTemplateUpdate(Map<String, dynamic> data) {
    _delegateToHomeRepo(data);
  }

  /// 설정 업데이트 메시지 처리
  static void _handleConfigUpdate(Map<String, dynamic> data) {
    // API 키 설정 처리
    _processApiKeyConfig(data['config']);

    // HomeRepo로 위임
    _delegateToHomeRepo(data);
  }

  /// API 키 설정 처리
  static void _processApiKeyConfig(dynamic config) {
    if (config is Map && config.containsKey('apiKey')) {
      final apiKey = config['apiKey'] as String?;
      if (apiKey != null && apiKey.isNotEmpty) {
        ExternalBridge.apiKey = apiKey;
        AuthService.setViewerApiKey(apiKey);
        AuthService.initializeViewerAuth();
      }
    }
  }

  /// HomeRepo로 메시지 위임
  static void _delegateToHomeRepo(Map<String, dynamic> data) {
    ExternalBridge.homeRepo?.handleIframeMessage(data);
  }

  /// 뷰어 준비 완료 메시지 전송
  static void _sendReadyMessage() {
    try {
      final readyMessage = {
        'type': 'ready',
        'data': _readyMessageData,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      };

      if (html.window.parent != null) {
        html.window.parent!.postMessage(readyMessage, '*');
      } else {
        _sendMessageToParent({
          'type': 'ready',
          'data': {'status': 'initialized'},
          'timestamp': DateTime.now().millisecondsSinceEpoch
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send ready message: $e');
      }
    }
  }

  /// 폴백 메시지 전송
  static void _sendMessageToParent(Map<String, dynamic> data) {
    try {
      js.context.callMethod('parent.postMessage', [data, '*']);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send message to parent: $e');
      }
    }
  }
}
