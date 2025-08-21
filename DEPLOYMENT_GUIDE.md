# 🚀 IDev 배포 및 모니터링 가이드

## 📋 개요
이 가이드는 IDev Flutter 웹 애플리케이션의 배포 및 모니터링 시스템 사용법을 설명합니다.

## 🔧 환경별 배포

### 1. 개발 환경 배포
```bash
# 기본값 (개발 환경)
./deploy-idev.sh

# 명시적 개발 환경 배포
./deploy-idev.sh development
./deploy-idev.sh dev
```

### 2. 프로덕션 환경 배포
```bash
./deploy-idev.sh production
./deploy-idev.sh prod
```

### 3. 로컬 환경 배포
```bash
./deploy-idev.sh local
```

## 🌐 환경별 API 엔드포인트

| 환경 | API 호스트 | 설명 |
|------|------------|------|
| **Production** | `https://production-api.execute-api.ap-northeast-2.amazonaws.com` | 프로덕션 서버 |
| **Development** | `https://17kj30av8h.execute-api.ap-northeast-2.amazonaws.com` | 개발 서버 (현재) |
| **Local** | `http://localhost:3000` | 로컬 개발 서버 |

## 📊 API 모니터링

### 모니터링 데이터 확인
```dart
import 'package:idev_v1/src/core/monitoring/api_monitor.dart';

// 특정 API 통계 확인
final stats = ApiMonitor().getApiStats('/params');
print(stats);

// 전체 API 통계 확인
final allStats = ApiMonitor().getAllApiStats();
allStats.forEach(print);

// 성능 문제가 있는 API 확인
final slowApis = ApiMonitor().getSlowApis();
final highErrorApis = ApiMonitor().getHighErrorRateApis(threshold: 5.0);
```

### 모니터링 지표
- **총 호출 수**: API가 호출된 총 횟수
- **성공률**: 성공한 호출의 비율 (%)
- **평균 응답 시간**: 성공한 호출의 평균 응답 시간
- **오류율**: 실패한 호출의 비율 (%)

## 🔄 에러 처리 및 재시도

### 자동 재시도 조건
- **연결 오류**: 네트워크 연결 문제
- **타임아웃**: 연결, 전송, 수신 타임아웃
- **서버 오류**: 500, 502, 503, 504 상태 코드

### 재시도 설정
- **최대 재시도 횟수**: 3회
- **재시도 간격**: 지수 백오프 (1초, 2초, 4초)

### 사용자 친화적 에러 메시지
- 기술적 오류를 일반 사용자가 이해할 수 있는 메시지로 변환
- 해결 방법 제시
- 재시도 권장

## 🚨 문제 해결

### 1. API 연결 오류
**증상**: `DioExceptionType.connectionError`
**해결 방법**:
- 네트워크 연결 상태 확인
- AWS API Gateway 상태 확인
- CORS 설정 검증

### 2. 서버 오류 (500)
**증상**: `DioExceptionType.badResponse` with status 500
**해결 방법**:
- AWS CloudWatch 로그 확인
- Lambda 함수 오류 분석
- API Gateway 설정 검증

### 3. 느린 응답
**증상**: 응답 시간이 3초 이상
**해결 방법**:
- API 모니터링 데이터 확인
- AWS Lambda 함수 성능 최적화
- 데이터베이스 쿼리 최적화

## 📈 성능 최적화

### 권장사항
1. **API 응답 시간**: 3초 이하 유지
2. **오류율**: 5% 이하 유지
3. **재시도 성공률**: 80% 이상 유지

### 모니터링 주기
- **실시간**: API 호출 시마다
- **일일**: 일일 통계 리포트
- **주간**: 성능 트렌드 분석

## 🔍 로그 분석

### 로그 레벨
- **INFO**: 일반적인 API 호출 정보
- **WARNING**: 느린 응답 (3초 이상)
- **ERROR**: 매우 느린 응답 (10초 이상) 또는 오류

### 로그 예시
```
🚀 API 호출 시작: /params
✅ API 호출 완료: /params (245ms)
⚠️ 느린 응답 감지: /versions (3500ms)
🐌 매우 느린 응답 감지: /users (12000ms)
```

## 🛠️ 개발자 도구

### 브라우저 콘솔에서 확인
```javascript
// API 통계 확인 (개발자 도구 콘솔에서)
console.log('API 통계:', window.flutterApiStats);

// 특정 API 성능 확인
console.log('Params API 성능:', window.flutterApiStats['/params']);
```

### 디버깅 모드
개발 환경에서는 상세한 로그가 출력됩니다:
- API 호출 시작/완료
- 에러 상세 정보
- 재시도 시도 정보
- 성능 분석 결과

## 📚 추가 리소스

- [Flutter Web 배포 가이드](https://docs.flutter.dev/deployment/web)
- [AWS API Gateway 모니터링](https://docs.aws.amazon.com/apigateway/latest/developerguide/monitoring-overview.html)
- [Dio HTTP 클라이언트](https://pub.dev/packages/dio)
