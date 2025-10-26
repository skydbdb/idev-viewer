# Internal Code Separation Guide

## 개요

internal 코드를 별도 저장소로 분리하여 pub.dev에 공개하지 않고, 패키지에서 참조하는 방법을 설명합니다.

## Git Dependency 방식

### 1. 현재 구조 (문제점)

```
idev_viewer/
├── lib/
│   ├── idev_viewer.dart          # 공개 API
│   └── src/
│       └── internal/              # ❌ 공개됨!
│           ├── board/            # 모든 소스코드
│           ├── core/              # 모든 로직
│           └── ...                # 314개 파일
└── pubspec.yaml
```

**문제**: `lib/` 안에 있으면 pub.dev에 공개됨

---

### 2. 분리 후 구조 (해결책)

```
idev_viewer/ (공개 저장소)
├── lib/
│   ├── idev_viewer.dart
│   └── src/
│       ├── idev_viewer_widget.dart
│       ├── models/
│       └── platform/
│           └── viewer_web.dart   # API만 제공
└── pubspec.yaml
    └── dependencies:
        idev_internal: ^1.0.0      # Git dependency

idev_internal/ (private 저장소)
├── lib/
│   ├── board/
│   ├── core/
│   └── ...
└── pubspec.yaml
```

**해결**: internal 코드가 pub.dev에 공개되지 않음

---

## 구현 방법

### Step 1: Internal 코드를 별도 저장소로 이동

#### 1-1. 내부 저장소 생성

```bash
# Private Git 저장소 생성 (예: GitHub Private Repository)
# https://github.com/your-org/idev-internal (private)

# 저장소 초기화
mkdir idev-internal
cd idev-internal
git init
git remote add origin git@github.com:your-org/idev-internal.git
```

#### 1-2. Internal 코드 복사

```bash
# idev_viewer 저장소에서
cd /Users/chaegyugug/Desktop/development/Flutter\ Project/idev_viewer

# internal 코드를 별도 디렉토리로 복사
cp -r IdevViewer/lib/src/internal ~/temp/idev-internal/lib/

# 새 저장소로 이동
cd ~/temp/idev-internal

# pubspec.yaml 생성
cat > pubspec.yaml << 'EOF'
name: idev_internal
description: Internal code for IDev Viewer (private)
version: 1.0.0
homepage: https://idev.biz

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # ... 필요한 의존성들
EOF

# 커밋 및 푸시
git add .
git commit -m "Initial commit: internal code"
git push origin main
```

#### 1-3. 저장소를 Private로 설정

GitHub에서:
1. Settings → General
2. Danger Zone → Change repository visibility
3. Change to Private

---

### Step 2: idev_viewer 패키지에서 참조

#### 2-1. pubspec.yaml 수정

```yaml
# idev_viewer/pubspec.yaml
name: idev_viewer
description: IDev-based template viewer plugin
version: 1.0.7

dependencies:
  flutter:
    sdk: flutter
  
  # Internal 코드를 Git dependency로 참조
  idev_internal:
    git:
      url: git@github.com:your-org/idev-internal.git
      ref: main
  
  # 또는 HTTPS 방식 (personal access token 필요)
  # idev_internal:
  #   git:
  #     url: https://github.com/your-org/idev-internal.git
  #     ref: main
  
  # 다른 의존성...
  universal_html: ^2.2.4
  # ...
```

#### 2-2. viewer_web.dart 수정

기존 코드:
```dart
import '../internal/board/board/viewer/template_viewer_page.dart';
import '../internal/pms/di/service_locator.dart';
import '../internal/repo/home_repo.dart';
```

**변경 불필요**: Git dependency로 참조하면 패키지 경로로 자동 import됨

수정된 코드:
```dart
import 'package:idev_internal/board/board/viewer/template_viewer_page.dart';
import 'package:idev_internal/pms/di/service_locator.dart';
import 'package:idev_internal/repo/home_repo.dart';
```

또는:

```dart
// viewer_web.dart
import 'package:idev_internal/board/board/viewer/template_viewer_page.dart' as internal;
import 'package:idev_internal/pms/di/service_locator.dart' as internal;
import 'package:idev_internal/repo/home_repo.dart' as internal;

// 사용
child: internal.TemplateViewerPage(...)
```

---

## 보호 메커니즘

### 1. pub.dev에 업로드되는 내용

#### idev_viewer 패키지 (공개)

```
pub.dev 에 업로드:
├── lib/
│   ├── idev_viewer.dart
│   ├── src/
│   │   ├── idev_viewer_widget.dart
│   │   ├── models/
│   │   └── platform/
│   │       └── viewer_web.dart
│   └── ...
└── pubspec.yaml
    └── dependencies:
        idev_internal:             # Git dependency 선언만
          git:
            url: git@github.com:...
```

**보호됨**:
- ✅ internal 코드 소스가 패키지에 포함되지 않음
- ✅ pubspec.yaml에 Git URL만 존재
- ✅ 사용자는 Git 권한이 있어야 내부 코드에 접근 가능

#### idev_internal 저장소 (비공개)

```
Private GitHub 저장소:
├── lib/
│   ├── board/
│   ├── core/
│   └── ... (314개 파일)
```

