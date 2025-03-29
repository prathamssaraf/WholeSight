import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';

abstract class NutritionCalculatorService {
  /// Calculates daily calorie needs based on user profile
  double calculateDailyCalorieNeeds(NutritionProfileEntity profile);
  
  /// Calculates macro distribution for given goals
  Map<String, double> calculateMacroTargets({
    required NutritionProfileEntity profile,
    required double calorieTarget,
  });
  
  /// Calculates the BMI (Body Mass Index)
  double calculateBMI({required double weightKg, required double heightCm});
  
  /// Calculates the TDEE (Total Daily Energy Expenditure)
  double calculateTDEE({
    required double bmr,
    required ActivityLevel activityLevel,
  });
  
  /// Calculates the BMR (Basal Metabolic Rate) using Harris-Benedict equation
  double calculateBMR({
    required int age,
    required double weightKg,
    required double heightCm,
    required Gender gender,
  });
  
  /// Calculates daily water needs in milliliters
  double calculateWaterNeeds({required double weightKg, required ActivityLevel activityLevel});
  
  /// Calculates nutrition totals for a meal
  Map<String, double> calculateMealNutrition(MealEntity meal);
  
  /// Calculates nutrition totals for a list of meals
  Map<String, double> calculateDailyNutrition(List<MealEntity> meals);
  
  /// Calculates the percentage of daily targets met
  Map<String, double> calculateTargetPercentages({
    required Map<String, double> actual,
    required Map<String, double> targets,
  });
}

class NutritionCalculatorServiceImpl implements NutritionCalculatorService {
  @override
  double calculateDailyCalorieNeeds(NutritionProfileEntity profile) {
    // Calculate BMR
    final bmr = calculateBMR(
      age: profile.age,
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      gender: profile.gender,
    );
    
    // Calculate TDEE
    final tdee = calculateTDEE(
      bmr: bmr, 
      activityLevel: profile.activityLevel,
    );
    
    // Adjust based on goal
    double calorieTarget;
    
    switch (profile.goal) {
      case Goal.loseWeight:
        calorieTarget = tdee * 0.8; // 20% deficit
        break;
      case Goal.gainWeight:
      case Goal.buildMuscle:
        calorieTarget = tdee * 1.15; // 15% surplus
        break;
      case Goal.improveAthletic:
        calorieTarget = tdee * 1.1; // 10% surplus
        break;
      case Goal.maintainWeight:
      case Goal.improveHealth:
      default:
        calorieTarget = tdee;
        break;
    }
    
    return calorieTarget;
  }
  
  @override
  Map<String, double> calculateMacroTargets({
    required NutritionProfileEntity profile,
    required double calorieTarget,
  }) {
    Map<String, double> macroTargets = {};
    
    switch (profile.goal) {
      case Goal.loseWeight:
        // Higher protein for weight loss
        macroTargets['protein'] = profile.weightKg * 2.2; // g/kg
        macroTargets['fat'] = profile.weightKg * 0.8; // g/kg
        // Calculate carbs with the remaining calories
        final proteinCalories = macroTargets['protein']! * 4;
        final fatCalories = macroTargets['fat']! * 9;
        final remainingCalories = calorieTarget - proteinCalories - fatCalories;
        macroTargets['carbs'] = remainingCalories > 0 ? remainingCalories / 4 : 50;
        break;
        
      case Goal.buildMuscle:
        // Higher protein and carbs for muscle building
        macroTargets['protein'] = profile.weightKg * 2.2; // g/kg
        macroTargets['fat'] = profile.weightKg * 1.0; // g/kg
        // Calculate carbs with the remaining calories
        final proteinCalories = macroTargets['protein']! * 4;
        final fatCalories = macroTargets['fat']! * 9;
        final remainingCalories = calorieTarget - proteinCalories - fatCalories;
        macroTargets['carbs'] = remainingCalories > 0 ? remainingCalories / 4 : 100;
        break;
        
      case Goal.improveAthletic:
        // Balanced macros with higher carbs for athletic performance
        macroTargets['protein'] = profile.weightKg * 1.8; // g/kg
        macroTargets['fat'] = profile.weightKg * 1.0; // g/kg
        // Calculate carbs with the remaining calories
        final proteinCalories = macroTargets['protein']! * 4;
        final fatCalories = macroTargets['fat']! * 9;
        final remainingCalories = calorieTarget - proteinCalories - fatCalories;
        macroTargets['carbs'] = remainingCalories > 0 ? remainingCalories / 4 : 150;
        break;
        
      // For maintenance and health improvement
      case Goal.maintainWeight:
      case Goal.gainWeight:
      case Goal.improveHealth:
      default:
        // Balanced macros
        macroTargets['protein'] = profile.weightKg * 1.6; // g/kg
        macroTargets['fat'] = profile.weightKg * 1.0; // g/kg
        // Calculate carbs with the remaining calories
        final proteinCalories = macroTargets['protein']! * 4;
        final fatCalories = macroTargets['fat']! * 9;
        final remainingCalories = calorieTarget - proteinCalories - fatCalories;
        macroTargets['carbs'] = remainingCalories > 0 ? remainingCalories / 4 : 100;
        break;
    }
    
    // Add fiber target based on calories
    macroTargets['fiber'] = calorieTarget / 1000 * 14; // 14g per 1000 calories
    
    return macroTargets;
  }
  
