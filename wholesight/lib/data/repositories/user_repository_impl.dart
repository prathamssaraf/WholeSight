import 'package:dartz/dartz.dart';
import 'package:whole_sight/core/errors/exceptions.dart';
import 'package:whole_sight/core/errors/failures.dart';
import 'package:whole_sight/core/network/network_info.dart';
import 'package:whole_sight/data/datasources/local/user_local_data_source.dart';
import 'package:whole_sight/data/datasources/remote/user_remote_data_source.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource localDataSource;
  final UserRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> getUserById(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.getUserById(userId);
        localDataSource.cacheUser(userModel);
        return Right(userModel);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final localUser = await localDataSource.getLastUser();
        return Right(localUser);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }

  @override
  Future<Either<Failure, UserEntity>> createNutritionProfile({
    required String userId,
    required NutritionProfileEntity nutritionProfile,
  }) async {
    print("UserRepositoryImpl: Creating nutrition profile for user: $userId");

    if (await networkInfo.isConnected) {
      try {
        print(
            "UserRepositoryImpl: Network connected, calling remote data source");

        final userModel = await remoteDataSource.createNutritionProfile(
          userId: userId,
          nutritionProfile: nutritionProfile,
        );

        print("UserRepositoryImpl: Remote data source returned successfully");
        localDataSource.cacheUser(userModel);
        return Right(userModel);
      } on ServerException catch (e) {
        print(
            "UserRepositoryImpl: ServerException caught: ${e.message ?? 'Unknown server error'}");
        return Left(
            ServerFailure(message: e.message ?? "Unknown server error"));
      } catch (e) {
        print("UserRepositoryImpl: Unexpected error: ${e.toString()}");
        return Left(
            ServerFailure(message: "Unexpected error: ${e.toString()}"));
      }
    } else {
      print("UserRepositoryImpl: No network connection");
      return Left(NetworkFailure(message: "No internet connection available"));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.updateUserProfile(
          userId: userId,
          name: name,
          email: email,
          photoUrl: photoUrl,
        );
        localDataSource.cacheUser(userModel);
        return Right(userModel);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateNutritionProfile({
    required String userId,
    required NutritionProfileEntity nutritionProfile,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.updateNutritionProfile(
          userId: userId,
          nutritionProfile: nutritionProfile,
        );
        localDataSource.cacheUser(userModel);
        return Right(userModel);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getUsersByGoal(Goal goal) async {
    if (await networkInfo.isConnected) {
      try {
        final users = await remoteDataSource.getUsersByGoal(goal);
        return Right(users);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      return Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, List<String>>> getNutritionInsights(
      String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final insights = await remoteDataSource.getNutritionInsights(userId);
        return Right(insights);
      } on ServerException {
        return Left(ServerFailure());
      }
    } else {
      try {
        final cachedInsights = await localDataSource.getCachedInsights(userId);
        return Right(cachedInsights);
      } on CacheException {
        return Left(CacheFailure());
      }
    }
  }
}
