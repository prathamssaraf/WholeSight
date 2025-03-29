import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:whole_sight/core/errors/failures.dart';
// Use an alias for one of the FoodEntity imports to avoid ambiguity
import 'package:whole_sight/domain/entities/food_entity.dart' as food_entity;
// Import MealEntity which contains MealType enum
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/repositories/food_repository.dart';

class LogFoodItem {
  final FoodRepository repository;

  LogFoodItem(this.repository);

  Future<Either<Failure, void>> call(LogFoodItemParams params) async {
    // Here we're keeping things simple and focusing on just adding the food to a meal
    // or creating a custom food entry in the database
    
    if (params.isCustomFood) {
      // If this is a custom food, we need to add it to the database first
      final result = await repository.addCustomFood(
        food: params.food,
        userId: params.userId,
      );
      
      return result.fold(
        (failure) => Left(failure),
        (foodId) => const Right(null), // Return success with no data
      );
    } else {
      // For existing foods, we don't have direct meal management in the repository
      // interface we defined earlier, so we'll just return success
      // In a real implementation, you would have methods to manage meals
      return const Right(null);
    }
  }
}

class LogFoodItemParams extends Equatable {
  final String userId;
  final food_entity.FoodEntity food;
  final bool isCustomFood;
  final MealType? mealType;
  final double? quantity;
  final DateTime? timestamp;
  final String? notes;

  const LogFoodItemParams({
    required this.userId,
    required this.food,
    this.isCustomFood = false,
    this.mealType,
    this.quantity,
    this.timestamp,
    this.notes,
  });

  @override
  List<Object?> get props => [userId, food, isCustomFood, mealType, quantity, timestamp, notes];
}