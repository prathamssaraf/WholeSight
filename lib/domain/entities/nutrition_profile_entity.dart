import 'package:equatable/equatable.dart';

// Ensure these enums are in the same file or imported
enum Gender { male, female, other }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extremelyActive
}

enum Goal {
  loseWeight,
  maintainWeight,
  gainWeight,
  buildMuscle,
  improveHealth,
  improveAthletic
}

enum DietType {
  standard,
  vegetarian,
  vegan,
  pescatarian,
  paleo,
  keto,
  lowCarb,
  lowFat,
  mediterranean,
  gluten_free,
  whole30,
  intermittentFasting
}

class NutritionProfileEntity extends Equatable {
  final String userId;
  final int age;
  final double weightKg;
  final double heightCm;
  final Gender gender;
  final ActivityLevel activityLevel;
  final Goal goal;
  final DietType dietType;
  final List<String> allergies;
  final List<String> dislikedFoods;
  final List<String> medicalConditions;
  final Map<String, double> macroTargets;
  final double calorieTarget;
  final double waterTarget;
  
  const NutritionProfileEntity({
    required this.userId,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.dietType,
    this.allergies = const [],
    this.dislikedFoods = const [],
    this.medicalConditions = const [],
    this.macroTargets = const {
      'protein': 0.0,
      'carbs': 0.0,
      'fats': 0.0,
    },
    required this.calorieTarget,
    required this.waterTarget,
  });
  
  factory NutritionProfileEntity.fromJson(Map<String, dynamic> json) {
    return NutritionProfileEntity(
      userId: json['userId'] as String,
      age: _parseIntSafely(json['age']),
      weightKg: _parseDoubleSafely(json['weightKg']),
      heightCm: _parseDoubleSafely(json['heightCm']),
      gender: _parseEnum(Gender.values, json['gender'], Gender.other),
      activityLevel: _parseEnum(
        ActivityLevel.values, 
        json['activityLevel'], 
        ActivityLevel.sedentary
      ),
      goal: _parseEnum(Goal.values, json['goal'], Goal.maintainWeight),
      dietType: _parseEnum(
        DietType.values, 
        json['dietType'], 
        DietType.standard
      ),
      allergies: _parseListSafely(json['allergies']),
      dislikedFoods: _parseListSafely(json['dislikedFoods']),
      medicalConditions: _parseListSafely(json['medicalConditions']),
      macroTargets: _parseMacroTargetsSafely(json['macroTargets']),
      calorieTarget: _parseDoubleSafely(json['calorieTarget']),
      waterTarget: _parseDoubleSafely(json['waterTarget']),
    );
  }
  
  // Utility method to safely parse enum
  static T _parseEnum<T extends Enum>(
    List<T> values, 
    dynamic value, 
    T defaultValue
  ) {
    if (value == null) return defaultValue;
    return values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == 
             value.toString().toLowerCase(), 
      orElse: () => defaultValue
    );
  }
  
  // Utility method to safely parse int
  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    return value is int ? value : int.tryParse(value.toString()) ?? 0;
  }
  
  // Utility method to safely parse double
  static double _parseDoubleSafely(dynamic value) {
    if (value == null) return 0.0;
    return value is double 
      ? value 
      : double.tryParse(value.toString()) ?? 0.0;
  }
  
  // Utility method to safely parse list
  static List<String> _parseListSafely(dynamic value) {
    if (value == null) return [];
    return value is List 
      ? value.map((e) => e.toString()).toList() 
      : [];
  }
  
  // Utility method to safely parse macro targets
  static Map<String, double> _parseMacroTargetsSafely(dynamic value) {
    final defaultMacros = {
      'protein': 0.0,
      'carbs': 0.0,
      'fats': 0.0,
    };
    
    if (value == null) return defaultMacros;
    
    if (value is Map) {
      return {
        'protein': _parseDoubleSafely(value['protein']),
        'carbs': _parseDoubleSafely(value['carbs']),
        'fats': _parseDoubleSafely(value['fats']),
      };
    }
    
    return defaultMacros;
  }
  
  // Existing methods remain the same
  NutritionProfileEntity copyWith({
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
    return NutritionProfileEntity(
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
  
  // Calculate BMI
  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));
  
  // BMI Category
  String get bmiCategory {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi < 25) {
      return 'Normal';
    } else if (bmi >= 25 && bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }
  
  @override
  List<Object?> get props => [
    userId,
    age,
    weightKg,
    heightCm,
    gender,
    activityLevel,
    goal,
    dietType,
    allergies,
    dislikedFoods,
    medicalConditions,
    macroTargets,
    calorieTarget,
    waterTarget,
  ];
}