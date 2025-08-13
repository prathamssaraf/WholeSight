import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:whole_sight/services/ai/dietician_ai_service.dart';
import 'package:whole_sight/services/auth/auth_service.dart';
import 'package:whole_sight/services/nutrition/meal_service.dart';
import 'package:whole_sight/services/data/data_export_service.dart';

class AIDieticianPage extends StatefulWidget {
  const AIDieticianPage({super.key});

  @override
  State<AIDieticianPage> createState() => _AIDieticianPageState();
}

class _AIDieticianPageState extends State<AIDieticianPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  UserEntity? _currentUser;
  List<Meal> _recentMeals = [];
  List<Meal> _todayMeals = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await getIt<AuthService>().getCurrentUser();
      if (user != null) {
        final mealService = getIt<MealService>();
        final now = DateTime.now();
        
        final todayMeals = await mealService.getMealsByUserAndDate(user.id, now);
        
        final recentMeals = <Meal>[];
        for (int i = 0; i < 7; i++) {
          final date = now.subtract(Duration(days: i));
          final meals = await mealService.getMealsByUserAndDate(user.id, date);
          recentMeals.addAll(meals);
        }

        setState(() {
          _currentUser = user;
          _todayMeals = todayMeals;
          _recentMeals = recentMeals;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        isUser: false,
        message: "👋 Hi! I'm NutriBot, your personal nutrition assistant! I have access to your nutrition profile and food logs to provide personalized advice.\n\nYou can ask me about your eating habits, get meal suggestions, or use the quick action buttons below!",
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || _currentUser == null) return;

    setState(() {
      _messages.add(ChatMessage(
        isUser: true,
        message: message,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final dieticianService = getIt<DieticianAIService>();
      
      // Check if user wants detailed breakdown
      final lowerMessage = message.toLowerCase();
      String response;
      
      if (lowerMessage.contains('detailed breakdown') || 
          lowerMessage.contains('more details') ||
          lowerMessage.contains('detail') && lowerMessage.contains('analysis')) {
        response = await dieticianService.getDetailedDailyAnalysis(
          user: _currentUser!,
          todayMealModels: _todayMeals,
        );
      } else {
        response = await dieticianService.getChatResponse(
          userMessage: message,
          user: _currentUser!,
          recentMealModels: _recentMeals,
        );
      }

      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: response,
          timestamp: DateTime.now(),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: "I'm sorry, I'm having trouble responding right now. Please try again in a moment.",
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _analyzeTodaysFood() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dieticianService = getIt<DieticianAIService>();
      final analysis = await dieticianService.analyzeDailyFoodLog(
        user: _currentUser!,
        todayMealModels: _todayMeals,
      );

      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: analysis,
          timestamp: DateTime.now(),
          actionType: 'daily_analysis',
          showDetailsButton: analysis.toLowerCase().contains('want a detailed breakdown'),
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: "I couldn't analyze your daily food log right now. Please try again.",
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _getPersonalizedAdvice() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dieticianService = getIt<DieticianAIService>();
      final advice = await dieticianService.getPersonalizedAdvice(
        user: _currentUser!,
        recentMealModels: _recentMeals,
      );

      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: advice,
          timestamp: DateTime.now(),
          actionType: 'personalized_advice',
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: "I couldn't generate personalized advice right now. Please try again.",
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _compareWithGoals() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dieticianService = getIt<DieticianAIService>();
      final comparison = await dieticianService.compareWithGoals(
        user: _currentUser!,
        recentMealModels: _recentMeals,
      );

      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: comparison,
          timestamp: DateTime.now(),
          actionType: 'goal_comparison',
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: "I couldn't compare your progress with your goals right now. Please try again.",
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _getMealSuggestions() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dieticianService = getIt<DieticianAIService>();
      final suggestions = await dieticianService.getMealSuggestions(
        user: _currentUser!,
      );

      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: suggestions,
          timestamp: DateTime.now(),
          actionType: 'meal_suggestions',
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: "I couldn't generate meal suggestions right now. Please try again.",
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _showFoodAnalysisDialog() async {
    final TextEditingController foodController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            'Analyze Food',
            style: AppTextStyles.headline6.copyWith(color: AppColors.textDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Describe the food you ate:',
                style: AppTextStyles.body2.copyWith(color: AppColors.textDark),
              ),
              SizedBox(height: 12),
              TextField(
                controller: foodController,
                maxLines: 3,
                style: TextStyle(color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'e.g., "2 slices of pepperoni pizza" or "1 cup of chicken fried rice"',
                  hintStyle: TextStyle(color: AppColors.textMedium),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.dividerLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: AppColors.textMedium)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _analyzeFoodFromText(foodController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text('Analyze', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _analyzeFoodFromText(String foodDescription) async {
    if (foodDescription.trim().isEmpty || _currentUser == null) return;

    setState(() {
      _messages.add(ChatMessage(
        isUser: true,
        message: "Analyze this food: $foodDescription",
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final dieticianService = getIt<DieticianAIService>();
      final analysisResult = await dieticianService.analyzeFoodFromText(
        foodDescription: foodDescription,
        user: _currentUser!,
      );

      if (analysisResult != null && analysisResult.canAddToLog) {
        setState(() {
          _messages.add(ChatMessage(
            isUser: false,
            message: _formatFoodAnalysisMessage(analysisResult),
            timestamp: DateTime.now(),
            actionType: 'food_analysis',
            foodAnalysis: analysisResult,
          ));
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            isUser: false,
            message: "I couldn't analyze that food description. Please try being more specific about the food item and portion size (e.g., '1 medium apple' or '2 slices of bread').",
            timestamp: DateTime.now(),
            isError: true,
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: "I couldn't analyze the food right now. Please try again in a moment.",
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  String _formatFoodAnalysisMessage(FoodAnalysisResult analysis) {
    return '''
**${analysis.foodName}**

📊 **Nutritional Analysis:**
• Calories: ${analysis.estimatedCalories.round()} kcal
• Protein: ${analysis.estimatedProtein.toStringAsFixed(1)}g
• Carbs: ${analysis.estimatedCarbs.toStringAsFixed(1)}g
• Fat: ${analysis.estimatedFat.toStringAsFixed(1)}g
• Serving: ${analysis.estimatedServingSize.toStringAsFixed(1)} ${analysis.servingUnit}

💡 **Analysis:** ${analysis.analysisExplanation}

Would you like to add this to your food log?
''';
  }

  Future<void> _addFoodToLog(FoodAnalysisResult analysis) async {
    if (_currentUser == null) return;

    try {
      // Create a FoodItem from the analysis
      final foodItem = FoodItem(
        name: analysis.foodName,
        quantity: '${analysis.estimatedServingSize.toStringAsFixed(1)} ${analysis.servingUnit}',
        calories: analysis.estimatedCalories.round(),
        protein: analysis.estimatedProtein,
        carbs: analysis.estimatedCarbs,
        fat: analysis.estimatedFat,
      );

      // Determine meal type based on current time
      final now = DateTime.now();
      final hour = now.hour;
      MealType mealType;
      String timeString = '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      if (hour < 10) {
        mealType = MealType.breakfast;
      } else if (hour < 14) {
        mealType = MealType.lunch;
      } else if (hour < 18) {
        mealType = MealType.snack;
      } else {
        mealType = MealType.dinner;
      }

      // Create a meal with the analyzed food
      final meal = Meal(
        type: mealType,
        time: timeString,
        foods: [foodItem],
        totalCalories: analysis.estimatedCalories.round(),
        userId: _currentUser!.id,
        date: now,
      );

      // Add the meal using MealService
      final mealService = getIt<MealService>();
      await mealService.addMeal(meal);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${analysis.foodName}" to your ${mealType.toString().split('.').last} log!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      
      // Refresh the data
      await _loadUserData();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add food to log: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _getDetailedAnalysis() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final dieticianService = getIt<DieticianAIService>();
      final detailedAnalysis = await dieticianService.getDetailedDailyAnalysis(
        user: _currentUser!,
        todayMealModels: _todayMeals,
      );

      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: detailedAnalysis,
          timestamp: DateTime.now(),
          actionType: 'detailed_analysis',
        ));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          message: "I couldn't provide detailed analysis right now. Please try again.",
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _exportAndShareData() async {
    if (_currentUser == null) return;

    try {
      final exportService = getIt<DataExportService>();
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: 30)); // Last 30 days

      await exportService.shareUserDataCsv(
        userId: _currentUser!.id,
        startDate: startDate,
        endDate: now,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your nutrition data has been shared!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export data: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Column(
        children: [
          // Quick Actions Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: AppTextStyles.subtitle2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickActionButton(
                        icon: Icons.today,
                        label: 'Analyze Today',
                        onTap: _analyzeTodaysFood,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 8),
                      _QuickActionButton(
                        icon: Icons.lightbulb,
                        label: 'Get Advice',
                        onTap: _getPersonalizedAdvice,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 8),
                      _QuickActionButton(
                        icon: Icons.track_changes,
                        label: 'Check Goals',
                        onTap: _compareWithGoals,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 8),
                      _QuickActionButton(
                        icon: Icons.restaurant_menu,
                        label: 'Meal Ideas',
                        onTap: _getMealSuggestions,
                        color: AppColors.info,
                      ),
                      SizedBox(width: 8),
                      _QuickActionButton(
                        icon: Icons.fastfood,
                        label: 'Analyze Food',
                        onTap: _showFoodAnalysisDialog,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8),
                      _QuickActionButton(
                        icon: Icons.share,
                        label: 'Export Data',
                        onTap: _exportAndShareData,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingMessage();
                }
                
                final message = _messages[index];
                return _ChatBubble(
                  message: message,
                  onAddToLog: _addFoodToLog,
                  onGetDetails: _getDetailedAnalysis,
                );
              },
            ),
          ),

          // Message Input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: AppColors.textDark),
                    decoration: InputDecoration(
                      hintText: 'Ask about diet & nutrition...',
                      hintStyle: TextStyle(color: AppColors.textMedium),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.dividerLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.psychology, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                SizedBox(width: 8),
                Text('Analyzing...', style: AppTextStyles.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(FoodAnalysisResult)? onAddToLog;
  final VoidCallback? onGetDetails;

  const _ChatBubble({
    required this.message,
    this.onAddToLog,
    this.onGetDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: message.isError ? AppColors.error : AppColors.primary,
              child: Icon(
                message.isError ? Icons.error : Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? AppColors.primary 
                    : message.isError 
                        ? AppColors.error.withOpacity(0.2)
                        : AppColors.surfaceDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.actionType != null) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getActionTypeLabel(message.actionType!),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                  message.isUser 
                    ? Text(
                        message.message,
                        style: AppTextStyles.body2.copyWith(color: Colors.white),
                      )
                    : MarkdownBody(
                        data: message.message,
                        styleSheet: MarkdownStyleSheet(
                          p: AppTextStyles.body2.copyWith(
                            color: message.isError ? AppColors.error : AppColors.textDark,
                          ),
                          strong: AppTextStyles.body2.copyWith(
                            color: message.isError ? AppColors.error : AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                          em: AppTextStyles.body2.copyWith(
                            color: message.isError ? AppColors.error : AppColors.textDark,
                            fontStyle: FontStyle.italic,
                          ),
                          listBullet: AppTextStyles.body2.copyWith(
                            color: message.isError ? AppColors.error : AppColors.textDark,
                          ),
                        ),
                        shrinkWrap: true,
                      ),
                  if (message.foodAnalysis != null && !message.isUser) ...[
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => onAddToLog?.call(message.foodAnalysis!),
                      icon: Icon(Icons.add, size: 16),
                      label: Text('Add to Food Log'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size(0, 32),
                      ),
                    ),
                  ],
                  if (message.showDetailsButton && !message.isUser) ...[
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => onGetDetails?.call(),
                      icon: Icon(Icons.info_outline, size: 16),
                      label: Text('Get Detailed Analysis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size(0, 32),
                      ),
                    ),
                  ],
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: AppTextStyles.caption.copyWith(
                      color: message.isUser 
                          ? Colors.white70 
                          : AppColors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: AppColors.secondary,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  String _getActionTypeLabel(String actionType) {
    switch (actionType) {
      case 'daily_analysis':
        return '📊 Daily Analysis';
      case 'detailed_analysis':
        return '📊 Detailed Analysis';
      case 'personalized_advice':
        return '💡 Personal Advice';
      case 'goal_comparison':
        return '🎯 Goal Check';
      case 'meal_suggestions':
        return '🍽️ Meal Ideas';
      case 'food_analysis':
        return '🔍 Food Analysis';
      default:
        return '🤖 AI Response';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final bool isUser;
  final String message;
  final DateTime timestamp;
  final bool isError;
  final String? actionType;
  final FoodAnalysisResult? foodAnalysis;
  final bool showDetailsButton;

  ChatMessage({
    required this.isUser,
    required this.message,
    required this.timestamp,
    this.isError = false,
    this.actionType,
    this.foodAnalysis,
    this.showDetailsButton = false,
  });
}