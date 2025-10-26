# Viewer Mode Patches Guide

## 개요

IDE 원본과 동기화 후 뷰어 모드에서 필요한 코드 수정사항을 자동으로 적용하는 가이드입니다.

## 동기화 프로세스

```
1. sync-idev-core-sources.sh 실행
   ↓
2. apply-viewer-mode-patches.sh 실행 (이 문서)
   ↓
3. Viewer 모드 테스트
```

## 수정된 파일 목록

### 1. `home_repo.dart`

**위치**: `lib/src/internal/repo/home_repo.dart`

#### 수정 1: AppStreams 조건부 초기화

**위치**: `HomeRepo()` 생성자 (약 495-499줄)

**수정 전**:
```dart
HomeRepo() {
  _appStreams = sl<AppStreams>();
  _apiService = sl<ApiService>();
  // ...
}
```

**수정 후**:
```dart
HomeRepo() {
  // 뷰어 모드에서는 AppStreams 사용하지 않음
  if (BuildMode.isEditor) {
    _appStreams = sl<AppStreams>();
  }
  _apiService = sl<ApiService>();
  // ...
}
```

**이유**: 뷰어 모드에서는 `AppStreams`가 GetIt에 등록되지 않음

---

#### 수정 2: API 메타데이터 기본값 처리

**위치**: `addApiRequest()` 메서드 (약 179-193줄)

**수정 전**:
```dart
void addApiRequest(String apiId, Map<String, dynamic> params) {
  final api = apis[apiId];
  
  Map<String, dynamic> reqParams = Map.from(params);
  reqParams['if_id'] = apiId;
  
  reqParams['method'] = api['method'];
  reqParams['uri'] = api['uri'];
  // ...
}
```

**수정 후**:
```dart
void addApiRequest(String apiId, Map<String, dynamic> params) {
  final api = apis[apiId];

  Map<String, dynamic> reqParams = Map.from(params);
  reqParams['if_id'] = apiId;

  // 뷰어 모드에서 API 메타데이터가 없을 때 기본값 사용
  if (api != null) {
    reqParams['method'] = api['method'];
    reqParams['uri'] = api['uri'];
  } else {
    // 뷰어 모드에서 API 메타데이터가 없을 때 기본값 설정
    reqParams['method'] = 'get'; // 기본값
    reqParams['uri'] = apiId; // API ID를 URI로 사용
  }
  // ...
}
```

**이유**: 뷰어 모드 초기화 시 `apis` 맵이 비어있을 수 있음

---

#### 수정 3: domainId 보존

**위치**: `addApiRequest()` 메서드 (약 195-210줄)

**수정 전**:
```dart
// reqParams에서 값이 비어있는 항목을 제거
reqParams.removeWhere((key, value) =>
    (value == null || (value is String && value.isEmpty)));
```

**수정 후**:
```dart
// reqParams에서 값이 비어있는 항목을 제거 (단, domainId, method, uri는 유지)
debugPrint('addApiRequest before reqParams: $reqParams');
reqParams.removeWhere((key, value) =>
    !['domainId', 'method', 'uri'].contains(key) &&
    (value == null || (value is String && value.isEmpty)));
debugPrint('addApiRequest after reqParams: $reqParams');
```

**이유**: API 요청 시 `domainId`, `method`, `uri`는 필수값

---

### 2. `api_service.dart`

**위치**: `lib/src/internal/core/api/api_service.dart`

#### 수정: EasyLoading 조건부 호출

**위치**: `request()` 메서드 (약 139-141줄, 221-223줄)

**수정 전**:
```dart
EasyLoading.show(status: 'loading...');
// ...
EasyLoading.dismiss();
```

**수정 후**:
```dart
// 뷰어 모드에서는 EasyLoading 사용하지 않음
if (BuildMode.isEditor) {
  EasyLoading.show(status: 'loading...');
}
// ...
// 뷰어 모드에서는 EasyLoading dismiss하지 않음
if (BuildMode.isEditor) {
  EasyLoading.dismiss();
}
```

**이유**: 뷰어 모드에서는 `EasyLoading.init()`을 호출하지 않음

---

### 3. `service_locator.dart`

**위치**: `lib/src/internal/pms/di/service_locator.dart`

#### 수정: HomeRepo 싱글톤 등록

**위치**: `initViewerServiceLocator()` 메서드 (약 19-30줄)

