import 'package:flutter/material.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/data/models/meal.dart'; // Changed to use Meal instead of MealEntity
import 'package:whole_sight/presentation/pages/food_logging/food_log_page.dart';
import 'package:whole_sight/services/auth/auth_service.dart';
import 'package:whole_sight/services/nutrition/meal_service.dart';
import 'package:fl_chart/fl_chart.dart'; // You'll need to add this dependency

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage>
    with AutomaticKeepAliveClientMixin {
  UserEntity? _user;
  bool _isLoading = true;
  List<Meal> _recentMeals = []; // Changed to Meal type

  // Summary data
  int _calorieConsumed = 0;
  int _calorieTarget = 2000; // Default
  int _proteinConsumed = 0;
  int _proteinTarget = 120; // Default
  double _waterConsumed = 0;
  double _waterTarget = 2.5; // Default in liters

  // Macronutrient data
  int _proteinGrams = 0;
  int _carbsGrams = 0;
  int _fatsGrams = 0;
  int _proteinPercentage = 0;
  int _carbsPercentage = 0;
  int _fatsPercentage = 0;

  // Other nutritional data
  int _fiberConsumed = 0;
  int _fiberTarget = 25;
  int _sugarConsumed = 0;
  int _sugarTarget = 36;

  // Weekly data for trend chart
  List<Map<String, dynamic>> _weeklyData = [];

  @override
  bool get wantKeepAlive => true; // Keep the state when switching tabs

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Public method to refresh data from outside
  void refreshData() {
    _loadUserData();
  }

  // Update your _loadUserData method to call _loadCalorieTarget
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user data
      final authService = getIt<AuthService>();
      final user = await authService.getCurrentUser();

      if (user == null) {
        print('Error: Could not load current user');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to load user data. Please sign in again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _user = user;
        });
      }

      // Load the calorie target from the meal service
      await _loadCalorieTarget();

      // Continue with loading meals and weekly data
      await _loadTodaysMeals();
      await _loadWeeklyData();
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading data. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Add this method to your InsightsPage class
  Future<void> _loadCalorieTarget() async {
    if (_user == null) return;

    try {
      final mealService = getIt<MealService>();
      final calorieTarget = await mealService.getUserCalorieTarget(_user!.id);

      if (mounted) {
        setState(() {
          _calorieTarget = calorieTarget;
          print('Updated calorie target to: $_calorieTarget from MealService');
        });
      }
    } catch (e) {
      print('Error loading calorie target from MealService: $e');
      // Keep existing target
    }
  }

  Future<void> _loadTodaysMeals() async {
    if (_user == null) return;

    try {
      final today = DateTime.now();
      final mealService = getIt<MealService>();

      // Get today's meals
      final meals = await mealService.getMealsByUserAndDate(_user!.id, today);

      // Calculate total nutrients from meals
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;
      double totalFiber = 0;
      double totalSugar = 0;

      for (var meal in meals) {
        totalCalories += meal.totalCalories;

        for (var food in meal.foods) {
          totalProtein += (food.protein ?? 0);
          totalCarbs += (food.carbs ?? 0);
          totalFat += (food.fat ?? 0);
          // Remove fiber and sugar calculations as they're not available
          // or add them to your FoodItem model if needed
          // totalFiber += (food.fiber ?? 0);
          // totalSugar += (food.sugar ?? 0);
        }
      }

      // Calculate macronutrient percentages
      final totalMacros = totalProtein + totalCarbs + totalFat;
      int proteinPct =
          totalMacros > 0 ? ((totalProtein / totalMacros) * 100).round() : 0;
      int carbsPct =
          totalMacros > 0 ? ((totalCarbs / totalMacros) * 100).round() : 0;
      int fatsPct =
          totalMacros > 0 ? ((totalFat / totalMacros) * 100).round() : 0;

      // Get recent meals (last 3)
      final recentMeals = meals.length > 3 ? meals.sublist(0, 3) : meals;

      if (mounted) {
        setState(() {
          _recentMeals = recentMeals;
          _calorieConsumed = totalCalories.round();
          _proteinConsumed = totalProtein.round();
          _proteinGrams = totalProtein.round();
          _carbsGrams = totalCarbs.round();
          _fatsGrams = totalFat.round();
          _proteinPercentage = proteinPct;
          _carbsPercentage = carbsPct;
          _fatsPercentage = fatsPct;
          _fiberConsumed = 0; // Set to 0 or calculate if available
          _sugarConsumed = 0; // Set to 0 or calculate if available

          // Assuming water tracking is done elsewhere
          // For now we'll use a placeholder
          _waterConsumed = 1.2;
        });
      }
    } catch (e) {
      print('Error loading meals: $e');
    }
  }

  Future<void> _loadWeeklyData() async {
    if (_user == null) return;

    try {
      final mealService = getIt<MealService>();
      final now = DateTime.now();

      List<Map<String, dynamic>> weekData = [];

      // Get data for the past 7 days
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final meals = await mealService.getMealsByUserAndDate(_user!.id, date);

        // Calculate total calories for the day
        int totalCalories = 0;
        for (var meal in meals) {
          totalCalories += meal.totalCalories;
        }

        // Format date as day of week
        final dayName = _getDayName(date.weekday);

        weekData.add({
          'day': dayName,
          'calories': totalCalories,
          'date': date,
        });
      }

      if (mounted) {
        setState(() {
          _weeklyData = weekData;
        });
      }
    } catch (e) {
      print('Error loading weekly data: $e');
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            if (_user != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Hello, ${_user!.name.split(' ')[0]}!',
                  style: AppTextStyles.headline5.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Summary card
            _buildSummaryCard(),

            const SizedBox(height: 24),

            // Weekly trend chart
            Text(
              'Weekly Calorie Trend',
              style: AppTextStyles.headline6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildWeeklyTrendChart(),

            const SizedBox(height: 24),

            // Nutrition breakdown
            Text(
              'Today\'s Nutrition',
              style: AppTextStyles.headline6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildNutritionBreakdown(),

            const SizedBox(height: 24),

            // AI insight
            Text(
              'AI Insight',
              style: AppTextStyles.headline6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildAIInsightCard(),

            const SizedBox(height: 24),

            // Recent meals with view all button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Meals',
                  style: AppTextStyles.headline6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to Food Log page or switch tab
                    DefaultTabController.of(context)
                        ?.animateTo(1); // Switch to Food Log tab
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecentMeals(),

            const SizedBox(height: 24),

            // Recommended foods
            Text(
              'Recommended Foods',
              style: AppTextStyles.headline6.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecommendedFoods(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart() {
    // Handle empty data case
    if (_weeklyData.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No data available for the past week',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ),
        ),
      );
    }

    // Calculate max value for y-axis
    final maxCalories = _weeklyData
        .map((day) => day['calories'] as int)
        .reduce((a, b) => a > b ? a : b);

    // Round up to nearest 500 for better scale
    final yAxisMax = ((maxCalories + 499) ~/ 500) * 500.0;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: yAxisMax > 0 ? yAxisMax : 2000,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: AppColors.backgroundDark.withOpacity(0.8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${_weeklyData[groupIndex]['calories']} cal',
                      const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= _weeklyData.length)
                        return Text('');
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _weeklyData[value.toInt()]['day'],
                          style: const TextStyle(
                            color: AppColors.textMedium,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      // Show fewer y-axis labels for cleanliness
                      if (value % 500 != 0) return Text('');

                      return Text(
                        '${value.toInt()}',
                        style: TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 500,
                getDrawingHorizontalLine: (value) {
                  return const FlLine(
                    color: AppColors.dividerLight,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
                verticalInterval: 1,
                getDrawingVerticalLine: (value) {
                  return const FlLine(
                    color: Colors.transparent,
                    strokeWidth: 0,
                  );
                },
              ),
              barGroups: List.generate(
                _weeklyData.length,
                (index) {
                  // Determine if this is today's bar
                  final isToday = _weeklyData[index]['date'].day ==
                          DateTime.now().day &&
                      _weeklyData[index]['date'].month ==
                          DateTime.now().month &&
                      _weeklyData[index]['date'].year == DateTime.now().year;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _weeklyData[index]['calories'].toDouble(),
                        color: isToday
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.5),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Summary',
                  style: AppTextStyles.headline6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Today',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  label: 'Calories',
                  value: '$_calorieConsumed',
                  target: '$_calorieTarget',
                  iconData: Icons.local_fire_department_outlined,
                  color: AppColors.primary,
                  progress: _calorieTarget > 0
                      ? _calorieConsumed / _calorieTarget
                      : 0,
                ),
                _buildSummaryItem(
                  label: 'Protein',
                  value: '${_proteinConsumed}g',
                  target: '${_proteinTarget}g',
                  iconData: Icons.fitness_center_outlined,
                  color: AppColors.protein,
                  progress: _proteinTarget > 0
                      ? _proteinConsumed / _proteinTarget
                      : 0,
                ),
                _buildSummaryItem(
                  label: 'Water',
                  value: '${_waterConsumed}L',
                  target: '${_waterTarget}L',
                  iconData: Icons.water_drop_outlined,
                  color: AppColors.secondary,
                  progress:
                      _waterTarget > 0 ? _waterConsumed / _waterTarget : 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required String target,
    required IconData iconData,
    required Color color,
    required double progress,
  }) {
    // Ensure progress is within bounds
    final boundedProgress = progress.clamp(0.0, 1.0);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.headline6.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'of $target',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: boundedProgress,
            backgroundColor: AppColors.dividerLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionBreakdown() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Improved header with info icon
            Row(
              children: [
                Text(
                  'Macronutrient Distribution',
                  style: AppTextStyles.subtitle1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.info_outline, size: 18),
                  onPressed: () {
                    // Show info dialog about macronutrients
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('About Macronutrients'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                'Protein: 4 calories per gram - Builds and repairs body tissues'),
                            SizedBox(height: 8),
                            Text(
                                'Carbs: 4 calories per gram - Primary energy source'),
                            SizedBox(height: 8),
                            Text(
                                'Fats: 9 calories per gram - Energy storage and hormone production'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('CLOSE'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Macronutrient distribution as a pie chart
            Container(
              height: 180,
              child: Row(
                children: [
                  // Pie chart is not implemented yet - use progress bars for now
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildMacroProgressBar(
                          label: 'Protein',
                          percentage: _proteinPercentage,
                          color: AppColors.protein,
                        ),
                        SizedBox(height: 16),
                        _buildMacroProgressBar(
                          label: 'Carbs',
                          percentage: _carbsPercentage,
                          color: AppColors.carbs,
                        ),
                        SizedBox(height: 16),
                        _buildMacroProgressBar(
                          label: 'Fats',
                          percentage: _fatsPercentage,
                          color: AppColors.fats,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Divider
            Divider(color: AppColors.dividerLight),

            const SizedBox(height: 16),

            // Fiber and sugar header
            Text(
              'Other Nutrients',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // For now, just show a placeholder message
            Text(
              'Additional nutrient tracking is coming soon!',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textMedium,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroProgressBar({
    required String label,
    required int percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 8),
            Text(
              '$label: $percentage%',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppColors.dividerLight,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildAIInsightCard() {
    // Generate a personalized insight based on user data
    String insightText = 'Based on your recent meals';
    String insightTitle = 'Nutrition Tip';
    IconData insightIcon = Icons.lightbulb_outline;

    if (_proteinPercentage < 20 && _calorieConsumed > 0) {
      insightTitle = 'Protein Recommendation';
      insightIcon = Icons.fitness_center_outlined;
      insightText =
          'Based on your recent meals, you might benefit from increasing your protein intake. Try adding more lean protein sources like chicken, fish, or legumes to your meals.';
    } else if (_calorieConsumed < _calorieTarget * 0.5 &&
        _calorieConsumed > 0) {
      insightTitle = 'Calorie Intake Alert';
      insightIcon = Icons.warning_amber_outlined;
      insightText =
          'Your calorie intake is below half of your daily goal. Remember to eat regular meals to maintain your energy throughout the day.';
    } else if (_calorieConsumed > _calorieTarget && _calorieConsumed > 0) {
      insightTitle = 'Calorie Management';
      insightIcon = Icons.balance_outlined;
      insightText =
          'You\'ve exceeded your calorie target for today. Consider balancing with more activity or adjusting your intake tomorrow.';
    } else {
      insightTitle = 'Progress Update';
      insightIcon = Icons.trending_up;
      insightText =
          'Based on your recent meals, you\'re making good progress toward your nutrition goals. Keep up the good work!';
    }

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    insightIcon,
                    color: AppColors.tertiary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            insightTitle,
                            style: AppTextStyles.subtitle1.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.tertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'AI',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.tertiary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Personalized for you',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Insight content
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.dividerLight,
                  width: 1,
                ),
              ),
              child: Text(
                insightText,
                style: AppTextStyles.body1
                    .copyWith(color: AppColors.textDark, fontSize: 12),
              ),
            ),

            const SizedBox(height: 16),

            // Feedback buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.thumb_down_outlined,
                    color: AppColors.textMedium,
                    size: 16,
                  ),
                  label: Text(
                    'Not helpful',
                    style: TextStyle(
                      color: AppColors.textMedium,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(0, 32),
                  ),
                ),
                SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.thumb_up_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  label: Text(
                    'Helpful',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(0, 32),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMeals() {
    if (_recentMeals.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.restaurant,
                size: 48,
                color: AppColors.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No meals logged yet today',
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log your meals to see them here',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to food log page
                  DefaultTabController.of(context)?.animateTo(1);
                },
                icon: Icon(Icons.add),
                label: Text('Add Meal'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentMeals.length,
        itemBuilder: (context, index) {
          final meal = _recentMeals[index];

          // Get food item names
          List<String> foodItems = meal.foods.map((food) => food.name).toList();

          return _buildMealCard(
            mealName: _getMealTypeName(meal.type),
            mealTime: meal.time,
            calories: meal.totalCalories,
            foodItems: foodItems,
            mealId: meal.id ?? "unknown",
          );
        },
      ),
    );
  }

  // Helper method to get meal type name
  String _getMealTypeName(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
      default:
        return 'Meal';
    }
  }

  Widget _buildMealCard({
    required String mealName,
    required String mealTime,
    required int calories,
    required List<String> foodItems,
    required String mealId,
  }) {
    // Choose icon based on meal name
    IconData mealIcon;
    Color mealColor;

    switch (mealName.toLowerCase()) {
      case 'breakfast':
        mealIcon = Icons.breakfast_dining;
        mealColor = Colors.orange;
        break;
      case 'lunch':
        mealIcon = Icons.lunch_dining;
        mealColor = Colors.green;
        break;
      case 'dinner':
        mealIcon = Icons.dinner_dining;
        mealColor = Colors.indigo;
        break;
      case 'snack':
        mealIcon = Icons.restaurant;
        mealColor = Colors.amber;
        break;
      default:
        mealIcon = Icons.restaurant;
        mealColor = AppColors.primary;
    }

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Meal header with icon and gradient background
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    mealColor.withOpacity(0.7),
                    mealColor.withOpacity(0.3),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      mealIcon,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  // Meal info
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              mealIcon,
                              color: Colors.white,
                              size: 24,
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                mealTime,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mealName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '$calories calories',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Food items
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foods',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...foodItems.take(3).map((food) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: mealColor.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                food,
                                style: AppTextStyles.body2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                  if (foodItems.length > 3)
                    Text(
                      '+ ${foodItems.length - 3} more',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // View details button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // Navigate to food log page and focus on this meal
                        DefaultTabController.of(context)?.animateTo(1);
                        // Ideally would scroll to this meal on the food log page
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: mealColor),
                        padding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          color: mealColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedFoods() {
    // Create recommendations based on user's nutrition profile and current intake
    List<Map<String, dynamic>> recommendedFoods = [];

    // Basic recommendations based on nutrition data
    if (_proteinPercentage < 20 && _calorieConsumed > 0) {
      recommendedFoods.add({
        'name': 'Greek Yogurt',
        'calories': 100,
        'protein': 18,
        'reason': 'High Protein',
        'icon': Icons.egg_alt_outlined,
        'color': AppColors.protein,
      });
      recommendedFoods.add({
        'name': 'Chicken Breast',
        'calories': 165,
        'protein': 31,
        'reason': 'Lean Protein',
        'icon': Icons.food_bank_outlined,
        'color': AppColors.protein,
      });
    }

    // Add some defaults if we don't have enough recommendations
    if (recommendedFoods.length < 4) {
      recommendedFoods.addAll([
        {
          'name': 'Salmon',
          'calories': 200,
          'protein': 22,
          'reason': 'Omega-3 Fats',
          'icon': Icons.set_meal_outlined,
          'color': Colors.orange,
        },
        {
          'name': 'Quinoa',
          'calories': 120,
          'protein': 8,
          'reason': 'Complete Protein',
          'icon': Icons.grain_outlined,
          'color': Colors.amber,
        },
        {
          'name': 'Spinach',
          'calories': 25,
          'protein': 3,
          'reason': 'Iron & Vitamins',
          'icon': Icons.spa_outlined,
          'color': Colors.green,
        },
        {
          'name': 'Blueberries',
          'calories': 85,
          'protein': 1,
          'reason': 'Antioxidants',
          'icon': Icons.bubble_chart_outlined,
          'color': Colors.blue,
        },
      ]);
    }

    // Take only the first 4 recommendations
    final displayedFoods = recommendedFoods.take(4).toList();

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayedFoods.length,
        itemBuilder: (context, index) {
          final food = displayedFoods[index];
          return _buildFoodCard(
            name: food['name'],
            calories: food['calories'],
            protein: food['protein'],
            reason: food['reason'],
            icon: food['icon'],
            color: food['color'],
          );
        },
      ),
    );
  }

  Widget _buildFoodCard({
    required String name,
    required int calories,
    required int protein,
    required String reason,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Food icon
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),

              const SizedBox(height: 12),

              // Food name
              Text(
                name,
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Calories and protein
              Text(
                '$calories cal | $protein g protein',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              const SizedBox(height: 8),

              // Reason
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reason,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Spacer(),

              // Add button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // In a real app, this would navigate to add food to meal flow
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name will be added to your next meal'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.add,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Add to Meal',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size(0, 32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
