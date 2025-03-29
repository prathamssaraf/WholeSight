import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whole_sight/core/errors/exceptions.dart';
import 'package:whole_sight/data/models/nutrition_profile.dart';
import 'package:whole_sight/data/models/user_model.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/services/firebase/firestore_service.dart';

abstract class UserRemoteDataSource {
  Future<UserModel> getUserById(String userId);

  Future<UserModel> createNutritionProfile({
    required String userId,
    required NutritionProfileEntity nutritionProfile,
  });

  Future<UserModel> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? photoUrl,
  });

  Future<UserModel> updateNutritionProfile({
    required String userId,
    required NutritionProfileEntity nutritionProfile,
  });

  Future<List<UserModel>> getUsersByGoal(Goal goal);

  Future<List<String>> getNutritionInsights(String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final FirestoreService firestoreService;

  UserRemoteDataSourceImpl({required this.firestoreService});

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      print("UserRemoteDataSource: Fetching user with ID: $userId");

      final userDoc = await firestoreService.getDocument(
        collection: 'users',
        documentId: userId,
      );

      print(
          "UserRemoteDataSource: Received user document: ${userDoc != null ? 'Yes' : 'No'}");

      if (userDoc != null) {
        try {
          print("UserRemoteDataSource: Attempting to parse user document");
          UserModel userModel = UserModel.fromJson(userDoc);
          print("UserRemoteDataSource: Successfully parsed user document");
          return userModel;
        } catch (parsingError) {
          print(
              "UserRemoteDataSource: Error parsing user document: $parsingError");
          throw ServerException("Error parsing user data: $parsingError");
        }
      } else {
        print("UserRemoteDataSource: User document not found");
        throw ServerException("User not found");
      }
    } catch (e) {
      print("UserRemoteDataSource: Error fetching user: $e");
      throw ServerException("Error fetching user: $e");
    }
  }

  @override
  Future<UserModel> createNutritionProfile({
    required String userId,
    required NutritionProfileEntity nutritionProfile,
  }) async {
    try {
      print(
          "UserRemoteDataSource: Creating nutrition profile for user: $userId");

      // Convert NutritionProfileEntity to Map
      final nutritionProfileModel =
          NutritionProfileModel.fromEntity(nutritionProfile);
      final nutritionProfileMap = nutritionProfileModel.toJson();

      print("UserRemoteDataSource: Updating Firestore document");
      // Update user data in Firestore
      await firestoreService.updateDocument(
        collection: 'users',
        documentId: userId,
        data: {
          'nutritionProfile': nutritionProfileMap,
          'hasCompletedOnboarding': true,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      print(
          "UserRemoteDataSource: Firestore update successful, fetching updated user");
      try {
        final updatedUser = await getUserById(userId);
        print("UserRemoteDataSource: Successfully retrieved updated user");
        return updatedUser;
      } catch (getUserError) {
        print(
            "UserRemoteDataSource: Error getting updated user: $getUserError");
        throw ServerException("Error fetching updated user: $getUserError");
      }
    } catch (e) {
      print("UserRemoteDataSource: Error in createNutritionProfile: $e");
      throw ServerException("Error creating nutrition profile: $e");
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    required String userId,
    String? name,
    String? email,
    String? photoUrl,
  }) async {
    try {
      // Update user data in Firestore
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) {
        updates['name'] = name;
      }

      if (email != null) {
        updates['email'] = email;
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }

      await firestoreService.updateDocument(
        collection: 'users',
        documentId: userId,
        data: updates,
      );

      // Get the updated user
      return await getUserById(userId);
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<UserModel> updateNutritionProfile({
    required String userId,
    required NutritionProfileEntity nutritionProfile,
  }) async {
    try {
      // Convert NutritionProfileEntity to Map
      final nutritionProfileModel =
          NutritionProfileModel.fromEntity(nutritionProfile);
      final nutritionProfileMap = nutritionProfileModel.toJson();

      // Update user data in Firestore
      await firestoreService.updateDocument(
        collection: 'users',
        documentId: userId,
        data: {
          'nutritionProfile': nutritionProfileMap,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Get the updated user
      return await getUserById(userId);
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<UserModel>> getUsersByGoal(Goal goal) async {
    try {
      final users = await firestoreService.getDocuments(
        collection: 'users',
        whereConditions: [
          ['nutritionProfile.goal', '==', goal.toString().split('.').last],
        ],
      );

      return users.map((user) => UserModel.fromJson(user)).toList();
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<List<String>> getNutritionInsights(String userId) async {
    try {
      // Get the user
      final user = await getUserById(userId);

      // Get recent meals
      final mealDocs = await firestoreService.getDocuments(
        collection: 'users/$userId/meals',
        orderBy: 'timestamp',
        descending: true,
        limit: 10,
      );

      // Generate insights (this could be AI-generated in a real app)
      final insights = _generateInsights(user, mealDocs);

      // Store the insights in Firestore
      await firestoreService.setDocument(
        collection: 'users/$userId/insights',
        documentId: 'latest',
        data: {
          'insights': insights,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      return insights;
    } catch (e) {
      throw ServerException();
    }
  }

  List<String> _generateInsights(
      UserModel user, List<Map<String, dynamic>> meals) {
    // This is a placeholder for what would be AI-generated insights
    // In a real app, this would use more sophisticated analysis
    final insights = <String>[];

    if (meals.isEmpty) {
      insights
          .add('Start logging your meals to receive personalized insights.');
      return insights;
    }

    // Calculate average daily calorie intake
    double totalCalories = 0;
    for (final meal in meals) {
      totalCalories += (meal['totalCalories'] as num).toDouble();
    }
    final averageDailyCalories =
        totalCalories / (meals.length / 3); // Assuming 3 meals per day

    // Compare with target calories
    final targetCalories = user.nutritionProfile?.calorieTarget ?? 2000;
    if (averageDailyCalories < targetCalories * 0.8) {
      insights.add(
          'You\'re consistently eating below your calorie target. Consider adding more nutrient-dense foods to meet your energy needs.');
    } else if (averageDailyCalories > targetCalories * 1.1) {
      insights.add(
          'You\'re consistently eating above your calorie target. Try reducing portion sizes slightly if weight management is a goal.');
    } else {
      insights.add(
          'You\'re doing a great job of staying close to your calorie target!');
    }

    // Check protein intake
    double totalProtein = 0;
    for (final meal in meals) {
      final foods = meal['foods'] as List<dynamic>;
      for (final food in foods) {
        totalProtein += (food['protein'] as num).toDouble() *
            (food['quantity'] as num).toDouble();
      }
    }
    final averageDailyProtein = totalProtein / (meals.length / 3);

    // Compare with target protein
    final targetProtein = user.nutritionProfile?.macroTargets['protein'] ??
        0.8 * user.nutritionProfile!.weightKg;
    if (averageDailyProtein < targetProtein * 0.8) {
      insights.add(
          'Your protein intake is lower than recommended. Try incorporating more lean protein sources like chicken, fish, tofu, or legumes.');
    } else {
      insights.add(
          'You\'re meeting your protein needs, which is great for muscle maintenance and recovery!');
    }

    // Add a general tip based on the user's goal
    if (user.nutritionProfile?.goal == Goal.loseWeight) {
      insights.add(
          'For weight loss, focus on high-volume, nutrient-dense foods like vegetables and lean proteins that keep you satisfied with fewer calories.');
    } else if (user.nutritionProfile?.goal == Goal.buildMuscle) {
      insights.add(
          'For muscle building, ensure you\'re eating enough calories and protein, especially within 1-2 hours after workouts.');
    }

    return insights;
  }
}
