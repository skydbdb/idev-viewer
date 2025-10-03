# API 경로 변경 가이드 (Migration Guide)

## 📋 개요

시스템 API와 테넌트 동적 API의 충돌을 방지하고 명확한 구분을 위해 모든 시스템 API에 `/idev/v1` 접두어를 추가했습니다.

## 🎯 변경 목적

- **충돌 방지**: 시스템 API와 테넌트 동적 API 간의 경로 충돌 해결
- **명확한 구분**: 시스템 기능과 사용자 정의 API의 명확한 분리
- **확장성**: 향후 API 버전 관리 지원 (v2, v3 등)
- **직관성**: 개발자가 API 타입을 쉽게 구분 가능
- **라우팅 최적화**: API 관리 기능과 동적 API 실행 기능의 명확한 분리

## 📊 변경된 API 경로 목록

### 시스템 API (변경 전 → 변경 후)

| 기능 | 변경 전 경로 | 변경 후 경로 | 설명 |
|------|-------------|-------------|------|
| **인증** | `/auth` | `/idev/v1/auth` | 사용자 인증 관련 API |
| **템플릿** | `/templates` | `/idev/v1/templates` | 템플릿 관리 API |
| **카테고리** | `/categories` | `/idev/v1/categories` | 카테고리 관리 API |
| **템플릿 카테고리** | `/template-categories` | `/idev/v1/template-categories` | 템플릿 카테고리 API |
| **템플릿 커밋** | `/template-commits` | `/idev/v1/template-commits` | 템플릿 커밋 API |
| **템플릿 버전** | `/template-versions` | `/idev/v1/template-versions` | 템플릿 버전 API |
| **템플릿 다운로드 로그** | `/template-download-logs` | `/idev/v1/template-download-logs` | 다운로드 로그 API |
| **사용자 템플릿 좋아요** | `/user-template-likes` | `/idev/v1/user-template-likes` | 좋아요 API |
| **템플릿 통계** | `/template-stats` | `/idev/v1/template-stats` | 통계 API |
| **공개 카테고리** | `/template-public-categories` | `/idev/v1/template-public-categories` | 공개 카테고리 API |
| **뷰어 API 키** | `/viewer-api-keys` | `/idev/v1/viewer-api-keys` | 뷰어 API 키 관리 |
| **테넌트 등록** | `/tenant-registration` | `/idev/v1/tenant-registration` | 테넌트 등록 API |
| **사용자 관리** | `/users` | `/idev/v1/users` | 테넌트별 사용자 관리 |
| **DB 사용자** | `/db-users` | `/idev/v1/db-users` | DB 사용자 관리 |
| **리소스** | `/resources` | `/idev/v1/resources` | 리소스 관리 API |
| **마스터 테넌트** | `/master/tenants` | `/idev/v1/master/tenants` | 마스터 테넌트 관리 |
| **관리자 트래픽** | `/admin/traffic` | `/idev/v1/admin/traffic` | 트래픽 관리 API |
| **CSV** | `/csv` | `/idev/v1/csv` | CSV 업로드/다운로드 |
| **마스터 스토리지** | `/master/storage` | `/idev/v1/master/storage` | 파일 스토리지 관리 |
| **공개 파일** | `/master/storage/public/*` | `/idev/v1/master/storage/public/*` | 공개 파일 접근 |
| **업로드** | `/upload` | `/idev/v1/upload` | 파일 업로드 API |
| **버전** | `/versions` | `/idev/v1/versions` | 버전 관리 API |

### 동적 API 관리 (변경 전 → 변경 후)

