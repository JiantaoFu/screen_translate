import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/services/activation_tracker.dart';
import 'package:screen_translate/widgets/first_failure_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<(String, Map<String, Object>)> events;
  late ActivationTracker tracker;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    events = [];
    tracker = ActivationTracker(sink: (name, params) => events.add((name, params)));
  });

  Future<BuildContext> pumpHost(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold();
      }),
    ));
    return ctx;
  }

  // The dialog future resolves only after a tap, so run it unawaited, then
  // await it once the tap has happened.
  testWidgets('tapping a reason reports it as the outcome', (tester) async {
    final ctx = await pumpHost(tester);
    tracker.startRequested(sourceLanguage: 'ja', targetLanguage: 'en', mode: 'onDevice');

    final result = showFirstFailureFeedback(ctx, tracker: tracker);
    await tester.pumpAndSettle();
    expect(find.text('Nothing was translated. What happened?'), findsOneWidget);

    await tester.tap(find.text('No text was found on screen'));
    await tester.pumpAndSettle();

    expect(await result, 'no_text');
    final feedback = events.singleWhere((e) => e.$1 == 'first_failure_feedback').$2;
    expect(feedback['outcome'], 'no_text');
    expect(feedback['language_pair'], 'ja_en');
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Close is reported as skipped, and the question is not asked again', (tester) async {
    final ctx = await pumpHost(tester);

    final first = showFirstFailureFeedback(ctx, tracker: tracker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(await first, 'skipped');

    final second = await showFirstFailureFeedback(ctx, tracker: tracker);
    await tester.pumpAndSettle();
    expect(second, isNull);
    expect(find.byType(AlertDialog), findsNothing);
    expect(events.where((e) => e.$1 == 'first_failure_feedback'), hasLength(1));
  });

  testWidgets('tapping outside the dialog counts as skipped', (tester) async {
    final ctx = await pumpHost(tester);

    final result = showFirstFailureFeedback(ctx, tracker: tracker);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(await result, 'skipped');
  });

  testWidgets('every reason button fits a narrow phone in a long-text language', (tester) async {
    final ctx = await pumpHost(tester, locale: const Locale('de'), size: const Size(320, 568));

    final result = showFirstFailureFeedback(ctx, tracker: tracker);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(OutlinedButton), findsNWidgets(3));

    // The dialog scrolls on a small screen: bring the last reason into view
    // first, as a user would, so the tap lands on it and not on the actions.
    await tester.ensureVisible(find.byType(OutlinedButton).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton).last);
    await tester.pumpAndSettle();
    expect(await result, 'slow');
  });
}
