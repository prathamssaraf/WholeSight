import 'package:dartz/dartz.dart';
import 'package:whole_sight/core/errors/failures.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';

abstract class UserRepository {
  Future<Either<Failure, UserEntity>> getUserById(String userId);
  
  Future<Either<Failure, UserEntity>> createNutritionProfile({
    required String userId,
    required NutritionProfileEntity nutritionProfile,
  });
  
  Future<Either<Failure, UserEntity>> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? photoUrl,
  });
  
  Future<Either<Failure, UserEntity>> updateNutritionProfile({
    required String userId,
    required NutritionProfileEntity nutritionProfile,
  });
  
  Future<Either<Failure, List<UserEntity>>> getUsersByGoal(Goal goal);
  
  Future<Either<Failure, List<String>>> getNutritionInsights(String userId);
}