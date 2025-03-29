import 'package:equatable/equatable.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isEmailVerified;
  final NutritionProfileEntity? nutritionProfile;
  final bool hasCompletedOnboarding;
  
  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isEmailVerified,
    this.nutritionProfile,
    this.hasCompletedOnboarding = false,
  });
  
  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    NutritionProfileEntity? nutritionProfile,
    bool? hasCompletedOnboarding,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      nutritionProfile: nutritionProfile ?? this.nutritionProfile,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
  
  @override
  List<Object?> get props => [
    id,
    email,
    name,
    photoUrl,
    createdAt,
    lastLoginAt,
    isEmailVerified,
    nutritionProfile,
    hasCompletedOnboarding,
  ];
}