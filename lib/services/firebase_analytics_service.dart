import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();

  // Resolved on first use, not in the constructor: FirebaseAnalytics.instance
  // throws until Firebase.initializeApp has run, and this singleton's field
  // initializer would otherwise make the whole service unconstructable
  // before startup finishes (and in tests).
  FirebaseAnalytics? _injected;
  FirebaseAnalytics get _analytics => _injected ??= FirebaseAnalytics.instance;
  final Logger _logger = Logger('FirebaseAnalyticsService');

  factory FirebaseAnalyticsService() {
    return _instance;
  }

  FirebaseAnalyticsService._internal();

  /// Lets a test drive the service without a live Firebase app.
  @visibleForTesting
  // ignore: use_setters_to_change_properties
  void debugUseAnalytics(FirebaseAnalytics analytics) => _injected = analytics;

  /// Initialize Firebase Analytics.
  ///
  /// Lets failures propagate. This runs as a startup step (see
  /// startup_tasks.dart), and a step that swallows its own error reports
  /// "ok" for a launch where analytics never came up — which is exactly the
  /// blind spot that made every funnel denominator untrustworthy.
  Future<void> init() async {
    // Enable analytics collection
    await _analytics.setAnalyticsCollectionEnabled(true);
    _logger.info('Firebase Analytics initialized');
  }

  /// Log a custom event, letting failures propagate.
  ///
  /// For callers that need to know whether the event actually went out —
  /// the startup steps, which otherwise log "ok" for a dropped event.
  Future<void> logEventOrThrow(
    String eventName, [
    Map<String, Object>? parameters,
  ]) async {
    // Firebase has restrictions on event names and parameter names
    final sanitizedName = _sanitizeEventName(eventName);
    final sanitizedParams = _sanitizeParameters(parameters);

    await _analytics.logEvent(
      name: sanitizedName,
      parameters: sanitizedParams,
    );
    _logger.info('Event logged: $sanitizedName with params: $sanitizedParams');
  }

  /// Log a custom event. Never throws: analytics must not break a feature.
  Future<void> logEvent(
    String eventName, [
    Map<String, Object>? parameters,
  ]) async {
    try {
      await logEventOrThrow(eventName, parameters);
    } catch (e) {
      _logger.severe('Error logging event: $e');
    }
  }

  /// Track app open event.
  ///
  /// Propagates failures: `app_opened` is the denominator of every funnel,
  /// including the 2 h activation north star, so its startup step has to be
  /// able to say it failed rather than logging "ok" for a launch that was
  /// never counted.
  Future<void> trackAppOpen() => logEventOrThrow('app_opened');

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

  /// Track translation performance metrics
  Future<void> trackPerformance({
    required int captureMs,
    required int ocrMs,
    required int translateMs,
    required int renderMs,
    required int totalMs,
    required String translationType,
  }) async {
    try {
      await logEvent(
        'translation_performance',
        {
          'capture_ms': captureMs,
          'ocr_ms': ocrMs,
          'translate_ms': translateMs,
          'render_ms': renderMs,
          'total_ms': totalMs,
          'translation_type': translationType,
        },
      );
    } catch (e) {
      _logger.severe('Error tracking performance: $e');
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

  /// Track error — also forwarded to Crashlytics as a non-fatal record so
  /// it shows up with a real stack trace and groups with related crashes,
  /// instead of living only as a bare type/message pair in Analytics.
  Future<void> trackError({
    required String errorType,
    required String errorMessage,
    StackTrace? stackTrace,
  }) async {
    try {
      await logEvent(
        'app_error',
        {
          'error_type': errorType,
          'error_message': errorMessage,
        },
      );
      await FirebaseCrashlytics.instance.recordError(
        errorMessage,
        stackTrace,
        reason: errorType,
        fatal: false,
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

  /// Track a request for an AI-mode language pair we don't support yet —
  /// the passive demand signal for "which model should we build next",
  /// logged from the exact point a user hits that wall rather than relying
  /// on them finding a separate feedback channel.
  Future<void> trackLanguagePairRequest({
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    try {
      await logEvent(
        'ai_language_pair_requested',
        {
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
        },
      );
    } catch (e) {
      _logger.severe('Error tracking language pair request: $e');
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
