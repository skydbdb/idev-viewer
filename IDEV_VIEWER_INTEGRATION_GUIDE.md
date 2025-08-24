# IDev Viewer 통합 가이드

## 📖 개요

IDev Viewer는 Flutter로 개발된 웹 애플리케이션을 타 프레임워크(React, Vue, Angular 등)에서 100% 동일한 렌더링으로 사용할 수 있도록 해주는 JavaScript 라이브러리입니다.

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    타 프레임워크 앱                          │
│  (React/Vue/Angular/vanilla JS)                           │
├─────────────────────────────────────────────────────────────┤
│                    idev-viewer.js                          │
│              (JavaScript 래퍼 라이브러리)                    │
├─────────────────────────────────────────────────────────────┤
│                    Flutter Web 앱                          │
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
    flutterAppPath: '/flutter-app/',
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

| 옵션 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `width` | string | ✅ | 뷰어 너비 (CSS 값) |
| `height` | string | ✅ | 뷰어 높이 (CSS 값) |
| `flutterAppPath` | string | ✅ | Flutter 앱 경로 |
| `template` | object | ✅ | 템플릿 정보 |
| `config` | object | ❌ | 설정 정보 |
| `onReady` | function | ❌ | 준비 완료 콜백 |
| `onError` | function | ❌ | 에러 콜백 |
| `onApiResponse` | function | ❌ | API 응답 콜백 |
| `onStreamData` | function | ❌ | 스트림 데이터 콜백 |
| `onTemplateUpdated` | function | ❌ | 템플릿 업데이트 콜백 |
| `onConfigUpdated` | function | ❌ | 설정 업데이트 콜백 |

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
                flutterAppPath: '/flutter-app/',
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
                flutterAppPath: '/flutter-app/',
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

### Angular

```typescript
import { Component, Input, OnDestroy, OnInit, ElementRef, ViewChild } from '@angular/core';
import { IdevViewer } from '@idev/viewer';

@Component({
    selector: 'app-idev-viewer',
    template: '<div #containerRef class="idev-viewer-container"></div>',
    styles: [`
        .idev-viewer-container {
            width: 100%;
            height: 500px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
    `]
})
export class IdevViewerComponent implements OnInit, OnDestroy {
    @Input() template: any;
    @Input() config: any;
    @ViewChild('containerRef', { static: true }) containerRef!: ElementRef;

    private viewer: any;
    private isReady = false;

    ngOnInit() {
        this.initViewer();
    }

    ngOnDestroy() {
        if (this.viewer) {
            this.viewer.destroy();
            this.viewer = null;
        }
    }

    private initViewer() {
        this.viewer = new IdevViewer({
            width: '100%',
            height: '500px',
            flutterAppPath: '/flutter-app/',
            template: this.template,
            config: this.config,
            onReady: (data: any) => {
                this.isReady = true;
                console.log('뷰어 준비 완료:', data);
            },
            onError: (error: any) => {
                console.error('에러 발생:', error);
            }
        });

        this.viewer.mount(this.containerRef.nativeElement);
    }
}
```

## 🧪 테스트 방법

### 1. 로컬 테스트

```bash
# Python HTTP 서버 시작
python3 -m http.server 8080

# 브라우저에서 접속
# http://localhost:8080/idev-viewer-js/test.html
```

### 2. React 예제 테스트

```bash
cd idev-viewer-js/examples/react-example
npm start
# http://localhost:8081
```

### 3. Vue 예제 테스트

```bash
cd idev-viewer-js/examples/vue-example
npm run serve
# http://localhost:8082
```

## 🔄 개발 워크플로우

### 1. Flutter 코드 수정 후

```bash
# 자동화 스크립트 실행
./build-and-deploy.sh

# 또는 수동으로
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false
cp -r build/web/* idev-viewer-js/
cp -r build/web/* idev-viewer-js/flutter-app/
cd idev-viewer-js && npm run build
```

### 2. NPM 패키지 배포

```bash
./build-and-deploy.sh --publish
```

## 🚨 문제 해결

### 일반적인 문제들

#### 1. Flutter 앱이 로드되지 않음
- `flutterAppPath`가 올바른지 확인
- Flutter Web 빌드가 최신인지 확인
- 브라우저 콘솔에서 에러 메시지 확인

#### 2. 템플릿이 렌더링되지 않음
- `template.script`가 올바른 JSON 형식인지 확인
- Flutter 앱에서 템플릿을 받았는지 확인
- `onReady` 콜백이 호출되었는지 확인

#### 3. CORS 오류
- 개발 서버에서 프록시 설정 확인
- Flutter 앱과 메인 앱이 같은 도메인에서 실행되는지 확인

### 디버깅 팁

1. **콘솔 로그 확인**: Flutter 앱과 JavaScript 간의 메시지 통신 확인
2. **네트워크 탭**: Flutter 앱 파일들이 올바르게 로드되는지 확인
3. **Flutter DevTools**: Flutter 앱의 상태와 위젯 트리 확인

## 📚 추가 리소스

- [Flutter Web 공식 문서](https://docs.flutter.dev/platform-integration/web)
- [PostMessage API 문서](https://developer.mozilla.org/en-US/docs/Web/API/Window/postMessage)
- [iframe 통신 가이드](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/iframe)

## 🤝 기여하기

버그 리포트나 기능 요청은 GitHub Issues를 통해 제출해주세요.

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
