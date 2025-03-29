import 'package:whole_sight/domain/entities/food_entity.dart';

class FoodModel {
  final String id;
  final String name;
  final String description;
  final double servingSize;
  final String servingUnit;
  final double calories;
  final Map<String, double> macronutrients;
  final Map<String, double> micronutrients;
  final List<String> allergens;
  final List<String> categories;
  final String? barcode;
  final String? brand;
  final String? imageUrl;
  final bool isVerified;
  final bool isUserCreated;
  final String? userId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  FoodModel({
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

  // Conversion method from FoodEntity to FoodModel
  factory FoodModel.fromEntity(FoodEntity entity) {
    return FoodModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      servingSize: entity.servingSize,
      servingUnit: entity.servingUnit,
      calories: entity.calories,
      macronutrients: entity.macronutrients,
      micronutrients: entity.micronutrients,
      allergens: entity.allergens,
      categories: entity.categories,
      barcode: entity.barcode,
      brand: entity.brand,
      imageUrl: entity.imageUrl,
      isVerified: entity.isVerified,
      isUserCreated: entity.isUserCreated,
      userId: entity.userId,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  // Optional: Conversion method from FoodModel to FoodEntity
  FoodEntity toEntity() {
    return FoodEntity(
      id: id,
      name: name,
      description: description,
      servingSize: servingSize,
      servingUnit: servingUnit,
      calories: calories,
      macronutrients: macronutrients,
      micronutrients: micronutrients,
      allergens: allergens,
      categories: categories,
      barcode: barcode,
      brand: brand,
      imageUrl: imageUrl,
      isVerified: isVerified,
      isUserCreated: isUserCreated,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // JSON Conversion Methods
  factory FoodModel.fromJson(Map<String, dynamic> json) {
    return FoodModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      servingSize: (json['servingSize'] ?? 0.0).toDouble(),
      servingUnit: json['servingUnit'] ?? '',
      calories: (json['calories'] ?? 0.0).toDouble(),
      // Map all other properties similarly
      macronutrients: (json['macronutrients'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value ?? 0.0).toDouble())
      ) ?? {},
      micronutrients: (json['micronutrients'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value ?? 0.0).toDouble())
      ) ?? {},
      allergens: List<String>.from(json['allergens'] ?? []),
      categories: List<String>.from(json['categories'] ?? []),
      barcode: json['barcode'],
      brand: json['brand'],
      imageUrl: json['imageUrl'],
      isVerified: json['isVerified'] ?? false,
      isUserCreated: json['isUserCreated'] ?? false,
      userId: json['userId'],
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  // Helper method to parse different date formats
  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    // If it's already a DateTime, return it
    if (dateValue is DateTime) return dateValue;
    
    // If it's a String, try parsing it
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return null;
      }
    }
    
    // If it's a map or has a toDate method (like Firestore Timestamp)
    if (dateValue is Map) {
      // Check for common Timestamp-like structures
      if (dateValue.containsKey('seconds') && dateValue.containsKey('nanoseconds')) {
        // Assuming a map with seconds and nanoseconds
        return DateTime.fromMillisecondsSinceEpoch(
          (dateValue['seconds'] * 1000 + dateValue['nanoseconds'] ~/ 1000000)
        );
      }
    }
    
    // If the object has a toDate method (for Firebase Timestamp)
    if (dateValue.toString().contains('Timestamp')) {
      try {
        return dateValue.toDate();
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'calories': calories,
      'macronutrients': macronutrients,
      'micronutrients': micronutrients,
      'allergens': allergens,
      'categories': categories,
      'barcode': barcode,
      'brand': brand,
      'imageUrl': imageUrl,
      'isVerified': isVerified,
      'isUserCreated': isUserCreated,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}