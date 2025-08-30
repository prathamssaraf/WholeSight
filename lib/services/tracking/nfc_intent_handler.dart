import 'package:flutter/services.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:whole_sight/services/tracking/water_tracking_service.dart';
import 'package:whole_sight/services/auth/auth_service.dart';
import 'package:whole_sight/di/dependency_injection.dart';
import 'package:whole_sight/core/utils/logger.dart';

class NfcIntentHandler {
  static const MethodChannel _channel = MethodChannel('com.example.wholesight/nfc');
  static WaterTrackingService? _waterService;
  
  static Future<void> initialize() async {
    try {
      // Set method call handler for native NFC intents
      _channel.setMethodCallHandler(_handleMethodCall);
      AppLogger.info('NFC Intent Handler initialized');
    } catch (e) {
      AppLogger.error('Error initializing NFC Intent Handler: $e');
    }
  }
  
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'handleNfcIntent':
        final String? ndefMessage = call.arguments['ndef_message'];
        if (ndefMessage != null) {
          await _processNfcIntent(ndefMessage);
        }
        break;
      default:
        AppLogger.warning('Unknown method call: ${call.method}');
    }
  }
  
  static Future<void> _processNfcIntent(String ndefMessage) async {
    try {
      AppLogger.info('Processing NFC intent with message: $ndefMessage');
      
      // Check if this is a water bottle sticker
      if (ndefMessage.contains('water_bottle_150ml')) {
        await _handleWaterBottleSticker();
      } else {
        AppLogger.info('NFC tag is not a water bottle sticker');
      }
    } catch (e) {
      AppLogger.error('Error processing NFC intent: $e');
    }
  }
  
  static Future<void> _handleWaterBottleSticker() async {
    try {
      // Initialize water service if not already done
      if (_waterService == null) {
        _waterService = WaterTrackingService();
        
        // Get current user and initialize service
        final user = await getIt<AuthService>().getCurrentUser();
        if (user != null) {
          await _waterService!.initialize(user.id);
        } else {
          AppLogger.error('No current user found for NFC water tracking');
          return;
        }
      }
      
      // Add 150ml water intake automatically
      final user = await getIt<AuthService>().getCurrentUser();
      if (user != null) {
        await _waterService!.addWaterIntake(
          userId: user.id,
          amountMl: 150.0,
          source: 'nfc',
        );
        
        AppLogger.info('Automatically added 150ml water intake from NFC scan');
        
        // Show notification or update UI (this would need to be handled differently
        // as we don't have direct access to the UI context here)
        _showNfcWaterIntakeNotification();
      }
    } catch (e) {
      AppLogger.error('Error handling water bottle NFC sticker: $e');
    }
  }
  
  static void _showNfcWaterIntakeNotification() {
    // This could be implemented using local notifications
    // or by sending an event to the UI layer
    AppLogger.info('Should show notification: Added 150ml water from NFC scan');
  }
  
  // Method to handle NFC tags discovered through the app's NFC scanning
  static Future<void> processDiscoveredTag(NfcTag tag) async {
    try {
      final ndef = Ndef.from(tag);
      if (ndef?.cachedMessage != null) {
        for (final record in ndef!.cachedMessage!.records) {
          final payload = String.fromCharCodes(record.payload);
          
          if (payload.contains('water_bottle_150ml')) {
            await _handleWaterBottleSticker();
            return;
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error processing discovered NFC tag: $e');
    }
  }
}