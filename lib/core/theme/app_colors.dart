import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF4CAF50); // Green
  static const Color primaryLight = Color(0xFF80E27E);
  static const Color primaryDark = Color(0xFF087F23);

  // Secondary colors
  static const Color secondary = Color(0xFF03A9F4); // Blue
  static const Color secondaryLight = Color(0xFF67DAFF);
  static const Color secondaryDark = Color(0xFF007AC1);

  // Tertiary colors
  static const Color tertiary = Color(0xFFFF9800); // Orange
  static const Color tertiaryLight = Color(0xFFFFC947);
  static const Color tertiaryDark = Color(0xFFC66900);

  // Text colors
  static const Color textDark = Color(0xFFF5F5F5);
  static const Color textMedium = Color(0xFFF5F5F5);
  static const Color textLight = Color(0xFFF5F5F5);

  // Background colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);

  // Surface colors
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Error colors
  static const Color error = Color(0xFFB00020);
  static const Color errorDark = Color(0xFFCF6679);

  // Divider colors
  static const Color dividerLight = Color(0xFFBDBDBD);
  static const Color dividerDark = Color(0xFF424242);

  // Success, warning, info colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Chart and graph colors
  static const List<Color> chartColors = [
    Color(0xFF4CAF50), // Primary green
    Color(0xFF03A9F4), // Secondary blue
    Color(0xFFFF9800), // Tertiary orange
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF3F51B5), // Indigo
    Color(0xFF00BCD4), // Cyan
    Color(0xFF009688), // Teal
    Color(0xFF8BC34A), // Light Green
  ];

  // Nutrition-specific colors
  static const Color protein = Color(0xFF8D6E63); // Brown
  static const Color carbs = Color(0xFFFFB74D); // Orange
  static const Color fats = Color(0xFFFFD54F); // Yellow
  static const Color fiber = Color(0xFF81C784); // Green
  static const Color vitamins = Color(0xFF4FC3F7); // Blue
  static const Color minerals = Color(0xFFBA68C8); // Purple

  // Gradient colors - these cannot be const because Lists with non-const items cannot be const
  static final List<Color> primaryGradient = [
    primary,
    primaryLight,
  ];

  static final List<Color> secondaryGradient = [
    secondary,
    secondaryLight,
  ];

  static final List<Color> tertiaryGradient = [
    tertiary,
    tertiaryLight,
  ];
}
