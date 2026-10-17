import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/lite/daily_translation_quota.dart';
import 'package:screen_translate/lite/lite_gate.dart';
import 'package:screen_translate/lite/paywall_screen.dart';
import 'package:screen_translate/lite/pro_entitlement.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_store.dart';

void main() {
  late FakeStore store;
  late LiteGate gate;
  late List<String> events;

  Future<void> pumpHost(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => PaywallScreen.show(context, gate, trigger: 'limit_reached'),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = FakeStore()..products = [proProduct(price: r'$2.99')];
    events = [];
    gate = LiteGate(
      enabled: true,
      quota: DailyTranslationQuota(prefs),
      entitlement: ProEntitlement(prefs, store: store),
      logEvent: (name, params) async => events.add(name),
    );
    await gate.entitlement.init();
  });

  testWidgets('shows Play price, buys, restores and closes once Pro', (tester) async {
    await pumpHost(tester);
    expect(events, [LiteGate.evPaywallShown]);
    expect(find.text(r'Unlock Pro · $2.99'), findsOneWidget);
    expect(find.textContaining('5 free translations a day'), findsOneWidget);

    await tester.tap(find.byKey(const Key('paywall_restore')));
    await tester.pump();
    expect(store.restores, 2);

    await tester.tap(find.byKey(const Key('paywall_unlock')));
    await tester.pump();
    expect(store.bought, hasLength(1));

    await gate.entitlement.handlePurchases([purchase(PurchaseStatus.purchased)]);
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsNothing);
    expect(find.text('Pro unlocked: unlimited translations!'), findsOneWidget);
  });

  testWidgets('translated (zh) and closable with Not now', (tester) async {
    await pumpHost(tester, locale: const Locale('zh'));
    expect(find.text('今天的免费翻译次数已用完'), findsOneWidget);
    await tester.tap(find.text('以后再说'));
    await tester.pumpAndSettle();
    expect(find.byType(PaywallScreen), findsNothing);
  });
}
