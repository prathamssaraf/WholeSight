import 'package:dartz/dartz.dart';
import 'package:whole_sight/core/errors/failures.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/data/models/meal.dart';

abstract class FoodRepository {
  // Existing methods
  Future<Either<Failure, List<FoodEntity>>> searchFoods({
    required String query,
    List<String>? categories,
    int limit = 20,
  });

  Future<Either<Failure, FoodEntity>> getFoodById(String id);

  Future<Either<Failure, FoodEntity?>> getFoodByBarcode(String barcode);

  Future<Either<Failure, List<FoodEntity>>> getRecentFoods({
    required String userId,
    int limit = 10,
  });

  Future<Either<Failure, List<FoodEntity>>> getFavoriteFoods({
    required String userId,
    int limit = 20,
  });

  Future<Either<Failure, String>> addCustomFood({
    required FoodEntity food,
    required String userId,
  });

  Future<Either<Failure, void>> updateCustomFood({
    required FoodEntity food,
    required String userId,
  });

  Future<Either<Failure, void>> deleteCustomFood({
    required String foodId,
    required String userId,
  });

  Future<Either<Failure, List<FoodEntity>>> getFoodRecommendations({
    required String userId,
    int limit = 5,
  });

  // New meal tracking methods
  Future<Either<Failure, List<Meal>>> getMealsByUserAndDate(
      String userId, DateTime date);

  Future<Either<Failure, String>> addMeal(Meal meal);

  Future<Either<Failure, void>> updateMeal(Meal meal);

  Future<Either<Failure, void>> deleteMeal(String mealId);

  Future<Either<Failure, void>> addFoodToMeal(String mealId, FoodItem foodItem);

  Future<Either<Failure, String>> createEmptyMeal(
      MealType type, String userId, DateTime date, String time);

  // Add this new method for removing food from a meal
  Future<Either<Failure, void>> removeFoodFromMeal(
      String mealId, String foodId);

  // Add this new method for updating food in a meal
  Future<Either<Failure, void>> updateFoodInMeal(
      String mealId, String foodId, FoodItem updatedFoodItem);
}
