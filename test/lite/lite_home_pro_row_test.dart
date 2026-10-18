import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/lite/daily_translation_quota.dart';
import 'package:screen_translate/lite/lite_gate.dart';
import 'package:screen_translate/lite/lite_home_pro_row.dart';
import 'package:screen_translate/lite/pro_entitlement.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_store.dart';

void main() {
  late FakeStore store;
  late LiteGate gate;
  late List<String> opened;

  Future<void> makeGate({List<String> prices = const [r'$2.99'], bool available = true}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = FakeStore()
      ..available = available
      ..products = [for (final p in prices) proProduct(price: p)];
    gate = LiteGate(
      enabled: true,
      quota: DailyTranslationQuota(prefs),
      entitlement: ProEntitlement(prefs, store: store, ownedPurchases: store),
      logEvent: (name, params) async {},
    );
    await gate.entitlement.init();
  }

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('en'), LiteGate? g}) async {
    opened = [];
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ListenableBuilder(
          listenable: gate,
          builder: (context, _) => LiteHomeProRow(
            gate: g ?? gate,
            onOpenPaywall: (gate, trigger) => opened.add(trigger),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('shows the quota and Unlock Pro with Play\'s localized price', (tester) async {
    await makeGate(prices: ['€3,49']);
    await pump(tester);
    expect(find.text('Free translations left today: 5'), findsOneWidget);
    expect(find.text('Unlock Pro · €3,49'), findsOneWidget);
    expect(find.textContaining(r'$2.99'), findsNothing);

    await tester.tap(find.byKey(const Key('lite_home_unlock')));
    await tester.tap(find.byKey(const Key('lite_remaining')));
    expect(opened, ['home_unlock', 'home']);
  });

  testWidgets('falls back to "Unlock Pro" without a price when Play has no details', (tester) async {
    await makeGate(prices: []);
    await pump(tester);
    expect(find.text('Unlock Pro'), findsOneWidget);
    await tester.tap(find.byKey(const Key('lite_home_unlock')));
    expect(opened, ['home_unlock']);
  });

  testWidgets('falls back to "Unlock Pro" when the store is unavailable', (tester) async {
    await makeGate(available: false);
    await pump(tester);
    expect(find.text('Unlock Pro'), findsOneWidget);
  });

  testWidgets('is hidden once Pro is owned', (tester) async {
    await makeGate();
    await pump(tester);
    expect(find.byKey(const Key('lite_home_unlock')), findsOneWidget);

    await gate.entitlement.handlePurchases([purchase(PurchaseStatus.purchased)]);
    await tester.pump();
    expect(find.byKey(const Key('lite_home_unlock')), findsNothing);
    expect(find.byKey(const Key('lite_remaining')), findsNothing);
  });

  testWidgets('nothing in the paid app (no gate)', (tester) async {
    await makeGate();
    opened = [];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: LiteHomeProRow(gate: null, onOpenPaywall: (g, t) => opened.add(t))),
    ));
    expect(find.byKey(const Key('lite_home_unlock')), findsNothing);
  });

  testWidgets('translated (zh)', (tester) async {
    await makeGate(prices: ['¥22.00']);
    await pump(tester, locale: const Locale('zh'));
    expect(find.text('解锁 Pro · ¥22.00'), findsOneWidget);
  });

  test('every locale has a Lite title that keeps the app name', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l = await AppLocalizations.delegate.load(locale);
      expect(l.app_title_lite, '${l.app_title} Lite', reason: locale.toString());
    }
  });
}
