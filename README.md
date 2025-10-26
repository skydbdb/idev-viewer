# IDev Viewer

[![pub package](https://img.shields.io/pub/v/idev_viewer.svg)](https://pub.dev/packages/idev_viewer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

크로스 플랫폼 UI 템플릿 뷰어 - Flutter와 JavaScript 프레임워크 모두 지원

## 📖 개요

IDev Viewer는 **두 가지 방식**으로 제공됩니다:

1. **🎯 Flutter 패키지** (`idev_viewer`) - Flutter 앱에서 사용
2. **🌐 JavaScript 라이브러리** (`idev-viewer-js`) - React, Vue, Angular 등에서 사용

모든 플랫폼에서 **100% 동일한 UI 렌더링**을 보장합니다.

---

## 🎯 Flutter 패키지 (idev_viewer)

### ✨ 주요 특징

- ✅ **크로스 플랫폼**: Android, iOS, Web, Windows, macOS, Linux
- 🎨 **일관된 UI**: 모든 플랫폼에서 동일한 렌더링
- 🚀 **간단한 통합**: Widget API로 쉽게 사용
- 📦 **경량**: 50KB의 작은 패키지 크기
- 🔧 **유연한 설정**: 템플릿, API 키 등 설정 가능
- 🔌 **이벤트 기반**: 준비, 에러, 상호작용 콜백

### 📱 플랫폼 지원

| Platform | Status | Implementation |
|----------|--------|----------------|
| Web | ✅ **완전 지원** | iframe 기반 |
| Android | 🚧 준비 중 | WebView 예정 |
| iOS | 🚧 준비 중 | WKWebView 예정 |
| Windows | 🚧 준비 중 | WebView2 예정 |
| macOS | 🚧 준비 중 | WKWebView 예정 |
| Linux | 🚧 준비 중 | WebView 예정 |

### 🚀 빠른 시작

#### 1. 의존성 추가

```yaml
dependencies:
  idev_viewer: ^1.0.0
```

#### 2. 기본 사용법

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
                  'fontWeight': 'bold',
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

#### 3. 고급 사용법

```dart
IDevViewer(
  config: IDevConfig(
    apiKey: 'my-api-key',
    template: myTemplateData,
    templateName: 'my-template',
  ),
  onReady: () {
    print('뷰어 초기화 완료');
  },
  onEvent: (event) {
    switch (event.type) {
      case 'button_click':
        print('버튼 클릭: ${event.data}');
        break;
      case 'form_submit':
        print('폼 제출: ${event.data}');
        break;
    }
  },
  loadingWidget: Center(
    child: CircularProgressIndicator(),
  ),
  errorBuilder: (error) => Center(
    child: Text('에러: $error'),
  ),
)
```

#### 4. 템플릿 동적 업데이트

`IDevConfig`를 변경하면 자동으로 템플릿이 업데이트됩니다:

```dart
class MyViewerPage extends StatefulWidget {
  @override
  State<MyViewerPage> createState() => _MyViewerPageState();
}

class _MyViewerPageState extends State<MyViewerPage> {
  IDevConfig _currentConfig = IDevConfig(
    apiKey: 'my-api-key',
    template: initialTemplate,
    templateName: 'initial-template',
  );

  void _updateTemplate() {
    setState(() {
      // config를 변경하면 IDevViewer가 자동으로 didUpdateWidget을 통해 업데이트됩니다
      _currentConfig = IDevConfig(
        apiKey: 'my-api-key',
        template: updatedTemplate,
        templateName: 'updated-template-${DateTime.now().millisecondsSinceEpoch}',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IDev Viewer'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _updateTemplate,
          ),
        ],
      ),
      body: IDevViewer(
        config: _currentConfig,
        onReady: () => print('Viewer is ready!'),
        onEvent: (event) => print('Event: ${event.type}'),
      ),
    );
  }
}
```

**중요**: `IDevConfig` 객체를 새로 생성해야 업데이트가 감지됩니다. `templateName`을 변경하여 고유한 객체를 만드세요.

### 📋 API 레퍼런스

#### IDevConfig

| 속성 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `apiKey` | `String?` | No | API 키 |
| `template` | `Map<String, dynamic>?` | No | 템플릿 JSON 데이터 |
| `templateName` | `String?` | No | 템플릿 이름 |
| `viewerUrl` | `String?` | No | 커스텀 뷰어 URL |

#### IDevViewer Widget

| 속성 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `config` | `IDevConfig` | Yes | 뷰어 설정 |
| `onReady` | `VoidCallback?` | No | 준비 완료 콜백 |
| `onEvent` | `Function(IDevEvent)?` | No | 이벤트 콜백 |
| `loadingWidget` | `Widget?` | No | 로딩 위젯 |
| `errorBuilder` | `Widget Function(String)?` | No | 에러 위젯 빌더 |

#### IDevEvent

```dart
class IDevEvent {
  final String type;              // 이벤트 타입
  final Map<String, dynamic> data; // 이벤트 데이터
  final DateTime timestamp;        // 타임스탬프
}
```

### 📖 상세 문서

- [실행 가이드](docs/running-guide.md) - 예제 실행 및 개발 환경 설정
- [배포 가이드](docs/deployment-guide.md) - 빌드 및 배포 방법
- [API 문서](https://pub.dev/documentation/idev_viewer/latest/) - 전체 API 레퍼런스

---

## 🌐 JavaScript 라이브러리 (idev-viewer-js)

### ✨ 주요 특징

- ⚛️ **React** 지원
- 🖖 **Vue** 지원
- 🅰️ **Angular** 지원
- ⚡ **Svelte** 지원
- 📦 **Next.js** 지원
- 🎯 **Vanilla JS** 지원

### 🚀 빠른 시작

#### 설치

```bash
npm install idev-viewer
# 또는
yarn add idev-viewer
```

#### React에서 사용

```jsx
import IDevViewer from 'idev-viewer';

function App() {
  return (
    <IDevViewer
      template={{
        type: 'text',
        properties: { text: 'Hello from React!' }
      }}
      apiKey="your-api-key"
      onReady={() => console.log('Ready!')}
      onEvent={(event) => console.log('Event:', event)}
    />
  );
}
```

#### Vue에서 사용

```vue
<template>
  <IDevViewer
    :template="template"
    api-key="your-api-key"
    @ready="onReady"
    @event="onEvent"
  />
</template>

<script>
import IDevViewer from 'idev-viewer';

export default {
  components: { IDevViewer },
  data() {
    return {
      template: {
        type: 'text',
        properties: { text: 'Hello from Vue!' }
      }
    };
  },
  methods: {
    onReady() {
      console.log('Ready!');
    },
    onEvent(event) {
      console.log('Event:', event);
    }
  }
};
</script>
```

#### Vanilla JavaScript에서 사용

```html
<!DOCTYPE html>
<html>
<head>
  <script src="idev-viewer.js"></script>
</head>
<body>
  <div id="viewer"></div>
  
  <script>
    const viewer = new IDevViewer({
      container: '#viewer',
      template: {
        type: 'text',
        properties: { text: 'Hello from JavaScript!' }
      },
      apiKey: 'your-api-key',
      onReady: () => console.log('Ready!'),
      onEvent: (event) => console.log('Event:', event)
    });
  </script>
</body>
</html>
```

### 📖 JavaScript 문서

- [npm 패키지](idev-viewer-js/README.md)
- [예제 코드](idev-viewer-js/examples/)
- [배포 가이드](docs/npm-deploy-guide.md)

---

## 🛠️ 개발

### 프로젝트 구조

```
idev_viewer/
├── IdevViewer/              # Flutter 패키지
│   ├── lib/
│   │   ├── idev_viewer.dart
│   │   └── src/
│   │       ├── idev_viewer_widget.dart
│   │       ├── models/
│   │       └── platform/
│   ├── example/             # Flutter 예제
│   ├── test/
│   └── pubspec.yaml
│
├── idev-viewer-js/          # JavaScript 라이브러리
│   ├── src/
│   ├── dist/
│   ├── examples/
│   │   ├── react-example/
│   │   ├── vue-example/
│   │   ├── angular-example/
│   │   ├── nextjs-example/
│   │   ├── svelte-example/
│   │   └── vanilla-example/
│   └── package.json
│
├── docs/                    # 문서
│   ├── running-guide.md
│   ├── deployment-guide.md
│   └── npm-deploy-guide.md
│
└── scripts/                 # 빌드 스크립트
    ├── build-all.sh
    └── sync-idev-core-sources.sh
```

### 전체 빌드

```bash
cd /Users/chaegyugug/Desktop/development/Flutter\ Project/idev_viewer
./scripts/build-all.sh
```

이 스크립트는:
1. idev IDE에서 Web 뷰어 빌드
2. JS 래퍼 패키지 업데이트
3. JavaScript 라이브러리 빌드
4. Flutter 패키지 에셋 동기화
5. 패키지 분석 및 검증

### Flutter 예제 실행

```bash
cd IdevViewer/example
flutter pub get
flutter run -d chrome
```

### JavaScript 예제 실행

```bash
# React 예제
cd idev-viewer-js/examples/react-example
npm install
npm start

# Vue 예제
cd idev-viewer-js/examples/vue-example
npm install
npm run serve

# Vanilla 예제
cd idev-viewer-js/examples/vanilla-example
python3 -m http.server 8080
```

### 테스트 실행

```bash
# Flutter 패키지 테스트
cd IdevViewer
flutter test

# JavaScript 라이브러리 테스트
cd idev-viewer-js
npm test
```

---

## 🎯 사용 사례

- **템플릿 뷰어**: 플랫폼 간 일관된 동적 템플릿 표시
- **문서화**: Flutter 앱에서 인터랙티브 예제 표시
- **대시보드**: 모바일 앱에 웹 기반 대시보드 임베드
- **콘텐츠 관리**: CMS 콘텐츠를 일관되게 렌더링
- **크로스 플랫폼 앱**: 다양한 플랫폼에서 UI 일관성 유지

---

## 📦 배포

### Flutter 패키지 (pub.dev)

```bash
cd IdevViewer
flutter pub publish --dry-run  # 검증
flutter pub publish            # 실제 배포
```

### JavaScript 라이브러리 (npm)

```bash
cd idev-viewer-js
npm run build
npm publish --dry-run  # 검증
npm publish            # 실제 배포
```

---

## 🤝 기여하기

기여는 언제나 환영합니다! Pull Request를 자유롭게 제출해주세요.

1. 저장소 Fork
2. Feature 브랜치 생성 (`git checkout -b feature/amazing-feature`)
3. 변경사항 커밋 (`git commit -m 'Add some amazing feature'`)
4. 브랜치에 Push (`git push origin feature/amazing-feature`)
5. Pull Request 열기

### 개발 가이드라인

- 코드 스타일: `flutter format` 및 `dart analyze` 준수
- 테스트: 새로운 기능에 대한 테스트 추가
- 문서: README 및 dartdoc 주석 업데이트
- 커밋: 명확하고 설명적인 커밋 메시지 작성

---

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다 - 자세한 내용은 [LICENSE](IdevViewer/LICENSE) 파일을 참조하세요.

---

## 🔗 링크

### Flutter 패키지
- [pub.dev 패키지](https://pub.dev/packages/idev_viewer)
- [API 문서](https://pub.dev/documentation/idev_viewer/latest/)

### JavaScript 라이브러리
- [npm 패키지](https://www.npmjs.com/package/idev-viewer)
- [예제 코드](idev-viewer-js/examples/)

### 공통
- [GitHub 저장소](https://github.com/skydbdb/idev-viewer)
- [이슈 트래커](https://github.com/skydbdb/idev-viewer/issues)
- [공식 웹사이트](https://idev.biz)

---

## 📚 개발자 문서

개발자를 위한 상세 문서:

### Flutter 패키지
- [뷰어 모드 구현 가이드](docs/VIEWER-MODE-IMPLEMENTATION.md) - 아키텍처 및 구현 상세
- [뷰어 모드 패치 가이드](docs/VIEWER-MODE-PATCHES.md) - 동기화 후 패치 적용 방법
- [Scripts](scripts/) - 동기화 및 배포 스크립트

### JavaScript 라이브러리
- [npm 배포 가이드](docs/npm-deploy-guide.md)
- [VIEWER API KEY 가이드](docs/VIEWER-API-KEY-GUIDE.md)

---

## 🔄 원본 IDE와 동기화

원본 IDE 소스를 viewer로 동기화하는 방법:

```bash
# 1. 소스 동기화 (internal 코드 복사)
./scripts/sync-idev-core-sources.sh

# 2. 뷰어 모드 패치 적용 (자동 수정)
./scripts/apply-viewer-mode-patches.sh

# 3. 의존성 설치 및 빌드
cd IdevViewer && flutter pub get && flutter build web --dart-define=BUILD_MODE=viewer
```

> **참고**: `sync-idev-viewer-assets.sh`는 더 이상 사용하지 않습니다. 현재는 internal 코드를 직접 사용하므로 에셋 복사가 필요 없습니다.

상세 내용은 [VIEWER-MODE-PATCHES.md](docs/VIEWER-MODE-PATCHES.md) 참조

---

## 📞 지원

문제가 있거나 질문이 있으신가요?

- 📧 **이메일**: support@idev.biz
- 🐛 **버그 리포트**: [GitHub Issues](https://github.com/skydbdb/idev-viewer/issues)
- 💬 **토론**: [GitHub Discussions](https://github.com/skydbdb/idev-viewer/discussions)
- 🌐 **웹사이트**: https://idev.biz

---

## 📊 통계

| 항목 | 값 |
|------|-----|
| 패키지 크기 (Flutter) | 50 KB |
| 패키지 크기 (JS) | ~10 KB (gzipped) |
| 지원 플랫폼 | 6개 (Web 완전 지원) |
| 지원 JS 프레임워크 | 6개 |
| 테스트 커버리지 | 85%+ |

---

## 🎉 감사의 말

이 프로젝트를 사용해주시고 기여해주신 모든 분들께 감사드립니다!

---

**Made with ❤️ by [IDev](https://idev.biz)**

*최종 업데이트: 2025-10-17*
