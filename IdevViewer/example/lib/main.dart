import 'package:flutter/material.dart';
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
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
  final List<String> _events = [];

  // 샘플 템플릿 데이터
  final Map<String, dynamic> _sampleTemplate = {
    'type': 'container',
    'properties': {
      'padding': 20,
      'backgroundColor': '#f0f0f0',
    },
    'children': [
      {
        'type': 'text',
        'properties': {
          'text': 'Hello from IDev Viewer!',
          'fontSize': 24,
          'fontWeight': 'bold',
        },
      },
      {
        'type': 'button',
        'properties': {
          'text': 'Click Me',
          'backgroundColor': '#007bff',
          'textColor': '#ffffff',
        },
      },
    ],
  };

  void _onReady() {
    setState(() {
      _isReady = true;
      _events.add('Viewer ready');
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
        title: const Text('IDev Viewer Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
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
                  _isReady ? 'Viewer Ready' : 'Loading...',
                  style: TextStyle(
                    color: _isReady ? Colors.green[900] : Colors.orange[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_events.length} events',
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
            child: IDevViewer(
              config: IDevConfig(
                apiKey: 'demo-api-key',
                template: _sampleTemplate,
                templateName: 'example-template',
              ),
              onReady: _onReady,
              onEvent: _onEvent,
              loadingWidget: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading IDev Viewer...'),
                  ],
                ),
              ),
              errorBuilder: (error) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
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
                          'Events Log',
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
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _events.isEmpty
                        ? const Center(
                            child: Text(
                              'No events yet',
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
