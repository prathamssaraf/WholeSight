import 'package:equatable/equatable.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';

enum MealType { breakfast, lunch, dinner, snack, other }

class MealItemEntity extends Equatable {
  final FoodEntity food;
  final double quantity; // Number of servings
  final double? weight; // Weight in grams (optional)
  final String? notes;
  
  const MealItemEntity({
    required this.food,
    required this.quantity,
    this.weight,
    this.notes,
  });
  
  // Calculate total calories for this meal item
  double get totalCalories => food.calories * quantity;
  
  // Calculate total protein for this meal item
  double get totalProtein => food.protein * quantity;
  
  // Calculate total carbs for this meal item
  double get totalCarbs => food.carbs * quantity;
  
  // Calculate total fat for this meal item
  double get totalFat => food.fat * quantity;
  
  // Calculate total fiber for this meal item
  double get totalFiber => food.fiber * quantity;
  
  // Calculate total sugar for this meal item
  double get totalSugar => food.sugar * quantity;
  
  @override
  List<Object?> get props => [food, quantity, weight, notes];
}

class MealEntity extends Equatable {
  final String id;
  final String userId;
  final String name;
  final MealType type;
  final DateTime timestamp;
  final List<MealItemEntity> items;
  final String? notes;
  final String? imageUrl;
  final bool isFavorite;
  final bool isTemplate;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const MealEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.timestamp,
    required this.items,
    this.notes,
    this.imageUrl,
    this.isFavorite = false,
    this.isTemplate = false,
    this.locationName,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
  });
  
  MealEntity copyWith({
    String? id,
    String? userId,
    String? name,
    MealType? type,
    DateTime? timestamp,
    List<MealItemEntity>? items,
    String? notes,
    String? imageUrl,
    bool? isFavorite,
    bool? isTemplate,
    String? locationName,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MealEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      items: items ?? this.items,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isTemplate: isTemplate ?? this.isTemplate,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Calculate total calories for the meal
  double get totalCalories {
    return items.fold(0, (sum, item) => sum + item.totalCalories);
  }
  
  // Calculate total protein for the meal
  double get totalProtein {
    return items.fold(0, (sum, item) => sum + item.totalProtein);
  }
  
  // Calculate total carbs for the meal
  double get totalCarbs {
    return items.fold(0, (sum, item) => sum + item.totalCarbs);
  }
  
  // Calculate total fat for the meal
  double get totalFat {
    return items.fold(0, (sum, item) => sum + item.totalFat);
  }
  
  // Calculate total fiber for the meal
  double get totalFiber {
    return items.fold(0, (sum, item) => sum + item.totalFiber);
  }
  
  // Calculate total sugar for the meal
  double get totalSugar {
    return items.fold(0, (sum, item) => sum + item.totalSugar);
  }
  
  // Calculate macronutrient distribution (percentages)
  Map<String, double> get macroDistribution {
    final totalProteinCalories = totalProtein * 4;
    final totalCarbsCalories = totalCarbs * 4;
    final totalFatCalories = totalFat * 9;
    final totalCals = totalProteinCalories + totalCarbsCalories + totalFatCalories;
    
    if (totalCals == 0) {
      return {
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      };
    }
    
    return {
      'protein': (totalProteinCalories / totalCals) * 100,
      'carbs': (totalCarbsCalories / totalCals) * 100,
      'fat': (totalFatCalories / totalCals) * 100,
    };
  }
  
  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    type,
    timestamp,
    items,
    notes,
    imageUrl,
    isFavorite,
    isTemplate,
    locationName,
    latitude,
    longitude,
    createdAt,
    updatedAt,
  ];
}