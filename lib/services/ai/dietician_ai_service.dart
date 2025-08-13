import 'dart:convert';
import 'package:whole_sight/core/utils/logger.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:whole_sight/services/ai/gemini_service.dart';

class FoodAnalysisResult {
  final String foodName;
  final double estimatedCalories;
  final double estimatedProtein;
  final double estimatedCarbs;
  final double estimatedFat;
  final double estimatedServingSize;
  final String servingUnit;
  final String analysisExplanation;
  final bool canAddToLog;

  FoodAnalysisResult({
    required this.foodName,
    required this.estimatedCalories,
    required this.estimatedProtein,
    required this.estimatedCarbs,
    required this.estimatedFat,
    required this.estimatedServingSize,
    required this.servingUnit,
    required this.analysisExplanation,
    required this.canAddToLog,
  });

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'estimatedCalories': estimatedCalories,
      'estimatedProtein': estimatedProtein,
      'estimatedCarbs': estimatedCarbs,
      'estimatedFat': estimatedFat,
      'estimatedServingSize': estimatedServingSize,
      'servingUnit': servingUnit,
      'analysisExplanation': analysisExplanation,
      'canAddToLog': canAddToLog,
    };
  }
}

abstract class DieticianAIService {
  Future<String> getChatResponse({
    required String userMessage,
    required UserEntity user,
    List<MealEntity>? recentMeals,
    List<Meal>? recentMealModels,
    String? context,
  });

  Future<FoodAnalysisResult?> analyzeFoodFromText({
    required String foodDescription,
    required UserEntity user,
  });

  Future<String> analyzeDailyFoodLog({
    required UserEntity user,
    List<MealEntity>? todayMeals,
    List<Meal>? todayMealModels,
  });

  Future<String> getDetailedDailyAnalysis({
    required UserEntity user,
    List<MealEntity>? todayMeals,
    List<Meal>? todayMealModels,
  });

  Future<String> getPersonalizedAdvice({
    required UserEntity user,
    List<MealEntity>? recentMeals,
    List<Meal>? recentMealModels,
  });

  Future<String> compareWithGoals({
    required UserEntity user,
    List<MealEntity>? recentMeals,
    List<Meal>? recentMealModels,
  });

  Future<String> getMealSuggestions({
    required UserEntity user,
    String? mealType,
  });

  Future<String> analyzeNutritionTrends({
    required UserEntity user,
    List<MealEntity>? weeklyMeals,
    List<Meal>? weeklyMealModels,
  });
}

class DieticianAIServiceImpl implements DieticianAIService {
  final GeminiService _geminiService;
  
  DieticianAIServiceImpl({
    required GeminiService geminiService,
  }) : _geminiService = geminiService;

  @override
  Future<String> getChatResponse({
    required String userMessage,
    required UserEntity user,
    List<MealEntity>? recentMeals,
    List<Meal>? recentMealModels,
    String? context,
  }) async {
    try {
      // First check if the message is nutrition/diet related
      if (!_isNutritionRelated(userMessage)) {
        return "I'm NutriBot, your personal nutrition assistant! I focus specifically on diet, nutrition, and food-related questions. Please ask me about your eating habits, meal planning, nutrition goals, food analysis, or anything related to your health and diet!";
      }

      final prompt = _buildChatPrompt(
        userMessage: userMessage,
        user: user,
        recentMeals: recentMeals,
        recentMealModels: recentMealModels,
        context: context,
      );

      final response = await _geminiService.generateContent(prompt: prompt);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get chat response', e, stackTrace);
      throw Exception('Failed to get AI response: $e');
    }
  }

  @override
  Future<FoodAnalysisResult?> analyzeFoodFromText({
    required String foodDescription,
    required UserEntity user,
  }) async {
    try {
      final prompt = _buildFoodAnalysisPrompt(
        foodDescription: foodDescription,
        user: user,
      );

      final response = await _geminiService.generateContent(prompt: prompt);
      return _parseFoodAnalysisResponse(response);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to analyze food from text', e, stackTrace);
      throw Exception('Failed to analyze food: $e');
    }
  }

