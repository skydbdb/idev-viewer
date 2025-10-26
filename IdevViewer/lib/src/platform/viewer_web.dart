import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:convert';
import 'dart:async';
import 'dart:ui_web' as ui_web;
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
  Timer? _readyTimeout;

  @override
  void initState() {
    super.initState();

    // JavaScript 전역 변수로 초기화 여부 확인 (Hot Restart에도 유지)
    final hasInitialized = js.context['_idevViewerHasInitialized'] == true;
    final existingViewer = js.context['_idevViewerInstance'];
    final allIframes = html.document.querySelectorAll('iframe');
    final hasIframe = allIframes.isNotEmpty;

    // 고정된 컨테이너 ID 사용 (Hot Restart 시에도 동일)
    _containerId = 'idev-viewer-container-singleton';

    // 이미 한 번 초기화되었거나, 뷰어 인스턴스가 존재하면 재사용
    if (hasInitialized || existingViewer != null || hasIframe) {
      // 생성 플래그 리셋
      js.context['_idevViewerCreating'] = false;
      js.context['_idevViewerMountAttempted'] = false;

      // PlatformView 등록 (이미 등록된 경우 스킵됨)
      _registerPlatformView();

      setState(() {
        _isReady = true;
      });
      widget.onReady?.call();
      return;
    }

    // 첫 번째 초기화 플래그 설정 (JavaScript 전역)
    js.context['_idevViewerHasInitialized'] = true;
    js.context['_idevViewerCreating'] = false;
    js.context['_idevViewerMountAttempted'] = false;

    // PlatformView 등록
    _registerPlatformView();
  }

  /// Platform View 등록 (HTML 요소를 Flutter 위젯으로 표시)
  void _registerPlatformView() {
    // 이미 등록되어 있는지 확인
    if (js.context['_idevPlatformViewRegistered'] == true) {
      return;
    }

    try {
      ui_web.platformViewRegistry.registerViewFactory(
        _containerId,
        (int viewId) {
          final container = html.DivElement()
            ..id = _containerId
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.border = 'none';

          return container;
        },
      );

      // 등록 완료 플래그
      js.context['_idevPlatformViewRegistered'] = true;
    } catch (e) {
      // 이미 등록된 경우 에러 무시
      js.context['_idevPlatformViewRegistered'] = true;
    }
  }

  /// DOM 컨테이너가 준비될 때까지 기다린 후 마운트
  Future<void> _waitForContainerAndMount(js.JsObject viewer) async {
    const maxAttempts = 50; // 5초 (50 × 100ms)
    const delayMs = 100;

    for (int i = 0; i < maxAttempts; i++) {
      final container = html.document.getElementById(_containerId);

      if (container != null) {
        // 약간의 추가 지연 (DOM이 완전히 준비되도록)
        await Future.delayed(const Duration(milliseconds: 100));

        try {
          viewer.callMethod('mount', ['#$_containerId']);
          return;
        } catch (e) {
          if (mounted) {
            setState(() {
              _error = '마운트 실패: $e';
            });
          }
          return;
        }
      }

      await Future.delayed(const Duration(milliseconds: delayMs));
    }

    // 타임아웃
    if (mounted) {
      setState(() {
        _error = '컨테이너를 찾을 수 없습니다 (ID: $_containerId)';
      });
    }
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
    // 이미 생성 중이면 중복 호출 방지
    if (js.context['_idevViewerCreating'] == true) {
      return;
    }

    js.context['_idevViewerCreating'] = true;

    try {
      // Hot reload 시 이전 IdevViewer 인스턴스 제거
      final existingViewer = js.context['_idevViewerInstance'];
      if (existingViewer != null) {
        try {
          existingViewer.callMethod('destroy');
        } catch (e) {
          // destroy 실패 무시
        }
        js.context['_idevViewerInstance'] = null;
      }

      // 모든 iframe 제거
      final existingIframes = html.document.querySelectorAll('iframe');
      for (final iframe in existingIframes) {
        iframe.remove();
      }

      // 컨테이너 내부 정리
      final container = html.document.getElementById(_containerId);
      if (container != null) {
        container.innerHtml = '';
      }

      // IdevViewer JavaScript 클래스 확인
      final IdevViewerClass = js.context['IdevViewer'];
      if (IdevViewerClass == null) {
        // Hot Restart로 인한 두 번째 초기화 시도 - ready 상태로 설정
        if (mounted) {
          setState(() {
            _isReady = true;
          });
          widget.onReady?.call();
        }
        return;
      }

      // 옵션 객체 생성
      final options = js.JsObject.jsify({
        'width': '100%',
        'height': '600px',
        'idevAppPath':
            '/assets/packages/idev_viewer/assets/idev-app/index.html',
        'autoCreateIframe': true,
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
          if (mounted) {
            // 이미 ready 상태면 중복 setState 방지
            if (_isReady) {
              return;
            }

            // 타임아웃 타이머 취소
            _readyTimeout?.cancel();
            _readyTimeout = null;

            // 생성 완료 플래그 해제
            js.context['_idevViewerCreating'] = false;

            final viewer = js.context['_idevViewerInstance'];
            if (viewer != null) {
              try {
                viewer['isReady'] = true;
              } catch (e) {
                // isReady 설정 실패 무시
              }
            }

            setState(() {
              _isReady = true;
              _error = null;
            });

            widget.onReady?.call();
          }
        }),
        'onError': js.JsFunction.withThis((that, error) {
          if (mounted) {
            setState(() {
              _error = error.toString();
            });
          }
        }),
      });

      // IdevViewer 인스턴스 생성
      final viewer = js.JsObject(IdevViewerClass, [options]);

      // JavaScript 전역 변수에 저장 (Dart 재시작에도 유지)
      js.context['_idevViewerInstance'] = viewer;

      // DOM 요소가 준비될 때까지 기다린 후 마운트
      _waitForContainerAndMount(viewer);

      // 10초 후 ready 처리 (IdevViewer가 준비될 때까지 대기)
      _readyTimeout = Timer(const Duration(seconds: 10), () {
        if (mounted && !_isReady) {
          setState(() {
            _isReady = true;
            _error = null;
          });
          widget.onReady?.call();
        }

        // 생성 완료 플래그 해제
        js.context['_idevViewerCreating'] = false;
      });
    } catch (e) {
      // 생성 실패 시에도 플래그 해제
      js.context['_idevViewerCreating'] = false;

      if (mounted) {
        setState(() {
          _error = 'Failed to create iframe: $e';
        });
      }
    }
  }

  /// 템플릿 업데이트
  void _updateTemplate() {
    final viewer = js.context['_idevViewerInstance'];

    if (viewer == null || widget.config.template == null) {
      return;
    }

    try {
      // widget.config.template이 {items: [...]} 형태라면 items만 추출
      // 이미 배열이라면 그대로 사용
      final scriptData = widget.config.template is List
          ? widget.config.template
          : widget.config.template!['items'] ?? [];

      // 배열을 JSON 문자열로 변환
      final scriptString = jsonEncode(scriptData);

      final template = js.JsObject.jsify({
        'script': scriptString,
        'templateId':
            'test_template_update_${DateTime.now().millisecondsSinceEpoch}',
        'templateNm': widget.config.templateName ?? 'viewer',
        'commitInfo': 'viewer-mode',
      });

      viewer.callMethod('updateTemplate', [template]);
    } catch (e) {
      // 템플릿 업데이트 실패 무시
    }
  }

  @override
  Widget build(BuildContext context) {
    // 첫 빌드 후 iframe 생성 (PlatformView가 렌더링된 후)
    if (!_isReady &&
        js.context['_idevViewerHasInitialized'] == true &&
        js.context['_idevViewerMountAttempted'] != true) {
      js.context['_idevViewerMountAttempted'] = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _createAndMountIframe();
        });
      });
    }

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

    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          // iframe 컨테이너 (항상 렌더링)
          HtmlElementView(
            viewType: _containerId,
          ),

          // 로딩 오버레이 (준비되지 않았을 때만 표시)
          if (!_isReady)
            widget.loadingWidget ??
                Container(
                  color: Colors.grey[100]?.withOpacity(0.95) ??
                      Colors.grey.withOpacity(0.95),
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
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 타임아웃 타이머 취소
    _readyTimeout?.cancel();
    _readyTimeout = null;

    super.dispose();
  }
}
