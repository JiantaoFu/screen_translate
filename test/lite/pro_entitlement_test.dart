import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:screen_translate/lite/pro_entitlement.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_store.dart';

void main() {
  late SharedPreferences prefs;
  late FakeStore store;
  late List<PurchaseDetails> purchasedCallbacks;

  ProEntitlement make() =>
      ProEntitlement(prefs, store: store, onPurchased: purchasedCallbacks.add);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = FakeStore();
    purchasedCallbacks = [];
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
}
