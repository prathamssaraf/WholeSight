import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:whole_sight/core/utils/logger.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv package

class UsdaFoodService {
  late final String apiKey;
  final String baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  UsdaFoodService() {
    // Get API key from .env file
    apiKey = dotenv.env['USDA_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      AppLogger.error('USDA API key not found in .env file', null, null);
      throw Exception('USDA API key not found in .env file');
    }
  }

  Future<List<FoodEntity>> searchFoods(String query,
      {int pageSize = 20}) async {
    try {
      final url =
          '$baseUrl/foods/search?api_key=$apiKey&query=$query&pageSize=$pageSize&dataType=Foundation,SR%20Legacy';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to search foods: ${response.statusCode} ${response.body}');
      }

      final data = json.decode(response.body);
      final foods = data['foods'] as List<dynamic>;

      return foods.map((food) => _mapUsdaFoodToEntity(food)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Error searching USDA foods', e, stackTrace);
      throw Exception('Failed to search USDA foods: $e');
    }
  }

  Future<FoodEntity> getFoodDetails(String fdcId) async {
    try {
      final url = '$baseUrl/food/$fdcId?api_key=$apiKey&format=full';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to get food details: ${response.statusCode} ${response.body}');
      }

      final food = json.decode(response.body);

      return _mapUsdaFoodDetailsToEntity(food);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting USDA food details', e, stackTrace);
      throw Exception('Failed to get USDA food details: $e');
    }
  }

  FoodEntity _mapUsdaFoodToEntity(Map<String, dynamic> food) {
    // Extract nutrients
    final nutrients = food['foodNutrients'] as List<dynamic>;

    // Map of nutrient ID to common name for quick extraction
    final Map<int, String> nutrientMap = {
      1003: 'protein',
      1004: 'fat',
      1005: 'carbohydrates',
      1008: 'calories',
      1079: 'fiber',
      2000: 'sugar'
    };

    final Map<String, double> macronutrients = {};
    double calories = 0;

    // Extract the common nutrients
    for (final nutrient in nutrients) {
      final nutrientId = nutrient['nutrientId'] as int;
      // Fix the type casting issue - handle both int and double values
      final dynamic rawValue = nutrient['value'];
      final double value =
          rawValue is int ? rawValue.toDouble() : (rawValue as double? ?? 0.0);

      if (nutrientMap.containsKey(nutrientId)) {
        if (nutrientId == 1008) {
          // Special handling for calories
          calories = value;
        } else {
          macronutrients[nutrientMap[nutrientId]!] = value;
        }
      }
    }

    // Get categories from food category
    final List<String> categories = [];
    if (food['foodCategory'] != null) {
      categories.add(food['foodCategory']);
    }

    return FoodEntity(
      id: food['fdcId'].toString(),
      name: food['description'] ?? 'Unknown Food',
      description: food['additionalDescriptions'] ?? '',
      servingSize: 100, // Default to 100g for USDA data
      servingUnit: 'g',
      calories: calories,
      macronutrients: macronutrients,
      micronutrients: {}, // Detailed micronutrients in the detailed view
      allergens: [],
      categories: categories,
      brand: food['brandOwner'],
      isVerified: true,
      isUserCreated: false,
      createdAt: DateTime.now(), // Add this line
      updatedAt: DateTime.now(), // Add this line
      userId: null, // Add this line
    );
  }

  FoodEntity _mapUsdaFoodDetailsToEntity(Map<String, dynamic> food) {
    // This is a more detailed mapping for a specific food
    // Similar to the above but with more complete nutrient extraction
    // For simplicity, just reuse the simpler mapping for now
    return _mapUsdaFoodToEntity(food);
  }
}
