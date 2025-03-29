import 'package:dartz/dartz.dart';
import 'package:whole_sight/core/errors/failures.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/domain/repositories/user_repository.dart';

class CreateUserProfile {
  final UserRepository repository;

  CreateUserProfile(this.repository);

  Future<Either<Failure, UserEntity>> call(
      CreateUserProfileParams params) async {
    print("CreateUserProfile: Starting with userId: ${params.userId}");

    try {
      final result = await repository.createNutritionProfile(
        userId: params.userId,
        nutritionProfile: params.nutritionProfile,
      );

      print(
          "CreateUserProfile: Repository returned: ${result.isRight() ? 'Success' : 'Failure'}");

      // If it's a failure, log the error message
      if (result.isLeft()) {
        result.fold(
            (failure) =>
                print("CreateUserProfile: Failure message: ${failure.message}"),
            (_) => {});
      }

      return result;
    } catch (e) {
      print("CreateUserProfile: Unexpected exception: ${e.toString()}");
      return Left(ServerFailure(
          message: "Error in CreateUserProfile: ${e.toString()}"));
    }
  }
}

class CreateUserProfileParams {
  final String userId;
  final NutritionProfileEntity nutritionProfile;

  CreateUserProfileParams({
    required this.userId,
    required this.nutritionProfile,
  });
}
