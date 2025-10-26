import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;
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
  late String _containerId;
  js.JsObject? _viewer; // JavaScript IdevViewer 인스턴스

  @override
  void initState() {
    super.initState();
    _containerId =
        'idev-viewer-container-${DateTime.now().millisecondsSinceEpoch}';

    // 컨테이너를 HTML에 먼저 추가
    final container = html.DivElement()
      ..id = _containerId
      ..style.width = '100%'
      ..style.height = '100%';

    html.document.body?.append(container);

    // iframe 생성 및 마운트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _createAndMountIframe();
      });
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

  /// JavaScript IdevViewer 라이브러리를 사용하여 뷰어 초기화
  void _createAndMountIframe() {
    try {
      // IdevViewer JavaScript 클래스 확인
      final IdevViewerClass = js.context['IdevViewer'];
      if (IdevViewerClass == null) {
        throw Exception('IdevViewer JavaScript 라이브러리가 로드되지 않았습니다');
      }

      print('✅ IdevViewer 라이브러리 로드 확인');

      // 옵션 객체 생성
      final options = js.JsObject.jsify({
        'width': '100%',
        'height': '600px',
        'idevAppPath': './idev-app/',
        'template': {
          'script': null,
          'templateId': 0,
          'templateNm': widget.config.templateName ?? 'viewer',
          'commitInfo': 'viewer-mode'
        },
        'config': {
          'apiKey':
              '7e074a90e6128deeab38d98765e82abe39ec87449f077d7ec85f328357f96b50',
          'theme': 'dark',
          'locale': 'ko'
        },
        'onReady': js.JsFunction.withThis((that, data) {
          print('✅ 뷰어 준비 완료');
          if (mounted) {
            setState(() {
              _isReady = true;
              _error = null;
            });
            widget.onReady?.call();
          }
        }),
        'onError': js.JsFunction.withThis((that, error) {
          print('❌ 뷰어 에러: $error');
          if (mounted) {
            setState(() {
              _error = error.toString();
            });
          }
        }),
      });

      // IdevViewer 인스턴스 생성
      _viewer = js.JsObject(IdevViewerClass, [options]);

      // 뷰어 마운트
      _viewer?.callMethod('mount', ['#$_containerId']);

      print('✅ IdevViewer 인스턴스 생성 및 마운트 완료');

      // 2초 후 ready 처리 (IdevViewer가 준비될 때까지 대기)
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isReady) {
          print('⏰ Ready 타임아웃, 강제 ready 처리');
          setState(() {
            _isReady = true;
            _error = null;
          });
          widget.onReady?.call();
        }
      });
    } catch (e) {
      print('❌ iframe 생성 실패: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to create iframe: $e';
        });
      }
    }
  }

  /// 템플릿 업데이트
  void _updateTemplate() {
    if (_viewer == null || widget.config.template == null) {
      print('⚠️ _updateTemplate: _viewer=${_viewer != null}, template=${widget.config.template != null}');
      return;
    }

    try {
      final template = js.JsObject.jsify({
        'script': jsonEncode(widget.config.template!['items'] ?? []),
        'templateId': 0,
        'templateNm': widget.config.templateName ?? 'viewer',
        'commitInfo': 'viewer-mode',
      });
      
      print('📝 updateTemplate 호출, script length: ${template['script'].toString().length}');
      _viewer?.callMethod('updateTemplate', [template]);
      print('✅ updateTemplate 호출 완료');
    } catch (e) {
      print('❌ 템플릿 업데이트 실패: $e');
      print('❌ 스택 추적: ${StackTrace.current}');
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

    // viewer container를 HTML로 렌더링
    return HtmlElementView(
      viewType: _containerId,
      onPlatformViewCreated: (int viewId) {
        // 컨테이너 생성 (IdevViewer가 mount할 곳)
        final container = html.DivElement()
          ..id = _containerId
          ..style.width = '100%'
          ..style.height = '100%';

        if (container.parent == null) {
          html.document.body?.append(container);
        }
      },
    );
  }

  @override
  void dispose() {
    print('🎭 [IDevViewer] dispose');

    // IdevViewer 제거
    _viewer?.callMethod('destroy');

    super.dispose();
  }
}
