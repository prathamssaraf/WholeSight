import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_event.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  // Privacy settings
  bool _shareAnonymousData = true;
  bool _personalization = true;
  bool _locationAccess = false;
  bool _profileVisibility = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Privacy',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Explanation text
                  Text(
                    'Control how your information is used and shared.',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Data usage settings
                  _buildSection(
                    title: 'Data Usage',
                    children: [
                      _buildSwitchTile(
                        title: 'Share Anonymous Data',
                        subtitle:
                            'Help improve WholeSight with anonymous usage data',
                        value: _shareAnonymousData,
                        onChanged: (value) {
                          setState(() {
                            _shareAnonymousData = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Personalized Experience',
                        subtitle:
                            'Allow app to use your data for personalized recommendations',
                        value: _personalization,
                        onChanged: (value) {
                          setState(() {
                            _personalization = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Location Access',
                        subtitle:
                            'Allow location access for nearby food suggestions',
                        value: _locationAccess,
                        onChanged: (value) {
                          setState(() {
                            _locationAccess = value;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Account privacy
                  _buildSection(
                    title: 'Account Privacy',
                    children: [
                      _buildSwitchTile(
                        title: 'Profile Visibility',
                        subtitle: 'Allow friends to see your progress',
                        value: _profileVisibility,
                        onChanged: (value) {
                          setState(() {
                            _profileVisibility = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(
                          'Blocked Users',
                          style: AppTextStyles.body1,
                        ),
                        subtitle: Text(
                          'Manage users you have blocked',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to blocked users page
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Data management
                  _buildSection(
                    title: 'Data Management',
                    children: [
                      ListTile(
                        title: Text(
                          'Download Your Data',
                          style: AppTextStyles.body1,
                        ),
                        subtitle: Text(
                          'Export all your personal data',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                        trailing: const Icon(Icons.download_outlined),
                        onTap: () {
                          _showDataDownloadDialog();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(
                          'Delete Nutrition History',
                          style: AppTextStyles.body1,
                        ),
                        subtitle: Text(
                          'Clear your food log and nutrition data',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                        trailing: const Icon(Icons.delete_outline),
                        onTap: () {
                          _showDeleteHistoryDialog();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(
                          'Delete Account',
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                        subtitle: Text(
                          'Permanently delete your account and all data',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.delete_forever_outlined,
                          color: AppColors.error,
                        ),
                        onTap: () {
                          _showDeleteAccountDialog();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Privacy policy
                  _buildSection(
                    title: 'Legal',
                    children: [
                      ListTile(
                        title: Text(
                          'Privacy Policy',
                          style: AppTextStyles.body1,
                        ),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () {
                          // TODO: Open privacy policy
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(
                          'Terms of Service',
                          style: AppTextStyles.body1,
                        ),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () {
                          // TODO: Open terms of service
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Save privacy settings
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Privacy settings saved'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        'Save Settings',
                        style: AppTextStyles.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  // Helper method to build a section with a title and card
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  // Helper method to build a switch list tile
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: AppTextStyles.body1,
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMedium,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
    );
  }

  // Dialog to confirm data download
  void _showDataDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Your Data'),
        content: const Text(
          'We will prepare a download package with all your personal data, nutrition history, and preferences. You\'ll receive an email with the download link once it\'s ready.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Data download requested. Check your email soon.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text(
              'Request Download',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to confirm nutrition history deletion
  void _showDeleteHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Nutrition History'),
        content: const Text(
          'This will permanently delete all your food logs, nutrition data, and progress history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nutrition history deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Delete History',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog to confirm account deletion
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          TextButton(
            onPressed: () {
              // Show secondary confirmation
              Navigator.pop(context);
              _showFinalDeleteConfirmation();
            },
            child: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // Final confirmation for account deletion
  void _showFinalDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: const Text(
          'Please type "DELETE" to confirm you want to permanently delete your account and all data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMedium),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement account deletion logic
              Navigator.pop(context);
              // Navigate back to login screen
              context.read<AuthBloc>().add(LogoutEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deleted successfully'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text(
              'Confirm Deletion',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
