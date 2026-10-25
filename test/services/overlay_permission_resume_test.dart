import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/services/overlay_service.dart';

void main() {
  group('ResumeAfterLeavingObserver', () {
    test('the resumed state we are already in does not count', () async {
      final o = ResumeAfterLeavingObserver();
      var done = false;
      o.resumed.then((_) => done = true);
      o.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(done, isFalse);
    });

    test('completes on return from the settings page', () async {
      final o = ResumeAfterLeavingObserver();
      var done = false;
      o.resumed.then((_) => done = true);
      o.didChangeAppLifecycleState(AppLifecycleState.inactive);
      o.didChangeAppLifecycleState(AppLifecycleState.paused);
      o.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(done, isTrue);
    });
  });

  group('recheckOverlayPermission', () {
    test('granted late (OEM delay) is still picked up', () async {
      var calls = 0;
      final ok = await OverlayService.recheckOverlayPermission(
        () async => ++calls >= 3,
        interval: Duration.zero,
      );
      expect(ok, isTrue);
      expect(calls, 3);
    });

    test('never granted returns false after the attempts', () async {
      var calls = 0;
      final ok = await OverlayService.recheckOverlayPermission(
        () async { calls++; return false; },
        interval: Duration.zero,
      );
      expect(ok, isFalse);
      expect(calls, 5);
    });
  });
}
