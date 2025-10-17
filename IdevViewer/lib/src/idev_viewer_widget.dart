import 'package:flutter/material.dart';
import 'models/viewer_config.dart';
import 'models/viewer_event.dart';

// 조건부 import: Web과 Native 구현 분리
import 'platform/viewer_native.dart'
    if (dart.library.html) 'platform/viewer_web.dart';

/// IDev 템플릿 뷰어 위젯
/// 
/// Android, iOS, Web, Windows에서 동일한 UI를 렌더링합니다.
/// 
/// 예제:
/// ```dart
/// IDevViewer(
///   config: IDevConfig(
///     apiKey: 'your-api-key',
///     template: templateJson,
///   ),
///   onReady: () => print('준비 완료'),
///   onEvent: (event) => print('이벤트: $event'),
/// )
/// ```
class IDevViewer extends StatelessWidget {
  /// 뷰어 설정
  final IDevConfig config;

  /// 뷰어 준비 완료 콜백
  final VoidCallback? onReady;

  /// 뷰어 이벤트 콜백
  final Function(IDevEvent)? onEvent;

  /// 로딩 위젯
  final Widget? loadingWidget;

  /// 에러 위젯 빌더
  final Widget Function(String error)? errorBuilder;

  const IDevViewer({
    Key? key,
    required this.config,
    this.onReady,
    this.onEvent,
    this.loadingWidget,
    this.errorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 플랫폼에 따라 자동으로 적절한 구현 선택
    return IDevViewerPlatform(
      config: config,
      onReady: onReady,
      onEvent: onEvent,
      loadingWidget: loadingWidget,
      errorBuilder: errorBuilder,
    );
  }
}

