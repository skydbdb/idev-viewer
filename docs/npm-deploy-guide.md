# IDev Viewer NPM 배포 가이드

## 📋 개요

이 문서는 `npm-deploy.sh` 스크립트를 사용하여 IDev Viewer JavaScript 라이브러리를 NPM에 배포하는 방법을 설명합니다.

## 🚀 배포 스크립트 사용법

### 기본 사용법

```bash
./scripts/npm-deploy.sh
```

### 실행 전 준비사항

1. **NPM 계정 로그인**
   ```bash
   npm login
   ```

2. **패키지 버전 확인**
   ```bash
   cd idev-viewer-js
   cat package.json | grep version
   ```

3. **빌드 상태 확인**
   ```bash
   ls -la idev-viewer-js/dist/
   ```

## 📦 배포 과정

### 1단계: 스크립트 실행
```bash
cd /Users/chaegyugug/Desktop/development/Flutter\ Project/idev_viewer
./scripts/npm-deploy.sh
```

### 2단계: 버전 확인
스크립트가 현재 패키지 버전을 표시합니다:
```
현재 버전: 1.0.0
```

### 3단계: 배포 확인
사용자에게 배포 진행 여부를 묻습니다:
```
배포를 진행하시겠습니까? (y/N):
```

### 4단계: 배포 실행
- `y` 또는 `Y` 입력 시: NPM 배포 진행
- 그 외 입력 시: 배포 취소

## 🔧 스크립트 기능

### 주요 기능
- ✅ 현재 패키지 버전 표시
- ✅ 사용자 확인 프롬프트
- ✅ NPM 배포 실행
- ✅ 배포 결과 확인
- ✅ 컬러풀한 로그 출력

### 색상 코드
- 🔵 **파란색**: 단계별 진행 상황
- 🟢 **초록색**: 성공 메시지
- 🟡 **노란색**: 경고 메시지
- 🔴 **빨간색**: 오류 메시지

## 📋 배포 전 체크리스트

### 필수 확인사항
- [ ] NPM 계정에 로그인되어 있는가?
- [ ] 패키지 버전이 올바른가?
- [ ] `dist/` 폴더에 빌드된 파일들이 있는가?
- [ ] `package.json`의 메타데이터가 올바른가?
- [ ] 테스트가 모두 통과하는가?

### 권장 확인사항
- [ ] CHANGELOG.md가 업데이트되었는가?
- [ ] README.md가 최신 상태인가?
- [ ] 예제들이 정상 작동하는가?

## 🚨 문제 해결

### 일반적인 오류

#### 1. 권한 오류
```bash
❌ NPM 패키지 배포 실패
```
**해결방법:**
```bash
npm login
# 또는
npm whoami
```

#### 2. 버전 충돌
```bash
❌ Version already exists
```
**해결방법:**
```bash
cd idev-viewer-js
npm version patch  # 또는 minor, major
```

#### 3. 빌드 파일 누락
```bash
❌ File not found: dist/idev-viewer.js
```
**해결방법:**
```bash
cd idev-viewer-js
npm run build
```

## 📊 배포 후 확인

### 1. NPM 패키지 확인
- URL: https://www.npmjs.com/package/idev-viewer
- 패키지 정보가 올바르게 표시되는지 확인

### 2. 설치 테스트
```bash
npm install idev-viewer
```

### 3. 예제 업데이트
각 예제에서 새로운 버전을 사용하도록 업데이트:
```bash
cd examples/vanilla-example
npm update idev-viewer
```

## 🔄 버전 관리

### 버전 업데이트 방법

#### 패치 버전 (1.0.0 → 1.0.1)
```bash
cd idev-viewer-js
npm version patch
```

#### 마이너 버전 (1.0.0 → 1.1.0)
```bash
cd idev-viewer-js
npm version minor
```

#### 메이저 버전 (1.0.0 → 2.0.0)
```bash
cd idev-viewer-js
npm version major
```

## 📝 배포 로그 예시

```
🚀 IDev Viewer NPM 배포 시작...
📋 NPM 패키지 배포 시작...
현재 버전: 1.0.0
배포를 진행하시겠습니까? (y/N): y
✅ NPM 패키지 배포 완료!
📦 패키지 URL: https://www.npmjs.com/package/idev-viewer
✅ ✨ 모든 작업이 완료되었습니다!
```

## 🛠️ 고급 사용법

### 자동 배포 (CI/CD)
```bash
# 자동 배포를 위한 환경변수 설정
export NPM_AUTO_DEPLOY=true
./scripts/npm-deploy.sh
```

### 특정 태그로 배포
```bash
cd idev-viewer-js
npm publish --tag beta
```

### 배포 취소
```bash
npm unpublish idev-viewer@1.0.0
```

## 📚 관련 문서

- [NPM 배포 가이드](https://docs.npmjs.com/cli/v8/commands/npm-publish)
- [패키지 버전 관리](https://docs.npmjs.com/about-semantic-versioning)
- [NPM 계정 관리](https://docs.npmjs.com/creating-and-using-organizations)

## 🤝 지원

문제가 발생하거나 질문이 있으시면:
- GitHub Issues: [프로젝트 저장소]/issues
- 이메일: [연락처 정보]

---

**마지막 업데이트:** 2024년 1월
**문서 버전:** 1.0.0
