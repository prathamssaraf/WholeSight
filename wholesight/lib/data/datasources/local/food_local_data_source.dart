import 'dart:convert';

import 'package:whole_sight/core/errors/exceptions.dart';
import 'package:whole_sight/core/services/local_storage_service.dart';
import 'package:whole_sight/data/models/food_model.dart';

abstract class FoodLocalDataSource {
  /// Gets cached food by ID.
  /// Throws [CacheException] if no cached data is present.
  Future<FoodModel> getCachedFoodById(String id);
  
  /// Gets cached food by barcode.
  /// Returns null if no food is found.
  /// Throws [CacheException] if no cached data is present.
  Future<FoodModel?> getCachedFoodByBarcode(String barcode);
  
  /// Gets cached recent foods for a user.
  /// Throws [CacheException] if no cached data is present.
  Future<List<FoodModel>> getCachedRecentFoods({
    required String userId,
    int limit = 10,
  });
  
  /// Gets cached favorite foods for a user.
  /// Throws [CacheException] if no cached data is present.
  Future<List<FoodModel>> getCachedFavoriteFoods({
    required String userId,
    int limit = 20,
  });
  
  /// Searches cached foods by query and categories.
  /// Throws [CacheException] if no cached data is present.
  Future<List<FoodModel>> searchCachedFoods({
    required String query,
    List<String>? categories,
    int limit = 20,
  });
  
  /// Gets cached food recommendations for a user.
  /// Throws [CacheException] if no cached data is present.
  Future<List<FoodModel>> getCachedFoodRecommendations({
    required String userId,
    int limit = 5,
  });
  
  /// Caches a food item.
  Future<void> cacheFood(FoodModel food);
  
  /// Removes a food item from cache.
  Future<void> removeFood(String id);
}

class FoodLocalDataSourceImpl implements FoodLocalDataSource {
  final LocalStorageService localStorageService;
  
  FoodLocalDataSourceImpl({required this.localStorageService});
  
  @override
  Future<FoodModel> getCachedFoodById(String id) async {
    final jsonString = await localStorageService.getString('FOOD_$id');
    if (jsonString != null) {
      return FoodModel.fromJson(json.decode(jsonString));
    } else {
      throw CacheException();
    }
  }
  
  @override
  Future<FoodModel?> getCachedFoodByBarcode(String barcode) async {
    final foodIds = await localStorageService.getStringList('CACHED_FOOD_IDS') ?? [];
    
    for (final id in foodIds) {
      final jsonString = await localStorageService.getString('FOOD_$id');
      if (jsonString != null) {
        final food = FoodModel.fromJson(json.decode(jsonString));
        if (food.barcode == barcode) {
          return food;
        }
      }
    }
    
    return null;
  }
  
  @override
  Future<List<FoodModel>> getCachedRecentFoods({
    required String userId,
    int limit = 10,
  }) async {
    final recentFoodIds = await localStorageService.getStringList('USER_${userId}_RECENT_FOODS') ?? [];
    final limitedIds = recentFoodIds.take(limit).toList();
    
    final foods = <FoodModel>[];
    
    for (final id in limitedIds) {
      try {
        final food = await getCachedFoodById(id);
        foods.add(food);
      } catch (e) {
        // Skip foods that couldn't be loaded
        continue;
      }
    }
    
    if (foods.isEmpty) {
      throw CacheException();
    }
    
    return foods;
  }
  
  @override
  Future<List<FoodModel>> getCachedFavoriteFoods({
    required String userId,
    int limit = 20,
  }) async {
    final favoriteFoodIds = await localStorageService.getStringList('USER_${userId}_FAVORITE_FOODS') ?? [];
    final limitedIds = favoriteFoodIds.take(limit).toList();
    
    final foods = <FoodModel>[];
    
    for (final id in limitedIds) {
      try {
        final food = await getCachedFoodById(id);
        foods.add(food);
      } catch (e) {
        // Skip foods that couldn't be loaded
        continue;
      }
    }
    
    if (foods.isEmpty) {
      throw CacheException();
    }
    
    return foods;
  }
  
  @override
  Future<List<FoodModel>> searchCachedFoods({
    required String query,
    List<String>? categories,
    int limit = 20,
  }) async {
    final foodIds = await localStorageService.getStringList('CACHED_FOOD_IDS') ?? [];
    
    final foods = <FoodModel>[];
    
    for (final id in foodIds) {
      try {
        final jsonString = await localStorageService.getString('FOOD_$id');
        if (jsonString != null) {
          final food = FoodModel.fromJson(json.decode(jsonString));
          
          // Check if the food matches the query
          final nameMatch = food.name.toLowerCase().contains(query.toLowerCase());
          final descriptionMatch = food.description.toLowerCase().contains(query.toLowerCase());
          final brandMatch = food.brand?.toLowerCase().contains(query.toLowerCase()) ?? false;
          
          // Check if the food matches the categories
          final categoryMatch = categories == null ||
              categories.isEmpty ||
              food.categories.any((cat) => categories.contains(cat));
          
          if ((nameMatch || descriptionMatch || brandMatch) && categoryMatch) {
            foods.add(food);
            
            if (foods.length >= limit) {
              break;
            }
          }
        }
      } catch (e) {
        // Skip foods that couldn't be loaded or don't match
        continue;
      }
    }
    
    if (foods.isEmpty) {
      throw CacheException();
    }
    
    return foods;
  }
  
  @override
  Future<List<FoodModel>> getCachedFoodRecommendations({
    required String userId,
    int limit = 5,
  }) async {
    final recommendationIds = await localStorageService.getStringList('USER_${userId}_RECOMMENDATIONS') ?? [];
    final limitedIds = recommendationIds.take(limit).toList();
    
    final foods = <FoodModel>[];
    
    for (final id in limitedIds) {
      try {
        final food = await getCachedFoodById(id);
        foods.add(food);
      } catch (e) {
        // Skip foods that couldn't be loaded
        continue;
      }
    }
    
    if (foods.isEmpty) {
      throw CacheException();
    }
    
    return foods;
  }
  
  @override
  Future<void> cacheFood(FoodModel food) async {
    // Cache the food
    await localStorageService.setString(
      'FOOD_${food.id}',
      json.encode(food.toJson()),
    );
    
    // Update the cached food IDs list
    final foodIds = await localStorageService.getStringList('CACHED_FOOD_IDS') ?? [];
    if (!foodIds.contains(food.id)) {
      foodIds.add(food.id);
      await localStorageService.setStringList('CACHED_FOOD_IDS', foodIds);
    }
  }
  
  @override
  Future<void> removeFood(String id) async {
    // Remove the food
    await localStorageService.remove('FOOD_$id');
    
    // Update the cached food IDs list
    final foodIds = await localStorageService.getStringList('CACHED_FOOD_IDS') ?? [];
    if (foodIds.contains(id)) {
      foodIds.remove(id);
      await localStorageService.setStringList('CACHED_FOOD_IDS', foodIds);
    }
  }
}