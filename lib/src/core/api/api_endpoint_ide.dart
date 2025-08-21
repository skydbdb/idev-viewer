class ApiEndpointIDE {
  static const String apis = '/apis';
  static const String params = '/params';
  static const String templates = '/templates';
  static const String templateCommits = '/template-commits';
  static const String templateVersions = '/template-versions';
  static const String versions = '/versions';
  static const String categories = '/categories';
  static const String templateCategories = '/template-categories';

  static const List<String> validEndpoints = [
    apis,
    params,
    templates,
    templateCommits,
    templateVersions,
    versions,
    categories,
    templateCategories,
  ];

  static bool isValidEndpoint(String uri) {
    return validEndpoints.any((endpoint) => uri.contains(endpoint));
  }
}
