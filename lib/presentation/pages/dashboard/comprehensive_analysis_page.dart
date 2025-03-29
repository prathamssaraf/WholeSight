// lib/presentation/pages/dashboard/comprehensive_analysis_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/usecases/user/get_comprehensive_nutrition_analysis.dart';
import 'package:whole_sight/presentation/bloc/analysis/nutrition_analysis_bloc.dart';
import 'package:whole_sight/presentation/widgets/common/loading_indicator.dart';
import 'package:whole_sight/presentation/widgets/food/nutrition_chart.dart';
import 'package:whole_sight/presentation/widgets/profile/progress_tracker.dart';
import 'package:whole_sight/domain/usecases/user/get_comprehensive_nutrition_analysis.dart';

class ComprehensiveAnalysisPage extends StatefulWidget {
  final String userId;

  const ComprehensiveAnalysisPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _ComprehensiveAnalysisPageState createState() =>
      _ComprehensiveAnalysisPageState();
}

class _ComprehensiveAnalysisPageState extends State<ComprehensiveAnalysisPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Load initial analysis
    context.read<NutritionAnalysisBloc>().add(
          LoadNutritionAnalysis(
            userId: widget.userId,
            startDate: _startDate,
            endDate: _endDate,
          ),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateDateRange(DateTime start, DateTime end) {
    setState(() {
      _startDate = start;
      _endDate = end;
    });

    context.read<NutritionAnalysisBloc>().add(
          ChangeDateRange(
            userId: widget.userId,
            startDate: start,
            endDate: end,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comprehensive Analysis', style: AppTextStyles.headline6),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Nutrient Analysis'),
            Tab(text: 'Meal Patterns'),
            Tab(text: 'Historical Data'),
            Tab(text: 'Insights'),
          ],
          labelStyle: AppTextStyles.button,
        ),
      ),
      body: Column(
        children: [
          _buildDateRangePicker(),
          Expanded(
            child: BlocBuilder<NutritionAnalysisBloc, NutritionAnalysisState>(
              builder: (context, state) {
                if (state is NutritionAnalysisLoading) {
                  return const Center(
                    child: LoadingIndicator(),
                  );
                } else if (state is NutritionAnalysisError) {
                  return Center(
                    child: Text(
                      'Error: ${state.message}',
                      style: TextStyle(color: AppColors.error),
                    ),
                  );
                } else if (state is NutritionAnalysisLoaded) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(state),
                      _buildNutrientAnalysisTab(state),
                      _buildMealPatternsTab(state),
                      _buildHistoricalDataTab(state),
                      _buildInsightsTab(state),
                    ],
                  );
                } else {
                  return Center(
                    child: Text(
                      'Select a date range to view analysis',
                      style: AppTextStyles.body1,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    final DateFormat formatter = DateFormat('MMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  formatter.format(_startDate),
                  style: AppTextStyles.body1,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('to'),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _selectDate(false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  formatter.format(_endDate),
                  style: AppTextStyles.body1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _startDate : _endDate;
    final DateTime firstDate = isStartDate
        ? DateTime.now().subtract(const Duration(days: 365))
        : _startDate;
    final DateTime lastDate = isStartDate ? _endDate : DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      if (isStartDate) {
        _updateDateRange(picked, _endDate);
      } else {
        _updateDateRange(_startDate, picked);
      }
    }
  }

  Widget _buildOverviewTab(NutritionAnalysisLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Daily Average'),
          _buildNutrientSummaryCard(state.result.dailyAverage),
          const SizedBox(height: 24),
          _buildSectionTitle('Target Achievement'),
          _buildTargetProgressCards(state.result.targetPercentages),
          const SizedBox(height: 24),
          _buildSectionTitle('Macronutrient Distribution'),
          SizedBox(
            height: 250,
            child: NutritionChart(
              proteinPercentage:
                  state.result.macronutrientRatio['protein'] ?? 0,
              carbsPercentage: state.result.macronutrientRatio['carbs'] ?? 0,
              fatPercentage: state.result.macronutrientRatio['fat'] ?? 0,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Weekly Trend'),
          SizedBox(
            height: 250,
            child: _buildWeeklyTrendChart(state.result.weeklyTrend),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientAnalysisTab(NutritionAnalysisLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Macronutrient Analysis'),
          _buildMacronutrientAnalysisCard(
              state.result.dailyAverage, state.result.targetPercentages),
          const SizedBox(height: 24),
          _buildSectionTitle('Micronutrient Completion'),
          _buildMicronutrientGrid(state.result.micronutrientCompletion),
          const SizedBox(height: 24),
          _buildSectionTitle('Nutrient Quality Score'),
          _buildNutrientQualityScore(state.result.dailyAverage),
          const SizedBox(height: 24),
          _buildSectionTitle('Nutrient Timing'),
          _buildNutrientTimingChart(state.result.mealTypeDistribution),
        ],
      ),
    );
  }

  Widget _buildMealPatternsTab(NutritionAnalysisLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Meal Distribution'),
          _buildMealDistributionChart(state.result.mealTypeDistribution),
          const SizedBox(height: 24),
          _buildSectionTitle('Top Nutrient-Dense Meals'),
          _buildTopMealsList(state.result.topMeals),
          const SizedBox(height: 24),
          _buildSectionTitle('Weekday Patterns'),
          _buildWeekdayPatternChart(state.result.weekdayPatterns),
        ],
      ),
    );
  }

  Widget _buildHistoricalDataTab(NutritionAnalysisLoaded state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Calorie History'),
          SizedBox(
            height: 250,
            child: _buildCalorieHistoryChart(state.result.dailyIntakeHistory),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Protein History'),
          SizedBox(
            height: 250,
            child: _buildProteinHistoryChart(state.result.dailyIntakeHistory),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Carbs & Fat History'),
          SizedBox(
            height: 250,
            child: _buildMacroHistoryChart(state.result.dailyIntakeHistory),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(NutritionAnalysisLoaded state) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionTitle('Nutrition Insights'),
        ...state.result.nutritionalInsights
            .map((insight) => _buildInsightCard(insight)),
        const SizedBox(height: 16),
        _buildSectionTitle('Recommendations'),
        _buildRecommendationsList(state.result),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: AppTextStyles.headline5,
      ),
    );
  }

  Widget _buildNutrientSummaryCard(Map<String, double> dailyAverage) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNutrientRow(
                'Calories', '${dailyAverage['calories']?.toInt() ?? 0} kcal'),
            _buildNutrientRow(
                'Protein', '${dailyAverage['protein']?.toInt() ?? 0} g'),
            _buildNutrientRow(
                'Carbs', '${dailyAverage['carbs']?.toInt() ?? 0} g'),
            _buildNutrientRow('Fat', '${dailyAverage['fat']?.toInt() ?? 0} g'),
            _buildNutrientRow(
                'Fiber', '${dailyAverage['fiber']?.toInt() ?? 0} g'),
            _buildNutrientRow(
                'Sugar', '${dailyAverage['sugar']?.toInt() ?? 0} g'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body1),
          Text(value,
              style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTargetProgressCards(Map<String, double> targetPercentages) {
    return Column(
      children: [
        _buildProgressCard(
            'Calories', targetPercentages['calories'] ?? 0, AppColors.primary),
        _buildProgressCard(
            'Protein', targetPercentages['protein'] ?? 0, AppColors.success),
        _buildProgressCard(
            'Carbs', targetPercentages['carbs'] ?? 0, AppColors.warning),
        _buildProgressCard(
            'Fat', targetPercentages['fat'] ?? 0, AppColors.secondary),
        _buildProgressCard(
            'Fiber', targetPercentages['fiber'] ?? 0, AppColors.info),
      ],
    );
  }

  Widget _buildProgressCard(String nutrient, double percentage, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(nutrient, style: AppTextStyles.body1),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProgressTracker(
                    progress: percentage / 100,
                    color: color,
                    height: 12,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${percentage.toInt()}% of daily target',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyTrendChart(Map<String, List<double>> weeklyTrend) {
    final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      legend: Legend(isVisible: true),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        LineSeries<_ChartData, String>(
          name: 'Calories',
          dataSource: List.generate(
            7,
            (index) => _ChartData(
              days[index],
              weeklyTrend['calories']?[index] ?? 0,
            ),
          ),
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          color: AppColors.primary,
        ),
        LineSeries<_ChartData, String>(
          name: 'Protein',
          dataSource: List.generate(
            7,
            (index) => _ChartData(
              days[index],
              weeklyTrend['protein']?[index] ?? 0,
            ),
          ),
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildMacronutrientAnalysisCard(
    Map<String, double> dailyAverage,
    Map<String, double> targetPercentages,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your macronutrient balance', style: AppTextStyles.subtitle1),
            const SizedBox(height: 16),
            _buildMacroAnalysisRow(
              'Protein',
              dailyAverage['protein']?.toInt() ?? 0,
              targetPercentages['protein'] ?? 0,
              AppColors.success,
            ),
            _buildMacroAnalysisRow(
              'Carbs',
              dailyAverage['carbs']?.toInt() ?? 0,
              targetPercentages['carbs'] ?? 0,
              AppColors.warning,
            ),
            _buildMacroAnalysisRow(
              'Fat',
              dailyAverage['fat']?.toInt() ?? 0,
              targetPercentages['fat'] ?? 0,
              AppColors.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroAnalysisRow(
    String label,
    int amount,
    double percentage,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.body1),
              Text('$amount g',
                  style: AppTextStyles.body1
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ProgressTracker(
            progress: percentage / 100,
            color: color,
            height: 8,
          ),
          const SizedBox(height: 4),
          Text(
            '${percentage.toInt()}% of target',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildMicronutrientGrid(Map<String, double> micronutrientCompletion) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: micronutrientCompletion.length,
      itemBuilder: (context, index) {
        final entry = micronutrientCompletion.entries.elementAt(index);
        return _buildMicronutrientCard(entry.key, entry.value);
      },
    );
  }

  Widget _buildMicronutrientCard(String nutrient, double percentage) {
    final Color color = percentage >= 100
        ? AppColors.success
        : percentage >= 70
            ? AppColors.warning
            : AppColors.error;

    return Card(
      margin: const EdgeInsets.symmetric(
          vertical: 4.0, horizontal: 6.0), // Smaller margins
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      color: const Color(0xFF272727),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced padding from 12.0 to 8.0
        child: Column(
          mainAxisSize: MainAxisSize.min, // Keep this to minimize height
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nutrient,
              style: const TextStyle(
                color: Color.fromRGBO(255, 255, 255, 1),
                fontSize: 10, // Smaller font
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3), // Minimal spacing
            ProgressTracker(
              progress: percentage / 100,
              color: color,
              height: 6, // Thinner progress bar
            ),
            const SizedBox(height: 2), // Minimal spacing
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 10, // Smaller font
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientQualityScore(Map<String, double> dailyAverage) {
    // Calculate a simple quality score based on protein and fiber
    final double proteinScore = dailyAverage['protein'] ?? 0;
    final double fiberScore =
        (dailyAverage['fiber'] ?? 0) * 3; // Weight fiber higher
    final double sugarPenalty =
        (dailyAverage['sugar'] ?? 0) * 0.5; // Penalty for sugar

    // Simple calculation, would be more sophisticated in real app
    double qualityScore = (proteinScore + fiberScore - sugarPenalty) / 20;
    qualityScore = qualityScore.clamp(0, 10); // Limit to 0-10 scale

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              qualityScore.toStringAsFixed(1),
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 8),
            Text(
              'Nutrition Quality Score (0-10)',
              style: AppTextStyles.body1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildQualityScoreDetails(qualityScore),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityScoreDetails(double score) {
    String qualityText;
    Color qualityColor;

    if (score >= 8) {
      qualityText = 'Excellent! Your diet is rich in key nutrients.';
      qualityColor = AppColors.success;
    } else if (score >= 6) {
      qualityText = 'Good. Your diet has a solid nutritional foundation.';
      qualityColor = AppColors.primary;
    } else if (score >= 4) {
      qualityText = 'Average. Consider increasing nutrient-dense foods.';
      qualityColor = AppColors.warning;
    } else {
      qualityText =
          'Needs improvement. Focus on whole foods with more nutrients.';
      qualityColor = AppColors.error;
    }

    return Column(
      children: [
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [AppColors.error, AppColors.warning, AppColors.success],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          qualityText,
          style: AppTextStyles.body2.copyWith(color: qualityColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNutrientTimingChart(Map<String, double> mealDistribution) {
    return SizedBox(
      height: 300,
      child: SfCircularChart(
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
        ),
        series: <CircularSeries>[
          DoughnutSeries<_PieData, String>(
            dataSource: mealDistribution.entries
                .map((e) => _PieData(e.key, e.value))
                .toList(),
            xValueMapper: (_PieData data, _) => data.x,
            yValueMapper: (_PieData data, _) => data.y,
            dataLabelMapper: (_PieData data, _) => '${data.y.toInt()}%',
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  Widget _buildMealDistributionChart(Map<String, double> mealDistribution) {
    return SizedBox(
      height: 300,
      child: SfCircularChart(
        legend: Legend(
          isVisible: true,
          position: LegendPosition.bottom,
        ),
        series: <CircularSeries>[
          PieSeries<_PieData, String>(
            dataSource: mealDistribution.entries
                .map((e) => _PieData(e.key, e.value))
                .toList(),
            xValueMapper: (_PieData data, _) => data.x,
            yValueMapper: (_PieData data, _) => data.y,
            dataLabelMapper: (_PieData data, _) => '${data.y.toInt()}%',
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            explode: true,
            explodeIndex: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildTopMealsList(List<MealEntity> topMeals) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topMeals.length,
      itemBuilder: (context, index) {
        final meal = topMeals[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text('${index + 1}',
                  style: const TextStyle(color: Colors.white)),
            ),
            title: Text(meal.name, style: AppTextStyles.subtitle2),
            subtitle: Text(
              '${meal.totalCalories.toInt()} cal, ${meal.totalProtein.toInt()}g protein',
              style: AppTextStyles.caption,
            ),
            trailing: Icon(
              _getMealTypeIcon(meal.type),
              color: AppColors.primary,
            ),
          ),
        );
      },
    );
  }

  IconData _getMealTypeIcon(MealType type) {
    switch (type) {
      case MealType.breakfast:
        return Icons.wb_sunny;
      case MealType.lunch:
        return Icons.restaurant;
      case MealType.dinner:
        return Icons.nightlight_round;
      case MealType.snack:
        return Icons.cookie;
      default:
        return Icons.fastfood;
    }
  }

  Widget _buildWeekdayPatternChart(Map<String, double> weekdayPatterns) {
    final sortedEntries = weekdayPatterns.entries.toList()
      ..sort((a, b) => _weekdayToInt(a.key).compareTo(_weekdayToInt(b.key)));

    return SizedBox(
      height: 250,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Calories'),
        ),
        series: <CartesianSeries>[
          ColumnSeries<_ChartData, String>(
            dataSource:
                sortedEntries.map((e) => _ChartData(e.key, e.value)).toList(),
            xValueMapper: (_ChartData data, _) => data.x,
            yValueMapper: (_ChartData data, _) => data.y,
            name: 'Calories',
            color: AppColors.primary,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
          ),
        ],
      ),
    );
  }

  int _weekdayToInt(String weekday) {
    switch (weekday) {
      case 'Monday':
        return 1;
      case 'Tuesday':
        return 2;
      case 'Wednesday':
        return 3;
      case 'Thursday':
        return 4;
      case 'Friday':
        return 5;
      case 'Saturday':
        return 6;
      case 'Sunday':
        return 7;
      default:
        return 0;
    }
  }

  Widget _buildCalorieHistoryChart(
      Map<DateTime, Map<String, double>> dailyIntakeHistory) {
    final sortedEntries = dailyIntakeHistory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final DateFormat dateFormat = DateFormat('MM/dd');

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Calories'),
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        tooltipSettings: const InteractiveTooltip(
          enable: true,
        ),
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enableDoubleTapZooming: true,
        enablePinching: true,
      ),
      series: <CartesianSeries>[
        LineSeries<_ChartData, String>(
          dataSource: sortedEntries
              .map((e) => _ChartData(
                    dateFormat.format(e.key),
                    e.value['calories'] ?? 0,
                  ))
              .toList(),
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          name: 'Calories',
          color: AppColors.primary,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildProteinHistoryChart(
      Map<DateTime, Map<String, double>> dailyIntakeHistory) {
    final sortedEntries = dailyIntakeHistory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final DateFormat dateFormat = DateFormat('MM/dd');

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Protein (g)'),
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        tooltipSettings: const InteractiveTooltip(
          enable: true,
        ),
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enableDoubleTapZooming: true,
        enablePinching: true,
      ),
      series: <CartesianSeries>[
        LineSeries<_ChartData, String>(
          dataSource: sortedEntries
              .map((e) => _ChartData(
                    dateFormat.format(e.key),
                    e.value['protein'] ?? 0,
                  ))
              .toList(),
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          name: 'Protein',
          color: AppColors.success,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildMacroHistoryChart(
      Map<DateTime, Map<String, double>> dailyIntakeHistory) {
    final sortedEntries = dailyIntakeHistory.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final DateFormat dateFormat = DateFormat('MM/dd');

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Grams'),
      ),
      legend: Legend(isVisible: true),
      trackballBehavior: TrackballBehavior(
        enable: true,
        tooltipSettings: const InteractiveTooltip(
          enable: true,
        ),
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enableDoubleTapZooming: true,
        enablePinching: true,
      ),
      series: <CartesianSeries>[
        LineSeries<_ChartData, String>(
          dataSource: sortedEntries
              .map((e) => _ChartData(
                    dateFormat.format(e.key),
                    e.value['carbs'] ?? 0,
                  ))
              .toList(),
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          name: 'Carbs',
          color: AppColors.warning,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
        LineSeries<_ChartData, String>(
          dataSource: sortedEntries
              .map((e) => _ChartData(
                    dateFormat.format(e.key),
                    e.value['fat'] ?? 0,
                  ))
              .toList(),
          xValueMapper: (_ChartData data, _) => data.x,
          yValueMapper: (_ChartData data, _) => data.y,
          name: 'Fat',
          color: AppColors.secondary,
          markerSettings: const MarkerSettings(isVisible: true),
        ),
      ],
    );
  }

  Widget _buildInsightCard(String insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                insight,
                style: AppTextStyles.body1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsList(NutritionAnalysisResult result) {
    // Generate recommendations based on analysis
    final List<Map<String, dynamic>> recommendations = [
      {
        'title': 'Balance Your Macros',
        'description':
            'Your current macro ratio is ${result.macronutrientRatio['protein']?.toInt() ?? 0}% protein, ${result.macronutrientRatio['carbs']?.toInt() ?? 0}% carbs, and ${result.macronutrientRatio['fat']?.toInt() ?? 0}% fat.',
        'icon': Icons.balance,
      },
      {
        'title': 'Increase Nutrient Density',
        'description':
            'Focus on foods rich in vitamins and minerals to improve your micronutrient completion scores.',
        'icon': Icons.trending_up,
      },
      {
        'title': 'Meal Timing',
        'description':
            'Consider distributing your calories more evenly throughout the day for sustained energy.',
        'icon': Icons.access_time,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: Icon(recommendation['icon'], color: AppColors.primary),
            title: Text(recommendation['title'],
                style:
                    AppTextStyles.body1.copyWith(fontWeight: FontWeight.bold)),
            subtitle:
                Text(recommendation['description'], style: AppTextStyles.body2),
          ),
        );
      },
    );
  }
}

class _ChartData {
  final String x;
  final double y;

  _ChartData(this.x, this.y);
}

class _PieData {
  final String x;
  final double y;

  _PieData(this.x, this.y);
}
