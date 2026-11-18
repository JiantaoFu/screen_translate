import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:screen_translate/l10n/app_localizations.dart';
import 'package:screen_translate/lite/daily_translation_quota.dart';
import 'package:screen_translate/lite/lite_gate.dart';
import 'package:screen_translate/lite/lite_home_pro_row.dart';
import 'package:screen_translate/lite/paywall_screen.dart';
import 'package:screen_translate/lite/pro_entitlement.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_store.dart';

/// Subscription plans next to the one-time unlock: which plans the paywall
/// offers, what buying and losing one does, and what gets logged.
void main() {
  const yearly = ProEntitlement.yearlyId;
  const monthly = ProEntitlement.monthlyId;
  const lifetime = ProEntitlement.productId;

  late SharedPreferences prefs;
  late FakeStore store;
  late List<String> offered;
  late List<MapEntry<String, Map<String, Object>>> events;
  late List<String> revoked;

  ProEntitlement makeEntitlement() => ProEntitlement(prefs,
      store: store,
      ownedPurchases: store,
      offeredIds: () => offered,
      onRevoked: revoked.add);

  LiteGate makeGate(ProEntitlement e) => LiteGate(
        enabled: true,
        quota: DailyTranslationQuota(prefs),
        entitlement: e,
        logEvent: (name, params) async => events.add(MapEntry(name, params)),
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = FakeStore()
      ..products = [
        proProduct(price: r'$6.99'),
        planProduct(monthly, r'$1.99'),
        planProduct(yearly, r'$9.99'),
      ];
    offered = [yearly, monthly, lifetime];
    events = [];
    revoked = [];
  });

  group('parseOfferedIds', () {
    test('keeps order, trims, drops unknown ids and repeats', () {
      expect(ProEntitlement.parseOfferedIds(' pro_yearly, pro_unlock ,bogus,pro_yearly'),
          [yearly, lifetime]);
    });

    test('nothing usable falls back to the one-time unlock', () {
      expect(ProEntitlement.parseOfferedIds(''), [lifetime]);
      expect(ProEntitlement.parseOfferedIds('bogus,,'), [lifetime]);
    });
  });

  group('offers', () {
    test('default is the one-time unlock only, even if Play has subscriptions', () async {
      final e = ProEntitlement(prefs, store: store, ownedPurchases: store);
      await e.init();
      expect(e.offers.map((p) => p.id), [lifetime]);
      expect(e.price, r'$6.99');
    });

    test('configured plans appear in the configured order', () async {
      final e = makeEntitlement();
      await e.init();
      expect(e.offers.map((p) => p.id), [yearly, monthly, lifetime]);
      expect(e.productFor(yearly)!.price, r'$9.99');
    });

    test('a plan Play does not return is left out', () async {
      store.products = [proProduct(price: r'$6.99'), planProduct(yearly, r'$9.99')];
      final e = makeEntitlement();
      await e.init();
      expect(e.offers.map((p) => p.id), [yearly, lifetime]);
    });

    test('configured subscriptions missing from Play fall back to the one-time unlock', () async {
      store.products = [proProduct(price: r'$6.99')];
      offered = [yearly, monthly];
      final e = makeEntitlement();
      await e.init();
      expect(e.offers.map((p) => p.id), [lifetime]);
    });

    test('follows a config change without a restart', () async {
      final e = makeEntitlement();
      await e.init();
      offered = [monthly];
      expect(e.offers.map((p) => p.id), [monthly]);
    });
  });

  group('owning a subscription', () {
    test('buying one grants Pro, acknowledges it and remembers which plan', () async {
      final e = makeEntitlement();
      await e.init();
      expect(await e.buy(yearly), isTrue);
      expect(store.bought.single.id, yearly);

      final p = purchase(PurchaseStatus.purchased, productId: yearly);
      await e.handlePurchases([p]);
      expect(e.isPro, isTrue);
      expect(e.ownedProductId, yearly);
      expect(store.completed, [p]);
    });

    test('a restored subscription grants Pro on a new install', () async {
      store.owned = [purchase(PurchaseStatus.restored, productId: monthly)];
      final e = makeEntitlement();
      await e.init();
      await pumpEventQueue();
      expect(e.isPro, isTrue);
      expect(e.ownedProductId, monthly);
    });

    test('an active subscription keeps Pro when the plan is no longer offered', () async {
      store.owned = [purchase(PurchaseStatus.restored, productId: monthly)];
      offered = [lifetime];
      final e = makeEntitlement();
      await e.init();
      await pumpEventQueue();
      expect(e.isPro, isTrue);
      expect(await e.syncWithStore(), ProSyncOutcome.unchanged);
    });

    test('an ended subscription is revoked after two empty answers, naming the plan', () async {
      await prefs.setBool(ProEntitlement.prefsKey, true);
      await prefs.setString(ProEntitlement.ownedProductKey, yearly);
      store.ownedResult = const OwnedPurchasesResult.ok([]);
      final e = makeEntitlement();
      await e.init(); // first empty answer
      expect(e.isPro, isTrue);
      expect(await e.syncWithStore(), ProSyncOutcome.revoked);
      expect(e.isPro, isFalse);
      expect(revoked, [yearly]);
      expect(e.ownedProductId, isNull);
    });
  });

  group('analytics', () {
    test('paywall_shown lists the offers; purchase_started and pro_purchased name the plan',
        () async {
      late LiteGate gate;
      final e = ProEntitlement(prefs,
          store: store,
          ownedPurchases: store,
          offeredIds: () => offered,
          onPurchased: (p) => gate.debugOnPurchased(p.productID));
      gate = makeGate(e);
      await e.init();

      gate.paywallShown('limit_reached');
      expect(events.last.key, LiteGate.evPaywallShown);
      expect(events.last.value['offers'], 'pro_yearly,pro_monthly,pro_unlock');

      await gate.startPurchase(monthly);
      expect(events.last.key, LiteGate.evPurchaseStarted);
      expect(events.last.value['product_id'], monthly);
      expect(events.last.value['price'], r'$1.99');
      expect(store.bought.single.id, monthly);

      await e.handlePurchases([purchase(PurchaseStatus.purchased, productId: monthly)]);
      expect(events.last.key, LiteGate.evProPurchased);
      expect(events.last.value['product_id'], monthly);
      expect(events.last.value['price'], r'$1.99');
    });
  });

  group('paywall', () {
    late LiteGate gate;

    Future<void> open(WidgetTester tester) async {
      gate = makeGate(makeEntitlement());
      await gate.entitlement.init();
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(children: [
              TextButton(
                onPressed: () => PaywallScreen.show(context, gate, trigger: 'limit_reached'),
                child: const Text('open'),
              ),
              LiteHomeProRow(gate: gate, onOpenPaywall: (_, __) {}),
            ]),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('lists the plans, preselects the first and states renewal terms',
        (tester) async {
      await open(tester);
      // Home row: no single price to quote when there is a choice of plans.
      expect(find.text('Unlock Pro'), findsOneWidget);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(r'$9.99 / year'), findsOneWidget);
      expect(find.text(r'$1.99 / month'), findsOneWidget);
      expect(find.text(r'$6.99 once'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byKey(const Key('paywall_terms')), findsOneWidget);
      expect(find.text('Cancel anytime'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('paywall_unlock')));
      await tester.tap(find.byKey(const Key('paywall_unlock')));
      await tester.pump();
      expect(store.bought.single.id, yearly);
    });

    testWidgets('choosing the one-time unlock drops the renewal terms and buys it',
        (tester) async {
      await open(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('paywall_plan_pro_unlock')));
      await tester.tap(find.byKey(const Key('paywall_plan_pro_unlock')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('paywall_terms')), findsNothing);
      expect(find.text('One-time purchase, no subscription'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('paywall_unlock')));
      await tester.tap(find.byKey(const Key('paywall_unlock')));
      await tester.pump();
      expect(store.bought.single.id, lifetime);

      await gate.entitlement.handlePurchases([purchase(PurchaseStatus.purchased)]);
      await tester.pumpAndSettle();
      expect(find.byType(PaywallScreen), findsNothing);
    });

    testWidgets('a single subscription on offer still shows its price and terms',
        (tester) async {
      offered = [monthly];
      await open(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(r'$1.99 / month'), findsOneWidget);
      expect(find.byKey(const Key('paywall_terms')), findsOneWidget);
      expect(find.byKey(const Key('paywall_plan_pro_unlock')), findsNothing);
    });
  });
}
