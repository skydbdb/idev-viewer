#!/bin/bash

echo "📦 IdevViewer 패키지 배포 시작..."

# 현재 디렉토리 확인
CURRENT_DIR=$(pwd)

# 1. 통합 빌드 실행
echo "🔨 통합 빌드 실행..."
./scripts/build-idev-viewer-package.sh

# 2. 버전 확인
cd IdevViewer
CURRENT_VERSION=$(grep "version:" pubspec.yaml | cut -d' ' -f2)
echo "현재 버전: $CURRENT_VERSION"

# 3. 배포 전 검증
echo "🔍 배포 전 검증..."
flutter pub publish --dry-run

# 4. 사용자 확인
read -p "IdevViewer 패키지를 배포하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 IdevViewer 패키지 배포 중..."
    flutter pub publish
    echo "✅ 배포 완료!"
    echo ""
    echo "🎉 지원 플랫폼:"
    echo "  📱 Android"
    echo "  🍎 iOS"
    echo "  🌐 Web"
    echo "  🪟 Windows"
else
    echo "❌ 배포 취소됨"
fi
