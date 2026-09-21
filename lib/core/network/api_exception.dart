enum ApiFailureType {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  timeout,
  rateLimited,
  server,
  unavailable,
  offline,
  unknown,
}

class ApiException implements Exception {
  const ApiException(this.type, this.message, {this.statusCode});

  final ApiFailureType type;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($type, $statusCode)';
}

