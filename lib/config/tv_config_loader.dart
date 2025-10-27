import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'dart:convert';
import '../models/tv_config_model.dart';
import '../utils/app_logger.dart';

class TVConfigLoader {
  static final Map<String, TVConfig> _configCache = {};
  static List<String>? _cachedBrands;

  /// Load a TV configuration by brand
  static Future<TVConfig> loadConfig(String brand) async {
    // Check cache first
    if (_configCache.containsKey(brand)) {
      logger.d('Loading $brand config from cache');
      return _configCache[brand]!;
    }

    try {
      // Load YAML file
      final configPath = 'assets/${brand.toLowerCase()}.yaml';
      final yamlString = await rootBundle.loadString(configPath);

      // Parse YAML
      final yamlMap = loadYaml(yamlString);

      // Create config object
      final config = TVConfig.fromYaml(yamlMap);

      // Cache it
      _configCache[brand] = config;

      logger.i('Loaded configuration for ${config.brand}');
      return config;
    } catch (e) {
      logger.e('Failed to load config for $brand', error: e);
      throw Exception('Could not load configuration for $brand: $e');
    }
  }

  /// Get list of available TV brands by scanning asset files
  static Future<List<String>> getAvailableBrands() async {
    // Return cached brands if available
    if (_cachedBrands != null) {
      return _cachedBrands!;
    }

    try {
      // Load the asset manifest
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Find all YAML files in assets folder
      final brands = <String>[];

      for (String key in manifestMap.keys) {
        if (key.startsWith('assets/') && key.endsWith('.yaml')) {
          // Extract filename without path and extension
          final filename = key
              .replaceFirst('assets/', '')
              .replaceFirst('.yaml', '');

          // Exclude non-TV config files (like tizen_os_samsung.yaml)
          if (filename == 'samsung' ||
              filename == 'lg_webos' ||
              filename == 'android_tv') {
            brands.add(filename);
          }
        }
      }

      brands.sort();
      _cachedBrands = brands;

      logger.i('Found ${brands.length} TV configuration(s): ${brands.join(", ")}');
      return brands;
    } catch (e) {
      logger.e('Failed to load available brands', error: e);
      // Fallback to hardcoded list
      return ['samsung', 'lg_webos', 'android_tv'];
    }
  }

  /// Clear config cache
  static void clearCache() {
    _configCache.clear();
    _cachedBrands = null;
    logger.d('TV config cache cleared');
  }
}