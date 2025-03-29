// lib/services/nutrition/meal_service.dart
import 'package:whole_sight/core/utils/logger.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/services/firebase/firestore_service.dart';
import 'package:whole_sight/services/auth/auth_service.dart'; // Add this import

class MealService {
  final FirestoreService _firestoreService;
  final String _mealsCollection = 'meals';

  MealService(this._firestoreService);

  // Add a new meal
  Future<String> addMeal(Meal meal) async {
    try {
      final mealId = await _firestoreService.addDocument(
        collection: _mealsCollection,
        data: meal.toJson(),
      );
      return mealId;
    } catch (e) {
      AppLogger.error('Failed to add meal', e);
      throw Exception('Failed to add meal: $e');
    }
  }

  // Get user's calorie target from their nutrition profile
  Future<int> getUserCalorieTarget(String userId) async {
    try {
      // Default target if nothing else works
      int defaultTarget = 2000;

      // Get the auth service
      final authService = getIt<AuthService>();

      // Try to get user profile
      final user = await authService.loadUserWithNutritionProfile(userId);

      // If no user or no nutrition profile, return default
      if (user == null || user.nutritionProfile == null) {
        print(
            'No user or nutrition profile found, using default calorie target');
        return defaultTarget;
      }

      // If user has a calorie target in their profile, use that
      if (user.nutritionProfile!.calorieTarget != null) {
        final calorieTarget = user.nutritionProfile!.calorieTarget!;

        // Convert to int regardless of whether it's int or double
        int target = calorieTarget.toInt();
        print('Using user\'s calorie target: $target');
        return target;
      }

      // Otherwise return default
      return defaultTarget;
    } catch (e) {
      print('Error getting user calorie target: $e');
      return 2000; // Default fallback
    }
  }

  // Get meals for a user on a specific date
  Future<List<Meal>> getMealsByUserAndDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final queryResults = await _firestoreService.getDocuments(
        collection: _mealsCollection,
        whereConditions: [
          ['userId', '==', userId],
          ['date', '>=', startOfDay.toIso8601String()],
          ['date', '<=', endOfDay.toIso8601String()],
        ],
        orderBy: 'time',
      );

      return queryResults.map((json) => Meal.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to get meals for user $userId on date $date', e);
      throw Exception('Failed to get meals: $e');
    }
  }

  // Update an existing meal
  Future<void> updateMeal(Meal meal) async {
    if (meal.id == null) {
      throw Exception('Cannot update a meal without an ID');
    }

    try {
      await _firestoreService.updateDocument(
        collection: _mealsCollection,
        documentId: meal.id!,
        data: meal.toJson(),
      );
    } catch (e) {
      AppLogger.error('Failed to update meal ${meal.id}', e);
      throw Exception('Failed to update meal: $e');
    }
  }

  Future<void> removeFoodFromMeal(String mealId, String foodId) async {
    try {
      // First get the current meal
      final mealData = await _firestoreService.getDocument(
        collection: _mealsCollection,
        documentId: mealId,
      );

      if (mealData == null) {
        throw Exception('Meal not found');
      }

      final meal = Meal.fromJson(mealData);
      final foods = meal.foods;

      // Since FoodItem doesn't have an id property, we need to find a different way to identify it
      // You might need to modify this based on how food items are uniquely identified in your app
      // For example, you could use an index-based approach if the foodId is actually the index
      int indexToRemove = -1;

      // Try to identify the food by position or some other property
      // This is a guess - you may need to adjust based on your actual implementation
      if (foodId.startsWith('food_')) {
        // If the ID is in format 'food_X' where X is an index
        try {
          final index = int.parse(foodId.split('_')[1]);
          if (index >= 0 && index < foods.length) {
            indexToRemove = index;
          }
        } catch (e) {
          // Parsing failed, continue with other approaches
        }
      }

      // If we couldn't find by index, try a name-based approach
      if (indexToRemove == -1) {
        for (int i = 0; i < foods.length; i++) {
          // This is a temporary solution - you may need a better way to uniquely identify foods
          // Perhaps comparing multiple properties like name and calories together
          if (foods[i].name == foodId) {
            indexToRemove = i;
            break;
          }
        }
      }

      if (indexToRemove == -1) {
        throw Exception('Food item not found in meal');
      }

      // Get the food item to calculate calories
      final foodToRemove = foods[indexToRemove];
      final foodCalories = foodToRemove.calories;

      // Remove the food item
      foods.removeAt(indexToRemove);

      // Calculate new total calories
      final newTotalCalories = meal.totalCalories - foodCalories;

      // Update the meal with the modified foods list and updated calories
      await _firestoreService.updateDocument(
        collection: _mealsCollection,
        documentId: mealId,
        data: {
          'foods': foods.map((food) => food.toJson()).toList(),
          'totalCalories': newTotalCalories,
        },
      );
    } catch (e) {
      AppLogger.error('Failed to remove food from meal $mealId', e);
      throw Exception('Failed to remove food from meal: $e');
    }
  }

  // Delete a meal
  Future<void> deleteMeal(String mealId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: _mealsCollection,
        documentId: mealId,
      );
    } catch (e) {
      AppLogger.error('Failed to delete meal $mealId', e);
      throw Exception('Failed to delete meal: $e');
    }
  }

  // Add food to a meal and update total calories
  Future<void> addFoodToMeal(String mealId, FoodItem foodItem) async {
    try {
      // First get the current meal
      final mealData = await _firestoreService.getDocument(
        collection: _mealsCollection,
        documentId: mealId,
      );

      if (mealData != null) {
        final meal = Meal.fromJson(mealData);

        // Add the new food and update calories
        final updatedFoods = [...meal.foods, foodItem];
        final newTotalCalories = meal.totalCalories + foodItem.calories;

        // Update the document
        await _firestoreService.updateDocument(
          collection: _mealsCollection,
          documentId: mealId,
          data: {
            'foods': updatedFoods.map((food) => food.toJson()).toList(),
            'totalCalories': newTotalCalories,
          },
        );
      } else {
        throw Exception('Meal not found');
      }
    } catch (e) {
      AppLogger.error('Failed to add food to meal $mealId', e);
      throw Exception('Failed to add food to meal: $e');
    }
  }
}
