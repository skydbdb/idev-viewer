# Asset Sync Script Deprecated

## 현재 상황

**`sync-idev-viewer-assets.sh` 스크립트는 더 이상 필요하지 않습니다.**

### 이유

현재 Web 플랫폼은 **internal 코드를 직접 사용**하도록 변경되었습니다:

1. **이전 방식**: `idev-viewer-js` (npm 패키지) + iframe
2. **현재 방식**: `internal` 코드 직접 사용 + `TemplateViewerPage`

### 변경 내역

- `viewer_web.dart`가 `idev-app` 또는 `idev-viewer.js` 파일을 사용하지 않음
- 모든 플랫폼에서 internal 코드 직접 사용
- Web에서는 `TemplateViewerPage`를 사용하여 렌더링

## 스크립트 상태

| 스크립트 | 상태 | 설명 |
|---------|------|------|
| `sync-idev-core-sources.sh` | ✅ **필수** | Internal 코드 동기화 |
| `apply-viewer-mode-patches.sh` | ✅ **필수** | Viewer 모드 패치 적용 |
| `sync-idev-viewer-assets.sh` | ❌ **불필요** | Internal 코드 사용으로 대체됨 |

## 현재 에셋 사용 여부

### Web 플랫폼

**사용하지 않음**: `IdevViewer/web/assets/` 폴더의 모든 파일

**이유**: `viewer_web.dart`에서 `internal` 코드 직접 사용

```dart
// viewer_web.dart
import '../internal/board/board/viewer/template_viewer_page.dart';
import '../internal/pms/di/service_locator.dart';
import '../internal/repo/home_repo.dart';
// ...
// idev-app, idev-viewer.js 사용 안 함
```

### Android, iOS, Windows, macOS, Linux

**상태**: 아직 구현되지 않음 (Coming Soon)

**계획**: 각 플랫폼도 Web과 동일하게 internal 코드 직접 사용 예정

## 정리

### 삭제 가능한 항목

1. **`sync-idev-viewer-assets.sh`**: 더 이상 필요 없음
2. **`idev-viewer-js/` 폴더**: npm 패키지용으로만 사용 (Flutter 패키지에 포함하지 않음)

### 유지해야 할 항목

1. **`sync-idev-core-sources.sh`**: Internal 코드 동기화 (필수)
2. **`apply-viewer-mode-patches.sh`**: Viewer 모드 패치 (필수)

## 현재 아키텍처

```
┌─────────────────────────────────────────────────┐
│               IDevViewer Package                │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │         viewer_web.dart (Web)              │ │
│  │                                             │ │
│  │  • internal 코드 직접 import                │ │
│  │  • TemplateViewerPage 사용                 │ │
│  │  • idev-app/idev-viewer.js 사용 안 함      │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │         viewer_android.dart (예정)         │ │
│  │  • internal 코드 직접 import                │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  ┌────────────────────────────────────────────┐ │
│  │         viewer_ios.dart (예정)            │ │
│  │  • internal 코드 직접 import                │ │
│  └────────────────────────────────────────────┘ │
│                                                  │
│  • Android, iOS 등은 아직 WebView 방식 예정     │
│  • 그러나 WebView 내부에서도 internal 코드 사용│
└─────────────────────────────────────────────────┘
```

## 권장 사항

### 즉시

1. `sync-idev-viewer-assets.sh` 스크립트 삭제 또는 주석 처리
2. README에서 동기화 단계 업데이트:
   ```bash
   # 이전 (더 이상 사용 안 함)
   ./scripts/sync-idev-viewer-assets.sh
   
   # 현재 (실제 사용 중)
   ./scripts/sync-idev-core-sources.sh
   ./scripts/apply-viewer-mode-patches.sh
   ```

### 미래 (Android, iOS 등 구현 시)

각 플랫폼도 Web과 동일하게 internal 코드 직접 사용:
- `viewer_android.dart`, `viewer_ios.dart` 등에서 internal 코드 import
- WebView 내부에서도 iframe이 아닌 internal 코드 직접 사용

## 결론

**`sync-idev-viewer-assets.sh`는 더 이상 사용하지 않아도 됩니다.**

현재 Web 플랫폼은 internal 코드를 직접 사용하며, 다른 플랫폼도 동일한 방식으로 구현될 예정입니다.

