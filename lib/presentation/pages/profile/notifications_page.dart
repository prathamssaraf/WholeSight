import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Notification settings
  bool _mealReminders = true;
  bool _weeklyReports = true;
  bool _foodRecommendations = true;
  bool _nutritionAlerts = true;
  bool _appUpdates = true;

  // Time settings
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
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
                    'Customize how and when you want to be notified.',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notification categories
                  _buildSection(
                    title: 'Notification Categories',
                    children: [
                      _buildSwitchTile(
                        title: 'Meal Reminders',
                        subtitle: 'Get reminders to log your meals',
                        value: _mealReminders,
                        onChanged: (value) {
                          setState(() {
                            _mealReminders = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Weekly Reports',
                        subtitle: 'Receive summaries of your nutrition',
                        value: _weeklyReports,
                        onChanged: (value) {
                          setState(() {
                            _weeklyReports = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Food Recommendations',
                        subtitle: 'Get personalized food suggestions',
                        value: _foodRecommendations,
                        onChanged: (value) {
                          setState(() {
                            _foodRecommendations = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Nutrition Alerts',
                        subtitle: 'Alerts about nutrient deficiencies',
                        value: _nutritionAlerts,
                        onChanged: (value) {
                          setState(() {
                            _nutritionAlerts = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'App Updates',
                        subtitle: 'News about new features and improvements',
                        value: _appUpdates,
                        onChanged: (value) {
                          setState(() {
                            _appUpdates = value;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Timing settings
                  _buildSection(
                    title: 'Reminder Settings',
                    children: [
                      ListTile(
                        title: Text(
                          'Meal Reminder Time',
                          style: AppTextStyles.body1,
                        ),
                        subtitle: Text(
                          'Daily reminder to log your meals',
                          style: AppTextStyles.caption,
                        ),
                        trailing: Text(
                          _reminderTime.format(context),
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: _reminderTime,
                            builder: (BuildContext context, Widget? child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: AppColors.primary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null && picked != _reminderTime) {
                            setState(() {
                              _reminderTime = picked;
                            });
                          }
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(
                          'Weekly Report Day',
                          style: AppTextStyles.body1,
                        ),
                        subtitle: Text(
                          'Day to receive your weekly nutrition summary',
                          style: AppTextStyles.caption,
                        ),
                        trailing: const Text(
                          'Sunday',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          // TODO: Implement day picker
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Delivery methods
                  _buildSection(
                    title: 'Delivery Methods',
                    children: [
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        subtitle: 'Receive notifications on your device',
                        value: true,
                        onChanged: (value) {
                          // This is the primary method, so we don't allow turning it off
                          // Just a placeholder to show the option
                        },
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Email Notifications',
                        subtitle: 'Receive notifications via email',
                        value: false,
                        onChanged: (value) {
                          // TODO: Implement email notification setting
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
                        // TODO: Save notification settings
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification settings saved'),
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
}
