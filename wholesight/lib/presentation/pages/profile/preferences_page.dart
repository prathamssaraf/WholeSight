import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_event.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';
import 'package:whole_sight/presentation/widgets/common/loading_indicator.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  // Form controllers and values
  DietType _selectedDietType = DietType.standard;
  List<String> _allergies = [];
  List<String> _dislikedFoods = [];
  List<String> _medicalConditions = [];

  // Text controllers
  final _allergiesController = TextEditingController();
  final _dislikedFoodsController = TextEditingController();
  final _medicalConditionsController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize with current user's data
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated && state.user.nutritionProfile != null) {
      final profile = state.user.nutritionProfile!;

      setState(() {
        _selectedDietType = profile.dietType;
        _allergies = List.from(profile.allergies);
        _dislikedFoods = List.from(profile.dislikedFoods);
        _medicalConditions = List.from(profile.medicalConditions);
      });

      // Set text controllers
      _allergiesController.text = _allergies.join(', ');
      _dislikedFoodsController.text = _dislikedFoods.join(', ');
      _medicalConditionsController.text = _medicalConditions.join(', ');
    }
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _dislikedFoodsController.dispose();
    _medicalConditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Preferences'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diet type section
            _buildSectionHeader('Diet Type'),
            const SizedBox(height: 16),
            _buildDietTypeSelector(),

            const SizedBox(height: 32),

            // Allergies section
            _buildSectionHeader('Allergies & Restrictions'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _allergiesController,
              labelText: 'Allergies or Food Restrictions',
              hintText: 'e.g., peanuts, shellfish, dairy',
              iconData: Icons.dangerous_outlined,
              onChanged: (value) {
                _allergies = _parseListInput(value);
              },
            ),

            const SizedBox(height: 32),

            // Disliked foods section
            _buildSectionHeader('Foods You Dislike'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _dislikedFoodsController,
              labelText: 'Foods You Prefer to Avoid',
              hintText: 'e.g., mushrooms, olives, cilantro',
              iconData: Icons.thumb_down_outlined,
              onChanged: (value) {
                _dislikedFoods = _parseListInput(value);
              },
            ),

            const SizedBox(height: 32),

            // Medical conditions section
            _buildSectionHeader('Medical Conditions'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _medicalConditionsController,
              labelText: 'Medical Conditions (Optional)',
              hintText: 'e.g., diabetes, hypertension, IBS',
              iconData: Icons.medical_services_outlined,
              onChanged: (value) {
                _medicalConditions = _parseListInput(value);
              },
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

  Widget _buildDietTypeSelector() {
    return Column(
      children: [
        _buildDietTypeOption(
          dietType: DietType.standard,
          title: 'Standard',
          description: 'No specific dietary restrictions',
          icon: Icons.restaurant_outlined,
        ),
        const SizedBox(height: 12),
        _buildDietTypeOption(
          dietType: DietType.vegetarian,
          title: 'Vegetarian',
          description: 'No meat, but includes dairy and eggs',
          icon: Icons.egg_outlined,
        ),
        const SizedBox(height: 12),
        _buildDietTypeOption(
          dietType: DietType.vegan,
          title: 'Vegan',
          description: 'No animal products',
          icon: Icons.grass_outlined,
        ),
        const SizedBox(height: 12),
        _buildDietTypeOption(
          dietType: DietType.pescatarian,
          title: 'Pescatarian',
          description: 'Vegetarian plus seafood',
          icon: Icons.set_meal_outlined,
        ),
        const SizedBox(height: 12),
        _buildDietTypeOption(
          dietType: DietType.keto,
          title: 'Keto',
          description: 'Very low carb, high fat diet',
          icon: Icons.local_fire_department_outlined,
        ),
        const SizedBox(height: 12),
        _buildDietTypeOption(
          dietType: DietType.lowCarb,
          title: 'Low Carb',
          description: 'Reduced carbohydrate intake',
          icon: Icons.grain_outlined,
        ),
        const SizedBox(height: 12),
        _buildDietTypeOption(
          dietType: DietType.mediterranean,
          title: 'Mediterranean',
          description:
              'Focuses on fruits, vegetables, whole grains, and healthy fats',
          icon: Icons.local_florist_outlined,
        ),
        const SizedBox(height: 12),
        _buildDietTypeOption(
          dietType: DietType.gluten_free,
          title: 'Gluten Free',
          description: 'Excludes gluten-containing foods',
          icon: Icons.do_not_disturb_outlined,
        ),
      ],
    );
  }

  Widget _buildDietTypeOption({
    required DietType dietType,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedDietType == dietType;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDietType = dietType;
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData iconData,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(iconData),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: onChanged,
      maxLines: null,
    );
  }

  List<String> _parseListInput(String input) {
    if (input.isEmpty) {
      return [];
    }

    return input
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  void _saveChanges() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated && state.user.nutritionProfile != null) {
      final currentProfile = state.user.nutritionProfile!;

      // Create updated profile
      final updatedProfile = currentProfile.copyWith(
        dietType: _selectedDietType,
        allergies: _allergies,
        dislikedFoods: _dislikedFoods,
        medicalConditions: _medicalConditions,
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
          content: const Text('Preferences updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
