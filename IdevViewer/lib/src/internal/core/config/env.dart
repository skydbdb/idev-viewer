enum Environment {
  development,
  production,
  local,
}

class AppConfig {
  static late final AppConfig instance;

  late final Environment currentEnvironment;
  late final String mode;

  final String apiHostAws;
  final String apiHostLegacyBase;
  final String apiHostLegacyHaksa;
  final String s3ImageBaseUrl; // S3 이미지 기본 URL 추가

  AppConfig._({
    required this.currentEnvironment,
    required this.apiHostAws,
    required this.apiHostLegacyBase,
    required this.apiHostLegacyHaksa,
    required this.s3ImageBaseUrl,
  }) {
    switch (currentEnvironment) {
      case Environment.production:
        mode = 'production';
        break;
      case Environment.development:
        mode = 'develop';
        break;
      case Environment.local:
        mode = 'local';
        break;
    }
  }

  static void initialize() {
    const String envString =
        String.fromEnvironment('ENVIRONMENT', defaultValue: 'local');
    Environment envEnum;
    switch (envString.toLowerCase()) {
      case 'production':
      case 'prod':
        envEnum = Environment.production;
        break;
      case 'development':
      case 'dev':
        envEnum = Environment.development;
        break;
      case 'local':
      default:
        envEnum = Environment.local;
        break;
    }

    // 환경별 API 호스트 설정
    final apiHosts = _getApiHostsForEnvironment(envEnum);

    instance = AppConfig._(
      currentEnvironment: envEnum,
      apiHostAws: apiHosts['aws']!,
      apiHostLegacyBase: apiHosts['legacyBase']!,
      apiHostLegacyHaksa: apiHosts['legacyHaksa']!,
      s3ImageBaseUrl: _getS3ImageBaseUrlForEnvironment(envEnum),
    );
  }

  /// 환경별 API 호스트 설정 반환
  static Map<String, String> _getApiHostsForEnvironment(Environment env) {
    switch (env) {
      case Environment.production:
        return {
          'aws': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
          'legacyBase':
              'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
          'legacyHaksa':
              'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
        };
      case Environment.development:
        return {
          'aws': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
          'legacyBase':
              'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
          'legacyHaksa':
              'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
        };
      case Environment.local:
        return {
          'aws': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
          'legacyBase':
              'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
          'legacyHaksa':
              'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
        };
    }
  }

  /// 환경별 S3 이미지 기본 URL 반환
  static String _getS3ImageBaseUrlForEnvironment(Environment env) {
    switch (env) {
      case Environment.production:
        return 'https://s3.ap-northeast-2.amazonaws.com/i-dev-template-images';
      case Environment.development:
        return 'https://s3.ap-northeast-2.amazonaws.com/i-dev-template-images';
      case Environment.local:
        return 'http://localhost:4566'; // LocalStack S3 포트
    }
  }

  bool get isLocal => currentEnvironment == Environment.local;
  bool get isDevelop => currentEnvironment == Environment.development;
  bool get isProduction => currentEnvironment == Environment.production;

  String encrypt(String value) {
    return value;
  }

  String decrypt(String value) {
    return value;
  }

  String getApiHost(String apiPath, {String? ifId}) {
    // 모든 API를 AWS API로 통일
    return apiHostAws;
  }
}
