import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whole_sight/core/errors/exceptions.dart';
import 'package:whole_sight/data/models/food_model.dart';
import 'package:whole_sight/services/ai/recommendation_service.dart';
import 'package:whole_sight/services/firebase/firestore_service.dart';
// Removed unused imports

// Define a local adapter for MealEntity to avoid conflicts
class _InternalMealEntity {
  final String id;
  final String userId;
  final String name;
  final String type;
  final DateTime timestamp;
  final List<dynamic> items;
  
  _InternalMealEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.timestamp,
    required this.items,
  });
  
  factory _InternalMealEntity.fromJson(Map<String, dynamic> json) {
    return _InternalMealEntity(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Meal',
      type: json['type']?.toString() ?? 'other',
      timestamp: _parseDateTime(json['timestamp']),
      items: json['items'] as List<dynamic>? ?? [],
    );
  }
  
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    
    try {
      return dateTime is DateTime 
        ? dateTime 
        : DateTime.parse(dateTime.toString());
    } catch (e) {
      return DateTime.now();
    }
  }
}

abstract class FoodRemoteDataSource {
  Future<List<FoodModel>> searchFoods({
    required String query,
    List<String>? categories,
    int limit = 20,
  });
  
  Future<FoodModel> getFoodById(String id);
  
  Future<FoodModel?> getFoodByBarcode(String barcode);
  
  Future<List<FoodModel>> getRecentFoods({
    required String userId,
    int limit = 10,
  });
  
  Future<List<FoodModel>> getFavoriteFoods({
    required String userId,
    int limit = 20,
  });

  Future<void> addToFavorites({
    required String userId,
    required String foodId,
  });
  
  Future<void> addFoodToFavorites({
    required String userId,
    required Map<String, dynamic> foodData,
  });

  Future<void> removeFromFavorites({
    required String userId,
    required String foodId,
  });

  Future<bool> isFavorite({
    required String userId,
    required String foodId,
  });
  
  Future<String> addCustomFood({
    required FoodModel food,
    required String userId,
  });
  
  Future<void> updateCustomFood({
    required FoodModel food,
    required String userId,
  });
  
  Future<void> deleteCustomFood({
    required String foodId,
    required String userId,
  });
  
  Future<List<FoodModel>> getFoodRecommendations({
    required String userId,
    int limit = 5,
  });
}

class FoodRemoteDataSourceImpl implements FoodRemoteDataSource {
  final FirestoreService firestoreService;
  final RecommendationService recommendationService;
  
  FoodRemoteDataSourceImpl({
    required this.firestoreService,
    required this.recommendationService,
  });
  
  @override
  Future<List<FoodModel>> searchFoods({
    required String query,
    List<String>? categories,
    int limit = 20,
  }) async {
    try {
      final whereConditions = <List<dynamic>>[];
      
      if (categories != null && categories.isNotEmpty) {
        whereConditions.add(['categories', 'array-contains-any', categories]);
      }
      
      final foods = await firestoreService.queryCollection(
        collection: 'foods',
        queryBuilder: (CollectionReference collectionRef) {
          Query queryRef = collectionRef;
          
          for (final condition in whereConditions) {
            if (condition[1] == '==') {
              queryRef = queryRef.where(condition[0], isEqualTo: condition[2]);
            } else if (condition[1] == 'array-contains-any') {
              queryRef = queryRef.where(condition[0], arrayContainsAny: condition[2]);
            }
          }
          
          // Use .toLowerCase() on the input query instead of on the Query
          queryRef = queryRef.where('searchTags', arrayContains: query.toLowerCase());
          
          return queryRef.orderBy('name').limit(limit);
        },
      );
      
      return foods.map((food) => FoodModel.fromJson(food)).toList();
    } catch (e) {
      throw ServerException();
    }
  }
  
