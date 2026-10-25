import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_translate/services/review_prompt_service.dart';

void main() {
  late SharedPreferences prefs;
  late DateTime now;
  late ReviewPromptService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    ReviewPromptService.resetSessionForTest();
    prefs = await SharedPreferences.getInstance();
    now = DateTime.utc(2026, 10, 5, 12);
    service = ReviewPromptService(prefs, now: () => now);
  });

  test('threshold is 3 successful sessions', () {
    expect(ReviewPromptService.successThreshold, 3);
  });

  test('does not prompt before the 3rd success', () async {
    await service.recordSuccessfulTranslation();
    await service.recordSuccessfulTranslation();
    expect(service.shouldPrompt(), isFalse);
  });

  test('prompts on the 3rd success', () async {
    for (var i = 0; i < 3; i++) {
      await service.recordSuccessfulTranslation();
    }
    expect(service.shouldPrompt(), isTrue);
  });

  test('success count persists across service instances (app restarts)',
      () async {
    await service.recordSuccessfulTranslation();
    await service.recordSuccessfulTranslation();
    final again = ReviewPromptService(prefs, now: () => now);
    await again.recordSuccessfulTranslation();
    expect(again.successCount, 3);
    expect(again.shouldPrompt(), isTrue);
  });

  test('legacy permanent error flag from <= 1.2.5 no longer blocks', () async {
    await prefs.setBool(ReviewPromptService.errorFlagKey, true);
    for (var i = 0; i < 3; i++) {
      await service.recordSuccessfulTranslation();
    }
    expect(service.shouldPrompt(), isTrue);
  });

  test('an error only blocks for the current app run', () async {
    for (var i = 0; i < 3; i++) {
      await service.recordSuccessfulTranslation();
    }
    await service.recordError();
    expect(service.shouldPrompt(), isFalse);
    ReviewPromptService.resetSessionForTest(); // next app run
    expect(ReviewPromptService(prefs, now: () => now).shouldPrompt(), isTrue);
  });

  test('does not prompt after an error in this run', () async {
    for (var i = 0; i < ReviewPromptService.successThreshold; i++) {
      await service.recordSuccessfulTranslation();
    }
    await service.recordError();
    expect(service.shouldPrompt(), isFalse);
  });

  test('at most once per 90 days', () async {
    for (var i = 0; i < ReviewPromptService.successThreshold; i++) {
      await service.recordSuccessfulTranslation();
    }
    expect(service.shouldPrompt(), isTrue);
    await service.markPromptShown();
    expect(service.shouldPrompt(), isFalse);

    now = now.add(const Duration(days: 89));
    expect(service.shouldPrompt(), isFalse);

    now = now.add(const Duration(days: 2));
    expect(service.shouldPrompt(), isTrue);
  });

  test('error recorded later also blocks a cooldown-eligible prompt', () async {
    for (var i = 0; i < ReviewPromptService.successThreshold; i++) {
      await service.recordSuccessfulTranslation();
    }
    await service.markPromptShown();
    now = now.add(const Duration(days: 91));
    await service.recordError();
    expect(service.shouldPrompt(), isFalse);
  });

  group('maybeRequestReview', () {
    Future<void> reachThreshold() async {
      for (var i = 0; i < ReviewPromptService.successThreshold; i++) {
        await service.recordSuccessfulTranslation();
      }
    }

    test('review API unavailable: no request, silent, not marked as shown',
        () async {
      await reachThreshold();
      var requested = 0;
      final logs = <String>[];
      final outcome = await service.maybeRequestReview(
        isAvailable: () async => false,
        requestReview: () async => requested++,
        log: logs.add,
      );
      expect(outcome, ReviewPromptOutcome.unavailable);
      expect(requested, 0);
      expect(service.lastPromptAt, isNull);
      expect(logs, hasLength(1), reason: 'logged only');
    });

    test('availability check throwing is treated as unavailable', () async {
      await reachThreshold();
      var requested = 0;
      final outcome = await service.maybeRequestReview(
        isAvailable: () async => throw Exception('no Play Store'),
        requestReview: () async => requested++,
        log: (_) {},
      );
      expect(outcome, ReviewPromptOutcome.unavailable);
      expect(requested, 0);
    });

    test('available: requests once and starts the cooldown', () async {
      await reachThreshold();
      var requested = 0;
      final outcome = await service.maybeRequestReview(
        isAvailable: () async => true,
        requestReview: () async => requested++,
        log: (_) {},
      );
      expect(outcome, ReviewPromptOutcome.requested);
      expect(requested, 1);
      expect(service.lastPromptAt!.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch);
      expect(
        await service.maybeRequestReview(
          isAvailable: () async => true,
          requestReview: () async => requested++,
          log: (_) {},
        ),
        ReviewPromptOutcome.notDue,
      );
      expect(requested, 1);
    });

    test('a failing request is swallowed and not marked', () async {
      await reachThreshold();
      final outcome = await service.maybeRequestReview(
        isAvailable: () async => true,
        requestReview: () async => throw Exception('play error'),
        log: (_) {},
      );
      expect(outcome, ReviewPromptOutcome.failed);
      expect(service.lastPromptAt, isNull);
    });

    test('not due: availability is not even checked', () async {
      var checked = false;
      final outcome = await service.maybeRequestReview(
        isAvailable: () async => checked = true,
        requestReview: () async {},
        log: (_) {},
      );
      expect(outcome, ReviewPromptOutcome.notDue);
      expect(checked, isFalse);
    });
  });
}
