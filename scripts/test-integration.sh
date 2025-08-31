#!/bin/bash

# IDev Viewer 통합 테스트 스크립트

echo "🧪 IDev Viewer 통합 테스트 시작..."

# 색상 정의
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Flutter Web 빌드 테스트
echo -e "${YELLOW}1. Flutter Web 빌드 테스트...${NC}"
if flutter build web --release --dart-define=FLUTTER_WEB_USE_SKIA=false; then
    echo -e "${GREEN}✅ Flutter Web 빌드 성공${NC}"
else
    echo -e "${RED}❌ Flutter Web 빌드 실패${NC}"
    exit 1
fi

# 2. 파일 복사 테스트
echo -e "${YELLOW}2. 파일 복사 테스트...${NC}"
if cp -r build/web/* idev-viewer-js/ && cp -r build/web/* idev-viewer-js/flutter-app/; then
    echo -e "${GREEN}✅ 파일 복사 성공${NC}"
else
    echo -e "${RED}❌ 파일 복사 실패${NC}"
    exit 1
fi

# 3. JavaScript 라이브러리 빌드 테스트
echo -e "${YELLOW}3. JavaScript 라이브러리 빌드 테스트...${NC}"
cd idev-viewer-js
if npm run build; then
    echo -e "${GREEN}✅ JavaScript 라이브러리 빌드 성공${NC}"
else
    echo -e "${RED}❌ JavaScript 라이브러리 빌드 실패${NC}"
    exit 1
fi

# 4. 빌드된 파일 확인
echo -e "${YELLOW}4. 빌드된 파일 확인...${NC}"
echo "📁 dist/ 디렉토리:"
ls -la dist/
echo ""
echo "📁 Flutter 앱 파일들:"
ls -la main.dart.js flutter.js index.html

# 5. HTTP 서버 시작
echo -e "${YELLOW}5. HTTP 서버 시작...${NC}"
echo "🌐 서버가 http://localhost:8080 에서 실행됩니다"
echo "📱 테스트 URL: http://localhost:8080/idev-viewer-js/test.html"
echo ""
echo "🔄 서버를 중지하려면 Ctrl+C를 누르세요"
echo ""

cd ..
python3 -m http.server 8080
