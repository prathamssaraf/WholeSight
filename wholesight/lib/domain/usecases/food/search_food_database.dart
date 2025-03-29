import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:whole_sight/core/errors/failures.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/domain/repositories/food_repository.dart';

class SearchFoodDatabase {
  final FoodRepository repository;

  SearchFoodDatabase(this.repository);

  Future<Either<Failure, List<FoodEntity>>> call(SearchFoodDatabaseParams params) async {
    return await repository.searchFoods(
      query: params.query,
      categories: params.categories,
      limit: params.limit,
    );
  }
}

class SearchFoodDatabaseParams extends Equatable {
  final String query;
  final List<String>? categories;
  final int limit;

  const SearchFoodDatabaseParams({
    required this.query,
    this.categories,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [query, categories, limit];
}