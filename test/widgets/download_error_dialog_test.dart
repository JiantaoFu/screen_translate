import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/widgets/download_error_dialog.dart';

void main() {
  Future<BuildContext> pumpHost(WidgetTester tester, {Size size = const Size(360, 640)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (c) {
        ctx = c;
        return const Scaffold();
      }),
    ));
    return ctx;
  }

  testWidgets('at most one dialog at a time: a second call returns dismiss', (tester) async {
    final ctx = await pumpHost(tester);
    final first = showDownloadFailedDialog(ctx, packLabel: 'Arabic');
    await tester.pumpAndSettle();
    final second = await showDownloadFailedDialog(ctx, packLabel: 'English');
    await tester.pumpAndSettle();

    expect(second, DownloadFailedAction.dismiss);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(isDownloadFailedDialogShowing, isTrue);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(await first, DownloadFailedAction.dismiss);
    expect(find.byType(AlertDialog), findsNothing);
    expect(isDownloadFailedDialogShowing, isFalse);
  });

  testWidgets('tapping outside dismisses it', (tester) async {
    final ctx = await pumpHost(tester);
    final result = showDownloadFailedDialog(ctx, packLabel: 'Arabic');
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(await result, DownloadFailedAction.dismiss);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Retry returns retry and frees the guard', (tester) async {
    final ctx = await pumpHost(tester);
    final result = showDownloadFailedDialog(ctx, packLabel: 'Arabic');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(await result, DownloadFailedAction.retry);
    expect(isDownloadFailedDialogShowing, isFalse);
  });

  for (final locale in const [Locale('en'), Locale('es'), Locale('pt'), Locale('id'), Locale('de')]) {
    testWidgets('four buttons fit on a small phone without overflow ($locale)', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
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
      showDownloadFailedDialog(ctx, packLabel: 'Chinese (Traditional)');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextButton), findsNWidgets(4));
      // Every button is fully inside the dialog.
      final dialogRect = tester.getRect(find.byType(AlertDialog));
      for (final e in find.byType(TextButton).evaluate()) {
        final r = tester.getRect(find.byWidget(e.widget));
        expect(dialogRect.contains(r.topLeft) && dialogRect.contains(r.bottomRight - const Offset(0.1, 0.1)), isTrue);
      }
      Navigator.of(ctx).pop();
      await tester.pumpAndSettle();
    });
  }
}
