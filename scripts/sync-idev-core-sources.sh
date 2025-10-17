#!/bin/bash
set -e

echo "🔄 idev IDE viewer 소스 동기화 시작..."

IDEV_IDE_PATH="/Users/chaegyugug/Desktop/development/Flutter Project/idev"
IDEV_VIEWER_PATH="/Users/chaegyugug/Desktop/development/Flutter Project/idev_viewer/IdevViewer"

# 1. Viewer 핵심 소스 복사
echo "📋 Viewer 소스 복사..."
rm -rf "${IDEV_VIEWER_PATH}/lib/src/internal/board/viewer"
mkdir -p "${IDEV_VIEWER_PATH}/lib/src/internal/board"
cp -r "${IDEV_IDE_PATH}/lib/src/board/board/viewer" \
      "${IDEV_VIEWER_PATH}/lib/src/internal/board/"

# 2. Board 관련 전체 소스 복사 (DockBoard 등 의존성)
echo "📦 Board 의존성 소스 복사..."
cp -r "${IDEV_IDE_PATH}/lib/src/board" \
      "${IDEV_VIEWER_PATH}/lib/src/internal/"

# 3. Config 파일들 복사
echo "⚙️  Config 파일 복사..."
mkdir -p "${IDEV_VIEWER_PATH}/lib/src/internal/config"
cp "${IDEV_IDE_PATH}/lib/config/external_bridge.dart" \
   "${IDEV_VIEWER_PATH}/lib/src/internal/config/" 2>/dev/null || true
cp "${IDEV_IDE_PATH}/lib/config/external_message_handler.dart" \
   "${IDEV_VIEWER_PATH}/lib/src/internal/config/" 2>/dev/null || true
cp "${IDEV_IDE_PATH}/lib/config/build_mode.dart" \
   "${IDEV_VIEWER_PATH}/lib/src/internal/config/" 2>/dev/null || true

# 4. Repo 파일 복사
echo "🗂️  Repo 파일 복사..."
mkdir -p "${IDEV_VIEWER_PATH}/lib/src/internal/repo"
cp -r "${IDEV_IDE_PATH}/lib/src/repo"/* \
      "${IDEV_VIEWER_PATH}/lib/src/internal/repo/" 2>/dev/null || true

# 5. Core 파일들 복사
echo "🎯 Core 파일 복사..."
cp -r "${IDEV_IDE_PATH}/lib/src/core" \
      "${IDEV_VIEWER_PATH}/lib/src/internal/" 2>/dev/null || true

# 6. 기타 필요한 소스들 복사
echo "📄 기타 소스 복사..."
cp -r "${IDEV_IDE_PATH}/lib/src/layout" \
      "${IDEV_VIEWER_PATH}/lib/src/internal/" 2>/dev/null || true
cp -r "${IDEV_IDE_PATH}/lib/src/pms" \
      "${IDEV_VIEWER_PATH}/lib/src/internal/" 2>/dev/null || true
cp -r "${IDEV_IDE_PATH}/lib/src/widgets" \
      "${IDEV_VIEWER_PATH}/lib/src/internal/" 2>/dev/null || true
cp -r "${IDEV_IDE_PATH}/lib/src/utils" \
      "${IDEV_VIEWER_PATH}/lib/src/internal/" 2>/dev/null || true
cp -r "${IDEV_IDE_PATH}/lib/src/const" \
      "${IDEV_VIEWER_PATH}/lib/src/internal/" 2>/dev/null || true
cp -r "${IDEV_IDE_PATH}/lib/src/auth" \
      "${IDEV_VIEWER_PATH}/lib/src/internal/" 2>/dev/null || true

# 7. import 경로 수정
echo "🔧 import 경로 수정..."

# idev_v1 패키지 경로를 idev_viewer 패키지 경로로 변경
find "${IDEV_VIEWER_PATH}/lib/src/internal" -name "*.dart" -type f -exec \
  sed -i '' 's|package:idev_v1/src/|package:idev_viewer/src/internal/|g' {} \;

find "${IDEV_VIEWER_PATH}/lib/src/internal" -name "*.dart" -type f -exec \
  sed -i '' 's|package:idev_v1/config/|package:idev_viewer/src/internal/config/|g' {} \;

# /config/ 같은 절대 경로를 패키지 경로로 변경
find "${IDEV_VIEWER_PATH}/lib/src/internal" -name "*.dart" -type f -exec \
  sed -i '' "s|import '/config/|import 'package:idev_viewer/src/internal/config/|g" {} \;

find "${IDEV_VIEWER_PATH}/lib/src/internal" -name "*.dart" -type f -exec \
  sed -i '' "s|import '/src/|import 'package:idev_viewer/src/internal/|g" {} \;

# 상대 경로에서 절대 패키지 경로로 변경 (복잡한 ../../../ 같은 경로)
find "${IDEV_VIEWER_PATH}/lib/src/internal" -name "*.dart" -type f -exec \
  sed -i '' "s|'../../../src/core|'package:idev_viewer/src/internal/core|g" {} \;

find "${IDEV_VIEWER_PATH}/lib/src/internal" -name "*.dart" -type f -exec \
  sed -i '' "s|'../../src/|'package:idev_viewer/src/internal/|g" {} \;

find "${IDEV_VIEWER_PATH}/lib/src/internal" -name "*.dart" -type f -exec \
  sed -i '' "s|'../src/|'package:idev_viewer/src/internal/|g" {} \;

echo "✅ 소스 동기화 완료!"
echo ""
echo "⚠️  다음 단계:"
echo "  1. cd IdevViewer"
echo "  2. flutter pub get"
echo "  3. flutter analyze (에러 확인)"
echo "  4. 누락된 의존성 파일이 있다면 이 스크립트에 추가"