| 기능 | 변경 전 경로 | 변경 후 경로 | 설명 |
|------|-------------|-------------|------|
| **API 목록** | `/apis` | `/idev/v1/apis` | 테넌트 API 목록 조회 |
| **API 상세** | `/apis/:apiId` | `/idev/v1/apis/:apiId` | API 상세 조회 |
| **API 생성** | `POST /apis` | `POST /idev/v1/apis` | API 생성 |
| **API 수정** | `PUT /apis/:apiId` | `PUT /idev/v1/apis/:apiId` | API 수정 |
| **API 삭제** | `DELETE /apis/:apiId` | `DELETE /idev/v1/apis/:apiId` | API 삭제 |
| **API 테스트** | `POST /apis/:apiId/test` | `POST /idev/v1/apis/:apiId/test` | API 테스트 |
| **파라미터 목록** | `/params` | `/idev/v1/params` | 파라미터 목록 조회 |
| **파라미터 상세** | `/params/:paramId` | `/idev/v1/params/:paramId` | 파라미터 상세 조회 |
| **파라미터 생성** | `POST /params` | `POST /idev/v1/params` | 파라미터 생성 |
| **파라미터 수정** | `PUT /params/:paramId` | `PUT /idev/v1/params/:paramId` | 파라미터 수정 |
| **파라미터 삭제** | `DELETE /params/:paramId` | `DELETE /idev/v1/params/:paramId` | 파라미터 삭제 |
| **스키마 조회** | `/schema` | `/idev/v1/schema` | 스키마 조회 |
| **테이블 목록** | `/schema/tables` | `/idev/v1/schema/tables` | 테이블 목록 조회 |
| **테이블 스키마** | `/schema/:tableName` | `/idev/v1/schema/:tableName` | 테이블 스키마 조회 |

### 테넌트 동적 API (변경 없음)

| 경로 패턴 | 설명 | 예시 |
|-----------|------|------|
| `/*` | 테넌트별 동적 API | `/users-list`, `/products`, `/orders`, `/customers` 등 |

### 특수 경로 (변경 없음)

| 경로 | 설명 |
|------|------|
| `/api-docs` | Swagger 문서 |
| `/health` | 헬스체크 |
| `/auth/test` | 인증 테스트 |

## 🔄 마이그레이션 가이드

### 1. 클라이언트 코드 수정

#### JavaScript/TypeScript 예시

```javascript
// 변경 전
const response = await fetch('/api/templates', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});

// 변경 후
const response = await fetch('/idev/v1/templates', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});
```

#### Axios 예시

```javascript
// 변경 전
const api = axios.create({
  baseURL: 'https://api.example.com',
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

// 템플릿 조회
const templates = await api.get('/templates');

// 변경 후
const api = axios.create({
  baseURL: 'https://api.example.com',
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

// 템플릿 조회
const templates = await api.get('/idev/v1/templates');
```

### 2. 환경 변수 설정

```bash
# 변경 전
REACT_APP_API_BASE_URL=https://api.example.com

# 변경 후
REACT_APP_API_BASE_URL=https://api.example.com/idev/v1
```

### 3. API 클라이언트 라이브러리 수정

```javascript
// 변경 전
class ApiClient {
  constructor(baseURL) {
    this.baseURL = baseURL;
  }
  
  async getTemplates() {
    return this.request('/templates');
  }
  
  async getUsers() {
    return this.request('/users');
  }
}

// 변경 후
class ApiClient {
  constructor(baseURL) {
    this.baseURL = baseURL;
  }
  
  async getTemplates() {
    return this.request('/idev/v1/templates');
  }
  
  async getUsers() {
    return this.request('/idev/v1/users');
  }
}
```

## 🎯 최종 라우팅 구조

### 📁 **라우터 분리 구조**

```
시스템 API: /idev/v1/*
├── 인증: /idev/v1/auth
├── 템플릿: /idev/v1/templates
├── 사용자: /idev/v1/users
├── 리소스: /idev/v1/resources
└── ...

API 관리: /idev/v1/*
├── API 관리: /idev/v1/apis
├── 파라미터 관리: /idev/v1/params
├── 스키마 관리: /idev/v1/schema
└── ...

테넌트 동적 API: /*
├── /users-list (A 태넌트)
├── /products (B 태넌트)
├── /orders (C 태넌트)
└── ...

특수 경로: /api-docs, /health, /auth/test
```