**보호됨**:
- ✅ Private 저장소로만 접근 가능
- ✅ Git 인증 필요 (SSH key 또는 Personal Access Token)
- ✅ 권한이 있는 사용자만 코드 확인 가능

---

### 2. 사용자가 패키지를 설치할 때

#### 시나리오 1: 일반 사용자 (pub.dev에서 설치)

```bash
flutter pub add idev_viewer
```

**결과**:
```
Dependencies:
  idev_viewer: ^1.0.7

Internal dependencies (transitive):
  idev_internal: git@github.com:your-org/idev-internal.git
```

**내부 코드 접근**:
- ❌ 기본적으로 Git 저장소에 접근 불가
- ❌ internal 코드를 다운로드할 수 없음
- ❌ 패키지 사용 불가

#### 시나리오 2: 권한이 있는 사용자

```bash
# SSH key를 GitHub에 등록
ssh-add ~/.ssh/id_rsa

# 패키지 설치
flutter pub add idev_viewer
```

**결과**:
- ✅ Git 저장소에 SSH로 접근
- ✅ internal 코드 자동 다운로드
- ✅ 패키지 사용 가능

**코드 접근**:
```bash
# internal 코드 위치
~/.pub-cache/hosted/pub.dev/idev_viewer-x.x.x/
# 또는
~/.pub-cache/git/cache/idev-internal-xxxx/

# 여기서 internal 코드 확인 가능 (권한이 있는 경우)
```

---

### 3. 보안 레이어

```
┌─────────────────────────────────────┐
│     pub.dev (공개)                  │
│                                     │
│  idev_viewer 패키지                 │
│  • Public API만 포함                │
│  • Git dependency 선언만            │
└──────────────────┬──────────────────┘
                   │
                   │ Git dependency 참조
                   ↓
┌─────────────────────────────────────┐
│  Private Git Repository            │
│  (GitHub Private)                  │
│                                     │
│  idev_internal                     │
│  • 전체 internal 코드               │
│  • 314개 파일                        │
│  • 인증 필요                         │
└─────────────────────────────────────┘
```

**보호 메커니즘**:
1. **pub.dev**: Internal 코드를 포함하지 않음
2. **Git 저장소**: Private로 설정
3. **접근 제어**: SSH/PAT 인증 필요
4. **권한 관리**: GitHub 팀/조직 권한으로 제어

---

## 장단점

### 장점

1. ✅ **완전한 코드 보호**: internal 코드가 pub.dev에 공개되지 않음
2. ✅ **버전 관리**: Internal 코드를 독립적으로 버전 관리 가능
3. ✅ **업데이트 용이**: Internal 수정 시 Git만 업데이트하면 패키지에 반영
4. ✅ **협업 관리**: Private 저장소로 팀 접근 제어 가능

### 단점

1. ⚠️ **복잡한 설정**: Git 인증 설정 필요
2. ⚠️ **사용자 복잡성**: SSH key 또는 Personal Access Token 필요
3. ⚠️ **유지보수**: 두 개의 저장소 관리 필요

---

## 구현 예시

### 실제 코드 예시

#### pubspec.yaml

```yaml
name: idev_viewer
version: 1.0.7

dependencies:
  flutter:
    sdk: flutter
  
  # Internal 코드를 Git dependency로
  idev_internal:
    git:
      url: git@github.com:skydbdb/idev-internal.git
      ref: main
      # 또는 특정 버전
      # ref: v1.0.0
```

#### viewer_web.dart

```dart
// 기존
import '../internal/board/board/viewer/template_viewer_page.dart';
import '../internal/pms/di/service_locator.dart';
import '../internal/repo/home_repo.dart';

// 변경 후
import 'package:idev_internal/board/board/viewer/template_viewer_page.dart';
import 'package:idev_internal/pms/di/service_locator.dart';
import 'package:idev_internal/repo/home_repo.dart';
```

---

## 마이그레이션 체크리스트

### 1. Internal 저장소 준비
- [ ] GitHub에 private 저장소 생성
- [ ] Internal 코드 복사
- [ ] pubspec.yaml 생성
- [ ] 첫 커밋 및 푸시

### 2. idev_viewer 패키지 수정
- [ ] `lib/src/internal/` 디렉토리 제거
- [ ] pubspec.yaml에 Git dependency 추가
- [ ] import 경로 수정 (`package:idev_internal/...`)

### 3. 테스트
- [ ] 로컬에서 테스트
- [ ] Git dependency 동작 확인
- [ ] 빌드 테스트

### 4. 배포
- [ ] pub.dev에 업로드
- [ ] Internal 코드가 포함되지 않았는지 확인

---

## 결론

### 내 코드가 보호되는 이유

1. **pub.dev**: Internal 코드를 포함하지 않음
2. **Git 저장소**: Private로 설정되어 인증 필요
3. **접근 제어**: 권한이 있는 사용자만 내부 코드에 접근 가능

### 핵심

```
보호 = pub.dev에 업로드하지 않음 + Private Git 저장소 + 인증 필요
```

pub.dev에는 API만 노출되고, 실제 internal 코드는 private 저장소에만 존재하며, Git 인증이 있는 사용자만 접근할 수 있습니다.

