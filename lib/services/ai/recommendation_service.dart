import 'dart:convert';

import 'package:whole_sight/core/utils/logger.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/services/ai/gemini_service.dart';

abstract class RecommendationService {
  Future<List<FoodEntity>> recommendFoodsBasedOnNutritionGaps({
    required NutritionProfileEntity nutritionProfile,
    required List<MealEntity> recentMeals,
    int limit = 5,
  });
  
  Future<List<Map<String, dynamic>>> generateMealPlan({
    required NutritionProfileEntity nutritionProfile,
    required int daysCount,
    List<String>? preferredFoods,
  });
  
  Future<String> getPersonalizedNutritionTip({
    required NutritionProfileEntity nutritionProfile,
    required List<MealEntity> recentMeals,
  });
  
  Future<List<Map<String, dynamic>>> suggestAlternativesToFavorites({
    required List<FoodEntity> favoriteFoods,
    required NutritionProfileEntity nutritionProfile,
  });
}

class RecommendationServiceImpl implements RecommendationService {
  final GeminiService _geminiService;
  
  RecommendationServiceImpl({
    required GeminiService geminiService,
  }) : _geminiService = geminiService;
  
  @override
  Future<List<FoodEntity>> recommendFoodsBasedOnNutritionGaps({
    required NutritionProfileEntity nutritionProfile,
    required List<MealEntity> recentMeals,
    int limit = 5,
  }) async {
    try {
      // Extract recent nutrition data
      final recentNutrition = _calculateAverageNutrition(recentMeals);
      
      // Create a prompt for Gemini
      final prompt = _buildNutritionGapsPrompt(
        nutritionProfile: nutritionProfile,
        recentNutrition: recentNutrition,
        limit: limit,
      );
      
      // Generate recommendations using Gemini
      final response = await _geminiService.generateContent(prompt: prompt);
      
      // Parse the response (implement a JSON parser for the Gemini response)
      final recommendedFoods = _parseRecommendationResponse(response);
      
      return recommendedFoods;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to recommend foods based on nutrition gaps', e, stackTrace);
      throw Exception('Failed to recommend foods: $e');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> generateMealPlan({
    required NutritionProfileEntity nutritionProfile,
    required int daysCount,
    List<String>? preferredFoods,
  }) async {
    try {
      // Create a prompt for Gemini
      final prompt = _buildMealPlanPrompt(
        nutritionProfile: nutritionProfile,
        daysCount: daysCount,
        preferredFoods: preferredFoods,
      );
      
      // Generate meal plan using Gemini
      final response = await _geminiService.generateContent(prompt: prompt);
      
      // Parse the response
      final mealPlan = _parseMealPlanResponse(response);
      
      return mealPlan;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate meal plan', e, stackTrace);
      throw Exception('Failed to generate meal plan: $e');
    }
  }
  
  @override
  Future<String> getPersonalizedNutritionTip({
    required NutritionProfileEntity nutritionProfile,
    required List<MealEntity> recentMeals,
  }) async {
    try {
      // Extract recent nutrition data
      final recentNutrition = _calculateAverageNutrition(recentMeals);
      
      // Create a prompt for Gemini
      final prompt = _buildNutritionTipPrompt(
        nutritionProfile: nutritionProfile,
        recentNutrition: recentNutrition,
      );
      
      // Generate a tip using Gemini
      final response = await _geminiService.generateContent(prompt: prompt);
      
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get personalized nutrition tip', e, stackTrace);
      throw Exception('Failed to get nutrition tip: $e');
    }
  }
  
  @override
  Future<List<Map<String, dynamic>>> suggestAlternativesToFavorites({
    required List<FoodEntity> favoriteFoods,
    required NutritionProfileEntity nutritionProfile,
  }) async {
    try {
      // Create a prompt for Gemini
      final prompt = _buildAlternativesPrompt(
        favoriteFoods: favoriteFoods,
        nutritionProfile: nutritionProfile,
      );
      
      // Generate alternatives using Gemini
      final response = await _geminiService.generateContent(prompt: prompt);
      
      // Parse the response
      final alternatives = _parseAlternativesResponse(response);
      
      return alternatives;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to suggest alternatives to favorites', e, stackTrace);
      throw Exception('Failed to suggest alternatives: $e');
    }
  }
  
  // Helper methods
  
  Map<String, double> _calculateAverageNutrition(List<MealEntity> meals) {
    if (meals.isEmpty) {
      return {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fat': 0,
        'fiber': 0,
      };
    }
    
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    
    for (final meal in meals) {
      totalCalories += meal.totalCalories;
      totalProtein += meal.totalProtein;
      totalCarbs += meal.totalCarbs;
      totalFat += meal.totalFat;
      totalFiber += meal.totalFiber;
    }
    
    final daysCount = meals.length / 3; // Assuming 3 meals per day
    
    return {
      'calories': totalCalories / daysCount,
      'protein': totalProtein / daysCount,
      'carbs': totalCarbs / daysCount,
      'fat': totalFat / daysCount,
      'fiber': totalFiber / daysCount,
    };
  }
  
  String _buildNutritionGapsPrompt({
    required NutritionProfileEntity nutritionProfile,
    required Map<String, double> recentNutrition,
    required int limit,
  }) {
    return '''
Please recommend $limit specific foods that would help fill the nutrition gaps based on the following information:

User Profile:
- Age: ${nutritionProfile.age}
- Gender: ${nutritionProfile.gender.toString().split('.').last}
- Weight: ${nutritionProfile.weightKg} kg
- Height: ${nutritionProfile.heightCm} cm
- Activity Level: ${nutritionProfile.activityLevel.toString().split('.').last}
- Goal: ${nutritionProfile.goal.toString().split('.').last}
- Diet Type: ${nutritionProfile.dietType.toString().split('.').last}
- Allergies: ${nutritionProfile.allergies.join(', ')}
- Disliked Foods: ${nutritionProfile.dislikedFoods.join(', ')}
- Medical Conditions: ${nutritionProfile.medicalConditions.join(', ')}

Daily Nutrition Targets:
- Calories: ${nutritionProfile.calorieTarget} kcal
- Protein: ${nutritionProfile.macroTargets['protein']} g
- Carbs: ${nutritionProfile.macroTargets['carbs']} g
- Fat: ${nutritionProfile.macroTargets['fat']} g

Recent Average Daily Intake:
- Calories: ${recentNutrition['calories']!.toStringAsFixed(1)} kcal
- Protein: ${recentNutrition['protein']!.toStringAsFixed(1)} g
- Carbs: ${recentNutrition['carbs']!.toStringAsFixed(1)} g
- Fat: ${recentNutrition['fat']!.toStringAsFixed(1)} g
- Fiber: ${recentNutrition['fiber']!.toStringAsFixed(1)} g

Please format your response as a JSON array of food objects with the following properties:
- name: Name of the food
- servingSize: Recommended serving size in grams
- servingUnit: Unit of measurement (g, ml, etc.)
- calories: Calories per serving
- macronutrients: Object with protein, carbs, and fat in grams
- category: Food category (fruit, vegetable, grain, protein, dairy, etc.)
- reason: Brief explanation of why this food helps fill nutrition gaps

Only include the JSON array in your response with no additional text.
''';
  }
  
  String _buildMealPlanPrompt({
    required NutritionProfileEntity nutritionProfile,
    required int daysCount,
    List<String>? preferredFoods,
  }) {
    final preferredFoodsText = preferredFoods != null && preferredFoods.isNotEmpty
        ? 'Preferred Foods: ${preferredFoods.join(", ")}'
        : 'No specific preferred foods mentioned.';
    
    return '''
Please create a $daysCount-day meal plan based on the following user profile:

User Profile:
- Age: ${nutritionProfile.age}
- Gender: ${nutritionProfile.gender.toString().split('.').last}
- Weight: ${nutritionProfile.weightKg} kg
- Height: ${nutritionProfile.heightCm} cm
- Activity Level: ${nutritionProfile.activityLevel.toString().split('.').last}
- Goal: ${nutritionProfile.goal.toString().split('.').last}
- Diet Type: ${nutritionProfile.dietType.toString().split('.').last}
- Allergies: ${nutritionProfile.allergies.join(', ')}
- Disliked Foods: ${nutritionProfile.dislikedFoods.join(', ')}
- Medical Conditions: ${nutritionProfile.medicalConditions.join(', ')}
- $preferredFoodsText

Daily Nutrition Targets:
- Calories: ${nutritionProfile.calorieTarget} kcal
- Protein: ${nutritionProfile.macroTargets['protein']} g
- Carbs: ${nutritionProfile.macroTargets['carbs']} g
- Fat: ${nutritionProfile.macroTargets['fat']} g

Please format your response as a JSON array of day objects, with each day containing breakfast, lunch, dinner, and snacks. For each meal, include:
- name: Name of the meal
- foods: Array of foods, each with name, servingSize, and servingUnit
- totalCalories: Estimated total calories for the meal
- macronutrients: Object with protein, carbs, and fat in grams

Only include the JSON array in your response with no additional text.
''';
  }
  
  String _buildNutritionTipPrompt({
    required NutritionProfileEntity nutritionProfile,
    required Map<String, double> recentNutrition,
  }) {
    return '''
Based on the following information, please provide one personalized nutrition tip that would be most helpful for this user.

User Profile:
- Age: ${nutritionProfile.age}
- Gender: ${nutritionProfile.gender.toString().split('.').last}
- Weight: ${nutritionProfile.weightKg} kg
- Height: ${nutritionProfile.heightCm} cm
- Activity Level: ${nutritionProfile.activityLevel.toString().split('.').last}
- Goal: ${nutritionProfile.goal.toString().split('.').last}
- Diet Type: ${nutritionProfile.dietType.toString().split('.').last}
- BMI: ${nutritionProfile.bmi.toStringAsFixed(1)} (${nutritionProfile.bmiCategory})
- Allergies: ${nutritionProfile.allergies.join(', ')}
- Medical Conditions: ${nutritionProfile.medicalConditions.join(', ')}

Daily Nutrition Targets:
- Calories: ${nutritionProfile.calorieTarget} kcal
- Protein: ${nutritionProfile.macroTargets['protein']} g
- Carbs: ${nutritionProfile.macroTargets['carbs']} g
- Fat: ${nutritionProfile.macroTargets['fat']} g

Recent Average Daily Intake:
- Calories: ${recentNutrition['calories']!.toStringAsFixed(1)} kcal
- Protein: ${recentNutrition['protein']!.toStringAsFixed(1)} g
- Carbs: ${recentNutrition['carbs']!.toStringAsFixed(1)} g
- Fat: ${recentNutrition['fat']!.toStringAsFixed(1)} g
- Fiber: ${recentNutrition['fiber']!.toStringAsFixed(1)} g

The tip should be specific, actionable, and relevant to their goals and recent nutrition patterns. Keep it conversational, supportive, and educational.
''';
  }
  
  String _buildAlternativesPrompt({
    required List<FoodEntity> favoriteFoods,
    required NutritionProfileEntity nutritionProfile,
  }) {
    final foodsText = favoriteFoods.map((food) {
      return '''
- ${food.name}:
  - Calories: ${food.calories} per ${food.servingSize}${food.servingUnit}
  - Protein: ${food.protein}g
  - Carbs: ${food.carbs}g
  - Fat: ${food.fat}g
  - Categories: ${food.categories.join(', ')}
''';
    }).join('');
    
    return '''
Please suggest healthier alternatives to the following favorite foods, considering the user's nutrition profile and goals:

Favorite Foods:
$foodsText

User Profile:
- Goal: ${nutritionProfile.goal.toString().split('.').last}
- Diet Type: ${nutritionProfile.dietType.toString().split('.').last}
- Allergies: ${nutritionProfile.allergies.join(', ')}
- Disliked Foods: ${nutritionProfile.dislikedFoods.join(', ')}

For each favorite food, please suggest 2-3 alternatives that are:
1. Nutritionally superior for the user's goals
2. Similar in taste or satisfaction
3. Realistic substitutions in meals

Please format your response as a JSON array with the following structure:
[
  {
    "originalFood": "name of original food",
    "alternatives": [
      {
        "name": "alternative name",
        "reason": "brief explanation of benefits",
        "nutritionComparison": "how it compares nutritionally"
      },
      ...
    ]
  },
  ...
]

Only include the JSON array in your response with no additional text.
''';
  }
  
  List<FoodEntity> _parseRecommendationResponse(String response) {
    try {
      // Clean up the response to extract just the JSON part
      String jsonStr = response.trim();
      
      // If the response is wrapped in ```json and ``` markdown code block, remove them
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      
      jsonStr = jsonStr.trim();
      
      // Parse the JSON
      final List<dynamic> parsedJson = json.decode(jsonStr);
      
      // Convert the parsed JSON to FoodEntity objects
      return parsedJson.map((item) {
        return FoodEntity(
          id: 'recommendation-${item['name'].toString().toLowerCase().replaceAll(' ', '-')}',
          name: item['name'],
          description: item['reason'] ?? '',
          servingSize: (item['servingSize'] as num).toDouble(),
          servingUnit: item['servingUnit'],
          calories: (item['calories'] as num).toDouble(),
          macronutrients: {
            'protein': (item['macronutrients']['protein'] as num).toDouble(),
            'carbs': (item['macronutrients']['carbs'] as num).toDouble(),
            'fat': (item['macronutrients']['fat'] as num).toDouble(),
          },
          micronutrients: {},
          allergens: [],
          categories: [item['category']],
          isVerified: false,
          isUserCreated: false,
          createdAt: DateTime.now(),
        );
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse food recommendations', e, stackTrace);
      throw Exception('Failed to parse food recommendations: $e');
    }
  }
  
  List<Map<String, dynamic>> _parseMealPlanResponse(String response) {
    try {
      // Clean up the response to extract just the JSON part
      String jsonStr = response.trim();
      
      // If the response is wrapped in ```json and ``` markdown code block, remove them
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      
      jsonStr = jsonStr.trim();
      
      // Parse the JSON
      final List<dynamic> parsedJson = json.decode(jsonStr);
      
      // Convert the parsed JSON to a List of Maps
      return parsedJson.map((item) => item as Map<String, dynamic>).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse meal plan', e, stackTrace);
      throw Exception('Failed to parse meal plan: $e');
    }
  }
  
  List<Map<String, dynamic>> _parseAlternativesResponse(String response) {
    try {
      // Clean up the response to extract just the JSON part
      String jsonStr = response.trim();
      
      // If the response is wrapped in ```json and ``` markdown code block, remove them
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      } else if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      
      jsonStr = jsonStr.trim();
      
      // Parse the JSON
      final List<dynamic> parsedJson = json.decode(jsonStr);
      
      // Convert the parsed JSON to a List of Maps
      return parsedJson.map((item) => item as Map<String, dynamic>).toList();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse food alternatives', e, stackTrace);
      throw Exception('Failed to parse food alternatives: $e');
    }
  }
}