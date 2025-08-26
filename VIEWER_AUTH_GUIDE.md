# idev-viewer 전용 인증 체계 가이드

## 📋 개요

idev-viewer 웹애플리케이션을 위한 전용 인증 체계입니다. 기존 JWT 인증과 별도로 API Key 기반의 인증을 제공하여 뷰어 애플리케이션에서 안전하게 API를 사용할 수 있습니다.

## 🔑 주요 특징

- **API Key 기반 인증**: 30일 유효기간을 가진 고유한 API Key 발급
- **이중 인증**: API Key로 토큰 발급 후, 토큰으로 API 호출
- **사용 통계**: API Key 사용 횟수 및 마지막 사용일 추적
- **보안**: 만료된 API Key 자동 비활성화
- **호환성**: 기존 JWT 인증과 함께 사용 가능
- **권한 분리**: 읽기 작업은 Viewer 인증, 쓰기 작업은 JWT 인증
- **전체 API 지원**: 모든 읽기 API에서 Viewer 인증 사용 가능

### API Key로 인증하여 토큰 발급
```bash
POST AwsApiUrl/viewer-api-keys/authenticate
Content-Type: application/json

{
  "apiKey": "7dcf950962fad7b84cb38a1989bde22ca6d1761a7ee0bfcc39cba72266b09011"
}
```

**응답:**
```json
{
  "result": "0",
  "reason": "Success",
  "data": {
    "token": "bb418b9261991422089e7ba6fca921ca9f74eceb69d15695c9f05af683ec75c783411a9f239c5a23de2d83ed95223322f5d4c4cba37c08307bdeed4c2fd6d90f",
    "user": {
      "userId": 4,
      "email": "skydbdb@gmail.com",
      "name": "채규국",
      "userType": "individual"
    },
    "viewerInfo": {
      "viewerName": "idev-viewer",
      "description": "idev-viewer 웹애플리케이션용",
      "expiresAt": "2025-09-25 15:59:28.000Z",
      "usageCount": 1
    },
    "message": "인증이 성공했습니다."
  }
}
```

## 📚 API 엔드포인트

### Viewer API Key 관리

| 메서드 | 경로 | 설명 | 인증 필요 |
|--------|------|------|-----------|
| POST | `/viewer-api-keys/generate` | 새로운 API Key 생성 | JWT |
| POST | `/viewer-api-keys/authenticate` | API Key로 인증 | 없음 |
| GET | `/viewer-api-keys/list` | 사용자의 API Key 목록 | JWT |
| DELETE | `/viewer-api-keys/deactivate/:apiKey` | API Key 비활성화 | JWT |
| POST | `/viewer-api-keys/cleanup` | 만료된 API Key 정리 | JWT |

### 전체 API (Viewer 인증 지원)

#### **템플릿 API**
| 메서드 | 경로 | 설명 | Viewer 인증 지원 |
|--------|------|------|------------------|
| GET | `/templates` | 템플릿 목록 조회 | ✅ |
| GET | `/templates/detailed` | 상세 템플릿 목록 | ✅ |
| GET | `/templates/:templateId` | 특정 템플릿 조회 | ✅ |
| GET | `/templates/versions` | 템플릿 버전 목록 | ✅ |
| PUT | `/templates/:templateId` | 템플릿 수정 | ❌ (JWT만) |
| POST | `/templates` | 템플릿 생성 | ❌ (JWT만) |
| DELETE | `/templates` | 템플릿 삭제 | ❌ (JWT만) |

#### **API 관리**
| 메서드 | 경로 | 설명 | Viewer 인증 지원 |
|--------|------|------|------------------|
| GET | `/apis` | API 목록 조회 | ✅ |
| POST | `/apis` | API 생성 | ❌ (JWT만) |

#### **파라미터 관리**
| 메서드 | 경로 | 설명 | Viewer 인증 지원 |
|--------|------|------|------------------|
| GET | `/params` | 파라미터 트리 조회 | ✅ |

#### **템플릿 커밋 관리**
| 메서드 | 경로 | 설명 | Viewer 인증 지원 |
|--------|------|------|------------------|
| GET | `/template-commits` | 커밋 목록 조회 | ✅ |
| POST | `/template-commits` | 커밋 생성 | ❌ (JWT만) |
| DELETE | `/template-commits` | 커밋 삭제 | ❌ (JWT만) |

