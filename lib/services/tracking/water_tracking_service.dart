import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:whole_sight/core/utils/logger.dart';

class WaterIntake {
  final String id;
  final double amount; // in milliliters
  final DateTime timestamp;
  final String source; // 'manual', 'nfc', or 'quick_add'

  WaterIntake({
    required this.id,
    required this.amount,
    required this.timestamp,
    required this.source,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  factory WaterIntake.fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
      source: map['source'] ?? 'manual',
    );
  }
}

class WaterTrackingService {
  static const String _todayWaterKey = 'today_water_intake';
  static const String _waterTargetKey = 'water_target';
  static const String _lastDateKey = 'last_water_date';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<WaterIntake> _todayIntakes = [];
  double _waterTarget = 2500; // default 2.5L in ml
  
  List<WaterIntake> get todayIntakes => _todayIntakes;
  double get waterTarget => _waterTarget;
  
  double get totalWaterToday {
    return _todayIntakes.fold(0.0, (total, intake) => total + intake.amount);
  }
  
  double get totalWaterTodayInLiters {
    return totalWaterToday / 1000.0;
  }
  
  double get waterTargetInLiters {
    return _waterTarget / 1000.0;
  }
  
  double get progressPercentage {
    if (_waterTarget <= 0) return 0.0;
    return (totalWaterToday / _waterTarget).clamp(0.0, 1.0);
  }
  
  double get remainingWaterToday {
    return (_waterTarget - totalWaterToday).clamp(0.0, double.infinity);
  }
  
  double get remainingWaterTodayInLiters {
    return remainingWaterToday / 1000.0;
  }

  Future<void> initialize(String userId) async {
    await _loadLocalData();
    await _syncWithFirestore(userId);
  }

  Future<void> addWaterIntake({
    required String userId,
    required double amountMl,
    required String source,
  }) async {
    try {
      final intake = WaterIntake(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amountMl,
        timestamp: DateTime.now(),
        source: source,
      );

      _todayIntakes.add(intake);
      await _saveLocalData();
      await _saveToFirestore(userId, intake);

      AppLogger.info('Water intake added: ${amountMl}ml from $source');
    } catch (e) {
      AppLogger.error('Error adding water intake: $e');
      rethrow;
    }
  }

  Future<void> updateWaterTarget(String userId, double targetMl) async {
    try {
      _waterTarget = targetMl;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_waterTargetKey, targetMl);
      
      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('water_settings')
          .doc('target')
          .set({
        'target_ml': targetMl,
        'updated_at': FieldValue.serverTimestamp(),
      });

      AppLogger.info('Water target updated to ${targetMl}ml');
    } catch (e) {
      AppLogger.error('Error updating water target: $e');
      rethrow;
    }
  }

  Future<void> removeWaterIntake(String userId, String intakeId) async {
    try {
      _todayIntakes.removeWhere((intake) => intake.id == intakeId);
      await _saveLocalData();
      
      // Remove from Firestore
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('water_intake')
          .doc(intakeId)
          .delete();

      AppLogger.info('Water intake removed: $intakeId');
    } catch (e) {
      AppLogger.error('Error removing water intake: $e');
      rethrow;
    }
  }

  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if it's a new day and reset if needed
      final lastDateString = prefs.getString(_lastDateKey);
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      
      if (lastDateString != todayString) {
        // New day, reset water intake
        _todayIntakes.clear();
        await prefs.setString(_lastDateKey, todayString);
        await prefs.remove(_todayWaterKey);
      } else {
        // Same day, load existing data
        final waterDataString = prefs.getString(_todayWaterKey);
        if (waterDataString != null) {
          final List<dynamic> waterDataList = 
              (waterDataString.split('|||')).where((s) => s.isNotEmpty).toList();
          
          _todayIntakes = waterDataList.map((data) {
            final parts = data.split('|');
            return WaterIntake(
              id: parts[0],
              amount: double.parse(parts[1]),
              timestamp: DateTime.parse(parts[2]),
              source: parts.length > 3 ? parts[3] : 'manual',
            );
          }).toList();
        }
      }
      
      // Load water target
      _waterTarget = prefs.getDouble(_waterTargetKey) ?? 2500.0;
      
    } catch (e) {
      AppLogger.error('Error loading local water data: $e');
      // Reset to defaults on error
      _todayIntakes.clear();
      _waterTarget = 2500.0;
    }
  }

  Future<void> _saveLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save water intake data as pipe-delimited string
      final waterDataString = _todayIntakes
          .map((intake) => '${intake.id}|${intake.amount}|${intake.timestamp.toIso8601String()}|${intake.source}')
          .join('|||');
      
      await prefs.setString(_todayWaterKey, waterDataString);
      
      // Update last date
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';
      await prefs.setString(_lastDateKey, todayString);
      
    } catch (e) {
      AppLogger.error('Error saving local water data: $e');
    }
  }

  Future<void> _saveToFirestore(String userId, WaterIntake intake) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('water_intake')
          .doc(intake.id)
          .set(intake.toMap());
    } catch (e) {
      AppLogger.error('Error saving water intake to Firestore: $e');
      // Don't rethrow here as we want local storage to work even if Firestore fails
    }
  }

  Future<void> _syncWithFirestore(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('water_intake')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      final firestoreIntakes = snapshot.docs
          .map((doc) => WaterIntake.fromMap(doc.data()))
          .toList();

      // Merge with local data (prefer local data for duplicates)
      final localIds = _todayIntakes.map((intake) => intake.id).toSet();
      final newIntakes = firestoreIntakes
          .where((intake) => !localIds.contains(intake.id))
          .toList();

      _todayIntakes.addAll(newIntakes);
      
      // Sort by timestamp
      _todayIntakes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      await _saveLocalData();

    } catch (e) {
      AppLogger.error('Error syncing with Firestore: $e');
      // Continue with local data only
    }
  }

  Future<List<WaterIntake>> getWaterIntakeHistory(String userId, {int days = 7}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('water_intake')
          .where('timestamp', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('timestamp', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => WaterIntake.fromMap(doc.data()))
          .toList();

    } catch (e) {
      AppLogger.error('Error getting water intake history: $e');
      return [];
    }
  }
}