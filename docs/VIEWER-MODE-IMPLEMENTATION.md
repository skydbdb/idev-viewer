# IDev Viewer Mode Implementation Guide

## 개요

IDEV Viewer는 Flutter 웹 플랫폼에서 **internal 코드를 직접 사용**하여 100% 동일한 렌더링을 제공합니다.

## 아키텍처

### 핵심 구성 요소

```
┌─────────────────────────────────────────────────────┐
│                 IDevViewer Widget                    │
│                                                      │
│  ┌───────────────────────────────────────────────┐ │
│  │         IDevViewerPlatform (Web)              │ │
│  │                                                 │ │
│  │  1. AppConfig 초기화                           │ │
│  │  2. Service Locator 초기화                    │ │
│  │  3. Viewer API 키 설정                        │ │
│  │  4. APIs/Params 로드                           │ │
│  │  5. Template Script 변환                      │ │
│  │                                                 │ │
│  │  ┌───────────────────────────────────────────┐ │
│  │  │      TemplateViewerPage                   │ │
│  │  │                                             │ │
│  │  │  • StackBoard                              │ │
│  │  │  • StackItems (Frame, Chart, Grid 등)      │ │
│  │  │  • Provider<HomeRepo>                     │ │
│  │  └───────────────────────────────────────────┘ │
│  └─────────────────────────────────────────────────┘ │
│                                                      │
│  ┌───────────────────────────────────────────────┐ │
│  │           GetIt Service Locator              │ │
│  │                                                │ │
│  │  • HomeRepo (LazySingleton)                  │ │
│  │  • ApiService                                  │ │
│  │  • ApiClient                                   │ │
│  └────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

### 데이터 흐름

1. **초기화 단계**:
   ```
   initState() 
   → _initializeViewer()
   → AppConfig.initialize()
   → initViewerServiceLocator()
   → AuthService.setViewerApiKey()
   → homeRepo.reqIdeApi('apis', 'params')
   → APIs/Params 응답 수신
   → _isReady = true
   ```

2. **템플릿 로드 단계**:
   ```
   _updateTemplate(Map template)
   → template['items'] 추출
   → jsonEncode(items)
   → _currentScript = script
   → TemplateViewerPage에 전달
   ```

3. **API 호출 단계**:
   ```
   StackSearchItem에서 조회 버튼 클릭
   → homeRepo.addApiRequest('IDEV-EMP_R', params)
   → apis['IDEV-EMP_R']에서 메타데이터 조회
   → ApiService로 실제 API 호출
   → 응답을 StackGridItem에 표시
   ```

## 주요 파일

### 1. `viewer_web.dart`
- **역할**: 웹 플랫폼 전용 뷰어 구현
- **핵심 기능**:
  - Viewer 초기화 및 API 메타데이터 로드
  - 템플릿 데이터를 JSON script로 변환
  - `TemplateViewerPage`로 렌더링 위임
  - Error handling 및 loading state 관리

**주요 메서드**:
- `_initializeViewer()`: Viewer 초기화 및 APIs/Params 로드
- `_updateTemplate()`: 템플릿 데이터를 JSON script로 변환
- `_checkAndLoadTemplate()`: APIs/Params 초기화 완료 확인

### 2. `template_viewer_page.dart`
- **역할**: 내부 뷰어 페이지 (원본 IDE와 동일한 렌더링)
- **사용 위치**: `viewer_web.dart`의 `build()` 메서드에서 사용
- **의존성**: `HomeRepo` (Provider로 주입)

### 3. `service_locator.dart`
- **역할**: 의존성 주입 관리
- **등록된 서비스**:
  - `HomeRepo`: LazySingleton (단일 인스턴스 공유)
  - `ApiService`: LazySingleton
  - `ApiClient`: LazySingleton

### 4. `home_repo.dart`
- **역할**: 중앙 저장소 (API 관리, 상태 관리)
- **핵심 기능**:
  - API 메타데이터 저장 (`apis` 맵)
  - API 요청 처리 (`addApiRequest`)
  - 응답 스트림 제공 (`getApiIdResponseStream`)
  - 뷰어 모드 지원 (Editor 대비 축소된 기능)

### 5. `api_service.dart`
- **역할**: 실제 API 호출 처리
- **특징**: 뷰어 모드에서는 `EasyLoading` 비활성화

## Viewer 모드 구현 세부사항

### 1. API 메타데이터 로드

초기화 시 `apis`와 `params`를 서버에서 가져와 `HomeRepo`에 저장합니다.

```dart
// viewer_web.dart
final homeRepo = sl<HomeRepo>();
homeRepo.versionId = 7;
homeRepo.domainId = 10001;

