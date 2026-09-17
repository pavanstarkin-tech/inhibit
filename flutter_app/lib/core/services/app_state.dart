import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/life_in_weeks.dart';
import '../models/rule_bundle_model.dart';
import 'native_shield_service.dart';
import 'sleep_schedule.dart';

class BlockedEvent {
  final String serviceId;
  final String ruleId;
  final int count;
  final DateTime timestamp;

  const BlockedEvent({
    required this.serviceId,
    required this.ruleId,
    required this.count,
    required this.timestamp,
  });
}

class RuleHealthEntry {
  final String ruleId;
  final int expected;
  final int actual;
  final bool isStale;

  const RuleHealthEntry({
    required this.ruleId,
    required this.expected,
    required this.actual,
    required this.isStale,
  });
}

class AppState extends ChangeNotifier {
  static const _keySettings = 'noscroll.settings';
  static const _keyOnboarded = 'noscroll.onboarded';
  static const _keyAge = 'noscroll.age';
  static const _keyScrollHours = 'noscroll.scroll_hours';
  static const _keySleepEnabled = 'noscroll.sleep_enabled';
  static const _keySleepStart = 'noscroll.sleep_start';
  static const _keySleepEnd = 'noscroll.sleep_end';
  static const _keyPostUnlocksDate = 'noscroll.post_unlocks_date';
  static const _keyPostUnlocksCount = 'noscroll.post_unlocks_count';
  static const _keyTotalBlocked = 'noscroll.total_blocked';
  static const _keyNativeInstaReels = 'noscroll.native_insta_reels';
  static const _keyNativeInstaExplore = 'noscroll.native_insta_explore';
  static const _keyNativeYtShorts = 'noscroll.native_yt_shorts';
  static const _keyShieldedApps = 'noscroll.shielded_apps';

  static const Map<String, String> serviceToPackage = {
    'instagram': 'com.instagram.android',
    'youtube': 'com.google.android.youtube',
  };

  bool _initialized = false;
  bool get isInitialized => _initialized;

  String _engineSource = '';
  String get engineSource => _engineSource;

  final Map<String, RuleBundle> _bundles = {};
  Map<String, RuleBundle> get bundles => Map.unmodifiable(_bundles);

  final Map<String, String> _rawBundles = {};
  Map<String, String> get rawBundles => Map.unmodifiable(_rawBundles);

  final Map<String, bool> _settings = {};
  Map<String, bool> get settings => Map.unmodifiable(_settings);

  final Map<String, bool> _shieldedNativeApps = {
    'instagram': true,
    'youtube': true,
  };
  Map<String, bool> get shieldedNativeApps => Map.unmodifiable(_shieldedNativeApps);

  bool _needsOnboarding = true;
  bool get needsOnboarding => _needsOnboarding;

  int _age = 22;
  int get age => _age;

  double _scrollHoursPerDay = 4.8;
  double get scrollHoursPerDay => _scrollHoursPerDay;

  // Sleep mode
  bool _sleepEnabled = false;
  bool get sleepEnabled => _sleepEnabled;

  int _sleepStartMinutes = 22 * 60; // 10:00 PM
  int get sleepStartMinutes => _sleepStartMinutes;

  int _sleepEndMinutes = 7 * 60;   // 7:00 AM
  int get sleepEndMinutes => _sleepEndMinutes;

  // Post mode
  int _postModeUnlocksRemaining = 4;
  int get postModeUnlocksRemaining => _postModeUnlocksRemaining;
  int get postUnlocksRemaining => _postModeUnlocksRemaining;

  Future<void> setSleepEnabled(bool enabled) async {
    await setSleepSchedule(
      enabled: enabled,
      startMinutes: _sleepStartMinutes,
      endMinutes: _sleepEndMinutes,
    );
  }

  // Native Granular OS Shielding
  bool _isAccessibilityGranted = false;
  bool get isAccessibilityGranted => _isAccessibilityGranted;

