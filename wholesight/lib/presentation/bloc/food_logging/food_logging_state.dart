// lib/presentation/bloc/food_logging/food_logging_state.dart
import 'package:equatable/equatable.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';

abstract class FoodLoggingState extends Equatable {
  const FoodLoggingState();

  @override
  List<Object?> get props => []; // Changed to Object? for consistency
}

// Basic states
class FoodLoggingInitial extends FoodLoggingState {}

class FoodLoggingLoading extends FoodLoggingState {}

class FoodLoggingError extends FoodLoggingState {
  final String message;

  const FoodLoggingError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Food search and logging states
class FoodSearchSuccess extends FoodLoggingState {
  final List<FoodEntity> foods;

  const FoodSearchSuccess({required this.foods});

  @override
  List<Object?> get props => [foods];
}

class FoodRecognitionSuccess extends FoodLoggingState {
  final List<FoodEntity> recognizedFoods;

  const FoodRecognitionSuccess({required this.recognizedFoods});

  @override
  List<Object?> get props => [recognizedFoods];
}

class FoodLoggingSuccess extends FoodLoggingState {
  final MealType mealType;
  final FoodEntity food;
  final double quantity;

  const FoodLoggingSuccess({
    required this.mealType,
    required this.food,
    required this.quantity,
  });

  @override
  List<Object?> get props => [mealType, food, quantity];
}

class CustomFoodAddedSuccess extends FoodLoggingState {
  final FoodEntity food;

  const CustomFoodAddedSuccess({required this.food});

  @override
  List<Object?> get props => [food];
}

// Meal tracking states
class MealsLoaded extends FoodLoggingState {
  final List<Meal> meals;
  final DateTime date;

  const MealsLoaded({required this.meals, required this.date});

  @override
  List<Object?> get props => [meals, date];
}

class MealAdded extends FoodLoggingState {
  final String mealId;
  final MealType type;

  const MealAdded({required this.mealId, required this.type});

  @override
  List<Object?> get props => [mealId, type];
}

class FoodItemAdded extends FoodLoggingState {
  final String mealId;
  final FoodItem foodItem;

  const FoodItemAdded({required this.mealId, required this.foodItem});

  @override
  List<Object?> get props => [mealId, foodItem];
}

// In food_logging_state.dart
class FoodItemDeleted extends FoodLoggingState {
  final String mealId;
  final String foodId;

  const FoodItemDeleted({
    required this.mealId,
    required this.foodId,
  });

  @override
  List<Object> get props => [mealId, foodId];
}

class MealDeleted extends FoodLoggingState {
  final String mealId;

  const MealDeleted({required this.mealId});

  @override
  List<Object> get props => [mealId];
}
