import 'package:equatable/equatable.dart';

// Abstract base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Specific failure types
class ServerFailure extends Failure {
  const ServerFailure({String message = 'Server error occurred'}) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure({String message = 'Cache error occurred'}) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure({String message = 'Network connection failed'}) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure({String message = 'Authentication failed'}) : super(message);
}

class ValidationFailure extends Failure {
  const ValidationFailure({String message = 'Validation failed'}) : super(message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({String message = 'Resource not found'}) : super(message);
}