# IdevViewer

[![pub package](https://img.shields.io/pub/v/idev_viewer.svg)](https://pub.dev/packages/idev_viewer)
[![pub points](https://img.shields.io/pub/points/idev_viewer?logo=dart)](https://pub.dev/packages/idev_viewer/score)
[![popularity](https://img.shields.io/pub/popularity/idev_viewer?logo=dart)](https://pub.dev/packages/idev_viewer/score)
[![likes](https://img.shields.io/pub/likes/idev_viewer?logo=dart)](https://pub.dev/packages/idev_viewer/score)

A Flutter plugin that provides 100% identical template rendering across all platforms (Android, iOS, Web, Windows) using IDev-based template system.

## 📖 Overview

IdevViewer is a Flutter plugin that enables consistent template rendering across multiple platforms. It leverages native WebView components to embed Flutter web applications, providing a unified API for template viewing and interaction.

## ✨ Features

- 🌐 **Cross-Platform**: Works on Android, iOS, Web, and Windows
- 🎨 **Consistent Rendering**: 100% identical template rendering across all platforms
- 🔄 **Dynamic Updates**: Real-time template and configuration updates
- 📱 **Native Performance**: Uses platform-specific WebView components
- 🎯 **Easy Integration**: Simple Flutter widget API
- 🔧 **Configurable**: Theme, locale, and API key support
- 📊 **Event Handling**: Ready, error, and interaction callbacks

## 🚀 Quick Start

### 1. Add Dependency

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  idev_viewer: ^1.0.0
```

### 2. Basic Usage

```dart
import 'package:idev_viewer/idev_viewer.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: IdevViewer(
          width: 400,
          height: 300,
          template: Template(
            script: '{"type": "text", "content": "Hello World"}',
            templateId: 'demo_template',
            templateNm: 'Demo Template',
            commitInfo: 'v1.0.0',
          ),
          config: Config(
            theme: 'light',
            locale: 'ko',
            apiKey: 'your-api-key',
            debugMode: false,
          ),
          onReady: (data) {
            print('Viewer ready: $data');
          },
          onError: (error) {
            print('Viewer error: $error');
          },
          onTemplateUpdate: (data) {
            print('Template updated: $data');
          },
          onItemTap: (data) {
            print('Item tapped: $data');
          },
        ),
      ),
    );
  }
}
```

## 📱 Platform Support

| Platform | Support | Implementation |
|----------|---------|----------------|
| Android  | ✅      | WebView        |
| iOS      | ✅      | WKWebView      |
| Web      | ✅      | HtmlElementView |
| Windows  | ✅      | WebView2       |

## 🔧 Configuration

### Template

```dart
final template = Template(
  script: '{"type": "grid", "columns": 3}', // JSON string
  templateId: 'unique_id',
  templateNm: 'Template Name',
  commitInfo: 'v1.0.0',
);
```

### Config

```dart
final config = Config(
  theme: 'light', // 'light' or 'dark'
  locale: 'ko',   // 'ko' or 'en'
  apiKey: 'your-api-key',
  debugMode: false,
  platform: 'mobile', // 'mobile', 'desktop', 'web'
);
```

## 📋 API Reference

### IdevViewer Widget

| Parameter | Type | Description |
|-----------|------|-------------|
| `template` | `Template?` | Template data to display |
| `config` | `Config` | Viewer configuration |
| `width` | `double` | Widget width |
| `height` | `double` | Widget height |
| `onReady` | `Function(Map<String, dynamic>)?` | Called when viewer is ready |
| `onError` | `Function(String)?` | Called when error occurs |
| `onTemplateUpdate` | `Function(Map<String, dynamic>)?` | Called when template updates |
| `onItemTap` | `Function(Map<String, dynamic>)?` | Called when item is tapped |

### Methods

```dart
// Update template dynamically
viewer.updateTemplate(newTemplate);

// Update configuration
viewer.updateConfig(newConfig);

// Get current state
final state = await viewer.getState();
```

## 🎯 Use Cases

- **Template Viewers**: Display dynamic templates consistently across platforms
- **Documentation**: Show interactive examples in Flutter apps
- **Dashboards**: Embed web-based dashboards in mobile apps
- **Content Management**: Display CMS content with consistent rendering
- **Cross-Platform Apps**: Maintain UI consistency across different platforms

## 🔄 Event Handling

```dart
IdevViewer(
  onReady: (data) {
    // Viewer is ready and loaded
    print('Viewer ready: ${data['status']}');
  },
  onError: (error) {
    // Handle errors
    print('Error: $error');
  },
  onTemplateUpdate: (data) {
    // Template was updated
    print('Template updated: ${data['templateId']}');
  },
  onItemTap: (data) {
    // User tapped an item
    print('Item tapped: ${data['itemId']}');
  },
)
```

## 🛠️ Development

### Running Tests

```bash
cd IdevViewer
flutter test
```

### Running Example

```bash
cd IdevViewer/example
flutter run
```

### Building Package

```bash
# Build JavaScript library
cd idev-viewer-js
npm run build

# Sync assets to Flutter package
./scripts/sync-idev-viewer-assets.sh

# Test package
cd IdevViewer
flutter test
```

### 📖 Running Guide

For detailed execution instructions, see the [Running Guide](docs/running-guide.md).

## 📦 Assets

The plugin includes the following assets:

- **idev-app/**: Flutter web application build artifacts
- **idev-viewer.js**: JavaScript wrapper library
- **Platform-specific**: Optimized for each platform's WebView

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Pub Package](https://pub.dev/packages/idev_viewer)
- [GitHub Repository](https://github.com/skydbdb/idev-viewer)
- [Documentation](https://pub.dev/documentation/idev_viewer/latest/)
- [Issues](https://github.com/skydbdb/idev-viewer/issues)

## 📞 Support

- **Email**: support@idev.biz
- **Website**: https://idev.biz
- **Issues**: [GitHub Issues](https://github.com/skydbdb/idev-viewer/issues)

---

Made with ❤️ by [IDev](https://idev.biz)