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
  final List<String> _events = [];
  Map<String, dynamic>? _templateData;

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
        'test-template.json',
      );
      final List<dynamic> templateList = jsonDecode(jsonString);

      setState(() {
        _templateData = {'items': templateList};
        _isLoading = false;
        _events.add('템플릿 로드 완료');
      });
      debugPrint('✅ 템플릿 로드 성공: ${templateList.length} items');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _events.add('템플릿 로드 실패: $e');
      });
      debugPrint('❌ 템플릿 로드 실패: $e');
    }
  }

  void _onReady() {
    setState(() {
      _isReady = true;
      _events.add('뷰어 준비 완료');
    });
    debugPrint('🎉 IDev Viewer is ready!');
  }

  void _onEvent(IDevEvent event) {
    setState(() {
      _events.add('${event.type}: ${event.data}');
    });
    debugPrint('📨 Event received: ${event.type}');
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
          // Info Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📋 테스트 정보',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('• 템플릿: test-template.json'),
                Text('• API 키: ${_apiKey.substring(0, 20)}...'),
                Text(
                  '• 상태: ${_isLoading
                      ? '로딩 중...'
                      : _isReady
                      ? '준비 완료 ✅'
                      : '대기 중'}',
                ),
              ],
            ),
          ),

          // Status bar
          Container(
            padding: const EdgeInsets.all(12),
            color: _isReady ? Colors.green[100] : Colors.orange[100],
            child: Row(
              children: [
                Icon(
                  _isReady ? Icons.check_circle : Icons.hourglass_empty,
                  color: _isReady ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _isReady ? '뷰어 준비 완료' : '로딩 중...',
                  style: TextStyle(
                    color: _isReady ? Colors.green[900] : Colors.orange[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_events.length} 이벤트',
                  style: TextStyle(
                    color: _isReady ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),

          // Viewer
          Expanded(
            flex: 3,
            child:
                _isLoading || _templateData == null
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
                      config: IDevConfig(
                        apiKey: _apiKey,
                        template: _templateData,
                        templateName: 'test-template-from-flutter',
                        theme: 'dark',
                        locale: 'ko',
                        debugMode: true,
                      ),
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
