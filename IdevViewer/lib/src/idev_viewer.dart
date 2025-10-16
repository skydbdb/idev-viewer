import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'models/template.dart';
import 'models/config.dart';
import 'models/viewer_options.dart';

/// IDev 뷰어 위젯
///
/// Android, iOS, Web, Windows 모든 플랫폼에서 동일한 렌더링을 제공하는 뷰어입니다.
/// 기존 idev-viewer-js의 모든 기능을 Flutter에서 사용할 수 있습니다.
class IdevViewer extends StatefulWidget {
  /// 템플릿 데이터
  final Template? template;

  /// 설정 정보
  final Config config;

  /// 뷰어 너비
  final double width;

  /// 뷰어 높이
  final double height;

  /// 뷰어 준비 완료 콜백
  final Function(Map<String, dynamic>)? onReady;

  /// 에러 발생 콜백
  final Function(String)? onError;

  /// 템플릿 업데이트 콜백
  final Function(Map<String, dynamic>)? onTemplateUpdate;

  /// 아이템 탭 콜백
  final Function(Map<String, dynamic>)? onItemTap;

  const IdevViewer({
    super.key,
    this.template,
    this.config = const Config(),
    this.width = 300.0,
    this.height = 200.0,
    this.onReady,
    this.onError,
    this.onTemplateUpdate,
    this.onItemTap,
  });

  @override
  _IdevViewerState createState() => _IdevViewerState();
}

class _IdevViewerState extends State<IdevViewer> {
  static const MethodChannel _channel = MethodChannel('idev_viewer');

  int? _viewId;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _setupMethodCallHandler();
    _createView();
  }

  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onReady':
          final data = call.arguments['data'] as Map<String, dynamic>;
          _isReady = true;
          widget.onReady?.call(data);
          break;
        case 'onError':
          final error = call.arguments['error'] as String;
          widget.onError?.call(error);
          break;
        case 'onTemplateUpdate':
          final template = call.arguments['template'] as Map<String, dynamic>;
          widget.onTemplateUpdate?.call(template);
          break;
        case 'onItemTap':
          final item = call.arguments['item'] as Map<String, dynamic>;
          widget.onItemTap?.call(item);
          break;
      }
    });
  }

  void _createView() {
    _viewId = DateTime.now().millisecondsSinceEpoch;

    final options = ViewerOptions(
      width: widget.width,
      height: widget.height,
      template: widget.template,
      config: widget.config,
    );

    _channel.invokeMethod('createView', {
      'viewId': _viewId,
      'width': widget.width,
      'height': widget.height,
      'options': options.toJson(),
    });
  }

  /// 템플릿 업데이트
  void updateTemplate(Template template) {
    if (_viewId != null) {
      _channel.invokeMethod('updateTemplate', {
        'viewId': _viewId,
        'template': template.toJson(),
      });
    }
  }

  /// 설정 업데이트
  void updateConfig(Config config) {
    if (_viewId != null) {
      _channel.invokeMethod('updateConfig', {
        'viewId': _viewId,
        'config': config.toJson(),
      });
    }
  }

  @override
  void didUpdateWidget(IdevViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.template != oldWidget.template) {
      updateTemplate(widget.template!);
    }

    if (widget.config != oldWidget.config) {
      updateConfig(widget.config);
    }
  }

  @override
  void dispose() {
    if (_viewId != null) {
      _channel.invokeMethod('destroyView', {'viewId': _viewId});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_viewId == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildPlatformSpecificView(),
      ),
    );
  }

  Widget _buildPlatformSpecificView() {
    if (kIsWeb) {
      return _buildWebView();
    } else if (Platform.isAndroid) {
      return _buildAndroidView();
    } else if (Platform.isIOS) {
      return _buildIOSView();
    } else if (Platform.isWindows) {
      return _buildWindowsView();
    } else {
      return Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Unsupported Platform',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                Platform.operatingSystem,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildWebView() {
    // Web 플랫폼용 구현
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Web Platform Viewer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              '(Implementation in progress)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidView() {
    return AndroidView(
      viewType: 'idev_viewer',
      creationParams: {
        'viewId': _viewId,
        'width': widget.width,
        'height': widget.height,
        'options': ViewerOptions(
          width: widget.width,
          height: widget.height,
          template: widget.template,
          config: widget.config,
        ).toJson(),
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  Widget _buildIOSView() {
    return UiKitView(
      viewType: 'idev_viewer',
      creationParams: {
        'viewId': _viewId,
        'width': widget.width,
        'height': widget.height,
        'options': ViewerOptions(
          width: widget.width,
          height: widget.height,
          template: widget.template,
          config: widget.config,
        ).toJson(),
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  Widget _buildWindowsView() {
    // Windows 플랫폼용 구현
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.desktop_windows, size: 48, color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Windows Platform Viewer',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              '(Implementation in progress)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
