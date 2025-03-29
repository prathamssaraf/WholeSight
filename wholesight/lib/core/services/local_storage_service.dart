import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorageService {
  /// Gets a string value for the given [key].
  /// Returns null if the key doesn't exist.
  Future<String?> getString(String key);
  
  /// Gets a boolean value for the given [key].
  /// Returns null if the key doesn't exist.
  Future<bool?> getBool(String key);
  
  /// Gets an integer value for the given [key].
  /// Returns null if the key doesn't exist.
  Future<int?> getInt(String key);
  
  /// Gets a double value for the given [key].
  /// Returns null if the key doesn't exist.
  Future<double?> getDouble(String key);
  
  /// Gets a list of strings for the given [key].
  /// Returns null if the key doesn't exist.
  Future<List<String>?> getStringList(String key);
  
  /// Sets a string [value] for the given [key].
  Future<bool> setString(String key, String value);
  
  /// Sets a boolean [value] for the given [key].
  Future<bool> setBool(String key, bool value);
  
  /// Sets an integer [value] for the given [key].
  Future<bool> setInt(String key, int value);
  
  /// Sets a double [value] for the given [key].
  Future<bool> setDouble(String key, double value);
  
  /// Sets a list of strings [value] for the given [key].
  Future<bool> setStringList(String key, List<String> value);
  
  /// Removes the value for the given [key].
  Future<bool> remove(String key);
  
  /// Removes all values.
  Future<bool> clear();
  
  /// Checks if a [key] exists in storage.
  Future<bool> containsKey(String key);
  
  /// Gets all keys in storage.
  Future<Set<String>> getKeys();
}

class LocalStorageServiceImpl implements LocalStorageService {
  final SharedPreferences sharedPreferences;
  
  LocalStorageServiceImpl({required this.sharedPreferences});
  
  @override
  Future<String?> getString(String key) async {
    return sharedPreferences.getString(key);
  }
  
  @override
  Future<bool?> getBool(String key) async {
    return sharedPreferences.getBool(key);
  }
  
  @override
  Future<int?> getInt(String key) async {
    return sharedPreferences.getInt(key);
  }
  
  @override
  Future<double?> getDouble(String key) async {
    return sharedPreferences.getDouble(key);
  }
  
  @override
  Future<List<String>?> getStringList(String key) async {
    return sharedPreferences.getStringList(key);
  }
  
  @override
  Future<bool> setString(String key, String value) async {
    return await sharedPreferences.setString(key, value);
  }
  
  @override
  Future<bool> setBool(String key, bool value) async {
    return await sharedPreferences.setBool(key, value);
  }
  
  @override
  Future<bool> setInt(String key, int value) async {
    return await sharedPreferences.setInt(key, value);
  }
  
  @override
  Future<bool> setDouble(String key, double value) async {
    return await sharedPreferences.setDouble(key, value);
  }
  
  @override
  Future<bool> setStringList(String key, List<String> value) async {
    return await sharedPreferences.setStringList(key, value);
  }
  
  @override
  Future<bool> remove(String key) async {
    return await sharedPreferences.remove(key);
  }
  
  @override
  Future<bool> clear() async {
    return await sharedPreferences.clear();
  }
  
  @override
  Future<bool> containsKey(String key) async {
    return sharedPreferences.containsKey(key);
  }
  
  @override
  Future<Set<String>> getKeys() async {
    return sharedPreferences.getKeys();
  }
}