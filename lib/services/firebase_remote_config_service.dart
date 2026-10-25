import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:logging/logging.dart';

class FirebaseRemoteConfigService {
  static final FirebaseRemoteConfigService _instance = FirebaseRemoteConfigService._internal();
  late FirebaseRemoteConfig _remoteConfig;
  final Logger _logger = Logger('FirebaseRemoteConfigService');

  factory FirebaseRemoteConfigService() {
    return _instance;
  }

  FirebaseRemoteConfigService._internal() {
    _remoteConfig = FirebaseRemoteConfig.instance;
  }

  /// Initialize Remote Config with default values
  Future<void> init() async {
    try {
      // Set default values (used before fetching from server)
      await _remoteConfig.setDefaults({
        'debug_ocr_boxes': false,
        'ocr_min_text_length': 1,
        'enable_analytics': true,
        'translation_timeout_seconds': 30,
        'max_concurrent_translations': 3,
      });

      // Set cache duration - how long to use cached values before fetching fresh
      // For development: 0 seconds (always fetch fresh)
      // For production: 3600 seconds (1 hour)
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 20),
          minimumFetchInterval: const Duration(seconds: 0), // Dev: fetch every time
        ),
      );

      // Fetch and activate remote config
      await _remoteConfig.fetchAndActivate();
      _logger.info('Firebase Remote Config initialized');
    } catch (e) {
      _logger.severe('Failed to initialize Remote Config: $e');
    }
  }

  /// Get boolean configuration
  bool getBool(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      _logger.warning('Error getting bool config for key: $key, $e');
      return false;
    }
  }

  /// Get string configuration
  String getString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      _logger.warning('Error getting string config for key: $key, $e');
      return '';
    }
  }

  /// Get integer configuration
  int getInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      _logger.warning('Error getting int config for key: $key, $e');
      return 0;
    }
  }

  /// Get double configuration
  double getDouble(String key) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      _logger.warning('Error getting double config for key: $key, $e');
      return 0.0;
    }
  }

  // Specific getters for your app

  /// Check if OCR debug boxes should be drawn
  bool isDebugOCRBoxesEnabled() => getBool('debug_ocr_boxes');

  /// Get minimum text length for OCR results
  int getOCRMinTextLength() => getInt('ocr_min_text_length');

  /// Check if analytics is enabled
  bool isAnalyticsEnabled() => getBool('enable_analytics');

  /// Get translation timeout in seconds
  int getTranslationTimeoutSeconds() => getInt('translation_timeout_seconds');

  /// Get max concurrent translations
  int getMaxConcurrentTranslations() => getInt('max_concurrent_translations');

  /// Manually fetch fresh config from server
  Future<void> fetchAndActivate() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      _logger.info('Remote config updated: $updated');
    } catch (e) {
      _logger.severe('Error fetching remote config: $e');
    }
  }

  /// Get all current values (useful for debugging)
  Map<String, RemoteConfigValue> getAllValues() {
    return _remoteConfig.getAll();
  }

  /// Print all config values to logs
  void logAllValues() {
    final values = _remoteConfig.getAll();
    values.forEach((key, value) {
      _logger.info('$key: ${value.asString()}');
    });
  }
}
