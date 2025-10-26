# IDevViewer

Flutter Web용 iDev 템플릿 뷰어 패키지 (읽기 전용 모드)

## 🚀 빠른 시작

### 설치

```yaml
# pubspec.yaml
dependencies:
  idev_viewer:
    path: ../IdevViewer
```

### 기본 사용

```dart
import 'package:idev_viewer/idev_viewer.dart';

IDevViewer(
  config: IDevConfig(
    templateName: 'my_template',
  ),
  onReady: () {
    print('Viewer is ready!');
  },
)
```

### 템플릿 업데이트

```dart
class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  IDevConfig _config = IDevConfig(
    templateName: 'initial',
    template: null,
  );

  void _updateTemplate() {
    setState(() {
      _config = IDevConfig(
        templateName: 'updated',
        template: [
          // 템플릿 데이터
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return IDevViewer(config: _config);
  }
}
```

## 📚 문서

상세한 가이드는 [VIEWER_INTEGRATION_GUIDE.md](./VIEWER_INTEGRATION_GUIDE.md)를 참고하세요.

### 주요 내용
- ✅ 아키텍처 설명
- ✅ 설치 및 설정
- ✅ 템플릿 업데이트 방법
- ✅ 트러블슈팅
- ✅ 기술 세부사항

## 🔧 주요 기능

- **읽기 전용 모드**: 템플릿을 안전하게 표시
- **동적 업데이트**: 런타임에 템플릿 변경 가능
- **iframe 격리**: 메인 앱과 독립적인 실행 환경
- **Hot Restart 지원**: 개발 중 안정적인 동작
- **커스터마이징**: 로딩 화면 및 에러 처리 커스터마이징 가능

## 🐛 트러블슈팅

### 일반적인 문제

**"Container not found" 에러**
- 자동으로 재시도하며, 대부분 자동 해결됩니다

**템플릿이 2번 호출됨**
- 이미 해결됨 - 중복 체크 로직 적용

**404 에러**
- `pubspec.yaml`에 assets 등록 확인:
  ```yaml
  flutter:
    assets:
      - assets/viewer-app/
  ```

더 많은 트러블슈팅 정보는 [가이드 문서](./VIEWER_INTEGRATION_GUIDE.md#트러블슈팅)를 참고하세요.

## 📂 프로젝트 구조

```
IdevViewer/
├── lib/
│   ├── idev_viewer.dart           # Public API
│   └── src/
│       ├── models/                # 데이터 모델
│       └── platform/              # 플랫폼별 구현
│           └── viewer_web.dart    # Web 구현
├── assets/
│   └── idev-app/                  # iDev Flutter 앱 (idev-viewer.js 포함)
├── example/                       # 예제 앱
├── VIEWER_INTEGRATION_GUIDE.md    # 상세 가이드
└── README.md                      # 이 파일
```

## 🎯 사용 사례

### 1. 템플릿 갤러리
```dart
ListView.builder(
  itemCount: templates.length,
  itemBuilder: (context, index) {
    return Card(
      child: SizedBox(
        height: 400,
        child: IDevViewer(
          config: IDevConfig(
            templateName: templates[index].name,
            template: templates[index].data,
          ),
        ),
      ),
    );
  },
)
```

### 2. 템플릿 미리보기
```dart
Dialog(
  child: SizedBox(
    width: 800,
    height: 600,
    child: IDevViewer(
      config: IDevConfig(
        templateName: 'preview',
        template: selectedTemplate,
      ),
      loadingWidget: Center(
        child: CircularProgressIndicator(),
      ),
    ),
  ),
)
```

## 🔄 업데이트 히스토리

### v1.0.0 (2025-10-26)
- ✅ 초기 릴리즈
- ✅ 읽기 전용 뷰어 모드 구현
- ✅ 동적 템플릿 업데이트
- ✅ Hot Restart 지원
- ✅ 중복 템플릿 호출 방지

## 📝 라이센스

이 프로젝트는 iDev 프로젝트의 일부입니다.

## 🤝 기여

이슈 및 PR은 언제나 환영합니다!

---

**더 자세한 정보**: [VIEWER_INTEGRATION_GUIDE.md](./VIEWER_INTEGRATION_GUIDE.md)