  @override
  Future<String> analyzeDailyFoodLog({
    required UserEntity user,
    List<MealEntity>? todayMeals,
    List<Meal>? todayMealModels,
  }) async {
    try {
      final prompt = _buildDailyAnalysisPrompt(
        user: user,
        todayMeals: todayMeals,
        todayMealModels: todayMealModels,
      );

      final response = await _geminiService.generateContent(prompt: prompt);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to analyze daily food log', e, stackTrace);
      throw Exception('Failed to analyze food log: $e');
    }
  }

  @override
  Future<String> getDetailedDailyAnalysis({
    required UserEntity user,
    List<MealEntity>? todayMeals,
    List<Meal>? todayMealModels,
  }) async {
    try {
      final prompt = _buildDetailedDailyAnalysisPrompt(
        user: user,
        todayMeals: todayMeals,
        todayMealModels: todayMealModels,
      );

      final response = await _geminiService.generateContent(prompt: prompt);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get detailed daily analysis', e, stackTrace);
      throw Exception('Failed to analyze detailed food log: $e');
    }
  }

  @override
  Future<String> getPersonalizedAdvice({
    required UserEntity user,
    List<MealEntity>? recentMeals,
    List<Meal>? recentMealModels,
  }) async {
    try {
      final prompt = _buildPersonalizedAdvicePrompt(
        user: user,
        recentMeals: recentMeals,
        recentMealModels: recentMealModels,
      );

      final response = await _geminiService.generateContent(prompt: prompt);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get personalized advice', e, stackTrace);
      throw Exception('Failed to get advice: $e');
    }
  }

  @override
  Future<String> compareWithGoals({
    required UserEntity user,
    List<MealEntity>? recentMeals,
    List<Meal>? recentMealModels,
  }) async {
    try {
      final prompt = _buildGoalComparisonPrompt(
        user: user,
        recentMeals: recentMeals,
        recentMealModels: recentMealModels,
      );

      final response = await _geminiService.generateContent(prompt: prompt);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to compare with goals', e, stackTrace);
      throw Exception('Failed to compare goals: $e');
    }
  }

  @override
  Future<String> getMealSuggestions({
    required UserEntity user,
    String? mealType,
  }) async {
    try {
      final prompt = _buildMealSuggestionsPrompt(
        user: user,
        mealType: mealType,
      );

      final response = await _geminiService.generateContent(prompt: prompt);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get meal suggestions', e, stackTrace);
      throw Exception('Failed to get meal suggestions: $e');
    }
  }

  @override
  Future<String> analyzeNutritionTrends({
    required UserEntity user,
    List<MealEntity>? weeklyMeals,
    List<Meal>? weeklyMealModels,
  }) async {
    try {
      final prompt = _buildTrendAnalysisPrompt(
        user: user,
        weeklyMeals: weeklyMeals,
        weeklyMealModels: weeklyMealModels,
      );

      final response = await _geminiService.generateContent(prompt: prompt);
      return response;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to analyze nutrition trends', e, stackTrace);
      throw Exception('Failed to analyze trends: $e');
    }
  }