**수정 전**:
```dart
void initViewerServiceLocator() {
  //ApiClient
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<ApiService>(
      () => ApiService(apiClient: sl<ApiClient>()));
}
```

**수정 후**:
```dart
void initViewerServiceLocator() {
  //ApiClient
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<ApiService>(
      () => ApiService(apiClient: sl<ApiClient>()));

  // 뷰어 모드에서 HomeRepo는 LazySingleton으로 등록 (단일 인스턴스)
  sl.registerLazySingleton<HomeRepo>(() => HomeRepo());
}
```

**추가 import**:
```dart
import '../../repo/home_repo.dart';
```

**이유**: Viewer 초기화와 TemplateViewerPage가 동일한 HomeRepo 인스턴스 사용

---

### 4. `env.dart`

**위치**: `lib/src/internal/core/config/env.dart`

#### 수정: API 호스트 설정

**위치**: `_getApiHostsForEnvironment()` 메서드 (약 ~40줄)

**수정 전**:
```dart
case Environment.local:
  return {
    'aws': 'http://localhost:3000',
    'legacyBase': 'http://localhost:3000',
    'legacyHaksa': 'http://localhost:3000',
  };
```

**수정 후**:
```dart
case Environment.local:
  return {
    'aws': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
    'legacyBase': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
    'legacyHaksa': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
  };
```

**이유**: 로컬 개발 환경에서 AWS API Gateway 사용

---

## 추가 수정된 파일들 (자동 처리됨)

다음 파일들은 `BuildMode.isEditor` 체크를 통해 자동으로 처리되므로 추가 수정이 필요 없습니다:

- `home_board.dart`: Editor 모드에서만 탭 상태 추가
- `right_tab.dart`: Editor 모드에서만 위젯트리 탭 추가
- `stack_item_case.dart` 등: AppStreams 조건부 초기화

---

## 패치 스크립트 사용 방법

### 1. 기본 사용

```bash
# 1. 원본 IDE와 동기화
./scripts/sync-idev-core-sources.sh

# 2. 뷰어 모드 패치 적용
./scripts/apply-viewer-mode-patches.sh

# 3. 의존성 설치
cd IdevViewer && flutter pub get
```

### 2. 패치 스크립트 확인

패치 스크립트는 다음 파일을 자동으로 수정합니다:

- `lib/src/internal/repo/home_repo.dart`
- `lib/src/internal/core/api/api_service.dart`
- `lib/src/internal/pms/di/service_locator.dart`

### 3. 수동 수정이 필요한 경우

패치 스크립트가 제대로 작동하지 않는 경우, 위의 "수정된 파일 목록" 섹션을 참조하여 수동으로 수정합니다.

---

## 검증 방법

### 1. 빌드 테스트

```bash
cd IdevViewer
flutter build web --dart-define=BUILD_MODE=viewer
```

### 2. 런타임 테스트

```bash
cd IdevViewer/example
flutter run -d chrome --dart-define=BUILD_MODE=viewer
```

### 3. 확인 사항

- ✅ 뷰어 초기화 성공
- ✅ APIs 메타데이터 로드 성공
- ✅ 템플릿 렌더링 성공
- ✅ API 호출 성공 (조회 버튼)

---

## 문제 해결

### 패치 적용 실패

**증상**: `apply-viewer-mode-patches.sh` 실행 시 에러 발생

**해결**:
```bash
# 1. 스크립트 권한 확인
ls -l scripts/apply-viewer-mode-patches.sh

# 2. 권한 부여
chmod +x scripts/apply-viewer-mode-patches.sh

# 3. 다시 실행
./scripts/apply-viewer-mode-patches.sh
```

### 수동 수정 방법

패치 스크립트가 제대로 작동하지 않는 경우:

1. 각 파일의 수정 사항을 위의 "수정된 파일 목록" 섹션에서 확인
2. 수동으로 코드를 수정
3. `flutter pub get && flutter analyze` 실행하여 검증

---

## 참고 자료

- [VIEWER-MODE-IMPLEMENTATION.md](VIEWER-MODE-IMPLEMENTATION.md): 뷰어 모드 구현 상세 가이드
- [viewer_web.dart](../IdevViewer/lib/src/platform/viewer_web.dart): 뷰어 웹 플랫폼 구현
- [예제 앱](../IdevViewer/example/lib/main.dart): 사용 예시

