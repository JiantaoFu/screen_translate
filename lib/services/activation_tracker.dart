import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_analytics_service.dart';

typedef AnalyticsSink = void Function(String name, Map<String, Object> params);

/// First-use funnel for the paid-upfront app. A buyer can refund within two
/// hours, so what matters most is whether the first session reaches a live
/// translation on screen. Events, in funnel order:
///
///   first_open (Firebase) -> live_start_requested -> overlay_permission_result
///   -> capture_permission_result -> live_started -> first_translation_shown
///
/// plus `live_stopped` (how the session ended) and `model_download`.
/// Nothing here records screen content, only steps, counts and durations.
class ActivationTracker {
  ActivationTracker({
    AnalyticsSink? sink,
    DateTime Function()? clock,
    Future<SharedPreferences> Function()? prefs,
  })  : _sink = sink ?? _firebaseSink,
        _clock = clock ?? DateTime.now,
        _prefs = prefs ?? SharedPreferences.getInstance;

  static final ActivationTracker instance = ActivationTracker();

  static const prefFirstSeenMs = 'activation_first_seen_ms';
  static const prefFirstTranslationLogged = 'activation_first_translation_logged';
  static const prefFailureFeedbackAsked = 'activation_failure_feedback_asked';

  /// A session that ends this quickly without ever showing a translation is
  /// the "it did nothing" signal.
  static const earlyStopSeconds = 10;

  final AnalyticsSink _sink;
  final DateTime Function() _clock;
  final Future<SharedPreferences> Function() _prefs;

  DateTime? _sessionStart;
  int _ocrFrames = 0;
  int _ocrEmptyFrames = 0;
  int _translationsShown = 0;
  String _pair = '';
  String _mode = '';
  final Set<String> _failuresThisSession = {};

  static void _firebaseSink(String name, Map<String, Object> params) {
    FirebaseAnalyticsService().logEvent(name, params);
  }

  void _emit(String name, Map<String, Object> params) {
    try {
      _sink(name, params);
    } catch (_) {
      // Analytics must never break the capture loop.
    }
  }

  /// Remember when this install first ran; call once on every app open.
  Future<void> recordAppOpen() async {
    try {
      final prefs = await _prefs();
      if (!prefs.containsKey(prefFirstSeenMs)) {
        await prefs.setInt(prefFirstSeenMs, _clock().millisecondsSinceEpoch);
      }
    } catch (_) {}
  }

  void startRequested({
    required String sourceLanguage,
    required String targetLanguage,
    required String mode,
  }) {
    _pair = '${sourceLanguage}_$targetLanguage';
    _mode = mode;
    _emit('live_start_requested', {'language_pair': _pair, 'mode': _mode});
  }

  // GA receives bools as numbers, which can only be metrics. Report yes/no
  // so these can be registered as dimensions.
  static String _yesNo(bool value) => value ? 'yes' : 'no';

  void overlayPermissionResult(bool granted) =>
      _emit('overlay_permission_result', {'granted': _yesNo(granted)});

  void capturePermissionResult(bool granted) =>
      _emit('capture_permission_result', {'granted': _yesNo(granted)});

  void liveStarted() {
    _sessionStart = _clock();
    _ocrFrames = 0;
    _ocrEmptyFrames = 0;
    _translationsShown = 0;
    _failuresThisSession.clear();
    _emit('live_started', {'language_pair': _pair, 'mode': _mode});
  }

  /// One OCR pass; [blocks] is how many translatable text blocks it found.
  void ocrFrame(int blocks) {
    _ocrFrames++;
    if (blocks == 0) _ocrEmptyFrames++;
  }

  /// Boxes were drawn on screen. Fires `first_translation_shown` once per
  /// install, with the time since the install first ran.
  Future<void> translationShown(int boxes) async {
    _translationsShown += boxes;
    try {
      final prefs = await _prefs();
      if (prefs.getBool(prefFirstTranslationLogged) ?? false) return;
      await prefs.setBool(prefFirstTranslationLogged, true);
      final firstSeen = prefs.getInt(prefFirstSeenMs);
      final params = <String, Object>{'language_pair': _pair, 'mode': _mode};
      if (firstSeen != null) {
        params['secs_since_install'] =
            _clock().difference(DateTime.fromMillisecondsSinceEpoch(firstSeen)).inSeconds;
      }
      _emit('first_translation_shown', params);
    } catch (_) {}
  }

  void liveStopped() {
    final start = _sessionStart;
    if (start == null) return;
    _sessionStart = null;
    final seconds = _clock().difference(start).inSeconds;
    _emit('live_stopped', {
      'language_pair': _pair,
      'mode': _mode,
      'duration_s': seconds,
      'boxes_shown': _translationsShown,
      'ocr_frames': _ocrFrames,
      'ocr_empty_frames': _ocrEmptyFrames,
      'early': _yesNo(seconds < earlyStopSeconds && _translationsShown == 0),
    });
  }

  /// Whether to ask "what went wrong?" after a session that showed nothing.
  /// True once per install: the first such session is the one that decides
  /// whether the buyer refunds, and asking again would only annoy.
  Future<bool> claimFailureFeedback() async {
    try {
      final prefs = await _prefs();
      if (prefs.getBool(prefFailureFeedbackAsked) ?? false) return false;
      await prefs.setBool(prefFailureFeedbackAsked, true);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The answer to that question; [reason] is one of [failureReasons].
  void failureFeedback(String reason) => _emit('first_failure_feedback', {
        'outcome': reason,
        'language_pair': _pair,
        'mode': _mode,
      });

  /// `no_text`, `wrong`, `slow`, `other` (opened the email form) or
  /// `skipped` (closed the dialog).
  static const failureReasons = ['no_text', 'wrong', 'slow', 'other', 'skipped'];

  /// [kind] is `quick` (ML Kit) or `ai` (ONNX pack); [failure] is a short
  /// error class, never a message that could carry user content.
  void modelDownload({
    required String kind,
    required String key,
    required String outcome,
    required int durationMs,
    String? failure,
  }) {
    _emit('model_download', {
      'kind': kind,
      'model': key,
      'outcome': outcome,
      'duration_ms': durationMs,
      if (failure != null) 'failure': failure,
    });
  }

  /// Why a start or a capture failed, for the failures that raise no crash.
  /// Logged once per place per session: the capture loop ticks twice a second.
  void failure(String where, Object error) {
    if (!_failuresThisSession.add(where)) return;
    _emit('live_failure', {
      'where': where,
      'error_type': error.runtimeType.toString(),
    });
  }
}
