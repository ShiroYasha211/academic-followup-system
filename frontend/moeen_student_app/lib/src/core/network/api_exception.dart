class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.errors,
    this.isOffline = false,
  });

  final String message;
  final int? statusCode;
  final Object? errors;
  final bool isOffline;

  @override
  String toString() => message;
}
