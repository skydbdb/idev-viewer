import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:idev_viewer/idev_viewer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isReady = false;
  bool _isInitialized = false; // 뷰어 초기화 여부
  bool _isLoading = false;
  bool _isUpdating = false;
  final List<String> _events = [];
  IDevConfig? _currentConfig;

  // React 예제와 동일한 API 키
  final String _apiKey =
      '7e074a90e6128deeab38d98765e82abe39ec87449f077d7ec85f328357f96b50';

  @override
  void initState() {
    super.initState();
    _addLog('🌐 페이지 로드 완료');
    _addLog('📁 IDev Viewer 라이브러리 로드 확인 중...');
    // 초기에는 뷰어를 초기화하지 않음 (버튼 클릭 시에만 초기화)
  }

  void _addLog(String message) {
    setState(() {
      _events.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
  }

  // 뷰어 초기화 (vanilla-example의 initViewer 패턴)
  Future<void> _initViewer() async {
    if (_isLoading) return;

    try {
      setState(() {
        _isLoading = true;
      });

      _addLog('🚀 뷰어 초기화 시작...');
      _addLog('✅ IDev Viewer 라이브러리 확인 완료');

      // 초기 설정 (템플릿 없이)
      setState(() {
        _currentConfig = IDevConfig(
          apiKey: _apiKey,
          template: null, // 초기에는 템플릿 없음
          templateName: 'test_template_initial',
          theme: 'dark',
          locale: 'ko',
          debugMode: false,
        );
        _isInitialized = true;
      });

      _addLog('🔧 IDev Viewer 인스턴스 생성 완료');
      _addLog('✅ 뷰어 마운트 완료');
    } catch (e) {
      _addLog('❌ 뷰어 초기화 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 템플릿 업데이트 (vanilla-example의 updateTemplate 패턴)
  Future<void> _updateTemplate() async {
    if (!_isReady) {
      _addLog('❌ 뷰어가 초기화되지 않았습니다.');
      return;
    }

    if (_isUpdating) return;

    try {
      setState(() {
        _isUpdating = true;
      });

      _addLog('📄 템플릿 업데이트 시작');

      // test-template.json 로드
      final String jsonString = await rootBundle.loadString(
        'assets/test-template.json',
      );
      final List<dynamic> templateList = jsonDecode(jsonString);
      _addLog('✅ 템플릿 데이터 로드 완료');

      final newTemplateData = {'items': templateList};

      setState(() {
        _currentConfig = IDevConfig(
          apiKey: _apiKey,
          template: newTemplateData,
          templateName: 'test_template_updated',
          theme: 'dark',
          locale: 'ko',
          debugMode: false,
        );
        _isUpdating = false;
      });

      _addLog('🔧 템플릿 객체 생성 완료');
      _addLog('✅ 템플릿 업데이트 요청 완료');
    } catch (e) {
      _addLog('❌ 템플릿 업데이트 실패: $e');
      setState(() {
        _isUpdating = false;
      });
    }
  }

  // 뷰어 제거 (vanilla-example의 destroyViewer 패턴)
  void _destroyViewer() {
    if (!_isReady) {
      _addLog('❌ 뷰어가 초기화되지 않았습니다.');
      return;
    }

    _addLog('🗑️ 뷰어 제거 시작');

    setState(() {
      _currentConfig = null;
      _isReady = false;
      _isInitialized = false;
      _isLoading = false;
    });

    _addLog('✅ 뷰어 제거 완료');
  }

  void _onReady() {
    setState(() {
      _isReady = true;
      _isLoading = false;
    });
    _addLog('✅ 뷰어 준비 완료!');
  }

  void _onEvent(IDevEvent event) {
    _addLog('${event.type}: ${event.data}');
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• IDev 앱 경로: /assets/packages/idev_viewer/assets/idev-app/',
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
                Text(
                  '• 라이브러리: idev-viewer.js',
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
                Text(
                  '• 템플릿: test-template.json',
                  style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                ),
              ],
            ),
          ),

          // 컨트롤 버튼 (vanilla-example 패턴)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text(
                  '🎮 컨트롤',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: (!_isInitialized && !_isLoading) ? _initViewer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: const Text('초기화'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_isReady && !_isUpdating) ? _updateTemplate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: Text(_isUpdating ? '업데이트 중...' : '템플릿 업데이트'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isReady ? _destroyViewer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                  ),
                  child: const Text('뷰어 제거'),
                ),
              ],
            ),
          ),

          // Status bar
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
                        ? '상태: 뷰어 준비 완료'
                        : _isInitialized
                            ? '상태: 뷰어 초기화 중...'
                            : '상태: 초기화 대기 중',
                    style: TextStyle(
                      color: _isReady ? Colors.green[900] : Colors.orange[900],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Viewer
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              margin: const EdgeInsets.all(16),
              child: !_isInitialized
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_outline,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            '🔄 뷰어 초기화 대기 중...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '초기화 버튼을 클릭하여 IDev Viewer를 시작하세요.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : IDevViewer(
                      key: const ValueKey('idev-viewer-singleton'),
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
                      errorBuilder: (error) => Center(
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
                              onPressed: _initViewer,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // Events log (vanilla-example 패턴)
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.grey[100],
                    child: Row(
                      children: [
                        const Text(
                          '📋 로그',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                            ),
                            child: const Text('클리어', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.grey[50],
                      child: _events.isEmpty
                          ? Center(
                              child: Text(
                                '로그가 여기에 표시됩니다...',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _events.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    _events[index],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                );
                              },
                            ),
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