#### **템플릿 버전 관리**
| 메서드 | 경로 | 설명 | Viewer 인증 지원 |
|--------|------|------|------------------|
| GET | `/template-versions` | 버전 목록 조회 | ✅ |
| GET | `/template-versions/script` | 버전별 스크립트 조회 | ✅ |
| POST | `/template-versions` | 버전 생성 | ❌ (JWT만) |
| DELETE | `/template-versions` | 버전 삭제 | ❌ (JWT만) |

#### **카테고리 관리**
| 메서드 | 경로 | 설명 | Viewer 인증 지원 |
|--------|------|------|------------------|
| GET | `/categories/tree` | 사용자별 카테고리 트리 | ✅ |
| GET | `/categories/system` | 시스템 기본 카테고리 | ✅ |
| POST | `/categories` | 카테고리 생성 | ❌ (JWT만) |
| PUT | `/categories/:categoryId` | 카테고리 수정 | ❌ (JWT만) |

#### **템플릿 카테고리 관리**
| 메서드 | 경로 | 설명 | Viewer 인증 지원 |
|--------|------|------|------------------|
| GET | `/template-categories/template/:templateId` | 템플릿별 카테고리 | ✅ |
| GET | `/template-categories/category` | 카테고리별 템플릿 | ✅ |
| GET | `/template-categories/parent` | 부모 카테고리 하위 템플릿 | ✅ |
| POST | `/template-categories` | 템플릿 카테고리 생성 | ❌ (JWT만) |
| POST | `/template-categories/copy-to-my-template` | 내 템플릿으로 복사 | ❌ (JWT만) |
| PUT | `/template-categories/:templateId/:categoryId` | 템플릿 카테고리 수정 | ❌ (JWT만) |
| DELETE | `/template-categories` | 템플릿 카테고리 삭제 | ❌ (JWT만) |
| DELETE | `/template-categories/template/:templateId` | 템플릿의 모든 카테고리 삭제 | ❌ (JWT만) |

#### **템플릿 공개 카테고리 관리**
| 메서드 | 경로 | 설명 | Viewer 인증 지원 |
|--------|------|------|------------------|
| GET | `/template-public-categories/template/:templateId` | 템플릿별 공개 카테고리 | ✅ |
| GET | `/template-public-categories/category/:categoryId` | 카테고리별 공개 템플릿 | ✅ |
| POST | `/template-public-categories` | 공개 카테고리 생성 | ❌ (JWT만) |
| POST | `/template-public-categories/multiple` | 여러 공개 카테고리 생성 | ❌ (JWT만) |
| PUT | `/template-public-categories/:templateId/:categoryId` | 공개 카테고리 수정 | ❌ (JWT만) |
| DELETE | `/template-public-categories` | 공개 카테고리 삭제 | ❌ (JWT만) |
| DELETE | `/template-public-categories/template/:templateId` | 템플릿의 모든 공개 카테고리 삭제 | ❌ (JWT만) |

## 🔐 인증 헤더

### API Key 인증
```
X-Viewer-Api-Key: {API_KEY}
```

### 토큰 인증
```
X-Viewer-Token: {TOKEN}
```

## 📝 사용 예시

