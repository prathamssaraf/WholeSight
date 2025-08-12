import 'package:dartz/dartz.dart';
import 'package:whole_sight/core/errors/exceptions.dart';
import 'package:whole_sight/core/errors/failures.dart';
import 'package:whole_sight/core/network/network_info.dart';
import 'package:whole_sight/data/datasources/local/food_local_data_source.dart';
import 'package:whole_sight/data/datasources/remote/food_remote_data_source.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/domain/entities/meal_entity.dart';
import 'package:whole_sight/domain/repositories/food_repository.dart';
import 'package:whole_sight/data/models/food_model.dart';
import 'package:whole_sight/data/models/meal.dart';
import 'package:whole_sight/services/nutrition/meal_service.dart';

class FoodRepositoryImpl implements FoodRepository {
  final FoodLocalDataSource localDataSource;
  final FoodRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final MealService mealService;

  FoodRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.mealService,
  });

  @override
  Future<Either<Failure, List<FoodEntity>>> searchFoods({
    required String query,
    List<String>? categories,
    int limit = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final foodModels = await remoteDataSource.searchFoods(
          query: query,
          categories: categories,
          limit: limit,
        );

        // Convert FoodModel list to FoodEntity list
        final foodEntities =
            foodModels.map((foodModel) => foodModel.toEntity()).toList();

        return Right(foodEntities);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final cachedFoodModels = await localDataSource.searchCachedFoods(
          query: query,
          categories: categories,
          limit: limit,
        );

        // Convert cached FoodModel list to FoodEntity list
        final cachedFoodEntities =
            cachedFoodModels.map((foodModel) => foodModel.toEntity()).toList();

        return Right(cachedFoodEntities);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, FoodEntity>> getFoodById(String id) async {
    if (await networkInfo.isConnected) {
      try {
        final foodModel = await remoteDataSource.getFoodById(id);
        localDataSource.cacheFood(foodModel);
        // Convert FoodModel to FoodEntity
        return Right(foodModel.toEntity());
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final cachedFoodModel = await localDataSource.getCachedFoodById(id);
        // Convert cached FoodModel to FoodEntity
        return Right(cachedFoodModel.toEntity());
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, FoodEntity?>> getFoodByBarcode(String barcode) async {
    if (await networkInfo.isConnected) {
      try {
        final foodModel = await remoteDataSource.getFoodByBarcode(barcode);
        if (foodModel != null) {
          localDataSource.cacheFood(foodModel);
          // Convert FoodModel to FoodEntity
          return Right(foodModel.toEntity());
        }
        // Return null if no food found
        return const Right(null);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final cachedFoodModel =
            await localDataSource.getCachedFoodByBarcode(barcode);
        // Convert cached FoodModel to FoodEntity (if not null)
        return Right(cachedFoodModel?.toEntity());
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<FoodEntity>>> getRecentFoods({
    required String userId,
    int limit = 10,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final foodModels = await remoteDataSource.getRecentFoods(
          userId: userId,
          limit: limit,
        );
        // Convert FoodModel list to FoodEntity list
        final foodEntities =
            foodModels.map((foodModel) => foodModel.toEntity()).toList();
        return Right(foodEntities);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final cachedFoodModels = await localDataSource.getCachedRecentFoods(
          userId: userId,
          limit: limit,
        );
        // Convert cached FoodModel list to FoodEntity list
        final cachedFoodEntities =
            cachedFoodModels.map((foodModel) => foodModel.toEntity()).toList();
        return Right(cachedFoodEntities);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<FoodEntity>>> getFavoriteFoods({
    required String userId,
    int limit = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final foodModels = await remoteDataSource.getFavoriteFoods(
          userId: userId,
          limit: limit,
        );
        // Convert FoodModel list to FoodEntity list
        final foodEntities =
            foodModels.map((foodModel) => foodModel.toEntity()).toList();
        return Right(foodEntities);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final cachedFoodModels = await localDataSource.getCachedFavoriteFoods(
          userId: userId,
          limit: limit,
        );
        // Convert cached FoodModel list to FoodEntity list
        final cachedFoodEntities =
            cachedFoodModels.map((foodModel) => foodModel.toEntity()).toList();
        return Right(cachedFoodEntities);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, void>> addToFavorites({
    required String userId,
    required String foodId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addToFavorites(
          userId: userId,
          foodId: foodId,
        );
        return const Right(null);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addFoodToFavorites({
    required String userId,
    required Map<String, dynamic> foodData,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.addFoodToFavorites(
          userId: userId,
          foodData: foodData,
        );
        return const Right(null);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> removeFromFavorites({
    required String userId,
    required String foodId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.removeFromFavorites(
          userId: userId,
          foodId: foodId,
        );
        return const Right(null);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, bool>> isFavorite({
    required String userId,
    required String foodId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final isFav = await remoteDataSource.isFavorite(
          userId: userId,
          foodId: foodId,
        );
        return Right(isFav);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, String>> addCustomFood({
    required FoodEntity food,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final foodModel = FoodModel.fromEntity(food);

        final foodId = await remoteDataSource.addCustomFood(
          food: foodModel,
          userId: userId,
        );
        // Cache the newly added food
        localDataSource.cacheFood(foodModel);
        return Right(foodId);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateCustomFood({
    required FoodEntity food,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        // Convert FoodEntity to FoodModel
        final foodModel = FoodModel.fromEntity(food);

        await remoteDataSource.updateCustomFood(
          food: foodModel,
          userId: userId,
        );

        // Update the cached food
        localDataSource.cacheFood(foodModel);

        return const Right(null);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomFood({
    required String foodId,
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteCustomFood(
          foodId: foodId,
          userId: userId,
        );
        // Remove from cache
        localDataSource.removeFood(foodId);
        return const Right(null);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<FoodEntity>>> getFoodRecommendations({
    required String userId,
    int limit = 5,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final recommendationModels =
            await remoteDataSource.getFoodRecommendations(
          userId: userId,
          limit: limit,
        );
        // Convert FoodModel list to FoodEntity list
        final recommendationEntities = recommendationModels
            .map((foodModel) => foodModel.toEntity())
            .toList();
        return Right(recommendationEntities);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final cachedRecommendationModels =
            await localDataSource.getCachedFoodRecommendations(
          userId: userId,
          limit: limit,
        );
        // Convert cached FoodModel list to FoodEntity list
        final cachedRecommendationEntities = cachedRecommendationModels
            .map((foodModel) => foodModel.toEntity())
            .toList();
        return Right(cachedRecommendationEntities);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, List<Meal>>> getMealsByUserAndDate(
      String userId, DateTime date) async {
    if (await networkInfo.isConnected) {
      try {
        final meals = await mealService.getMealsByUserAndDate(userId, date);
        return Right(meals);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      // For offline mode, we could implement local caching of meals if needed
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, String>> addMeal(Meal meal) async {
    if (await networkInfo.isConnected) {
      try {
        final mealId = await mealService.addMeal(meal);
        return Right(mealId);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateMeal(Meal meal) async {
    if (await networkInfo.isConnected) {
      try {
        await mealService.updateMeal(meal);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteMeal(String mealId) async {
    if (await networkInfo.isConnected) {
      try {
        await mealService.deleteMeal(mealId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> addFoodToMeal(
      String mealId, FoodItem foodItem) async {
    if (await networkInfo.isConnected) {
      try {
        await mealService.addFoodToMeal(mealId, foodItem);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, String>> createEmptyMeal(
      MealType type, String userId, DateTime date, String time) async {
    if (await networkInfo.isConnected) {
      try {
        final newMeal = Meal(
          type: type,
          time: time,
          foods: [],
          totalCalories: 0,
          userId: userId,
          date: date,
        );

        final mealId = await mealService.addMeal(newMeal);
        return Right(mealId);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> removeFoodFromMeal(
      String mealId, String foodId) async {
    if (await networkInfo.isConnected) {
      try {
        await mealService.removeFoodFromMeal(mealId, foodId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateFoodInMeal(
      String mealId, String foodId, FoodItem updatedFoodItem) async {
    if (await networkInfo.isConnected) {
      try {
        await mealService.updateFoodInMeal(mealId, foodId, updatedFoodItem);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  // @override
  // Future<Either<Failure, void>> addFoodToMeal(
  //     String mealId, FoodItem foodItem) {
  //   // TODO: implement addFoodToMeal
  //   throw UnimplementedError();
  // }

  // @override
  // Future<Either<Failure, String>> addMeal(Meal meal) {
  //   // TODO: implement addMeal
  //   throw UnimplementedError();
  // }

  // @override
  // Future<Either<Failure, String>> createEmptyMeal(
  //     MealType type, String userId, DateTime date, String time) {
  //   // TODO: implement createEmptyMeal
  //   throw UnimplementedError();
  // }

  // @override
  // Future<Either<Failure, void>> deleteMeal(String mealId) {
  //   // TODO: implement deleteMeal
  //   throw UnimplementedError();
  // }

  // @override
  // Future<Either<Failure, List<Meal>>> getMealsByUserAndDate(
  //     String userId, DateTime date) {
  //   // TODO: implement getMealsByUserAndDate
  //   throw UnimplementedError();
  // }

  // @override
  // Future<Either<Failure, void>> updateMeal(Meal meal) {
  //   // TODO: implement updateMeal
  //   throw UnimplementedError();
  // }
}
