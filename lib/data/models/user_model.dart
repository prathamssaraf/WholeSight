import 'package:whole_sight/data/models/nutrition_profile.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.photoUrl,
    required super.createdAt,
    required super.lastLoginAt,
    required super.isEmailVerified,
    super.nutritionProfile,
    super.hasCompletedOnboarding = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    NutritionProfileEntity? nutritionProfile;

    if (json['nutritionProfile'] != null) {
      nutritionProfile = NutritionProfileModel.fromJson(
          json['nutritionProfile'] as Map<String, dynamic>);
    }

    // Handle Firestore Timestamp objects
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;

      // Handle Firestore Timestamp
      if (value.runtimeType.toString().contains('Timestamp')) {
        return value.toDate();
      }

      // Try parsing as string
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        print("Date parsing error: $e for value: $value");
        return DateTime.now(); // Fallback
      }
    }

    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      createdAt: parseDateTime(json['createdAt']),
      lastLoginAt: parseDateTime(json['lastLoginAt']),
      isEmailVerified: json['isEmailVerified'] ?? false,
      nutritionProfile: nutritionProfile,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      photoUrl: entity.photoUrl,
      createdAt: entity.createdAt,
      lastLoginAt: entity.lastLoginAt,
      isEmailVerified: entity.isEmailVerified,
      nutritionProfile: entity.nutritionProfile,
      hasCompletedOnboarding: entity.hasCompletedOnboarding,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'nutritionProfile': nutritionProfile != null
          ? (nutritionProfile is NutritionProfileModel
              ? (nutritionProfile as NutritionProfileModel).toJson()
              : NutritionProfileModel.fromEntity(nutritionProfile!).toJson())
          : null,
      'hasCompletedOnboarding': hasCompletedOnboarding,
    };
  }

  UserModel copyWith({
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
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      nutritionProfile: nutritionProfile ?? this.nutritionProfile,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
    );
  }
}
