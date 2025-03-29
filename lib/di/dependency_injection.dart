import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whole_sight/core/network/network_info.dart';
import 'package:whole_sight/core/services/local_storage_service.dart';
import 'package:whole_sight/data/datasources/local/food_local_data_source.dart';
import 'package:whole_sight/data/datasources/local/user_local_data_source.dart';
import 'package:whole_sight/data/datasources/remote/food_remote_data_source.dart';
import 'package:whole_sight/data/datasources/remote/user_remote_data_source.dart';
import 'package:whole_sight/data/repositories/food_repository_impl.dart';
import 'package:whole_sight/data/repositories/user_repository_impl.dart';
import 'package:whole_sight/domain/repositories/food_repository.dart';
import 'package:whole_sight/domain/repositories/user_repository.dart';
import 'package:whole_sight/domain/usecases/food/get_food_recommendations.dart';
import 'package:whole_sight/domain/usecases/food/log_food_item.dart';
import 'package:whole_sight/domain/usecases/food/search_food_database.dart';
import 'package:whole_sight/domain/usecases/user/create_user_profile.dart';
import 'package:whole_sight/domain/usecases/user/get_nutrition_insights.dart';
import 'package:whole_sight/domain/usecases/user/update_user_goals.dart';
import 'package:whole_sight/presentation/bloc/auth/auth_bloc.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_bloc.dart';
import 'package:whole_sight/presentation/bloc/nutrition/nutrition_bloc.dart';
import 'package:whole_sight/services/ai/gemini_service.dart';
import 'package:whole_sight/services/ai/image_recognition_service.dart';
import 'package:whole_sight/services/ai/recommendation_service.dart';
import 'package:whole_sight/services/auth/auth_service.dart';
import 'package:whole_sight/services/firebase/firestore_service.dart';
import 'package:whole_sight/services/nutrition/food_database_service.dart';
import 'package:whole_sight/services/nutrition/nutrition_calculator_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:whole_sight/services/nutrition/meal_service.dart';
import 'package:whole_sight/presentation/bloc/food_logging/food_logging_bloc.dart';
import 'package:whole_sight/services/nutrition/usda_food_service.dart';
import 'package:whole_sight/domain/usecases/user/get_comprehensive_nutrition_analysis.dart';
import 'package:whole_sight/presentation/bloc/analysis/nutrition_analysis_bloc.dart';

final getIt = GetIt.instance;

Future<void> initDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  final connectivity = Connectivity();
  getIt.registerSingleton<Connectivity>(connectivity);

  getIt.registerLazySingleton(() => GetComprehensiveNutritionAnalysis(
        foodRepository: getIt<FoodRepository>(),
        userRepository: getIt<UserRepository>(),
        calculatorService: getIt<NutritionCalculatorService>(),
      ));

// Add to the BLoCs section
  getIt.registerFactory(
    () => NutritionAnalysisBloc(
      getAnalysis: getIt<GetComprehensiveNutritionAnalysis>(),
    ),
  );

  // Core
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<
        Connectivity>()), // Fixed: removed named parameter, using positional
  );
  getIt.registerLazySingleton<UsdaFoodService>(
    () => UsdaFoodService(), // Replace with your actual API key
  );
  getIt.registerLazySingleton<LocalStorageService>(
    () =>
        LocalStorageServiceImpl(sharedPreferences: getIt<SharedPreferences>()),
  );

  // AI Services
  // Note: You'll need to replace 'YOUR_API_KEY' with your actual Gemini API key
  // In production, this should be securely stored and accessed
  final model = GenerativeModel(
    model: 'gemini-pro',
    apiKey: 'YOUR_API_KEY',
  );

  getIt.registerSingleton<GenerativeModel>(model);

  getIt.registerLazySingleton<GeminiService>(
    () => GeminiServiceImpl(model: getIt<GenerativeModel>()),
  );

  getIt.registerLazySingleton<ImageRecognitionService>(
    () => ImageRecognitionServiceImpl(),
  );

  getIt.registerLazySingleton<RecommendationService>(
    () => RecommendationServiceImpl(geminiService: getIt<GeminiService>()),
  );

  // Firebase Services
  getIt.registerLazySingleton<FirestoreService>(
    () => FirestoreServiceImpl(),
  );

  getIt.registerLazySingleton<AuthService>(
    () => AuthServiceImpl(),
  );

  // Nutrition Services
  getIt.registerLazySingleton<FoodDatabaseService>(
    () => FoodDatabaseServiceImpl(firestoreService: getIt<FirestoreService>()),
  );

  getIt.registerLazySingleton<NutritionCalculatorService>(
    () => NutritionCalculatorServiceImpl(),
  );

  // Data Sources
  getIt.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(
        localStorageService: getIt<LocalStorageService>()),
  );

  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(firestoreService: getIt<FirestoreService>()),
  );

  getIt.registerLazySingleton<FoodLocalDataSource>(
    () => FoodLocalDataSourceImpl(
        localStorageService: getIt<LocalStorageService>()),
  );

  getIt.registerLazySingleton<FoodRemoteDataSource>(
    () => FoodRemoteDataSourceImpl(
      firestoreService: getIt<FirestoreService>(),
      recommendationService: getIt<RecommendationService>(),
    ),
  );

  // Repositories
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      localDataSource: getIt<UserLocalDataSource>(),
      remoteDataSource: getIt<UserRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );

  getIt.registerLazySingleton<FoodRepository>(
    () => FoodRepositoryImpl(
      localDataSource: getIt<FoodLocalDataSource>(),
      remoteDataSource: getIt<FoodRemoteDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
      mealService: getIt<MealService>(),
    ),
  );

  // Use Cases
  // User
  getIt.registerLazySingleton(() => CreateUserProfile(getIt<UserRepository>()));
  getIt.registerLazySingleton(
      () => GetNutritionInsights(getIt<UserRepository>()));
  getIt.registerLazySingleton(() => UpdateUserGoals(getIt<UserRepository>()));

  // Food
  getIt.registerLazySingleton<MealService>(
    () => MealService(getIt<FirestoreService>()),
  );
  getIt.registerLazySingleton(
      () => GetFoodRecommendations(getIt<FoodRepository>()));
  getIt.registerLazySingleton(() => LogFoodItem(getIt<FoodRepository>()));
  getIt
      .registerLazySingleton(() => SearchFoodDatabase(getIt<FoodRepository>()));

  // BLoCs
  getIt.registerFactory(
    () => AuthBloc(
      authService: getIt<AuthService>(),
      createUserProfile: getIt<CreateUserProfile>(),
    ),
  );

  getIt.registerFactory<FoodLoggingBloc>(
    () => FoodLoggingBloc(
      logFoodItem: getIt<LogFoodItem>(),
      searchFoodDatabase: getIt<SearchFoodDatabase>(),
      imageRecognitionService: getIt<ImageRecognitionService>(),
      foodRepository: getIt<FoodRepository>(),
    ),
  );

  getIt.registerFactory(
    () => NutritionBloc(
      getNutritionInsights: getIt<GetNutritionInsights>(),
      getFoodRecommendations: getIt<GetFoodRecommendations>(),
      recommendationService: getIt<RecommendationService>(),
    ),
  );
}
