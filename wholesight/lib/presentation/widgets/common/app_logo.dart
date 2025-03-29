import 'package:flutter/material.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              'assets/icons/logo.png',
              width: size * 0.6,
              height: size * 0.6,
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // App name
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Whole',
                style: AppTextStyles.headline5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextSpan(
                text: 'Sight',
                style: AppTextStyles.headline5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // Tagline
        Text(
          'AI-Enhanced Nutrition & Health',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMedium,
          ),
        ),
      ],
    );
  }
}
