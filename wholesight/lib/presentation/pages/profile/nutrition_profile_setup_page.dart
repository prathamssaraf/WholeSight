import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_event.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';
import 'package:whole_sight/presentation/pages/dashboard/dashboard_page.dart';
import 'package:whole_sight/presentation/widgets/common/loading_indicator.dart';

class NutritionProfileSetupPage extends StatefulWidget {
  final UserEntity user;

  const NutritionProfileSetupPage({
    super.key,
    required this.user,
  });

  @override
  State<NutritionProfileSetupPage> createState() =>
      _NutritionProfileSetupPageState();
}

class _NutritionProfileSetupPageState extends State<NutritionProfileSetupPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // User profile data
  int _age = 30;
  double _weightKg = 70;
  double _heightCm = 170;
  Gender _gender = Gender.male;
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  Goal _goal = Goal.maintainWeight;
  DietType _dietType = DietType.standard;
  List<String> _allergies = [];
  List<String> _dislikedFoods = [];
  List<String> _medicalConditions = [];

  // Steps in the setup process
  final List<String> _steps = [
    'Basic Info',
    'Body Stats',
    'Activity',
    'Goals',
    'Diet',
    'Preferences',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          print(
              "NutritionProfileSetupPage: Received state: ${state.runtimeType}");
          if (state is AuthError) {
            print(
                "NutritionProfileSetupPage: Error state received: ${state.message}");
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is ProfileUpdateSuccess) {
            print("NutritionProfileSetupPage: ProfileUpdateSuccess received");
            // Navigate to dashboard
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const DashboardPage()),
              (route) => false,
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Header
                    Row(
                      children: [
                        if (_currentStep > 0)
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _goToPreviousStep,
                          ),
                        Expanded(
                          child: Text(
                            'Step ${_currentStep + 1} of ${_steps.length}: ${_steps[_currentStep]}',
                            style: AppTextStyles.headline6,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(width: _currentStep > 0 ? 48 : 0),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Progress bar
                    LinearProgressIndicator(
                      value: (_currentStep + 1) / _steps.length,
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ],
                ),
              ),

              // Page view
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: [
                    _buildBasicInfoStep(),
                    _buildBodyStatsStep(),
                    _buildActivityStep(),
                    _buildGoalsStep(),
                    _buildDietStep(),
                    _buildPreferencesStep(),
                  ],
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip button (only show if not on last step)
                    _currentStep < _steps.length - 1
                        ? TextButton(
                            onPressed: _skipToLastStep,
                            child: Text(
                              'Skip to End',
                              style: AppTextStyles.button.copyWith(
                                color: AppColors.textMedium,
                              ),
                            ),
                          )
                        : const SizedBox(width: 100),

                    // Next/Submit button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is AuthLoading
                              ? null
                              : _currentStep < _steps.length - 1
                                  ? _goToNextStep
                                  : _submitProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            minimumSize: const Size(120, 48),
                          ),
                          child: state is AuthLoading
                              ? const LoadingIndicator(color: Colors.white)
                              : Text(
                                  _currentStep < _steps.length - 1
                                      ? 'Next'
                                      : 'Complete Setup',
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Step builders
  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tell us about yourself',
            style: AppTextStyles.headline5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This information helps us personalize your nutrition recommendations.',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 32),

          // Gender selection
          Text(
            'Gender',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSelectionTile(
                  isSelected: _gender == Gender.male,
                  title: 'Male',
                  icon: Icons.male,
                  onTap: () {
                    setState(() {
                      _gender = Gender.male;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSelectionTile(
                  isSelected: _gender == Gender.female,
                  title: 'Female',
                  icon: Icons.female,
                  onTap: () {
                    setState(() {
                      _gender = Gender.female;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSelectionTile(
                  isSelected: _gender == Gender.other,
                  title: 'Other',
                  icon: Icons.person,
                  onTap: () {
                    setState(() {
                      _gender = Gender.other;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Age selection
          Text(
            'Age',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() {
                    if (_age > 1) {
                      _age--;
                    }
                  });
                },
              ),
              Expanded(
                child: Slider(
                  value: _age.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: _age.toString(),
                  onChanged: (value) {
                    setState(() {
                      _age = value.round();
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() {
                    if (_age < 100) {
                      _age++;
                    }
                  });
                },
              ),
            ],
          ),
          Center(
            child: Text(
              '$_age years',
              style: AppTextStyles.headline6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyStatsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Statistics',
            style: AppTextStyles.headline5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us calculate your nutritional needs more accurately.',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 32),

          // Height selection
          Text(
            'Height',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() {
                    if (_heightCm > 100) {
                      _heightCm--;
                    }
                  });
                },
              ),
              Expanded(
                child: Slider(
                  value: _heightCm,
                  min: 100,
                  max: 220,
                  divisions: 120,
                  label: _heightCm.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _heightCm = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() {
                    if (_heightCm < 220) {
                      _heightCm++;
                    }
                  });
                },
              ),
            ],
          ),
          Center(
            child: Text(
              '${_heightCm.round()} cm',
              style: AppTextStyles.headline6,
            ),
          ),
          const SizedBox(height: 32),

          // Weight selection
          Text(
            'Weight',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() {
                    if (_weightKg > 30) {
                      _weightKg--;
                    }
                  });
                },
              ),
              Expanded(
                child: Slider(
                  value: _weightKg,
                  min: 30,
                  max: 200,
                  divisions: 170,
                  label: _weightKg.round().toString(),
                  onChanged: (value) {
                    setState(() {
                      _weightKg = value;
                    });
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () {
                  setState(() {
                    if (_weightKg < 200) {
                      _weightKg++;
                    }
                  });
                },
              ),
            ],
          ),
          Center(
            child: Text(
              '${_weightKg.round()} kg',
              style: AppTextStyles.headline6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Level',
            style: AppTextStyles.headline5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the option that best describes your typical activity level.',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 32),

          // Activity level selection
          _buildActivityLevelTile(
            level: ActivityLevel.sedentary,
            title: 'Sedentary',
            description: 'Little or no exercise, desk job',
            icon: Icons.weekend_outlined,
          ),
          const SizedBox(height: 16),
          _buildActivityLevelTile(
            level: ActivityLevel.lightlyActive,
            title: 'Lightly Active',
            description: 'Light exercise 1-3 days/week',
            icon: Icons.directions_walk_outlined,
          ),
          const SizedBox(height: 16),
          _buildActivityLevelTile(
            level: ActivityLevel.moderatelyActive,
            title: 'Moderately Active',
            description: 'Moderate exercise 3-5 days/week',
            icon: Icons.directions_run_outlined,
          ),
          const SizedBox(height: 16),
          _buildActivityLevelTile(
            level: ActivityLevel.veryActive,
            title: 'Very Active',
            description: 'Hard exercise 6-7 days/week',
            icon: Icons.fitness_center_outlined,
          ),
          const SizedBox(height: 16),
          _buildActivityLevelTile(
            level: ActivityLevel.extremelyActive,
            title: 'Extremely Active',
            description:
                'Hard daily exercise & physical job or training twice a day',
            icon: Icons.sports_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Goals',
            style: AppTextStyles.headline5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What would you like to achieve with WholeSight?',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 32),

          // Goal selection
          _buildGoalTile(
            goal: Goal.loseWeight,
            title: 'Lose Weight',
            description: 'Reduce body fat while maintaining muscle',
            icon: Icons.trending_down_outlined,
          ),
          const SizedBox(height: 16),
          _buildGoalTile(
            goal: Goal.maintainWeight,
            title: 'Maintain Weight',
            description:
                'Stay at your current weight while improving nutrition',
            icon: Icons.balance_outlined,
          ),
          const SizedBox(height: 16),
          _buildGoalTile(
            goal: Goal.gainWeight,
            title: 'Gain Weight',
            description: 'Increase body weight in a healthy way',
            icon: Icons.trending_up_outlined,
          ),
          const SizedBox(height: 16),
          _buildGoalTile(
            goal: Goal.buildMuscle,
            title: 'Build Muscle',
            description: 'Increase strength and muscle mass',
            icon: Icons.fitness_center_outlined,
          ),
          const SizedBox(height: 16),
          _buildGoalTile(
            goal: Goal.improveHealth,
            title: 'Improve Overall Health',
            description: 'Focus on balanced nutrition and wellness',
            icon: Icons.favorite_outlined,
          ),
          const SizedBox(height: 16),
          _buildGoalTile(
            goal: Goal.improveAthletic,
            title: 'Improve Athletic Performance',
            description: 'Optimize nutrition for sports and exercise',
            icon: Icons.speed_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildDietStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dietary Preferences',
            style: AppTextStyles.headline5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the diet type that best matches your preferences.',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 32),

          // Diet type selection
          _buildDietTypeTile(
            dietType: DietType.standard,
            title: 'Standard',
            description: 'No specific dietary restrictions',
            icon: Icons.restaurant_outlined,
          ),
          const SizedBox(height: 16),
          _buildDietTypeTile(
            dietType: DietType.vegetarian,
            title: 'Vegetarian',
            description: 'No meat, but includes dairy and eggs',
            icon: Icons.egg_outlined,
          ),
          const SizedBox(height: 16),
          _buildDietTypeTile(
            dietType: DietType.vegan,
            title: 'Vegan',
            description: 'No animal products',
            icon: Icons.grass_outlined,
          ),
          const SizedBox(height: 16),
          _buildDietTypeTile(
            dietType: DietType.pescatarian,
            title: 'Pescatarian',
            description: 'Vegetarian plus seafood',
            icon: Icons.set_meal_outlined,
          ),
          const SizedBox(height: 16),
          _buildDietTypeTile(
            dietType: DietType.keto,
            title: 'Keto',
            description: 'Very low carb, high fat diet',
            icon: Icons.local_fire_department_outlined,
          ),
          const SizedBox(height: 16),
          _buildDietTypeTile(
            dietType: DietType.lowCarb,
            title: 'Low Carb',
            description: 'Reduced carbohydrate intake',
            icon: Icons.grain_outlined,
          ),
          const SizedBox(height: 16),
          _buildDietTypeTile(
            dietType: DietType.mediterranean,
            title: 'Mediterranean',
            description:
                'Focuses on fruits, vegetables, whole grains, and healthy fats',
            icon: Icons.local_florist_outlined,
          ),
          const SizedBox(height: 16),
          _buildDietTypeTile(
            dietType: DietType.gluten_free,
            title: 'Gluten Free',
            description: 'Excludes gluten-containing foods',
            icon: Icons.do_not_disturb_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Preferences',
            style: AppTextStyles.headline5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about any allergies, foods you dislike, or medical conditions that may affect your nutrition.',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 32),

          // Allergies
          Text(
            'Allergies',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Placeholder for allergy input
          const TextField(
            decoration: InputDecoration(
              hintText: 'e.g., peanuts, shellfish, dairy',
              prefixIcon: Icon(Icons.dangerous_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Disliked foods
          Text(
            'Foods You Dislike',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Placeholder for disliked foods input
          const TextField(
            decoration: InputDecoration(
              hintText: 'e.g., mushrooms, olives, cilantro',
              prefixIcon: Icon(Icons.thumb_down_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Medical conditions
          Text(
            'Medical Conditions',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Placeholder for medical conditions input
          const TextField(
            decoration: InputDecoration(
              hintText: 'e.g., diabetes, hypertension, IBS',
              prefixIcon: Icon(Icons.medical_services_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // Privacy note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Your health information is private and encrypted. We use it only to provide personalized nutrition recommendations.',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildSelectionTile({
    required bool isSelected,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 12,
        ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textMedium,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.body1.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLevelTile({
    required ActivityLevel level,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _activityLevel == level;

    return InkWell(
      onTap: () {
        setState(() {
          _activityLevel = level;
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

  Widget _buildGoalTile({
    required Goal goal,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _goal == goal;

    return InkWell(
      onTap: () {
        setState(() {
          _goal = goal;
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

  Widget _buildDietTypeTile({
    required DietType dietType,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _dietType == dietType;

    return InkWell(
      onTap: () {
        setState(() {
          _dietType = dietType;
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

  // Navigation methods
  void _goToNextStep() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousStep() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipToLastStep() {
    _pageController.animateToPage(
      _steps.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _submitProfile() {
    // Calculate daily calorie needs based on Harris-Benedict formula
    print("Submitting profile...");
    double bmr;
    if (_gender == Gender.male) {
      bmr =
          88.362 + (13.397 * _weightKg) + (4.799 * _heightCm) - (5.677 * _age);
    } else {
      bmr =
          447.593 + (9.247 * _weightKg) + (3.098 * _heightCm) - (4.330 * _age);
    }

    // Apply activity factor
    double calorieTarget;
    switch (_activityLevel) {
      case ActivityLevel.sedentary:
        calorieTarget = bmr * 1.2;
        break;
      case ActivityLevel.lightlyActive:
        calorieTarget = bmr * 1.375;
        break;
      case ActivityLevel.moderatelyActive:
        calorieTarget = bmr * 1.55;
        break;
      case ActivityLevel.veryActive:
        calorieTarget = bmr * 1.725;
        break;
      case ActivityLevel.extremelyActive:
        calorieTarget = bmr * 1.9;
        break;
    }

    // Adjust for goal
    switch (_goal) {
      case Goal.loseWeight:
        calorieTarget *= 0.8; // 20% deficit
        break;
      case Goal.gainWeight:
      case Goal.buildMuscle:
        calorieTarget *= 1.15; // 15% surplus
        break;
      default:
        // No adjustment for maintenance
        break;
    }

    // Calculate macronutrient targets
    Map<String, double> macroTargets;

    switch (_goal) {
      case Goal.loseWeight:
        macroTargets = {
          'protein': _weightKg * 2.0, // Higher protein for weight loss
          'fat': (_weightKg * 0.8),
          'carbs': (calorieTarget -
                  ((_weightKg * 2.0) * 4 + (_weightKg * 0.8) * 9)) /
              4,
        };
        break;
      case Goal.buildMuscle:
        macroTargets = {
          'protein': _weightKg * 2.2, // Higher protein for muscle building
          'fat': (_weightKg * 1.0),
          'carbs': (calorieTarget -
                  ((_weightKg * 2.2) * 4 + (_weightKg * 1.0) * 9)) /
              4,
        };
        break;
      case Goal.improveAthletic:
        macroTargets = {
          'protein': _weightKg * 1.8,
          'fat': (_weightKg * 1.0),
          'carbs': (calorieTarget -
                  ((_weightKg * 1.8) * 4 + (_weightKg * 1.0) * 9)) /
              4,
        };
        break;
      default:
        macroTargets = {
          'protein': _weightKg * 1.6,
          'fat': (_weightKg * 1.0),
          'carbs': (calorieTarget -
                  ((_weightKg * 1.6) * 4 + (_weightKg * 1.0) * 9)) /
              4,
        };
        break;
    }

    // Ensure macros are not negative
    macroTargets['carbs'] =
        macroTargets['carbs']! < 0 ? 30 : macroTargets['carbs']!;

    // Create nutrition profile
    final nutritionProfile = NutritionProfileEntity(
      userId: widget.user.id,
      age: _age,
      weightKg: _weightKg,
      heightCm: _heightCm,
      gender: _gender,
      activityLevel: _activityLevel,
      goal: _goal,
      dietType: _dietType,
      allergies: _allergies,
      dislikedFoods: _dislikedFoods,
      medicalConditions: _medicalConditions,
      macroTargets: macroTargets,
      calorieTarget: calorieTarget,
      waterTarget: _weightKg * 30, // 30ml per kg of body weight
    );

    print(
        "Creating nutrition profile with: ${widget.user.id}, $_gender, $_age, $_heightCm, $_weightKg");

    // Submit the profile
    context.read<AuthBloc>().add(
          CompleteProfileEvent(
            nutritionProfile: nutritionProfile,
          ),
        );
    print("Profile submission event dispatched");
  }
}
