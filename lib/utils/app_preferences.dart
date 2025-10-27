import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class AppPreferences {
  static const String _keyLastTVBrand = 'last_tv_brand';
  static const String _keyLastTVIP = 'last_tv_ip';
  static const String _keyLastTVName = 'last_tv_name';

  static SharedPreferences? _prefs;

  /// Initialize preferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    logger.d('App preferences initialized');
  }

  /// Save last used TV configuration
  static Future<void> saveLastTV({
    required String brand,
    required String ipAddress,
    String? tvName,
  }) async {
    if (_prefs == null) await init();

    await _prefs!.setString(_keyLastTVBrand, brand);
    await _prefs!.setString(_keyLastTVIP, ipAddress);
    if (tvName != null) {
      await _prefs!.setString(_keyLastTVName, tvName);
    }

    logger.i('Saved last TV: $brand at $ipAddress');
  }

  /// Get last used TV brand
  static String? getLastTVBrand() {
    return _prefs?.getString(_keyLastTVBrand);
  }

  /// Get last used TV IP address
  static String? getLastTVIP() {
    return _prefs?.getString(_keyLastTVIP);
  }

  /// Get last used TV name
  static String? getLastTVName() {
    return _prefs?.getString(_keyLastTVName);
  }

  /// Check if there's a saved TV configuration
  static bool hasSavedTV() {
    final brand = getLastTVBrand();
    final ip = getLastTVIP();
    return brand != null && brand.isNotEmpty && ip != null && ip.isNotEmpty;
  }

  /// Clear saved TV configuration
  static Future<void> clearLastTV() async {
    if (_prefs == null) await init();

    await _prefs!.remove(_keyLastTVBrand);
    await _prefs!.remove(_keyLastTVIP);
    await _prefs!.remove(_keyLastTVName);

    logger.i('Cleared last TV configuration');
  }
}
