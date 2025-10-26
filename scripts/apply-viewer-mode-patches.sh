#!/bin/bash
set -e

echo "🔧 Viewer 모드 패치 적용 시작..."

IDEV_VIEWER_PATH="/Users/chaegyugug/Desktop/development/Flutter Project/idev_viewer/IdevViewer"

# 1. home_repo.dart 패치
echo "📝 home_repo.dart 패치..."
FILE="$IDEV_VIEWER_PATH/lib/src/internal/repo/home_repo.dart"

# HomeRepo 생성자 패치 (AppStreams 조건부 초기화)
if ! grep -q "// 뷰어 모드에서는 AppStreams 사용하지 않음" "$FILE"; then
  echo "  → HomeRepo 생성자 패치 적용..."
  sed -i '' 's/HomeRepo() {/HomeRepo() {\n    \/\/ 뷰어 모드에서는 AppStreams 사용하지 않음\n    if (BuildMode.isEditor) {\n      _appStreams = sl<AppStreams>();\n    }/' "$FILE"
fi

# addApiRequest 패치 (기본값 처리)
if ! grep -q "// 뷰어 모드에서 API 메타데이터가 없을 때 기본값 사용" "$FILE"; then
  echo "  → addApiRequest 기본값 처리 패치 적용..."
  
  # api != null 처리 추가
  sed -i '' 's/if (api != null) {/\/\/ 뷰어 모드에서 API 메타데이터가 없을 때 기본값 사용\n    if (api != null) {/' "$FILE"
  
  # else 블록 추가
  sed -i '' 's/reqParams\[.method.\] = api\[.method.\];/&\n    } else {\n      \/\/ 뷰어 모드에서 API 메타데이터가 없을 때 기본값 설정\n      reqParams\[.method.\] = .get.; \/\/ 기본값\n      reqParams\[.uri.\] = apiId; \/\/ API ID를 URI로 사용\n    }/' "$FILE"
fi

# 2. api_service.dart 패치
echo "📝 api_service.dart 패치..."
FILE="$IDEV_VIEWER_PATH/lib/src/internal/core/api/api_service.dart"

# EasyLoading.show() 조건부 처리
if ! grep -q "// 뷰어 모드에서는 EasyLoading 사용하지 않음" "$FILE"; then
  echo "  → EasyLoading.show() 조건부 처리 패치 적용..."
  sed -i '' 's/EasyLoading.show(status: /\/\/ 뷰어 모드에서는 EasyLoading 사용하지 않음\n      if (BuildMode.isEditor) {\n        EasyLoading.show(status: /' "$FILE"
fi

# EasyLoading.dismiss() 조건부 처리
if ! grep -q "// 뷰어 모드에서는 EasyLoading dismiss하지 않음" "$FILE"; then
  echo "  → EasyLoading.dismiss() 조건부 처리 패치 적용..."
  sed -i '' 's/EasyLoading.dismiss();/\/\/ 뷰어 모드에서는 EasyLoading dismiss하지 않음\n        if (BuildMode.isEditor) {\n          EasyLoading.dismiss();\n        }/' "$FILE"
fi

# 3. service_locator.dart 패치
echo "📝 service_locator.dart 패치..."
FILE="$IDEV_VIEWER_PATH/lib/src/internal/pms/di/service_locator.dart"

# initViewerServiceLocator에 HomeRepo 추가
if ! grep -q "sl.registerLazySingleton<HomeRepo>" "$FILE"; then
  echo "  → HomeRepo 등록 패치 적용..."
  
  # import 추가
  if ! grep -q "import '../../repo/home_repo.dart';" "$FILE"; then
    sed -i '' "s|import '../../repo/app_streams.dart';|&\nimport '../../repo/home_repo.dart';|" "$FILE"
  fi
  
  # initViewerServiceLocator에 등록 추가
  sed -i '' 's/void initViewerServiceLocator() {/&\n  \/\/ 뷰어 모드에서 HomeRepo는 LazySingleton으로 등록 (단일 인스턴스)\n  sl.registerLazySingleton<HomeRepo>(() => HomeRepo());/' "$FILE"
fi

echo "✅ Viewer 모드 패치 적용 완료!"

