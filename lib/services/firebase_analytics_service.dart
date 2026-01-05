import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logging/logging.dart';

class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  late FirebaseAnalytics _analytics;
  final Logger _logger = Logger('FirebaseAnalyticsService');

  factory FirebaseAnalyticsService() {
    return _instance;
  }

  FirebaseAnalyticsService._internal() {
    _analytics = FirebaseAnalytics.instance;
  }

  /// Initialize Firebase Analytics
  Future<void> init() async {
    try {
      // Enable analytics collection
      await _analytics.setAnalyticsCollectionEnabled(true);
      _logger.info('Firebase Analytics initialized');
    } catch (e) {
      _logger.severe('Failed to initialize Firebase Analytics: $e');
    }
  }

  /// Log a custom event
  Future<void> logEvent(
    String eventName, [
    Map<String, Object>? parameters,
  ]) async {
    try {
      // Firebase has restrictions on event names and parameter names
      final sanitizedName = _sanitizeEventName(eventName);
      final sanitizedParams = _sanitizeParameters(parameters);

      await _analytics.logEvent(
        name: sanitizedName,
        parameters: sanitizedParams,
      );
      _logger.info('Event logged: $sanitizedName with params: $sanitizedParams');
    } catch (e) {
      _logger.severe('Error logging event: $e');
    }
  }

  /// Track app open event
  Future<void> trackAppOpen() async {
    try {
      await logEvent('app_opened');
    } catch (e) {
      _logger.severe('Error tracking app open: $e');
    }
  }

  /// Track screen view
  Future<void> trackScreenView(String screenName) async {
    try {
      await _analytics.logScreenView(
        screenName: _sanitizeEventName(screenName),
      );
      _logger.info('Screen viewed: $screenName');
    } catch (e) {
      _logger.severe('Error tracking screen view: $e');
    }
  }

  /// Track translation performed
  Future<void> trackTranslation({
    required String sourceLanguage,
    required String targetLanguage,
    required String translationType,
  }) async {
    try {
      await logEvent(
        'translation_performed',
        {
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
          'translation_type': translationType,
        },
      );
    } catch (e) {
      _logger.severe('Error tracking translation: $e');
    }
  }

  /// Track OCR operation
  Future<void> trackOCR({
    required int textBlocksFound,
    required String language,
  }) async {
    try {
      await logEvent(
        'ocr_performed',
        {
          'text_blocks_found': textBlocksFound,
          'language': language,
        },
      );
    } catch (e) {
      _logger.severe('Error tracking OCR: $e');
    }
  }

  /// Track error
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
  }) async {
    try {
      await logEvent(
        'app_error',
        {
          'error_type': errorType,
          'error_message': errorMessage,
        },
      );
    } catch (e) {
      _logger.severe('Error logging error event: $e');
    }
  }

  /// Track feature usage
  Future<void> trackFeatureUsage(String featureName) async {
    try {
      await logEvent('feature_used', {'feature_name': featureName});
    } catch (e) {
      _logger.severe('Error tracking feature usage: $e');
    }
  }

  /// Set user ID for tracking
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      _logger.info('User ID set: $userId');
    } catch (e) {
      _logger.severe('Error setting user ID: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      _logger.info('User property set: $name = $value');
    } catch (e) {
      _logger.severe('Error setting user property: $e');
    }
  }

  /// Reset user data
  Future<void> resetUserData() async {
    try {
      await _analytics.resetAnalyticsData();
      _logger.info('Analytics data reset');
    } catch (e) {
      _logger.severe('Error resetting analytics data: $e');
    }
  }

  /// Sanitize event name to meet Firebase requirements
  /// Event names must be 40 characters or less, alphanumeric and underscore only
  String _sanitizeEventName(String name) {
    String sanitized = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    // Firebase has a limit of 40 characters
    if (sanitized.length > 40) {
      sanitized = sanitized.substring(0, 40);
    }

    return sanitized;
  }

  /// Sanitize parameters to meet Firebase requirements
  Map<String, Object>? _sanitizeParameters(Map<String, dynamic>? params) {
    if (params == null) return null;

    final sanitized = <String, Object>{};

    for (final entry in params.entries) {
      final key = _sanitizeEventName(entry.key);
      final value = entry.value;

      // Firebase accepts String, int, double, and bool parameter values
      if (value is String) {
        // Firebase has a 100 character limit for parameter values
        sanitized[key] = value.length > 100
            ? value.substring(0, 100)
            : value;
      } else if (value is int || value is double || value is bool) {
        sanitized[key] = value;
      } else {
        // Convert other types to string
        sanitized[key] = value.toString();
      }
    }

    return sanitized.isEmpty ? null : sanitized;
  }
}
