import 'package:equatable/equatable.dart';

class FoodEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double servingSize; // in grams
  final String servingUnit; // e.g., 'g', 'ml', 'oz', 'cup'
  final double calories; // per serving
  final Map<String, double> macronutrients; // protein, carbs, fats in grams
  final Map<String, double> micronutrients; // vitamins, minerals in various units
  final List<String> allergens;
  final List<String> categories; // e.g., 'fruits', 'vegetables', 'dairy'
  final String? barcode;
  final String? brand;
  final String? imageUrl;
  final bool isVerified; // Whether the food data has been verified
  final bool isUserCreated; // Whether this food was created by a user
  final String? userId; // If user created, the ID of the user who created it
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  const FoodEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.servingSize,
    required this.servingUnit,
    required this.calories,
    required this.macronutrients,
    required this.micronutrients,
    required this.allergens,
    required this.categories,
    this.barcode,
    this.brand,
    this.imageUrl,
    required this.isVerified,
    required this.isUserCreated,
    this.userId,
    required this.createdAt,
    this.updatedAt,
  });
  
  FoodEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? servingSize,
    String? servingUnit,
    double? calories,
    Map<String, double>? macronutrients,
    Map<String, double>? micronutrients,
    List<String>? allergens,
    List<String>? categories,
    String? barcode,
    String? brand,
    String? imageUrl,
    bool? isVerified,
    bool? isUserCreated,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      calories: calories ?? this.calories,
      macronutrients: macronutrients ?? this.macronutrients,
      micronutrients: micronutrients ?? this.micronutrients,
      allergens: allergens ?? this.allergens,
      categories: categories ?? this.categories,
      barcode: barcode ?? this.barcode,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
      isUserCreated: isUserCreated ?? this.isUserCreated,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // Get protein content in grams
  double get protein => macronutrients['protein'] ?? 0.0;
  
  // Get carbs content in grams
  double get carbs => macronutrients['carbs'] ?? 0.0;
  
  // Get fat content in grams
  double get fat => macronutrients['fat'] ?? 0.0;
  
  // Get fiber content in grams
  double get fiber => macronutrients['fiber'] ?? 0.0;
  
  // Get sugar content in grams
  double get sugar => macronutrients['sugar'] ?? 0.0;
  
  // Calculate calories from macronutrients
  double get calculatedCalories {
    return (protein * 4) + (carbs * 4) + (fat * 9);
  }
  
  @override
  List<Object?> get props => [
    id,
    name,
    description,
    servingSize,
    servingUnit,
    calories,
    macronutrients,
    micronutrients,
    allergens,
    categories,
    barcode,
    brand,
    imageUrl,
    isVerified,
    isUserCreated,
    userId,
    createdAt,
    updatedAt,
  ];
}