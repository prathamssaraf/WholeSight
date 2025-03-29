// lib/presentation/bloc/food_logging/food_logging_event.dart
import 'package:equatable/equatable.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_state.dart';

abstract class FoodLoggingEvent extends Equatable {
  const FoodLoggingEvent();

  @override
  List<Object?> get props =>
      []; // Change this to match your original FoodLoggingEvent
}

// Food search and logging events
class SearchFoodsEvent extends FoodLoggingEvent {
  final String query;
  final List<String>? categories;

  const SearchFoodsEvent({
    required this.query,
    this.categories,
  });

  @override
  List<Object?> get props => [query, categories];
}

class RecognizeFoodFromImageEvent extends FoodLoggingEvent {
  final List<int> imageBytes;

  const RecognizeFoodFromImageEvent({
    required this.imageBytes,
  });

  @override
  List<Object?> get props => [imageBytes];
}

class LogFoodEvent extends FoodLoggingEvent {
  final String userId;
  final FoodEntity food;
  final MealType mealType;
  final double quantity;
  final String? notes;

  const LogFoodEvent({
    required this.userId,
    required this.food,
    required this.mealType,
    required this.quantity,
    this.notes,
  });

  @override
  List<Object?> get props => [userId, food, mealType, quantity, notes];
}

class AddCustomFoodEvent extends FoodLoggingEvent {
  final String userId;
  final FoodEntity food;

  const AddCustomFoodEvent({
    required this.userId,
    required this.food,
  });

  @override
  List<Object?> get props => [userId, food];
}

// Meal tracking events
class LoadMealsForDateEvent extends FoodLoggingEvent {
  final DateTime date;
  final String userId;

  const LoadMealsForDateEvent({required this.date, required this.userId});

  @override
  List<Object?> get props => [date, userId];
}

class CreateMealEvent extends FoodLoggingEvent {
  final MealType mealType;
  final String userId;
  final DateTime date;
  final String time;

  const CreateMealEvent({
    required this.mealType,
    required this.userId,
    required this.date,
    required this.time,
  });

  @override
  List<Object?> get props => [mealType, userId, date, time];
}

class AddFoodToMealEvent extends FoodLoggingEvent {
  final String mealId;
  final FoodItem foodItem;
  final String userId; // Added
  final DateTime date; // Added

  AddFoodToMealEvent({
    required this.mealId,
    required this.foodItem,
    required this.userId,
    required this.date,
  });

  @override
  List<Object?> get props => [mealId, foodItem, userId, date];
}

// Event to delete a food item from a meal
class DeleteFoodFromMealEvent extends FoodLoggingEvent {
  final String mealId;
  final String foodId;
  final String userId;
  final DateTime date;

  DeleteFoodFromMealEvent({
    required this.mealId,
    required this.foodId,
    required this.userId,
    required this.date,
  });

  @override
  List<Object> get props => [mealId, foodId, userId, date];
}

// Event to delete an entire meal
class DeleteMealEvent extends FoodLoggingEvent {
  final String mealId;
  final String userId;
  final DateTime date;

  DeleteMealEvent({
    required this.mealId,
    required this.userId,
    required this.date,
  });

  @override
  List<Object> get props => [mealId, userId, date];
}
