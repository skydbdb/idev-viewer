# IDev Viewer

Flutter로 개발된 웹 애플리케이션을 타 프레임워크(React, Vue, Angular 등)에서 100% 동일한 렌더링으로 사용할 수 있도록 해주는 JavaScript 라이브러리입니다.

## 🚀 빠른 시작

### 1. 자동화 스크립트 사용 (권장)

```bash
# 전체 빌드 및 배포
./build-and-deploy.sh

# NPM 패키지 배포 포함
./build-and-deploy.sh --publish
```

### 2. 수동 빌드

```bash
# Flutter Web 빌드
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false

# 파일 복사
cp -r build/web/* idev-viewer-js/
cp -r build/web/* idev-viewer-js/flutter-app/

# JavaScript 라이브러리 빌드
cd idev-viewer-js && npm run build
```

## 📚 상세 가이드

- **[통합 가이드](./IDEV_VIEWER_INTEGRATION_GUIDE.md)** - 타 프레임워크에서 사용하는 방법
- **[실행 테스트 매뉴얼](./idev-viewer-js/EXECUTION_TEST_MANUAL.md)** - 상세한 테스트 절차

## 🧪 테스트

### 통합 테스트 실행

```bash
./test-integration.sh
```

### 개별 테스트

```bash
# Python HTTP 서버 시작
python3 -m http.server 8080

# 테스트 URL
# http://localhost:8080/idev-viewer-js/test.html
```

## 📦 NPM 패키지

```bash
npm install @idev/viewer
```

## 🏗️ 프로젝트 구조

```
idev_viewer/
├── lib/                          # Flutter 소스 코드
├── idev-viewer-js/              # JavaScript 라이브러리
│   ├── src/                     # 소스 코드
│   ├── dist/                    # 빌드된 라이브러리
│   ├── examples/                # React/Vue 예제
│   ├── flutter-app/             # Flutter Web 앱
│   └── package.json
├── build-and-deploy.sh          # 자동화 스크립트
├── test-integration.sh          # 테스트 스크립트
└── README.md
```

## 🔧 개발 환경

- Flutter 3.x
- Node.js 18+
- Python 3.x (테스트용 HTTP 서버)

## 📋 주요 기능

- ✅ Flutter Web 앱을 iframe으로 임베드
- ✅ PostMessage를 통한 양방향 통신
- ✅ 템플릿 동적 업데이트
- ✅ 설정 변경 지원
- ✅ React, Vue, Angular 등 모든 프레임워크 지원
- ✅ TypeScript 지원

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 📞 지원

문제가 있거나 질문이 있으시면 GitHub Issues를 통해 문의해주세요. 