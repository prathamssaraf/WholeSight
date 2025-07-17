import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/repositories/food_repository.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:whole_sight/domain/usecases/food/log_food_item.dart';
import 'package:whole_sight/domain/usecases/food/search_food_database.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_event.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_state.dart';
import 'package:whole_sight/services/ai/image_recognition_service.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_state.dart'
    as state_lib;
import 'package:whole_sight/presentation/pages/food_logging/food_log_page.dart';

// BLoC
class FoodLoggingBloc extends Bloc<FoodLoggingEvent, FoodLoggingState> {
  final LogFoodItem logFoodItem;
  final SearchFoodDatabase searchFoodDatabase;
  final ImageRecognitionService imageRecognitionService;
  final FoodRepository foodRepository;

  FoodLoggingBloc({
    required this.logFoodItem,
    required this.searchFoodDatabase,
    required this.imageRecognitionService,
    required this.foodRepository,
  }) : super(FoodLoggingInitial()) {
    on<SearchFoodsEvent>(_onSearchFoods);
    on<RecognizeFoodFromImageEvent>(_onRecognizeFoodFromImage);
    on<LogFoodEvent>(_onLogFood);
    on<AddCustomFoodEvent>(_onAddCustomFood);
    on<LoadMealsForDateEvent>(_onLoadMealsForDate);
    on<CreateMealEvent>(_onCreateMeal);
    on<AddFoodToMealEvent>(_onAddFoodToMeal);
    on<DeleteMealEvent>(_onDeleteMeal);
    on<DeleteFoodFromMealEvent>(_onDeleteFoodFromMeal);
    on<ScanBarcodeEvent>(_onScanBarcode);
  }

  Future<void> _onSearchFoods(
    SearchFoodsEvent event,
    Emitter<FoodLoggingState> emit,
  ) async {
    emit(FoodLoggingLoading());

    final params = SearchFoodDatabaseParams(
      query: event.query,
      categories: event.categories,
    );

    final result = await searchFoodDatabase(params);

    result.fold(
      (failure) => emit(FoodLoggingError(message: failure.toString())),
      (foods) => emit(FoodSearchSuccess(foods: foods)),
    );
  }

  Future<void> _onRecognizeFoodFromImage(
    RecognizeFoodFromImageEvent event,
    Emitter<FoodLoggingState> emit,
  ) async {
    emit(FoodLoggingLoading());

    try {
      // Convert List<int> to Uint8List
      final Uint8List uint8List = Uint8List.fromList(event.imageBytes);

      final recognizedFoods =
          await imageRecognitionService.recognizeFoodFromBytes(
        uint8List,
      );

      emit(FoodRecognitionSuccess(recognizedFoods: recognizedFoods));
    } catch (e) {
      emit(FoodLoggingError(
          message: 'Failed to recognize food: ${e.toString()}'));
    }
  }

  Future<void> _onLogFood(
    LogFoodEvent event,
    Emitter<FoodLoggingState> emit,
  ) async {
    emit(FoodLoggingLoading());

    final params = LogFoodItemParams(
      userId: event.userId,
      food: event.food,
      mealType: event.mealType,
      quantity: event.quantity,
      timestamp: DateTime.now(),
      notes: event.notes,
    );

    final result = await logFoodItem(params);

    result.fold(
      (failure) => emit(FoodLoggingError(message: failure.toString())),
      (_) => emit(FoodLoggingSuccess(
        mealType: event.mealType,
        food: event.food,
        quantity: event.quantity,
      )),
    );
  }

  Future<void> _onAddCustomFood(
    AddCustomFoodEvent event,
    Emitter<FoodLoggingState> emit,
  ) async {
    emit(FoodLoggingLoading());

    final params = LogFoodItemParams(
      userId: event.userId,
      food: event.food,
      isCustomFood: true,
    );

    final result = await logFoodItem(params);

    result.fold(
      (failure) => emit(FoodLoggingError(message: failure.toString())),
      (_) => emit(CustomFoodAddedSuccess(food: event.food)),
    );
  }

  Future<void> _onLoadMealsForDate(
    LoadMealsForDateEvent event,
    Emitter<FoodLoggingState> emit,
  ) async {
    emit(FoodLoggingLoading());
    try {
      final result = await foodRepository.getMealsByUserAndDate(
        event.userId,
        event.date,
      );

      result.fold(
        (failure) => emit(FoodLoggingError(message: failure.toString())),
        (meals) => emit(MealsLoaded(meals: meals, date: event.date)),
      );
    } catch (e) {
      emit(FoodLoggingError(message: 'Failed to load meals: ${e.toString()}'));
    }
  }

  Future<void> _onCreateMeal(
    CreateMealEvent event,
    Emitter<FoodLoggingState> emit,
  ) async {
    emit(FoodLoggingLoading());
    try {
      final result = await foodRepository.createEmptyMeal(
        event.mealType,
        event.userId,
        event.date,
        event.time,
      );

      result.fold(
        (failure) => emit(FoodLoggingError(message: failure.toString())),
        (mealId) {
          // Use MealAdded state from food_logging_state.dart
          emit(MealAdded(mealId: mealId, type: event.mealType));

          // Reload meals for the date
          add(LoadMealsForDateEvent(date: event.date, userId: event.userId));
        },
      );
    } catch (e) {
      emit(FoodLoggingError(message: 'Failed to create meal: ${e.toString()}'));
    }
  }

