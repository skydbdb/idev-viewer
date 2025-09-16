# IDev Viewer

Flutter로 개발된 웹 애플리케이션을 타 프레임워크(React, Vue, Angular 등)에서 100% 동일한 렌더링으로 사용할 수 있도록 해주는 JavaScript 라이브러리입니다.

## 📖 개요

IDev Viewer는 Flutter Web 앱을 iframe으로 임베드하여 다른 프레임워크에서 사용할 수 있게 해주는 JavaScript 래퍼 라이브러리입니다. PostMessage API를 통해 양방향 통신을 지원하며, 템플릿과 설정을 동적으로 업데이트할 수 있습니다.

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    타 프레임워크 앱                          │
│  (React/Vue/Angular/vanilla JS)                           │
├─────────────────────────────────────────────────────────────┤
│                    idev-viewer.js                          │
│              (JavaScript 래퍼 라이브러리)                    │
├─────────────────────────────────────────────────────────────┤
│                    IDev Web 앱                             │
│              (iframe으로 임베드)                           │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 빠른 시작

### 1. NPM 패키지 설치

```bash
npm install @idev/viewer
```

### 2. 기본 사용법

```javascript
import { IdevViewer } from '@idev/viewer';

// IdevViewer 인스턴스 생성
const viewer = new IdevViewer({
    width: '100%',
    height: '500px',
    idevAppPath: '/idev-app/',
    template: {
        script: JSON.stringify(templateData),
        templateId: 'my_template',
        templateNm: 'My Template',
        commitInfo: 'v1.0.0'
    },
    config: {
        theme: 'dark',
        locale: 'ko'
    },
    onReady: (data) => {
        console.log('뷰어 준비 완료:', data);
    },
    onError: (error) => {
        console.error('에러 발생:', error);
    }
});

// DOM에 마운트
viewer.mount(document.getElementById('viewer-container'));
```

## 📋 API 레퍼런스

### IdevViewer 생성자 옵션

| 옵션 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `width` | string | '100%' | 뷰어 너비 (CSS 값) |
| `height` | string | '600px' | 뷰어 높이 (CSS 값) |
| `idevAppPath` | string | './idev-app/' | IDev 앱 경로 |
| `template` | object | null | 템플릿 정보 |
| `config` | object | {} | 설정 정보 |
| `onReady` | function | null | 준비 완료 콜백 |
| `onError` | function | null | 에러 콜백 |
| `onStateUpdate` | function | null | 상태 업데이트 콜백 |
| `onTemplateUpdated` | function | null | 템플릿 업데이트 콜백 |
| `onConfigUpdated` | function | null | 설정 업데이트 콜백 |
| `onApiResponse` | function | null | API 응답 콜백 |
| `onStreamData` | function | null | 스트림 데이터 콜백 |
| `onItemTap` | function | null | 아이템 탭 콜백 |
| `onItemEdit` | function | null | 아이템 편집 콜백 |
| `autoCreateIframe` | boolean | true | 자동 iframe 생성 |
| `autoSetupMessageHandlers` | boolean | true | 자동 메시지 핸들러 설정 |

### 메서드

#### `mount(container)`
뷰어를 DOM 컨테이너에 마운트합니다.

```javascript
viewer.mount(document.getElementById('viewer-container'));
```

#### `updateTemplate(template)`
템플릿을 업데이트합니다.

```javascript
viewer.updateTemplate({
    script: JSON.stringify(newTemplateData),
    templateId: 'updated_template',
    templateNm: 'Updated Template',
    commitInfo: 'v1.1.0'
});
```

#### `updateConfig(config)`
설정을 업데이트합니다.

```javascript
viewer.updateConfig({
    theme: 'light',
    locale: 'en'
});
```

#### `requestApi(method, endpoint, data, options)`
API 요청을 전송합니다.

```javascript
viewer.requestApi('GET', '/api/data', null, {
    timeout: 5000
});
```

