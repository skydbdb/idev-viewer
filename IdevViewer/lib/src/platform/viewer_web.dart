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

  @override
  void initState() {
    super.initState();

    print('🎬 initState 호출됨');

    // JavaScript 전역 변수에서 뷰어 인스턴스 확인 (Dart 재시작에도 유지)
    final existingViewer = js.context['_idevViewerInstance'];
    
    // 모든 iframe 확인 (더 광범위한 검색)
    final allIframes = html.document.querySelectorAll('iframe');
    final hasIframe = allIframes.isNotEmpty;

    print(
        '  - JS _idevViewerInstance: ${existingViewer != null ? 'exist' : 'null'}');
    print('  - Total iframes: ${allIframes.length}');
    if (allIframes.isNotEmpty) {
      for (var iframe in allIframes) {
        print('    - iframe id: ${iframe.id}, src: ${iframe.getAttribute('src')}');
      }
    }
    print(
        '  - IdevViewer class: ${js.context['IdevViewer'] != null ? 'exist' : 'null'}');

    // React의 useRef 패턴: 이미 뷰어가 존재하거나 iframe이 있으면 재사용
    if (existingViewer != null || hasIframe) {
      print('♻️ 기존 뷰어/iframe 재사용 (중복 초기화 방지)');
      setState(() {
        _isReady = true;
      });
      widget.onReady?.call();
      return;
    }

    print('🆕 새 뷰어 인스턴스 생성 시작');

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
      // Hot reload 시 이전 iframe 제거
      final existingViewer = js.context['_idevViewerInstance'];
      if (existingViewer != null) {
        print('🗑️ 기존 IdevViewer 인스턴스 제거');
        js.context['_idevViewerInstance'] = null;
      }

      final existingIframes = html.document.querySelectorAll('iframe');
      for (final iframe in existingIframes) {
        if (iframe.id.contains('idev-viewer-')) {
          print('🗑️ 기존 iframe 제거: ${iframe.id}');
          iframe.remove();
        }
      }

      // IdevViewer JavaScript 클래스 확인
      print('🔍 IdevViewer 클래스 확인 중...');

      final IdevViewerClass = js.context['IdevViewer'];
      if (IdevViewerClass == null) {
        print('❌ IdevViewer 클래스가 없습니다.');
        throw Exception('IdevViewer JavaScript 라이브러리가 로드되지 않았습니다');
      }

      print('✅ IdevViewer 라이브러리 로드 확인');

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
          print('✅ 뷰어 준비 완료');
          if (mounted) {
            final viewer = js.context['_idevViewerInstance'];
            if (viewer != null) {
              // IdevViewer의 isReady도 강제로 true로 설정
              try {
                // JsObject에서 속성 설정
                viewer['isReady'] = true;
                print('✅ IdevViewer.isReady를 true로 설정');
              } catch (e) {
                print('⚠️ isReady 설정 실패: $e');
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
          print('❌ 뷰어 에러: $error');
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

      print('🔍 뷰어 인스턴스 생성 완료, JavaScript 전역에 저장, mount 시도...');

      // 뷰어 마운트
      viewer.callMethod('mount', ['#$_containerId']);

      print('🔍 mount 호출 완료');

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
    final viewer = js.context['_idevViewerInstance'];

    if (viewer == null || widget.config.template == null) {
      print(
          '⚠️ _updateTemplate: viewer=${viewer != null}, template=${widget.config.template != null}');
      return;
    }

    try {
      // vanilla-example 패턴을 따름
      // script를 문자열로 변환 (JSON.stringify와 동일)
      final scriptData = widget.config.template!['items'] ?? [];
      final template = js.JsObject.jsify({
        'script': jsonEncode(scriptData), // 이미 JSON 문자열
        'templateId':
            'test_template_update_${DateTime.now().millisecondsSinceEpoch}',
        'templateNm': widget.config.templateName ?? 'viewer',
        'commitInfo': 'viewer-mode',
      });

      print('🔍 template 객체 생성 완료');
      print('  - script length: ${template['script'].toString().length}');
      print('  - templateId: ${template['templateId']}');
      print('  - templateNm: ${template['templateNm']}');

      print(
          '📝 updateTemplate 호출, script length: ${template['script'].toString().length}');
      print('🔍 viewer 정보: ${viewer != null ? 'exist' : 'null'}');

      try {
        print('🔍 viewer.callMethod 시도...');
        viewer.callMethod('updateTemplate', [template]);
        print('✅ updateTemplate 호출 완료');

        // 디버깅: 생성된 template 객체 확인
        print('🔍 template 내용: $template');
      } catch (e) {
        print('❌ callMethod 실패: $e');
        print('❌ 상세: ${StackTrace.current}');
      }
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

    // HTML body에 직접 추가된 div를 사용 (vanilla-example 방식)
    // Flutter는 단순히 placeholder로 SizedBox 반환
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: IgnorePointer(
        // JavaScript가 직접 제어하므로 Flutter 이벤트 무시
        child: Container(),
      ),
    );
  }

  @override
  void dispose() {
    print('🎭 [IDevViewer] dispose');

    // IdevViewer 제거 (전역 인스턴스는 유지, 개별 위젯만 정리)
    // _globalViewer?.callMethod('destroy');

    super.dispose();
  }
}