  Future<void> _onAddFoodToMeal(
    AddFoodToMealEvent event,
    Emitter<FoodLoggingState> emit,
  ) async {
    emit(FoodLoggingLoading());
    try {
      final result = await foodRepository.addFoodToMeal(
        event.mealId,
        event.foodItem,
      );

      result.fold(
        (failure) => emit(FoodLoggingError(message: failure.toString())),
        (_) {
          // Emit the FoodItemAdded state first
          emit(FoodItemAdded(mealId: event.mealId, foodItem: event.foodItem));

          // Then always reload meals
          add(LoadMealsForDateEvent(date: event.date, userId: event.userId));
        },
      );
    } catch (e) {
      emit(FoodLoggingError(
          message: 'Failed to add food to meal: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteMeal(
    DeleteMealEvent event,
    Emitter<FoodLoggingState> emit,
  ) async {
    emit(FoodLoggingLoading());
    try {
      final result = await foodRepository.deleteMeal(event.mealId);

      result.fold(
        (failure) => emit(FoodLoggingError(message: failure.toString())),
        (_) {
          // Use MealDeleted state from food_logging_state.dart
          // This is the correct way to create and emit a MealDeleted state
          emit(state_lib.MealDeleted(mealId: event.mealId));

          // Reload meals for the date
          add(LoadMealsForDateEvent(date: event.date, userId: event.userId));
        },
      );
    } catch (e) {
      emit(FoodLoggingError(message: 'Failed to delete meal: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteFoodFromMeal(
    DeleteFoodFromMealEvent event,
    Emitter<FoodLoggingState> emit,
  ) async {
    emit(FoodLoggingLoading());
    try {
      final result = await foodRepository.removeFoodFromMeal(
        event.mealId,
        event.foodId,
      );

      result.fold(
        (failure) => emit(FoodLoggingError(message: failure.toString())),
        (_) {
          // Emit the FoodItemDeleted state first
          emit(FoodItemDeleted(mealId: event.mealId, foodId: event.foodId));

          // Then reload meals
          add(LoadMealsForDateEvent(date: event.date, userId: event.userId));
        },
      );
    } catch (e) {
      emit(FoodLoggingError(
          message: 'Failed to remove food from meal: ${e.toString()}'));
    }
  }

  Future<void> _onScanBarcode(
    ScanBarcodeEvent event,
    Emitter<FoodLoggingState> emit,
  ) async {
    emit(FoodLoggingLoading());
    
    try {
      // Fetch product data from Open Food Facts API
      final productData = await _fetchProductFromBarcode(event.barcode);
      
      if (productData == null) {
        emit(FoodLoggingError(message: 'Product not found in database'));
        return;
      }
      
      // Create FoodEntity from product data
      final foodEntity = FoodEntity(
        id: 'scanned_${event.barcode}',
        name: productData['name'] ?? 'Unknown Product',
        description: productData['brand'] ?? '',
        servingSize: 100.0, // Base serving size from Open Food Facts
        servingUnit: 'g',
        calories: (productData['calories'] as num).toDouble(),
        macronutrients: {
          'protein': (productData['protein'] as num).toDouble(),
          'carbs': (productData['carbs'] as num).toDouble(),
          'fat': (productData['fat'] as num).toDouble(),
        },
        micronutrients: {},
        allergens: [],
        categories: [],
        barcode: event.barcode,
        brand: productData['brand'],
        isVerified: false,
        isUserCreated: false,
        createdAt: DateTime.now(),
      );

      // Calculate nutrition values based on selected servings
      final scaledCalories = (productData['calories'] as num).toDouble() * event.servings;
      final scaledProtein = (productData['protein'] as num).toDouble() * event.servings;
      final scaledCarbs = (productData['carbs'] as num).toDouble() * event.servings;
      final scaledFat = (productData['fat'] as num).toDouble() * event.servings;

      // Create FoodItem with custom serving size
      final foodItem = FoodItem(
        name: productData['name'] ?? 'Unknown Product',
        quantity: '${FoodLogUtils.formatServingQuantity(event.servings)} ${event.servingUnit}',
        calories: scaledCalories.toInt(),
        protein: scaledProtein,
        carbs: scaledCarbs,
        fat: scaledFat,
      );

      // Add to meal
      final result = await foodRepository.addFoodToMeal(event.mealId, foodItem);
      
      result.fold(
        (failure) => emit(FoodLoggingError(message: failure.toString())),
        (_) {
          emit(FoodItemAdded(mealId: event.mealId, foodItem: foodItem));
          // Reload meals for the date
          add(LoadMealsForDateEvent(date: event.date, userId: event.userId));
        },
      );
    } catch (e) {
      emit(FoodLoggingError(message: 'Failed to scan barcode: ${e.toString()}'));
    }
  }

  Future<Map<String, dynamic>?> _fetchProductFromBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final product = data['product'];
          final nutriments = product['nutriments'] ?? {};

          return {
            'name': product['product_name'] ?? 'Unknown Product',
            'calories': (nutriments['energy-kcal_100g'] ?? 0).toDouble(),
            'protein': (nutriments['proteins_100g'] ?? 0).toDouble(),
            'carbs': (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
            'fat': (nutriments['fat_100g'] ?? 0).toDouble(),
            'brand': product['brands'] ?? '',
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
