# idev_viewer

[![pub package](https://img.shields.io/pub/v/idev_viewer.svg)](https://pub.dev/packages/idev_viewer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Cross-platform UI template viewer for Flutter applications with **100% identical rendering** across all platforms.

## Features

- ✅ **Cross-platform**: Android, iOS, Web, Windows, macOS, Linux
- 🎨 **Identical UI**: Same appearance on all platforms
- 🚀 **Easy Integration**: Simple Widget API
- 📦 **Lightweight**: Minimal dependencies
- 🔧 **Flexible**: Customize via configuration
- 🔌 **Event-driven**: React to viewer events

## Platforms

| Platform | Status | Implementation |
|----------|--------|----------------|
| Web | ✅ Fully Supported | iframe-based viewer |
| Android | 🚧 Coming Soon | WebView-based viewer |
| iOS | 🚧 Coming Soon | WebView-based viewer |
| Windows | 🚧 Coming Soon | WebView-based viewer |
| macOS | 🚧 Coming Soon | WebView-based viewer |
| Linux | 🚧 Coming Soon | WebView-based viewer |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  idev_viewer: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:idev_viewer/idev_viewer.dart';

class MyViewerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('IDev Viewer')),
      body: IDevViewer(
        config: IDevConfig(
          apiKey: 'your-api-key',
          template: {
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
                },
              },
            ],
          },
        ),
        onReady: () => print('Viewer is ready!'),
        onEvent: (event) => print('Event: ${event.type}'),
      ),
    );
  }
}
```

## Configuration

### IDevConfig

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `apiKey` | `String?` | No | API key for authentication |
| `template` | `Map<String, dynamic>?` | No | Template JSON data |
| `templateName` | `String?` | No | Template name |
| `viewerUrl` | `String?` | No | Custom viewer URL |

### IDevViewer Widget

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `config` | `IDevConfig` | Yes | Viewer configuration |
| `onReady` | `VoidCallback?` | No | Called when viewer is ready |
| `onEvent` | `Function(IDevEvent)?` | No | Called on viewer events |
| `loadingWidget` | `Widget?` | No | Custom loading widget |
| `errorBuilder` | `Widget Function(String)?` | No | Custom error widget |

## Examples

See the [`example`](example) directory for a complete example application.

### Basic Usage

```dart
IDevViewer(
  config: IDevConfig(
    template: myTemplateData,
  ),
)
```

### With Callbacks

```dart
IDevViewer(
  config: IDevConfig(
    apiKey: 'my-api-key',
    template: myTemplateData,
  ),
  onReady: () {
    print('Viewer initialized successfully');
  },
  onEvent: (event) {
    print('Received event: ${event.type}');
    // Handle different event types
    switch (event.type) {
      case 'button_click':
        // Handle button click
        break;
      case 'form_submit':
        // Handle form submission
        break;
    }
  },
)
```

### Custom Loading and Error Widgets

```dart
IDevViewer(
  config: IDevConfig(template: myTemplateData),
  loadingWidget: Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading viewer...'),
      ],
    ),
  ),
  errorBuilder: (error) => Center(
    child: Text('Error: $error'),
  ),
)
```

## For JavaScript Frameworks

If you're using React, Vue, Angular, or other JavaScript frameworks, check out our npm package:

```bash
npm install idev-viewer
```

See the [idev-viewer-js documentation](../idev-viewer-js/README.md) for more information.

## Documentation

For more detailed documentation, visit:
- [API Documentation](https://pub.dev/documentation/idev_viewer/latest/)
- [GitHub Repository](https://github.com/skydbdb/idev-viewer)
- [Official Website](https://idev.biz)

## Contributing

Contributions are welcome! Please read our [contributing guidelines](../docs/README.md) first.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: support@idev.biz
- 🐛 Issues: [GitHub Issues](https://github.com/skydbdb/idev-viewer/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/skydbdb/idev-viewer/discussions)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.
