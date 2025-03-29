import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_event.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';
import 'package:whole_sight/presentation/pages/profile/edit_profile_page.dart';
import 'package:whole_sight/presentation/pages/profile/goals_page.dart';
import 'package:whole_sight/presentation/pages/profile/preferences_page.dart';
import 'package:whole_sight/presentation/pages/profile/notifications_page.dart';
import 'package:whole_sight/presentation/pages/profile/privacy_page.dart';
import 'package:whole_sight/presentation/pages/profile/help_support_page.dart';
import 'package:whole_sight/presentation/pages/profile/about_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final user = state.user;
          final nutritionProfile = user.nutritionProfile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile card
                _buildProfileCard(
                    context, user.name, user.email, user.photoUrl),

                const SizedBox(height: 24),

                // Nutrition profile summary
                if (nutritionProfile != null)
                  _buildNutritionProfileSummary(nutritionProfile),

                const SizedBox(height: 24),

                // Action buttons
                _buildActionButtons(context),

                const SizedBox(height: 24),

                // Settings sections
                _buildSettingsSections(context),

                const SizedBox(height: 24),

                // App info
                Center(
                  child: Column(
                    children: [
                      Text(
                        'WholeSight v1.0.0',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '© 2025 WholeSight',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
        // Loading or error state
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    String name,
    String email,
    String? photoUrl,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Profile image
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.network(
                        photoUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: AppTextStyles.headline4.copyWith(
                              color: AppColors.primary,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: AppTextStyles.headline4.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.headline6.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    email,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      // Get user from the current AuthBloc state
                      final state = context.read<AuthBloc>().state;
                      if (state is AuthAuthenticated) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfilePage(user: state.user),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionProfileSummary(NutritionProfileEntity profile) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Profile',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionInfoItem(
                    icon: Icons.fitness_center_outlined,
                    label: 'Goal',
                    value: _formatEnum(profile.goal.toString()),
                  ),
                ),
                Expanded(
                  child: _buildNutritionInfoItem(
                    icon: Icons.restaurant_outlined,
                    label: 'Diet Type',
                    value: _formatEnum(profile.dietType.toString()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionInfoItem(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Daily Calories',
                    value: '${profile.calorieTarget.round()} kcal',
                  ),
                ),
                Expanded(
                  child: _buildNutritionInfoItem(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Current Weight',
                    value: '${profile.weightKg} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildNutritionInfoItem(
                    icon: Icons.height_outlined,
                    label: 'Height',
                    value: '${profile.heightCm} cm',
                  ),
                ),
                Expanded(
                  child: _buildNutritionInfoItem(
                    icon: Icons.speed_outlined,
                    label: 'Activity Level',
                    value: _formatEnum(profile.activityLevel.toString()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.fitness_center,
            label: 'Goals',
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GoalsPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.restaurant_menu,
            label: 'Preferences',
            color: AppColors.secondary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PreferencesPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.history,
            label: 'History',
            color: AppColors.tertiary,
            onTap: () {
              // TODO: Navigate to history page
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSections(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const NotificationsPage()),
              );
            },
          ),
          Divider(height: 1, color: AppColors.dividerLight),
          _buildSettingsItem(
            icon: Icons.lock_outlined,
            title: 'Privacy',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPage()),
              );
            },
          ),
          Divider(height: 1, color: AppColors.dividerLight),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HelpSupportPage()),
              );
            },
          ),
          Divider(height: 1, color: AppColors.dividerLight),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
          Divider(height: 1, color: AppColors.dividerLight),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Log Out',
            onTap: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textMedium),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(LogoutEvent());
                      },
                      child: Text(
                        'Log Out',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.body1,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _formatEnum(String enumString) {
    // Remove enum type prefix (e.g., "Goal.loseWeight" -> "loseWeight")
    final parts = enumString.split('.');
    if (parts.length > 1) {
      final value = parts[1];

      // Convert camelCase to separate words with first letter capitalized
      final result = value.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => ' ${match.group(0)}',
      );

      return result[0].toUpperCase() + result.substring(1);
    }

    return enumString;
  }
}
