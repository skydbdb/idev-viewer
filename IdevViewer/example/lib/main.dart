import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idev_viewer/idev_viewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDev Viewer Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isReady = false;
  bool _isLoading = true;
  bool _isUpdating = false;
  final List<String> _events = [];
  Map<String, dynamic>? _templateData;
  IDevConfig? _currentConfig;

  // React 예제와 동일한 API 키
  final String _apiKey =
      '7e074a90e6128deeab38d98765e82abe39ec87449f077d7ec85f328357f96b50';

  @override
  void initState() {
    super.initState();
    _loadTemplate();
  }

  Future<void> _loadTemplate() async {
    try {
      // test-template.json 로드
      final String jsonString = await rootBundle.loadString(
        'assets/test-template.json',
      );
      final List<dynamic> templateList = jsonDecode(jsonString);

      setState(() {
        _templateData = {'items': templateList};
        _isLoading = false;
        _events.add('템플릿 로드 완료');
        _currentConfig = IDevConfig(
          apiKey: _apiKey,
          template: _templateData,
          templateName: 'test-template-from-flutter',
          theme: 'dark',
          locale: 'ko',
          debugMode: false,
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _events.add('템플릿 로드 실패: $e');
      });
    }
  }

  Future<void> _updateTemplate() async {
    if (_isUpdating) return;

    try {
      setState(() {
        _isUpdating = true;
        _events.add('템플릿 업데이트 시작');
      });

      // test-template.json 다시 로드
      final String jsonString = await rootBundle.loadString(
        'assets/test-template.json',
      );
      final List<dynamic> templateList = jsonDecode(jsonString);

      final newTemplateData = {'items': templateList};

      setState(() {
        _templateData = newTemplateData;
        _currentConfig = IDevConfig(
          apiKey: _apiKey,
          template: newTemplateData,
          templateName:
              'test-template-updated-${DateTime.now().millisecondsSinceEpoch}',
          theme: 'dark',
          locale: 'ko',
          debugMode: false,
        );
        _isUpdating = false;
        _events.add('템플릿 업데이트 완료');
      });
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _events.add('템플릿 업데이트 실패: $e');
      });
    }
  }

  void _onReady() {
    setState(() {
      _isReady = true;
      _events.add('뷰어 준비 완료');
    });
  }

  void _onEvent(IDevEvent event) {
    setState(() {
      _events.add('${event.type}: ${event.data}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚀 IDev Viewer Flutter Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Status bar (통합)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _isReady ? Colors.green[100] : Colors.orange[100],
            child: Row(
              children: [
                Icon(
                  _isReady ? Icons.check_circle : Icons.hourglass_empty,
                  color: _isReady ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isReady
                        ? '✅ 준비 완료 | test-template.json (${_templateData != null ? (_templateData!['items'] as List).length : 0} items)'
                        : '⏳ 로딩 중...',
                    style: TextStyle(
                      color: _isReady ? Colors.green[900] : Colors.orange[900],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_events.length} 이벤트',
                  style: TextStyle(
                    color: _isReady ? Colors.green[700] : Colors.orange[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 버튼 영역
          if (_isReady)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _updateTemplate,
                    icon:
                        _isUpdating
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.refresh),
                    label: Text(_isUpdating ? '업데이트 중...' : '템플릿 업데이트'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'test-template.json 다시 로드',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ),

          // Viewer
          Expanded(
            flex: 3,
            child:
                _isLoading || _currentConfig == null
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('템플릿 로딩 중...'),
                        ],
                      ),
                    )
                    : IDevViewer(
                      config: _currentConfig!,
                      onReady: _onReady,
                      onEvent: _onEvent,
                      loadingWidget: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('IDev Viewer 시작 중...'),
                          ],
                        ),
                      ),
                      errorBuilder:
                          (error) => Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text('오류: $error'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLoading = true;
                                      _events.clear();
                                    });
                                    _loadTemplate();
                                  },
                                  child: const Text('다시 시도'),
                                ),
                              ],
                            ),
                          ),
                    ),
          ),

          // Events log
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.grey[200],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Text(
                          '이벤트 로그',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (_events.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _events.clear();
                              });
                            },
                            child: const Text('클리어'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child:
                        _events.isEmpty
                            ? const Center(
                              child: Text(
                                '아직 이벤트가 없습니다',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                            : ListView.builder(
                              itemCount: _events.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                final eventIndex = _events.length - 1 - index;
                                return ListTile(
                                  dense: true,
                                  leading: Text(
                                    '${eventIndex + 1}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  title: Text(
                                    _events[eventIndex],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