  String _buildChatPrompt({
    required String userMessage,
    required UserEntity user,
    List<MealEntity>? recentMeals,
    List<Meal>? recentMealModels,
    String? context,
  }) {
    final profile = user.nutritionProfile;
    
    return '''
You are NutriBot, a friendly AI nutrition assistant for the WholeSight app. Provide brief, actionable nutrition advice. Keep responses under 3 sentences unless detailed analysis is requested.

USER PROFILE:
- Name: ${user.name}
- Age: ${profile?.age ?? 'Not specified'}
- Gender: ${profile?.gender.toString().split('.').last ?? 'Not specified'}
- Height: ${profile?.heightCm ?? 'Not specified'} cm
- Weight: ${profile?.weightKg ?? 'Not specified'} kg
- Activity Level: ${profile?.activityLevel.toString().split('.').last ?? 'Not specified'}
- Primary Goal: ${profile?.goal.toString().split('.').last ?? 'Not specified'}
- Diet Type: ${profile?.dietType.toString().split('.').last ?? 'Not specified'}
- BMI: ${profile?.bmi.toStringAsFixed(1) ?? 'Not calculated'} (${profile?.bmiCategory ?? 'Not categorized'})
- Allergies: ${profile?.allergies.isNotEmpty == true ? profile!.allergies.join(', ') : 'None listed'}
- Disliked Foods: ${profile?.dislikedFoods.isNotEmpty == true ? profile!.dislikedFoods.join(', ') : 'None listed'}
- Medical Conditions: ${profile?.medicalConditions.isNotEmpty == true ? profile!.medicalConditions.join(', ') : 'None listed'}

DAILY TARGETS:
- Calories: ${profile?.calorieTarget ?? 'Not set'} kcal
- Protein: ${profile?.macroTargets['protein'] ?? 'Not set'} g
- Carbs: ${profile?.macroTargets['carbs'] ?? 'Not set'} g
- Fat: ${profile?.macroTargets['fat'] ?? 'Not set'} g

${context != null ? 'ADDITIONAL CONTEXT:\n$context\n' : ''}

${recentMeals != null && recentMeals.isNotEmpty ? _formatRecentMealsForPrompt(recentMeals) : recentMealModels != null && recentMealModels.isNotEmpty ? _formatRecentMealModelsForPrompt(recentMealModels) : ''}

USER MESSAGE: "$userMessage"

Provide a brief, helpful response that:
- Directly answers their question
- Considers their goals and restrictions
- Gives 1-2 actionable tips
- Is encouraging but concise

Keep responses to 2-3 sentences unless they ask for detailed analysis.
''';
  }

  String _buildDailyAnalysisPrompt({
    required UserEntity user,
    List<MealEntity>? todayMeals,
    List<Meal>? todayMealModels,
  }) {
    final profile = user.nutritionProfile;
    
    return '''
As a professional AI dietician, please analyze today's food intake for ${user.name}.

USER PROFILE:
- Primary Goal: ${profile?.goal.toString().split('.').last ?? 'Not specified'}
- Daily Calorie Target: ${profile?.calorieTarget ?? 'Not set'} kcal
- Protein Target: ${profile?.macroTargets['protein'] ?? 'Not set'} g
- Carbs Target: ${profile?.macroTargets['carbs'] ?? 'Not set'} g
- Fat Target: ${profile?.macroTargets['fat'] ?? 'Not set'} g
- Diet Type: ${profile?.dietType.toString().split('.').last ?? 'Not specified'}
- Allergies: ${profile?.allergies.isNotEmpty == true ? profile!.allergies.join(', ') : 'None'}

TODAY'S MEALS:
${todayMeals != null ? _formatMealsForPrompt(todayMeals) : todayMealModels != null ? _formatMealModelsForPrompt(todayMealModels) : 'No meal data available'}

Provide a brief summary (2-3 sentences):
1. Overall assessment of today's intake vs goals
2. One thing they did well + one area to improve
3. End with: "Want a detailed breakdown?"

Be encouraging and focus on key insights only.
''';
  }

  String _buildDetailedDailyAnalysisPrompt({
    required UserEntity user,
    List<MealEntity>? todayMeals,
    List<Meal>? todayMealModels,
  }) {
    final profile = user.nutritionProfile;
    
    return '''
As NutriBot, provide a comprehensive analysis of today's food intake for ${user.name}.

USER PROFILE:
- Primary Goal: ${profile?.goal.toString().split('.').last ?? 'Not specified'}
- Daily Calorie Target: ${profile?.calorieTarget ?? 'Not set'} kcal
- Protein Target: ${profile?.macroTargets['protein'] ?? 'Not set'} g
- Carbs Target: ${profile?.macroTargets['carbs'] ?? 'Not set'} g
- Fat Target: ${profile?.macroTargets['fat'] ?? 'Not set'} g
- Diet Type: ${profile?.dietType.toString().split('.').last ?? 'Not specified'}
- Allergies: ${profile?.allergies.isNotEmpty == true ? profile!.allergies.join(', ') : 'None'}

TODAY'S MEALS:
${todayMeals != null ? _formatMealsForPrompt(todayMeals) : todayMealModels != null ? _formatMealModelsForPrompt(todayMealModels) : 'No meal data available'}

Please provide a detailed breakdown:

**📊 Nutritional Summary:**
- How calories and macros compare to targets (with percentages)
- Key nutritional gaps or excesses

**✅ What You Did Well:**
- Positive aspects of today's choices
- Foods that supported your goals

**🎯 Areas for Improvement:**
- Specific nutritional gaps
- Better food choices for next time

**💡 Tomorrow's Action Plan:**
- 2-3 specific, actionable recommendations
- Suggested foods or meal adjustments

Keep it encouraging and focus on sustainable improvements.
''';
  }

