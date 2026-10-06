import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_translate/services/review_prompt_service.dart';

void main() {
  late SharedPreferences prefs;
  late DateTime now;
  late ReviewPromptService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime.utc(2026, 10, 5, 12);
    service = ReviewPromptService(prefs, now: () => now);
  });

  test('does not prompt before the 5th success', () async {
    for (var i = 0; i < 4; i++) {
      await service.recordSuccessfulTranslation();
    }
    expect(service.shouldPrompt(), isFalse);
  });

  test('prompts on the 5th success', () async {
    for (var i = 0; i < 5; i++) {
      await service.recordSuccessfulTranslation();
    }
    expect(service.shouldPrompt(), isTrue);
  });

  test('never prompts after an error was recorded', () async {
    for (var i = 0; i < 5; i++) {
      await service.recordSuccessfulTranslation();
    }
    await service.recordError();
    expect(service.shouldPrompt(), isFalse);
  });

  test('at most once per 90 days', () async {
    for (var i = 0; i < 5; i++) {
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
    for (var i = 0; i < 5; i++) {
      await service.recordSuccessfulTranslation();
    }
    await service.markPromptShown();
    now = now.add(const Duration(days: 91));
    await service.recordError();
    expect(service.shouldPrompt(), isFalse);
  });
}
