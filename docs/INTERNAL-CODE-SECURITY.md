# Internal Code Security Analysis

## 현재 상황

### ⚠️ 경고: Internal 코드가 이미 패키지에 포함되어 있습니다

```
IdevViewer/lib/src/internal/
├── board/         # 렌더링 로직
├── core/          # API, 인증
├── repo/          # 데이터 관리
├── layout/        # UI 레이아웃
└── ...            # 모든 소스코드
```

**pub.dev에 업로드하면 모든 코드가 공개됩니다.**

## pub.dev 공개 범위

### 공개되는 항목
- ✅ 모든 `.dart` 파일 (소스코드)
- ✅ 모든 `README.md` (문서)
- ✅ `pubspec.yaml` (의존성)
- ✅ `CHANGELOG.md` (변경 내역)

### 비공개 항목
- ❌ `.gitignore`에 있는 파일들
- ❌ 빌드 아티팩트
- ❌ 테스트 데이터

## 현재 아키텍처의 문제점

### 1. Internal 코드가 공개됨

현재 구조:
```
IdevViewer/
├── lib/
│   ├── idev_viewer.dart          # 공개 API
│   └── src/
│       ├── idev_viewer_widget.dart  # 공개
│       ├── models/                    # 공개
│       ├── platform/                  # 공개
│       └── internal/                  # ❌ 공개됨! (의도하지 않음)
│           ├── board/                 # 모든 소스코드 공개
│           ├── core/                  # 모든 로직 공개
│           └── ...
```

**문제**: `lib/src/internal/` 디렉토리가 패키지에 포함되어 있어 업로드 시 모든 소스가 공개됩니다.

### 2. Export 구조 확인

현재 `idev_viewer.dart`:
```dart
library idev_viewer;

export 'src/idev_viewer_widget.dart';
export 'src/models/viewer_config.dart';
export 'src/models/viewer_event.dart';
```

**좋은 점**: explicit export만 사용하고 있어 internal 코드를 직접 import할 수 없습니다.

**나쁜 점**: 여전히 소스코드는 패키지에 포함되어 공개됩니다.

## 해결 방안

### 방안 1: Internal 코드 제거 (권장)

패키지에서 internal 코드를 완전히 제거하고, **외부에서 가져오는 방식**으로 변경:

```
pub.dev package (공개)
├── lib/
│   ├── idev_viewer.dart
│   ├── src/
│   │   ├── idev_viewer_widget.dart
│   │   ├── models/
│   │   └── platform/
│   │       └── viewer_web.dart  # API만 제공
└── pubspec.yaml

사용자 앱
├── lib/
│   └── viewer.dart
└── assets/
    └── internal/        # 사용자가 별도로 관리
        └── [internal 코드]
```

**장점**:
- Internal 코드가 pub.dev에 공개되지 않음
- 사용자가 필요 시 자신의 internal 코드 제공
- 패키지 크기 감소

**단점**:
- 사용자가 수동으로 internal 코드 관리 필요
- 복잡한 설정

### 방안 2: 코드 난독화 (부분적 해결)

코드를 난독화하여 가독성을 낮춤:

```bash
flutter build web --release --dart2js-opt=--minify
```

**장점**:
- 빠른 적용 가능
- 패키지 크기 감소

**단점**:
- 소스코드는 여전히 공개됨 (단지 읽기 어려울 뿐)
- 완전한 보안은 아님

### 방안 3: Internal 코드를 별도 패키지로 분리 (현실적)

Internal 코드를 private Git 저장소로 관리:

```yaml
# pubspec.yaml
dependencies:
  idev_viewer: ^1.0.0
  idev_internal:
    git:
      url: git@github.com:your-org/idev-internal.git
      ref: main
```

**장점**:
- Internal 코드가 pub.dev에 공개되지 않음
- 버전 관리 및 업데이트 용이

**단점**:
- Git 저장소 접근 권한 관리 필요
- 사용자 설정 복잡

### 방안 4: 현재 상태 유지 (권장하지 않음)

현재대로 유지하고 internal 코드를 공개:

**장점**:
- 즉시 사용 가능
- 추가 작업 없음

**단점**:
- ⚠️ **소스코드가 모두 공개됨**
- 보안 위험
- 비즈니스 로직 노출

## 권장 해결책

### 단계별 마이그레이션

1. **Phase 1: 현재 상태 분석**
   ```bash
   # internal 코드 크기 확인
   du -sh IdevViewer/lib/src/internal
   find IdevViewer/lib/src/internal -name "*.dart" | wc -l
   ```

2. **Phase 2: Internal 코드 분리**
   - Internal 코드를 별도 Git 저장소로 이동
   - Private 저장소로 설정

3. **Phase 3: 패키지 구조 변경**
   - `IdevViewer/lib/src/internal/` 제거
   - Git dependency로 internal 코드 참조

4. **Phase 4: 문서 업데이트**
   - 설치 가이드에 internal 코드 설정 추가
   - README 업데이트

## 즉시 조치

### 1. pubspec.yaml 검증

현재 `pubspec.yaml`에 asset 경로가 있는지 확인:

```yaml
# IdevViewer/pubspec.yaml
flutter:
  assets:
    - assets/  # 이것이 internal 코드를 포함하는가?
```

### 2. .gitignore 업데이트

만약 internal 코드를 제외하려면:

```bash
# .gitignore에 추가
lib/src/internal/
```

**주의**: 이렇게 하면 빌드가 실패합니다.

### 3. Package 검증

로컬에서 패키지 내용 확인:

```bash
cd IdevViewer
flutter pub publish --dry-run
```

업로드될 파일 목록을 확인합니다.

## 결론

### ⚠️ 현재 상태

**Internal 코드가 패키지에 포함되어 있어 pub.dev 업로드 시 모두 공개됩니다.**

### 권장 조치

1. **즉시**: Internal 코드가 공개되는 위험 알림 추가 (README)
2. **단기**: Internal 코드를 별도 저장소로 분리
3. **장기**: Git dependency 방식으로 전환

### 코드 난독화는 해결책이 아님

코드 난독화는 **가독성을 낮출 뿐, 완전한 보안이 아닙니다.**
진정한 보안을 위해서는 코드 자체를 패키지에서 제외해야 합니다.

