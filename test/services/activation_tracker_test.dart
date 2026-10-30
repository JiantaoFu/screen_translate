import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/activation_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<(String, Map<String, Object>)> events;
  late DateTime now;
  late ActivationTracker tracker;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events = [];
    now = DateTime(2026, 10, 15, 12);
    tracker = ActivationTracker(
      sink: (name, params) => events.add((name, params)),
      clock: () => now,
    );
  });

  Map<String, Object> only(String name) =>
      events.singleWhere((e) => e.$1 == name).$2;

  test('funnel steps carry the language pair and the permission outcome', () {
    tracker.startRequested(sourceLanguage: 'ja', targetLanguage: 'en', mode: 'onDevice');
    tracker.overlayPermissionResult(true);
    tracker.capturePermissionResult(false);

    expect(events.map((e) => e.$1), [
      'live_start_requested',
      'overlay_permission_result',
      'capture_permission_result',
    ]);
    expect(only('live_start_requested'), {'language_pair': 'ja_en', 'mode': 'onDevice'});
    expect(only('overlay_permission_result'), {'granted': 'yes'});
    expect(only('capture_permission_result'), {'granted': 'no'});
  });

  test('the consent prompt is reported apart from the system permission', () {
    tracker.startRequested(sourceLanguage: 'ja', targetLanguage: 'en', mode: 'onDevice');
    tracker.captureConsentPrompt(false);

    // Backing out of our own explanation must not look like a denied
    // MediaProjection dialog, or the two refusals cannot be told apart.
    expect(events.map((e) => e.$1), ['live_start_requested', 'capture_consent_prompt']);
    expect(only('capture_consent_prompt'), {'outcome': 'cancel'});
  });

  test('continuing past the consent prompt is its own outcome', () {
    tracker.captureConsentPrompt(true);
    expect(only('capture_consent_prompt'), {'outcome': 'continue'});
  });

  test('first_translation_shown fires once per install with seconds since install', () async {
    await tracker.recordAppOpen();
    now = now.add(const Duration(minutes: 3));
    tracker.startRequested(sourceLanguage: 'en', targetLanguage: 'zh', mode: 'onDevice');
    tracker.liveStarted();

    await tracker.translationShown(2);
    await tracker.translationShown(1);

    expect(events.where((e) => e.$1 == 'first_translation_shown'), hasLength(1));
    expect(only('first_translation_shown')['secs_since_install'], 180);
  });

  test('first_translation_shown survives a new tracker (app restart)', () async {
    await tracker.recordAppOpen();
    await tracker.translationShown(1);

    final restarted = ActivationTracker(
      sink: (name, params) => events.add((name, params)),
      clock: () => now,
    );
    await restarted.translationShown(1);

    expect(events.where((e) => e.$1 == 'first_translation_shown'), hasLength(1));
  });

  test('recordAppOpen keeps the first install time', () async {
    await tracker.recordAppOpen();
    now = now.add(const Duration(days: 2));
    await tracker.recordAppOpen();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(ActivationTracker.prefFirstSeenMs),
        DateTime(2026, 10, 15, 12).millisecondsSinceEpoch);
  });

  test('a session that stops quickly with nothing shown is flagged early', () {
    tracker.startRequested(sourceLanguage: 'ja', targetLanguage: 'en', mode: 'onDevice');
    tracker.liveStarted();
    tracker.ocrFrame(0);
    tracker.ocrFrame(0);
    tracker.ocrFrame(3);
    now = now.add(const Duration(seconds: 5));
    tracker.liveStopped();

    final stopped = only('live_stopped');
    expect(stopped['early'], 'yes');
    expect(stopped['duration_s'], 5);
    expect(stopped['ocr_frames'], 3);
    expect(stopped['ocr_empty_frames'], 2);
    expect(stopped['boxes_shown'], 0);
  });

  test('a quick stop after showing boxes, or a long empty one, is not early', () async {
    tracker.startRequested(sourceLanguage: 'ja', targetLanguage: 'en', mode: 'onDevice');
    tracker.liveStarted();
    await tracker.translationShown(4);
    now = now.add(const Duration(seconds: 3));
    tracker.liveStopped();
    expect(only('live_stopped')['early'], 'no');
    expect(only('live_stopped')['boxes_shown'], 4);

    events.clear();
    tracker.liveStarted();
    now = now.add(const Duration(seconds: 60));
    tracker.liveStopped();
    expect(only('live_stopped')['early'], 'no');
  });

  test('live_stopped is sent once, and not without a started session', () {
    tracker.liveStopped();
    expect(events, isEmpty);

    tracker.liveStarted();
    tracker.liveStopped();
    tracker.liveStopped();
    expect(events.where((e) => e.$1 == 'live_stopped'), hasLength(1));
  });

  test('a new session starts its counters from zero', () {
    tracker.liveStarted();
    tracker.ocrFrame(0);
    tracker.liveStopped();
    events.clear();

    tracker.liveStarted();
    tracker.liveStopped();
    expect(only('live_stopped')['ocr_frames'], 0);
    expect(only('live_stopped')['ocr_empty_frames'], 0);
  });

  test('a failure repeating every tick is reported once per session', () {
    tracker.liveStarted();
    for (var i = 0; i < 50; i++) {
      tracker.failure('capture_tick', StateError('x'));
    }
    tracker.failure('start', ArgumentError('y'));

    final failures = events.where((e) => e.$1 == 'live_failure').toList();
    expect(failures, hasLength(2));
    expect(failures.first.$2, {'where': 'capture_tick', 'error_type': 'StateError'});

    tracker.liveStarted();
    tracker.failure('capture_tick', StateError('x'));
    expect(events.where((e) => e.$1 == 'live_failure'), hasLength(3));
  });

  test('model_download includes the failure class only when there is one', () {
    tracker.modelDownload(kind: 'ai', key: 'ko-en', outcome: 'completed', durationMs: 1200);
    tracker.modelDownload(
        kind: 'quick', key: 'ja', outcome: 'failed', durationMs: 90000, failure: 'SocketException');

    expect(events[0].$2.containsKey('failure'), false);
    expect(events[1].$2['failure'], 'SocketException');
    expect(events[1].$2['outcome'], 'failed');
  });

  test('the failure question is claimed once per install, even across restarts', () async {
    expect(await tracker.claimFailureFeedback(), true);
    expect(await tracker.claimFailureFeedback(), false);

    final restarted = ActivationTracker(sink: (_, __) {}, clock: () => now);
    expect(await restarted.claimFailureFeedback(), false);
  });

  test('failure feedback reports the chosen reason under the outcome parameter', () {
    tracker.startRequested(sourceLanguage: 'ko', targetLanguage: 'en', mode: 'onnx');
    tracker.failureFeedback('no_text');

    expect(only('first_failure_feedback'),
        {'outcome': 'no_text', 'language_pair': 'ko_en', 'mode': 'onnx'});
    expect(ActivationTracker.failureReasons,
        containsAll(['no_text', 'wrong', 'slow', 'other', 'skipped']));
  });

  test('a throwing sink never reaches the caller', () {
    final broken = ActivationTracker(sink: (_, __) => throw StateError('analytics down'));
    expect(() => broken.liveStarted(), returnsNormally);
    expect(() => broken.liveStopped(), returnsNormally);
    expect(() => broken.modelDownload(kind: 'ai', key: 'k', outcome: 'completed', durationMs: 1),
        returnsNormally);
  });

  group('first_translation_shown', () {
    test('carries the box count', () async {
      tracker.startRequested(sourceLanguage: 'ja', targetLanguage: 'en', mode: 'onnx');
      await tracker.translationShown(3);
      expect(only('first_translation_shown')['boxes'], 3);
    });

    test('a tick that drew no box does not count as the first translation', () async {
      await tracker.translationShown(0);
      expect(events, isEmpty);
      await tracker.translationShown(2);
      expect(only('first_translation_shown')['boxes'], 2);
    });
  });

  group('first_ocr_text_found', () {
    test('fires once per install on the first frame with text, with time since live start',
        () async {
      tracker.startRequested(sourceLanguage: 'ja', targetLanguage: 'en', mode: 'onDevice');
      tracker.liveStarted();
      tracker.ocrFrame(0);
      now = now.add(const Duration(milliseconds: 1500));
      tracker.ocrFrame(4);
      await tracker.pendingFirstOcrText;
      tracker.ocrFrame(7);

      expect(only('first_ocr_text_found'), {
        'mode': 'onDevice',
        'language_pair': 'ja_en',
        'text_block_count': 4,
        'ms_since_live_start': 1500,
      });

      final restarted = ActivationTracker(
        sink: (name, params) => events.add((name, params)),
        clock: () => now,
      );
      restarted.liveStarted();
      restarted.ocrFrame(2);
      await restarted.pendingFirstOcrText;
      expect(events.where((e) => e.$1 == 'first_ocr_text_found'), hasLength(1));
    });

    test('leaves out the live-start time when there is no live session', () async {
      tracker.ocrFrame(1);
      await tracker.pendingFirstOcrText;
      expect(only('first_ocr_text_found').containsKey('ms_since_live_start'), false);
    });

    test('still counts the frame for live_stopped', () async {
      tracker.liveStarted();
      tracker.ocrFrame(2);
      await tracker.pendingFirstOcrText;
      tracker.liveStopped();
      expect(only('live_stopped')['ocr_frames'], 1);
      expect(only('live_stopped')['ocr_empty_frames'], 0);
    });
  });

  group('first_translation_failed', () {
    test('reports stage, a short error code and the mode, once per install', () async {
      tracker.startRequested(sourceLanguage: 'ko', targetLanguage: 'en', mode: 'onnx');
      await tracker.firstTranslationFailed(stage: 'translate', error: StateError('secret text'));
      await tracker.firstTranslationFailed(stage: 'render', error: ArgumentError('x'));

      expect(only('first_translation_failed'),
          {'stage': 'translate', 'error_type': 'StateError', 'mode': 'onnx'});

      final restarted = ActivationTracker(
        sink: (name, params) => events.add((name, params)),
        clock: () => now,
      );
      await restarted.firstTranslationFailed(stage: 'ocr', error: StateError('x'));
      expect(events.where((e) => e.$1 == 'first_translation_failed'), hasLength(1));
    });

    test('is not sent once a translation was shown on this install', () async {
      await tracker.translationShown(1);
      await tracker.firstTranslationFailed(stage: 'ocr', error: StateError('x'));

      final restarted = ActivationTracker(
        sink: (name, params) => events.add((name, params)),
        clock: () => now,
      );
      await restarted.firstTranslationFailed(stage: 'ocr', error: StateError('x'));
      expect(events.where((e) => e.$1 == 'first_translation_failed'), isEmpty);
    });

    test('never carries an error message, only the type', () async {
      await tracker.firstTranslationFailed(
          stage: 'translate', error: Exception('Bonjour, mon mot de passe est 1234'));
      final params = only('first_translation_failed');
      expect(params['error_type'], isNot(contains('Bonjour')));
      expect(params.values.join(' '), isNot(contains('1234')));
    });

    test('an unknown stage becomes other', () async {
      await tracker.firstTranslationFailed(stage: 'somewhere', error: StateError('x'));
      expect(only('first_translation_failed')['stage'], 'other');
    });

    test('a failed model download counts as the model stage', () async {
      tracker.modelDownload(
          kind: 'ai', key: 'ko-en', outcome: 'failed', durationMs: 10, failure: 'SocketException');
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(only('first_translation_failed'),
          {'stage': 'model', 'error_type': 'SocketException', 'mode': 'onnx'});
    });

    test('a completed model download is not a failure', () async {
      tracker.modelDownload(kind: 'quick', key: 'ja', outcome: 'completed', durationMs: 10);
      await Future<void>.delayed(Duration.zero);
      expect(events.where((e) => e.$1 == 'first_translation_failed'), isEmpty);
    });
  });

  test('errorCode keeps only the type, never a thrown string', () {
    expect(ActivationTracker.errorCode(StateError('x')), 'StateError');
    expect(ActivationTracker.errorCode('my secret screen text'), 'String');
    expect(ActivationTracker.errorCode(null), 'unknown');
    expect(ActivationTracker.shortCode('Platform Exception: <b>'), 'Platform_Exception___b_');
    expect(ActivationTracker.shortCode('A' * 80).length, 40);
    expect(ActivationTracker.shortCode(''), 'unknown');
  });

  test('a thrown string is reported as String, not its text', () async {
    await tracker.firstTranslationFailed(stage: 'ocr', error: 'Hola 555-1234');
    expect(only('first_translation_failed')['error_type'], 'String');
  });

  test('accessibility events use yes/no and a fixed action list', () {
    tracker.accessibilityPromptShown();
    tracker.accessibilityPermissionResult(enabled: true, action: 'settings_opened');
    tracker.accessibilityPermissionResult(enabled: false, action: 'whatever');
    expect(events[0].$1, 'accessibility_prompt_shown');
    expect(events[0].$2, isEmpty);
    expect(events[1].$2, {'enabled': 'yes', 'action': 'settings_opened'});
    expect(events[2].$2, {'enabled': 'no', 'action': 'unknown'});
  });
}
