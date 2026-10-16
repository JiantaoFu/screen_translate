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
}