### JavaScript/TypeScript 클라이언트
```typescript
class IdevViewerClient {
  private apiKey: string;
  private token: string | null = null;
  private baseUrl: string;

  constructor(apiKey: string, baseUrl: string = 'AwsApiUrl') {
    this.apiKey = apiKey;
    this.baseUrl = baseUrl;
  }

  // API Key로 인증하여 토큰 발급
  async authenticate(): Promise<void> {
    const response = await fetch(`${this.baseUrl}/viewer-api-keys/authenticate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ apiKey: this.apiKey }),
    });

    const data = await response.json();
    if (data.result === '0') {
      this.token = data.data.token;
      console.log('✅ 인증 성공:', data.data.user);
    } else {
      throw new Error('인증 실패: ' + data.error);
    }
  }

  // 템플릿 목록 조회
  async getTemplates(): Promise<any[]> {
    if (!this.token) {
      await this.authenticate();
    }

    const response = await fetch(`${this.baseUrl}/templates`, {
      headers: {
        'X-Viewer-Token': this.token!,
      },
    });

    const data = await response.json();
    return data.data.result;
  }

  // 상세 템플릿 목록 조회
  async getDetailedTemplates(): Promise<any[]> {
    if (!this.token) {
      await this.authenticate();
    }

    const response = await fetch(`${this.baseUrl}/templates/detailed`, {
      headers: {
        'X-Viewer-Token': this.token!,
      },
    });

    const data = await response.json();
    return data.data.result;
  }

  // API 목록 조회
  async getApis(): Promise<any[]> {
    if (!this.token) {
      await this.authenticate();
    }

    const response = await fetch(`${this.baseUrl}/apis`, {
      headers: {
        'X-Viewer-Token': this.token!,
      },
    });

    const data = await response.json();
    return data.data.result;
  }

  // 파라미터 트리 조회
  async getParams(): Promise<any[]> {
    if (!this.token) {
      await this.authenticate();
    }

    const response = await fetch(`${this.baseUrl}/params`, {
      headers: {
        'X-Viewer-Token': this.token!,
      },
    });

    const data = await response.json();
    return data.data.result;
  }

  // 카테고리 트리 조회
  async getCategories(): Promise<any[]> {
    if (!this.token) {
      await this.authenticate();
    }

    const response = await fetch(`${this.baseUrl}/categories/tree`, {
      headers: {
        'X-Viewer-Token': this.token!,
      },
    });

    const data = await response.json();
    return data.data.result;
  }

  // 시스템 카테고리 조회 (인증 불필요)
  async getSystemCategories(): Promise<any[]> {
    const response = await fetch(`${this.baseUrl}/categories/system`);
    const data = await response.json();
    return data.data.result;
  }
}

// 사용 예시
const viewer = new IdevViewerClient('your_api_key_here');

// 템플릿 목록 조회
const templates = await viewer.getTemplates();

// API 목록 조회
const apis = await viewer.getApis();

// 파라미터 조회
const params = await viewer.getParams();

// 카테고리 조회
const categories = await viewer.getCategories();
```

### cURL 예시
```bash
# 1. API Key로 인증하여 토큰 발급
curl -X POST AwsApiUrl/viewer-api-keys/authenticate \
  -H "Content-Type: application/json" \
  -d '{"apiKey": "your_api_key_here"}'

# 2. 토큰으로 템플릿 조회
curl -X GET AwsApiUrl/templates \
  -H "X-Viewer-Token: your_token_here"

# 3. API Key로 직접 템플릿 조회
curl -X GET AwsApiUrl/templates \
  -H "X-Viewer-Api-Key: your_api_key_here"

# 4. 다른 API들도 동일하게 사용 가능
# API 목록 조회
curl -X GET AwsApiUrl/apis \
  -H "X-Viewer-Token: your_token_here"

# 파라미터 트리 조회
curl -X GET AwsApiUrl/params \
  -H "X-Viewer-Token: your_token_here"

# 카테고리 트리 조회
curl -X GET AwsApiUrl/categories/tree \
  -H "X-Viewer-Token: your_token_here"

# 시스템 카테고리 조회 (인증 불필요)
curl -X GET AwsApiUrl/categories/system

# 템플릿 커밋 목록 조회
curl -X GET AwsApiUrl/template-commits \
  -H "X-Viewer-Token: your_token_here"

# 템플릿 버전 목록 조회
curl -X GET AwsApiUrl/template-versions \
  -H "X-Viewer-Token: your_token_here"
```

## 🚨 문제 해결

### 일반적인 오류

| 오류 코드 | 설명 | 해결 방법 |
|-----------|------|-----------|
| `MISSING_VIEWER_API_KEY` | API Key 헤더 누락 | `X-Viewer-Api-Key` 헤더 추가 |
| `MISSING_VIEWER_TOKEN` | 토큰 헤더 누락 | `X-Viewer-Token` 헤더 추가 |
| `INVALID_VIEWER_API_KEY` | 유효하지 않은 API Key | API Key 확인 및 재발급 |
| `INVALID_VIEWER_TOKEN` | 유효하지 않은 토큰 | 토큰 재발급 |
| `VIEWER_AUTH_ERROR` | 인증 처리 오류 | 서버 로그 확인 |

**참고**: 이 가이드는 idev-viewer 전용 인증 체계의 기본 사용법을 다룹니다. 프로덕션 환경에서는 추가적인 보안 조치를 고려하세요.
