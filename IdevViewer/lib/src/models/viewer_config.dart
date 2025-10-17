/// IDev Viewer 설정 클래스
class IDevConfig {
  /// API 키 (옵션)
  final String? apiKey;

  /// 템플릿 JSON 데이터
  final Map<String, dynamic>? template;

  /// 템플릿 이름
  final String? templateName;

  /// 테마 (dark, light 등)
  final String? theme;

  /// 로케일 (ko, en 등)
  final String? locale;

  /// 디버그 모드
  final bool debugMode;

  /// 플랫폼 (web, android, ios 등)
  final String? platform;

  /// 뷰어 기본 URL (선택사항, 기본값은 패키지 내 viewer 사용)
  final String? viewerUrl;

  const IDevConfig({
    this.apiKey,
    this.template,
    this.templateName,
    this.theme,
    this.locale,
    this.debugMode = false,
    this.platform,
    this.viewerUrl,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      if (apiKey != null) 'apiKey': apiKey,
      if (template != null) 'template': template,
      if (templateName != null) 'templateName': templateName,
      if (theme != null) 'theme': theme,
      if (locale != null) 'locale': locale,
      'debugMode': debugMode,
      if (platform != null) 'platform': platform,
      if (viewerUrl != null) 'viewerUrl': viewerUrl,
    };
  }

  /// JSON에서 생성
  factory IDevConfig.fromJson(Map<String, dynamic> json) {
    return IDevConfig(
      apiKey: json['apiKey'] as String?,
      template: json['template'] as Map<String, dynamic>?,
      templateName: json['templateName'] as String?,
      theme: json['theme'] as String?,
      locale: json['locale'] as String?,
      debugMode: json['debugMode'] as bool? ?? false,
      platform: json['platform'] as String?,
      viewerUrl: json['viewerUrl'] as String?,
    );
  }
}
