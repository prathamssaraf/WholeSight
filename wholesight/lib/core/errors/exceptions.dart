/// Exception thrown when there is a failure with a server request.
class ServerException implements Exception {
  final String? message;
  
  ServerException([this.message]);
  
  @override
  String toString() {
    return message ?? 'Server Exception';
  }
}

/// Exception thrown when there is a failure with the cache.
class CacheException implements Exception {
  final String? message;
  
  CacheException([this.message]);
  
  @override
  String toString() {
    return message ?? 'Cache Exception';
  }
}

/// Exception thrown when there is a failure with network connectivity.
class NetworkException implements Exception {
  final String? message;
  
  NetworkException([this.message]);
  
  @override
  String toString() {
    return message ?? 'Network Exception';
  }
}

/// Exception thrown when there is an authentication failure.
class AuthException implements Exception {
  final String? message;
  
  AuthException([this.message]);
  
  @override
  String toString() {
    return message ?? 'Authentication Exception';
  }
}

/// Exception thrown when an operation is not permitted.
class PermissionException implements Exception {
  final String? message;
  
  PermissionException([this.message]);
  
  @override
  String toString() {
    return message ?? 'Permission Exception';
  }
}

/// Exception thrown when an operation fails due to invalid input.
class ValidationException implements Exception {
  final String? message;
  
  ValidationException([this.message]);
  
  @override
  String toString() {
    return message ?? 'Validation Exception';
  }
}