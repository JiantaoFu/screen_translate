import 'package:shared_preferences/shared_preferences.dart';

/// Decides when to ask for a Play in-app review.
///
/// Rules (frozen for 1.2.4):
/// - ask once after the user's 5th successful translation;
/// - at most once per device per 90 days;
/// - never on a device that has recorded an error (download failure, crash).
class ReviewPromptService {
  static const successCountKey = 'review_success_count';
  static const lastPromptAtKey = 'review_last_prompt_at_ms';
  static const errorFlagKey = 'review_error_flag';

  static const successThreshold = 5;
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
    await _prefs.setBool(errorFlagKey, true);
  }

  bool get hasError => _prefs.getBool(errorFlagKey) ?? false;

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
}
