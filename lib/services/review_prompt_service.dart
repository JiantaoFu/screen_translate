import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What [ReviewPromptService.maybeRequestReview] did.
enum ReviewPromptOutcome { notDue, unavailable, requested, failed }

/// Decides when to ask for a Play in-app review.
///
/// Rules (1.2.6):
/// - ask once the user has had 3 successful translation sessions (a live
///   session that drew at least one translation counts once, however many
///   500 ms capture ticks it ran);
/// - at most once per device per 90 days;
/// - not during an app run that recorded an error (download failure, or a
///   crash on the previous run). Until 1.2.5 this was a permanent per-device
///   flag, so one flaky model download blocked the prompt forever; the old
///   flag is now ignored.
/// - if Play's in-app review API is unavailable, skip silently (log only).
///   Never fall back to opening the store or showing a message the user
///   didn't ask for.
class ReviewPromptService {
  static const successCountKey = 'review_success_count';
  static const lastPromptAtKey = 'review_last_prompt_at_ms';
  /// Legacy (<= 1.2.5) permanent error flag. No longer read.
  static const errorFlagKey = 'review_error_flag';

  // Errors block the prompt for the rest of this app run only.
  static bool _errorThisSession = false;

  @visibleForTesting
  static void resetSessionForTest() => _errorThisSession = false;

  static const successThreshold = 3;
  static const cooldown = Duration(days: 90);

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  ReviewPromptService(this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  Future<void> recordSuccessfulTranslation() async {
    final n = (_prefs.getInt(successCountKey) ?? 0) + 1;
    await _prefs.setInt(successCountKey, n);
  }

  Future<void> recordError() async {
    _errorThisSession = true;
  }

  bool get hasError => _errorThisSession;

  int get successCount => _prefs.getInt(successCountKey) ?? 0;

  DateTime? get lastPromptAt {
    final ms = _prefs.getInt(lastPromptAtKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Whether we should show the in-app review prompt right now.
  bool shouldPrompt({DateTime? at}) {
    if (hasError) return false;
    if (successCount < successThreshold) return false;
    final now = at ?? _now();
    final last = lastPromptAt;
    if (last != null && now.difference(last) < cooldown) return false;
    // First ask: exactly when we reach the threshold (or any later moment
    // if we haven't asked yet). After that, cooldown alone gates re-asks.
    return true;
  }

  Future<void> markPromptShown({DateTime? at}) async {
    final now = at ?? _now();
    await _prefs.setInt(lastPromptAtKey, now.millisecondsSinceEpoch);
  }

  /// Asks for a review if one is due. [isAvailable] and [requestReview] are
  /// `InAppReview.instance.isAvailable` / `requestReview` in the app.
  ///
  /// Unavailable (no Play Store, unsupported device) or a failing request
  /// is logged and otherwise ignored, and the prompt isn't marked as shown,
  /// so the cooldown only starts after a real request.
  Future<ReviewPromptOutcome> maybeRequestReview({
    required Future<bool> Function() isAvailable,
    required Future<void> Function() requestReview,
    void Function(String message)? log,
  }) async {
    final logger = log ?? debugPrint;
    if (!shouldPrompt()) return ReviewPromptOutcome.notDue;
    bool available;
    try {
      available = await isAvailable();
    } catch (e) {
      logger('In-app review: availability check failed: $e');
      available = false;
    }
    if (!available) {
      logger('In-app review: unavailable on this device, skipping silently');
      return ReviewPromptOutcome.unavailable;
    }
    try {
      await requestReview();
    } catch (e) {
      logger('In-app review: request failed, skipping silently: $e');
      return ReviewPromptOutcome.failed;
    }
    await markPromptShown();
    return ReviewPromptOutcome.requested;
  }
}