### 🔧 **라우터 역할 분담**

| 라우터 | 경로 | 역할 | 설명 |
|--------|------|------|------|
| **시스템 라우터들** | `/idev/v1/*` | 시스템 기능 | 인증, 템플릿, 사용자 관리 등 |
| **API 관리 라우터** | `/idev/v1/*` | API 관리 | API/Param/Schema CRUD 작업 |
| **동적 API 라우터** | `/*` | 동적 API 실행 | 테넌트별 사용자 정의 API 실행 |

## 🔧 문제 해결 과정

### 🚨 **발생했던 문제**

마이그레이션 초기에 다음과 같은 문제가 발생했습니다:

```
❌ API 오류 발생
   Status Code: 404
   URL: https://api.example.com/idev/v1/apis?response_format=json
   Response Data: {result: -1, reason: API_NOT_FOUND, error: API를 찾을 수 없습니다: GET /apis}
```

### 🔍 **문제 원인 분석**

1. **라우팅 충돌**: `dynamicApiRoutes`가 두 번 등록되어 충돌 발생
2. **경로 처리 오류**: `/idev/v1/apis` 요청이 동적 API 라우터로 잘못 처리됨
3. **라우터 역할 혼재**: API 관리 기능과 동적 API 실행 기능이 같은 라우터에 존재

### 🚨 **추가 발생 문제**

마이그레이션 후 추가로 다음과 같은 문제가 발생했습니다:

```
❌ API 오류 발생
   Status Code: 404
   URL: https://api.example.com/table/EMP/data?response_format=json&limit=100&offset=0
   Response Data: {result: -1, reason: API_NOT_FOUND, error: API를 찾을 수 없습니다: GET /table/EMP/data}
```

### 🔍 **추가 문제 원인 분석**

1. **CSV 라우터 경로 문제**: `/table/EMP/data` 경로가 시스템 API이지만 루트 레벨에서 호출됨
2. **라우터 등록 순서**: CSV 라우터가 `/idev/v1/` 경로로만 등록되어 루트 레벨 접근 불가
3. **클라이언트 호환성**: 기존 클라이언트가 루트 레벨에서 CSV API 호출

### ✅ **추가 해결 방법**

1. **CSV 라우터 이중 등록**: 시스템 API와 테넌트 API 모두 지원
2. **라우터 등록 순서 조정**: CSV 라우터를 동적 API 라우터보다 먼저 등록
3. **동적 API 라우터에서 CSV 경로 제외**: `/table`로 시작하는 경로를 명시적으로 제외
4. **로깅 추가**: 어떤 라우터가 처리하는지 명확히 확인
5. **점진적 마이그레이션**: 기존 경로와 새 경로 모두 지원

## ⚠️ 주의사항

### 1. 테넌트 동적 API는 변경되지 않음

테넌트별로 생성한 동적 API는 기존 경로를 그대로 사용합니다:

```javascript
// 테넌트 동적 API (변경 없음)
const usersList = await fetch('/users-list', {
  headers: {
    'X-Tenant-Id': 'tenant-a'
  }
});
```

### 2. API 관리 기능은 새로운 경로 사용

API 생성, 수정, 삭제 등의 관리 기능은 새로운 경로를 사용합니다:

```javascript
// API 관리 (변경됨)
const apis = await fetch('/idev/v1/apis', {
  headers: {
    'X-Tenant-Id': 'tenant-a'
  }
});
```

### 3. 디버깅 로그 확인

서버 로그에서 다음과 같은 메시지를 확인할 수 있습니다:

```
🔧 API 관리 엔드포인트 처리: GET /apis
🔧 Param 관리 엔드포인트 처리: GET /params
🔍 DynamicApiRoutes 처리 중: GET /users-list
✅ 동적 API로 처리: /users-list
```

