import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/widgets/screen_capture_consent.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ScreenCaptureConsent.prefs = SharedPreferences.getInstance;
  });

  group('when to explain', () {
    test('explains on a fresh install, and stops once a grant is recorded', () async {
      expect(await ScreenCaptureConsent.shouldExplain(), isTrue);
      await ScreenCaptureConsent.markGranted();
      expect(await ScreenCaptureConsent.shouldExplain(), isFalse);
    });

    test('a denied dialog leaves the explanation in place for the next try', () async {
      // Only markGranted() clears it, so someone who refused Android's prompt
      // sees the reason again rather than the bare system warning.
      expect(await ScreenCaptureConsent.shouldExplain(), isTrue);
      expect(await ScreenCaptureConsent.shouldExplain(), isTrue);
    });

    test('unreadable prefs explain rather than skip', () async {
      ScreenCaptureConsent.prefs = () => Future.error(StateError('no prefs'));
      expect(await ScreenCaptureConsent.shouldExplain(), isTrue);
      // And recording a grant against them must not throw into the caller.
      await ScreenCaptureConsent.markGranted();
    });
  });

  Widget host(void Function(BuildContext) onReady) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => onReady(context),
            child: const Text('go'),
          ),
        ),
      );

  testWidgets('explain() returns what the user chose', (tester) async {
    bool? result;
    await tester.pumpWidget(host((c) async => result = await ScreenCaptureConsent.explain(c)));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    // The dialog has to answer the system prompt's warning, so the body is
    // what carries this feature; an empty one would ship as a silent no-op.
    expect(find.textContaining('reads text'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Grant Permission'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('offerRetry() returns what the user chose', (tester) async {
    bool? result;
    await tester.pumpWidget(host((c) async => result = await ScreenCaptureConsent.offerRetry(c)));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(result, isTrue);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
