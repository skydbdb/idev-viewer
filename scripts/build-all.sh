#!/bin/bash
set -e

echo "🚀 IDev Viewer 전체 빌드 시작..."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "${BLUE}📋 $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IDEV_IDE_PATH="/Users/chaegyugug/Desktop/development/Flutter Project/idev"

cd "$PROJECT_ROOT"

print_step "Step 1: idev IDE에서 Web 뷰어 빌드"
cd "$IDEV_IDE_PATH"
flutter build web \
  --dart-define=ENVIRONMENT=prod \
  --dart-define=BUILD_MODE=viewer \
  --release \
  --no-source-maps \
  --tree-shake-icons \
  --output=build/web-viewer
print_success "Flutter Web 뷰어 빌드 완료"

print_step "Step 2: JS 래퍼 패키지 업데이트"
cd "$PROJECT_ROOT"
rm -rf idev-viewer-js/idev-app
mkdir -p idev-viewer-js/idev-app
cp -r "$IDEV_IDE_PATH/build/web-viewer"/* idev-viewer-js/idev-app/
print_success "idev-app 복사 완료"

print_step "Step 3: JavaScript 래퍼 빌드"
cd idev-viewer-js
if [ -f "package.json" ]; then
    npm run build
    print_success "JS 라이브러리 빌드 완료"
else
    print_error "package.json을 찾을 수 없습니다"
    exit 1
fi

print_step "Step 4: Flutter 패키지에 viewer-app 복사"
cd "$PROJECT_ROOT"
rm -rf IdevViewer/assets/viewer-app
mkdir -p IdevViewer/assets/viewer-app
cp -r idev-viewer-js/idev-app/* IdevViewer/assets/viewer-app/
print_success "Flutter 패키지 에셋 복사 완료"

print_step "Step 5: pubspec.yaml에 assets 추가 확인"
if ! grep -q "assets:" IdevViewer/pubspec.yaml; then
    print_error "pubspec.yaml에 assets 섹션이 없습니다"
fi

print_step "Step 6: Flutter 패키지 분석"
cd IdevViewer
flutter pub get
flutter analyze --no-fatal-infos
print_success "패키지 분석 완료"

print_step "Step 7: 패키지 퍼블리시 가능 여부 체크"
flutter pub publish --dry-run
print_success "패키지 퍼블리시 체크 완료"

echo ""
print_success "🎉 빌드 완료!"
echo ""
echo "📦 산출물:"
echo "  - npm 패키지: $PROJECT_ROOT/idev-viewer-js/"
echo "  - Flutter 패키지: $PROJECT_ROOT/IdevViewer/"
echo ""
echo "📋 다음 단계:"
echo "  1. npm publish (JS 프레임워크용)"
echo "     cd $PROJECT_ROOT/idev-viewer-js && npm publish"
echo ""
echo "  2. flutter pub publish (Flutter 앱용)"
echo "     cd $PROJECT_ROOT/IdevViewer && flutter pub publish"

