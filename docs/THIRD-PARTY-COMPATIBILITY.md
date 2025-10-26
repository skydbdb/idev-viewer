# 제3자 개발자 호환성 분석

## 질문

**pub.dev에 공개된 idev_viewer를 import해서 사용하는 제3자 개발자가 공개된 코드로만 실행하는데 문제가 없는가?**

## 답변: ❌ **실행 불가능**

### 문제점

현재 `viewer_web.dart`는 internal 코드를 직접 import 합니다:

```dart
// viewer_web.dart
import '../internal/board/board/viewer/template_viewer_page.dart';
import '../internal/pms/di/service_locator.dart';
import '../internal/repo/home_repo.dart';
import '../internal/core/api/api_endpoint_ide.dart';
import '../internal/core/auth/auth_service.dart';
import '../internal/core/config/env.dart';
```

**문제**: internal 코드가 패키지 내부에 있어야 실행 가능

---

## 시나리오 분석

### 시나리오 1: Internal 코드가 포함된 경우

```
pub.dev 업로드:
idev_viewer/
└── lib/
    ├── idev_viewer.dart
    └── src/
        ├── idev_viewer_widget.dart
        ├── models/
        ├── platform/
        │   └── viewer_web.dart        ← import '../internal/...'
        └── internal/                   ← 여기가 있어야 함
            ├── board/
            ├── core/
            └── ... 314개 파일

결과: ✅ 실행 가능하지만 코드 공개됨
```

### 시나리오 2: Internal 코드가 제외된 경우

```
pub.dev 업로드 (internal 제외):
idev_viewer/
└── lib/
    ├── idev_viewer.dart
    └── src/
        ├── idev_viewer_widget.dart
        ├── models/
        └── platform/
            └── viewer_web.dart        ← import '../internal/...'

internal/ ← 없음!

결과: ❌ 컴파일 에러 발생!
```

**에러**:
```
Error: Could not find module '../internal/board/board/viewer/template_viewer_page.dart'
```

---

## 해결 방법

### 방법 1: Internal 코드를 포함 (현재 방식)

**문제**: 
- Internal 코드가 pub.dev에 공개됨
- 314개 파일이 모두 공개됨

**장점**:
- 실행 가능
- 추가 설정 불필요

**단점**:
- 코드 공개
- 보안 위험

### 방법 2: Internal 코드를 Export만 공개 (권장)

**구조 변경**:

```
lib/
├── idev_viewer.dart
└── src/
    ├── internal/                      ← 여기
    │   └── exported/                  ← 새로운 폴더
    │       ├── template_viewer_page.dart (간접 export)
    │       ├── service_locator.dart
    │       └── home_repo.dart
    └── platform/
        └── viewer_web.dart
```

**viewer_web.dart 수정**:

```dart
// 기존
import '../internal/board/board/viewer/template_viewer_page.dart';

// 변경 후
import 'package:idev_viewer/src/internal/exported/template_viewer_page.dart';
```

**internal/exported/ 구조**:

```dart
// internal/exported/template_viewer_page.dart
export '../../internal/board/board/viewer/template_viewer_page.dart';

// internal/exported/service_locator.dart
export '../../internal/pms/di/service_locator.dart';

// internal/exported/home_repo.dart
export '../../internal/repo/home_repo.dart';
```

**결과**:
- ✅ 실행 가능
- ✅ Internal 상세 코드는 보호됨
- ✅ Export 파일만 공개

**단점**:
- 여전히 internal 구조가 노출됨 (export 경로에서)

### 방법 3: Git Dependency (완전한 보호)

**pubspec.yaml**:

```yaml
dependencies:
  idev_internal:
    git:
      url: git@github.com:your-org/idev-internal.git
```

**viewer_web.dart**:

```dart
import 'package:idev_internal/board/board/viewer/template_viewer_page.dart';
```

**결과**:
- ✅ 실행 가능 (Git 권한 있는 경우)
- ✅ Internal 코드가 pub.dev에 공개되지 않음
- ✅ 완전한 보호

**단점**:
- 사용자가 Git 인증 필요

---

## 제3자 개발자 시나리오

### 시나리오 A: Internal 포함

```
제3자 개발자:
1. flutter pub add idev_viewer
2. import 'package:idev_viewer/idev_viewer.dart';
3. IDevViewer(...)

결과: ✅ 정상 실행
```

### 시나리오 B: Internal 제외 (Git dependency 없음)

```
제3자 개발자:
1. flutter pub add idev_viewer
2. import 'package:idev_viewer/idev_viewer.dart';
3. IDevViewer(...)

결과: ❌ 컴파일 에러
```

### 시나리오 C: Git Dependency

```
제3자 개발자:
1. flutter pub add idev_viewer
2. Git 인증 설정 (SSH key 또는 PAT)
3. import 'package:idev_viewer/idev_viewer.dart';
4. IDevViewer(...)

결과: 
- 권한 있음 → ✅ 실행 가능
- 권한 없음 → ❌ Git 접근 실패
```

---

## 결론 및 권장사항

### 현재 상태 (Internal 포함)

**제3자 개발자가 실행 가능한가?**  
✅ **가능** - 하지만 internal 코드가 모두 공개됨

**문제**:
- 314개 internal 파일이 pub.dev에 공개됨
- 비즈니스 로직 노출

**해결책**:
1. 현재대로 유지 (코드 공개)
2. Git dependency로 전환 (코드 보호)

### 권장: Git Dependency 방식

**이유**:
- ✅ 실행 가능 (권한 있는 사용자)
- ✅ Internal 코드 보호
- ✅ 버전 관리 용이

**제3자 개발자 가이드**:

```
# 사용자가 해야 할 일

1. SSH key 생성 및 GitHub 등록
ssh-keygen -t ed25519 -C "your-email@example.com"
cat ~/.ssh/id_ed25519.pub  # GitHub에 등록

2. 패키지 설치
flutter pub add idev_viewer

3. (자동) Git dependency 다운로드
# idev_internal이 자동으로 ~/.pub-cache에 다운로드됨

4. 사용
import 'package:idev_viewer/idev_viewer.dart';
```

---

## 최종 답변

### 질문: 공개된 코드로만 실행하는데 문제가 없는가?

**답변**: 
- **현재 방식 (internal 포함)**: ✅ 실행 가능, 하지만 코드 공개
- **Internal 분리 후**: ❌ 실행 불가능

### 해결책: Git Dependency

- ✅ 실행 가능 (권한 있는 사용자)
- ✅ 코드 보호
- ⚠️ 설정 복잡

### 권장사항

**선택지**:
1. **현재 유지**: 코드 공개되지만 즉시 사용 가능
2. **Git Dependency**: 코드 보호하지만 설정 복잡
3. **Export 방식**: 부분 보호, 중간 지점

**결론**: Git Dependency 방식으로 전환하는 것을 권장합니다.

