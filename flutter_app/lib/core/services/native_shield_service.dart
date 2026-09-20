import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeShieldService {
  static const _channel = MethodChannel('app.noscroll/shield');

  static void setupIncomingServiceListener(Function(String serviceId) onServiceRequested) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onOpenServiceFromShield') {
        final serviceId = call.arguments as String?;
        if (serviceId != null && serviceId.isNotEmpty) {
          onServiceRequested(serviceId);
        }
      }
    });
  }

  static Future<String?> getPendingLaunchService() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      return await _channel.invokeMethod<String>('getPendingLaunchService');
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isAccessibilityGranted() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final bool? result = await _channel.invokeMethod<bool>('isAccessibilityGranted');
      return result ?? false;
    } catch (e) {
      if (kDebugMode) print('Error checking accessibility permission: $e');
      return false;
    }
  }

  static Future<bool> openAccessibilitySettings() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final bool? result = await _channel.invokeMethod<bool>('openAccessibilitySettings');
      return result ?? false;
    } catch (e) {
      if (kDebugMode) print('Error opening accessibility settings: $e');
      return false;
    }
  }

  static Future<void> updateShieldRules({
    required bool blockInstaReels,
    required bool blockInstaExplore,
    required bool blockYtShorts,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod('updateShieldRules', {
        'blockInstaReels': blockInstaReels,
        'blockInstaExplore': blockInstaExplore,
        'blockYtShorts': blockYtShorts,
      });
    } catch (e) {
      if (kDebugMode) print('Error updating native shield rules: $e');
    }
  }

  static Future<void> setPackageShielded(String package, bool shielded) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    try {
      await _channel.invokeMethod('setPackageShielded', {
        'package': package,
        'shielded': shielded,
      });
    } catch (e) {
      if (kDebugMode) print('Error setting package shielded: $e');
    }
  }

  static Future<Map<String, int>> getShieldStats() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return {'totalReelsScrolled': 0, 'totalReelsBlocked': 0};
    }
    try {
      final res = await _channel.invokeMapMethod<String, int>('getShieldStats');
      return res ?? {'totalReelsScrolled': 0, 'totalReelsBlocked': 0};
    } catch (e) {
      if (kDebugMode) print('Error getting shield stats: $e');
      return {'totalReelsScrolled': 0, 'totalReelsBlocked': 0};
    }
  }

  static Future<bool> startPostMode({int durationMinutes = 30}) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final bool? res = await _channel.invokeMethod<bool>('startPostMode', {
        'durationMinutes': durationMinutes,
      });
      return res ?? true;
    } catch (e) {
      if (kDebugMode) print('Error starting native post mode: $e');
      return false;
    }
  }

  static Future<bool> isPostModeActive() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final bool? res = await _channel.invokeMethod<bool>('isPostModeActive');
      return res ?? false;
    } catch (e) {
      if (kDebugMode) print('Error checking post mode active: $e');
      return false;
    }
  }

  static Future<int> getPostModeRemainingSeconds() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return 0;
    }
    try {
      final int? res = await _channel.invokeMethod<int>('getPostModeRemainingSeconds');
      return res ?? 0;
    } catch (e) {
      if (kDebugMode) print('Error getting post mode remaining seconds: $e');
      return 0;
    }
  }

  static Future<int> getRemainingLives() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return 4;
    }
    try {
      final int? res = await _channel.invokeMethod<int>('getRemainingLives');
      return res ?? 4;
    } catch (e) {
      if (kDebugMode) print('Error getting remaining lives: $e');
      return 4;
    }
  }

  static Future<bool> consumeLife() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final bool? res = await _channel.invokeMethod<bool>('consumeLife');
      return res ?? false;
    } catch (e) {
      if (kDebugMode) print('Error consuming life: $e');
      return false;
    }
  }

  static Future<bool> simulatePaymentUnlock() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    try {
      final bool? res = await _channel.invokeMethod<bool>('simulatePaymentUnlock');
      return res ?? false;
    } catch (e) {
      if (kDebugMode) print('Error simulating payment unlock: $e');
      return false;
    }
  }

  static Future<bool> openUrl(String url) async {
    try {
      final bool? res = await _channel.invokeMethod<bool>('openUrl', {'url': url});
      return res ?? false;
    } catch (e) {
      if (kDebugMode) print('Error opening URL natively: $e');
      return false;
    }
  }
}

