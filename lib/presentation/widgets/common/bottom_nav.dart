import 'package:flutter/material.dart';
import 'package:whole_sight/core/theme/app_colors.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get the bottom padding from MediaQuery
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BottomAppBar(
      // Fixed height that accounts for bottom system insets
      height: 56 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard,
            label: 'Dashboard',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.restaurant_outlined,
            activeIcon: Icons.restaurant,
            label: 'Food Log',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.psychology_outlined,
            activeIcon: Icons.psychology,
            label: 'NutriBot',
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = currentIndex == index;

    // Add extra space for the middle item to accommodate the FAB
    return Expanded(
      child: Padding(
        padding: EdgeInsets.symmetric(
          // Slightly reduced vertical padding
          vertical: 6.0,
          horizontal: 4.0,
        ),
        child: InkWell(
          onTap: () => onTap(index),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : AppColors.textMedium,
                // Keep original size
                size: 24,
              ),
              const SizedBox(height: 2), // Reduced spacing slightly
              Text(
                label,
                style: TextStyle(
                  fontSize: 12, // Keep original font size
                  color: isActive ? AppColors.primary : AppColors.textMedium,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                // Add overflow handling
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
