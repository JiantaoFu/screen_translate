import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/main.dart';

/// The order of background startup is what decides whether a launch is
/// counted at all: `first_open` comes from the native Firebase SDK, but
/// `app_opened` and the whole activation funnel are sent from here. They
/// used to sit behind Remote Config, whose 20 s fetch overran the 10 s it
/// was given, so on a slow network the launch was never reported and every
/// funnel denominator was wrong.
void main() {
  final names = backgroundStartupTasks().map((t) => t.name).toList();

  int at(String name) {
    final i = names.indexOf(name);
    expect(i, isNonNegative, reason: 'missing startup step "$name" in $names');
    return i;
  }

  test('reporting the launch comes before the slow steps', () {
    expect(at('app_opened'), lessThan(at('Remote Config')));
    expect(at('activation first-seen'), lessThan(at('Remote Config')));
    expect(at('app_opened'), lessThan(at('previous-run crash check')));
    expect(at('activation first-seen'), lessThan(at('previous-run crash check')));
  });

  test('Firebase and crash reporting come first', () {
    expect(at('Firebase'), 0);
    expect(at('crash reporting'), 1);
    expect(at('crash reporting'), lessThan(at('analytics')));
  });

  test('analytics is initialized before the first event is sent', () {
    expect(at('analytics'), lessThan(at('app_opened')));
  });

  test('Remote Config gets more than its own 20 s fetch timeout', () {
    final remoteConfig =
        backgroundStartupTasks().firstWhere((t) => t.name == 'Remote Config');
    expect(remoteConfig.timeout, greaterThan(const Duration(seconds: 20)));
  });
}
