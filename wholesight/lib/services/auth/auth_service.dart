import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:whole_sight/core/utils/logger.dart';
import 'package:whole_sight/domain/entities/nutrition_profile_entity.dart';
import 'package:whole_sight/domain/entities/user_entity.dart';
import 'package:whole_sight/services/firebase/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AuthService {
  Future<bool> isAuthenticated();
  Future<UserEntity?> getCurrentUser(); // Changed to nullable return type
  Stream<UserEntity?> get authStateChanges;
  Future<UserEntity?> loadUserWithNutritionProfile(String userId);
  Future<UserEntity> signup({
    required String email,
    required String password,
    required String name,
  });
  Future<UserEntity> login({
    required String email,
    required String password,
  });
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithApple();
  Future<void> logout();
  Future<UserEntity> updateProfile({
    String? name,
    String? photoUrl,
  });
  Future<UserEntity> updateNutritionProfile({
    required NutritionProfileEntity nutritionProfile,
  });
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> resetPassword({
    required String code,
    required String newPassword,
  });
}

class AuthServiceImpl implements AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  late final FirestoreService _firestoreService;

  AuthServiceImpl({FirestoreService? firestoreService}) {
    _firestoreService = firestoreService ?? FirestoreServiceImpl();
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        print('AuthService: User signed out or not authenticated');
        return null;
      }

      try {
        return await getCurrentUser();
      } catch (e) {
        AppLogger.error('Error mapping auth state change to UserEntity', e);
        return null;
      }
    });
  }

  Future<UserEntity?> loadUserWithNutritionProfile(String userId) async {
    try {
      // Get the Firebase user
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      // Get the complete user document from Firestore
      final userDoc = await _firestoreService.getDocument(
        collection: 'users',
        documentId: userId,
      );

      if (userDoc == null) return null;

      // Map the Firestore document to a UserEntity with nutrition profile
      return _mapFirestoreDocToUserEntity(userDoc, userId);
    } catch (e, stackTrace) {
      AppLogger.error(
          'Failed to load user with nutrition profile', e, stackTrace);
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    // Add a short delay to give Firebase Auth time to restore session
    await Future.delayed(Duration(milliseconds: 500));
    final user = _firebaseAuth.currentUser;
    print('AuthService: isAuthenticated check: ${user != null}');
    return user != null;
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final userDoc = await _firestoreService.getDocument(
        collection: 'users',
        documentId: firebaseUser.uid,
      );

      if (userDoc != null) {
        // Convert the Firestore document to a UserEntity
        return _mapFirestoreDocToUserEntity(userDoc, firebaseUser.uid);
      } else {
        // If the user document doesn't exist in Firestore yet,
        // create a basic user profile based on Firebase Auth data
        final basicUser = UserEntity(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          lastLoginAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
          hasCompletedOnboarding: false,
        );

        // Save the basic user to Firestore
        await _saveUserToFirestore(basicUser);

        return basicUser;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get current user', e, stackTrace);
      throw Exception('Failed to get user data: $e');
    }
  }

  @override
  Future<UserEntity> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user in Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to create user');
      }

      // Update display name
      await firebaseUser.updateDisplayName(name);

      // Create UserEntity
      final user = UserEntity(
        id: firebaseUser.uid,
        email: email,
        name: name,
        photoUrl: firebaseUser.photoURL,
        createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
        hasCompletedOnboarding: false,
      );

      // Save user to Firestore
      await _saveUserToFirestore(user);

      return user;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sign up', e, stackTrace);
      throw Exception('Failed to sign up: $e');
    }
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to login');
      }

      // Update last login time in Firestore
      await _firestoreService.updateDocument(
        collection: 'users',
        documentId: firebaseUser.uid,
        data: {
          'lastLoginAt': DateTime.now(),
        },
      );

      return getCurrentUser();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to login', e, stackTrace);
      throw Exception('Failed to login: $e');
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      // Trigger the Google Sign In flow
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in aborted');
      }

      // Get auth details from Google
      final googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        // Create a new user in Firestore
        final user = UserEntity(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName ?? '',
          photoUrl: firebaseUser.photoURL,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          lastLoginAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
          hasCompletedOnboarding: false,
        );

        await _saveUserToFirestore(user);
      } else {
        // Update last login time in Firestore
        await _firestoreService.updateDocument(
          collection: 'users',
          documentId: firebaseUser.uid,
          data: {
            'lastLoginAt': DateTime.now(),
          },
        );
      }

      return getCurrentUser();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sign in with Google', e, stackTrace);
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<UserEntity> signInWithApple() async {
    try {
      // Get Apple sign in credentials
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuthCredential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in with Firebase
      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to sign in with Apple');
      }

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Apple might not provide a name every time, only on the first login
      String name = firebaseUser.displayName ?? '';
      if (name.isEmpty && appleCredential.givenName != null) {
        name = '${appleCredential.givenName} ${appleCredential.familyName}';
        // Update the display name in Firebase Auth
        await firebaseUser.updateDisplayName(name);
      }

      if (isNewUser) {
        // Create a new user in Firestore
        final user = UserEntity(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: name,
          photoUrl: firebaseUser.photoURL,
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
          lastLoginAt: firebaseUser.metadata.lastSignInTime ?? DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
          hasCompletedOnboarding: false,
        );

        await _saveUserToFirestore(user);
      } else {
        // Update last login time in Firestore
        await _firestoreService.updateDocument(
          collection: 'users',
          documentId: firebaseUser.uid,
          data: {
            'lastLoginAt': DateTime.now(),
          },
        );
      }

      return getCurrentUser();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to sign in with Apple', e, stackTrace);
      throw Exception('Failed to sign in with Apple: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to logout', e, stackTrace);
      throw Exception('Failed to logout: $e');
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        throw Exception('No authenticated user found');
      }

      // Update display name in Firebase Auth if provided
      if (name != null) {
        await firebaseUser.updateDisplayName(name);
      }

      // Update photo URL in Firebase Auth if provided
      if (photoUrl != null) {
        await firebaseUser.updatePhotoURL(photoUrl);
      }

      // Update user data in Firestore
      final updates = <String, dynamic>{};
      if (name != null) {
        updates['name'] = name;
      }
      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }

      if (updates.isNotEmpty) {
        await _firestoreService.updateDocument(
          collection: 'users',
          documentId: firebaseUser.uid,
          data: updates,
        );
      }

      return getCurrentUser();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update profile', e, stackTrace);
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<UserEntity> updateNutritionProfile({
    required NutritionProfileEntity nutritionProfile,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser == null) {
        throw Exception('No authenticated user found');
      }

      // Convert NutritionProfileEntity to Map
      final nutritionProfileMap = {
        'userId': nutritionProfile.userId,
        'age': nutritionProfile.age,
        'weightKg': nutritionProfile.weightKg,
        'heightCm': nutritionProfile.heightCm,
        'gender': nutritionProfile.gender.toString().split('.').last,
        'activityLevel':
            nutritionProfile.activityLevel.toString().split('.').last,
        'goal': nutritionProfile.goal.toString().split('.').last,
        'dietType': nutritionProfile.dietType.toString().split('.').last,
        'allergies': nutritionProfile.allergies,
        'dislikedFoods': nutritionProfile.dislikedFoods,
        'medicalConditions': nutritionProfile.medicalConditions,
        'macroTargets': nutritionProfile.macroTargets,
        'calorieTarget': nutritionProfile.calorieTarget,
        'waterTarget': nutritionProfile.waterTarget,
      };

      // Update user data in Firestore
      await _firestoreService.updateDocument(
        collection: 'users',
        documentId: firebaseUser.uid,
        data: {
          'nutritionProfile': nutritionProfileMap,
          'hasCompletedOnboarding': true,
        },
      );

      return getCurrentUser();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update nutrition profile', e, stackTrace);
      throw Exception('Failed to update nutrition profile: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send password reset email', e, stackTrace);
      throw Exception('Failed to send password reset email: $e');
    }
  }

  @override
  Future<void> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _firebaseAuth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to reset password', e, stackTrace);
      throw Exception('Failed to reset password: $e');
    }
  }

  // Helper Methods

  Future<void> _saveUserToFirestore(UserEntity user) async {
    final userData = {
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'photoUrl': user.photoUrl,
      'createdAt': user.createdAt,
      'lastLoginAt': user.lastLoginAt,
      'isEmailVerified': user.isEmailVerified,
      'hasCompletedOnboarding': user.hasCompletedOnboarding,
      'nutritionProfile': user.nutritionProfile != null
          ? {
              'userId': user.nutritionProfile!.userId,
              'age': user.nutritionProfile!.age,
              'weightKg': user.nutritionProfile!.weightKg,
              'heightCm': user.nutritionProfile!.heightCm,
              'gender':
                  user.nutritionProfile!.gender.toString().split('.').last,
              'activityLevel': user.nutritionProfile!.activityLevel
                  .toString()
                  .split('.')
                  .last,
              'goal': user.nutritionProfile!.goal.toString().split('.').last,
              'dietType':
                  user.nutritionProfile!.dietType.toString().split('.').last,
              'allergies': user.nutritionProfile!.allergies,
              'dislikedFoods': user.nutritionProfile!.dislikedFoods,
              'medicalConditions': user.nutritionProfile!.medicalConditions,
              'macroTargets': user.nutritionProfile!.macroTargets,
              'calorieTarget': user.nutritionProfile!.calorieTarget,
              'waterTarget': user.nutritionProfile!.waterTarget,
            }
          : null,
    };

    await _firestoreService.setDocument(
      collection: 'users',
      documentId: user.id,
      data: userData,
    );
  }

  UserEntity _mapFirestoreDocToUserEntity(
      Map<String, dynamic> doc, String userId) {
    // Extract nutrition profile data if it exists
    NutritionProfileEntity? nutritionProfile;

    if (doc['nutritionProfile'] != null) {
      try {
        final nutritionProfileData =
            doc['nutritionProfile'] as Map<String, dynamic>;

        // Convert macroTargets
        Map<String, double> macroTargets = {};
        if (nutritionProfileData['macroTargets'] != null) {
          (nutritionProfileData['macroTargets'] as Map<String, dynamic>)
              .forEach((key, value) {
            if (value is int) {
              macroTargets[key] = value.toDouble();
            } else if (value is double) {
              macroTargets[key] = value;
            }
          });
        }

        nutritionProfile = NutritionProfileEntity(
          userId: nutritionProfileData['userId'] as String? ?? userId,
          age: nutritionProfileData['age'] as int,
          weightKg: nutritionProfileData['weightKg'] is int
              ? (nutritionProfileData['weightKg'] as int).toDouble()
              : nutritionProfileData['weightKg'] as double,
          heightCm: nutritionProfileData['heightCm'] is int
              ? (nutritionProfileData['heightCm'] as int).toDouble()
              : nutritionProfileData['heightCm'] as double,
          gender: _parseGender(nutritionProfileData['gender'] as String),
          activityLevel: _parseActivityLevel(
              nutritionProfileData['activityLevel'] as String),
          goal: _parseGoal(nutritionProfileData['goal'] as String),
          dietType: _parseDietType(nutritionProfileData['dietType'] as String),
          allergies: List<String>.from(nutritionProfileData['allergies'] ?? []),
          dislikedFoods:
              List<String>.from(nutritionProfileData['dislikedFoods'] ?? []),
          medicalConditions: List<String>.from(
              nutritionProfileData['medicalConditions'] ?? []),
          macroTargets: macroTargets,
          calorieTarget: nutritionProfileData['calorieTarget'] is int
              ? (nutritionProfileData['calorieTarget'] as int).toDouble()
              : nutritionProfileData['calorieTarget'] as double,
          waterTarget: nutritionProfileData['waterTarget'] is int
              ? (nutritionProfileData['waterTarget'] as int).toDouble()
              : nutritionProfileData['waterTarget'] as double,
        );
      } catch (e) {
        print('Error parsing nutrition profile: $e');
      }
    }

    // Rest of the method remains the same...
    // Convert Timestamp to DateTime if needed
    DateTime createdAt = DateTime.now();
    if (doc['createdAt'] != null) {
      if (doc['createdAt'] is Timestamp) {
        createdAt = (doc['createdAt'] as Timestamp).toDate();
      } else if (doc['createdAt'] is DateTime) {
        createdAt = doc['createdAt'] as DateTime;
      }
    }

    DateTime lastLoginAt = DateTime.now();
    if (doc['lastLoginAt'] != null) {
      if (doc['lastLoginAt'] is Timestamp) {
        lastLoginAt = (doc['lastLoginAt'] as Timestamp).toDate();
      } else if (doc['lastLoginAt'] is DateTime) {
        lastLoginAt = doc['lastLoginAt'] as DateTime;
      }
    }

    return UserEntity(
      id: userId,
      email: doc['email'] as String,
      name: doc['name'] as String,
      photoUrl: doc['photoUrl'] as String?,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      isEmailVerified: doc['isEmailVerified'] as bool? ?? false,
      nutritionProfile: nutritionProfile,
      hasCompletedOnboarding: doc['hasCompletedOnboarding'] as bool? ?? false,
    );
  }

  Gender _parseGender(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      default:
        return Gender.other;
    }
  }

  ActivityLevel _parseActivityLevel(String value) {
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

  Goal _parseGoal(String value) {
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

  DietType _parseDietType(String value) {
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