// API 메타데이터 로드
homeRepo.reqIdeApi('get', ApiEndpointIDE.apis);
homeRepo.reqIdeApi('get', ApiEndpointIDE.params);
```

**응답 예시**:
```json
{
  "result": [
    {
      "if_id": "IDEV-EMP_R",
      "method": "get",
      "uri": "/emp",
      "group": "인사정보 조회"
    }
  ]
}
```

이 데이터는 `homeRepo.apis` 맵에 저장됩니다:
```dart
apis['IDEV-EMP_R'] = {
  'method': 'get',
  'uri': '/emp',
  'group': '인사정보 조회'
}
```

### 2. 템플릿 스크립트 변환

템플릿 데이터를 `TemplateViewerPage`가 이해할 수 있는 JSON script 형식으로 변환합니다.

```dart
// viewer_web.dart
void _updateTemplate(Map<String, dynamic> template) {
  // items 배열만 추출
  final items = template['items'] as List<dynamic>? ?? [];
  
  // JSON으로 변환
  final script = jsonEncode(items);
  
  setState(() {
    _currentScript = script;
  });
}
```

**입력 예시**:
```json
{
  "items": [
    {
      "id": "Frame_4g0e9n",
      "type": "StackFrameItem",
      "content": { ... }
    },
    {
      "id": "Search_vty2c0",
      "type": "StackSearchItem",
      "content": { ... }
    }
  ]
}
```

**출력 예시**:
```json
[
  {
    "id": "Frame_4g0e9n",
    "type": "StackFrameItem",
    "content": { ... }
  },
  {
    "id": "Search_vty2c0",
    "type": "StackSearchItem",
    "content": { ... }
  }
]
```

### 3. API 호출 처리

조회 버튼 클릭 시 `HomeRepo`의 `apis` 맵에서 메타데이터를 조회하고 실제 API를 호출합니다.

```dart
// StackSearchItem에서 조회 버튼 클릭
homeRepo.addApiRequest('IDEV-EMP_R', {
  'id': '1001',
  'name': '홍길동'
});

// home_repo.dart
void addApiRequest(String apiId, Map<String, dynamic> params) {
  final api = apis[apiId]; // 메타데이터 조회
  
  if (api != null) {
    reqParams['method'] = api['method']; // 'get'
    reqParams['uri'] = api['uri'];       // '/emp'
  }
  
  // ApiService로 실제 호출
  apiService.request(...);
}
```

### 4. HomeRepo 싱글톤 패턴

**문제**:
- 초기화 시 생성한 `HomeRepo` 인스턴스와 `TemplateViewerPage`에서 사용하는 인스턴스가 다름
- `apis` 맵이 초기화된 인스턴스에만 존재
- 조회 버튼 클릭 시 `apis` 맵이 비어있음

**해결**:
```dart
// service_locator.dart
void initViewerServiceLocator() {
  // LazySingleton으로 등록 (단일 인스턴스)
  sl.registerLazySingleton<HomeRepo>(() => HomeRepo());
}

// viewer_web.dart
final homeRepo = sl<HomeRepo>(); // GetIt에서 싱글톤 가져옴

