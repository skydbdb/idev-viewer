# 뷰어 API 키 가이드

## 개요

뷰어 API 키는 시스템의 데이터를 읽기 전용으로 접근할 수 있는 안전한 인증 방식입니다. 이 가이드는 뷰어 API 키의 생성, 사용, 관리 방법을 설명합니다.

## 주요 특징

- **읽기 전용 접근**: 데이터 조회만 가능하며 수정/삭제는 불가능
- **만료 시간 설정**: 기본 30일, 최대 설정 가능
- **사용 통계 추적**: 사용 횟수 및 마지막 사용 시간 기록
- **보안성**: 고유한 64자리 API 키와 토큰 생성
- **관리 기능**: 생성, 조회, 비활성화, 정리 기능 제공

## API 엔드포인트

### 기본 URL
```
https://your-domain.com/viewer-api-keys
```

## 1. API 키 생성

### 엔드포인트
```
POST /viewer-api-keys/generate
```

### 인증
- JWT 토큰 필요 (Authorization 헤더)

### 요청 본문
```json
{
  "viewerName": "뷰어 이름",
  "description": "설명 (선택사항)",
  "expiresInDays": 30
}
```

### 요청 예시
```bash
curl -X POST https://your-domain.com/viewer-api-keys/generate \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "viewerName": "데이터 분석팀",
    "description": "월간 리포트 생성을 위한 API 키",
    "expiresInDays": 90
  }'
```

### 응답 예시
```json
{
  "result": "0",
  "reason": "Success",
  "data": {
    "apiKey": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6",
    "token": "b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7l8m9n0o1p2q3r4s5t6u7v8w9x0y1z2",
    "expiresAt": "2024-12-10T00:00:00.000Z",
    "message": "Viewer API Key가 성공적으로 생성되었습니다."
  }
}
```

## 2. API 키 인증

### 엔드포인트
```
POST /viewer-api-keys/authenticate
```

### 인증
- API 키 필요 (요청 본문에 포함)

### 요청 본문
```json
{
  "apiKey": "your-api-key-here"
}
```

### 요청 예시
```bash
curl -X POST https://your-domain.com/viewer-api-keys/authenticate \
  -H "Content-Type: application/json" \
  -d '{
    "apiKey": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6"
  }'
```

### 응답 예시
```json
{
  "result": "0",
  "reason": "Success",
  "data": {
    "token": "b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2g3h4i5j6k7l8m9n0o1p2q3r4s5t6u7v8w9x0y1z2",
    "user": {
      "userId": 123,
      "email": "user@example.com",
      "name": "홍길동",
      "userType": "admin"
    },
    "viewerInfo": {
      "viewerName": "데이터 분석팀",
      "description": "월간 리포트 생성을 위한 API 키",
      "expiresAt": "2024-12-10T00:00:00.000Z",
      "usageCount": 1
    },
    "message": "인증이 성공했습니다."
  }
}
```

## 3. API 키 목록 조회

### 엔드포인트
```
GET /viewer-api-keys/list
```

### 인증
- JWT 토큰 필요 (Authorization 헤더)

### 요청 예시
```bash
curl -X GET https://your-domain.com/viewer-api-keys/list \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 응답 예시
```json
{
  "result": "0",
  "reason": "Success",
  "data": {
    "apiKeys": [
      {
        "id": 1,
        "apiKey": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6",
        "viewerName": "데이터 분석팀",
        "description": "월간 리포트 생성을 위한 API 키",
        "isActive": true,
        "expiresAt": "2024-12-10T00:00:00.000Z",
        "lastUsedAt": "2024-09-10T14:30:00.000Z",
        "usageCount": 15,
        "createdAt": "2024-09-10T09:00:00.000Z",
        "updatedAt": "2024-09-10T14:30:00.000Z"
      }
    ],
    "count": 1
  }
}
```

**참고사항:**
- `apiKey` 필드에는 전체 API Key가 포함됩니다.
- 본인이 생성한 API Key이므로 안전하게 사용할 수 있습니다.

## 4. API 키 비활성화

### 엔드포인트
```
DELETE /viewer-api-keys/deactivate/{apiKey}
```

### 인증
- JWT 토큰 필요 (Authorization 헤더)

### 요청 예시
```bash
curl -X DELETE https://your-domain.com/viewer-api-keys/deactivate/a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 응답 예시
```json
{
  "result": "0",
  "reason": "Success",
  "data": {
    "message": "Viewer API Key가 성공적으로 비활성화되었습니다."
  }
}
```

## 5. 만료된 API 키 정리

### 엔드포인트
```
POST /viewer-api-keys/cleanup
```

### 인증
- JWT 토큰 필요 (Authorization 헤더)
- 관리자 권한 필요

