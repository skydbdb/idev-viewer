/// IDev Viewer 설정 클래스
class IDevConfig {
  /// API 키 (옵션)
  final String? apiKey;

  /// 템플릿 JSON 데이터
  final Map<String, dynamic>? template;

  /// 템플릿 이름
  final String? templateName;

  /// 뷰어 기본 URL (선택사항, 기본값은 패키지 내 viewer 사용)
  final String? viewerUrl;

  const IDevConfig({
    this.apiKey,
    this.template,
    this.templateName,
    this.viewerUrl,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      if (apiKey != null) 'apiKey': apiKey,
      if (template != null) 'template': template,
      if (templateName != null) 'templateName': templateName,
      if (viewerUrl != null) 'viewerUrl': viewerUrl,
    };
  }

  /// JSON에서 생성
  factory IDevConfig.fromJson(Map<String, dynamic> json) {
    return IDevConfig(
      apiKey: json['apiKey'] as String?,
      template: json['template'] as Map<String, dynamic>?,
      templateName: json['templateName'] as String?,
      viewerUrl: json['viewerUrl'] as String?,
    );
  }
}

