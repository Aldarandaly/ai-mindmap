class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException({required this.message, this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'No internet connection.'});
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Session expired. Please login again.', super.statusCode = 401});
}

class NotFoundException extends ApiException {
  const NotFoundException({super.message = 'Resource not found.', super.statusCode = 404});
}

class ServerException extends ApiException {
  const ServerException({super.message = 'Server error. Please try again.', super.statusCode = 500});
}
