import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/accessibility_funnel_reporter.dart';
import 'package:screen_translate/services/activation_tracker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = AccessibilityFunnelReporter.defaultChannel;
  late List<(String, Map<String, Object>)> events;
  late AccessibilityFunnelReporter reporter;
  late int calls;
  Object? Function()? answer;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events = [];
    calls = 0;
    reporter = AccessibilityFunnelReporter(
      tracker: ActivationTracker(sink: (name, params) => events.add((name, params))),
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'takeAccessibilityFunnel');
      calls++;
      return answer?.call();
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    answer = null;
  });

  test('prompt shown and the result become the two events', () async {
    answer = () => {
          'promptShown': true,
          'result': {'enabled': true, 'action': 'settings_opened'},
        };
    await reporter.report();
    expect(events.map((e) => e.$1),
        ['accessibility_prompt_shown', 'accessibility_permission_result']);
    expect(events[0].$2, isEmpty);
    expect(events[1].$2, {'enabled': 'yes', 'action': 'settings_opened'});
  });

  test('nothing pending sends nothing', () async {
    answer = () => {'promptShown': false};
    await reporter.report();
    expect(events, isEmpty);
  });

  test('a disabled service after dismissing is reported as no', () async {
    answer = () => {
          'promptShown': false,
          'result': {'enabled': false, 'action': 'dismissed'},
        };
    await reporter.report();
    expect(events.single.$2, {'enabled': 'no', 'action': 'dismissed'});
  });

  test('an unexpected action code is reported as unknown', () async {
    answer = () => {
          'result': {'enabled': false, 'action': 'some screen text'},
        };
    await reporter.report();
    expect(events.single.$2['action'], 'unknown');
  });

  test('overlapping resumes share one native call', () async {
    answer = () => {'promptShown': true};
    await Future.wait([reporter.report(), reporter.report()]);
    expect(calls, 1);
    expect(events, hasLength(1));
  });

  test('a missing or failing native side is ignored', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await expectLater(reporter.report(), completes);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => throw PlatformException(code: 'x'));
    await expectLater(reporter.report(), completes);
    expect(events, isEmpty);
  });
}
