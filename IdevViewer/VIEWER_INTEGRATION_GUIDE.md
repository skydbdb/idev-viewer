# IDevViewer Flutter Web Integration Guide

## 📋 목차
1. [개요](#개요)
2. [아키텍처](#아키텍처)
3. [설치 및 설정](#설치-및-설정)
4. [사용 방법](#사용-방법)
5. [템플릿 업데이트](#템플릿-업데이트)
6. [트러블슈팅](#트러블슈팅)
7. [기술 세부사항](#기술-세부사항)

---

## 개요

IDevViewer는 Flutter Web 애플리케이션에 **읽기 전용(Viewer Mode)** iDev 템플릿 뷰어를 임베드하는 패키지입니다.

### 주요 특징
- ✅ **읽기 전용 모드**: 템플릿 편집 기능 없이 안전하게 표시
- ✅ **동적 템플릿 업데이트**: 런타임에 템플릿 변경 가능
- ✅ **iframe 기반 격리**: 메인 앱과 독립적인 실행 환경
- ✅ **Hot Restart 지원**: 개발 중 중복 초기화 방지
- ✅ **커스터마이징 가능**: 로딩 화면 및 에러 처리 커스터마이징

---

## 아키텍처

### 전체 구조

```
┌─────────────────────────────────────────────────┐
│ Flutter Web App (Main)                          │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │ IDevViewerPlatform Widget                 │ │
│  │                                           │ │
│  │  ┌─────────────────────────────────────┐ │ │
│  │  │ HtmlElementView                     │ │ │
│  │  │ (PlatformView - DOM Container)      │ │ │
│  │  │                                     │ │ │
│  │  │  ┌───────────────────────────────┐ │ │ │
│  │  │  │ <iframe> (viewer-app)         │ │ │ │
│  │  │  │                               │ │ │ │
│  │  │  │  Flutter Web App (Viewer)     │ │ │ │
│  │  │  │  - 읽기 전용 모드            │ │ │ │
│  │  │  │  - 템플릿 렌더링             │ │ │ │
│  │  │  └───────────────────────────────┘ │ │ │
│  │  └─────────────────────────────────────┘ │ │
│  └───────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘

         ↕ postMessage (Template Updates)
```

### 통신 흐름

```
1. 초기화
   Flutter Widget → JavaScript IdevViewer → iframe 생성

2. 템플릿 업데이트
   Flutter → IdevViewer.updateTemplate() 
         → postMessage 
         → iframe (viewer-app) 
         → Flutter 내부 상태 업데이트

3. Ready 신호
   iframe → postMessage('flutter-ready') 
         → IdevViewer 
         → Flutter onReady callback
```

---

## 설치 및 설정

### 1. 패키지 추가

```yaml
# pubspec.yaml
dependencies:
  idev_viewer:
    path: ../IdevViewer  # 로컬 경로
```

### 2. 필수 파일 확인

프로젝트에 다음 파일들이 포함되어야 합니다:

```
IdevViewer/
├── assets/
│   ├── viewer-app/           # 읽기 전용 Flutter 앱
│   │   ├── index.html
│   │   ├── main.dart.js
│   │   ├── flutter.js
│   │   └── ...
│   └── idev-app/             # 편집 모드 (백업용)
└── lib/
    └── src/
        └── platform/
            └── viewer_web.dart
```

### 3. pubspec.yaml 설정

```yaml
# IdevViewer/pubspec.yaml
flutter:
  assets:
    # viewer-app (읽기 전용)
    - assets/viewer-app/
    - assets/viewer-app/assets/
    - assets/viewer-app/canvaskit/
    - assets/viewer-app/icons/
```

---

## 사용 방법

### 기본 사용

```dart
import 'package:idev_viewer/idev_viewer.dart';

class MyViewerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Template Viewer')),
      body: IDevViewer(
        config: IDevConfig(
          templateName: 'my_template',
          template: null, // 초기 템플릿 (optional)
        ),
        onReady: () {
          print('Viewer is ready!');
        },
      ),
    );
  }
}
```

### 커스텀 로딩 & 에러 처리

```dart
IDevViewer(
  config: IDevConfig(
    templateName: 'my_template',
  ),
  onReady: () {
    print('Viewer is ready!');
  },
  loadingWidget: Container(
    color: Colors.blue[50],
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 16),
          Text(
            '템플릿 로딩 중...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue[800],
            ),
          ),
        ],
      ),
    ),
  ),
  errorBuilder: (error) {
    return Container(
      color: Colors.red[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text(
              '로드 실패',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  },
)
```

---

## 템플릿 업데이트

### 동적 템플릿 변경

```dart
class MyViewerPage extends StatefulWidget {
  @override
  _MyViewerPageState createState() => _MyViewerPageState();
}

class _MyViewerPageState extends State<MyViewerPage> {
  IDevConfig _config = IDevConfig(
    templateName: 'initial_template',
    template: null,
  );

  void _updateTemplate(List<dynamic> newTemplateItems) {
    setState(() {
      _config = IDevConfig(
        templateName: 'updated_template',
        template: newTemplateItems,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Template Viewer'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // 템플릿 업데이트
              _updateTemplate([
                {
                  "boardId": "#TEMPLATE#",
                  "id": "Frame_1",
                  "type": "StackFrameItem",
                  // ... 템플릿 데이터
                }
              ]);
            },
          ),
        ],
      ),
      body: IDevViewer(
        config: _config,
        onReady: () {
          print('Viewer ready!');
        },
      ),
    );
  }
}
```

### 템플릿 형식

템플릿은 다음 두 가지 형식을 지원합니다:

**1. 배열 형식 (권장)**
```dart
template: [
  {
    "boardId": "#TEMPLATE#",
    "id": "Frame_1",
    "type": "StackFrameItem",
    // ...
  },
  // 더 많은 아이템...
]
```

**2. 객체 형식 (items 키 필요)**
```dart
template: {
  "items": [
    {
      "boardId": "#TEMPLATE#",
      "id": "Frame_1",
      "type": "StackFrameItem",
      // ...
    },
  ]
}
```

---

## 트러블슈팅

### 1. "Container not found" 에러

**원인**: PlatformView 컨테이너가 DOM에 렌더링되기 전에 마운트 시도

**해결**: 자동으로 재시도하지만, 문제가 지속되면 `_waitForContainerAndMount` 타임아웃 증가

```dart
// viewer_web.dart
const maxAttempts = 50; // 기본값: 5초
```

### 2. Hot Restart 후 중복 iframe

**원인**: JavaScript 전역 변수가 유지되어 기존 뷰어 감지 실패

**해결**: 자동 처리됨 - 기존 iframe 자동 정리 및 재사용

### 3. 템플릿이 2번 호출됨

**원인**: postMessage로 받은 템플릿을 polling이 다시 감지

**해결**: 이미 수정됨 - `lastTemplateId` 중복 체크로 방지

### 4. 404 에러 (viewer-app/index.html)

**원인**: Assets가 pubspec.yaml에 등록되지 않음

**해결**:
```yaml
flutter:
  assets:
    - assets/viewer-app/
    - assets/viewer-app/assets/
```

### 5. IdevViewer 클래스를 찾을 수 없음

**원인**: `idev-viewer.js`가 로드되지 않음

**해결**:
```html
<!-- viewer-app/index.html -->
<script src="idev-viewer.js"></script>
```

---

## 기술 세부사항

### PlatformView 사용

```dart
// PlatformView 등록
ui_web.platformViewRegistry.registerViewFactory(
  'idev-viewer-container-singleton',
  (int viewId) {
    return html.DivElement()
      ..id = 'idev-viewer-container-singleton'
      ..style.width = '100%'
      ..style.height = '100%';
  },
);

// Flutter 위젯에서 사용
HtmlElementView(
  viewType: 'idev-viewer-container-singleton',
)
```

### JavaScript 전역 변수 (Hot Restart 대응)

```dart
// 초기화 여부 확인
js.context['_idevViewerHasInitialized'] = true;

// 뷰어 인스턴스 저장
js.context['_idevViewerInstance'] = viewer;

// 중복 생성 방지 플래그
js.context['_idevViewerCreating'] = false;
js.context['_idevViewerMountAttempted'] = false;
```

### 메시지 전달 프로토콜

**Dart → iframe:**
```javascript
viewer.callMethod('updateTemplate', [template]);
// ↓
postMessage({
  type: 'update_template',
  template: {...},
  timestamp: Date.now()
})
```

**iframe → Dart:**
```javascript
window.parent.postMessage(JSON.stringify({
  type: 'flutter-ready',
  data: { status: 'ready' }
}), '*');
```

### 중복 템플릿 방지 로직

```javascript
// viewer-app/index.html
var lastTemplateId = null;

function handleMessage(message) {
  if (message.type === 'update_template' && message.template) {
    var newTemplateId = message.template.templateId;
    if (newTemplateId === lastTemplateId) {
      return; // 중복 스킵
    }
    lastTemplateId = newTemplateId;
    // 템플릿 처리...
  }
}
```

### 렌더링 순서

1. `initState()` - 초기화 확인 및 PlatformView 등록
2. `build()` - HtmlElementView 렌더링 (로딩 오버레이 포함)
3. `PostFrameCallback` - DOM 준비 후 IdevViewer 인스턴스 생성
4. `_waitForContainerAndMount()` - 컨테이너 대기 후 마운트
5. `onReady` - iframe 로드 완료 후 콜백 호출

---

## 성능 최적화

### 1. iframe 재사용
Hot Restart 시 새로운 iframe을 생성하지 않고 기존 것을 재사용합니다.

### 2. 지연 로딩
PlatformView가 DOM에 렌더링될 때까지 300ms 지연하여 안정성을 확보합니다.

### 3. 타임아웃 관리
Ready 타임아웃을 10초로 설정하여 느린 네트워크에서도 정상 작동합니다.

---

## 참고 자료

### 관련 파일
- `lib/src/platform/viewer_web.dart` - 메인 구현
- `assets/viewer-app/index.html` - 뷰어 앱 HTML
- `idev-viewer-js/src/core/IdevViewer.js` - JavaScript 라이브러리

### Flutter Web 공식 문서
- [Platform Views](https://docs.flutter.dev/platform-integration/web/web-specific-code)
- [JavaScript Interop](https://api.flutter.dev/flutter/dart-html/dart-html-library.html)

---

## 라이센스

이 프로젝트는 iDev 프로젝트의 일부입니다.

---

## 지원

문제가 발생하면 다음 정보를 포함하여 이슈를 등록해주세요:

1. Flutter 버전 (`flutter --version`)
2. 브라우저 및 버전
3. 콘솔 에러 로그
4. 재현 단계

---

**작성일**: 2025-10-26  
**버전**: 1.0.0

