#!/bin/bash

echo "🔄 IdevViewer 패키지 에셋 동기화 시작..."

# 현재 디렉토리 확인
CURRENT_DIR=$(pwd)
echo "현재 디렉토리: $CURRENT_DIR"

# idev-viewer-js 경로 확인
IDEV_JS_PATH="$CURRENT_DIR/idev-viewer-js"
if [ ! -d "$IDEV_JS_PATH" ]; then
    echo "❌ idev-viewer-js 디렉토리를 찾을 수 없습니다: $IDEV_JS_PATH"
    exit 1
fi

# idev-app 경로 확인
IDEV_APP_PATH="$IDEV_JS_PATH/idev-app"
if [ ! -d "$IDEV_APP_PATH" ]; then
    echo "❌ idev-app 디렉토리를 찾을 수 없습니다: $IDEV_APP_PATH"
    exit 1
fi

# IdevViewer 패키지 경로
IDEV_VIEWER_PATH="$CURRENT_DIR/IdevViewer"

# Android 에셋 복사
echo "📱 Android 에셋 복사..."
ANDROID_ASSETS_PATH="$IDEV_VIEWER_PATH/android/src/main/assets"
mkdir -p "$ANDROID_ASSETS_PATH"
if [ -d "$ANDROID_ASSETS_PATH/idev-app" ]; then
    rm -rf "$ANDROID_ASSETS_PATH/idev-app"
fi
cp -r "$IDEV_APP_PATH" "$ANDROID_ASSETS_PATH/"
cp "$IDEV_JS_PATH/dist/idev-viewer.js" "$ANDROID_ASSETS_PATH/"
echo "✅ Android 에셋 복사 완료"

# iOS 에셋 복사
echo "🍎 iOS 에셋 복사..."
IOS_ASSETS_PATH="$IDEV_VIEWER_PATH/ios/Assets"
mkdir -p "$IOS_ASSETS_PATH"
if [ -d "$IOS_ASSETS_PATH/idev-app" ]; then
    rm -rf "$IOS_ASSETS_PATH/idev-app"
fi
cp -r "$IDEV_APP_PATH" "$IOS_ASSETS_PATH/"
cp "$IDEV_JS_PATH/dist/idev-viewer.js" "$IOS_ASSETS_PATH/"
echo "✅ iOS 에셋 복사 완료"

# Web 에셋 복사
echo "🌐 Web 에셋 복사..."
WEB_ASSETS_PATH="$IDEV_VIEWER_PATH/web/assets"
mkdir -p "$WEB_ASSETS_PATH"
if [ -d "$WEB_ASSETS_PATH/idev-app" ]; then
    rm -rf "$WEB_ASSETS_PATH/idev-app"
fi
cp -r "$IDEV_APP_PATH" "$WEB_ASSETS_PATH/"
cp "$IDEV_JS_PATH/dist/idev-viewer.js" "$WEB_ASSETS_PATH/"
echo "✅ Web 에셋 복사 완료"

# Windows 에셋 복사
echo "🪟 Windows 에셋 복사..."
WINDOWS_ASSETS_PATH="$IDEV_VIEWER_PATH/windows/assets"
mkdir -p "$WINDOWS_ASSETS_PATH"
if [ -d "$WINDOWS_ASSETS_PATH/idev-app" ]; then
    rm -rf "$WINDOWS_ASSETS_PATH/idev-app"
fi
cp -r "$IDEV_APP_PATH" "$WINDOWS_ASSETS_PATH/"
cp "$IDEV_JS_PATH/dist/idev-viewer.js" "$WINDOWS_ASSETS_PATH/"
echo "✅ Windows 에셋 복사 완료"

echo "🎉 IdevViewer 패키지 에셋 동기화 완료!"
echo ""
echo "📋 동기화된 플랫폼들:"
echo "  - Android: $ANDROID_ASSETS_PATH/"
echo "  - iOS: $IOS_ASSETS_PATH/"
echo "  - Web: $WEB_ASSETS_PATH/"
echo "  - Windows: $WINDOWS_ASSETS_PATH/"