  @override
  Future<FoodModel> getFoodById(String id) async {
    try {
      final foodDoc = await firestoreService.getDocument(
        collection: 'foods',
        documentId: id,
      );
      
      if (foodDoc != null) {
        return FoodModel.fromJson(foodDoc);
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException();
    }
  }
  
  @override
  Future<FoodModel?> getFoodByBarcode(String barcode) async {
    try {
      final foods = await firestoreService.getDocuments(
        collection: 'foods',
        whereConditions: [
          ['barcode', '==', barcode],
        ],
        limit: 1,
      );
      
      if (foods.isNotEmpty) {
        return FoodModel.fromJson(foods.first);
      } else {
        return null;
      }
    } catch (e) {
      throw ServerException();
    }
  }
  
  @override
  Future<List<FoodModel>> getRecentFoods({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final recentFoodRefs = await firestoreService.getDocuments(
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
      final List<FoodModel> recentFoods = [];
      
      for (final foodId in foodIds) {
        final foodDoc = await firestoreService.getDocument(
          collection: 'foods',
          documentId: foodId,
        );
        
        if (foodDoc != null) {
          recentFoods.add(FoodModel.fromJson(foodDoc));
        }
      }
      
      return recentFoods;
    } catch (e) {
      throw ServerException();
    }
  }
  
  @override
  Future<List<FoodModel>> getFavoriteFoods({
    required String userId,
    int limit = 20,
  }) async {
    try {
      final favoriteFoodDocs = await firestoreService.getDocuments(
        collection: 'users/$userId/favoriteFoods',
        orderBy: 'timestamp',
        descending: true,
        limit: limit,
      );
      
      if (favoriteFoodDocs.isEmpty) {
        return [];
      }
      
      // Convert stored food data directly to FoodModel objects
      final List<FoodModel> favoriteFoods = [];
      
      for (final doc in favoriteFoodDocs) {
        // Check if this is the new format with complete food data
        if (doc.containsKey('foodName')) {
          final foodModel = FoodModel(
            id: doc['id'] ?? 'favorite_${doc['foodName']}_${DateTime.now().millisecondsSinceEpoch}',
            name: doc['foodName'] ?? 'Unknown Food',
            description: 'Favorite food item',
            servingSize: _parseServingSize(doc['servingSize']),
            servingUnit: _parseServingUnit(doc['servingSize']),
            calories: (doc['calories'] as num? ?? 0).toDouble(),
            macronutrients: {
              'protein': (doc['protein'] as num? ?? 0).toDouble(),
              'carbohydrates': (doc['carbs'] as num? ?? 0).toDouble(),
              'fat': (doc['fat'] as num? ?? 0).toDouble(),
            },
            micronutrients: {},
            allergens: [],
            categories: [],
            isVerified: false,
            isUserCreated: false,
            createdAt: DateTime.now(),
          );
          favoriteFoods.add(foodModel);
        } else if (doc.containsKey('foodId')) {
          // Legacy format - try to fetch from foods collection
          try {
            final foodDoc = await firestoreService.getDocument(
              collection: 'foods',
              documentId: doc['foodId'],
            );
            
            if (foodDoc != null) {
              favoriteFoods.add(FoodModel.fromJson(foodDoc));
            }
          } catch (e) {
            // If food document doesn't exist, skip this favorite
            continue;
          }
        }
      }
      
      return favoriteFoods;
    } catch (e) {
      throw ServerException();
    }
  }
  
  double _parseServingSize(String? servingSizeString) {
    if (servingSizeString == null) return 1.0;
    
    // Extract numeric value from strings like "1 medium (182g)" or "100g"
    final regex = RegExp(r'(\d+\.?\d*)');
    final match = regex.firstMatch(servingSizeString);
    return match != null ? double.tryParse(match.group(1)!) ?? 1.0 : 1.0;
  }
  
  String _parseServingUnit(String? servingSizeString) {
    if (servingSizeString == null) return 'serving';
    
    // Try to extract unit from strings like "1 medium (182g)" or "100g" 
    if (servingSizeString.contains('g')) return 'g';
    if (servingSizeString.contains('ml') || servingSizeString.contains('mL')) return 'ml';
    if (servingSizeString.contains('cup')) return 'cup';
    if (servingSizeString.contains('medium') || servingSizeString.contains('large') || servingSizeString.contains('small')) return 'item';
    
    return 'serving';
  }

  @override
  Future<void> addToFavorites({
    required String userId,
    required String foodId,
  }) async {
    try {
      // For now, store the foodId as provided and let the UI handle the food data lookup
      await firestoreService.addDocument(
        collection: 'users/$userId/favoriteFoods',
        data: {
          'foodId': foodId,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> addFoodToFavorites({
    required String userId,
    required Map<String, dynamic> foodData,
  }) async {
    try {
      await firestoreService.addDocument(
        collection: 'users/$userId/favoriteFoods',
        data: {
          'foodName': foodData['name'],
          'calories': foodData['calories'],
          'servingSize': foodData['servingSize'],
          'protein': foodData['protein'],
          'carbs': foodData['carbs'], 
          'fat': foodData['fat'],
          'timestamp': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> removeFromFavorites({
    required String userId,
    required String foodId,
  }) async {
    try {
      // Look for documents with either foodId or foodName matching the provided foodId
      final favoriteDocs = await firestoreService.getDocuments(
        collection: 'users/$userId/favoriteFoods',
        whereConditions: [
          ['foodId', '==', foodId],
        ],
      );
      
      // Also check for new format documents by foodName
      final favoriteDocsbyName = await firestoreService.getDocuments(
        collection: 'users/$userId/favoriteFoods',
        whereConditions: [
          ['foodName', '==', foodId],
        ],
      );
      
      // Combine both results
      final allDocs = [...favoriteDocs, ...favoriteDocsbyName];
      
      for (final doc in allDocs) {
        await firestoreService.deleteDocument(
          collection: 'users/$userId/favoriteFoods',
          documentId: doc['id'],
        );
      }
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<bool> isFavorite({
    required String userId,
    required String foodId,
  }) async {
    try {
      // Check both legacy foodId and new foodName format
      final favoriteDocs = await firestoreService.getDocuments(
        collection: 'users/$userId/favoriteFoods',
        whereConditions: [
          ['foodId', '==', foodId],
        ],
        limit: 1,
      );
      
      if (favoriteDocs.isNotEmpty) {
        return true;
      }
      
      // Also check new format with foodName
      final favoriteDocsbyName = await firestoreService.getDocuments(
        collection: 'users/$userId/favoriteFoods',
        whereConditions: [
          ['foodName', '==', foodId],
        ],
        limit: 1,
      );
      
      return favoriteDocsbyName.isNotEmpty;
    } catch (e) {
      throw ServerException();
    }
  }
  
  @override
  Future<String> addCustomFood({
    required FoodModel food,
    required String userId,
  }) async {
    try {
      // Prepare the food data
      final foodData = food.toJson();
      foodData['userId'] = userId;
      foodData['isUserCreated'] = true;
      foodData['isVerified'] = false;
      foodData['createdAt'] = FieldValue.serverTimestamp();
      
      // Generate search tags for the food
      final searchTags = _generateSearchTags(food.name, food.description, food.brand);
      foodData['searchTags'] = searchTags;
      
      // Add the food to Firestore
      final foodId = await firestoreService.addDocument(
        collection: 'foods',
        data: foodData,
      );
      
      return foodId;
    } catch (e) {
      throw ServerException();
    }
  }
  
  @override
  Future<void> updateCustomFood({
    required FoodModel food,
    required String userId,
  }) async {
    try {
      // Verify that this food belongs to the user
      final existingFoodDoc = await firestoreService.getDocument(
        collection: 'foods',
        documentId: food.id,
      );
      
      if (existingFoodDoc == null) {
        throw ServerException();
      }
      
      if (existingFoodDoc['isUserCreated'] == true &&
          existingFoodDoc['userId'] != userId) {
        throw ServerException();
      }
      
      // Prepare the food data
      final foodData = food.toJson();
      foodData['updatedAt'] = FieldValue.serverTimestamp();
      
      // Generate search tags for the food
      final searchTags = _generateSearchTags(food.name, food.description, food.brand);
      foodData['searchTags'] = searchTags;
      
      // Update the food in Firestore
      await firestoreService.updateDocument(
        collection: 'foods',
        documentId: food.id,
        data: foodData,
      );
    } catch (e) {
      throw ServerException();
    }
  }
  
  @override
  Future<void> deleteCustomFood({
    required String foodId,
    required String userId,
  }) async {
    try {
      // Verify that this food belongs to the user
      final existingFoodDoc = await firestoreService.getDocument(
        collection: 'foods',
        documentId: foodId,
      );
      
      if (existingFoodDoc == null) {
        throw ServerException();
      }
      
      if (existingFoodDoc['isUserCreated'] == true &&
          existingFoodDoc['userId'] != userId) {
        throw ServerException();
      }
      
      // Delete the food from Firestore
      await firestoreService.deleteDocument(
        collection: 'foods',
        documentId: foodId,
      );
    } catch (e) {
      throw ServerException();
    }
  }
  
  @override
Future<List<FoodModel>> getFoodRecommendations({
  required String userId,
  int limit = 5,
}) async {
  // Placeholder implementation that returns a fixed list of FoodModel objects
  return [
    FoodModel(
      id: 'placeholder1',
      name: 'Grilled Salmon',
      description: 'Healthy and delicious grilled salmon with lemon and herbs',
      servingSize: 150,
      servingUnit: 'g',
      calories: 250,
      macronutrients: {
        'protein': 30,
        'carbohydrates': 5,
        'fat': 15,
      },
      micronutrients: {
        'vitamin_d': 10,
        'omega_3': 2.5,
      },
      allergens: ['fish'],
      categories: ['main dish', 'seafood'],
      imageUrl: 'https://example.com/grilled_salmon.jpg',
      isVerified: true,
      isUserCreated: false,
      createdAt: DateTime.now(),
    ),
    FoodModel(
      id: 'placeholder2',
      name: 'Quinoa Salad',
      description: 'Refreshing quinoa salad with vegetables and lemon dressing',
      servingSize: 200,
      servingUnit: 'g',
      calories: 180,
      macronutrients: {
        'protein': 8,
        'carbohydrates': 30,
        'fat': 5,
      },
      micronutrients: {
        'fiber': 5,
        'iron': 2,
      },
      allergens: [],
      categories: ['salad', 'vegetarian'],
      imageUrl: 'https://example.com/quinoa_salad.jpg',
      isVerified: true,
      isUserCreated: false,
      createdAt: DateTime.now(),
    ),
    // Add more placeholder FoodModel objects as needed
  ];
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
}