// lib/data/models/meal.dart
import 'package:whole_sight/domain/entities/meal_entity.dart';

class FoodItem {
  final String name;
  final String quantity;
  final int calories;
  final double? protein;
  final double? carbs;
  final double? fat;

  FoodItem({
    required this.name,
    required this.quantity,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? '',
      calories: json['calories'] ?? 0,
      protein: json['protein'],
      carbs: json['carbs'],
      fat: json['fat'],
    );
  }
}

class Meal {
  final String? id; // Optional for new unsaved meals
  final MealType type;
  final String time;
  final List<FoodItem> foods;
  final int totalCalories;
  final String userId;
  final DateTime date;

  Meal({
    this.id,
    required this.type,
    required this.time,
    required this.foods,
    required this.totalCalories,
    required this.userId,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.index,
      'time': time,
      'foods': foods.map((food) => food.toJson()).toList(),
      'totalCalories': totalCalories,
      'userId': userId,
      'date': date.toIso8601String(),
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    List<FoodItem> foodsList = [];
    if (json['foods'] != null) {
      foodsList = List<FoodItem>.from(
          (json['foods'] as List).map((food) => FoodItem.fromJson(food)));
    }

    return Meal(
      id: json['id'],
      type: MealType.values[json['type'] ?? 0],
      time: json['time'] ?? '',
      foods: foodsList,
      totalCalories: json['totalCalories'] ?? 0,
      userId: json['userId'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }

  // Create a copy of this Meal with modified fields
  Meal copyWith({
    String? id,
    MealType? type,
    String? time,
    List<FoodItem>? foods,
    int? totalCalories,
    String? userId,
    DateTime? date,
  }) {
    return Meal(
      id: id ?? this.id,
      type: type ?? this.type,
      time: time ?? this.time,
      foods: foods ?? this.foods,
      totalCalories: totalCalories ?? this.totalCalories,
      userId: userId ?? this.userId,
      date: date ?? this.date,
    );
  }
}
