/// IDev 템플릿 데이터 모델
/// 
/// 템플릿의 스크립트, ID, 이름, 커밋 정보를 포함합니다.
class Template {
  /// 템플릿의 JSON 스크립트 데이터
  final String script;
  
  /// 템플릿 고유 ID
  final String templateId;
  
  /// 템플릿 표시 이름
  final String templateNm;
  
  /// 커밋 정보 (버전 등)
  final String commitInfo;

  const Template({
    required this.script,
    required this.templateId,
    required this.templateNm,
    required this.commitInfo,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'script': script,
      'templateId': templateId,
      'templateNm': templateNm,
      'commitInfo': commitInfo,
    };
  }

  /// JSON에서 생성
  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      script: json['script'] ?? '',
      templateId: json['templateId'] ?? '',
      templateNm: json['templateNm'] ?? '',
      commitInfo: json['commitInfo'] ?? '',
    );
  }

  /// 복사본 생성 (일부 필드 변경)
  Template copyWith({
    String? script,
    String? templateId,
    String? templateNm,
    String? commitInfo,
  }) {
    return Template(
      script: script ?? this.script,
      templateId: templateId ?? this.templateId,
      templateNm: templateNm ?? this.templateNm,
      commitInfo: commitInfo ?? this.commitInfo,
    );
  }

  @override
  String toString() {
    return 'Template(templateId: $templateId, templateNm: $templateNm, commitInfo: $commitInfo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Template &&
        other.script == script &&
        other.templateId == templateId &&
        other.templateNm == templateNm &&
        other.commitInfo == commitInfo;
  }

  @override
  int get hashCode {
    return script.hashCode ^
        templateId.hashCode ^
        templateNm.hashCode ^
        commitInfo.hashCode;
  }
}
