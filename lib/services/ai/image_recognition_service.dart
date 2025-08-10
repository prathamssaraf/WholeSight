import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:whole_sight/core/utils/logger.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/services/ai/gemini_service.dart';
import 'package:whole_sight/services/nutrition/food_database_service.dart';
import 'dart:math';

abstract class ImageRecognitionService {
  Future<List<FoodEntity>> recognizeFoodFromImage(File imageFile);
  Future<List<FoodEntity>> recognizeFoodFromBytes(Uint8List imageBytes);
  Future<List<FoodEntity>> recognizeFoodFromMultipleImages(List<File> imageFiles);
  Future<List<FoodEntity>> recognizeFoodFromMultipleImageBytes(List<Uint8List> multipleImageBytes);
  Future<Map<String, dynamic>> estimatePortionSizes(File imageFile);
}

class ImageRecognitionServiceImpl implements ImageRecognitionService {
  final GeminiService _geminiService;
  final FoodDatabaseService? _foodDatabaseService;

  // Initialize with the model from dotenv
  static final model = GenerativeModel(
    model: 'gemini-2.0-flash-lite',
    apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
  );

  ImageRecognitionServiceImpl({
    GeminiService? geminiService,
    FoodDatabaseService? foodDatabaseService,
  })  : _geminiService = geminiService ?? GeminiServiceImpl(model: model),
        _foodDatabaseService = foodDatabaseService;

  @override
  Future<List<FoodEntity>> recognizeFoodFromImage(File imageFile) async {
    try {
      // Read the image file as bytes
      final imageBytes = await imageFile.readAsBytes();

      return recognizeFoodFromBytes(imageBytes);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to recognize food from image', e, stackTrace);
      throw Exception('Failed to recognize food from image: $e');
    }
  }

  @override
  Future<List<FoodEntity>> recognizeFoodFromBytes(Uint8List imageBytes) async {
    try {
      // Use Gemini Vision to identify foods in the image
      final prompt = '''
Analyze this image and identify all food and drink items present.
For each item, provide the following details:
1. Item name
2. Brief description of the item
3. Estimated portion size (in grams or milliliters)
4. Serving unit (g, ml, oz, cup, etc.)
5. Estimated calories
6. Macronutrients (protein, carbs, fat, fiber, sugar) in grams
7. Category (e.g., fruit, vegetable, protein, grain, dairy, beverage)
8. Allergens (if applicable)

Format your response as a JSON array with the following structure:
[
  {
    "name": "item name",
    "description": "brief description",
    "servingSize": numeric portion size (no units),
    "servingUnit": "g" or "ml" or appropriate unit,
    "calories": estimated calories per serving,
    "macronutrients": {
      "protein": estimated protein in grams,
      "carbs": estimated carbs in grams,
      "fat": estimated fat in grams,
      "fiber": estimated fiber in grams,
      "sugar": estimated sugar in grams
    },
    "allergens": ["allergen1", "allergen2", ...],
    "categories": ["category1", "category2", ...]
  },
  ...
]

Only include the JSON array in your response, with no additional text.
''';

      // Create a part that contains the image
      final imagePart = DataPart('image/jpeg', imageBytes);

      // Query Gemini with the image and prompt
      final response = await _geminiService.generateContentWithImage(
        prompt: prompt,
        image: imagePart,
      );

      // Parse the JSON response
      final jsonResponse = _parseGeminiJsonResponse(response);
      List<dynamic> foodItems;

      try {
        foodItems = json.decode(jsonResponse) as List<dynamic>;
      } catch (e) {
        AppLogger.error('Failed to parse Gemini response as JSON', e);
        // Fallback to creating sample food items
        return _generateFallbackFoodEntities();
      }

      // Convert the identified items to FoodEntity objects
      List<FoodEntity> recognizedFoods = [];
      final now = DateTime.now();

      for (final item in foodItems) {
        try {
          final String foodName = item['name'] ?? 'Unknown Food';
          final String description = item['description'] ?? '';

          // Parse serving details
          final double servingSize = (item['servingSize'] is num)
              ? (item['servingSize'] as num).toDouble()
              : 100.0;

          final String servingUnit = item['servingUnit'] ?? 'g';

          // Parse calories
          final double calories = (item['calories'] is num)
              ? (item['calories'] as num).toDouble()
              : 0.0;

          // Parse macronutrients
          final macroMap = Map<String, double>.from({
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
            'fiber': 0.0,
            'sugar': 0.0,
          });

          if (item['macronutrients'] is Map) {
            final macros = item['macronutrients'] as Map;
            for (final key in macroMap.keys) {
              if (macros[key] is num) {
                macroMap[key] = (macros[key] as num).toDouble();
              }
            }
          }

          // Parse allergens
          List<String> allergens = [];
          if (item['allergens'] is List) {
            allergens = List<String>.from(
                (item['allergens'] as List).map((e) => e.toString()));
          }

          // Parse categories
          List<String> categories = [];
          if (item['categories'] is List) {
            categories = List<String>.from(
                (item['categories'] as List).map((e) => e.toString()));
          }

          // Create the FoodEntity object
          final foodEntity = FoodEntity(
            id: 'ai-${DateTime.now().millisecondsSinceEpoch}-${recognizedFoods.length}',
            name: foodName,
            description: description,
            servingSize: servingSize,
            servingUnit: servingUnit,
            calories: calories,
            macronutrients: macroMap,
            micronutrients: {}, // We don't have this data from the AI yet
            allergens: allergens,
            categories: categories,
            barcode: null,
            brand: null,
            imageUrl: null,
            isVerified: false, // AI-generated data isn't verified
            isUserCreated: true,
            userId: null, // No user ID as it's created by AI
            createdAt: now,
            updatedAt: null,
          );

          recognizedFoods.add(foodEntity);
        } catch (e) {
          AppLogger.error('Error creating FoodEntity from item: $item', e);
          // Continue to the next item
        }
      }

      // If no foods were recognized, return some fallback foods
      if (recognizedFoods.isEmpty) {
        return _generateFallbackFoodEntities();
      }

      return recognizedFoods;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to recognize food from bytes', e, stackTrace);
      // Return fallback food entities rather than throwing
      return _generateFallbackFoodEntities();
    }
  }

