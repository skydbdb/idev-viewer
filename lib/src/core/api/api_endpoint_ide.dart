class ApiEndpointIDE {
  static const String apis = '/idev/v1/apis';
  static const String params = '/idev/v1/params';
  static const String templates = '/idev/v1/templates';
  static const String templateCommits = '/idev/v1/template-commits';
  static const String templateVersions = '/idev/v1/template-versions';
  static const String versions = '/idev/v1/versions';
  static const String categories = '/idev/v1/categories';
  static const String templateCategories = '/idev/v1/template-categories';

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