### 4. 점진적 마이그레이션

기존 클라이언트와의 호환성을 위해 점진적으로 마이그레이션할 수 있습니다:

1. **1단계**: 새로운 경로로 API 호출 테스트
2. **2단계**: 클라이언트 코드 업데이트
3. **3단계**: 기존 경로 지원 중단 (선택사항)

## 🚀 배포 체크리스트

- [ ] 서버 코드 배포 완료
- [ ] 새로운 라우터 구조 적용 확인
- [ ] 클라이언트 코드 업데이트
- [ ] API 문서 업데이트
- [ ] 테스트 환경에서 검증
- [ ] 프로덕션 환경 배포
- [ ] 모니터링 및 오류 확인

## 🧪 테스트 가이드

### 1. **API 관리 기능 테스트**

```bash
# API 목록 조회
curl -X GET "https://api.example.com/idev/v1/apis" \
  -H "X-Tenant-Id: your-tenant-id" \
  -H "Authorization: Bearer your-token"

# 파라미터 목록 조회
curl -X GET "https://api.example.com/idev/v1/params" \
  -H "X-Tenant-Id: your-tenant-id" \
  -H "Authorization: Bearer your-token"

# 스키마 조회
curl -X GET "https://api.example.com/idev/v1/schema" \
  -H "X-Tenant-Id: your-tenant-id" \
  -H "Authorization: Bearer your-token"
```

### 2. **테넌트 동적 API 테스트**

```bash
# 테넌트 동적 API 호출 (기존 경로 유지)
curl -X GET "https://api.example.com/users-list" \
  -H "X-Tenant-Id: your-tenant-id" \
  -H "Authorization: Bearer your-token"

curl -X GET "https://api.example.com/products" \
  -H "X-Tenant-Id: your-tenant-id" \
  -H "Authorization: Bearer your-token"
```

### 3. **시스템 API 테스트**

```bash
# 시스템 API 호출 (새로운 경로)
curl -X GET "https://api.example.com/idev/v1/templates" \
  -H "Authorization: Bearer your-token"

curl -X GET "https://api.example.com/idev/v1/users" \
  -H "Authorization: Bearer your-token"
```

### 4. **CSV API 테스트**

```bash
# 테이블 데이터 조회 (기존 경로 - 루트 레벨)
curl -X GET "https://api.example.com/table/EMP/data?response_format=json&limit=100&offset=0" \
  -H "X-Tenant-Id: your-tenant-id" \
  -H "Authorization: Bearer your-token"

# 테이블 데이터 조회 (새로운 경로 - /idev/v1 접두어)
curl -X GET "https://api.example.com/idev/v1/table/EMP/data?response_format=json&limit=100&offset=0" \
  -H "X-Tenant-Id: your-tenant-id" \
  -H "Authorization: Bearer your-token"
```

### 5. **파일 스토리지 API 테스트**

```bash
# 공개 파일 접근 (새로운 경로 - /idev/v1 접두어)
curl -I "https://api.example.com/idev/v1/master/storage/public/tenant-id/path/to/file.pdf"

# 기존 경로는 더 이상 지원되지 않음 (400 오류)
curl -I "https://api.example.com/master/storage/public/tenant-id/path/to/file.pdf"

# 파일 다운로드 (새로운 경로 - /idev/v1 접두어)
curl -I "https://api.example.com/idev/v1/master/storage/files/tenant-id/path/to/file.pdf/download" \
  -H "X-Tenant-Id: tenant-id" \
  -H "Authorization: Bearer your-token"

# 기존 다운로드 경로는 더 이상 지원되지 않음 (400 오류)
curl -I "https://api.example.com/master/storage/files/tenant-id/path/to/file.pdf/download"
```

### 6. **파일 공개/비공개 설정 API 테스트**

