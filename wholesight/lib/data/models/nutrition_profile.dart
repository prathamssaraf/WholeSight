import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';

class NutritionProfileModel extends NutritionProfileEntity {
  const NutritionProfileModel({
    required super.userId,
    required super.age,
    required super.weightKg,
    required super.heightCm,
    required super.gender,
    required super.activityLevel,
    required super.goal,
    required super.dietType,
    super.allergies = const [],
    super.dislikedFoods = const [],
    super.medicalConditions = const [],
    super.macroTargets = const {
      'protein': 0.0,
      'carbs': 0.0,
      'fats': 0.0,
    },
    required super.calorieTarget,
    required super.waterTarget,
  });

  factory NutritionProfileModel.fromJson(Map<String, dynamic> json) {
    return NutritionProfileModel(
      userId: json['userId'],
      age: json['age'],
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toDouble(),
      gender: _parseGender(json['gender']),
      activityLevel: _parseActivityLevel(json['activityLevel']),
      goal: _parseGoal(json['goal']),
      dietType: _parseDietType(json['dietType']),
      allergies: List<String>.from(json['allergies'] ?? []),
      dislikedFoods: List<String>.from(json['dislikedFoods'] ?? []),
      medicalConditions: List<String>.from(json['medicalConditions'] ?? []),
      macroTargets: Map<String, double>.from(
        (json['macroTargets'] as Map<dynamic, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
      ),
      calorieTarget: (json['calorieTarget'] as num).toDouble(),
      waterTarget: (json['waterTarget'] as num).toDouble(),
    );
  }

  factory NutritionProfileModel.fromEntity(NutritionProfileEntity entity) {
    return NutritionProfileModel(
      userId: entity.userId,
      age: entity.age,
      weightKg: entity.weightKg,
      heightCm: entity.heightCm,
      gender: entity.gender,
      activityLevel: entity.activityLevel,
      goal: entity.goal,
      dietType: entity.dietType,
      allergies: entity.allergies,
      dislikedFoods: entity.dislikedFoods,
      medicalConditions: entity.medicalConditions,
      macroTargets: entity.macroTargets,
      calorieTarget: entity.calorieTarget,
      waterTarget: entity.waterTarget,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'age': age,
      'weightKg': weightKg,
      'heightCm': heightCm,
      'gender': gender.toString().split('.').last,
      'activityLevel': activityLevel.toString().split('.').last,
      'goal': goal.toString().split('.').last,
      'dietType': dietType.toString().split('.').last,
      'allergies': allergies,
      'dislikedFoods': dislikedFoods,
      'medicalConditions': medicalConditions,
      'macroTargets': macroTargets,
      'calorieTarget': calorieTarget,
      'waterTarget': waterTarget,
    };
  }

  NutritionProfileModel copyWith({
    String? userId,
    int? age,
    double? weightKg,
    double? heightCm,
    Gender? gender,
    ActivityLevel? activityLevel,
    Goal? goal,
    DietType? dietType,
    List<String>? allergies,
    List<String>? dislikedFoods,
    List<String>? medicalConditions,
    Map<String, double>? macroTargets,
    double? calorieTarget,
    double? waterTarget,
  }) {
    return NutritionProfileModel(
      userId: userId ?? this.userId,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      gender: gender ?? this.gender,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
      dietType: dietType ?? this.dietType,
      allergies: allergies ?? this.allergies,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      macroTargets: macroTargets ?? this.macroTargets,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      waterTarget: waterTarget ?? this.waterTarget,
    );
  }

  // Helper methods for parsing enums
  static Gender _parseGender(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.other;
    }
  }
  
  static ActivityLevel _parseActivityLevel(String value) {
    switch (value.toLowerCase()) {
      case 'sedentary':
        return ActivityLevel.sedentary;
      case 'lightlyactive':
        return ActivityLevel.lightlyActive;
      case 'moderatelyactive':
        return ActivityLevel.moderatelyActive;
      case 'veryactive':
        return ActivityLevel.veryActive;
      case 'extremelyactive':
        return ActivityLevel.extremelyActive;
      default:
        return ActivityLevel.moderatelyActive;
    }
  }
  
  static Goal _parseGoal(String value) {
    switch (value.toLowerCase()) {
      case 'loseweight':
        return Goal.loseWeight;
      case 'maintainweight':
        return Goal.maintainWeight;
      case 'gainweight':
        return Goal.gainWeight;
      case 'buildmuscle':
        return Goal.buildMuscle;
      case 'improvehealth':
        return Goal.improveHealth;
      case 'improveathletic':
        return Goal.improveAthletic;
      default:
        return Goal.maintainWeight;
    }
  }
  
  static DietType _parseDietType(String value) {
    switch (value.toLowerCase()) {
      case 'standard':
        return DietType.standard;
      case 'vegetarian':
        return DietType.vegetarian;
      case 'vegan':
        return DietType.vegan;
      case 'pescatarian':
        return DietType.pescatarian;
      case 'paleo':
        return DietType.paleo;
      case 'keto':
        return DietType.keto;
      case 'lowcarb':
        return DietType.lowCarb;
      case 'lowfat':
        return DietType.lowFat;
      case 'mediterranean':
        return DietType.mediterranean;
      case 'gluten_free':
        return DietType.gluten_free;
      case 'whole30':
        return DietType.whole30;
      case 'intermittentfasting':
        return DietType.intermittentFasting;
      default:
        return DietType.standard;
    }
  }
}