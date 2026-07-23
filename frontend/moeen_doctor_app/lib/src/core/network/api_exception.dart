class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.errors, this.code});

  final String message;
  final int? statusCode;
  final Object? errors;
  final String? code;

  @override
  String toString() => message;
}
