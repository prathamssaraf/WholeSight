import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:whole_sight/core/errors/failures.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/domain/repositories/food_repository.dart';

class GetFoodRecommendations {
  final FoodRepository repository;

  GetFoodRecommendations(this.repository);

  Future<Either<Failure, List<FoodEntity>>> call(GetFoodRecommendationsParams params) async {
    return await repository.getFoodRecommendations(
      userId: params.userId,
      limit: params.limit,
    );
  }
}

class GetFoodRecommendationsParams extends Equatable {
  final String userId;
  final int limit;

  const GetFoodRecommendationsParams({
    required this.userId,
    this.limit = 5,
  });

  @override
  List<Object?> get props => [userId, limit];
}