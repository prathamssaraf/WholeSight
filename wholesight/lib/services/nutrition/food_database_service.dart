import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whole_sight/core/utils/logger.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/services/firebase/firestore_service.dart';

abstract class FoodDatabaseService {
  Future<List<FoodEntity>> searchFoods({
    required String query,
    List<String>? categories,
    int limit = 20,
  });
  
  Future<FoodEntity?> getFoodById(String id);
  
  Future<FoodEntity?> getFoodByBarcode(String barcode);
  
  Future<List<FoodEntity>> getRecentFoods({
    required String userId,
    int limit = 10,
  });
  
  Future<List<FoodEntity>> getFavoriteFoods({
    required String userId,
    int limit = 20,
  });
  
  Future<String> addCustomFood({
    required FoodEntity food,
    required String userId,
  });
  
  Future<void> updateCustomFood({
    required FoodEntity food,
    required String userId,
  });
  
  Future<void> deleteCustomFood({
    required String foodId,
    required String userId,
  });
  
  Future<List<String>> getFoodCategories();
}

class FoodDatabaseServiceImpl implements FoodDatabaseService {
  final FirestoreService _firestoreService;
  
  FoodDatabaseServiceImpl({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreServiceImpl();
  
  @override
  Future<List<FoodEntity>> searchFoods({
    required String query,
    List<String>? categories,
    int limit = 20,
  }) async {
    try {
      // Normalize the query
      final normalizedQuery = query.toLowerCase().trim();
      
      // Create where conditions for the search
      final List<dynamic> whereConditions = [];
      
      // Add category filter if provided
      if (categories != null && categories.isNotEmpty) {
        whereConditions.add(['categories', 'array-contains-any', categories]);
      }
      
      // We'll use a compound query here, but for a production app,
      // you might want to implement a more sophisticated search solution,
      // such as Algolia or Firebase's own search extension
      final foods = await _firestoreService.queryCollection(
        collection: 'foods',
        queryBuilder: (CollectionReference collectionRef) {
          Query query = collectionRef;
          
          // Apply all where conditions
          for (final condition in whereConditions) {
            if (condition[1] == '==') {
              query = query.where(condition[0], isEqualTo: condition[2]);
            } else if (condition[1] == 'array-contains-any') {
              query = query.where(condition[0], arrayContainsAny: condition[2]);
            }
          }
          
          // Apply search (this is a simple implementation and might need improvement)
          // In a real app, consider using a dedicated search solution
          query = query.where('searchTags', arrayContains: normalizedQuery);
          
          // Order and limit
          return query.limit(limit).orderBy('name');
        },
      );
      
      // Convert Firestore docs to FoodEntity objects
      return foods.map((food) => _mapFirestoreDocToFoodEntity(food)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to search foods: $query', e, stackTrace);
      throw Exception('Failed to search foods: $e');
    }
  }
  
  @override
  Future<FoodEntity?> getFoodById(String id) async {
    try {
      final food = await _firestoreService.getDocument(
        collection: 'foods',
        documentId: id,
      );
      
      if (food == null) {
        return null;
      }
      
      return _mapFirestoreDocToFoodEntity(food);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get food by ID: $id', e, stackTrace);
      throw Exception('Failed to get food by ID: $e');
    }
  }
  
  @override
  Future<FoodEntity?> getFoodByBarcode(String barcode) async {
    try {
      final foods = await _firestoreService.getDocuments(
        collection: 'foods',
        whereConditions: [
          ['barcode', '==', barcode],
        ],
        limit: 1,
      );
      
      if (foods.isEmpty) {
        return null;
      }
      
      return _mapFirestoreDocToFoodEntity(foods.first);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get food by barcode: $barcode', e, stackTrace);
      throw Exception('Failed to get food by barcode: $e');
    }
  }
  
  @override
  Future<List<FoodEntity>> getRecentFoods({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final recentFoodRefs = await _firestoreService.getDocuments(
        collection: 'users/$userId/recentFoods',
        orderBy: 'timestamp',
        descending: true,
        limit: limit,
      );
      
      // Extract food IDs from recent foods collection
      final foodIds = recentFoodRefs.map((doc) => doc['foodId'] as String).toList();
      
      if (foodIds.isEmpty) {
        return [];
      }
      
      // Fetch the actual food documents
      final List<FoodEntity> recentFoods = [];
      
      for (final foodId in foodIds) {
        final food = await getFoodById(foodId);
        if (food != null) {
          recentFoods.add(food);
        }
      }
      
      return recentFoods;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get recent foods for user: $userId', e, stackTrace);
      throw Exception('Failed to get recent foods: $e');
    }
  }
  
  @override
  Future<List<FoodEntity>> getFavoriteFoods({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final favoriteFoodRefs = await _firestoreService.getDocuments(
        collection: 'users/$userId/favoriteFoods',
        orderBy: 'timestamp',
        descending: true,
        limit: limit,
      );
      
      // Extract food IDs from favorite foods collection
      final foodIds = favoriteFoodRefs.map((doc) => doc['foodId'] as String).toList();
      
      if (foodIds.isEmpty) {
        return [];
      }
      
      // Fetch the actual food documents
      final List<FoodEntity> favoriteFoods = [];
      
      for (final foodId in foodIds) {
        final food = await getFoodById(foodId);
        if (food != null) {
          favoriteFoods.add(food);
        }
      }
      
      return favoriteFoods;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get favorite foods for user: $userId', e, stackTrace);
      throw Exception('Failed to get favorite foods: $e');
    }
  }
  
  @override
  Future<String> addCustomFood({
    required FoodEntity food,
    required String userId,
  }) async {
    try {
      // Prepare the food data
      final foodData = _mapFoodEntityToFirestoreDoc(food, userId);
      
      // Generate search tags for the food
      foodData['searchTags'] = _generateSearchTags(food.name, food.description, food.brand);
      
      // Add the food to Firestore
      final foodId = await _firestoreService.addDocument(
        collection: 'foods',
        data: foodData,
      );
      
      return foodId;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add custom food for user: $userId', e, stackTrace);
      throw Exception('Failed to add custom food: $e');
    }
  }
  
  @override
  Future<void> updateCustomFood({
    required FoodEntity food,
    required String userId,
  }) async {
    try {
      // Verify that this food belongs to the user
      final existingFood = await getFoodById(food.id);
      
      if (existingFood == null) {
        throw Exception('Food not found');
      }
      
      if (existingFood.isUserCreated && existingFood.userId != userId) {
        throw Exception('Not authorized to update this food');
      }
      
      // Prepare the food data
      final foodData = _mapFoodEntityToFirestoreDoc(food, userId);
      
      // Generate search tags for the food
      foodData['searchTags'] = _generateSearchTags(food.name, food.description, food.brand);
      
      // Update the food in Firestore
      await _firestoreService.updateDocument(
        collection: 'foods',
        documentId: food.id,
        data: foodData,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update custom food: ${food.id} for user: $userId', e, stackTrace);
      throw Exception('Failed to update custom food: $e');
    }
  }
  
  @override
  Future<void> deleteCustomFood({
    required String foodId,
    required String userId,
  }) async {
    try {
      // Verify that this food belongs to the user
      final existingFood = await getFoodById(foodId);
      
      if (existingFood == null) {
        throw Exception('Food not found');
      }
      
      if (existingFood.isUserCreated && existingFood.userId != userId) {
        throw Exception('Not authorized to delete this food');
      }
      
      // Delete the food from Firestore
      await _firestoreService.deleteDocument(
        collection: 'foods',
        documentId: foodId,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete custom food: $foodId for user: $userId', e, stackTrace);
      throw Exception('Failed to delete custom food: $e');
    }
  }
  
  @override
  Future<List<String>> getFoodCategories() async {
    try {
      final categoriesDoc = await _firestoreService.getDocument(
        collection: 'metadata',
        documentId: 'foodCategories',
      );
      
      if (categoriesDoc == null || !categoriesDoc.containsKey('categories')) {
        return [];
      }
      
      return List<String>.from(categoriesDoc['categories']);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get food categories', e, stackTrace);
      throw Exception('Failed to get food categories: $e');
    }
  }
  
  // Helper Methods
  
  FoodEntity _mapFirestoreDocToFoodEntity(Map<String, dynamic> doc) {
    return FoodEntity(
      id: doc['id'] as String? ?? '',
      name: doc['name'] as String? ?? '',
      description: doc['description'] as String? ?? '',
      servingSize: _safeDoubleConvert(doc['servingSize']),
      servingUnit: doc['servingUnit'] as String? ?? '',
      calories: _safeDoubleConvert(doc['calories']),
      macronutrients: _safeMapConvert(doc['macronutrients']),
      micronutrients: _safeMapConvert(doc['micronutrients'] ?? {}),
      allergens: List<String>.from(doc['allergens'] ?? []),
      categories: List<String>.from(doc['categories'] ?? []),
      barcode: doc['barcode'] as String?,
      brand: doc['brand'] as String?,
      imageUrl: doc['imageUrl'] as String?,
      isVerified: doc['isVerified'] as bool? ?? false,
      isUserCreated: doc['isUserCreated'] as bool? ?? false,
      userId: doc['userId'] as String?,
      createdAt: _safeDateTimeConvert(doc['createdAt']),
      updatedAt: _safeDateTimeConvert(doc['updatedAt']),
    );
  }
  
  Map<String, dynamic> _mapFoodEntityToFirestoreDoc(FoodEntity food, String userId) {
    return {
      'name': food.name,
      'description': food.description,
      'servingSize': food.servingSize,
      'servingUnit': food.servingUnit,
      'calories': food.calories,
      'macronutrients': food.macronutrients,
      'micronutrients': food.micronutrients,
      'allergens': food.allergens,
      'categories': food.categories,
      'barcode': food.barcode,
      'brand': food.brand,
      'imageUrl': food.imageUrl,
      'isVerified': false, // User-created foods are not verified by default
      'isUserCreated': true,
      'userId': userId,
      'createdAt': food.createdAt,
      'updatedAt': DateTime.now(),
    };
  }
  
  List<String> _generateSearchTags(String name, String description, String? brand) {
    final Set<String> tags = {};
    
    // Add the whole name
    tags.add(name.toLowerCase());
    
    // Add individual words from the name
    tags.addAll(name.toLowerCase().split(' '));
    
    // Add the brand if available
    if (brand != null && brand.isNotEmpty) {
      tags.add(brand.toLowerCase());
      tags.addAll(brand.toLowerCase().split(' '));
    }
    
    // Add words from the description
    tags.addAll(description.toLowerCase().split(' '));
    
    // Filter out empty strings and very short words
    return tags.where((tag) => tag.length > 2).toList();
  }

  // Utility methods for safe type conversion
  double _safeDoubleConvert(dynamic value) {
    if (value == null) return 0.0;
    return (value is num) ? value.toDouble() : 0.0;
  }

  Map<String, double> _safeMapConvert(dynamic map) {
    if (map is Map) {
      return Map<String, double>.from(
        map.map(
          (key, value) => MapEntry(
            key.toString(), 
            (value is num) ? value.toDouble() : 0.0
          )
        )
      );
    }
    return {};
  }

  DateTime _safeDateTimeConvert(dynamic value) {
    if (value is DateTime) return value;
    return DateTime.now();
  }
}