#### `subscribeToStream(streamType, callback)`
스트림 데이터를 구독합니다.

```javascript
const subscriptionId = viewer.subscribeToStream('realtime', (data) => {
    console.log('스트림 데이터:', data);
});
```

#### `resize(width, height)`
뷰어 크기를 조정합니다.

```javascript
viewer.resize('800px', '600px');
```

#### `getState()`
현재 뷰어 상태를 가져옵니다.

```javascript
const state = viewer.getState();
```

#### `destroy()`
뷰어를 제거하고 리소스를 정리합니다.

```javascript
viewer.destroy();
```

## 🔧 프레임워크별 통합 예제

### React

```jsx
import React, { useEffect, useRef, useState } from 'react';
import { IdevViewer } from '@idev/viewer';

function IdevViewerComponent({ template, config }) {
    const containerRef = useRef(null);
    const viewerRef = useRef(null);
    const [isReady, setIsReady] = useState(false);

    useEffect(() => {
        if (containerRef.current && !viewerRef.current) {
            viewerRef.current = new IdevViewer({
                width: '100%',
                height: '500px',
                idevAppPath: '/idev-app/',
                template,
                config,
                onReady: (data) => {
                    setIsReady(true);
                    console.log('뷰어 준비 완료:', data);
                },
                onError: (error) => {
                    console.error('에러 발생:', error);
                }
            });

            viewerRef.current.mount(containerRef.current);
        }

        return () => {
            if (viewerRef.current) {
                viewerRef.current.destroy();
                viewerRef.current = null;
            }
        };
    }, []);

    useEffect(() => {
        if (viewerRef.current && isReady) {
            viewerRef.current.updateTemplate(template);
        }
    }, [template, isReady]);

    return (
        <div ref={containerRef} className="idev-viewer-container" />
    );
}

export default IdevViewerComponent;
```

### Vue

```vue
<template>
    <div ref="containerRef" class="idev-viewer-container" />
</template>

<script>
import { IdevViewer } from '@idev/viewer';

export default {
    name: 'IdevViewerComponent',
    props: {
        template: {
            type: Object,
            required: true
        },
        config: {
            type: Object,
            required: true
        }
    },
    data() {
        return {
            viewer: null,
            isReady: false
        };
    },
    mounted() {
        this.initViewer();
    },
    beforeUnmount() {
        if (this.viewer) {
            this.viewer.destroy();
            this.viewer = null;
        }
    },
    watch: {
        template: {
            handler(newTemplate) {
                if (this.viewer && this.isReady) {
                    this.viewer.updateTemplate(newTemplate);
                }
            },
            deep: true
        },
        config: {
            handler(newConfig) {
                if (this.viewer && this.isReady) {
                    this.viewer.updateConfig(newConfig);
                }
            },
            deep: true
        }
    },
    methods: {
        initViewer() {
            this.viewer = new IdevViewer({
                width: '100%',
                height: '500px',
                idevAppPath: '/idev-app/',
                template: this.template,
                config: this.config,
                onReady: (data) => {
                    this.isReady = true;
                    console.log('뷰어 준비 완료:', data);
                },
                onError: (error) => {
                    console.error('에러 발생:', error);
                }
            });

            this.viewer.mount(this.$refs.containerRef);
        }
    }
};
</script>

<style scoped>
.idev-viewer-container {
    width: 100%;
    height: 500px;
    border: 1px solid #ddd;
    border-radius: 4px;
}
</style>
```

### Next.js