  bool _nativeShieldInstaReels = true;
  bool get nativeShieldInstaReels => _nativeShieldInstaReels;

  bool _nativeShieldInstaExplore = true;
  bool get nativeShieldInstaExplore => _nativeShieldInstaExplore;

  bool _nativeShieldYtShorts = true;
  bool get nativeShieldYtShorts => _nativeShieldYtShorts;

  // Pending service requested from native shield
  String? _requestedServiceFromShield;
  String? get requestedServiceFromShield => _requestedServiceFromShield;

  // Telemetry & Stats
  int _totalItemsBlocked = 0;
  int get totalItemsBlocked => _totalItemsBlocked;

  final Map<String, int> _blockedByService = {};
  Map<String, int> get blockedByService => Map.unmodifiable(_blockedByService);

  final List<BlockedEvent> _recentBlockedEvents = [];
  List<BlockedEvent> get recentBlockedEvents => List.unmodifiable(_recentBlockedEvents);

  final Map<String, RuleHealthEntry> _ruleHealth = {};
  Map<String, RuleHealthEntry> get ruleHealth => Map.unmodifiable(_ruleHealth);

  late SharedPreferences _prefs;

  LifeInWeeks get lifeInWeeks =>
      LifeInWeeks(age: _age, scrollHoursPerDay: _scrollHoursPerDay);

  SleepSchedule get sleepSchedule => SleepSchedule(
        startMinute: _sleepStartMinutes,
        endMinute: _sleepEndMinutes,
        enabled: _sleepEnabled,
      );

  bool get isSleepActiveNow => sleepSchedule.isActive(DateTime.now());

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    _needsOnboarding = !(_prefs.getBool(_keyOnboarded) ?? false);
    _age = _prefs.getInt(_keyAge) ?? 22;
    _scrollHoursPerDay = _prefs.getDouble(_keyScrollHours) ?? 4.8;
    _sleepEnabled = _prefs.getBool(_keySleepEnabled) ?? false;
    _sleepStartMinutes = _prefs.getInt(_keySleepStart) ?? (22 * 60);
    _sleepEndMinutes = _prefs.getInt(_keySleepEnd) ?? (7 * 60);
    _totalItemsBlocked = _prefs.getInt(_keyTotalBlocked) ?? 0;

    _nativeShieldInstaReels = _prefs.getBool(_keyNativeInstaReels) ?? true;
    _nativeShieldInstaExplore = _prefs.getBool(_keyNativeInstaExplore) ?? true;
    _nativeShieldYtShorts = _prefs.getBool(_keyNativeYtShorts) ?? true;

    _restoreShieldedApps();
    _restorePostMode();
    _restoreSettings();

    await _loadAssets();
    await checkAccessibilityPermission();
    await _syncNativeShieldRules();

    // Check for pending launch from ShieldActivity
    final pendingSvc = await NativeShieldService.getPendingLaunchService();
    if (pendingSvc != null && pendingSvc.isNotEmpty) {
      _requestedServiceFromShield = pendingSvc;
    }

    NativeShieldService.setupIncomingServiceListener((svcId) {
      _requestedServiceFromShield = svcId;
      notifyListeners();
    });

