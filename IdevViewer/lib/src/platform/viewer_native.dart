import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/viewer_config.dart';
import '../models/viewer_event.dart';

/// Native 플랫폼 구현 (Android, iOS, Desktop)
/// 
/// 현재는 간단한 메시지를 표시하고, 실제 구현은 WebView를 통해 이루어집니다.
/// WebView 패키지 (webview_flutter 등)를 추가하여 확장할 수 있습니다.
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
  bool _isReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 초기화 로직
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isReady = true;
      });

      widget.onReady?.call();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(_error!);
    }

    if (!_isReady && widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    // 현재는 간단한 플레이스홀더
    // 실제 구현에서는 webview_flutter 등을 사용하여 
    // assets에 있는 viewer-app을 로드합니다
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phonelink,
                size: 64,
                color: Colors.white70,
              ),
              const SizedBox(height: 24),
              Text(
                'IDev Viewer',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Native 플랫폼 지원 준비 중',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.config.template != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Template Data:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        const JsonEncoder.withIndent('  ')
                            .convert(widget.config.template),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

