# Changelog

All notable changes to the IDevViewer project will be documented in this file.

## [1.0.0] - 2025-10-26

### ✨ Added
- 초기 릴리즈
- Flutter Web용 읽기 전용 템플릿 뷰어 구현
- iframe 기반 격리 실행 환경
- PlatformView를 사용한 Web 통합
- 동적 템플릿 업데이트 기능
- Hot Restart 자동 감지 및 재사용
- 커스터마이징 가능한 로딩 화면
- 커스터마이징 가능한 에러 처리
- `onReady` 콜백 지원

### 🐛 Fixed
- Hot Restart 시 iframe 중복 생성 문제 해결
- "Container not found" 에러 해결 (PlatformView 등록 타이밍 개선)
- 템플릿 중복 호출 방지 (`lastTemplateId` 중복 체크)
- `window.flutterConfiguration` 지원 중단 경고 해결 (`engineInitializer` 사용)
- 404 에러 해결 (viewer-app assets 등록)
- 초기화 버튼이 재활성화되는 문제 해결
- 뷰어 화면 중첩 문제 해결

### 🔧 Changed
- `dart:ui`에서 `dart:ui_web`로 마이그레이션 (`platformViewRegistry`)
- `idevAppPath`를 `idev-app`으로 사용 (`idev-viewer.js` 포함)
- Ready 타임아웃을 10초로 증가
- 컨테이너 ID를 고정값(`idev-viewer-container-singleton`)으로 변경
- 디버깅 로그 제거 (프로덕션 준비)
- `viewer-app` 제거하고 `idev-app` 단일 경로로 통합

### 📚 Documentation
- 상세한 통합 가이드 작성 (`VIEWER_INTEGRATION_GUIDE.md`)
- README 작성
- 아키텍처 다이어그램 추가
- 트러블슈팅 가이드 추가
- 사용 예제 추가

### 🏗️ Architecture
- JavaScript 전역 변수를 사용한 Hot Restart 대응
- postMessage 기반 Dart-JavaScript 통신
- 중복 방지 플래그 시스템 구현
- DOM 컨테이너 대기 로직 구현 (50회 재시도, 5초)
- 템플릿 polling 중복 감지 메커니즘

### 📦 Assets
- `idev-app` (Flutter 앱 + idev-viewer.js) 포함
- JavaScript 라이브러리 통합 (`idev-viewer.js`)

---

## [Unreleased]

### 🔮 Planned
- 이벤트 리스너 추가 (`onEvent` 콜백)
- 설정 옵션 확장 (테마, 로케일)
- 성능 최적화
- TypeScript 타입 정의 추가
- 단위 테스트 추가
- E2E 테스트 추가

---

## 버전 형식
형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.0.0/)을 따르며,
버전 관리는 [Semantic Versioning](https://semver.org/lang/ko/)을 따릅니다.

### 버전 규칙
- **MAJOR**: 호환되지 않는 API 변경
- **MINOR**: 하위 호환 가능한 기능 추가
- **PATCH**: 하위 호환 가능한 버그 수정

### 변경 유형
- **Added**: 새로운 기능
- **Changed**: 기존 기능 변경
- **Deprecated**: 곧 제거될 기능
- **Removed**: 제거된 기능
- **Fixed**: 버그 수정
- **Security**: 보안 관련 변경