```jsx
import { useEffect, useRef, useState } from 'react';
import Script from 'next/script';

function IdevViewerComponent({ template, config }) {
    const containerRef = useRef(null);
    const viewerRef = useRef(null);
    const [isReady, setIsReady] = useState(false);
    const [isLibraryLoaded, setIsLibraryLoaded] = useState(false);

    useEffect(() => {
        if (isLibraryLoaded && containerRef.current && !viewerRef.current) {
            viewerRef.current = new window.IdevViewer({
                width: '100%',
                height: '500px',
                idevAppPath: '/idev-app/',
                template,
                config,
                onReady: (data) => {
                    setIsReady(true);
                    console.log('뷰어 준비 완료:', data);
                },
                onError: (error) => {
                    console.error('에러 발생:', error);
                }
            });

            viewerRef.current.mount(containerRef.current);
        }

        return () => {
            if (viewerRef.current) {
                viewerRef.current.destroy();
                viewerRef.current = null;
            }
        };
    }, [isLibraryLoaded]);

    return (
        <>
            <Script
                src="/idev-viewer.js"
                onLoad={() => setIsLibraryLoaded(true)}
            />
            <div ref={containerRef} className="idev-viewer-container" />
        </>
    );
}

export default IdevViewerComponent;
```

### Vanilla JavaScript

```html
<!DOCTYPE html>
<html>
<head>
    <title>IDev Viewer Example</title>
    <script src="idev-viewer.js"></script>
</head>
<body>
    <div id="viewer-container"></div>
    
    <script>
        const viewer = new IdevViewer({
            width: '100%',
            height: '500px',
            idevAppPath: './idev-app/',
            template: {
                script: JSON.stringify(templateData),
                templateId: 'my_template',
                templateNm: 'My Template',
                commitInfo: 'v1.0.0'
            },
            config: {
                theme: 'dark',
                locale: 'ko'
            },
            onReady: (data) => {
                console.log('뷰어 준비 완료:', data);
            },
            onError: (error) => {
                console.error('에러 발생:', error);
            }
        });

        viewer.mount(document.getElementById('viewer-container'));
    </script>
</body>
</html>
```

## 🧪 테스트 방법

### 1. 자동화 스크립트 사용 (권장)

```bash
# 전체 빌드 및 배포
./scripts/build-and-deploy.sh

# NPM 패키지 배포 포함
./scripts/build-and-deploy.sh --publish

# 통합 테스트 실행
./scripts/test-integration.sh
```

### 2. 수동 빌드

```bash
# Flutter Web 빌드
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false

# 파일 복사
cp -r build/web/* idev-viewer-js/idev-app/

# JavaScript 라이브러리 빌드
cd idev-viewer-js && npm run build
```

### 3. 로컬 테스트

```bash
# Python HTTP 서버 시작
python3 -m http.server 8080

# 브라우저에서 접속
# - Vanilla 예제: http://localhost:8080/idev-viewer-js/examples/vanilla-example/
# - React 예제: cd idev-viewer-js/examples/react-example && npm start
# - Vue 예제: cd idev-viewer-js/examples/vue-example && npm run serve
# - Next.js 예제: cd idev-viewer-js/examples/nextjs-example && npm run dev
```

## 🏗️ 프로젝트 구조

```
idev_viewer/
├── lib/                          # Flutter 소스 코드
├── idev-viewer-js/              # JavaScript 라이브러리
│   ├── src/                     # 소스 코드
│   ├── dist/                    # 빌드된 라이브러리
│   ├── examples/                # 프레임워크별 예제
│   │   ├── vanilla-example/     # Vanilla JS 예제
│   │   ├── react-example/       # React 예제
│   │   ├── vue-example/         # Vue 예제
│   │   └── nextjs-example/      # Next.js 예제
│   ├── idev-app/                # IDev Web 앱
│   └── package.json
├── scripts/
│   ├── build-and-deploy.sh      # 자동화 스크립트
│   └── test-integration.sh      # 테스트 스크립트
└── README.md
```

## 🔧 개발 환경

- **Flutter**: 3.x 이상
- **Node.js**: 18.x 이상
- **Python**: 3.x (테스트용 HTTP 서버)
- **브라우저**: Chrome, Firefox, Safari, Edge (최신 버전)

## 📦 NPM 패키지

```bash
# 설치
npm install @idev/viewer

# 또는 yarn
yarn add @idev/viewer

# 또는 pnpm
pnpm add @idev/viewer
```

