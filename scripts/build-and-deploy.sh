#!/bin/bash

# IDev Viewer 빌드 및 배포 자동화 스크립트
# 사용법: ./scripts/build-and-deploy.sh [--publish]

set -e

echo "🚀 IDev Viewer 빌드 및 배포 시작..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 함수 정의
print_step() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 1. Flutter Web 빌드
print_step "1. Flutter Web 빌드 시작..."
if flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false; then
    print_success "Flutter Web 빌드 완료"
else
    print_error "Flutter Web 빌드 실패"
    exit 1
fi

# 2. Flutter 앱 파일 복사
print_step "2. Flutter 앱 파일 복사..."

# 메인 flutter-app 디렉토리로 복사
if cp -r build/web/* idev-viewer-js/flutter-app/; then
    print_success "메인 flutter-app 디렉토리로 파일 복사 완료"
else
    print_error "메인 flutter-app 파일 복사 실패"
    exit 1
fi

# 예제들의 flutter-app 디렉토리로 복사
print_step "3. 예제들의 flutter-app 디렉토리로 복사..."

# React 예제
if cp -r build/web/* idev-viewer-js/examples/react-example/public/flutter-app/; then
    print_success "React 예제 flutter-app 복사 완료"
    # React 예제의 base href 수정
    sed -i '' 's|<base href="/">|<base href="/flutter-app/">|g' idev-viewer-js/examples/react-example/public/flutter-app/index.html
    print_success "React 예제 base href 수정 완료"
else
    print_error "React 예제 flutter-app 복사 실패"
    exit 1
fi

# Vue 예제
if cp -r build/web/* idev-viewer-js/examples/vue-example/public/flutter-app/; then
    print_success "Vue 예제 flutter-app 복사 완료"
    # Vue 예제의 base href 수정
    sed -i '' 's|<base href="/">|<base href="/flutter-app/">|g' idev-viewer-js/examples/vue-example/public/flutter-app/index.html
    print_success "Vue 예제 base href 수정 완료"
else
    print_error "Vue 예제 flutter-app 복사 실패"
    exit 1
fi

# Vanilla 예제
if cp -r build/web/* idev-viewer-js/examples/vanilla-example/flutter-app/; then
    print_success "Vanilla 예제 flutter-app 복사 완료"
    # Vanilla 예제의 base href 수정
    sed -i '' 's|<base href="/">|<base href="./">|g' idev-viewer-js/examples/vanilla-example/flutter-app/index.html
    print_success "Vanilla 예제 base href 수정 완료"
else
    print_error "Vanilla 예제 flutter-app 복사 실패"
    exit 1
fi

# 4. JavaScript 라이브러리 빌드
print_step "4. JavaScript 라이브러리 빌드..."
cd idev-viewer-js

if npm run build; then
    print_success "JavaScript 라이브러리 빌드 완료"
else
    print_error "JavaScript 라이브러리 빌드 실패"
    exit 1
fi

cd .. # 원래 디렉토리로 돌아가기

# 5. 예제들에 빌드된 라이브러리 복사
print_step "5. 예제들에 빌드된 라이브러리 복사..."

# React 예제
if cp idev-viewer-js/dist/idev-viewer.js idev-viewer-js/examples/react-example/public/idev-viewer.js; then
    print_success "React 예제에 라이브러리 복사 완료"
else
    print_error "React 예제 라이브러리 복사 실패"
    exit 1
fi

# Vue 예제
if cp idev-viewer-js/dist/idev-viewer.js idev-viewer-js/examples/vue-example/public/idev-viewer.js; then
    print_success "Vue 예제에 라이브러리 복사 완료"
else
    print_error "Vue 예제 라이브러리 복사 실패"
    exit 1
fi

# Vanilla 예제
if cp idev-viewer-js/dist/idev-viewer.js idev-viewer-js/examples/vanilla-example/idev-viewer.js; then
    print_success "Vanilla 예제에 라이브러리 복사 완료"
else
    print_error "Vanilla 예제 라이브러리 복사 실패"
    exit 1
fi

# 6. 빌드 결과 확인
print_step "6. 빌드 결과 확인..."
echo "📁 빌드된 JavaScript 라이브러리:"
ls -la idev-viewer-js/dist/
echo ""
echo "📁 메인 Flutter 앱 파일들:"
ls -la idev-viewer-js/flutter-app/main.dart.js idev-viewer-js/flutter-app/flutter.js idev-viewer-js/flutter-app/index.html
echo ""
echo "📁 React 예제 Flutter 앱 파일들:"
ls -la idev-viewer-js/examples/react-example/public/flutter-app/main.dart.js idev-viewer-js/examples/react-example/public/flutter-app/flutter.js idev-viewer-js/examples/react-example/public/flutter-app/index.html
echo ""
echo "📁 Vue 예제 Flutter 앱 파일들:"
ls -la idev-viewer-js/examples/vue-example/public/flutter-app/main.dart.js idev-viewer-js/examples/vue-example/public/flutter-app/flutter.js idev-viewer-js/examples/vue-example/public/flutter-app/index.html
echo ""
echo "📁 Vanilla 예제 Flutter 앱 파일들:"
ls -la idev-viewer-js/examples/vanilla-example/flutter-app/main.dart.js idev-viewer-js/examples/vanilla-example/flutter-app/flutter.js idev-viewer-js/examples/vanilla-example/flutter-app/index.html

# 7. NPM 패키지 배포 (옵션)
if [[ $1 == "--publish" ]]; then
    print_step "7. NPM 패키지 배포..."
    cd idev-viewer-js
    
    # 현재 버전 확인
    CURRENT_VERSION=$(node -p "require('./package.json').version")
    echo "현재 버전: $CURRENT_VERSION"
    
    read -p "배포를 진행하시겠습니까? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if npm publish; then
            print_success "NPM 패키지 배포 완료!"
            echo "📦 패키지 URL: https://www.npmjs.com/package/@idev/viewer"
        else
            print_error "NPM 패키지 배포 실패"
            exit 1
        fi
    else
        print_warning "배포가 취소되었습니다"
    fi
    cd .. # 원래 디렉토리로 돌아가기
else
    print_warning "NPM 배포를 건너뜁니다. 배포하려면 --publish 옵션을 사용하세요"
fi

# 8. 완료 메시지
echo ""
print_success "🎉 IDev Viewer 빌드 및 배포 완료!"
echo ""
echo "📋 다음 단계:"
echo "1. 로컬 테스트: python3 -m http.server 8080"
echo "2. 테스트 URL들:"
echo "   - Vanilla 예제: http://localhost:8080/idev-viewer-js/examples/vanilla-example/"
echo "   - React 예제: cd idev-viewer-js/examples/react-example && npm start"
echo "   - Vue 예제: cd idev-viewer-js/examples/vue-example && npm start"
echo "3. NPM 패키지 사용법 확인"
echo "4. 통합 테스트: ./scripts/test-integration.sh"

print_success "✨ 모든 작업이 완료되었습니다!"