  String _buildPersonalizedAdvicePrompt({
    required UserEntity user,
    List<MealEntity>? recentMeals,
    List<Meal>? recentMealModels,
  }) {
    final profile = user.nutritionProfile;
    
    return '''
Provide personalized nutrition advice for ${user.name} based on their recent eating patterns.

USER PROFILE:
- Age: ${profile?.age} years
- Goal: ${profile?.goal.toString().split('.').last}
- BMI: ${profile?.bmi.toStringAsFixed(1)} (${profile?.bmiCategory})
- Activity Level: ${profile?.activityLevel.toString().split('.').last}
- Diet Type: ${profile?.dietType.toString().split('.').last}
- Medical Conditions: ${profile?.medicalConditions.isNotEmpty == true ? profile!.medicalConditions.join(', ') : 'None'}

RECENT EATING PATTERNS:
${recentMeals != null ? _formatRecentMealsForPrompt(recentMeals) : recentMealModels != null ? _formatRecentMealModelsForPrompt(recentMealModels) : 'No recent meal data available'}

Please provide:
1. **Pattern Analysis**: What trends do you notice in their eating habits?
2. **Personalized Recommendations**: 3-4 specific, actionable suggestions
3. **Potential Challenges**: What obstacles might they face and how to overcome them
4. **Success Tips**: Practical strategies for maintaining progress

Focus on sustainable, realistic changes that fit their lifestyle and preferences.
''';
  }

  String _buildGoalComparisonPrompt({
    required UserEntity user,
    List<MealEntity>? recentMeals,
    List<Meal>? recentMealModels,
  }) {
    final profile = user.nutritionProfile;
    
    return '''
Compare ${user.name}'s recent nutrition intake with their stated goals and provide insights.

GOALS & TARGETS:
- Primary Goal: ${profile?.goal.toString().split('.').last}
- Daily Calories: ${profile?.calorieTarget} kcal
- Protein: ${profile?.macroTargets['protein']} g
- Carbs: ${profile?.macroTargets['carbs']} g
- Fat: ${profile?.macroTargets['fat']} g

RECENT PERFORMANCE:
${recentMeals != null ? _formatRecentMealsForPrompt(recentMeals) : recentMealModels != null ? _formatRecentMealModelsForPrompt(recentMealModels) : 'No recent meal data available'}

Please analyze:
1. **Goal Alignment**: How well are they meeting their targets?
2. **Progress Indicators**: Positive trends you observe
3. **Gap Analysis**: Where they're falling short and why
4. **Adjustment Recommendations**: Should any targets be modified?
5. **Next Steps**: Specific actions to improve alignment

Provide percentages where possible and be specific about which aspects of their nutrition plan are working well versus areas needing attention.
''';
  }

