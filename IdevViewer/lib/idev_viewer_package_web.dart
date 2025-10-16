import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:js' as js;

class IdevViewerPackageWebPlugin {
  static void registerWith(dynamic registrar) {
    final MethodChannel channel = MethodChannel(
      'idev_viewer',
      const StandardMethodCodec(),
      registrar.messenger,
    );

    final IdevViewerPackageWebPlugin instance = IdevViewerPackageWebPlugin();
    channel.setMethodCallHandler(instance.handleMethodCall);
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getPlatformVersion':
        return 'Web ${html.window.navigator.userAgent}';
      default:
        throw PlatformException(
          code: 'Unimplemented',
          details: 'idev_viewer for web doesn\'t implement \'${call.method}\'',
        );
    }
  }
}

class IdevViewerWebWidget extends StatefulWidget {
  final Map<String, dynamic>? template;
  final Map<String, dynamic> config;
  final double width;
  final double height;
  final Function(Map<String, dynamic>)? onReady;
  final Function(String)? onError;

  const IdevViewerWebWidget({
    super.key,
    this.template,
    this.config = const {},
    this.width = 300.0,
    this.height = 200.0,
    this.onReady,
    this.onError,
  });

  @override
  _IdevViewerWebWidgetState createState() => _IdevViewerWebWidgetState();
}

class _IdevViewerWebWidgetState extends State<IdevViewerWebWidget> {
  html.DivElement? _container;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebViewer();
  }

  void _initializeWebViewer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createWebContainer();
    });
  }

  void _createWebContainer() {
    _container = html.DivElement()
      ..id = 'idev-viewer-container-${DateTime.now().millisecondsSinceEpoch}'
      ..style.width = '${widget.width}px'
      ..style.height = '${widget.height}px'
      ..style.border = '1px solid #ddd'
      ..style.borderRadius = '8px';

    html.document.body?.append(_container!);

    _loadIdevViewer();
  }

  void _loadIdevViewer() {
    // JavaScript 라이브러리 로드
    final script = html.ScriptElement()
      ..src = '/idev-viewer.js'
      ..onLoad.listen((_) {
        _initializeViewer();
      });

    html.document.head?.append(script);
  }

  void _initializeViewer() {
    if (_container == null) return;

    final initScript = '''
      if (typeof IdevViewer !== 'undefined') {
        window.idevViewer = new IdevViewer({
          width: '100%',
          height: '100%',
          idevAppPath: '/idev-app/',
          template: ${widget.template != null ? jsonEncode(widget.template) : 'null'},
          config: ${jsonEncode(widget.config)},
          onReady: function(data) {
            // Flutter로 메시지 전송
            console.log('IdevViewer ready:', data);
          },
          onError: function(error) {
            // Flutter로 에러 메시지 전송
            console.error('IdevViewer error:', error);
          }
        });
        
        window.idevViewer.mount(document.getElementById('${_container!.id}'));
      }
    ''';

    js.context.callMethod('eval', [initScript]);
    _isInitialized = true;
  }

  @override
  void didUpdateWidget(IdevViewerWebWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.template != oldWidget.template && _isInitialized) {
      _updateTemplate();
    }

    if (widget.config != oldWidget.config && _isInitialized) {
      _updateConfig();
    }
  }

  void _updateTemplate() {
    if (widget.template != null) {
      final script = '''
        if (window.idevViewer) {
          window.idevViewer.updateTemplate(${jsonEncode(widget.template)});
        }
      ''';
      js.context.callMethod('eval', [script]);
    }
  }

  void _updateConfig() {
    final script = '''
      if (window.idevViewer) {
        window.idevViewer.updateConfig(${jsonEncode(widget.config)});
      }
    ''';
    js.context.callMethod('eval', [script]);
  }

  @override
  void dispose() {
    _container?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: HtmlElementView(
        viewType: _container?.id ?? 'idev-viewer-container',
      ),
    );
  }
}
