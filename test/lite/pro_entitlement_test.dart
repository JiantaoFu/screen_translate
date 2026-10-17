import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:screen_translate/lite/pro_entitlement.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_store.dart';

void main() {
  late SharedPreferences prefs;
  late FakeStore store;
  late List<PurchaseDetails> purchasedCallbacks;
  late int revokedCallbacks;

  ProEntitlement make() => ProEntitlement(prefs,
      store: store,
      ownedPurchases: store,
      onPurchased: purchasedCallbacks.add,
      onRevoked: () => revokedCallbacks++);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = FakeStore();
    purchasedCallbacks = [];
    revokedCallbacks = 0;
  });

  test('starts free; init loads Play price and restores purchases', () async {
    final e = make();
    expect(e.isPro, isFalse);
    await e.init();
    expect(e.storeAvailable, isTrue);
    expect(e.price, r'$2.99');
    expect(store.restores, 1);
    expect(e.isPro, isFalse);
  });

  test('price is whatever Play returns (never hard-coded)', () async {
    store.products = [proProduct(price: '¥22.00')];
    final e = make();
    await e.init();
    expect(e.price, '¥22.00');
  });

  test('restore on reinstall grants pro, acknowledges, and is not a new purchase', () async {
    store.owned = [purchase(PurchaseStatus.restored)];
    final e = make();
    await e.init();
    await pumpEventQueue();
    expect(e.isPro, isTrue);
    expect(prefs.getBool(ProEntitlement.prefsKey), isTrue);
    expect(store.completed, hasLength(1));
    expect(purchasedCallbacks, isEmpty);
  });

  test('purchase flow: pending, then purchased -> pro, acknowledged, callback once', () async {
    final e = make();
    await e.init();
    expect(await e.buy(), isTrue);
    expect(store.bought.single.id, ProEntitlement.productId);
    expect(e.purchasePending, isTrue);

    await e.handlePurchases([purchase(PurchaseStatus.pending, pendingComplete: false)]);
    expect(e.isPro, isFalse);
    expect(e.purchasePending, isTrue);

    await e.handlePurchases([purchase(PurchaseStatus.purchased)]);
    expect(e.isPro, isTrue);
    expect(e.purchasePending, isFalse);
    expect(store.completed, hasLength(1));
    expect(purchasedCallbacks, hasLength(1));

    // The same purchase redelivered (e.g. restore later) doesn't re-fire.
    await e.handlePurchases([purchase(PurchaseStatus.restored)]);
    expect(purchasedCallbacks, hasLength(1));
  });

  test('cancel and error clear pending and do not grant', () async {
    final e = make();
    await e.init();
    await e.buy();
    await e.handlePurchases([purchase(PurchaseStatus.canceled)]);
    expect(e.purchasePending, isFalse);
    expect(e.isPro, isFalse);
    await e.buy();
    await e.handlePurchases([purchase(PurchaseStatus.error)]);
    expect(e.purchasePending, isFalse);
    expect(e.isPro, isFalse);
    expect(e.lastError, 'card declined');
  });

  test('other product ids never grant pro but are still completed', () async {
    final e = make();
    await e.handlePurchases([purchase(PurchaseStatus.purchased, productId: 'something_else')]);
    expect(e.isPro, isFalse);
    expect(store.completed, hasLength(1));
  });

  test('pro is remembered across launches, even offline', () async {
    await prefs.setBool(ProEntitlement.prefsKey, true);
    store.available = false;
    final e = make();
    expect(e.isPro, isTrue);
    await e.init();
    expect(e.isPro, isTrue);
    expect(e.storeAvailable, isFalse);
  });

  test('store unavailable: no product, buy returns false', () async {
    store.available = false;
    final e = make();
    await e.init();
    expect(e.price, isNull);
    store.products = [];
    expect(await e.buy(), isFalse);
    expect(e.purchasePending, isFalse);
  });

  test('restore button triggers a Play restore', () async {
    final e = make();
    await e.init();
    store.owned = [purchase(PurchaseStatus.restored)];
    await e.restore();
    await pumpEventQueue();
    expect(store.restores, 2);
    expect(e.isPro, isTrue);
  });

  group('refund revocation (owned purchases query at app start)', () {
    setUp(() async => prefs.setBool(ProEntitlement.prefsKey, true));

    test('query ok and pro_unlock missing -> revoke, persist, callback', () async {
      store.ownedResult = const OwnedPurchasesResult.ok([]);
      final e = make();
      expect(e.isPro, isTrue);
      await e.init();
      expect(store.ownedQueries, 1);
      expect(e.isPro, isFalse);
      expect(prefs.getBool(ProEntitlement.prefsKey), isFalse);
      expect(revokedCallbacks, 1);
    });

    test('only other products / non-purchased pro_unlock -> revoke', () async {
      final e = make();
      store.ownedResult = OwnedPurchasesResult.ok([
        purchase(PurchaseStatus.purchased, productId: 'something_else'),
        purchase(PurchaseStatus.pending, pendingComplete: false),
      ]);
      expect(await e.syncWithStore(), ProSyncOutcome.revoked);
      expect(e.isPro, isFalse);
    });

    test('query ok and pro_unlock present -> keep', () async {
      store.ownedResult =
          OwnedPurchasesResult.ok([purchase(PurchaseStatus.purchased, pendingComplete: false)]);
      final e = make();
      expect(await e.syncWithStore(), ProSyncOutcome.unchanged);
      expect(e.isPro, isTrue);
      expect(revokedCallbacks, 0);
    });

    test('query ok and pro_unlock present but local free -> grant and acknowledge', () async {
      await prefs.setBool(ProEntitlement.prefsKey, false);
      final owned = purchase(PurchaseStatus.purchased);
      store.ownedResult = OwnedPurchasesResult.ok([owned]);
      final e = make();
      expect(e.isPro, isFalse);
      expect(await e.syncWithStore(), ProSyncOutcome.granted);
      expect(e.isPro, isTrue);
      expect(prefs.getBool(ProEntitlement.prefsKey), isTrue);
      expect(store.completed, [owned]);
      expect(purchasedCallbacks, isEmpty); // not a new purchase
    });

    test('query error (e.g. offline) -> keep pro', () async {
      store.ownedResult = const OwnedPurchasesResult.error();
      final e = make();
      await e.init();
      expect(e.isPro, isTrue);
      expect(await e.syncWithStore(), ProSyncOutcome.kept);
      expect(prefs.getBool(ProEntitlement.prefsKey), isTrue);
      expect(revokedCallbacks, 0);
    });

    test('billing unavailable from the query -> keep pro', () async {
      store.ownedResult = const OwnedPurchasesResult.unavailable();
      final e = make();
      await e.init();
      expect(e.isPro, isTrue);
      expect(await e.syncWithStore(), ProSyncOutcome.kept);
      expect(revokedCallbacks, 0);
    });

    test('store unavailable at launch -> no query, keep pro', () async {
      store.available = false;
      store.ownedResult = const OwnedPurchasesResult.ok([]);
      final e = make();
      await e.init();
      expect(store.ownedQueries, 0);
      expect(e.isPro, isTrue);
    });

    test('query throws -> keep pro', () async {
      store.ownedThrows = Exception('boom');
      final e = make();
      await e.init();
      expect(e.isPro, isTrue);
      expect(await e.syncWithStore(), ProSyncOutcome.kept);
      expect(revokedCallbacks, 0);
    });

    test('free user with nothing owned stays free, no revoke event', () async {
      await prefs.setBool(ProEntitlement.prefsKey, false);
      store.ownedResult = const OwnedPurchasesResult.ok([]);
      final e = make();
      await e.init();
      expect(e.isPro, isFalse);
      expect(revokedCallbacks, 0);
    });
  });
}
