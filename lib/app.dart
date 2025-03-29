import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/core/theme/app_theme.dart';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_event.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_bloc.dart';
import 'package:whole_sight/presentation/pages/auth/onboarding_page.dart';
import 'package:whole_sight/presentation/pages/dashboard/dashboard_page.dart';

class WholeSightApp extends StatelessWidget {
  const WholeSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => getIt<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<FoodLoggingBloc>(
          create: (context) => getIt<FoodLoggingBloc>(),
        ),
        // Add other global BLoCs here
      ],
      child: MaterialApp(
        title: 'WholeSight',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthChecking) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (state is AuthAuthenticated) {
              return const DashboardPage();
            } else {
              return const OnboardingPage();
            }
          },
        ),
        // Define your routes here
        routes: {
          // '/': (context) => const SplashScreen(),
          // '/onboarding': (context) => const OnboardingPage(),
          // '/login': (context) => const LoginPage(),
          // '/signup': (context) => const SignupPage(),
          // '/dashboard': (context) => const DashboardPage(),
          // Add more routes as needed
        },
      ),
    );
  }
}
