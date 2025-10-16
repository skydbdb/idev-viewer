/// IDev 뷰어 설정 모델
///
/// 테마, 언어, API 키, 디버그 모드, 플랫폼 정보를 포함합니다.
class Config {
  /// 테마 ('dark' 또는 'light')
  final String theme;

  /// 언어 설정 ('ko', 'en', 'ja' 등)
  final String locale;

  /// API 키 (선택사항)
  final String? apiKey;

  /// 디버그 모드 활성화 여부
  final bool debug;

  /// 플랫폼 설정 ('auto', 'android', 'ios', 'web', 'windows')
  final String platform;

  const Config({
    this.theme = 'dark',
    this.locale = 'ko',
    this.apiKey,
    this.debug = false,
    this.platform = 'auto',
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'locale': locale,
      'apiKey': apiKey,
      'debug': debug,
      'platform': platform,
    };
  }

  /// JSON에서 생성
  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      theme: json['theme'] ?? 'dark',
      locale: json['locale'] ?? 'ko',
      apiKey: json['apiKey'],
      debug: json['debug'] ?? false,
      platform: json['platform'] ?? 'auto',
    );
  }

  /// 복사본 생성 (일부 필드 변경)
  Config copyWith({
    String? theme,
    String? locale,
    String? apiKey,
    bool? debug,
    String? platform,
  }) {
    return Config(
      theme: theme ?? this.theme,
      locale: locale ?? this.locale,
      apiKey: apiKey ?? this.apiKey,
      debug: debug ?? this.debug,
      platform: platform ?? this.platform,
    );
  }

  @override
  String toString() {
    return 'Config(theme: $theme, locale: $locale, debug: $debug, platform: $platform)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Config &&
        other.theme == theme &&
        other.locale == locale &&
        other.apiKey == apiKey &&
        other.debug == debug &&
        other.platform == platform;
  }

  @override
  int get hashCode {
    return theme.hashCode ^
        locale.hashCode ^
        apiKey.hashCode ^
        debug.hashCode ^
        platform.hashCode;
  }
}
