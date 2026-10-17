import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:screen_translate/lite/daily_translation_quota.dart';
import 'package:screen_translate/lite/lite_gate.dart';
import 'package:screen_translate/lite/pro_entitlement.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_store.dart';

void main() {
  late SharedPreferences prefs;
  late FakeStore store;
  late List<MapEntry<String, Map<String, Object>>> events;
  late DateTime now;
  late LiteGate gate;

  LiteGate make({bool enabled = true, int limit = 5}) {
    late LiteGate g;
    final entitlement = ProEntitlement(prefs, store: store, onPurchased: (_) => g.debugOnPurchased());
    g = LiteGate(
      enabled: enabled,
      quota: DailyTranslationQuota(prefs, now: () => now, limit: () => limit),
      entitlement: entitlement,
      logEvent: (name, params) async => events.add(MapEntry(name, params)),
    );
    return g;
  }

  List<String> names() => events.map((e) => e.key).toList();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = FakeStore();
    events = [];
    now = DateTime(2026, 10, 17, 10);
    gate = make();
  });

  test('never blocks before the limit: no paywall at launch', () {
    expect(gate.mayStartTranslation(kind: 'live'), isTrue);
    expect(gate.paywallPending, isFalse);
    expect(gate.takePendingPaywall(), isFalse);
    expect(events, isEmpty);
  });

  test('paywall is due right after the success that used the last free one', () async {
    for (var i = 0; i < 4; i++) {
      await gate.recordTranslationSuccess(kind: 'live');
      expect(gate.paywallPending, isFalse);
      expect(gate.mayStartTranslation(kind: 'live'), isTrue);
    }
    var notified = 0;
    gate.addListener(() => notified++);
    await gate.recordTranslationSuccess(kind: 'image');
    expect(gate.paywallPending, isTrue);
    expect(notified, greaterThan(0));
    expect(gate.takePendingPaywall(), isTrue);
    expect(gate.takePendingPaywall(), isFalse, reason: 'shown once');
  });

  test('the next attempt after the 5th success is blocked and logs free_limit_hit', () async {
    for (var i = 0; i < 5; i++) {
      await gate.recordTranslationSuccess(kind: 'live');
    }
    events.clear();
    expect(gate.mayStartTranslation(kind: 'live'), isFalse);
    expect(events.single.key, LiteGate.evFreeLimitHit);
    expect(events.single.value, {'remaining_free': 0, 'daily_limit': 5, 'kind': 'live'});
  });

  test('translation_success carries remaining_free and daily_limit', () async {
    await gate.recordTranslationSuccess(kind: 'live');
    expect(events.single.key, LiteGate.evTranslationSuccess);
    expect(events.single.value,
        {'remaining_free': 4, 'daily_limit': 5, 'is_pro': 0, 'kind': 'live'});
  });

  test('paywall_shown logs trigger and quota', () async {
    await gate.recordTranslationSuccess(kind: 'live');
    events.clear();
    gate.paywallShown('limit_reached');
    expect(events.single.key, LiteGate.evPaywallShown);
    expect(events.single.value, {'remaining_free': 4, 'daily_limit': 5, 'trigger': 'limit_reached'});
  });

  test('a new day unblocks', () async {
    for (var i = 0; i < 5; i++) {
      await gate.recordTranslationSuccess(kind: 'live');
    }
    expect(gate.mayStartTranslation(kind: 'live'), isFalse);
    now = DateTime(2026, 10, 18, 0, 1);
    expect(gate.mayStartTranslation(kind: 'live'), isTrue);
    expect(gate.remainingFree, 5);
  });

  test('remote limit is honoured', () async {
    gate = make(limit: 2);
    await gate.recordTranslationSuccess(kind: 'live');
    await gate.recordTranslationSuccess(kind: 'live');
    expect(gate.paywallPending, isTrue);
    expect(gate.mayStartTranslation(kind: 'live'), isFalse);
  });

  test('purchase: pro_purchased logged once, pro bypasses limit, no pending paywall', () async {
    await gate.entitlement.init();
    for (var i = 0; i < 5; i++) {
      await gate.recordTranslationSuccess(kind: 'live');
    }
    expect(gate.paywallPending, isTrue);
    events.clear();
    await gate.entitlement.handlePurchases([purchase(PurchaseStatus.purchased)]);
    expect(gate.isPro, isTrue);
    expect(names(), [LiteGate.evProPurchased]);
    expect(events.single.value['product_id'], 'pro_unlock');
    expect(events.single.value['price'], r'$2.99');
    expect(gate.paywallPending, isFalse);
    expect(gate.takePendingPaywall(), isFalse);
    expect(gate.mayStartTranslation(kind: 'live'), isTrue);

    events.clear();
    final use = await gate.recordTranslationSuccess(kind: 'live');
    expect(use!.justExhausted, isFalse);
    expect(events.single.value['is_pro'], 1);
  });

  test('restored purchase does not log pro_purchased', () async {
    store.owned = [purchase(PurchaseStatus.restored)];
    await gate.entitlement.init();
    await pumpEventQueue();
    expect(gate.isPro, isTrue);
    expect(names(), isNot(contains(LiteGate.evProPurchased)));
  });

  test('disabled gate (paid flavor) never blocks, counts or logs', () async {
    gate = make(enabled: false);
    for (var i = 0; i < 10; i++) {
      expect(await gate.recordTranslationSuccess(kind: 'live'), isNull);
    }
    expect(gate.mayStartTranslation(kind: 'live'), isTrue);
    expect(gate.paywallPending, isFalse);
    expect(events, isEmpty);
    expect(prefs.getInt(DailyTranslationQuota.countKey), isNull);
  });
}
