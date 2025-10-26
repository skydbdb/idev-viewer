# Viewer Mode 동기화 문제 해결 요약

## 문제

원본 IDE가 수정된 후 `sync-idev-core-sources.sh`를 실행하면, **뷰어 모드에서 필요한 코드 수정사항이 사라져** 뷰어가 제대로 작동하지 않습니다.

## 해결 방안

### 1. 자동 패치 스크립트 (추천)

동기화 후 자동으로 필요한 수정사항을 적용하는 스크립트를 추가했습니다:

```bash
# 1. 소스 동기화
./scripts/sync-idev-core-sources.sh

# 2. 뷰어 모드 패치 적용 (자동)
./scripts/apply-viewer-mode-patches.sh

# 3. 빌드
cd IdevViewer && flutter pub get && flutter build web --dart-define=BUILD_MODE=viewer
```

### 2. 수동 수정 가이드

자동 스크립트가 작동하지 않는 경우, 다음 파일들을 수정해야 합니다:

#### A. `lib/src/internal/repo/home_repo.dart`

**1. AppStreams 조건부 초기화** (495-499줄)
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

**2. API 메타데이터 기본값 처리** (179-193줄)
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

**3. domainId 보존** (197-210줄)
```dart
// reqParams에서 값이 비어있는 항목을 제거 (단, domainId, method, uri는 유지)
reqParams.removeWhere((key, value) =>
    !['domainId', 'method', 'uri'].contains(key) &&
    (value == null || (value is String && value.isEmpty)));
```

#### B. `lib/src/internal/core/api/api_service.dart`

**EasyLoading 조건부 호출** (139-141줄, 221-223줄)
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

#### C. `lib/src/internal/pms/di/service_locator.dart`

**HomeRepo 싱글톤 등록** (19-30줄)
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

#### D. `lib/src/internal/core/config/env.dart`

**API 호스트 설정** (~40줄)
```dart
case Environment.local:
  return {
    'aws': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
    'legacyBase': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
    'legacyHaksa': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
  };
```

## 영향받는 코드 부분

### 1. Viewer 모드 특화 수정

- **AppStreams 관련**: 뷰어 모드에서는 `AppStreams`가 GetIt에 등록되지 않으므로 조건부 초기화 필요
- **EasyLoading**: 뷰어 모드에서는 `EasyLoading.init()`을 호출하지 않으므로 조건부 사용 필요
- **API 메타데이터**: 초기화 시 `apis` 맵이 비어있을 수 있으므로 기본값 제공 필요
- **HomeRepo 싱글톤**: Viewer 초기화와 TemplateViewerPage가 동일한 인스턴스 사용 필요

### 2. BuildMode 체크로 자동 처리됨

다음 파일들은 `BuildMode.isEditor` 체크로 자동 처리되므로 추가 수정 불필요:
- `home_board.dart`
- `right_tab.dart`
- `stack_item_case.dart`
- 모든 `stack_*_case.dart` 파일들

## 패치 스크립트 작동 원리

`apply-viewer-mode-patches.sh`는 다음과 같이 작동합니다:

1. **파일 존재 확인**: 수정할 파일이 존재하는지 확인
2. **패치 적용**: sed 명령어를 사용하여 필요한 코드 추가/수정
3. **중복 방지**: 이미 수정된 코드인지 확인하여 중복 수정 방지

## 사용 예시

```bash
# 1. 원본 IDE에서 수정사항 발생
# (예: home_repo.dart에 새로운 기능 추가)

# 2. Viewer와 동기화
./scripts/sync-idev-core-sources.sh

# 3. 뷰어 모드 패치 자동 적용
./scripts/apply-viewer-mode-patches.sh

# 4. 빌드 및 테스트
cd IdevViewer && flutter pub get && flutter build web --dart-define=BUILD_MODE=viewer
```

## 참고 문서

- [VIEWER-MODE-IMPLEMENTATION.md](VIEWER-MODE-IMPLEMENTATION.md): 뷰어 모드 구현 상세 가이드
- [VIEWER-MODE-PATCHES.md](VIEWER-MODE-PATCHES.md): 패치 적용 상세 가이드
- [sync-idev-core-sources.sh](../scripts/sync-idev-core-sources.sh): 동기화 스크립트
- [apply-viewer-mode-patches.sh](../scripts/apply-viewer-mode-patches.sh): 패치 적용 스크립트

## 문제 해결

### 패치 스크립트 실행 오류

```bash
# 스크립트 권한 부여
chmod +x scripts/apply-viewer-mode-patches.sh

# 다시 실행
./scripts/apply-viewer-mode-patches.sh
```

### 패치 적용 후에도 오류 발생

1. 수동 수정 가이드를 참조하여 직접 수정
2. `flutter pub get` 후 `flutter analyze` 실행하여 분석
3. Git diff로 수정사항 확인

## 결론

원본 IDE와 동기화 후 뷰어 모드 패치를 자동으로 적용할 수 있는 스크립트와 문서를 제공합니다. 이를 통해 매번 동기화할 때마다 발생하는 수동 수정 작업을 자동화할 수 있습니다.

