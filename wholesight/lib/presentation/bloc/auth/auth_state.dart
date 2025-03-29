import 'package:equatable/equatable.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthChecking extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  
  const AuthAuthenticated({required this.user});
  
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class AuthError extends AuthState {
  final String message;
  
  const AuthError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class SignupSuccess extends AuthState {
  final UserEntity user;
  
  const SignupSuccess({required this.user});
  
  @override
  List<Object?> get props => [user];
}

class LoginSuccess extends AuthState {
  final UserEntity user;
  
  const LoginSuccess({required this.user});
  
  @override
  List<Object?> get props => [user];
}

class LogoutSuccess extends AuthState {}

class ProfileUpdateSuccess extends AuthState {
  final UserEntity user;
  
  const ProfileUpdateSuccess({required this.user});
  
  @override
  List<Object?> get props => [user];
}

class PasswordResetEmailSent extends AuthState {}

class PasswordResetSuccess extends AuthState {}