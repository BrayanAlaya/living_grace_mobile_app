class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    this.body,
    this.message,
  });

  final int statusCode;
  final dynamic body;
  final String? message;
}

class ApiNetworkException implements Exception {
  const ApiNetworkException([this.message = 'Error de red']);

  final String message;
}
