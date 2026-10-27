import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The parts of [InAppPurchase] the lite flavor uses; a fake in tests.
abstract class StoreGateway {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids);
  Future<bool> buyNonConsumable(ProductDetails product);
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);
}

class InAppPurchaseGateway implements StoreGateway {
  InAppPurchase get _iap => InAppPurchase.instance;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;
  @override
  Future<bool> isAvailable() => _iap.isAvailable();
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) => _iap.queryProductDetails(ids);
  @override
  Future<bool> buyNonConsumable(ProductDetails product) =>
      _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
  @override
  Future<void> restorePurchases() => _iap.restorePurchases();
  @override
  Future<void> completePurchase(PurchaseDetails purchase) => _iap.completePurchase(purchase);
}

/// Outcome of asking the store which products the user owns right now.
enum OwnedQueryStatus {
  /// The query ran and [OwnedPurchasesResult.purchases] is authoritative.
  ok,

  /// Billing isn't usable here (no Play, not Android, not connected).
  unavailable,

  /// Play answered with an error (offline, service timeout, ...).
  error,
}

class OwnedPurchasesResult {
  final OwnedQueryStatus status;
  final List<PurchaseDetails> purchases;

  const OwnedPurchasesResult.ok(this.purchases) : status = OwnedQueryStatus.ok;
  const OwnedPurchasesResult.unavailable()
      : status = OwnedQueryStatus.unavailable,
        purchases = const [];
  const OwnedPurchasesResult.error()
      : status = OwnedQueryStatus.error,
        purchases = const [];
}

/// Asks the store for the purchases the user currently owns; a fake in tests.
abstract class OwnedPurchasesSource {
  Future<OwnedPurchasesResult> queryOwned();
}

/// Google Play's owned purchases (BillingClient.queryPurchasesAsync, via
/// [InAppPurchaseAndroidPlatformAddition.queryPastPurchases]). A refunded and
/// revoked purchase is no longer returned. Never throws.
class PlayOwnedPurchasesSource implements OwnedPurchasesSource {
  @override
  Future<OwnedPurchasesResult> queryOwned() async {
    try {
      if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
        return const OwnedPurchasesResult.unavailable();
      }
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) return const OwnedPurchasesResult.unavailable();
      final res = await iap
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
          .queryPastPurchases();
      if (res.error != null) return const OwnedPurchasesResult.error();
      return OwnedPurchasesResult.ok(res.pastPurchases);
    } catch (_) {
      return const OwnedPurchasesResult.error();
    }
  }
}

/// What [ProEntitlement.syncWithStore] did to the local Pro flag.
enum ProSyncOutcome {
  /// Query failed or billing unavailable: local state left as it was.
  kept,

  /// Play agrees with the local state.
  unchanged,

  /// Play has `pro_unlock` but local didn't: granted (and acknowledged).
  granted,

  /// Play answered and has no purchased `pro_unlock` (refund/revoke): revoked.
  revoked,
}

/// Whether the lite user owns the one-time `pro_unlock` product.
///
/// - Purchased/restored `pro_unlock` grants Pro and is remembered locally,
///   so Pro works offline and right at launch.
/// - Every purchase update that needs it is completed, which acknowledges it
///   on Google Play (unacknowledged purchases are refunded after 3 days).
/// - [init] restores purchases, so a reinstall or a new phone gets Pro back
///   without a tap; the paywall also has a Restore button.
/// - [init] also asks Play which purchases are owned ([syncWithStore]) and
///   revokes local Pro once Play has answered successfully without
///   `pro_unlock` [emptyQueriesBeforeRevoke] times in a row (refunded +
///   revoked in Play Console). Offline, billing unavailable, any error, or a
///   single empty answer keeps the local state, so a paying user is never
///   locked out by a flaky connection or a signed-out Play Store.
/// - The price shown is Play's localized [ProductDetails.price], never a
///   hard-coded string.
class ProEntitlement extends ChangeNotifier {
  static const productId = 'pro_unlock';
  static const prefsKey = 'lite_pro_unlocked';
  static const emptyQueriesKey = 'lite_pro_empty_queries';

  /// Successful owned-purchase queries in a row that must come back without
  /// `pro_unlock` before local Pro is revoked.
  ///
  /// One is not enough. queryPurchasesAsync answers OK with an empty list
  /// while the user is signed out of the Play Store, after Play's data has
  /// been cleared, and before it has re-synced on a fresh install — states
  /// where isAvailable() still returns true. Revoking on the first such
  /// answer takes Pro away from someone who paid, and restorePurchases()
  /// won't bring it back until Play is itself healthy again. A real refund
  /// keeps answering empty, so it still lands on the next launch.
  static const emptyQueriesBeforeRevoke = 2;

  final SharedPreferences _prefs;
  final StoreGateway _store;
  final OwnedPurchasesSource _owned;

  /// Called once for a new purchase (not for restores): analytics.
  final void Function(PurchaseDetails purchase)? onPurchased;

  /// Called when Play no longer reports `pro_unlock` and Pro is revoked.
  final void Function()? onRevoked;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _isPro;
  bool _storeAvailable = false;
  bool _purchasePending = false;
  bool _initialized = false;
  int _grants = 0;
  ProductDetails? _product;
  String? _lastError;