  String _buildMealSuggestionsPrompt({
    required UserEntity user,
    String? mealType,
  }) {
    final profile = user.nutritionProfile;
    final mealTimeContext = mealType != null ? ' for $mealType' : '';
    
    return '''
Suggest personalized meals$mealTimeContext for ${user.name}.

USER PREFERENCES:
- Goal: ${profile?.goal.toString().split('.').last}
- Diet Type: ${profile?.dietType.toString().split('.').last}
- Allergies: ${profile?.allergies.isNotEmpty == true ? profile!.allergies.join(', ') : 'None'}
- Disliked Foods: ${profile?.dislikedFoods.isNotEmpty == true ? profile!.dislikedFoods.join(', ') : 'None'}
- Daily Calorie Target: ${profile?.calorieTarget} kcal

NUTRITIONAL TARGETS${mealType != null ? ' (for this meal)' : ''}:
- Protein: ${profile?.macroTargets['protein']} g daily
- Carbs: ${profile?.macroTargets['carbs']} g daily  
- Fat: ${profile?.macroTargets['fat']} g daily

Please suggest 3-4 meal options that:
1. Align with their dietary restrictions and preferences
2. Support their fitness/health goals
3. Are practical and accessible
4. Include approximate nutritional information
5. Consider meal timing if specified

Format each suggestion with:
- Meal name
- Key ingredients
- Estimated calories and macros
- Brief explanation of why it fits their goals
- Simple preparation notes
''';
  }

  String _buildTrendAnalysisPrompt({
    required UserEntity user,
    List<MealEntity>? weeklyMeals,
    List<Meal>? weeklyMealModels,
  }) {
    final profile = user.nutritionProfile;
    
    return '''
Analyze nutrition trends over the past week for ${user.name}.

USER GOALS:
- Primary Goal: ${profile?.goal.toString().split('.').last}
- Target Calories: ${profile?.calorieTarget} kcal/day
- Target Macros: P:${profile?.macroTargets['protein']}g, C:${profile?.macroTargets['carbs']}g, F:${profile?.macroTargets['fat']}g

WEEKLY DATA:
${weeklyMeals != null ? _formatWeeklyMealsForPrompt(weeklyMeals) : weeklyMealModels != null ? 'Weekly meal data available but in different format' : 'No weekly meal data available'}

Please analyze and provide:
1. **Weekly Overview**: General patterns and consistency
2. **Daily Variations**: Which days were best/worst and why
3. **Macro Balance Trends**: How protein, carbs, and fat intake varied
4. **Behavioral Patterns**: Timing, meal frequency, food choices
5. **Progress Indicators**: Signs of improvement or areas of concern
6. **Week Ahead Strategy**: Specific recommendations for next week

Focus on trends rather than daily fluctuations, and provide actionable insights for sustainable improvement.
''';
  }

