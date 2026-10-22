import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Result of recording one successful translation.
class QuotaUse {
  final int usedToday;
  final int dailyLimit;
  final int remaining;

  /// This success used up the last free translation of the day: the moment
  /// to show the paywall (the user has just seen the translation).
  final bool justExhausted;

  const QuotaUse({
    required this.usedToday,
    required this.dailyLimit,
    required this.remaining,
    required this.justExhausted,
  });
}

/// Lite flavor's free allowance: [dailyLimit] successful translations per
/// local calendar day (Remote Config `lite_daily_free_translations`, default 5).
///
/// What counts as one translation (see TranslationProvider / LiteGate):
/// - one live Start session that drew at least one translation on screen
///   (however many capture ticks or manual captures it ran), or
/// - one image translation (gallery or shared image) that returned text.
/// Sessions that show nothing, denied permissions and failures don't count.
///
/// The limit only blocks the next *attempt* once it is used up; a session in
/// progress is never cut off, and nothing is blocked at app launch before
/// the user has translated anything that day.
class DailyTranslationQuota {
  static const dayKey = 'lite_quota_day';
  static const countKey = 'lite_quota_count';
  static const defaultLimit = 5;

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final int Function() _limit;

  DailyTranslationQuota(
    this._prefs, {
    DateTime Function()? now,
    int Function()? limit,
  })  : _now = now ?? DateTime.now,
        _limit = limit ?? (() => defaultLimit);

  /// The current limit; unusable values (< 1) fall back to [defaultLimit].
  int get dailyLimit {
    final n = _limit();
    return n >= 1 ? n : defaultLimit;
  }

  /// Local calendar day, e.g. 2026-10-17.
  static String dayStamp(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  String get _today => dayStamp(_now());

  int get usedToday =>
      _prefs.getString(dayKey) == _today ? (_prefs.getInt(countKey) ?? 0) : 0;

  int get remaining => max(0, dailyLimit - usedToday);

  bool get isExhausted => remaining == 0;

  /// Whether a new translation may start. Pro is always allowed.
  bool canTranslate({required bool isPro}) => isPro || !isExhausted;

  /// Counts one success. Pro successes aren't counted (Pro is unlimited).
  Future<QuotaUse> recordSuccess({required bool isPro}) async {
    final limit = dailyLimit;
    if (isPro) {
      return QuotaUse(usedToday: usedToday, dailyLimit: limit, remaining: remaining, justExhausted: false);
    }
    final before = usedToday;
    final used = before + 1;
    await _prefs.setString(dayKey, _today);
    await _prefs.setInt(countKey, used);
    final left = max(0, limit - used);
    return QuotaUse(
      usedToday: used,
      dailyLimit: limit,
      remaining: left,
      justExhausted: before < limit && used >= limit,
    );
  }
}
