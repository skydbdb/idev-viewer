import 'template.dart';
import 'config.dart';

/// IDev 뷰어 옵션 모델
///
/// 뷰어의 크기, 템플릿, 설정, 콜백 함수들을 포함합니다.
class ViewerOptions {
  /// 뷰어 너비
  final double width;

  /// 뷰어 높이
  final double height;

  /// 템플릿 데이터
  final Template? template;

  /// 설정 정보
  final Config config;

  /// 뷰어 준비 완료 콜백
  final Function(Map<String, dynamic>)? onReady;

  /// 에러 발생 콜백
  final Function(String)? onError;

  /// 템플릿 업데이트 콜백
  final Function(Map<String, dynamic>)? onTemplateUpdate;

  /// 아이템 탭 콜백
  final Function(Map<String, dynamic>)? onItemTap;

  const ViewerOptions({
    this.width = 300.0,
    this.height = 200.0,
    this.template,
    this.config = const Config(),
    this.onReady,
    this.onError,
    this.onTemplateUpdate,
    this.onItemTap,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
      'template': template?.toJson(),
      'config': config.toJson(),
    };
  }

  /// 복사본 생성 (일부 필드 변경)
  ViewerOptions copyWith({
    double? width,
    double? height,
    Template? template,
    Config? config,
    Function(Map<String, dynamic>)? onReady,
    Function(String)? onError,
    Function(Map<String, dynamic>)? onTemplateUpdate,
    Function(Map<String, dynamic>)? onItemTap,
  }) {
    return ViewerOptions(
      width: width ?? this.width,
      height: height ?? this.height,
      template: template ?? this.template,
      config: config ?? this.config,
      onReady: onReady ?? this.onReady,
      onError: onError ?? this.onError,
      onTemplateUpdate: onTemplateUpdate ?? this.onTemplateUpdate,
      onItemTap: onItemTap ?? this.onItemTap,
    );
  }

  @override
  String toString() {
    return 'ViewerOptions(width: $width, height: $height, template: $template, config: $config)';
  }
}