  String _formatRecentMealsForPrompt(List<MealEntity> meals) {
    if (meals.isEmpty) return 'No recent meal data available.';
    
    final buffer = StringBuffer();
    buffer.writeln('RECENT MEALS:');
    
    for (final meal in meals.take(10)) {
      buffer.writeln('${meal.timestamp.toString().split(' ')[0]} - ${meal.type.toString().split('.').last}:');
      if (meal.items.isNotEmpty) {
        for (final item in meal.items) {
          buffer.writeln('  • ${item.food.name}: ${item.totalCalories.toStringAsFixed(0)} cal, P:${item.totalProtein.toStringAsFixed(1)}g, C:${item.totalCarbs.toStringAsFixed(1)}g, F:${item.totalFat.toStringAsFixed(1)}g');
        }
      } else {
        buffer.writeln('  • No items logged');
      }
      buffer.writeln('  Total: ${meal.totalCalories.toStringAsFixed(0)} calories');
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  String _formatMealsForPrompt(List<MealEntity> meals) {
    if (meals.isEmpty) return 'No meals logged today.';
    
    final buffer = StringBuffer();
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    
    for (final meal in meals) {
      buffer.writeln('${meal.type.toString().split('.').last.toUpperCase()}:');
      if (meal.items.isNotEmpty) {
        for (final item in meal.items) {
          buffer.writeln('  • ${item.food.name}: ${item.totalCalories.toStringAsFixed(0)} cal');
          totalCalories += item.totalCalories;
          totalProtein += item.totalProtein;
          totalCarbs += item.totalCarbs;
          totalFat += item.totalFat;
        }
      } else {
        buffer.writeln('  • No items logged');
      }
      buffer.writeln('  Meal Total: ${meal.totalCalories.toStringAsFixed(0)} calories');
      buffer.writeln();
    }
    
    buffer.writeln('DAILY TOTALS:');
    buffer.writeln('  Total Calories: ${totalCalories.toStringAsFixed(0)}');
    buffer.writeln('  Total Protein: ${totalProtein.toStringAsFixed(1)}g');
    buffer.writeln('  Total Carbs: ${totalCarbs.toStringAsFixed(1)}g');
    buffer.writeln('  Total Fat: ${totalFat.toStringAsFixed(1)}g');
    
    return buffer.toString();
  }

  String _formatWeeklyMealsForPrompt(List<MealEntity> meals) {
    if (meals.isEmpty) return 'No weekly meal data available.';
    
    final buffer = StringBuffer();
    final dailyTotals = <DateTime, Map<String, double>>{};
    
    for (final meal in meals) {
      final date = DateTime(meal.timestamp.year, meal.timestamp.month, meal.timestamp.day);
      
      if (!dailyTotals.containsKey(date)) {
        dailyTotals[date] = {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
      }
      
      dailyTotals[date]!['calories'] = dailyTotals[date]!['calories']! + meal.totalCalories;
      dailyTotals[date]!['protein'] = dailyTotals[date]!['protein']! + meal.totalProtein;
      dailyTotals[date]!['carbs'] = dailyTotals[date]!['carbs']! + meal.totalCarbs;
      dailyTotals[date]!['fat'] = dailyTotals[date]!['fat']! + meal.totalFat;
    }
    
    final sortedDates = dailyTotals.keys.toList()..sort();
    
    for (final date in sortedDates) {
      final totals = dailyTotals[date]!;
      final dayName = _getDayName(date.weekday);
      buffer.writeln('$dayName (${date.toString().split(' ')[0]}):');
      buffer.writeln('  Calories: ${totals['calories']!.toStringAsFixed(0)}');
      buffer.writeln('  Protein: ${totals['protein']!.toStringAsFixed(1)}g');
      buffer.writeln('  Carbs: ${totals['carbs']!.toStringAsFixed(1)}g');
      buffer.writeln('  Fat: ${totals['fat']!.toStringAsFixed(1)}g');
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  bool _isNutritionRelated(String message) {
    final nutritionKeywords = [
      'food', 'eat', 'diet', 'nutrition', 'calorie', 'protein', 'carb', 'fat', 
      'meal', 'breakfast', 'lunch', 'dinner', 'snack', 'recipe', 'cook', 
      'weight', 'health', 'vitamin', 'mineral', 'fiber', 'sugar', 'sodium',
      'ingredient', 'restaurant', 'hungry', 'full', 'taste', 'flavor',
      'vegetarian', 'vegan', 'keto', 'paleo', 'gluten', 'dairy', 'organic',
      'fresh', 'portion', 'serving', 'gram', 'ounce', 'cup', 'tablespoon',
      'nutritious', 'healthy', 'unhealthy', 'macro', 'micro', 'supplement'
    ];

    final lowerMessage = message.toLowerCase();
    return nutritionKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  String _buildFoodAnalysisPrompt({
    required String foodDescription,
    required UserEntity user,
  }) {
    final profile = user.nutritionProfile;
    
    return '''
You are NutriBot, a friendly nutritionist analyzing food from a text description. Analyze the following food description and provide accurate nutritional estimates.

USER CONTEXT:
- Diet Type: ${profile?.dietType.toString().split('.').last ?? 'Not specified'}
- Allergies: ${profile?.allergies.isNotEmpty == true ? profile!.allergies.join(', ') : 'None'}
- Goals: ${profile?.goal.toString().split('.').last ?? 'General health'}

FOOD DESCRIPTION: "$foodDescription"

Please analyze this food description and provide a JSON response with the following structure:
{
  "foodName": "Clean, standardized name of the food item",
  "estimatedCalories": number (total calories for the described portion),
  "estimatedProtein": number (grams),
  "estimatedCarbs": number (grams),
  "estimatedFat": number (grams),
  "estimatedServingSize": number (quantity of the serving),
  "servingUnit": "string (g, ml, piece, cup, etc.)",
  "analysisExplanation": "Brief explanation of how you calculated these values",
  "canAddToLog": boolean (true if this is a recognizable food item that can be logged)
}

IMPORTANT RULES:
1. If the description is too vague or not a food item, set "canAddToLog" to false
2. Provide realistic estimates based on standard portion sizes
3. Consider the user's dietary preferences and restrictions
4. If multiple foods are mentioned, focus on the main/largest item
5. Be conservative with calorie estimates - it's better to underestimate slightly

Only return the JSON object, no additional text.
''';
  }

  FoodAnalysisResult? _parseFoodAnalysisResponse(String response) {
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
      final Map<String, dynamic> parsedJson = Map<String, dynamic>.from(
        json.decode(jsonStr)
      );
      
      return FoodAnalysisResult(
        foodName: parsedJson['foodName'] as String,
        estimatedCalories: (parsedJson['estimatedCalories'] as num).toDouble(),
        estimatedProtein: (parsedJson['estimatedProtein'] as num).toDouble(),
        estimatedCarbs: (parsedJson['estimatedCarbs'] as num).toDouble(),
        estimatedFat: (parsedJson['estimatedFat'] as num).toDouble(),
        estimatedServingSize: (parsedJson['estimatedServingSize'] as num).toDouble(),
        servingUnit: parsedJson['servingUnit'] as String,
        analysisExplanation: parsedJson['analysisExplanation'] as String,
        canAddToLog: parsedJson['canAddToLog'] as bool,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to parse food analysis response', e, stackTrace);
      return null;
    }
  }

  String _formatRecentMealModelsForPrompt(List<Meal> meals) {
    if (meals.isEmpty) return 'No recent meal data available.';
    
    final buffer = StringBuffer();
    buffer.writeln('RECENT MEALS:');
    
    for (final meal in meals.take(10)) {
      buffer.writeln('${meal.date.toString().split(' ')[0]} - ${meal.type.toString().split('.').last}:');
      if (meal.foods.isNotEmpty) {
        for (final food in meal.foods) {
          buffer.writeln('  • ${food.name}: ${food.calories.toStringAsFixed(0)} cal, P:${food.protein?.toStringAsFixed(1) ?? '0'}g, C:${food.carbs?.toStringAsFixed(1) ?? '0'}g, F:${food.fat?.toStringAsFixed(1) ?? '0'}g');
        }
      } else {
        buffer.writeln('  • No items logged');
      }
      buffer.writeln('  Total: ${meal.totalCalories.toStringAsFixed(0)} calories');
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  String _formatMealModelsForPrompt(List<Meal> meals) {
    if (meals.isEmpty) return 'No meals logged today.';
    
    final buffer = StringBuffer();
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    
    for (final meal in meals) {
      buffer.writeln('${meal.type.toString().split('.').last.toUpperCase()}:');
      if (meal.foods.isNotEmpty) {
        for (final food in meal.foods) {
          buffer.writeln('  • ${food.name}: ${food.calories.toStringAsFixed(0)} cal');
          totalCalories += food.calories;
          totalProtein += food.protein ?? 0;
          totalCarbs += food.carbs ?? 0;
          totalFat += food.fat ?? 0;
        }
      } else {
        buffer.writeln('  • No items logged');
      }
      buffer.writeln('  Meal Total: ${meal.totalCalories.toStringAsFixed(0)} calories');
      buffer.writeln();
    }
    
    buffer.writeln('DAILY TOTALS:');
    buffer.writeln('  Total Calories: ${totalCalories.toStringAsFixed(0)}');
    buffer.writeln('  Total Protein: ${totalProtein.toStringAsFixed(1)}g');
    buffer.writeln('  Total Carbs: ${totalCarbs.toStringAsFixed(1)}g');
    buffer.writeln('  Total Fat: ${totalFat.toStringAsFixed(1)}g');
    
    return buffer.toString();
  }
}