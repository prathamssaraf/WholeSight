import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:whole_sight/core/errors/failures.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/domain/repositories/user_repository.dart';

class UpdateUserGoals {
  final UserRepository repository;

  UpdateUserGoals(this.repository);

  Future<Either<Failure, UserEntity>> call(UpdateUserGoalsParams params) async {
    // Get the current nutrition profile
    final userResult = await repository.getUserById(params.userId);
    
    return userResult.fold(
      (failure) => Left(failure),
      (user) {
        if (user.nutritionProfile == null) {
          return Left(ValidationFailure('User does not have a nutrition profile'));
        }
        
        // Update the nutrition profile with new goals
        final updatedProfile = user.nutritionProfile!.copyWith(
          goal: params.goal,
          calorieTarget: params.calorieTarget,
          macroTargets: params.macroTargets,
          dietType: params.dietType,
        );
        
        // Save the updated profile
        return repository.updateNutritionProfile(
          userId: params.userId,
          nutritionProfile: updatedProfile,
        );
      },
    );
  }
}

class UpdateUserGoalsParams extends Equatable {
  final String userId;
  final Goal? goal;
  final double? calorieTarget;
  final Map<String, double>? macroTargets;
  final DietType? dietType;

  const UpdateUserGoalsParams({
    required this.userId,
    this.goal,
    this.calorieTarget,
    this.macroTargets,
    this.dietType,
  });

  @override
  List<Object?> get props => [userId, goal, calorieTarget, macroTargets, dietType];
}

class ValidationFailure extends Failure {
  final String message;

  // Added const and super constructor call
  const ValidationFailure(this.message) : super(message);

  @override
  // Changed to match parent class return type
  List<Object> get props => [message];
}