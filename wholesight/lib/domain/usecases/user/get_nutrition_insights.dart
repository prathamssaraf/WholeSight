import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:whole_sight/core/errors/failures.dart';
import 'package:whole_sight/domain/repositories/user_repository.dart';

class GetNutritionInsights {
  final UserRepository repository;

  GetNutritionInsights(this.repository);

  Future<Either<Failure, List<String>>> call(GetNutritionInsightsParams params) async {
    return await repository.getNutritionInsights(params.userId);
  }
}

class GetNutritionInsightsParams extends Equatable {
  final String userId;

  const GetNutritionInsightsParams({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}