    _initialized = true;
    notifyListeners();
  }

  void consumeRequestedService() {
    _requestedServiceFromShield = null;
  }

  void _restoreShieldedApps() {
    final raw = _prefs.getString(_keyShieldedApps);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) {
          if (v is bool) _shieldedNativeApps[k] = v;
        });
      } catch (_) {}
    }
  }

  void _restoreSettings() {
    final raw = _prefs.getString(_keySettings);
    if (raw != null) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        map.forEach((k, v) {
          if (v is bool) _settings[k] = v;
        });
      } catch (e) {
        if (kDebugMode) print('Failed to restore settings: $e');
      }
    }
  }

  void _restorePostMode() {
    final today = _dateKey(DateTime.now());
    final savedDate = _prefs.getString(_keyPostUnlocksDate);
    if (savedDate == today) {
      _postModeUnlocksRemaining = _prefs.getInt(_keyPostUnlocksCount) ?? 4;
    } else {
      _postModeUnlocksRemaining = 4;
      _prefs.setString(_keyPostUnlocksDate, today);
      _prefs.setInt(_keyPostUnlocksCount, 4);
    }
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  Future<void> _loadAssets() async {
    try {
      _engineSource = await rootBundle.loadString('assets/engine/noscroll.js');
    } catch (e) {
      if (kDebugMode) print('Error loading noscroll.js: $e');
    }

    final services = [
      'instagram',
      'youtube',
    ];

    for (final svc in services) {
      try {
        final raw = await rootBundle.loadString('assets/rules/$svc.json');
        _rawBundles[svc] = raw;
        _bundles[svc] = RuleBundle.fromRawJson(raw);
      } catch (e) {
        if (kDebugMode) print('Error loading rule bundle $svc: $e');
      }
    }
  }

  // --- Setting Mutations ---

  Future<void> completeOnboarding({required int age, required double scrollHours}) async {
    _age = age;
    _scrollHoursPerDay = scrollHours;
    _needsOnboarding = false;
    await _prefs.setInt(_keyAge, age);
    await _prefs.setDouble(_keyScrollHours, scrollHours);
    await _prefs.setBool(_keyOnboarded, true);
    notifyListeners();
  }

  Future<void> updateAge(int age) async {
    _age = age;
    await _prefs.setInt(_keyAge, age);
    notifyListeners();
  }

  Future<void> updateScrollHours(double hours) async {
    _scrollHoursPerDay = hours;
    await _prefs.setDouble(_keyScrollHours, hours);
    notifyListeners();
  }

  bool isSurfaceEnabled(String serviceId, String surfaceKey) {
    final id = '$serviceId.$surfaceKey';
    if (_settings.containsKey(id)) {
      return _settings[id]!;
    }
    final bundle = _bundles[serviceId];
    final surface = bundle?.services[serviceId]?.surfaces[surfaceKey];
    return surface?.defaultEnabled ?? true;
  }

  Future<void> setSurfaceEnabled(String serviceId, String surfaceKey, bool enabled) async {
    final id = '$serviceId.$surfaceKey';
    _settings[id] = enabled;
    await _prefs.setString(_keySettings, jsonEncode(_settings));
    notifyListeners();
  }

  bool isNativeAppShielded(String serviceId) {
    return _shieldedNativeApps[serviceId] ?? false;
  }

  Future<void> setNativeAppShielded(String serviceId, bool shielded) async {
    _shieldedNativeApps[serviceId] = shielded;
    await _prefs.setString(_keyShieldedApps, jsonEncode(_shieldedNativeApps));

    final pkg = serviceToPackage[serviceId];
    if (pkg != null) {
      await NativeShieldService.setPackageShielded(pkg, shielded);
    }
    notifyListeners();
  }

  Future<void> setSleepSchedule({
    required bool enabled,
    required int startMinutes,
    required int endMinutes,
  }) async {
    _sleepEnabled = enabled;
    _sleepStartMinutes = startMinutes;
    _sleepEndMinutes = endMinutes;
    await _prefs.setBool(_keySleepEnabled, enabled);
    await _prefs.setInt(_keySleepStart, startMinutes);
    await _prefs.setInt(_keySleepEnd, endMinutes);
    notifyListeners();
  }

  bool usePostUnlock() {
    _restorePostMode();
    if (_postModeUnlocksRemaining > 0) {
      _postModeUnlocksRemaining--;
      _prefs.setInt(_keyPostUnlocksCount, _postModeUnlocksRemaining);
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- Native OS Granular Shielding ---

  Future<void> checkAccessibilityPermission() async {
    _isAccessibilityGranted = await NativeShieldService.isAccessibilityGranted();
    notifyListeners();
  }

  Future<void> openAccessibilitySettings() async {
    await NativeShieldService.openAccessibilitySettings();
  }

  Future<void> setGranularShield({
    bool? blockInstaReels,
    bool? blockInstaExplore,
    bool? blockYtShorts,
  }) async {
    if (blockInstaReels != null) {
      _nativeShieldInstaReels = blockInstaReels;
      await _prefs.setBool(_keyNativeInstaReels, blockInstaReels);
    }
    if (blockInstaExplore != null) {
      _nativeShieldInstaExplore = blockInstaExplore;
      await _prefs.setBool(_keyNativeInstaExplore, blockInstaExplore);
    }
    if (blockYtShorts != null) {
      _nativeShieldYtShorts = blockYtShorts;
      await _prefs.setBool(_keyNativeYtShorts, blockYtShorts);
    }
    await _syncNativeShieldRules();
    notifyListeners();
  }

  Future<void> _syncNativeShieldRules() async {
    await NativeShieldService.updateShieldRules(
      blockInstaReels: _nativeShieldInstaReels,
      blockInstaExplore: _nativeShieldInstaExplore,
      blockYtShorts: _nativeShieldYtShorts,
    );

    for (final entry in _shieldedNativeApps.entries) {
      final pkg = serviceToPackage[entry.key];
      if (pkg != null) {
        await NativeShieldService.setPackageShielded(pkg, entry.value);
      }
    }
  }

  // --- Engine JavaScript Bootstrap Generator ---

  String generateBootstrapJs(String serviceId) {
    final rawBundle = _rawBundles[serviceId] ?? '{}';
    final configMap = {
      'bundle': jsonDecode(rawBundle),
      'settings': _settings,
      'telemetry': kDebugMode,
    };
    final configJson = jsonEncode(configMap);

    return '''
      window.__NOSCROLL_CONFIG = $configJson;
      $_engineSource
    ''';
  }

  // --- Bridge Message Dispatcher ---

  void handleBridgeMessage(String rawJson, {String serviceId = ''}) {
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final type = map['type'] as String?;

      if (kDebugMode) {
        print('[NoScrollBridge] Received: $type -> $rawJson');
      }

      switch (type) {
        case 'blocked':
          final ruleId = map['ruleId'] as String? ?? 'unknown';
          final count = map['count'] as int? ?? 1;
          _recordBlocked(serviceId: serviceId.isNotEmpty ? serviceId : ruleId.split('.').first, ruleId: ruleId, count: count);
          break;

        case 'probe':
          final ruleId = map['ruleId'] as String? ?? '';
          final expected = map['expected'] as int? ?? 0;
          final actual = map['actual'] as int? ?? 0;
          final isStale = expected > 0 && actual == 0;
          _ruleHealth[ruleId] = RuleHealthEntry(
            ruleId: ruleId,
            expected: expected,
            actual: actual,
            isStale: isStale,
          );
          notifyListeners();
          break;

        case 'auth-surface':
          break;

        default:
          break;
      }
    } catch (e) {
      if (kDebugMode) print('[NoScrollBridge] Parse error: $e ($rawJson)');
    }
  }

  void _recordBlocked({required String serviceId, required String ruleId, required int count}) {
    _totalItemsBlocked += count;
    _blockedByService[serviceId] = (_blockedByService[serviceId] ?? 0) + count;
    _recentBlockedEvents.insert(
      0,
      BlockedEvent(
        serviceId: serviceId,
        ruleId: ruleId,
        count: count,
        timestamp: DateTime.now(),
      ),
    );
    if (_recentBlockedEvents.length > 50) {
      _recentBlockedEvents.removeLast();
    }
    _prefs.setInt(_keyTotalBlocked, _totalItemsBlocked);
    notifyListeners();
  }
}