```bash
# 파일 공개 설정 (새로운 경로 - /idev/v1 접두어)
curl -X POST "https://api.example.com/idev/v1/master/storage/files/tenant-id/path/to/file.pdf/access" \
  -H "Content-Type: application/json" \
  -H "X-Tenant-Id: tenant-id" \
  -H "Authorization: Bearer your-token" \
  -d '{"isPublic": true}'

# 파일 비공개 설정
curl -X POST "https://api.example.com/idev/v1/master/storage/files/tenant-id/path/to/file.pdf/access" \
  -H "Content-Type: application/json" \
  -H "X-Tenant-Id: tenant-id" \
  -H "Authorization: Bearer your-token" \
  -d '{"isPublic": false}'

# 파일 공개 상태 조회
curl -X GET "https://api.example.com/idev/v1/master/storage/files/tenant-id/path/to/file.pdf/access" \
  -H "X-Tenant-Id: tenant-id" \
  -H "Authorization: Bearer your-token"

# 기존 경로는 더 이상 지원되지 않음 (400 오류)
curl -X POST "https://api.example.com/master/storage/files/tenant-id/path/to/file.pdf/access" \
  -H "Content-Type: application/json" \
  -H "X-Tenant-Id: tenant-id" \
  -H "Authorization: Bearer your-token" \
  -d '{"isPublic": true}'
```

### 7. **보안 강화 사항**

#### **비공개 파일 보안 강화**
- **문제**: 비공개 파일이 S3 직접 URL로 접근 가능했던 보안 취약점
- **해결**: S3 버킷 정책 수정 및 Lambda 스트리밍으로 변경
- **효과**: 비공개 파일이 브라우저에서 직접 접근 불가

#### **접근 제어 중앙화**
- **모든 파일 접근**: Lambda를 통한 중앙 제어
- **S3 직접 접근**: 완전 차단 (403 Forbidden)
- **로그 추적**: 모든 파일 접근이 Lambda 로그에 기록

#### **보안 테스트 결과**

| 파일 상태 | Lambda API 접근 | S3 직접 URL 접근 | 보안 상태 |
|----------|----------------|-----------------|----------|
| **공개 파일** | ✅ 200 OK | ❌ 403 Forbidden | ✅ **안전** |
| **비공개 파일** | ❌ 403 Forbidden | ❌ 403 Forbidden | ✅ **안전** |

### 8. **로그 확인**

서버 로그에서 다음과 같은 메시지를 확인하세요:

```
✅ 정상 처리 로그:
🔧 API 관리 엔드포인트 처리: GET /apis
🔧 Param 관리 엔드포인트 처리: GET /params
📊 CSV 라우터 처리: GET /table/EMP/data
✅ 동적 API로 처리: /users-list

❌ 오류 로그 (발생하면 안 됨):
🔍 DynamicApiRoutes 처리 중: GET /idev/v1/apis
⏭️ 시스템 라우팅으로 건너뛰기: /idev/v1/apis
🔍 DynamicApiRoutes 처리 중: GET /table/EMP/data
⏭️ CSV 라우팅으로 건너뛰기: /table/EMP/data

✅ 보안 강화 로그:
✅ 공개 파일 Lambda 스트리밍 시작
📤 공개 파일 S3 직접 URL로 리다이렉트: https://idev-tenant-storage.s3.ap-northeast-2.amazonaws.com/...
✅ 공개 파일 다운로드 완료: document.pdf
```

## 📞 지원

마이그레이션 과정에서 문제가 발생하면 개발팀에 문의해주세요.

- **이메일**: dev-team@idev.biz
- **슬랙**: #api-support
- **문서**: [API 문서](https://docs.idev.biz)

---

**업데이트 날짜**: 2024년 12월 19일  
**버전**: v1.1 (라우터 분리 및 문제 해결)  
**작성자**: 개발팀  
**최종 수정**: 라우터 분리 구조 적용 및 디버깅 가이드 추가
