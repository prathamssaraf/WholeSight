import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Add this import
import 'package:whole_sight/core/theme/app_colors.dart';

class SocialAuthButton extends StatelessWidget {
  final String icon;
  final VoidCallback onPressed;
  final double size;

  const SocialAuthButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: AppColors.dividerLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          // Use Center instead of Padding for better alignment
          child: icon.endsWith('.svg')
              ? SvgPicture.asset(
                  // Use SvgPicture for SVG files
                  icon,
                  width: size * 0.5,
                  height: size * 0.5,
                  // Add a color filter to ensure visibility
                  colorFilter:
                      const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                )
              : Image.asset(
                  // Keep Image.asset for regular image files
                  icon,
                  width: size * 0.75,
                  height: size * 0.75,
                ),
        ),
      ),
    );
  }
}
