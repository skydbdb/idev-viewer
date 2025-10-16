#!/bin/bash

echo "🚀 IdevViewer 패키지 통합 빌드 시작..."

# 현재 디렉토리 확인
CURRENT_DIR=$(pwd)
echo "현재 디렉토리: $CURRENT_DIR"

# 1. JavaScript 라이브러리 빌드
echo "📦 JavaScript 라이브러리 빌드..."
cd idev-viewer-js
if [ -f "package.json" ]; then
    npm run build
    echo "✅ JavaScript 라이브러리 빌드 완료"
else
    echo "❌ package.json을 찾을 수 없습니다"
    exit 1
fi

# 2. Flutter 웹 앱 빌드
echo "📱 Flutter 웹 앱 빌드..."
cd ..
flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false

# 3. 빌드 결과를 idev-app에 복사
echo "📋 Flutter 웹 앱 에셋 복사..."
cp -r build/web/* idev-viewer-js/idev-app/

# 4. IdevViewer 패키지 에셋 동기화
echo "🔄 IdevViewer 패키지 에셋 동기화..."
./scripts/sync-idev-viewer-assets.sh

# 5. IdevViewer 패키지 테스트
echo "🧪 IdevViewer 패키지 테스트..."
cd IdevViewer
flutter test

echo "🎉 IdevViewer 패키지 통합 빌드 완료!"
echo ""
echo "📋 지원 플랫폼:"
echo "  ✅ Android"
echo "  ✅ iOS" 
echo "  ✅ Web"
echo "  ✅ Windows"
