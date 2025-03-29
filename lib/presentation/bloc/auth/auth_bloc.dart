import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/core/utils/logger.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
//import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/domain/usecases/user/create_user_profile.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_event.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';
import 'package:whole_sight/services/auth/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  final CreateUserProfile createUserProfile;

  AuthBloc({
    required this.authService,
    required this.createUserProfile,
  }) : super(AuthInitial()) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignupEvent>(_onSignup);
    on<CompleteProfileEvent>(_onCompleteProfile);
    on<LoginEvent>(_onLogin);
    on<GoogleSignInEvent>(_onGoogleSignIn);
    on<AppleSignInEvent>(_onAppleSignIn);
    on<LogoutEvent>(_onLogout);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<UpdateNutritionProfileEvent>(_onUpdateNutritionProfile);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<ResetPasswordEvent>(_onResetPassword);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthChecking());

      final isAuthenticated = await authService.isAuthenticated();

      if (isAuthenticated) {
        final user = await authService.getCurrentUser();
        if (user != null) {
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthError(message: 'User data is null'));
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to check auth status', e, stackTrace);
      emit(const AuthError(message: 'Failed to check authentication status'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignup(
    SignupEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final user = await authService.signup(
        email: event.email,
        password: event.password,
        name: event.name,
      );

      emit(SignupSuccess(user: user));
      emit(AuthAuthenticated(user: user));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sign up', e, stackTrace);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onCompleteProfile(
    CompleteProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final currentUser = await authService.getCurrentUser();
      final params = CreateUserProfileParams(
        userId: currentUser!.id,
        nutritionProfile: event.nutritionProfile,
      );

      final result = await createUserProfile(params);

      return result.fold(
        (failure) => emit(AuthError(message: failure.message)),
        (user) {
          // First emit ProfileUpdateSuccess
          emit(ProfileUpdateSuccess(user: user));

          // Then immediately emit AuthAuthenticated without delay
          // The UI can handle transition animations if needed
          emit(AuthAuthenticated(user: user));
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to complete profile', e, stackTrace);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogin(
    LoginEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final user = await authService.login(
        email: event.email,
        password: event.password,
      );

      emit(LoginSuccess(user: user));
      emit(AuthAuthenticated(user: user));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to login', e, stackTrace);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onGoogleSignIn(
    GoogleSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final user = await authService.signInWithGoogle();

      emit(LoginSuccess(user: user));
      emit(AuthAuthenticated(user: user));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sign in with Google', e, stackTrace);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onAppleSignIn(
    AppleSignInEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final user = await authService.signInWithApple();

      emit(LoginSuccess(user: user));
      emit(AuthAuthenticated(user: user));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sign in with Apple', e, stackTrace);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      await authService.logout();

      emit(LogoutSuccess());
      emit(AuthUnauthenticated());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to logout', e, stackTrace);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final user = await authService.updateProfile(
        name: event.name,
        photoUrl: event.photoUrl,
      );

      emit(ProfileUpdateSuccess(user: user));
      emit(AuthAuthenticated(user: user));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update profile', e, stackTrace);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onUpdateNutritionProfile(
    UpdateNutritionProfileEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      final user = await authService.updateNutritionProfile(
        nutritionProfile: event.nutritionProfile,
      );

      emit(ProfileUpdateSuccess(user: user));
      emit(AuthAuthenticated(user: user));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update nutrition profile', e, stackTrace);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onForgotPassword(
    ForgotPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      await authService.sendPasswordResetEmail(email: event.email);

      emit(PasswordResetEmailSent());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send password reset email', e, stackTrace);
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(AuthLoading());

      await authService.resetPassword(
        code: event.code,
        newPassword: event.newPassword,
      );

      emit(PasswordResetSuccess());
    } catch (e, stackTrace) {
      AppLogger.error('Failed to reset password', e, stackTrace);
      emit(AuthError(message: e.toString()));
    }
  }
}
