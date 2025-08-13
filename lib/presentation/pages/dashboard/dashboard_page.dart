import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_event.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_state.dart';
import 'package:whole_sight/presentation/pages/food_logging/food_log_page.dart';
import 'package:whole_sight/presentation/pages/dashboard/insights_page.dart';
import 'package:whole_sight/presentation/pages/ai_dietician/ai_dietician_page.dart';
import 'package:whole_sight/presentation/pages/profile/profile_page.dart';
import 'package:whole_sight/presentation/widgets/common/bottom_nav.dart';
import 'package:whole_sight/services/auth/auth_service.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/services/nutrition/meal_service.dart'; // Added for nutrition summary
import 'package:whole_sight/presentation/bloc/analysis/nutrition_analysis_bloc.dart';
import 'package:whole_sight/presentation/pages/dashboard/comprehensive_analysis_page.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_bloc.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  UserEntity? _currentUser;
  bool _isLoading = true;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  // Daily summary data
  int _calorieConsumed = 0;
  int _calorieTarget = 2000; // Default
  Map<String, double> _macroDistribution = {
    'protein': 0,
    'carbs': 0,
    'fats': 0,
  };

  // Page references - Using GlobalKey to access state
  final GlobalKey _foodLogKey = GlobalKey();
  final GlobalKey _insightsKey = GlobalKey();

  late List<Widget> _pages;

  final List<String> _titles = [
    'Dashboard',
    'Food Log',
    'NutriBot',
    'Profile',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize pages with keys
    _pages = [
      InsightsPage(key: _insightsKey),
      FoodLogPage(key: _foodLogKey),
      const AIDieticianPage(),
      const ProfilePage(),
    ];
    _loadUserData();
    _loadNutritionSummary();
  }

  Widget _buildAnalysisCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToAnalysisPage(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.analytics,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comprehensive Analysis',
                      style: AppTextStyles.subtitle1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Detailed insights into your nutrition patterns',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // In DashboardPage, _loadUserData method
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await getIt<AuthService>().getCurrentUser();
      if (mounted) {
        setState(() {
          _currentUser = user;

          // Update calorie target if available from user profile
          if (user?.nutritionProfile != null) {
            try {
              // Safely handle calorieTarget
              if (user!.nutritionProfile!.calorieTarget != null) {
                _calorieTarget = user.nutritionProfile!.calorieTarget!.toInt();
              }
            } catch (e) {
              print('Error processing nutrition profile data: $e');
              // Keep default value
            }
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToAnalysisPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => getIt<NutritionAnalysisBloc>(),
          child: ComprehensiveAnalysisPage(
            userId: _currentUser?.id ?? '',
          ),
        ),
      ),
    );
  }

  Future<void> _loadNutritionSummary() async {
    if (_currentUser == null) return;

    try {
      final mealService = getIt<MealService>();
      final today = DateTime.now();

      // Get meals for today - using positional parameters
      final meals =
          await mealService.getMealsByUserAndDate(_currentUser!.id, today);

      // Calculate nutrition summary manually
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (var meal in meals) {
        totalCalories += meal.totalCalories;

        for (var food in meal.foods) {
          totalProtein += food.protein ?? 0;
          totalCarbs += food.carbs ?? 0;
          totalFat += food.fat ?? 0;
        }
      }

      // Calculate percentages
      final totalMacros = totalProtein + totalCarbs + totalFat;
      double proteinPercentage =
          totalMacros > 0 ? totalProtein / totalMacros : 0.33;
      double carbsPercentage =
          totalMacros > 0 ? totalCarbs / totalMacros : 0.34;
      double fatsPercentage = totalMacros > 0 ? totalFat / totalMacros : 0.33;

      if (mounted) {
        setState(() {
          _calorieConsumed = totalCalories.round();
          _macroDistribution = {
            'protein': proteinPercentage,
            'carbs': carbsPercentage,
            'fats': fatsPercentage,
          };
        });
      }
    } catch (e) {
      print('Error loading nutrition summary: $e');
      // In case of error, set default values to ensure UI doesn't break
      if (mounted) {
        setState(() {
          _macroDistribution = {
            'protein': 0.33,
            'carbs': 0.34,
            'fats': 0.33,
          };
        });
      }
    }
  }

  Future<void> _refreshCurrentPage() async {
    // Reload nutrition summary
    await _loadNutritionSummary();

    // Trigger refresh for the current page
    if (_currentIndex == 0) {
      // For insights page, simply rebuild it
      setState(() {
        _pages[0] = InsightsPage(key: GlobalKey());
      });
    } else if (_currentIndex == 1) {
      // For food log page, rebuild it as well
      setState(() {
        _pages[1] = FoodLogPage(key: GlobalKey());
      });
    } else if (_currentIndex == 2) {
      // For NutriBot page, rebuild it as well
      setState(() {
        _pages[2] = const AIDieticianPage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _refreshCurrentPage,
          tooltip: 'Refresh data',
        ),
        actions: [
          // User greeting/avatar
          if (_currentUser != null)
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              // child: Center(
              //   child: Text(
              //     'Hi, ${_currentUser!.name.split(' ')[0]}',
              //     style: const TextStyle(
              //       fontWeight: FontWeight.w500,
              //       fontSize: 14,
              //     ),
              //   ),
              // ),
            ),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textMedium),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(LogoutEvent());
                      },
                      child: Text(
                        'Log Out',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                // User authenticated - reload data
                _loadUserData();
                _loadNutritionSummary();
              }
            },
          ),
          BlocListener<FoodLoggingBloc, FoodLoggingState>(
            listener: (context, state) {
              // Listen for food logging changes and update dashboard
              if (state is FoodItemAdded || 
                  state is FoodItemDeleted || 
                  state is MealDeleted ||
                  state is MealsLoaded) {
                _loadNutritionSummary();
              }
            },
          ),
        ],
        child: _isLoading
            ? _buildLoadingShimmer()
            : Column(
                children: [
                  // Show nutrition summary widget at the top if on dashboard
                  if (_currentIndex == 0) _buildNutritionSummary(),

                  // Add analysis card if on dashboard
                  if (_currentIndex == 0) _buildAnalysisCard(), // Add this line

                  // Main content
                  Expanded(
                    child: IndexedStack(
                      index: _currentIndex,
                      children: _pages,
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildNutritionSummary() {
    final caloriesRemaining = _calorieTarget - _calorieConsumed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side: Calorie info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Progress',
                  style: AppTextStyles.subtitle2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$_calorieConsumed',
                      style: AppTextStyles.headline6.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      ' / $_calorieTarget cal',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  caloriesRemaining > 0
                      ? '$caloriesRemaining cal remaining'
                      : 'Calorie goal reached',
                  style: AppTextStyles.caption.copyWith(
                    color: caloriesRemaining > 0
                        ? AppColors.textMedium
                        : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),

          // Right side: Macro distribution
          Container(
            width: 100,
            height: 30,
            child: Stack(
              children: [
                // Macro progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (_macroDistribution['protein']! * 100).round(),
                        child: Container(color: AppColors.protein),
                      ),
                      Expanded(
                        flex: (_macroDistribution['carbs']! * 100).round(),
                        child: Container(color: AppColors.carbs),
                      ),
                      Expanded(
                        flex: (_macroDistribution['fats']! * 100).round(),
                        child: Container(color: AppColors.fats),
                      ),
                    ],
                  ),
                ),

                // Text overlay
                Center(
                  child: Text(
                    'MACROS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading your nutrition data...',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
          ),
        ],
      ),
    );
  }
}

// Model to hold nutrition summary data
class NutritionSummary {
  final int totalCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatsGrams;
  final double proteinPercentage;
  final double carbsPercentage;
  final double fatsPercentage;

  NutritionSummary({
    required this.totalCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatsGrams,
    required this.proteinPercentage,
    required this.carbsPercentage,
    required this.fatsPercentage,
  });
}
