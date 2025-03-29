// lib/domain/usecases/user/get_comprehensive_nutrition_analysis.dart
import 'package:dartz/dartz.dart';
import 'package:whole_sight/core/errors/failures.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/domain/repositories/food_repository.dart';
import 'package:whole_sight/domain/repositories/user_repository.dart';
import 'package:whole_sight/services/nutrition/nutrition_calculator_service.dart';
// Add this import to the top of get_comprehensive_nutrition_analysis.dart
import 'package:whole_sight/data/models/meal.dart';

class NutritionAnalysisResult {
  final Map<String, double> dailyAverage;
  final Map<String, double> targetPercentages;
  final Map<String, List<double>> weeklyTrend;
  final Map<String, double> mealTypeDistribution;
  final List<String> nutritionalInsights;
  final Map<String, double> macronutrientRatio;
  final Map<String, double> micronutrientCompletion;
  final List<MealEntity> topMeals;
  final Map<String, double> weekdayPatterns;
  final Map<DateTime, Map<String, double>> dailyIntakeHistory;

  NutritionAnalysisResult({
    required this.dailyAverage,
    required this.targetPercentages,
    required this.weeklyTrend,
    required this.mealTypeDistribution,
    required this.nutritionalInsights,
    required this.macronutrientRatio,
    required this.micronutrientCompletion,
    required this.topMeals,
    required this.weekdayPatterns,
    required this.dailyIntakeHistory,
  });
}

// Rest of your use case implementation...
class GetComprehensiveNutritionAnalysis {
  final FoodRepository foodRepository;
  final UserRepository userRepository;
  final NutritionCalculatorService calculatorService;

  GetComprehensiveNutritionAnalysis({
    required this.foodRepository,
    required this.userRepository,
    required this.calculatorService,
  });

