import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:whole_sight/domain/entities/food_entity.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/domain/usecases/food/get_food_recommendations.dart';
import 'package:whole_sight/domain/usecases/user/get_nutrition_insights.dart';
import 'package:whole_sight/services/ai/recommendation_service.dart';

// Events
abstract class NutritionEvent extends Equatable {
  const NutritionEvent();

  @override
  List<Object?> get props => [];
}

class GetInsightsEvent extends NutritionEvent {
  final String userId;

  const GetInsightsEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class GetFoodRecommendationsEvent extends NutritionEvent {
  final String userId;
  final int limit;

  const GetFoodRecommendationsEvent({
    required this.userId,
    this.limit = 5,
  });

  @override
  List<Object?> get props => [userId, limit];
}

class GetPersonalizedNutritionTipEvent extends NutritionEvent {
  final String userId;
  final NutritionProfileEntity nutritionProfile;

  const GetPersonalizedNutritionTipEvent({
    required this.userId,
    required this.nutritionProfile,
  });

  @override
  List<Object?> get props => [userId, nutritionProfile];
}

// States
abstract class NutritionState extends Equatable {
  const NutritionState();

  @override
  List<Object?> get props => [];
}

class NutritionInitial extends NutritionState {}

class NutritionLoading extends NutritionState {}

class InsightsLoaded extends NutritionState {
  final List<String> insights;

  const InsightsLoaded({required this.insights});

  @override
  List<Object?> get props => [insights];
}

class FoodRecommendationsLoaded extends NutritionState {
  final List<FoodEntity> recommendations;

  const FoodRecommendationsLoaded({required this.recommendations});

  @override
  List<Object?> get props => [recommendations];
}

class NutritionTipLoaded extends NutritionState {
  final String tip;

  const NutritionTipLoaded({required this.tip});

  @override
  List<Object?> get props => [tip];
}

class NutritionError extends NutritionState {
  final String message;

  const NutritionError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class NutritionBloc extends Bloc<NutritionEvent, NutritionState> {
  final GetNutritionInsights getNutritionInsights;
  final GetFoodRecommendations getFoodRecommendations;
  final RecommendationService recommendationService;

  NutritionBloc({
    required this.getNutritionInsights,
    required this.getFoodRecommendations,
    required this.recommendationService,
  }) : super(NutritionInitial()) {
    on<GetInsightsEvent>(_onGetInsights);
    on<GetFoodRecommendationsEvent>(_onGetFoodRecommendations);
    on<GetPersonalizedNutritionTipEvent>(_onGetPersonalizedNutritionTip);
  }

  Future<void> _onGetInsights(
    GetInsightsEvent event,
    Emitter<NutritionState> emit,
  ) async {
    emit(NutritionLoading());

    final params = GetNutritionInsightsParams(userId: event.userId);
    final result = await getNutritionInsights(params);

    result.fold(
      (failure) => emit(NutritionError(message: failure.toString())),
      (insights) => emit(InsightsLoaded(insights: insights)),
    );
  }

  Future<void> _onGetFoodRecommendations(
    GetFoodRecommendationsEvent event,
    Emitter<NutritionState> emit,
  ) async {
    emit(NutritionLoading());

    final params = GetFoodRecommendationsParams(
      userId: event.userId,
      limit: event.limit,
    );

    final result = await getFoodRecommendations(params);

    result.fold(
      (failure) => emit(NutritionError(message: failure.toString())),
      (recommendations) => emit(FoodRecommendationsLoaded(recommendations: recommendations)),
    );
  }

  Future<void> _onGetPersonalizedNutritionTip(
    GetPersonalizedNutritionTipEvent event,
    Emitter<NutritionState> emit,
  ) async {
    emit(NutritionLoading());

    try {
      // This directly uses the recommendation service rather than going through a use case
      // In a more complete implementation, you might want to create a dedicated use case for this
      final tip = await recommendationService.getPersonalizedNutritionTip(
        nutritionProfile: event.nutritionProfile,
        recentMeals: [], // In a real app, you would fetch recent meals
      );

      emit(NutritionTipLoaded(tip: tip));
    } catch (e) {
      emit(NutritionError(message: 'Failed to get nutrition tip: ${e.toString()}'));
    }
  }
}