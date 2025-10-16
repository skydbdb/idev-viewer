import 'package:flutter/material.dart';
import 'package:idev_viewer/idev_viewer.dart';

/// IDev Viewer 패키지 전용 데모 앱
///
/// 이 앱은 IdevViewer 패키지의 기능을 보여주는 데모용 앱입니다.
/// 실제 패키지 사용법을 확인할 수 있습니다.
void main() {
  runApp(const IdevViewerDemoApp());
}

class IdevViewerDemoApp extends StatelessWidget {
  const IdevViewerDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDev Viewer Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const IdevViewerDemoHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class IdevViewerDemoHomePage extends StatefulWidget {
  const IdevViewerDemoHomePage({super.key});

  @override
  State<IdevViewerDemoHomePage> createState() => _IdevViewerDemoHomePageState();
}

class _IdevViewerDemoHomePageState extends State<IdevViewerDemoHomePage> {
  Template? _currentTemplate;
  Config _currentConfig = const Config(
    theme: 'dark',
    locale: 'ko',
    platform: 'auto',
  );
  bool _isViewerReady = false;
  String? _lastError;

  @override
  void initState() {
    super.initState();
    _loadInitialTemplate();
  }

  void _loadInitialTemplate() {
    setState(() {
      _currentTemplate = Template(
        script: '''
        {
          "widgets": [
            {
              "type": "text",
              "content": "IDev Viewer Demo",
              "style": {
                "fontSize": 24,
                "fontWeight": "bold",
                "color": "#ffffff"
              }
            },
            {
              "type": "button",
              "content": "Click Me!",
              "action": "demo_action"
            }
          ],
          "layout": {
            "type": "column",
            "spacing": 16,
            "padding": 20
          },
          "config": {
            "theme": "dark",
            "locale": "ko"
          }
        }
        ''',
        templateId: 'demo_template',
        templateNm: 'Demo Template',
        commitInfo: 'v1.0.0',
      );
    });
  }

  void _updateTemplate() {
    setState(() {
      _currentTemplate = Template(
        script: '''
        {
          "widgets": [
            {
              "type": "text",
              "content": "Updated Template!",
              "style": {
                "fontSize": 20,
                "fontWeight": "normal",
                "color": "#00ff00"
              }
            },
            {
              "type": "image",
              "src": "assets/images/idev.jpeg",
              "width": 200,
              "height": 150
            }
          ],
          "layout": {
            "type": "row",
            "spacing": 12,
            "padding": 16
          },
          "config": {
            "theme": "light",
            "locale": "en"
          }
        }
        ''',
        templateId: 'updated_demo_template',
        templateNm: 'Updated Demo Template',
        commitInfo: 'v1.1.0',
      );
    });
  }

  void _toggleTheme() {
    setState(() {
      _currentConfig = Config(
        theme: _currentConfig.theme == 'dark' ? 'light' : 'dark',
        locale: _currentConfig.locale,
        platform: _currentConfig.platform,
      );
    });
  }

  void _toggleLocale() {
    setState(() {
      _currentConfig = Config(
        theme: _currentConfig.theme,
        locale: _currentConfig.locale == 'ko' ? 'en' : 'ko',
        platform: _currentConfig.platform,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IDev Viewer Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateTemplate,
            tooltip: 'Update Template',
          ),
          IconButton(
            icon: Icon(_currentConfig.theme == 'dark'
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _toggleLocale,
            tooltip: 'Toggle Locale',
          ),
        ],
      ),
      body: Column(
        children: [
          // 상태 정보 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                Text(
                  'Platform: ${_getCurrentPlatform()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Theme: ${_currentConfig.theme} | Locale: ${_currentConfig.locale}',
                  style: const TextStyle(fontSize: 12),
                ),
                if (_isViewerReady)
                  const Text(
                    '✅ Viewer Ready',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                if (_lastError != null)
                  Text(
                    '❌ Error: $_lastError',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
          ),
          // 뷰어
          Expanded(
            child: _currentTemplate != null
                ? IdevViewer(
                    template: _currentTemplate!,
                    config: _currentConfig,
                    width: double.infinity,
                    height: 600,
                    onReady: (data) {
                      setState(() {
                        _isViewerReady = true;
                        _lastError = null;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${_getCurrentPlatform()} 뷰어 준비 완료!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    onError: (error) {
                      setState(() {
                        _isViewerReady = false;
                        _lastError = error;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('에러: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    onTemplateUpdate: (template) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('템플릿 업데이트: ${template['templateId']}'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    onItemTap: (item) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('아이템 탭: ${item['type']}'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ],
      ),
    );
  }

  String _getCurrentPlatform() {
    if (Theme.of(context).platform == TargetPlatform.android) {
      return 'Android';
    } else if (Theme.of(context).platform == TargetPlatform.iOS) {
      return 'iOS';
    } else if (Theme.of(context).platform == TargetPlatform.fuchsia) {
      return 'Fuchsia';
    } else {
      return 'Web/Windows';
    }
  }
}
