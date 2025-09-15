import '../auth/viewer_auth_service.dart';

enum Environment {
  development,
  production,
  local,
}

class AppConfig {
  static late final AppConfig instance;
  static bool _isInitialized = false;

  late final Environment currentEnvironment;
  late final String mode;

  final String apiHostAws;
  final String apiHostLegacyBase;
  final String apiHostLegacySite;
  final String s3ImageBaseUrl; // S3 이미지 기본 URL 추가

  AppConfig._({
    required this.currentEnvironment,
    required this.apiHostAws,
    required this.apiHostLegacyBase,
    required this.apiHostLegacySite,
    required this.s3ImageBaseUrl,
  }) {
    switch (currentEnvironment) {
      case Environment.production:
        mode = 'production';
        break;
      case Environment.local:
      case Environment.development:
        mode = 'develop';
        break;
    }
  }

  static void initialize() {
    const String envString =
        String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
    Environment envEnum;
    switch (envString.toLowerCase()) {
      case 'production':
      case 'prod':
        envEnum = Environment.production;
        break;
      case 'development':
      case 'dev':
      case 'local':
      default:
        envEnum = Environment.development; // local 대신 development를 기본값으로 설정
        break;
    }

    // 환경별 API 호스트 설정
    final apiHosts = _getApiHostsForEnvironment(envEnum);

    instance = AppConfig._(
      currentEnvironment: envEnum,
      apiHostAws: apiHosts['aws']!,
      apiHostLegacyBase: apiHosts['legacyBase']!,
      apiHostLegacySite: apiHosts['legacySite']!,
      s3ImageBaseUrl: _getS3ImageBaseUrlForEnvironment(envEnum),
    );

    _isInitialized = true;
    print('AppConfig: 초기화 완료 - 환경: $envEnum, AWS API: ${apiHosts['aws']}');
  }

  /// 환경별 API 호스트 설정 반환
  static Map<String, String> _getApiHostsForEnvironment(Environment env) {
    switch (env) {
      case Environment.production:
        return {
          'aws':
              'https://production-api.execute-api.ap-northeast-2.amazonaws.com',
          'legacyBase':
              'https://production-api.execute-api.ap-northeast-2.amazonaws.com',
          'legacySite':
              'https://production-api.execute-api.ap-northeast-2.amazonaws.com',
        };
      case Environment.development:
        return {
          'aws': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
          'legacyBase':
              'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
          'legacySite':
              'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
        };
      case Environment.local:
        // local 환경에서도 AWS API 사용 (vanilla-example, react-example과 동일하게)
        return {
          'aws': 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
          'legacyBase':
              'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com',
          'legacySite':
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
        return 'https://s3.ap-northeast-2.amazonaws.com/i-dev-template-images'; // LocalStack S3 포트
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
    // 초기화되지 않은 경우 기본 AWS API 호스트 사용
    if (!_isInitialized) {
      print('AppConfig: 초기화되지 않음, 기본 AWS API 호스트 사용');
      return 'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com';
    }

    // 환경에 관계없이 항상 AWS API 사용 (강제)
    final isViewerAuthenticated = ViewerAuthService.isViewerAuthenticated;
    const selectedHost =
        'https://fuv3je9sl0.execute-api.ap-northeast-2.amazonaws.com';

    print(
        'AppConfig: API 호스트 선택 - 뷰어 인증: $isViewerAuthenticated, 호스트: $selectedHost (강제 AWS API 사용)');

    return selectedHost;
  }

  String getApiKey(String apiPath, {String? ifId}) {
    return ViewerAuthService.viewerApiKey;
  }
}
