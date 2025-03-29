import 'dart:convert';

import 'package:whole_sight/core/errors/exceptions.dart';
import 'package:whole_sight/core/services/local_storage_service.dart';
import 'package:whole_sight/data/models/user_model.dart';

abstract class UserLocalDataSource {
  /// Gets the last user cached.
  /// Throws [CacheException] if no cached data is present.
  Future<UserModel> getLastUser();
  
  /// Gets cached insights for a user.
  /// Throws [CacheException] if no cached data is present.
  Future<List<String>> getCachedInsights(String userId);
  
  /// Caches a user.
  Future<void> cacheUser(UserModel user);
  
  /// Caches insights for a user.
  Future<void> cacheInsights(String userId, List<String> insights);
}

class UserLocalDataSourceImpl implements UserLocalDataSource {
  final LocalStorageService localStorageService;
  
  UserLocalDataSourceImpl({required this.localStorageService});
  
  @override
  Future<UserModel> getLastUser() async {
    final jsonString = await localStorageService.getString('LAST_USER');
    if (jsonString != null) {
      return UserModel.fromJson(json.decode(jsonString));
    } else {
      throw CacheException();
    }
  }
  
  @override
  Future<List<String>> getCachedInsights(String userId) async {
    final insights = await localStorageService.getStringList('USER_${userId}_INSIGHTS');
    if (insights != null && insights.isNotEmpty) {
      return insights;
    } else {
      throw CacheException();
    }
  }
  
  @override
  Future<void> cacheUser(UserModel user) async {
    // Cache the user
    await localStorageService.setString(
      'USER_${user.id}',
      json.encode(user.toJson()),
    );
    
    // Update the last user
    await localStorageService.setString(
      'LAST_USER',
      json.encode(user.toJson()),
    );
  }
  
  @override
  Future<void> cacheInsights(String userId, List<String> insights) async {
    await localStorageService.setStringList(
      'USER_${userId}_INSIGHTS',
      insights,
    );
  }
}