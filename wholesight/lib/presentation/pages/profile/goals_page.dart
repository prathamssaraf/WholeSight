import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_event.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';
import 'package:whole_sight/presentation/widgets/common/loading_indicator.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  // Form controllers and values
  Goal _selectedGoal = Goal.maintainWeight;
  double _calorieTarget = 2000;
  double _weightTarget = 70;
  Map<String, double> _macroTargets = {
    'protein': 120,
    'carbs': 200,
    'fat': 65,
  };

  @override
  void initState() {
    super.initState();

    // Initialize with current user's data
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated && state.user.nutritionProfile != null) {
      final profile = state.user.nutritionProfile!;

      setState(() {
        _selectedGoal = profile.goal;
        _calorieTarget = profile.calorieTarget;
        _weightTarget = profile.weightKg;
        _macroTargets = Map.from(profile.macroTargets);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Targets'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary goal section
            _buildSectionHeader('Primary Goal'),
            const SizedBox(height: 16),
            _buildGoalSelector(),

            const SizedBox(height: 32),

            // Target metrics
            _buildSectionHeader('Target Metrics'),
            const SizedBox(height: 16),
            _buildCalorieTarget(),

            const SizedBox(height: 24),

            _buildWeightTarget(),

            const SizedBox(height: 32),

            // Macronutrient targets
            _buildSectionHeader('Macronutrient Targets'),
            const SizedBox(height: 16),
            _buildMacroTargets(),

            const SizedBox(height: 32),

            // Save button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state is AuthLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: state is AuthLoading
                        ? const LoadingIndicator(color: Colors.white)
                        : Text(
                            'Save Changes',
                            style: AppTextStyles.button.copyWith(
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headline6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: AppColors.dividerLight),
      ],
    );
  }

  Widget _buildGoalSelector() {
    return Column(
      children: [
        _buildGoalOption(
          goal: Goal.loseWeight,
          title: 'Lose Weight',
          description: 'Reduce body fat while maintaining muscle',
          icon: Icons.trending_down_outlined,
        ),
        const SizedBox(height: 12),
        _buildGoalOption(
          goal: Goal.maintainWeight,
          title: 'Maintain Weight',
          description: 'Stay at your current weight while improving nutrition',
          icon: Icons.balance_outlined,
        ),
        const SizedBox(height: 12),
        _buildGoalOption(
          goal: Goal.gainWeight,
          title: 'Gain Weight',
          description: 'Increase body weight in a healthy way',
          icon: Icons.trending_up_outlined,
        ),
        const SizedBox(height: 12),
        _buildGoalOption(
          goal: Goal.buildMuscle,
          title: 'Build Muscle',
          description: 'Increase strength and muscle mass',
          icon: Icons.fitness_center_outlined,
        ),
        const SizedBox(height: 12),
        _buildGoalOption(
          goal: Goal.improveHealth,
          title: 'Improve Overall Health',
          description: 'Focus on balanced nutrition and wellness',
          icon: Icons.favorite_outlined,
        ),
        const SizedBox(height: 12),
        _buildGoalOption(
          goal: Goal.improveAthletic,
          title: 'Improve Athletic Performance',
          description: 'Optimize nutrition for sports and exercise',
          icon: Icons.speed_outlined,
        ),
      ],
    );
  }

  Widget _buildGoalOption({
    required Goal goal,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedGoal == goal;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGoal = goal;

          // Save current calorie target before adjustment
          double previousCalorieTarget = _calorieTarget;

          // Update calorie target based on goal
          switch (goal) {
            case Goal.loseWeight:
              _calorieTarget = previousCalorieTarget * 0.8; // 20% deficit
              break;
            case Goal.gainWeight:
            case Goal.buildMuscle:
              _calorieTarget = previousCalorieTarget * 1.15; // 15% surplus
              break;
            default:
              // No adjustment for maintenance
              break;
          }

          // Ensure calorie target is within bounds
          _calorieTarget = _calorieTarget.clamp(1200.0, 4000.0);

          // Update macro targets based on goal
          switch (goal) {
            case Goal.loseWeight:
              _macroTargets = {
                'protein':
                    _weightTarget * 2.2, // Higher protein for weight loss
                'fat': _weightTarget * 0.8,
                'carbs': (_calorieTarget -
                        ((_weightTarget * 2.2) * 4 +
                            (_weightTarget * 0.8) * 9)) /
                    4,
              };
              break;
            case Goal.buildMuscle:
              _macroTargets = {
                'protein':
                    _weightTarget * 2.2, // Higher protein for muscle building
                'fat': _weightTarget * 1.0,
                'carbs': (_calorieTarget -
                        ((_weightTarget * 2.2) * 4 +
                            (_weightTarget * 1.0) * 9)) /
                    4,
              };
              break;
            case Goal.improveAthletic:
              _macroTargets = {
                'protein': _weightTarget * 1.8,
                'fat': _weightTarget * 1.0,
                'carbs': (_calorieTarget -
                        ((_weightTarget * 1.8) * 4 +
                            (_weightTarget * 1.0) * 9)) /
                    4,
              };
              break;
            default:
              _macroTargets = {
                'protein': _weightTarget * 1.6,
                'fat': _weightTarget * 1.0,
                'carbs': (_calorieTarget -
                        ((_weightTarget * 1.6) * 4 +
                            (_weightTarget * 1.0) * 9)) /
                    4,
              };
              break;
          }

          // Ensure macros are within valid ranges
          _macroTargets['protein'] =
              (_macroTargets['protein'] ?? 120).clamp(50.0, 250.0);
          _macroTargets['fat'] =
              (_macroTargets['fat'] ?? 65).clamp(30.0, 150.0);
          _macroTargets['carbs'] =
              (_macroTargets['carbs'] ?? 30).clamp(50.0, 400.0);
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dividerLight,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.dividerLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textMedium,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color:
                          isSelected ? AppColors.primary : AppColors.textDark,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieTarget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Calorie Target',
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                setState(() {
                  if (_calorieTarget > 1200) {
                    _calorieTarget -= 50;
                  }
                });
              },
            ),
            Expanded(
              child: Slider(
                value: _calorieTarget,
                min: 1200,
                max: 4000,
                divisions: 56, // (4000 - 1200) / 50
                label: _calorieTarget.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _calorieTarget = value;
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  if (_calorieTarget < 4000) {
                    _calorieTarget += 50;
                  }
                });
              },
            ),
          ],
        ),
        Center(
          child: Text(
            '${_calorieTarget.round()} calories',
            style: AppTextStyles.headline6,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightTarget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Weight',
          style: AppTextStyles.subtitle1.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                setState(() {
                  if (_weightTarget > 40) {
                    _weightTarget -= 0.5;
                  }
                });
              },
            ),
            Expanded(
              child: Slider(
                value: _weightTarget,
                min: 40,
                max: 150,
                divisions: 220, // (150 - 40) / 0.5
                label: _weightTarget.toString(),
                onChanged: (value) {
                  setState(() {
                    _weightTarget = value;
                  });
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  if (_weightTarget < 150) {
                    _weightTarget += 0.5;
                  }
                });
              },
            ),
          ],
        ),
        Center(
          child: Text(
            '${_weightTarget.toStringAsFixed(1)} kg',
            style: AppTextStyles.headline6,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroTargets() {
    return Column(
      children: [
        // Pie chart visualization
        Container(
          height: 120,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMacroPercentage(
                macro: 'Protein',
                percentage:
                    (_macroTargets['protein']! * 4 / _calorieTarget * 100)
                        .round(),
                color: AppColors.protein,
              ),
              _buildMacroPercentage(
                macro: 'Carbs',
                percentage: (_macroTargets['carbs']! * 4 / _calorieTarget * 100)
                    .round(),
                color: AppColors.carbs,
              ),
              _buildMacroPercentage(
                macro: 'Fat',
                percentage:
                    (_macroTargets['fat']! * 9 / _calorieTarget * 100).round(),
                color: AppColors.fats,
              ),
            ],
          ),
        ),

        // Protein slider
        _buildMacroSlider(
          label: 'Protein',
          value: _macroTargets['protein'] ?? 120,
          min: 50,
          max: 250,
          color: AppColors.protein,
          onChange: (value) {
            setState(() {
              _macroTargets['protein'] = value;

              // Adjust carbs to maintain calorie target
              final proteinCalories = value * 4;
              final fatCalories = _macroTargets['fat']! * 9;
              final remainingCalories =
                  _calorieTarget - proteinCalories - fatCalories;
              _macroTargets['carbs'] =
                  remainingCalories / 4 > 0 ? remainingCalories / 4 : 0;
            });
          },
        ),

        const SizedBox(height: 16),

        // Carbs slider
        _buildMacroSlider(
          label: 'Carbs',
          value: _macroTargets['carbs'] ?? 200,
          min: 50,
          max: 400,
          color: AppColors.carbs,
          onChange: (value) {
            setState(() {
              _macroTargets['carbs'] = value;

              // Adjust fat to maintain calorie target
              final proteinCalories = _macroTargets['protein']! * 4;
              final carbsCalories = value * 4;
              final remainingCalories =
                  _calorieTarget - proteinCalories - carbsCalories;
              _macroTargets['fat'] =
                  remainingCalories / 9 > 0 ? remainingCalories / 9 : 0;
            });
          },
        ),

        const SizedBox(height: 16),

        // Fat slider
        _buildMacroSlider(
          label: 'Fat',
          value: _macroTargets['fat'] ?? 65,
          min: 30,
          max: 150,
          color: AppColors.fats,
          onChange: (value) {
            setState(() {
              _macroTargets['fat'] = value;

              // Adjust carbs to maintain calorie target
              final proteinCalories = _macroTargets['protein']! * 4;
              final fatCalories = value * 9;
              final remainingCalories =
                  _calorieTarget - proteinCalories - fatCalories;
              _macroTargets['carbs'] =
                  remainingCalories / 4 > 0 ? remainingCalories / 4 : 0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMacroPercentage({
    required String macro,
    required int percentage,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                '$percentage%',
                style: AppTextStyles.subtitle1.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            macro,
            style: AppTextStyles.body2.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required ValueChanged<double> onChange,
  }) {
    // Ensure value is within bounds
    double clampedValue = value.clamp(min, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.subtitle2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${clampedValue.round()} g',
              style: AppTextStyles.subtitle2.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: clampedValue,
          min: min,
          max: max,
          divisions: ((max - min) / 5).round(),
          activeColor: color,
          onChanged: onChange,
        ),
      ],
    );
  }

  void _saveChanges() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated && state.user.nutritionProfile != null) {
      final currentProfile = state.user.nutritionProfile!;

      // Create updated profile
      final updatedProfile = currentProfile.copyWith(
        goal: _selectedGoal,
        calorieTarget: _calorieTarget,
        weightKg: _weightTarget,
        macroTargets: _macroTargets,
      );

      // Update profile
      context.read<AuthBloc>().add(
            UpdateNutritionProfileEvent(
              nutritionProfile: updatedProfile,
            ),
          );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Goals updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
