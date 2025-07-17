import 'dart:async';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/services/nutrition/food_database_service.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:whole_sight/core/theme/app_colors.dart';
import 'package:whole_sight/core/theme/app_text_styles.dart';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/presentation/pages/food_logging/add_meal_button.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_bloc.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_event.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_state.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:whole_sight/presentation/pages/food_logging/image_recognition_page.dart';
import 'package:whole_sight/presentation/pages/food_logging/barcode_scan_page.dart';
import 'package:whole_sight/services/auth/auth_service.dart';
import 'package:whole_sight/services/nutrition/usda_food_service.dart';

// Utility class for common functions
class FoodLogUtils {
  static String formatDate(DateTime date) {
    // If it's today
    if (DateTime.now().year == date.year &&
        DateTime.now().month == date.month &&
        DateTime.now().day == date.day) {
      return 'Today';
    }

    // If it's yesterday
    if (DateTime.now().subtract(const Duration(days: 1)).year == date.year &&
        DateTime.now().subtract(const Duration(days: 1)).month == date.month &&
        DateTime.now().subtract(const Duration(days: 1)).day == date.day) {
      return 'Yesterday';
    }

    // Otherwise, format as Month Day, Year
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String getCurrentTimeFormatted() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;

    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute.toString().padLeft(2, '0');

    return '$hour12:$minuteStr $period';
  }

