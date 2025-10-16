import 'package:flutter/material.dart';
import 'package:idev_viewer/idev_viewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDev Viewer Package Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'IDev Viewer Package Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Template? _template;
  Config _config = const Config(theme: 'dark', locale: 'ko');

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  void _loadTemplate() {
    setState(() {
      _template = Template(
        script: '''
        {
          "widgets": [
            {
              "type": "text",
              "content": "IDev Viewer Package Example",
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
        templateId: 'example_template',
        templateNm: 'Example Template',
        commitInfo: 'v1.0.0',
      );
    });
  }

  void _updateTemplate() {
    setState(() {
      _template = Template(
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
        templateId: 'updated_example_template',
        templateNm: 'Updated Example Template',
        commitInfo: 'v1.1.0',
      );
    });
  }

  void _toggleTheme() {
    setState(() {
      _config = Config(
        theme: _config.theme == 'dark' ? 'light' : 'dark',
        locale: _config.locale,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateTemplate,
            tooltip: 'Update Template',
          ),
          IconButton(
            icon: Icon(
                _config.theme == 'dark' ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Column(
        children: [
          // 플랫폼 정보 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Text(
              'Platform: ${_getCurrentPlatform()}',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // 뷰어
          Expanded(
            child: _template != null
                ? IdevViewer(
                    template: _template!,
                    config: _config,
                    width: double.infinity,
                    height: 600,
                    onReady: (data) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${_getCurrentPlatform()} 뷰어 준비 완료!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    onError: (error) {
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
