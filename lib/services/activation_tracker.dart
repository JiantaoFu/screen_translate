import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_analytics_service.dart';

typedef AnalyticsSink = void Function(String name, Map<String, Object> params);

/// First-use funnel for the paid-upfront app. A buyer can refund within two
/// hours, so what matters most is whether the first session reaches a live
/// translation on screen. Events, in funnel order:
///
///   first_open (Firebase) -> live_start_requested -> overlay_permission_result
///   -> capture_permission_result -> live_started -> first_ocr_text_found
///   -> first_translation_shown
///
/// plus `live_stopped` (how the session ended), `model_download`,
/// `first_translation_failed` (the first thing that broke before any
/// translation was ever shown) and the accessibility prompt
/// (`accessibility_prompt_shown` -> `accessibility_permission_result`).
/// Nothing here records screen content, only steps, counts, durations and
/// exception class names.
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
  static const prefFirstTranslationLogged =
      'activation_first_translation_logged';
  static const prefFailureFeedbackAsked = 'activation_failure_feedback_asked';
  static const prefFirstOcrTextLogged = 'activation_first_ocr_text_logged';
  static const prefFirstTranslationFailedLogged =
      'activation_first_translation_failed_logged';

  /// Where a first translation can break, for `first_translation_failed`.
  static const failureStages = [
    'start',
    'capture',
    'ocr',
    'translate',
    'render',
    'model'
  ];

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
  // In-memory short cuts so the 500 ms capture loop doesn't read prefs on
  // every tick once the once-per-install event is out.
  bool _firstOcrTextDone = false;
  bool _firstTranslationDone = false;
  bool _firstFailureDone = false;

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
  /// The first pass that finds any text fires `first_ocr_text_found`, once
  /// per install.
  void ocrFrame(int blocks) {
    _ocrFrames++;
    if (blocks == 0) {
      _ocrEmptyFrames++;
    } else if (!_firstOcrTextDone) {
      _firstOcrTextDone = true;
      _firstOcrTextFound(blocks);
    }
  }

  /// Completes once `first_ocr_text_found` was sent (or skipped as already
  /// sent); tests await it, the capture loop doesn't.
  @visibleForTesting
  Future<void>? pendingFirstOcrText;

  void _firstOcrTextFound(int blocks) {
    final start = _sessionStart;
    final params = <String, Object>{
      'mode': _mode,
      'language_pair': _pair,
      'text_block_count': blocks,
      if (start != null)
        'ms_since_live_start': _clock().difference(start).inMilliseconds,
    };
    pendingFirstOcrText = _oncePerInstall(prefFirstOcrTextLogged, () {
      _emit('first_ocr_text_found', params);
    });
  }

  /// Runs [send] if [key] was never set, and sets it. Never throws.
  Future<void> _oncePerInstall(String key, void Function() send) async {
    try {
      final prefs = await _prefs();
      if (prefs.getBool(key) ?? false) return;
      await prefs.setBool(key, true);
      send();
    } catch (_) {}
  }

  /// [boxes] translation boxes were drawn on screen. The first call with at
  /// least one box fires `first_translation_shown` once per install, with
  /// the box count and the time since the install first ran.
  Future<void> translationShown(int boxes) async {
    _translationsShown += boxes;
    if (boxes <= 0 || _firstTranslationDone) return;
    _firstTranslationDone = true;
    try {
      final prefs = await _prefs();
      if (prefs.getBool(prefFirstTranslationLogged) ?? false) return;
      await prefs.setBool(prefFirstTranslationLogged, true);
      final firstSeen = prefs.getInt(prefFirstSeenMs);
      final params = <String, Object>{
        'language_pair': _pair,
        'mode': _mode,
        'boxes': boxes,
      };
      if (firstSeen != null) {
        params['secs_since_install'] = _clock()
            .difference(DateTime.fromMillisecondsSinceEpoch(firstSeen))
            .inSeconds;
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
  static const failureReasons = [
    'no_text',
    'wrong',
    'slow',
    'other',
    'skipped'
  ];

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
    if (outcome == 'failed') {
      // Quick packs are ML Kit (onDevice), AI packs are ONNX; used when no
      // session has started yet, so the mode is still unknown.
      firstTranslationFailed(
        stage: 'model',
        code: failure ?? 'unknown',
        mode: _mode.isNotEmpty ? _mode : (kind == 'ai' ? 'onnx' : 'onDevice'),
      );
    }
  }

  /// The first failure on the way to a first translation: once per install,
  /// and only while no translation has ever been shown on this install.
  /// [stage] is one of [failureStages]. The `error_type` is [error]'s class
  /// name (never its message), or [code] when the caller already has a
  /// class-name code (model downloads); both cut to a short identifier.
  ///
  /// [error] is content-free by construction — only its runtime type is
  /// read. [code] cannot be: it is whatever the caller passes, reduced to a
  /// short identifier but not otherwise inspected, so callers must pass a
  /// class name (`e.runtimeType.toString()`) and never a message, which
  /// could carry a file path, a URL or user content.
  Future<void> firstTranslationFailed({
    required String stage,
    Object? error,
    String? code,
    String? mode,
  }) async {
    if (_firstFailureDone || _firstTranslationDone) return;
    _firstFailureDone = true;
    final params = <String, Object>{
      'stage': failureStages.contains(stage) ? stage : 'other',
      'error_type': code != null ? shortCode(code) : errorCode(error),
      'mode': mode ?? _mode,
    };
    try {
      final prefs = await _prefs();
      if (prefs.getBool(prefFirstTranslationLogged) ?? false) {
        _firstTranslationDone = true;
        return;
      }
    } catch (_) {}
    await _oncePerInstall(prefFirstTranslationFailedLogged, () {
      _emit('first_translation_failed', params);
    });
  }

  /// Content-free code for an error: its runtime type name only. A thrown
  /// String (`throw 'some text'`) becomes `String`, never the text.
  @visibleForTesting
  static String errorCode(Object? error) =>
      error == null ? 'unknown' : shortCode(error.runtimeType.toString());

  /// [raw] reduced to `[A-Za-z0-9_]`, at most 40 characters.
  @visibleForTesting
  static String shortCode(String raw) {
    final code = raw.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    if (code.isEmpty) return 'unknown';
    return code.length > 40 ? code.substring(0, 40) : code;
  }

  /// The one-time accessibility explainer (native AccessibilityPermissionActivity) was shown.
  void accessibilityPromptShown() =>
      _emit('accessibility_prompt_shown', <String, Object>{});

  /// What the accessibility service looked like once the user left that
  /// explainer. [action] is how they left it: `settings_opened`,
  /// `dismissed`, `already_enabled` (closed itself) or `unknown`.
  void accessibilityPermissionResult(
          {required bool enabled, required String action}) =>
      _emit('accessibility_permission_result', {
        'enabled': _yesNo(enabled),
        'action': accessibilityActions.contains(action) ? action : 'unknown',
      });

  static const accessibilityActions = [
    'settings_opened',
    'dismissed',
    'already_enabled',
    'unknown'
  ];

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