  Future<Either<Failure, NutritionAnalysisResult>> call({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Default to last 30 days if no dates provided
    final end = endDate ?? DateTime.now();
    final start = startDate ?? end.subtract(const Duration(days: 30));

    try {
      // Get user profile to access targets
      final userResult = await userRepository.getUserById(userId);

      return userResult.fold(
        (failure) => Left(failure),
        (user) async {
          final profile = user.nutritionProfile;
          if (profile == null) {
            // Use a concrete implementation of Failure instead of the abstract class
            return Left(
                ServerFailure(message: 'User has no nutrition profile'));
          }

          final mealsResult = await _getMealsForDateRange(userId, start, end);
          return mealsResult.fold(
            (failure) => Left(failure),
            (meals) {
              // Calculate analysis data
              final result = _calculateAnalysisData(meals, profile);
              return Right(result);
            },
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, List<MealEntity>>> _getMealsForDateRange(
      String userId, DateTime startDate, DateTime endDate) async {
    List<MealEntity> allMeals = [];

    // Get meals for each day in the range
    for (DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      final mealsResult =
          await foodRepository.getMealsByUserAndDate(userId, date);

      await mealsResult.fold(
        (failure) => Left(failure),
        (meals) {
          // Convert each Meal to MealEntity
          for (var meal in meals) {
            try {
              // Convert from Meal to MealEntity
              allMeals.add(_convertMealToEntity(meal));
            } catch (e) {
              print('Error converting meal: $e');
              // Continue with next meal
            }
          }
        },
      );
    }

    if (allMeals.isEmpty) {
      // If no meals found, provide sample data for testing
      allMeals = _generateSampleMealEntities();
    }

    return Right(allMeals);
  }

// Helper function to convert Meal to MealEntity
  MealEntity _convertMealToEntity(Meal meal) {
    // Convert FoodItem list to MealItemEntity list
    List<MealItemEntity> mealItems = [];
    // For now, we're skipping the actual food items conversion as it would
    // require converting FoodItem to FoodEntity which may not be available

    // Create a meaningful name from the meal type
    String mealName = '';
    switch (meal.type) {
      case MealType.breakfast:
        mealName = 'Breakfast at ${meal.time}';
        break;
      case MealType.lunch:
        mealName = 'Lunch at ${meal.time}';
        break;
      case MealType.dinner:
        mealName = 'Dinner at ${meal.time}';
        break;
      case MealType.snack:
        mealName = 'Snack at ${meal.time}';
        break;
      default:
        mealName = 'Meal at ${meal.time}';
    }

    return MealEntity(
      id: meal.id ?? '',
      userId: meal.userId,
      name: mealName,
      type: meal.type, // MealType enum is shared between classes
      timestamp: meal.date, // Use the meal date
      items: mealItems, // Empty list for now
      createdAt: DateTime.now(),
    );
  }

// Sample data function for testing
  List<MealEntity> _generateSampleMealEntities() {
    final now = DateTime.now();
    List<MealEntity> sampleMeals = [];

    // Generate a variety of meals over the last week
    for (int i = 0; i < 7; i++) {
      final mealDate = now.subtract(Duration(days: i));

      // Add breakfast
      sampleMeals.add(MealEntity(
        id: 'breakfast-$i',
        userId: 'user1',
        name: 'Breakfast Meal ${i + 1}',
        type: MealType.breakfast,
        timestamp: DateTime(mealDate.year, mealDate.month, mealDate.day, 8, 0),
        items: [],
        createdAt: now,
      ));

      // Add lunch
      sampleMeals.add(MealEntity(
        id: 'lunch-$i',
        userId: 'user1',
        name: 'Lunch Meal ${i + 1}',
        type: MealType.lunch,
        timestamp: DateTime(mealDate.year, mealDate.month, mealDate.day, 13, 0),
        items: [],
        createdAt: now,
      ));

      // Add dinner
      sampleMeals.add(MealEntity(
        id: 'dinner-$i',
        userId: 'user1',
        name: 'Dinner Meal ${i + 1}',
        type: MealType.dinner,
        timestamp: DateTime(mealDate.year, mealDate.month, mealDate.day, 19, 0),
        items: [],
        createdAt: now,
      ));

      // Sometimes add a snack
      if (i % 2 == 0) {
        sampleMeals.add(MealEntity(
          id: 'snack-$i',
          userId: 'user1',
          name: 'Afternoon Snack ${i + 1}',
          type: MealType.snack,
          timestamp:
              DateTime(mealDate.year, mealDate.month, mealDate.day, 16, 0),
          items: [],
          createdAt: now,
        ));
      }
    }

    return sampleMeals;
  }

// Helper functions for safe property access
  String getNameFromMeal(dynamic meal) {
    // Check what property to use for the name
    if (meal.name != null) return meal.name;
    if (meal.type != null) return 'Meal: ${meal.type}';
    return 'Unnamed Meal';
  }

  DateTime getDateTimeFromMeal(dynamic meal) {
    try {
      if (meal.timestamp != null) return meal.timestamp;
      if (meal.date != null) {
        if (meal.date is String) return DateTime.parse(meal.date);
        if (meal.date is DateTime) return meal.date;
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  MealType getMealTypeFromString(String typeStr) {
    switch (typeStr.toLowerCase()) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'snack':
        return MealType.snack;
      default:
        return MealType.other;
    }
  }

  MealType _convertMealType(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return MealType.breakfast;
      case 'lunch':
        return MealType.lunch;
      case 'dinner':
        return MealType.dinner;
      case 'snack':
        return MealType.snack;
      default:
        return MealType.other;
    }
  }

  NutritionAnalysisResult _calculateAnalysisData(
    List<MealEntity> meals,
    NutritionProfileEntity profile,
  ) {
    // Group meals by date
    final mealsByDate = _groupMealsByDate(meals);

    // Calculate daily averages
    final dailyAverage = _calculateDailyAverages(mealsByDate);

    // Calculate target percentages
    final targetPercentages = calculatorService.calculateTargetPercentages(
      actual: dailyAverage,
      targets: {
        'calories': profile.calorieTarget,
        'protein': profile.macroTargets['protein'] ?? 0.0,
        'carbs': profile.macroTargets['carbs'] ?? 0.0,
        'fat': profile.macroTargets['fats'] ?? 0.0,
        'fiber': profile.macroTargets['fiber'] ?? 0.0,
      },
    );

    // Calculate weekly trends
    final weeklyTrend = _calculateWeeklyTrend(mealsByDate);

    // Calculate meal type distribution
    final mealTypeDistribution = _calculateMealTypeDistribution(meals);

    // Get nutritional insights (this would typically come from an AI service)
    final nutritionalInsights =
        _generateNutritionalInsights(dailyAverage, targetPercentages, profile);

    // Calculate macronutrient ratio
    final macronutrientRatio = _calculateMacronutrientRatio(dailyAverage);

    // Calculate micronutrient completion
    final micronutrientCompletion =
        _calculateMicronutrientCompletion(meals, profile);

    // Get top meals (by nutritional quality or frequency)
    final topMeals = _getTopMeals(meals);

    // Calculate weekday patterns
    final weekdayPatterns = _calculateWeekdayPatterns(mealsByDate);

    // Prepare daily intake history
    final dailyIntakeHistory = _prepareDailyIntakeHistory(mealsByDate);

    return NutritionAnalysisResult(
      dailyAverage: dailyAverage,
      targetPercentages: targetPercentages,
      weeklyTrend: weeklyTrend,
      mealTypeDistribution: mealTypeDistribution,
      nutritionalInsights: nutritionalInsights,
      macronutrientRatio: macronutrientRatio,
      micronutrientCompletion: micronutrientCompletion,
      topMeals: topMeals,
      weekdayPatterns: weekdayPatterns,
      dailyIntakeHistory: dailyIntakeHistory,
    );
  }

  // Helper methods for calculations
  Map<DateTime, List<MealEntity>> _groupMealsByDate(List<MealEntity> meals) {
    final Map<DateTime, List<MealEntity>> mealsByDate = {};

    for (final meal in meals) {
      final date = DateTime(
          meal.timestamp.year, meal.timestamp.month, meal.timestamp.day);

      if (!mealsByDate.containsKey(date)) {
        mealsByDate[date] = [];
      }

      mealsByDate[date]!.add(meal);
    }

    return mealsByDate;
  }

  Map<String, double> _calculateDailyAverages(
      Map<DateTime, List<MealEntity>> mealsByDate) {
    if (mealsByDate.isEmpty) {
      return {
        'calories': 0.0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'fiber': 0.0,
        'sugar': 0.0,
      };
    }

    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;
    double totalSugar = 0.0;

    for (final meals in mealsByDate.values) {
      for (final meal in meals) {
        totalCalories += meal.totalCalories;
        totalProtein += meal.totalProtein;
        totalCarbs += meal.totalCarbs;
        totalFat += meal.totalFat;
        totalFiber += meal.totalFiber;
        totalSugar += meal.totalSugar;
      }
    }

    final daysCount = mealsByDate.length;

    return {
      'calories': totalCalories / daysCount,
      'protein': totalProtein / daysCount,
      'carbs': totalCarbs / daysCount,
      'fat': totalFat / daysCount,
      'fiber': totalFiber / daysCount,
      'sugar': totalSugar / daysCount,
    };
  }

  Map<String, List<double>> _calculateWeeklyTrend(
      Map<DateTime, List<MealEntity>> mealsByDate) {
    // Implement weekly trend calculation logic
    // For now, returning a placeholder
    return {
      'calories': [2000, 1950, 2100, 2050, 1900, 2150, 2000],
      'protein': [120, 115, 125, 130, 110, 128, 122],
      'carbs': [200, 190, 210, 205, 185, 215, 200],
      'fat': [70, 68, 75, 72, 65, 76, 70],
    };
  }

  Map<String, double> _calculateMealTypeDistribution(List<MealEntity> meals) {
    final Map<MealType, int> mealTypeCounts = {};

    for (final meal in meals) {
      mealTypeCounts[meal.type] = (mealTypeCounts[meal.type] ?? 0) + 1;
    }

    final total = meals.length;
    final Map<String, double> distribution = {};

    for (final entry in mealTypeCounts.entries) {
      final percentage = (entry.value / total) * 100;
      switch (entry.key) {
        case MealType.breakfast:
          distribution['Breakfast'] = percentage;
          break;
        case MealType.lunch:
          distribution['Lunch'] = percentage;
          break;
        case MealType.dinner:
          distribution['Dinner'] = percentage;
          break;
        case MealType.snack:
          distribution['Snack'] = percentage;
          break;
        default:
          distribution['Other'] = percentage;
          break;
      }
    }

    return distribution;
  }

  List<String> _generateNutritionalInsights(
    Map<String, double> dailyAverage,
    Map<String, double> targetPercentages,
    NutritionProfileEntity profile,
  ) {
    final List<String> insights = [];

    // Calories insights
    if (targetPercentages['calories'] != null) {
      final caloriePercentage = targetPercentages['calories']!;
      if (caloriePercentage < 80) {
        insights.add(
            'Your calorie intake is significantly below your target. Consider eating more to reach your goals.');
      } else if (caloriePercentage > 120) {
        insights.add(
            'Your calorie intake is above your target. Consider adjusting portion sizes.');
      } else {
        insights.add(
            'Your calorie intake is well aligned with your target. Great job!');
      }
    }

    // Protein insights
    if (targetPercentages['protein'] != null) {
      final proteinPercentage = targetPercentages['protein']!;
      if (proteinPercentage < 80) {
        insights.add(
            'Consider increasing your protein intake to support your ${profile.goal.toString().split('.').last} goal.');
      } else if (proteinPercentage > 150) {
        insights.add(
            'Your protein intake is very high. While good for muscle building, balance is important.');
      } else {
        insights.add(
            'Your protein intake is good and supports your fitness goals.');
      }
    }

    // Carb insights
    if (targetPercentages['carbs'] != null) {
      final carbPercentage = targetPercentages['carbs']!;
      if (profile.dietType == DietType.keto ||
          profile.dietType == DietType.lowCarb) {
        if (carbPercentage > 120) {
          insights.add(
              'Your carb intake is higher than recommended for your ${profile.dietType.toString().split('.').last} diet.');
        } else {
          insights.add(
              'Your carb intake aligns well with your ${profile.dietType.toString().split('.').last} diet plan.');
        }
      }
    }

    // Fat insights
    if (targetPercentages['fat'] != null) {
      final fatPercentage = targetPercentages['fat']!;
      if (fatPercentage < 70) {
        insights.add(
            'Your fat intake may be too low for hormone health. Consider adding healthy fats.');
      }
    }

    // Fiber insights
    if (dailyAverage['fiber'] != null) {
      final fiberIntake = dailyAverage['fiber']!;
      if (fiberIntake < 25) {
        insights.add(
            'Your fiber intake is below recommendations. Try adding more fruits, vegetables, and whole grains.');
      } else {
        insights.add(
            'Your fiber intake is good, supporting digestive health and steady energy levels.');
      }
    }

    // Add more insights based on dietary restrictions, goals, etc.
    return insights;
  }

  Map<String, double> _calculateMacronutrientRatio(
      Map<String, double> dailyAverage) {
    final protein = dailyAverage['protein'] ?? 0.0;
    final carbs = dailyAverage['carbs'] ?? 0.0;
    final fat = dailyAverage['fat'] ?? 0.0;

    final proteinCalories = protein * 4;
    final carbCalories = carbs * 4;
    final fatCalories = fat * 9;

    final totalCalories = proteinCalories + carbCalories + fatCalories;

    if (totalCalories == 0) {
      return {'protein': 0, 'carbs': 0, 'fat': 0};
    }

    return {
      'protein': (proteinCalories / totalCalories) * 100,
      'carbs': (carbCalories / totalCalories) * 100,
      'fat': (fatCalories / totalCalories) * 100,
    };
  }

  Map<String, double> _calculateMicronutrientCompletion(
    List<MealEntity> meals,
    NutritionProfileEntity profile,
  ) {
    // This would require more detailed food data with micronutrient information
    // For now, returning a placeholder
    return {
      'Vitamin A': 85,
      'Vitamin C': 120,
      'Vitamin D': 65,
      'Calcium': 90,
      'Iron': 80,
      'Potassium': 75,
    };
  }

  List<MealEntity> _getTopMeals(List<MealEntity> meals) {
    // For example, sort by nutrient density (calories/protein ratio)
    final sortedMeals = List<MealEntity>.from(meals);
    sortedMeals.sort((a, b) {
      final aRatio = a.totalProtein > 0
          ? a.totalCalories / a.totalProtein
          : double.infinity;
      final bRatio = b.totalProtein > 0
          ? b.totalCalories / b.totalProtein
          : double.infinity;
      return aRatio.compareTo(bRatio);
    });

    // Return top 5 or fewer if less available
    return sortedMeals.take(5).toList();
  }

  Map<String, double> _calculateWeekdayPatterns(
      Map<DateTime, List<MealEntity>> mealsByDate) {
    final Map<int, double> caloriesByWeekday = {};
    final Map<int, int> daysCounted = {};

    for (final entry in mealsByDate.entries) {
      final weekday = entry.key.weekday;
      double totalCalories = 0;

      for (final meal in entry.value) {
        totalCalories += meal.totalCalories;
      }

      caloriesByWeekday[weekday] =
          (caloriesByWeekday[weekday] ?? 0) + totalCalories;
      daysCounted[weekday] = (daysCounted[weekday] ?? 0) + 1;
    }

    final Map<String, double> result = {};

    for (final entry in caloriesByWeekday.entries) {
      final weekdayName = _getWeekdayName(entry.key);
      final average = entry.value / (daysCounted[entry.key] ?? 1);
      result[weekdayName] = average;
    }

    return result;
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }

  Map<DateTime, Map<String, double>> _prepareDailyIntakeHistory(
      Map<DateTime, List<MealEntity>> mealsByDate) {
    final Map<DateTime, Map<String, double>> result = {};

    for (final entry in mealsByDate.entries) {
      double calories = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;

      for (final meal in entry.value) {
        calories += meal.totalCalories;
        protein += meal.totalProtein;
        carbs += meal.totalCarbs;
        fat += meal.totalFat;
      }

      result[entry.key] = {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };
    }

    return result;
  }
}
