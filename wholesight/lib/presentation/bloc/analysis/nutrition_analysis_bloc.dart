// lib/presentation/bloc/analysis/nutrition_analysis_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:whole_sight/domain/usecases/user/get_comprehensive_nutrition_analysis.dart';

// Events
abstract class NutritionAnalysisEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNutritionAnalysis extends NutritionAnalysisEvent {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;

  LoadNutritionAnalysis({
    required this.userId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

class ChangeDateRange extends NutritionAnalysisEvent {
  final DateTime startDate;
  final DateTime endDate;
  final String userId;

  ChangeDateRange({
    required this.startDate,
    required this.endDate,
    required this.userId,
  });

  @override
  List<Object?> get props => [startDate, endDate, userId];
}

// States
abstract class NutritionAnalysisState extends Equatable {
  @override
  List<Object?> get props => [];
}

class NutritionAnalysisInitial extends NutritionAnalysisState {}

class NutritionAnalysisLoading extends NutritionAnalysisState {}

class NutritionAnalysisLoaded extends NutritionAnalysisState {
  final NutritionAnalysisResult result;
  final DateTime startDate;
  final DateTime endDate;

  NutritionAnalysisLoaded({
    required this.result,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [result, startDate, endDate];
}

class NutritionAnalysisError extends NutritionAnalysisState {
  final String message;

  NutritionAnalysisError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class NutritionAnalysisBloc
    extends Bloc<NutritionAnalysisEvent, NutritionAnalysisState> {
  final GetComprehensiveNutritionAnalysis getAnalysis;

  NutritionAnalysisBloc({required this.getAnalysis})
      : super(NutritionAnalysisInitial()) {
    on<LoadNutritionAnalysis>(_onLoadAnalysis);
    on<ChangeDateRange>(_onChangeDateRange);
  }

  Future<void> _onLoadAnalysis(
    LoadNutritionAnalysis event,
    Emitter<NutritionAnalysisState> emit,
  ) async {
    emit(NutritionAnalysisLoading());

    final result = await getAnalysis(
      userId: event.userId,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (failure) => emit(
          NutritionAnalysisError(failure.message ?? "Failed to load analysis")),
      (data) => emit(NutritionAnalysisLoaded(
        result: data,
        startDate: event.startDate ??
            DateTime.now().subtract(const Duration(days: 30)),
        endDate: event.endDate ?? DateTime.now(),
      )),
    );
  }

  Future<void> _onChangeDateRange(
    ChangeDateRange event,
    Emitter<NutritionAnalysisState> emit,
  ) async {
    emit(NutritionAnalysisLoading());

    final result = await getAnalysis(
      userId: event.userId,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    result.fold(
      (failure) => emit(
          NutritionAnalysisError(failure.message ?? "Failed to load analysis")),
      (data) => emit(NutritionAnalysisLoaded(
        result: data,
        startDate: event.startDate,
        endDate: event.endDate,
      )),
    );
  }
}