  @override
  double calculateBMI({required double weightKg, required double heightCm}) {
    // BMI = weight(kg) / height(m)²
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }
  
  @override
  double calculateTDEE({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    double activityFactor;
    
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        activityFactor = 1.2;
        break;
      case ActivityLevel.lightlyActive:
        activityFactor = 1.375;
        break;
      case ActivityLevel.moderatelyActive:
        activityFactor = 1.55;
        break;
      case ActivityLevel.veryActive:
        activityFactor = 1.725;
        break;
      case ActivityLevel.extremelyActive:
        activityFactor = 1.9;
        break;
    }
    
    return bmr * activityFactor;
  }
  
  @override
  double calculateBMR({
    required int age,
    required double weightKg,
    required double heightCm,
    required Gender gender,
  }) {
    // Harris-Benedict Equation
    if (gender == Gender.male) {
      return 88.362 + (13.397 * weightKg) + (4.799 * heightCm) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weightKg) + (3.098 * heightCm) - (4.330 * age);
    }
  }
  
  @override
  double calculateWaterNeeds({
    required double weightKg,
    required ActivityLevel activityLevel,
  }) {
    // Base water needs: 30-35ml per kg of body weight
    double baseNeeds = weightKg * 30;
    
    // Adjust for activity level
    switch (activityLevel) {
      case ActivityLevel.sedentary:
        return baseNeeds;
      case ActivityLevel.lightlyActive:
        return baseNeeds * 1.1;
      case ActivityLevel.moderatelyActive:
        return baseNeeds * 1.2;
      case ActivityLevel.veryActive:
        return baseNeeds * 1.3;
      case ActivityLevel.extremelyActive:
        return baseNeeds * 1.4;
    }
  }
  
  @override
  Map<String, double> calculateMealNutrition(MealEntity meal) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;
    double sugar = 0;
    
    for (var item in meal.items) {
      calories += item.totalCalories;
      protein += item.totalProtein;
      carbs += item.totalCarbs;
      fat += item.totalFat;
      fiber += item.totalFiber;
      sugar += item.totalSugar;
    }
    
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
    };
  }
  
  @override
  Map<String, double> calculateDailyNutrition(List<MealEntity> meals) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;
    double sugar = 0;
    
    for (var meal in meals) {
      final mealNutrition = calculateMealNutrition(meal);
      calories += mealNutrition['calories'] ?? 0;
      protein += mealNutrition['protein'] ?? 0;
      carbs += mealNutrition['carbs'] ?? 0;
      fat += mealNutrition['fat'] ?? 0;
      fiber += mealNutrition['fiber'] ?? 0;
      sugar += mealNutrition['sugar'] ?? 0;
    }
    
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
    };
  }
  
  @override
  Map<String, double> calculateTargetPercentages({
    required Map<String, double> actual,
    required Map<String, double> targets,
  }) {
    final Map<String, double> percentages = {};
    
    targets.forEach((key, targetValue) {
      if (targetValue > 0 && actual.containsKey(key)) {
        percentages[key] = (actual[key] ?? 0) / targetValue * 100;
      } else {
        percentages[key] = 0;
      }
    });
    
    return percentages;
  }
}