### 패키지 정보

- **패키지명**: `@idev/viewer`
- **버전**: `1.0.0`
- **설명**: "Flutter-based template viewer with 100% identical rendering"
- **키워드**: flutter, viewer, template, iframe, react, vue, angular

## 📋 주요 기능

- ✅ **Flutter Web 앱 임베드**: iframe을 통한 Flutter 앱 렌더링
- ✅ **양방향 통신**: PostMessage API를 통한 실시간 데이터 교환
- ✅ **템플릿 동적 업데이트**: 런타임에 템플릿 변경 가능
- ✅ **설정 변경 지원**: 테마, 언어 등 설정 실시간 변경
- ✅ **다중 프레임워크 지원**: React, Vue, Angular, Next.js 등 모든 프레임워크 지원
- ✅ **TypeScript 지원**: 완전한 타입 정의 제공
- ✅ **API 통신**: RESTful API 요청/응답 지원
- ✅ **스트림 데이터**: 실시간 데이터 스트림 구독
- ✅ **이벤트 핸들링**: 아이템 탭, 편집 등 사용자 상호작용 처리
- ✅ **반응형 디자인**: 다양한 화면 크기에 대응

## 🚨 문제 해결

### 일반적인 문제들

#### 1. IDev 앱이 로드되지 않음
- `idevAppPath`가 올바른지 확인
- IDev Web 빌드가 최신인지 확인
- 브라우저 콘솔에서 에러 메시지 확인
- CORS 설정 확인

#### 2. 템플릿이 렌더링되지 않음
- `template.script`가 올바른 JSON 형식인지 확인
- IDev 앱에서 템플릿을 받았는지 확인
- `onReady` 콜백이 호출되었는지 확인

#### 3. CORS 오류
- 개발 서버에서 프록시 설정 확인
- IDev 앱과 메인 앱이 같은 도메인에서 실행되는지 확인
- Next.js의 경우 `next.config.js`에서 rewrites 설정 확인

#### 4. 라이브러리가 로드되지 않음
- 스크립트 태그의 경로가 올바른지 확인
- 네트워크 탭에서 파일 로드 상태 확인
- 브라우저 캐시 클리어

### 디버깅 팁

1. **콘솔 로그 확인**: IDev 앱과 JavaScript 간의 메시지 통신 확인
2. **네트워크 탭**: IDev 앱 파일들이 올바르게 로드되는지 확인
3. **Flutter DevTools**: IDev 앱의 상태와 위젯 트리 확인
4. **PostMessage 디버깅**: 브라우저 개발자 도구에서 메시지 이벤트 모니터링

## 🔄 개발 워크플로우

### 1. Flutter 코드 수정 후

```bash
# 자동화 스크립트 실행 (권장)
./scripts/build-and-deploy.sh

# 또는 수동으로
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false
cp -r build/web/* idev-viewer-js/idev-app/
cd idev-viewer-js && npm run build
```

### 2. NPM 패키지 배포

```bash
# 버전 업데이트 후 배포
./scripts/build-and-deploy.sh --publish
```

### 3. 테스트

```bash
# 통합 테스트 실행
./scripts/test-integration.sh

# 개별 예제 테스트
cd idev-viewer-js/examples/react-example && npm start
```

## 📚 추가 리소스

- [Flutter Web 공식 문서](https://docs.flutter.dev/platform-integration/web)
- [PostMessage API 문서](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage)
- [iframe 통신 가이드](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe)
- [React 공식 문서](https://react.dev/)
- [Vue 공식 문서](https://vuejs.org/)
- [Next.js 공식 문서](https://nextjs.org/)

## 🤝 기여하기

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

## 📞 지원

문제가 있거나 질문이 있으시면 GitHub Issues를 통해 문의해주세요.

---

**IDev Viewer** - Flutter Web 앱을 모든 프레임워크에서 사용하세요! 🚀