class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiError({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiError: $message (Status: $statusCode)';
}