  ProEntitlement(
    this._prefs, {
    StoreGateway? store,
    OwnedPurchasesSource? ownedPurchases,
    this.onPurchased,
    this.onRevoked,
  })  : _store = store ?? InAppPurchaseGateway(),
        _owned = ownedPurchases ?? PlayOwnedPurchasesSource(),
        _isPro = _prefs.getBool(prefsKey) ?? false;

  bool get isPro => _isPro;
  bool get storeAvailable => _storeAvailable;
  bool get purchasePending => _purchasePending;
  bool get initialized => _initialized;
  ProductDetails? get product => _product;

  /// Play's localized price, e.g. "$2.99" or "¥22.00"; null until loaded.
  String? get price => _product?.price;
  String? get lastError => _lastError;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _sub = _store.purchaseStream.listen(
      handlePurchases,
      onError: (Object e) {
        _lastError = e.toString();
        _purchasePending = false;
        notifyListeners();
      },
    );
    try {
      _storeAvailable = await _store.isAvailable();
      if (_storeAvailable) {
        await loadProduct();
        await _store.restorePurchases();
      }
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
    if (_storeAvailable) await syncWithStore();
  }

  /// Reconciles local Pro with what Play says is owned (run at app start).
  ///
  /// Grants (and acknowledges) when Play has `pro_unlock` but local doesn't.
  /// Revokes only after [emptyQueriesBeforeRevoke] successful queries in a
  /// row came back without it; otherwise keeps the current state.
  Future<ProSyncOutcome> syncWithStore() async {
    final grantsBefore = _grants;
    OwnedPurchasesResult res;
    try {
      res = await _owned.queryOwned();
    } catch (_) {
      return ProSyncOutcome.kept;
    }
    if (res.status != OwnedQueryStatus.ok) return ProSyncOutcome.kept;

    final owned = res.purchases.where((p) =>
        p.productID == productId &&
        (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored));
    if (owned.isNotEmpty) {
      if (_isPro) {
        if ((_prefs.getInt(emptyQueriesKey) ?? 0) != 0) {
          await _prefs.setInt(emptyQueriesKey, 0);
        }
        return ProSyncOutcome.unchanged;
      }
      await _grant();
      for (final p in owned) {
        if (p.pendingCompletePurchase) await _complete(p); // acknowledge
      }
      notifyListeners();
      return ProSyncOutcome.granted;
    }
    // A purchase that landed on the stream while we were querying wins.
    if (!_isPro || _grants != grantsBefore) return ProSyncOutcome.unchanged;
    final empties = (_prefs.getInt(emptyQueriesKey) ?? 0) + 1;
    await _prefs.setInt(emptyQueriesKey, empties);
    if (empties < emptyQueriesBeforeRevoke) return ProSyncOutcome.kept;
    _isPro = false;
    await _prefs.setBool(prefsKey, false);
    await _prefs.setInt(emptyQueriesKey, 0);
    notifyListeners();
    onRevoked?.call();
    return ProSyncOutcome.revoked;
  }

  Future<void> loadProduct() async {
    try {
      final res = await _store.queryProductDetails({productId});
      final match = res.productDetails.where((p) => p.id == productId);
      _product = match.isEmpty ? null : match.first;
      if (res.error != null) _lastError = res.error!.message;
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
  }

  /// Starts the Play purchase sheet. The result arrives on the purchase stream.
  Future<bool> buy() async {
    if (_isPro) return true;
    if (_product == null) await loadProduct();
    final product = _product;
    if (product == null) return false;
    _lastError = null;
    _purchasePending = true;
    notifyListeners();
    try {
      final started = await _store.buyNonConsumable(product);
      if (!started) {
        _purchasePending = false;
        notifyListeners();
      }
      return started;
    } catch (e) {
      _lastError = e.toString();
      _purchasePending = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> restore() async {
    _lastError = null;
    try {
      await _store.restorePurchases();
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
    }
  }

  @visibleForTesting
  Future<void> handlePurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != productId) {
        if (p.pendingCompletePurchase) await _complete(p);
        continue;
      }
      switch (p.status) {
        case PurchaseStatus.pending:
          _purchasePending = true;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final wasPro = _isPro;
          await _grant();
          _purchasePending = false;
          if (p.status == PurchaseStatus.purchased && !wasPro) onPurchased?.call(p);
          break;
        case PurchaseStatus.error:
          _lastError = p.error?.message ?? 'purchase error';
          _purchasePending = false;
          break;
        case PurchaseStatus.canceled:
          _purchasePending = false;
          break;
      }
      if (p.pendingCompletePurchase) await _complete(p);
    }
    notifyListeners();
  }

  Future<void> _complete(PurchaseDetails p) async {
    try {
      await _store.completePurchase(p); // acknowledges on Google Play
    } catch (e) {
      _lastError = e.toString();
    }
  }

  Future<void> _grant() async {
    _grants++;
    _isPro = true;
    await _prefs.setBool(prefsKey, true);
    // Play has the purchase, so any earlier empty answers were transient.
    await _prefs.setInt(emptyQueriesKey, 0);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