  static String getMealTypeName(MealType type) {
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

  static String formatNutritionValue(dynamic value) {
    if (value == null) return '0.0';
    if (value is int) return value.toString();
    if (value is double) {
      // Show whole numbers without decimal if it's a whole number
      if (value == value.truncateToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }

  static String formatServingQuantity(dynamic value) {
    if (value == null) return '0';
    if (value is int) return value.toString();
    if (value is double) {
      // Show whole numbers without decimal if it's a whole number
      if (value == value.truncateToDouble()) {
        return value.toInt().toString();
      }
      return value.toStringAsFixed(1);
    }
    return value.toString();
  }
}

// Main Food Log Page
class FoodLogPage extends StatefulWidget {
  const FoodLogPage({super.key});

  @override
  State<FoodLogPage> createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage> {
  DateTime _selectedDate = DateTime.now();
  String _userId = '';
  bool _isLoading = false;
  bool _isAuthChecking = true; // New flag to track auth check status
  List<Map<String, dynamic>> _mealData = [];
  StreamSubscription<UserEntity?>? _authSubscription; // For auth state changes
  int _calorieTarget = 2000;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeAuth() async {
    setState(() {
      _isAuthChecking = true;
    });

    try {
      final authService = getIt<AuthService>();

      // First, try to get the current user directly
      final user = await authService.getCurrentUser();

      if (user != null) {
        if (mounted) {
          setState(() {
            _userId = user.id;
            _isAuthChecking = false;
            print('User authenticated directly: $_userId');
          });
          _loadMeals();
          _loadCalorieTarget(); // Add this line
        }
      } else {
        // If no user is found initially, check if authenticated
        final isAuth = await authService.isAuthenticated();

        if (isAuth) {
          // Try again after a short delay
          await Future.delayed(Duration(seconds: 1));
          final retryUser = await authService.getCurrentUser();

          if (retryUser != null && mounted) {
            setState(() {
              _userId = retryUser.id;
              _isAuthChecking = false;
              print('User authenticated after retry: $_userId');
            });
            _loadMeals();
            _loadCalorieTarget(); // Add this line
          } else {
            // Still no user after retry
            if (mounted) {
              setState(() {
                _isAuthChecking = false;
                print('No user found after retry');
              });
            }
          }
        } else {
          // Not authenticated
          if (mounted) {
            setState(() {
              _isAuthChecking = false;
              print('User not authenticated');
            });
          }
        }
      }

      // Set up auth state listener for future changes
      _subscribeToAuthChanges(authService);
    } catch (e) {
      print('Error in _initializeAuth: $e');
      if (mounted) {
        setState(() {
          _isAuthChecking = false;
        });
      }
    }
  }

  void _subscribeToAuthChanges(AuthService authService) {
    _authSubscription = authService.authStateChanges.listen((user) {
      if (user != null && mounted) {
        final newUserId = user.id;
        if (_userId != newUserId) {
          print('Auth state changed - new user: $newUserId');
          setState(() {
            _userId = newUserId;
          });
          _loadMeals();
          _loadCalorieTarget();
        }
      } else if (mounted) {
        setState(() {
          _userId = '';
          _mealData = [];
        });
        print('Auth state changed - no user');
      }
    });
  }

  void _loadMeals() {
    if (_userId.isNotEmpty) {
      print('Loading meals for user: $_userId on date: $_selectedDate');
      context.read<FoodLoggingBloc>().add(
            LoadMealsForDateEvent(
              date: _selectedDate,
              userId: _userId,
            ),
          );
    } else {
      print('Cannot load meals: User ID is empty');
    }
  }

  Future<void> _loadCalorieTarget() async {
    if (_userId.isEmpty) return;

    try {
      final target = await getUserCalorieTarget(_userId);
      if (mounted) {
        setState(() {
          _calorieTarget = target;
          print('Updated calorie target to: $_calorieTarget');
        });
      }
    } catch (e) {
      print('Error loading calorie target: $e');
    }
  }

  Future<num> _getCalorieTarget() async {
    if (_userId.isEmpty) return 2000; // Default

    try {
      final authService = getIt<AuthService>();
      final user = await authService.loadUserWithNutritionProfile(_userId);

      if (user == null || user.nutritionProfile == null) {
        return 2000; // Default
      }

      if (user.nutritionProfile!.calorieTarget != null) {
        final calorieTarget = user.nutritionProfile!.calorieTarget!;
        if (calorieTarget is int) {
          return calorieTarget;
        } else if (calorieTarget is double) {
          return calorieTarget.toInt();
        }
      }

      return 2000; // Default
    } catch (e) {
      print('Error getting calorie target: $e');
      return 2000; // Default
    }
  }

  Future<int> getUserCalorieTarget(String userId) async {
    try {
      // Default target if nothing else works
      int defaultTarget = 2000;

      // Get the auth service
      final authService = getIt<AuthService>();

      // Try to get user profile
      final user = await authService.loadUserWithNutritionProfile(userId);

      // If no user or no nutrition profile, return default
      if (user == null || user.nutritionProfile == null) {
        print(
            'No user or nutrition profile found, using default calorie target');
        return defaultTarget;
      }

      // If user has a calorie target in their profile, use that
      if (user.nutritionProfile!.calorieTarget != null) {
        // Convert to int regardless of whether it's int or double
        int target = user.nutritionProfile!.calorieTarget!.toInt();
        print('Using user\'s calorie target: $target');
        return target;
      }

      // Otherwise return default
      return defaultTarget;
    } catch (e) {
      print('Error getting user calorie target: $e');
      return 2000; // Default fallback
    }
  }

  // Confirm food item deletion
  Future<bool> _confirmDeleteFood(String foodName) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Food Item'),
              content: Text(
                  'Are you sure you want to remove "$foodName" from this meal?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'DELETE',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

// Confirm meal deletion
  void _confirmDeleteMeal(String mealId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Meal'),
          content:
              const Text('Are you sure you want to delete this entire meal?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMeal(mealId);
              },
              child: const Text(
                'DELETE',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

// Delete a food item from a meal
  void _deleteFoodFromMeal(String mealId, String foodId) {
    context.read<FoodLoggingBloc>().add(
          DeleteFoodFromMealEvent(
            mealId: mealId,
            foodId: foodId,
            userId: _userId,
            date: _selectedDate,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food item removed'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

// Delete an entire meal
  void _deleteMeal(String mealId) {
    context.read<FoodLoggingBloc>().add(
          DeleteMealEvent(
            mealId: mealId,
            userId: _userId,
            date: _selectedDate,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meal deleted'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Manual refresh option
  Future<void> _refreshData() async {
    if (_userId.isNotEmpty) {
      _loadMeals();
    } else {
      // Try to get user again
      final authService = getIt<AuthService>();
      final user = await authService.getCurrentUser();

      if (user != null && mounted) {
        setState(() {
          _userId = user.id;

          // Also update calorie target when refreshing user data
          if (user.nutritionProfile != null &&
              user.nutritionProfile!.calorieTarget != null) {
            try {
              final calorieTarget = user.nutritionProfile!.calorieTarget!;
              if (calorieTarget is int) {
                _calorieTarget = calorieTarget as int;
              } else if (calorieTarget is double) {
                _calorieTarget = calorieTarget.toInt();
              }
              print('Refresh: updated calorie target to $_calorieTarget');
            } catch (e) {
              print('Error converting calorie target during refresh: $e');
            }
          }
        });
        _loadMeals();
      }
    }
  }

  void _showAuthenticationRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Please sign in to view your meals'),
        action: SnackBarAction(
          label: 'SIGN IN',
          onPressed: () {
            // Navigate to your authentication screen
            // Navigator.pushNamed(context, '/login');
          },
        ),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _formatQuantityForDisplay(String quantity) {
    // Handle cases where quantity might have floating-point precision issues
    // e.g., "0.300000000000000041serving" -> "0.3 serving"
    
    if (quantity.isEmpty) return quantity;
    
    // First, try to extract number and unit using regex
    // This handles cases like "0.300000000000000041serving" where there's no space
    final regex = RegExp(r'^([0-9]*\.?[0-9]+)(.*)$');
    final match = regex.firstMatch(quantity);
    
    if (match != null) {
      final numberPart = match.group(1)!;
      final unitPart = match.group(2)!.trim();
      
      try {
        final number = double.parse(numberPart);
        final formattedNumber = FoodLogUtils.formatServingQuantity(number);
        return unitPart.isNotEmpty ? '$formattedNumber $unitPart' : formattedNumber;
      } catch (e) {
        // If parsing fails, return the original quantity
        return quantity;
      }
    }
    
    // Fallback to original logic for space-separated format
    final parts = quantity.split(' ');
    if (parts.isEmpty) return quantity;
    
    final numberPart = parts[0];
    final unitPart = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    
    try {
      final number = double.parse(numberPart);
      final formattedNumber = FoodLogUtils.formatServingQuantity(number);
      return unitPart.isNotEmpty ? '$formattedNumber $unitPart' : formattedNumber;
    } catch (e) {
      // If parsing fails, return the original quantity
      return quantity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FoodLoggingBloc, FoodLoggingState>(
      listener: (context, state) {
        if (state is FoodLoggingLoading) {
          setState(() {
            _isLoading = true;
          });
        } else if (state is MealsLoaded) {
          setState(() {
            _isLoading = false;
            _mealData = _convertMealsToMealData(state.meals);
            print('Meals loaded: ${_mealData.length} meals found');
          });
          _loadCalorieTarget(); // Add this line
        } else if (state is FoodItemAdded) {
          // No need to update state here as we're reloading meals
          print('Food item added to meal: ${state.mealId}');
          _loadMeals(); // Reload to show the updated meal
        } else if (state is FoodItemDeleted) {
          print('Food item deleted from meal: ${state.mealId}');
          _loadMeals(); // Reload to show the updated meal
        } else if (state is MealDeleted) {
          print('Meal deleted: ${state.mealId}');
          _loadMeals(); // Reload to show the removed meal
        } else if (state is FoodLoggingError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        // If still checking authentication
        if (_isAuthChecking) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Initializing...'),
                ],
              ),
            ),
          );
        }

        // If no user authenticated
        if (_userId.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Required',
                    style: AppTextStyles.headline6.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please sign in to view and track your meals',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to authentication screen
                      // Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('SIGN IN'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _initializeAuth,
                    child: const Text('RETRY'),
                  ),
                ],
              ),
            ),
          );
        }

        // User is authenticated, show food log UI
        return Scaffold(
          body: Column(
            children: [
              // Date selector
              _buildDateSelector(),

              // Daily summary
              _buildDailySummary(),

              // Refresh button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: _refreshData,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.refresh,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Refresh',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Meal list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _mealData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.restaurant,
                                  size: 64,
                                  color: AppColors.primary.withOpacity(0.5),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No meals yet',
                                  style: AppTextStyles.subtitle1.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add your first meal to get started',
                                  style: AppTextStyles.body1.copyWith(
                                    color: AppColors.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _mealData.length,
                            itemBuilder: (context, index) {
                              final meal = _mealData[index];
                              return _buildMealCard(meal);
                            },
                          ),
              ),
            ],
          ),
          floatingActionButton: AddMealButton(
            onMealTypeSelected: _handleAddMeal,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final MealType type = meal['type'] as MealType;
    final String time = meal['time'] as String;
    final List<Map<String, dynamic>> foods =
        (meal['foods'] as List<dynamic>).cast<Map<String, dynamic>>();
    final int totalCalories = meal['totalCalories'] as int;
    final String mealId = meal['id'] as String;

    IconData mealIcon;
    String mealName = FoodLogUtils.getMealTypeName(type);

    switch (type) {
      case MealType.breakfast:
        mealIcon = Icons.breakfast_dining;
        break;
      case MealType.lunch:
        mealIcon = Icons.lunch_dining;
        break;
      case MealType.dinner:
        mealIcon = Icons.dinner_dining;
        break;
      case MealType.snack:
        mealIcon = Icons.restaurant;
        break;
      default:
        mealIcon = Icons.restaurant;
    }

    return GestureDetector(
      onLongPress: () {
        _showMealOptions(context, meal);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 2,
        child: Column(
          children: [
            // Meal header (without delete button)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      mealIcon,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mealName,
                          style: AppTextStyles.subtitle1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          time,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$totalCalories',
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'calories',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                  // Remove the delete button from here
                ],
              ),
            ),

            // Rest of your meal card implementation remains the same
            // Food items with their own gestures...
            if (foods.isNotEmpty)
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: foods.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  color: AppColors.dividerLight,
                ),
                itemBuilder: (context, index) {
                  final food = foods[index];
                  final foodId = food['id'] ?? 'food_$index';

                  return GestureDetector(
                    onLongPress: () {
                      _showFoodItemOptions(context, food, mealId, foodId);
                    },
                    child: ListTile(
                      title: Text(
                        food['name'] as String,
                        style: AppTextStyles.body1,
                      ),
                      subtitle: Text(
                        _formatQuantityForDisplay(food['quantity'] as String),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                      trailing: Text(
                        '${food['calories']}',
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Remove the delete button from here
                    ),
                  );
                },
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No foods added yet',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textMedium,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            // Add food button
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: OutlinedButton.icon(
                onPressed: () => _showAddFoodBottomSheet(context, type, mealId),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Food'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMealOptions(BuildContext context, Map<String, dynamic> meal) {
    final String mealId = meal['id'] as String;
    final String mealName =
        FoodLogUtils.getMealTypeName(meal['type'] as MealType);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  mealName,
                  style: AppTextStyles.headline6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: const Text('Edit Meal'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add edit meal logic here
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Delete Meal'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMeal(mealId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined,
                      color: AppColors.secondary),
                  title: const Text('Share'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add share meal logic here
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFoodItemOptions(BuildContext context, Map<String, dynamic> food,
      String mealId, String foodId) {
    final String foodName = food['name'] as String;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  foodName,
                  style: AppTextStyles.headline6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: const Text('Edit Food Item'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add edit food logic here
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Delete Food Item'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteFood(foodName).then((confirmed) {
                      if (confirmed) {
                        _deleteFoodFromMeal(mealId, foodId);
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.favorite_border,
                      color: AppColors.tertiary),
                  title: const Text('Add to Favorites'),
                  onTap: () {
                    Navigator.pop(context);
                    // Add favorites logic here
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
              _loadMeals(); // Load meals for the new date
            },
          ),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    FoodLogUtils.formatDate(_selectedDate),
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: DateTime.now().difference(_selectedDate).inDays <= 0
                ? null
                : () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.add(const Duration(days: 1));
                    });
                    _loadMeals(); // Load meals for the new date
                  },
          ),
        ],
      ),
    );
  }

  // Update the _buildDailySummary method
  Widget _buildDailySummary() {
    // Calculate total calories
    int totalCalories = _mealData.fold(
      0,
      (sum, meal) => sum + (meal['totalCalories'] as int),
    );

    // Instead of the hardcoded 2000, we'll now use a variable
    // that can be updated through the authService

    // We'll load the target calories when the page is initialized
    // This will be done in initState or in the _loadMeals method

    final double percentage =
        _calorieTarget > 0 ? totalCalories / _calorieTarget : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Progress circle
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: percentage > 1.0 ? 1.0 : percentage,
                  backgroundColor: AppColors.dividerLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage > 1.0 ? AppColors.warning : AppColors.primary,
                  ),
                  strokeWidth: 8,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$totalCalories',
                        style: AppTextStyles.subtitle1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'cal',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Calorie details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Calorie Target',
                  style: AppTextStyles.subtitle2.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildCalorieDetail(
                      label: 'Goal',
                      value: '$_calorieTarget',
                      color: AppColors.primary,
                    ),
                    _buildCalorieDetail(
                      label: 'Food',
                      value: '$totalCalories',
                      color: AppColors.tertiary,
                    ),
                    _buildCalorieDetail(
                      label: 'Remaining',
                      value: '${_calorieTarget - totalCalories}',
                      color: AppColors.textDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieDetail({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAddMeal(MealType mealType) {
    // Check if this meal type already exists for today
    bool mealTypeExists = _mealData.any((meal) => meal['type'] == mealType);

    if (mealTypeExists) {
      // Show a message that this meal already exists
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${FoodLogUtils.getMealTypeName(mealType)} already exists for today'),
          backgroundColor: AppColors.warning,
        ),
      );
    } else {
      // Add a new empty meal through BLoC
      context.read<FoodLoggingBloc>().add(
            CreateMealEvent(
              mealType: mealType,
              userId: _userId,
              date: _selectedDate,
              time: FoodLogUtils.getCurrentTimeFormatted(),
            ),
          );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${FoodLogUtils.getMealTypeName(mealType)} added'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  // Convert Meal models to map structure for UI
  List<Map<String, dynamic>> _convertMealsToMealData(List<Meal> meals) {
    return meals.map((meal) {
      List<Map<String, dynamic>> foodsList = meal.foods
          .map((food) => {
                'name': food.name,
                'quantity': food.quantity,
                'calories': food.calories,
                'protein': food.protein,
                'carbs': food.carbs,
                'fat': food.fat,
              })
          .toList();

      return {
        'id': meal.id,
        'type': meal.type,
        'time': meal.time,
        'foods': foodsList,
        'totalCalories': meal.totalCalories,
      };
    }).toList();
  }

  void _showAddFoodBottomSheet(
      BuildContext context, MealType mealType, String mealId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return AddFoodBottomSheet(
          mealType: mealType,
          mealId: mealId,
          userId: _userId, // Pass this
          date: _selectedDate, // Pass this
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMeals();
    }
  }
}

class AddFoodBottomSheet extends StatefulWidget {
  final MealType mealType;
  final String mealId;
  final String userId; // Add this
  final DateTime date; // Add this

  const AddFoodBottomSheet({
    super.key,
    required this.mealType,
    required this.mealId,
    required this.userId, // Add this
    required this.date, // Add this
  });

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> {
  final _searchController = TextEditingController();
  int _selectedInputMethod = 0;
  final UsdaFoodService _usdaService = getIt<UsdaFoodService>();
  // Add these variables after the existing _inputMethods list
  final FoodDatabaseService _foodService = getIt<FoodDatabaseService>();
  bool _isSearching = false;
  Timer? _debounce;
// Note: Keep your existing _searchResults list for now

  final List<Map<String, dynamic>> _inputMethods = [
    {
      'title': 'Search',
      'icon': Icons.search,
      'description': 'Search our food database',
    },
    {
      'title': 'Scan',
      'icon': Icons.camera_alt_outlined,
      'description': 'Use camera to identify food',
    },
    {
      'title': 'Barcode',
      'icon': Icons.qr_code_scanner_outlined,
      'description': 'Scan product barcode',
    },
    {
      'title': 'Voice',
      'icon': Icons.mic_outlined,
      'description': 'Add food by voice',
    },
    {
      'title': 'Custom',
      'icon': Icons.add_circle_outline,
      'description': 'Create custom food',
    },
  ];

  // Sample search results for demonstration
  List<Map<String, dynamic>> _searchResults = [
    {
      'name': 'Apple',
      'calories': 95,
      'servingSize': '1 medium (182g)',
      'protein': 0.5,
      'carbs': 25.0,
      'fat': 0.3,
    },
    {
      'name': 'Banana',
      'calories': 105,
      'servingSize': '1 medium (118g)',
      'protein': 1.3,
      'carbs': 27.0,
      'fat': 0.4,
    },
    {
      'name': 'Chicken Breast',
      'calories': 165,
      'servingSize': '100g, cooked',
      'protein': 31.0,
      'carbs': 0.0,
      'fat': 3.6,
    },
    {
      'name': 'Salmon',
      'calories': 206,
      'servingSize': '100g, cooked',
      'protein': 22.0,
      'carbs': 0.0,
      'fat': 13.0,
    },
    {
      'name': 'Brown Rice',
      'calories': 215,
      'servingSize': '1 cup cooked (195g)',
      'protein': 5.0,
      'carbs': 45.0,
      'fat': 1.8,
    },
  ];

  Future<void> _searchFood(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Use the USDA service to search for foods
      final results = await _usdaService.searchFoods(query);

      // Transform FoodEntity objects to the map format your UI expects
      final formattedResults = results
          .map((food) => {
                'name': food.name,
                'calories': food.calories,
                'servingSize': '${food.servingSize} ${food.servingUnit}',
                'protein': food.macronutrients['protein'] ?? 0.0,
                'carbs': food.macronutrients['carbohydrates'] ?? 0.0,
                'fat': food.macronutrients['fat'] ?? 0.0,
              })
          .toList();

      setState(() {
        _searchResults = formattedResults;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching food: $e');

      // If USDA API fails, fall back to mock data
      final queryLower = query.toLowerCase();
      final filteredResults = _getMockFoodData()
          .where((food) =>
              food['name'].toString().toLowerCase().contains(queryLower))
          .toList();

      setState(() {
        _searchResults = filteredResults;
        _isSearching = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Using offline data (USDA API error)'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

// Add this method to the same class for mock data fallback:
  List<Map<String, dynamic>> _getMockFoodData() {
    return [
      {
        'name': 'Apple',
        'calories': 95,
        'servingSize': '1 medium (182g)',
        'protein': 0.5,
        'carbs': 25.0,
        'fat': 0.3,
      },
      {
        'name': 'Banana',
        'calories': 105,
        'servingSize': '1 medium (118g)',
        'protein': 1.3,
        'carbs': 27.0,
        'fat': 0.4,
      },
      // Add more mock food items as needed
    ];
  }

  void _addFoodToMeal(Map<String, dynamic> food) {
    final foodItem = FoodItem(
      name: food['name'] as String,
      quantity: food['servingSize'] as String,
      calories: (food['calories'] as num).toInt(),
      protein: food['protein'] as double?,
      carbs: food['carbs'] as double?,
      fat: food['fat'] as double?,
    );
    context.read<FoodLoggingBloc>().add(
          AddFoodToMealEvent(
            mealId: widget.mealId,
            foodItem: foodItem,
            userId: widget.userId, // Passed here
            date: widget.date, // Passed here
          ),
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${food['name']} added to meal'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _navigateToBarcodeScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScanPage(
          mealId: widget.mealId,
          mealType: widget.mealType,
          selectedDate: widget.date,
        ),
      ),
    );
  }

  Future<void> _scanBarcode(BuildContext context) async {
    try {
      // Start barcode scanning
      final barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666",
        "Cancel",
        true,
        ScanMode.BARCODE,
      );

      // If user cancels the scan, return
      if (barcodeScanRes == '-1') return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(width: 16),
              Text('Looking up product...'),
            ],
          ),
          duration:
              Duration(seconds: 30), // Longer duration for slow connections
          backgroundColor: AppColors.primary,
        ),
      );

      // Fetch food data from Open Food Facts
      final foundFood = await _getFoodFromBarcode(barcodeScanRes);

      // Hide loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (foundFood != null) {
        // Show product details in a dialog
        _showFoundFoodDialog(context, foundFood);
      } else {
        // Show not found message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Product not found in database. Try adding it manually or scan a different product.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'ADD MANUALLY',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _selectedInputMethod = 4; // Switch to custom food tab
                });
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Hide any existing snackbar first
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error scanning barcode: ${e.toString().substring(0, min(e.toString().length, 100))}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _showFoundFoodDialog(BuildContext context, Map<String, dynamic> food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Product Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              food['name'],
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Serving size: ${food['servingSize']}'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNutrientInfo('Calories', '${food['calories'].toInt()}'),
                _buildNutrientInfo('Protein', '${FoodLogUtils.formatNutritionValue(food['protein'])}g'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNutrientInfo('Carbs', '${FoodLogUtils.formatNutritionValue(food['carbs'])}g'),
                _buildNutrientInfo('Fat', '${FoodLogUtils.formatNutritionValue(food['fat'])}g'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _addFoodToMeal(food);
            },
            child: Text('ADD TO MEAL'),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getFoodFromBarcode(String barcode) async {
    try {
      // Make API request to Open Food Facts
      final response = await http.get(
        Uri.parse(
            'https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if product was found
        if (data['status'] == 1) {
          final product = data['product'];
          final nutriments = product['nutriments'] ?? {};

          // Extract relevant nutrition information
          return {
            'name': product['product_name'] ?? 'Unknown Product',
            'calories': (nutriments['energy-kcal_100g'] ?? 0).toDouble(),
            'servingSize': product['serving_size'] ?? '100g',
            'protein': (nutriments['proteins_100g'] ?? 0).toDouble(),
            'carbs': (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
            'fat': (nutriments['fat_100g'] ?? 0).toDouble(),
          };
        }
      }

      // If we get here, the product wasn't found or there was an error
      return null;
    } catch (e) {
      print('Error fetching food data: $e');
      return null;
    }
  }

  Widget _buildNutrientInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMedium,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientBadge(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String mealName = FoodLogUtils.getMealTypeName(widget.mealType);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Add Food to $mealName',
                style: AppTextStyles.headline6.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Input method tabs
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _inputMethods.length,
              itemBuilder: (context, index) {
                final method = _inputMethods[index];
                final isSelected = _selectedInputMethod == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedInputMethod = index;
                    });
                  },
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.dividerLight,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          method['icon'] as IconData,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMedium,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          method['title'] as String,
                          style: AppTextStyles.subtitle2.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textDark,
                          ),
                        ),
                        Text(
                          method['description'] as String,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMedium,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Content based on selected input method
          Expanded(
            child: _buildInputMethodContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputMethodContent() {
    switch (_selectedInputMethod) {
      case 0: // Search
        return _buildSearchContent();
      case 1: // Camera
        return _buildCameraContent();
      case 2: // Barcode
        return _buildBarcodeContent();
      case 3: // Voice
        return _buildVoiceContent();
      case 4: // Custom
        return _buildCustomContent();
      default:
        return _buildSearchContent();
    }
  }

  Widget _buildSearchContent() {
    return Column(
      children: [
        // Search field
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search for a food',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 500), () {
              _searchFood(value);
            });
          },
        ),

        const SizedBox(height: 16),

        // Search results
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
                  ? _searchController.text.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 64,
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Search for food items',
                                style: AppTextStyles.subtitle1.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter a food name to search',
                                style: AppTextStyles.body1.copyWith(
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.no_food,
                                size: 64,
                                color: AppColors.warning.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No results found',
                                style: AppTextStyles.subtitle1.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try a different search term',
                                style: AppTextStyles.body1.copyWith(
                                  color: AppColors.textMedium,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // Switch to custom food input
                                  setState(() {
                                    _selectedInputMethod = 4;
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Add Custom Food'),
                              ),
                            ],
                          ),
                        )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final food = _searchResults[index];
                        return _buildFoodResultItem(food);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFoodResultItem(Map<String, dynamic> food) {
    return InkWell(
      onTap: () {
        // Optional: Handle tap on the entire item if needed
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left section with food icon
            Icon(
              Icons.restaurant,
              color: AppColors.primary,
              size: 20,
            ),

            SizedBox(width: 12),

            // Middle section with food details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  Text(
                    food['name'] as String,
                    style: AppTextStyles.subtitle2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Serving size
                  Text(
                    food['servingSize'] as String,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),

                  SizedBox(height: 8),

                  // Make the nutrients row scrollable
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildNutrientBadge(
                            'Cal', '${food['calories']}', AppColors.primary),
                        SizedBox(width: 16),
                        _buildNutrientBadge(
                            'C', '${FoodLogUtils.formatNutritionValue(food['carbs'])}g', AppColors.carbs),
                        SizedBox(width: 16),
                        _buildNutrientBadge(
                            'P', '${FoodLogUtils.formatNutritionValue(food['protein'])}g', AppColors.protein),
                        SizedBox(width: 16),
                        _buildNutrientBadge(
                            'F', '${FoodLogUtils.formatNutritionValue(food['fat'])}g', AppColors.fats),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Right section with add button
            Container(
              width: 40,
              height: 40,
              child: Material(
                color: AppColors.primary,
                shape: CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    _addFoodToMeal(food);
                  },
                  child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update the _buildCameraContent method in _AddFoodBottomSheetState class

  Widget _buildCameraContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Take a Photo of Your Food',
            style: AppTextStyles.headline6.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Our AI will analyze the image and identify the food items',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Close the bottom sheet
              Navigator.pop(context);

              // Navigate to the image recognition page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImageRecognitionPage(
                    userId: widget.userId,
                    mealId: widget.mealId,
                    mealType: widget.mealType,
                    date: widget.date,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Open Camera'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.qr_code_scanner_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Scan Product Barcode',
            style: AppTextStyles.headline6.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Quickly log packaged foods by scanning the barcode',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToBarcodeScan(context),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Barcode'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Add Food by Voice',
            style: AppTextStyles.headline6.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Describe your meal using natural language',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () {
              // In a real app, this would start voice recording
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap to Speak',
            style: AppTextStyles.subtitle1.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Custom Food',
            style: AppTextStyles.headline6.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Food name
          TextField(
            decoration: InputDecoration(
              labelText: 'Food Name',
              hintText: 'e.g., Homemade Granola',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Serving size and unit
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Serving Size',
                    hintText: 'e.g., 100',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: 'g',
                  items: const [
                    DropdownMenuItem(
                      value: 'g',
                      child: Text('g'),
                    ),
                    DropdownMenuItem(
                      value: 'ml',
                      child: Text('ml'),
                    ),
                    DropdownMenuItem(
                      value: 'oz',
                      child: Text('oz'),
                    ),
                    DropdownMenuItem(
                      value: 'cup',
                      child: Text('cup'),
                    ),
                    DropdownMenuItem(
                      value: 'tbsp',
                      child: Text('tbsp'),
                    ),
                    DropdownMenuItem(
                      value: 'tsp',
                      child: Text('tsp'),
                    ),
                  ],
                  onChanged: (value) {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Calories
          TextField(
            decoration: InputDecoration(
              labelText: 'Calories',
              hintText: 'per serving',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 24),

          // Macronutrients header
          Text(
            'Macronutrients (g)',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Protein, Carbs, Fat
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Protein',
                    suffixText: 'g',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Carbs',
                    suffixText: 'g',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Fat',
                    suffixText: 'g',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Fiber and Sugar
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Fiber',
                    suffixText: 'g',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Sugar',
                    suffixText: 'g',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Empty space for alignment
            ],
          ),

          const SizedBox(height: 24),

          // Food categories
          Text(
            'Categories',
            style: AppTextStyles.subtitle1.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip('Fruits', true),
              _buildCategoryChip('Vegetables', false),
              _buildCategoryChip('Protein', false),
              _buildCategoryChip('Dairy', false),
              _buildCategoryChip('Grains', false),
              _buildCategoryChip('Snacks', false),
              _buildCategoryChip('Beverages', false),
              _buildCategoryChip('Desserts', false),
            ],
          ),

          const SizedBox(height: 32),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Create a new food item and add it to the meal
                final customFood = {
                  'name': 'Custom Food', // In a real app, get from TextField
                  'calories': 200.0, // In a real app, get from TextField
                  'servingSize': '100g', // In a real app, get from fields
                  'protein': 10.0, // In a real app, get from TextField
                  'carbs': 20.0, // In a real app, get from TextField
                  'fat': 15.0, // In a real app, get from TextField
                };

                _addFoodToMeal(customFood);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Save Custom Food',
                style: AppTextStyles.button.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (value) {
        // In a real app, this would toggle the category
        setState(() {});
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textDark,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.dividerLight,
        ),
      ),
    );
  }
}