// TemplateViewerPage
return Provider<HomeRepo>(
  create: (_) => sl<HomeRepo>(), // 동일한 싱글톤 인스턴스
  child: TemplateViewerPage(...),
);
```

## Viewer 모드 vs Editor 모드

| 항목 | Viewer 모드 | Editor 모드 |
|------|------------|-------------|
| 렌더링 | TemplateViewerPage | HomeBoard |
| API 메타데이터 | 초기화 시 로드 필요 | 미리 로드됨 |
| HomeRepo.constructor | `AppStreams` 없이 생성 | `AppStreams` 포함 |
| EasyLoading | 비활성화 | 활성화 |
| 템플릿 편집 | 불가능 | 가능 |

## 주요 수정 사항

### 1. HomeRepo의 조건부 초기화
```dart
// home_repo.dart
if (BuildMode.isEditor) {
  _appStreams = sl<AppStreams>();
} else {
  _appStreams = null; // Viewer 모드에서는 AppStreams 없음
}
```

### 2. ApiService의 EasyLoading 조건부 호출
```dart
// api_service.dart
if (BuildMode.isEditor) {
  EasyLoading.show();
}
// ...
if (BuildMode.isEditor) {
  EasyLoading.dismiss();
}
```

### 3. Viewer 모드용 API 기본값
```dart
// home_repo.dart
if (api != null) {
  reqParams['method'] = api['method'];
  reqParams['uri'] = api['uri'];
} else {
  // Viewer 모드에서 메타데이터가 없으면 기본값 사용
  reqParams['method'] = 'get';
  reqParams['uri'] = apiId;
}
```

## 설정

### API 호스트 설정
```dart
// env.dart
case Environment.local:
  return {
    'aws': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
    'legacyBase': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
    'legacyHaksa': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
  };
```

### Viewer API 키 설정
```dart
// viewer_web.dart
const apiKey = '7e074a90e6128deeab38d98765e82abe39ec87449f077d7ec85f328357f96b50';
AuthService.setViewerApiKey(apiKey);
```

## 사용 예시

### 기본 사용
```dart
IDevViewer(
  config: IDevConfig(
    apiKey: 'your-api-key',
    template: templateData,
  ),
)
```

### API 메타데이터 로드 후 템플릿 로드
```dart
IDevViewer(
  config: IDevConfig(
    template: null, // 초기에는 템플릿 없음
  ),
  onReady: () {
    // APIs/Params 로드 완료 후 템플릿 로드
    setState(() {
      currentConfig = IDevConfig(template: myTemplate);
    });
  },
)
```

### 동적 템플릿 업데이트
```dart
ElevatedButton(
  onPressed: () {
    setState(() {
      currentConfig = IDevConfig(
        template: newTemplateData, // 새 템플릿 로드
      );
    });
  },
  child: Text('템플릿 업데이트'),
)
```

## 문제 해결

### APIs 맵이 비어있음
- **원인**: `HomeRepo` 싱글톤 패턴 미사용
- **해결**: `initViewerServiceLocator()`에서 `LazySingleton`으로 등록

### 조회 버튼 클릭 시 API 호출 안됨
- **원인**: API 메타데이터가 로드되지 않음
- **해결**: 초기화 시 `reqIdeApi('get', ApiEndpointIDE.apis)` 호출

### 템플릿이 초기 로드됨
- **원인**: `initState()`에서 템플릿을 로드함
- **해결**: `template: null`로 초기화하고 버튼 클릭 시 로드

### API 응답이 화면에 표시 안됨
- **원인**: `HomeRepo` 인스턴스가 다름
- **해결**: Provider에서 `sl<HomeRepo>()`로 동일한 싱글톤 사용

## 참고 자료

- [TemplateViewerPage 소스코드](lib/src/internal/board/board/viewer/template_viewer_page.dart)
- [HomeRepo 소스코드](lib/src/internal/repo/home_repo.dart)
- [Service Locator 소스코드](lib/src/internal/pms/di/service_locator.dart)
- [예제 앱](example/lib/main.dart)