### 요청 예시
```bash
curl -X POST https://your-domain.com/viewer-api-keys/cleanup \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 응답 예시
```json
{
  "result": "0",
  "reason": "Success",
  "data": {
    "message": "만료된 API Key 정리가 완료되었습니다.",
    "cleanedCount": 5
  }
}
```

## API 키 사용 방법

### 1. 헤더를 통한 인증

API 키를 사용하여 다른 API 엔드포인트에 접근할 때는 다음 헤더를 포함해야 합니다:

```bash
curl -X GET https://your-domain.com/api/some-endpoint \
  -H "x-viewer-api-key: your-api-key-here"
```

### 2. 토큰을 통한 인증

API 키 인증 후 받은 토큰을 사용할 수도 있습니다:

```bash
curl -X GET https://your-domain.com/api/some-endpoint \
  -H "x-viewer-token: your-token-here"
```

## 에러 코드

| 코드 | 설명 | HTTP 상태 |
|------|------|-----------|
| `MISSING_VIEWER_API_KEY` | API 키가 헤더에 없음 | 401 |
| `INVALID_VIEWER_API_KEY` | 유효하지 않은 API 키 | 403 |
| `MISSING_VIEWER_NAME` | 뷰어 이름이 없음 | 400 |
| `USER_AUTH_REQUIRED` | 사용자 인증 필요 | 401 |
| `API_KEY_NOT_FOUND` | API 키를 찾을 수 없음 | 404 |
| `VIEWER_AUTH_ERROR` | 뷰어 인증 오류 | 500 |

## 보안 고려사항

### 1. API 키 보관
- API 키는 안전한 곳에 보관하세요
- 환경 변수나 보안 저장소 사용을 권장합니다
- 로그나 코드에 API 키를 노출하지 마세요

### 2. 만료 관리
- 정기적으로 API 키의 만료일을 확인하세요
- 필요에 따라 새로운 API 키를 생성하세요
- 사용하지 않는 API 키는 비활성화하세요

### 3. 접근 제한
- 뷰어 API 키는 읽기 전용 접근만 가능합니다
- 민감한 데이터 접근 시 추가 권한 확인이 필요할 수 있습니다

## 사용 예시

### JavaScript/Node.js
```javascript
const axios = require('axios');

// API 키로 인증
async function authenticateWithApiKey(apiKey) {
  try {
    const response = await axios.post('https://your-domain.com/viewer-api-keys/authenticate', {
      apiKey: apiKey
    });
    
    return response.data.data.token;
  } catch (error) {
    console.error('인증 실패:', error.response.data);
    throw error;
  }
}

// API 키로 데이터 조회
async function fetchDataWithApiKey(apiKey) {
  try {
    const response = await axios.get('https://your-domain.com/api/data', {
      headers: {
        'x-viewer-api-key': apiKey
      }
    });
    
    return response.data;
  } catch (error) {
    console.error('데이터 조회 실패:', error.response.data);
    throw error;
  }
}
```

### Python
```python
import requests

# API 키로 인증
def authenticate_with_api_key(api_key):
    response = requests.post(
        'https://your-domain.com/viewer-api-keys/authenticate',
        json={'apiKey': api_key}
    )
    
    if response.status_code == 200:
        return response.json()['data']['token']
    else:
        raise Exception(f'인증 실패: {response.json()}')

# API 키로 데이터 조회
def fetch_data_with_api_key(api_key):
    response = requests.get(
        'https://your-domain.com/api/data',
        headers={'x-viewer-api-key': api_key}
    )
    
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f'데이터 조회 실패: {response.json()}')
```

## FAQ

### Q: API 키는 언제 만료되나요?
A: 기본적으로 30일 후 만료되며, 생성 시 `expiresInDays` 파라미터로 조정할 수 있습니다.

### Q: API 키를 여러 개 생성할 수 있나요?
A: 네, 사용자당 여러 개의 API 키를 생성할 수 있습니다. 각각 다른 용도로 사용할 수 있습니다.

### Q: API 키가 만료되면 어떻게 하나요?
A: 새로운 API 키를 생성하거나, 기존 API 키의 만료일을 연장할 수 있습니다.

### Q: API 키 사용량을 모니터링할 수 있나요?
A: 네, API 키 목록 조회 시 `usageCount`와 `lastUsedAt` 정보를 확인할 수 있습니다.

### Q: API 키를 삭제할 수 있나요?
A: API 키는 완전히 삭제되지 않고 비활성화됩니다. 비활성화된 API 키는 다시 활성화할 수 없습니다.

## 지원

추가 질문이나 문제가 있으시면 개발팀에 문의해주세요.

- 이메일: dev-team@your-domain.com
- 문서 업데이트: 2024년 9월 10일
