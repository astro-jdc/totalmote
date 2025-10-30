import '../config/tv_config_loader.dart';
import 'generic_tv_service.dart';
import '../utils/app_logger.dart';

/// Factory class to create TV services based on brand
class TVServiceFactory {
  static final Map<String, GenericTVService> _serviceCache = {};

  /// Create a TV service for a specific brand
  static Future<GenericTVService> createService(String brand) async {
    try {
      // Check if service already exists in cache
      if (_serviceCache.containsKey(brand)) {
        logger.d('Returning cached service for $brand');
        return _serviceCache[brand]!;
      }

      // Load configuration for the brand
      logger.i('Creating new TV service for $brand');
      final config = await TVConfigLoader.loadConfig(brand);

      // Create service with the config
      final service = GenericTVService(config);

      // Cache it
      _serviceCache[brand] = service;

      logger.i('Successfully created ${config.brand} TV service');
      return service;
    } catch (e) {
      logger.e('Failed to create TV service for $brand', error: e);
      rethrow;
    }
  }

  /// Get list of supported TV brands
  static Future<List<String>> getSupportedBrands() async {
    return await TVConfigLoader.getAvailableBrands();
  }

  /// Get service if it exists in cache
  static GenericTVService? getExistingService(String brand) {
    return _serviceCache[brand];
  }

  /// Clear service cache
  static void clearCache() {
    // Dispose all services before clearing
    for (var service in _serviceCache.values) {
      service.dispose();
    }
    _serviceCache.clear();
    logger.d('TV service cache cleared');
  }

  /// Dispose a specific service
  static void disposeService(String brand) {
    if (_serviceCache.containsKey(brand)) {
      _serviceCache[brand]!.dispose();
      _serviceCache.remove(brand);
      logger.d('Disposed TV service for $brand');
    }
  }
}