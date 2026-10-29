import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/lite/daily_translation_quota.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late DateTime now;
  late int remoteLimit;

  DailyTranslationQuota quota() =>
      DailyTranslationQuota(prefs, now: () => now, limit: () => remoteLimit);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 10, 17, 9, 30);
    remoteLimit = 5;
  });

  test('fresh install: nothing used, translating allowed (no paywall at launch)', () {
    final q = quota();
    expect(q.usedToday, 0);
    expect(q.remaining, 5);
    expect(q.canTranslate(isPro: false), isTrue);
  });

  test('5 successes are allowed; the 5th reports justExhausted and blocks the next', () async {
    final q = quota();
    for (var i = 1; i <= 4; i++) {
      final use = await q.recordSuccess(isPro: false);
      expect(use.usedToday, i);
      expect(use.remaining, 5 - i);
      expect(use.justExhausted, isFalse);
      expect(q.canTranslate(isPro: false), isTrue);
    }
    final fifth = await q.recordSuccess(isPro: false);
    expect(fifth.remaining, 0);
    expect(fifth.justExhausted, isTrue);
    expect(q.canTranslate(isPro: false), isFalse);
  });

  test('justExhausted fires only once per day', () async {
    final q = quota();
    for (var i = 0; i < 5; i++) {
      await q.recordSuccess(isPro: false);
    }
    // e.g. a session already running when the limit was reached
    final extra = await q.recordSuccess(isPro: false);
    expect(extra.justExhausted, isFalse);
    expect(extra.remaining, 0);
  });

  test('counter resets on the next local day', () async {
    final q = quota();
    for (var i = 0; i < 5; i++) {
      await q.recordSuccess(isPro: false);
    }
    now = DateTime(2026, 10, 17, 23, 59, 59);
    expect(q.canTranslate(isPro: false), isFalse);
    now = DateTime(2026, 10, 18, 0, 0, 1);
    expect(q.usedToday, 0);
    expect(q.remaining, 5);
    expect(q.canTranslate(isPro: false), isTrue);
    final use = await q.recordSuccess(isPro: false);
    expect(use.usedToday, 1);
    expect(prefs.getString(DailyTranslationQuota.dayKey), '2026-10-18');
  });

  test('a stored count from an older day is ignored, even across months/years', () async {
    await prefs.setString(DailyTranslationQuota.dayKey, '2025-12-31');
    await prefs.setInt(DailyTranslationQuota.countKey, 99);
    now = DateTime(2026, 1, 1, 0, 5);
    expect(quota().usedToday, 0);
  });

  test('limit comes from Remote Config and is re-read each time', () async {
    remoteLimit = 3;
    final q = quota();
    await q.recordSuccess(isPro: false);
    await q.recordSuccess(isPro: false);
    final third = await q.recordSuccess(isPro: false);
    expect(third.dailyLimit, 3);
    expect(third.justExhausted, isTrue);
    expect(q.canTranslate(isPro: false), isFalse);
    remoteLimit = 10; // fetched later in the day
    expect(q.remaining, 7);
    expect(q.canTranslate(isPro: false), isTrue);
  });

  test('unusable remote values (0, negative) fall back to the default 5', () {
    remoteLimit = 0;
    expect(quota().dailyLimit, DailyTranslationQuota.defaultLimit);
    remoteLimit = -2;
    expect(quota().dailyLimit, 5);
  });

  test('pro bypasses the limit and is not counted', () async {
    final q = quota();
    for (var i = 0; i < 5; i++) {
      await q.recordSuccess(isPro: false);
    }
    expect(q.canTranslate(isPro: true), isTrue);
    final use = await q.recordSuccess(isPro: true);
    expect(use.justExhausted, isFalse);
    expect(q.usedToday, 5);
  });

  test('dayStamp is the local calendar day, zero padded', () {
    expect(DailyTranslationQuota.dayStamp(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });
}
