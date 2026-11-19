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

/// Purchase-flow cases from the PR #36 review: a cancel the Billing plugin
/// reports without a product id, a subscription that expires while the app
/// stays open, and when the paywall counts as shown.
void main() {
  const yearly = ProEntitlement.yearlyId;
  const monthly = ProEntitlement.monthlyId;
  const lifetime = ProEntitlement.productId;

  late SharedPreferences prefs;
  late FakeStore store;
  late List<MapEntry<String, Map<String, Object>>> events;
  late DateTime now;
  late List<String> offered;
  late List<String> revoked;

  ProEntitlement makeEntitlement() => ProEntitlement(prefs,
      store: store,
      ownedPurchases: store,
      offeredIds: () => offered,
      onRevoked: revoked.add,
      now: () => now);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = FakeStore()
      ..products = [
        proProduct(),
        planProduct(monthly, r'$1.99'),
        planProduct(yearly, r'$9.99'),
      ];
    events = [];
    now = DateTime(2026, 11, 18, 12);
    offered = [yearly, monthly, lifetime];
    revoked = [];
  });

  group('cancel or error without a product id', () {
    test('cancel with an empty productID ends the pending purchase', () async {
      final e = makeEntitlement();
      await e.init();
      await e.buy(yearly);
      expect(e.purchasePending, isTrue);
      await e.handlePurchases([purchase(PurchaseStatus.canceled, productId: '')]);
      expect(e.purchasePending, isFalse);
      expect(e.isPro, isFalse);
    });

    test('error with an empty productID ends it and keeps the message', () async {
      final e = makeEntitlement();
      await e.init();
      await e.buy(monthly);
      await e.handlePurchases([purchase(PurchaseStatus.error, productId: '')]);
      expect(e.purchasePending, isFalse);
      expect(e.lastError, 'card declined');
      expect(e.isPro, isFalse);
    });

    test('a purchased event for another product still never grants', () async {
      final e = makeEntitlement();
      await e.init();
      await e.handlePurchases([purchase(PurchaseStatus.purchased, productId: 'other')]);
      expect(e.isPro, isFalse);
    });
  });

  group('re-check on resume', () {
    setUp(() async => prefs.setBool(ProEntitlement.prefsKey, true));

    test('an expired subscription is revoked without a cold start', () async {
      store.owned = [purchase(PurchaseStatus.purchased, productId: yearly)];
      final e = makeEntitlement();
      await e.init(); // launch: Play still has the subscription
      expect(e.isPro, isTrue);

      store.owned = []; // it expires while the app stays open
      now = now.add(ProEntitlement.resyncInterval);
      expect(await e.syncIfStale(), ProSyncOutcome.kept); // first empty answer
      expect(e.isPro, isTrue);
      now = now.add(ProEntitlement.resyncInterval);
      expect(await e.syncIfStale(), ProSyncOutcome.revoked);
      expect(e.isPro, isFalse);
    });

    test('throttled: resumes inside the interval do not query Play', () async {
      final e = makeEntitlement();
      store.owned = [purchase(PurchaseStatus.purchased)];
      await e.init();
      final queries = store.ownedQueries;
      now = now.add(const Duration(minutes: 5));
      expect(await e.syncIfStale(), isNull);
      expect(store.ownedQueries, queries);
      now = now.add(ProEntitlement.resyncInterval);
      await e.syncIfStale();
      expect(store.ownedQueries, queries + 1);
    });

    test('a failed query on resume does not count toward the revoke', () async {
      final e = makeEntitlement();
      store.owned = [purchase(PurchaseStatus.purchased)];
      await e.init();
      store.ownedThrows = Exception('offline');
      for (var i = 0; i < 3; i++) {
        now = now.add(ProEntitlement.resyncInterval);
        expect(await e.syncIfStale(), ProSyncOutcome.kept);
      }
      expect(e.isPro, isTrue);
    });

    test('a purchase arriving during the revoke never ends up revoked', () async {
      // The second empty answer revokes; a restored subscription landing on
      // the purchase stream at any point while that revoke writes its
      // preferences must win. Try every interleaving up to 40 microtasks.
      var finishedFirst = 0;
      for (var delay = 0; delay < 40; delay++) {
        SharedPreferences.setMockInitialValues(
            {ProEntitlement.prefsKey: true, ProEntitlement.emptyQueriesKey: 1});
        prefs = await SharedPreferences.getInstance();
        store.owned = [purchase(PurchaseStatus.purchased, productId: yearly)];
        final e = makeEntitlement();
        await e.init(); // resets the empty count: Play has it
        await prefs.setInt(ProEntitlement.emptyQueriesKey, 1);
        store.owned = [];
        now = now.add(ProEntitlement.resyncInterval);

        final sync = e.syncIfStale();
        for (var i = 0; i < delay; i++) {
          await Future<void>.microtask(() {});
        }
        // Revoke already finished and reported before the purchase came:
        // a real revoke followed by a restore, not this race.
        final revokedBefore = revoked.isNotEmpty;
        await e.handlePurchases(
            [purchase(PurchaseStatus.restored, productId: yearly)]);
        await sync;
        expect(e.isPro, isTrue, reason: 'in memory, delay $delay');
        expect(prefs.getBool(ProEntitlement.prefsKey), isTrue,
            reason: 'persisted, delay $delay');
        if (!revokedBefore) {
          expect(revoked, isEmpty, reason: 'no pro_revoked, delay $delay');
        } else {
          finishedFirst++;
        }
        revoked.clear();
      }
      // The sweep reached past the revoke's end, so the race window above
      // was covered in full.
      expect(finishedFirst, greaterThan(0));
    });

    test('nothing to do before init', () async {
      final e = makeEntitlement();
      expect(await e.syncIfStale(), isNull);
      expect(store.ownedQueries, 0);
    });

    test('Play unavailable at launch: a later check still reaches it', () async {
      store.available = false;
      final e = makeEntitlement();
      await e.init();
      expect(store.ownedQueries, 0);
      expect(e.offers, isEmpty);

      store.available = true; // Billing back; the subscription has lapsed
      store.owned = [];
      now = now.add(ProEntitlement.resyncInterval);
      expect(await e.syncIfStale(), ProSyncOutcome.kept);
      expect(e.storeAvailable, isTrue);
      expect(e.offers, isNotEmpty, reason: 'plans loaded once Play is back');
      now = now.add(ProEntitlement.resyncInterval);
      expect(await e.syncIfStale(), ProSyncOutcome.revoked);
      expect(e.isPro, isFalse);
    });

    test('still unavailable: Pro is kept and the check stays throttled', () async {
      store.available = false;
      final e = makeEntitlement();
      await e.init();
      for (var i = 0; i < 3; i++) {
        now = now.add(ProEntitlement.resyncInterval);
        await e.syncIfStale();
      }
      expect(e.isPro, isTrue);
      expect(await e.syncIfStale(), isNull, reason: 'inside the interval');
    });
  });

  group('re-check while translating', () {
    test('a new translation by a Pro user re-checks Play, throttled', () async {
      await prefs.setBool(ProEntitlement.prefsKey, true);
      store.owned = [purchase(PurchaseStatus.purchased, productId: yearly)];
      final gate = LiteGate(
        enabled: true,
        quota: DailyTranslationQuota(prefs),
        entitlement: makeEntitlement(),
        logEvent: (name, params) async {},
      );
      await gate.entitlement.init();
      final queries = store.ownedQueries;
      expect(gate.mayStartTranslation(kind: 'live'), isTrue);
      await pumpEventQueue();
      expect(store.ownedQueries, queries, reason: 'inside the interval');
      now = now.add(ProEntitlement.resyncInterval);
      expect(gate.mayStartTranslation(kind: 'live'), isTrue);
      await pumpEventQueue();
      expect(store.ownedQueries, queries + 1);
    });
  });

  group('counting an attempt let in as Pro', () {
    late DailyTranslationQuota quota;
    late LiteGate gate;

    // Pro cached, one free translation left today, and Play has already
    // answered "nothing owned" once, so the next check revokes.
    Future<void> setUpRevokingGate() async {
      await prefs.setBool(ProEntitlement.prefsKey, true);
      quota = DailyTranslationQuota(prefs);
      for (var i = 1; i < quota.dailyLimit; i++) {
        await quota.recordSuccess(isPro: false);
      }
      store.owned = [];
      gate = LiteGate(
        enabled: true,
        quota: quota,
        entitlement: makeEntitlement(),
        logEvent: (name, params) async => events.add(MapEntry(name, params)),
      );
      await gate.entitlement.init(); // first empty answer: kept
      expect(gate.isPro, isTrue);
      expect(quota.remaining, 1);
      now = now.add(ProEntitlement.resyncInterval);
    }

    test('a revoke during the attempt does not spend free translations', () async {
      await setUpRevokingGate();
      final a = gate.admitTranslation(kind: LiteGate.kindImage)!; // let in as Pro
      expect(a.asPro, isTrue);
      await pumpEventQueue(); // the check it started revokes meanwhile
      expect(gate.isPro, isFalse);

      await gate.recordTranslationSuccess(kind: LiteGate.kindImage, admission: a);
      expect(quota.remaining, 1, reason: 'counted as the Pro attempt it was');
      expect(gate.paywallPending, isFalse);
      expect(events.last.value['is_pro'], 1);

      // The next attempt is a free one and is counted as such.
      final b = gate.admitTranslation(kind: LiteGate.kindImage)!;
      expect(b.asPro, isFalse);
      await gate.recordTranslationSuccess(kind: LiteGate.kindImage, admission: b);
      expect(quota.remaining, 0);
      expect(gate.paywallPending, isTrue);
    });

    for (final firstDoneFirst in [true, false]) {
      test(
          'two images in flight keep their own admission '
          '(${firstDoneFirst ? 'first' : 'second'} finishes first)', () async {
        await setUpRevokingGate();
        final pro = gate.admitTranslation(kind: LiteGate.kindImage)!;
        await pumpEventQueue(); // revoked while the first image is processed
        final free = gate.admitTranslation(kind: LiteGate.kindImage)!; // shared next
        expect([pro.asPro, free.asPro], [true, false]);

        final order = firstDoneFirst ? [pro, free] : [free, pro];
        for (final a in order) {
          await gate.recordTranslationSuccess(kind: LiteGate.kindImage, admission: a);
        }
        expect(quota.remaining, 0, reason: 'only the free image spent one');
        expect(gate.paywallPending, isTrue);
        final counted = [
          for (final e in events)
            if (e.key == LiteGate.evTranslationSuccess) e.value['is_pro']
        ];
        expect(counted, firstDoneFirst ? [1, 0] : [0, 1]);
      });
    }

    test('two free images finishing together spend two', () async {
      final quota = DailyTranslationQuota(prefs);
      final gate = LiteGate(
        enabled: true,
        quota: quota,
        entitlement: makeEntitlement(),
        logEvent: (name, params) async {},
      );
      await gate.entitlement.init();
      final a = gate.admitTranslation(kind: LiteGate.kindImage)!;
      final b = gate.admitTranslation(kind: LiteGate.kindImage)!;
      await Future.wait([
        gate.recordTranslationSuccess(kind: LiteGate.kindImage, admission: a),
        gate.recordTranslationSuccess(kind: LiteGate.kindImage, admission: b),
      ]);
      expect(quota.usedToday, 2);
      expect(quota.remaining, quota.dailyLimit - 2);
    });

    test('a live session is counted with its own admission', () async {
      await setUpRevokingGate();
      final live = gate.admitTranslation(kind: LiteGate.kindLive)!;
      await pumpEventQueue();
      expect(gate.isPro, isFalse);
      // A second Start, let in as free, must not change how the first counts
      // (TranslationProvider only binds an admission when it accepts Start).
      expect(gate.admitTranslation(kind: LiteGate.kindLive)!.asPro, isFalse);
      await gate.recordTranslationSuccess(kind: LiteGate.kindLive, admission: live);
      expect(quota.remaining, 1);
    });
  });

  group('paywall_shown', () {
    late LiteGate gate;

    Future<void> open(WidgetTester tester) async {
      gate = LiteGate(
        enabled: true,
        quota: DailyTranslationQuota(prefs),
        entitlement: makeEntitlement(),
        logEvent: (name, params) async => events.add(MapEntry(name, params)),
      );
      await gate.entitlement.init();
      await tester.pumpWidget(MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => PaywallScreen.show(context, gate, trigger: 'limit_hit'),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    List<Map<String, Object>> shown() =>
        [for (final e in events) if (e.key == LiteGate.evPaywallShown) e.value];

    Future<void> close(WidgetTester tester) async {
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
    }

    testWidgets('plans already loaded: logged once, with them', (tester) async {
      await open(tester);
      expect(shown(), hasLength(1));
      expect(shown().single['offers'], 'pro_yearly,pro_monthly,pro_unlock');
      expect(shown().single['trigger'], 'limit_hit');
      await close(tester);
      expect(shown(), hasLength(1));
    });

    testWidgets('plans arriving after the paywall opened are what gets logged', (tester) async {
      final loaded = store.products;
      store.products = []; // cold start: Play hasn't answered yet
      await open(tester);
      expect(shown(), isEmpty);

      store.products = loaded;
      await gate.entitlement.loadProduct();
      await tester.pumpAndSettle();
      expect(shown(), hasLength(1));
      expect(shown().single['offers'], 'pro_yearly,pro_monthly,pro_unlock');
    });

    testWidgets('plans changing after the exposure are logged as an update', (tester) async {
      offered = [lifetime]; // Remote Config default on a cold start
      await open(tester);
      expect(shown().single['offers'], 'pro_unlock');

      offered = [yearly, monthly, lifetime]; // Remote Config activates
      await gate.entitlement.loadProduct();
      await tester.pumpAndSettle();
      expect(shown(), hasLength(2));
      expect(shown().last['offers'], 'pro_yearly,pro_monthly,pro_unlock');
      expect(shown().last['offers_changed'], 1);
      expect(shown().first.containsKey('offers_changed'), isFalse);

      await gate.entitlement.loadProduct(); // same plans again: nothing new
      await tester.pumpAndSettle();
      expect(shown(), hasLength(2));
    });

    testWidgets('a Remote Config switch seen only on a rebuild is logged too', (tester) async {
      offered = [lifetime];
      await open(tester);
      expect(shown().single['offers'], 'pro_unlock');

      // Remote Config activates the subscriptions: no Billing or entitlement
      // notification. Then the page rebuilds (a rotation, say).
      offered = [yearly, monthly, lifetime];
      tester.element(find.byType(PaywallScreen)).markNeedsBuild();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('paywall_plan_pro_yearly')), findsOneWidget);
      expect(shown(), hasLength(2));
      expect(shown().last['offers'], 'pro_yearly,pro_monthly,pro_unlock');
      expect(shown().last['offers_changed'], 1);
    });

    testWidgets('Pro arriving with a page over the paywall closes only the paywall',
        (tester) async {
      await open(tester);
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.push(MaterialPageRoute(
          builder: (_) => const Scaffold(body: Text('shared image'))));
      await tester.pumpAndSettle();

      // A background re-sync (or restore) grants Pro.
      await gate.entitlement.handlePurchases(
          [purchase(PurchaseStatus.restored, productId: yearly)]);
      await tester.pumpAndSettle();
      expect(find.text('shared image'), findsOneWidget);
      expect(find.byType(PaywallScreen), findsNothing);

      nav.pop(); // back from the image goes home, not to a stale paywall
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      expect(find.byType(PaywallScreen), findsNothing);
    });

    testWidgets('closed before any plan loaded: logged once, with empty offers', (tester) async {
      store.products = [];
      await open(tester);
      await close(tester);
      expect(shown(), hasLength(1));
      expect(shown().single['offers'], '');
    });
  });
}