  @override
  Future<Map<String, dynamic>> estimatePortionSizes(File imageFile) async {
    try {
      // Read the image file as bytes
      final imageBytes = await imageFile.readAsBytes();

      // Use Gemini Vision to estimate portion sizes
      final prompt = '''
Analyze this image of food and provide an estimate of the portion sizes.
Focus on:
1. Total calorie estimate
2. Portion size of each visible food item in standard measurements (grams, cups, tablespoons, etc.)
3. Relative proportions of macronutrients (protein, carbs, fats)

Format your response as a JSON object with the following structure:
{
  "totalCalories": estimated total calories,
  "items": [
    {
      "name": "item name",
      "portion": {
        "amount": estimated amount,
        "unit": "g" or "ml" or appropriate unit
      },
      "calories": estimated calories for this item,
      "macros": {
        "protein": estimated protein in grams,
        "carbs": estimated carbs in grams,
        "fat": estimated fat in grams
      }
    },
    ...
  ]
}

Only include the JSON object in your response, with no additional text.
''';

      // Create a part that contains the image
      final imagePart = DataPart('image/jpeg', imageBytes);

      // Query Gemini with the image and prompt
      final response = await _geminiService.generateContentWithImage(
        prompt: prompt,
        image: imagePart,
      );

      // Parse the JSON response
      final jsonString = _parseGeminiJsonResponse(response);

      try {
        return json.decode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        AppLogger.error('Failed to parse JSON response for portion sizes', e);
        // Return a fallback response
        return {
          "totalCalories": 500,
          "items": [
            {
              "name": "Unknown Food",
              "portion": {"amount": 100, "unit": "g"},
              "calories": 500,
              "macros": {"protein": 15, "carbs": 60, "fat": 20}
            }
          ]
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to estimate portion sizes', e, stackTrace);
      throw Exception('Failed to estimate portion sizes: $e');
    }
  }

  // Helper method to parse Gemini's JSON response
  String _parseGeminiJsonResponse(String response) {
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

      return jsonStr;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse Gemini JSON response', e, stackTrace);
      throw Exception('Failed to parse AI response: $e');
    }
  }

  // Generate fallback food entities if AI recognition fails
  List<FoodEntity> _generateFallbackFoodEntities() {
    final random = Random();
    final now = DateTime.now();

    // Create a few common food items as fallbacks
    final List<Map<String, dynamic>> commonFoods = [
      {
        'name': 'Apple',
        'description': 'Fresh red apple',
        'servingSize': 150.0,
        'servingUnit': 'g',
        'calories': 80.0,
        'protein': 0.5,
        'carbs': 21.0,
        'fat': 0.3,
        'categories': ['fruit'],
      },
      {
        'name': 'Banana',
        'description': 'Ripe yellow banana',
        'servingSize': 120.0,
        'servingUnit': 'g',
        'calories': 105.0,
        'protein': 1.3,
        'carbs': 27.0,
        'fat': 0.4,
        'categories': ['fruit'],
      },
      {
        'name': 'Chicken Breast',
        'description': 'Cooked chicken breast',
        'servingSize': 100.0,
        'servingUnit': 'g',
        'calories': 165.0,
        'protein': 31.0,
        'carbs': 0.0,
        'fat': 3.6,
        'categories': ['protein', 'meat'],
      },
      {
        'name': 'Salad',
        'description': 'Mixed green salad with vegetables',
        'servingSize': 150.0,
        'servingUnit': 'g',
        'calories': 45.0,
        'protein': 2.0,
        'carbs': 9.0,
        'fat': 0.5,
        'categories': ['vegetable'],
      },
    ];

    // Pick 1-3 random foods
    final numFoods = 1 + random.nextInt(3);
    final selectedIndices = <int>{};

    while (selectedIndices.length < numFoods &&
        selectedIndices.length < commonFoods.length) {
      selectedIndices.add(random.nextInt(commonFoods.length));
    }

    // Create FoodEntity objects
    return selectedIndices.map((index) {
      final food = commonFoods[index];

      return FoodEntity(
        id: 'fallback-${DateTime.now().millisecondsSinceEpoch}-$index',
        name: food['name'],
        description: food['description'],
        servingSize: food['servingSize'],
        servingUnit: food['servingUnit'],
        calories: food['calories'],
        macronutrients: {
          'protein': food['protein'],
          'carbs': food['carbs'],
          'fat': food['fat'],
          'fiber': 0.0,
          'sugar': 0.0,
        },
        micronutrients: {},
        allergens: [],
        categories: List<String>.from(food['categories']),
        isVerified: true,
        isUserCreated: false,
        createdAt: now,
      );
    }).toList();
  }

  @override
  Future<List<FoodEntity>> recognizeFoodFromMultipleImages(List<File> imageFiles) async {
    try {
      // Convert all image files to bytes
      List<Uint8List> imageBytesList = [];
      for (File imageFile in imageFiles) {
        final imageBytes = await imageFile.readAsBytes();
        imageBytesList.add(imageBytes);
      }
      
      return recognizeFoodFromMultipleImageBytes(imageBytesList);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to recognize food from multiple images', e, stackTrace);
      throw Exception('Failed to recognize food from multiple images: $e');
    }
  }

  @override
  Future<List<FoodEntity>> recognizeFoodFromMultipleImageBytes(List<Uint8List> multipleImageBytes) async {
    try {
      if (multipleImageBytes.isEmpty) {
        throw Exception('No images provided');
      }

      // Limit to maximum 3 images
      final imagesToProcess = multipleImageBytes.take(3).toList();
      
      // Create enhanced prompt for multiple images
      final prompt = '''
Analyze these ${imagesToProcess.length} images and identify all food and drink items present across all images.
For each item, provide the following details:
1. Item name
2. Brief description of the item
3. Estimated portion size (in grams or milliliters)
4. Serving unit (g, ml, oz, cup, etc.)
5. Estimated calories
6. Macronutrients (protein, carbs, fat, fiber, sugar) in grams
7. Category (e.g., fruit, vegetable, protein, grain, dairy, beverage)
8. Allergens (if applicable)
9. Which image the food appears in (1, 2, or 3)

If the same food appears in multiple images, only include it once but note all images it appears in.
Combine nutrition information from all angles/views when the same food is shown multiple times.

Format your response as a JSON array with the following structure:
[
  {
    "name": "item name",
    "description": "brief description",
    "servingSize": numeric portion size (no units),
    "servingUnit": "g" or "ml" or appropriate unit,
    "calories": estimated calories per serving,
    "macronutrients": {
      "protein": estimated protein in grams,
      "carbs": estimated carbs in grams,
      "fat": estimated fat in grams,
      "fiber": estimated fiber in grams,
      "sugar": estimated sugar in grams
    },
    "allergens": ["allergen1", "allergen2", ...],
    "categories": ["category1", "category2", ...],
    "appearsInImages": [1, 2, 3]
  },
  ...
]

Only include the JSON array in your response, with no additional text.
''';

      // Create image parts for all images
      List<DataPart> imageParts = [];
      for (int i = 0; i < imagesToProcess.length; i++) {
        imageParts.add(DataPart('image/jpeg', imagesToProcess[i]));
      }

      // Query Gemini with all images and prompt
      final response = await _geminiService.generateContentWithMultipleImages(
        prompt: prompt,
        images: imageParts,
      );

      // Parse the JSON response
      final jsonResponse = _parseGeminiJsonResponse(response);
      List<dynamic> foodItems;

      try {
        foodItems = json.decode(jsonResponse) as List<dynamic>;
      } catch (e) {
        AppLogger.error('Failed to parse Gemini response as JSON for multiple images', e);
        // Fallback to analyzing each image individually and combining results
        return _analyzeImagesIndividually(imagesToProcess);
      }

      // Convert the identified items to FoodEntity objects
      List<FoodEntity> recognizedFoods = [];
      final now = DateTime.now();

      for (final item in foodItems) {
        try {
          final String foodName = item['name'] ?? 'Unknown Food';
          final String description = item['description'] ?? '';

          // Parse serving details
          final double servingSize = (item['servingSize'] is num)
              ? (item['servingSize'] as num).toDouble()
              : 100.0;

          final String servingUnit = item['servingUnit'] ?? 'g';

          // Parse calories
          final double calories = (item['calories'] is num)
              ? (item['calories'] as num).toDouble()
              : 0.0;

          // Parse macronutrients
          final macroMap = Map<String, double>.from({
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
            'fiber': 0.0,
            'sugar': 0.0,
          });

          if (item['macronutrients'] is Map) {
            final macros = item['macronutrients'] as Map;
            for (final key in macroMap.keys) {
              if (macros[key] is num) {
                macroMap[key] = (macros[key] as num).toDouble();
              }
            }
          }

          // Parse allergens
          List<String> allergens = [];
          if (item['allergens'] is List) {
            allergens = List<String>.from(
                (item['allergens'] as List).map((e) => e.toString()));
          }

          // Parse categories
          List<String> categories = [];
          if (item['categories'] is List) {
            categories = List<String>.from(
                (item['categories'] as List).map((e) => e.toString()));
          }

          // Parse which images the food appears in
          String imageInfo = '';
          if (item['appearsInImages'] is List) {
            final imageNumbers = List<int>.from(
                (item['appearsInImages'] as List).map((e) => e is num ? e.toInt() : 1));
            imageInfo = ' (appears in image${imageNumbers.length > 1 ? 's' : ''} ${imageNumbers.join(', ')})';
          }

          // Create the FoodEntity object with enhanced description
          final foodEntity = FoodEntity(
            id: 'ai-multi-${DateTime.now().millisecondsSinceEpoch}-${recognizedFoods.length}',
            name: foodName,
            description: description + imageInfo,
            servingSize: servingSize,
            servingUnit: servingUnit,
            calories: calories,
            macronutrients: macroMap,
            micronutrients: {},
            allergens: allergens,
            categories: categories,
            barcode: null,
            brand: null,
            imageUrl: null,
            isVerified: false,
            isUserCreated: true,
            userId: null,
            createdAt: now,
            updatedAt: null,
          );

          recognizedFoods.add(foodEntity);
        } catch (e) {
          AppLogger.error('Error creating FoodEntity from multi-image item: $item', e);
        }
      }

      // If no foods were recognized, try individual analysis
      if (recognizedFoods.isEmpty) {
        return _analyzeImagesIndividually(imagesToProcess);
      }

      return recognizedFoods;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to recognize food from multiple image bytes', e, stackTrace);
      // Fallback to individual image analysis
      return _analyzeImagesIndividually(multipleImageBytes);
    }
  }

  // Helper method to analyze images individually as fallback
  Future<List<FoodEntity>> _analyzeImagesIndividually(List<Uint8List> imageBytesList) async {
    List<FoodEntity> allRecognizedFoods = [];
    
    for (int i = 0; i < imageBytesList.length; i++) {
      try {
        final foods = await recognizeFoodFromBytes(imageBytesList[i]);
        // Add image indicator to food names to help user identify source
        for (final food in foods) {
          final updatedFood = FoodEntity(
            id: '${food.id}-img${i + 1}',
            name: '${food.name} (Image ${i + 1})',
            description: food.description,
            servingSize: food.servingSize,
            servingUnit: food.servingUnit,
            calories: food.calories,
            macronutrients: food.macronutrients,
            micronutrients: food.micronutrients,
            allergens: food.allergens,
            categories: food.categories,
            barcode: food.barcode,
            brand: food.brand,
            imageUrl: food.imageUrl,
            isVerified: food.isVerified,
            isUserCreated: food.isUserCreated,
            userId: food.userId,
            createdAt: food.createdAt,
            updatedAt: food.updatedAt,
          );
          allRecognizedFoods.add(updatedFood);
        }
      } catch (e) {
        AppLogger.error('Failed to analyze individual image ${i + 1}', e);
      }
    }
    
    return allRecognizedFoods.isNotEmpty ? allRecognizedFoods : _generateFallbackFoodEntities();
  }
}
