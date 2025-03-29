import 'package:flutter/material.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';

class AddMealButton extends StatelessWidget {
  final Function(MealType) onMealTypeSelected;

  const AddMealButton({
    super.key,
    required this.onMealTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        _showMealTypeBottomSheet(context);
      },
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add),
      mini: false, // Set to false to make it larger
    );
  }

  void _showMealTypeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Meal',
                style: AppTextStyles.headline6.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Select meal type to add',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 24),
              _buildMealTypeButton(
                context,
                MealType.breakfast,
                'Breakfast',
                Icons.breakfast_dining,
                'Morning meal to start your day',
              ),
              _buildMealTypeButton(
                context,
                MealType.lunch,
                'Lunch',
                Icons.lunch_dining,
                'Midday meal to keep you going',
              ),
              _buildMealTypeButton(
                context,
                MealType.dinner,
                'Dinner',
                Icons.dinner_dining,
                'Evening meal to end your day',
              ),
              _buildMealTypeButton(
                context,
                MealType.snack,
                'Snack',
                Icons.restaurant,
                'Small meal between main meals',
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMealTypeButton(
    BuildContext context,
    MealType type,
    String title,
    IconData icon,
    String description,
  ) {
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
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.subtitle1.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        description,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.textMedium,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onMealTypeSelected(type);
      },
    );
  }
}
