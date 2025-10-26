class BuildMode {
  // Build-time mode: 'viewer' or 'editor'
  static const String mode =
      String.fromEnvironment('BUILD_MODE', defaultValue: 'editor');

  // Optional flags already used elsewhere
  static const String environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  static bool get isViewer => mode == 'viewer';
  static bool get isEditor => !isViewer;
  static bool get isProd => environment == 'prod';
}
