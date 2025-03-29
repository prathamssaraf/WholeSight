import 'package:equatable/equatable.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SignupEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  
  const SignupEvent({
    required this.email,
    required this.password,
    required this.name,
  });
  
  @override
  List<Object?> get props => [email, password, name];
}

class CompleteProfileEvent extends AuthEvent {
  final NutritionProfileEntity nutritionProfile;
  
  const CompleteProfileEvent({
    required this.nutritionProfile,
  });
  
  @override
  List<Object?> get props => [nutritionProfile];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  
  const LoginEvent({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object?> get props => [email, password];
}

class GoogleSignInEvent extends AuthEvent {}

class AppleSignInEvent extends AuthEvent {}

class LogoutEvent extends AuthEvent {}

class UpdateProfileEvent extends AuthEvent {
  final String? name;
  final String? photoUrl;
  
  const UpdateProfileEvent({
    this.name,
    this.photoUrl,
  });
  
  @override
  List<Object?> get props => [name, photoUrl];
}

class UpdateNutritionProfileEvent extends AuthEvent {
  final NutritionProfileEntity nutritionProfile;
  
  const UpdateNutritionProfileEvent({
    required this.nutritionProfile,
  });
  
  @override
  List<Object?> get props => [nutritionProfile];
}

class ForgotPasswordEvent extends AuthEvent {
  final String email;
  
  const ForgotPasswordEvent({
    required this.email,
  });
  
  @override
  List<Object?> get props => [email];
}

class ResetPasswordEvent extends AuthEvent {
  final String code;
  final String newPassword;
  
  const ResetPasswordEvent({
    required this.code,
    required this.newPassword,
  });
  
  @override
  List<Object?> get props => [code, newPassword];
}