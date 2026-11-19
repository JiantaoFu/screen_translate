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

/// Whether the lite user owns Pro: the one-time `pro_unlock` product or an
/// active subscription ([subscriptionIds]).
///
/// - Any purchased/restored Pro product grants Pro and is remembered
///   locally, so Pro works offline and right at launch.
/// - Which products the paywall offers, and in what order, comes from
///   [offers] (Remote Config `lite_paywall_products`). A product Play
///   doesn't return is left out, so listing a subscription that hasn't been
///   created in Play Console yet changes nothing. Owning is checked against
///   every Pro product whatever is on offer, so turning a plan off never
///   takes Pro away from someone who bought it.
/// - Every purchase update that needs it is completed, which acknowledges it
///   on Google Play (unacknowledged purchases are refunded after 3 days).
/// - [init] restores purchases, so a reinstall or a new phone gets Pro back
///   without a tap; the paywall also has a Restore button.
/// - [init] also asks Play which purchases are owned ([syncWithStore]) and
///   revokes local Pro once Play has answered successfully without any
///   Pro product [emptyQueriesBeforeRevoke] times in a row (refunded +
///   revoked in Play Console, or a subscription that ran out). Offline, billing unavailable, any error, or a
///   single empty answer keeps the local state, so a paying user is never
///   locked out by a flaky connection or a signed-out Play Store.
/// - The price shown is Play's localized [ProductDetails.price], never a
///   hard-coded string.
class ProEntitlement extends ChangeNotifier {
  /// The one-time (lifetime) unlock.
  static const productId = 'pro_unlock';
  static const monthlyId = 'pro_monthly';
  static const yearlyId = 'pro_yearly';

  /// Auto-renewing plans. In Play Console each is a subscription with one
  /// base plan and no free-trial offer, so [ProductDetails.price] is the
  /// recurring price.
  static const subscriptionIds = {monthlyId, yearlyId};
  static const allProductIds = {productId, ...subscriptionIds};

  static bool isSubscription(String id) => subscriptionIds.contains(id);

  /// [raw] ("pro_yearly, pro_monthly,pro_unlock") as an ordered list of known
  /// product ids without repeats; `[pro_unlock]` when nothing usable is left.
  static List<String> parseOfferedIds(String raw) {
    final ids = <String>[];
    for (final part in raw.split(',')) {
      final id = part.trim();
      if (allProductIds.contains(id) && !ids.contains(id)) ids.add(id);
    }
    return ids.isEmpty ? const [productId] : ids;
  }

  static const prefsKey = 'lite_pro_unlocked';
  static const ownedProductKey = 'lite_pro_product';
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

  /// Called when Play no longer reports a Pro product and Pro is revoked,
  /// with the product that had granted it.
  final void Function(String productId)? onRevoked;

  /// The products to offer, in paywall order; read on every use so a Remote
  /// Config change applies without a restart.
  final List<String> Function() _offeredIds;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _isPro;
  bool _storeAvailable = false;
  bool _purchasePending = false;
  bool _initialized = false;
  int _grants = 0;
  Future<void>? _writing;
  final Map<String, ProductDetails> _products = {};
  String? _lastError;
  final DateTime Function() _now;
  DateTime? _lastSync;
  Future<ProSyncOutcome>? _syncing;

  /// Minimum time between the re-syncs [syncIfStale] runs on app resume.
  static const resyncInterval = Duration(minutes: 30);

  ProEntitlement(
    this._prefs, {
    StoreGateway? store,
    OwnedPurchasesSource? ownedPurchases,
    this.onPurchased,
    this.onRevoked,
    List<String> Function()? offeredIds,
    DateTime Function()? now,
  })  : _store = store ?? InAppPurchaseGateway(),
        _now = now ?? DateTime.now,
        _offeredIds = offeredIds ?? (() => const [productId]),
        _owned = ownedPurchases ?? PlayOwnedPurchasesSource(),
        _isPro = _prefs.getBool(prefsKey) ?? false;

  bool get isPro => _isPro;
  bool get storeAvailable => _storeAvailable;
  bool get purchasePending => _purchasePending;
  bool get initialized => _initialized;

  /// The one-time unlock's details; null until loaded.
  ProductDetails? get product => _products[productId];

  /// The one-time unlock's localized price from Play, e.g. "$2.99" or
  /// "¥22.00"; null until loaded.
  String? get price => product?.price;

  ProductDetails? productFor(String id) => _products[id];

  /// The products to show on the paywall, in order: the configured ones that
  /// Play returned. Falls back to the one-time unlock when none of them
  /// loaded, and is empty only when nothing loaded at all.
  List<ProductDetails> get offers {
    final configured = [
      for (final id in _offeredIds())
        if (_products[id] != null) _products[id]!,
    ];
    if (configured.isNotEmpty) return configured;
    final fallback = product;
    return fallback == null ? const [] : [fallback];
  }

  /// The product that granted Pro on this install, when known.
  String? get ownedProductId => _prefs.getString(ownedProductKey);
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
  /// Grants (and acknowledges) when Play has a Pro product but local doesn't.
  /// Revokes only after [emptyQueriesBeforeRevoke] successful queries in a
  /// row came back without it; otherwise keeps the current state.
  Future<ProSyncOutcome> syncWithStore() {
    // One query at a time: a resume during the launch sync joins it.
    return _syncing ??= _syncWithStore().whenComplete(() => _syncing = null);
  }

  /// Re-checks Play when the app comes back to the foreground, at most once
  /// per [resyncInterval]. Without it an expired subscription stayed Pro for
  /// as long as the app was never cold-started. The revoke rule is the same
  /// as at launch ([emptyQueriesBeforeRevoke] empty answers in a row; failed
  /// queries don't count).
  Future<ProSyncOutcome?> syncIfStale() async {
    if (!_initialized) return null;
    final last = _lastSync;
    if (last != null && _now().difference(last) < resyncInterval) return null;
    // Play may have been unavailable at launch (Billing not ready, offline)
    // and back since. Not returning early here: otherwise a cached Pro
    // could never be checked again in this process. The owned-purchases
    // query reports an unavailable store itself, which keeps Pro.
    _lastSync = _now();
    if (!_storeAvailable) await _retryStore();
    return syncWithStore();
  }

  Future<void> _retryStore() async {
    try {
      if (!await _store.isAvailable()) return;
      _storeAvailable = true;
      await loadProduct(); // so the paywall can offer the plans again
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
    }
  }

  Future<ProSyncOutcome> _syncWithStore() async {
    _lastSync = _now();
    final grantsBefore = _grants;
    OwnedPurchasesResult res;
    try {
      res = await _owned.queryOwned();
    } catch (_) {
      return ProSyncOutcome.kept;
    }
    if (res.status != OwnedQueryStatus.ok) return ProSyncOutcome.kept;

    final owned = res.purchases
        .where((p) =>
            allProductIds.contains(p.productID) &&
            (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored))
        .toList();
    if (owned.isNotEmpty) {
      if (_isPro) {
        if ((_prefs.getInt(emptyQueriesKey) ?? 0) != 0) {
          await _prefs.setInt(emptyQueriesKey, 0);
        }
        return ProSyncOutcome.unchanged;
      }
      await _grant(owned.first.productID);
      for (final p in owned) {
        if (p.pendingCompletePurchase) await _complete(p); // acknowledge
      }
      notifyListeners();
      return ProSyncOutcome.granted;
    }
    final lost = ownedProductId ?? productId;
    final outcome = await _serialized(() async {
      // A purchase that landed on the stream while we were querying, or
      // while an earlier write was in flight, wins. Checked inside the
      // serialized section, so no grant can slip in between this check and
      // the revoke below.
      if (!_isPro || _grants != grantsBefore) return ProSyncOutcome.unchanged;
      final empties = (_prefs.getInt(emptyQueriesKey) ?? 0) + 1;
      await _prefs.setInt(emptyQueriesKey, empties);
      if (empties < emptyQueriesBeforeRevoke) return ProSyncOutcome.kept;
      _isPro = false;
      await _prefs.setBool(prefsKey, false);
      await _prefs.setInt(emptyQueriesKey, 0);
      await _prefs.remove(ownedProductKey);
      return ProSyncOutcome.revoked;
    });
    if (outcome == ProSyncOutcome.revoked) {
      notifyListeners();
      onRevoked?.call(lost);
    }
    return outcome;
  }

  /// Runs entitlement writes (grant, revoke) one after another. Each one
  /// awaits several preference writes; without this a purchase granted
  /// during a revoke's writes could be overwritten by the revoke.
  ///
  /// When nothing is writing it runs at once, in the caller's zone and up to
  /// its first await synchronously, exactly like an unguarded call.
  Future<T> _serialized<T>(Future<T> Function() write) async {
    while (_writing != null) {
      await _writing;
    }
    final done = Completer<void>();
    _writing = done.future;
    try {
      return await write();
    } finally {
      _writing = null;
      done.complete();
    }
  }

  Future<void> loadProduct() async {
    try {
      final res = await _store.queryProductDetails(allProductIds);
      _products.clear();
      for (final p in res.productDetails) {
        // Play returns one entry per offer of a subscription; the first is
        // the base plan (see [subscriptionIds]).
        if (allProductIds.contains(p.id)) _products.putIfAbsent(p.id, () => p);
      }
      if (res.error != null) _lastError = res.error!.message;
    } catch (e) {
      _lastError = e.toString();
    }
    notifyListeners();
  }

  /// Starts the Play purchase sheet for [id] (the one-time unlock unless
  /// told otherwise). The result arrives on the purchase stream.
  Future<bool> buy([String id = productId]) async {
    if (_isPro) return true;
    if (_products[id] == null) await loadProduct();
    final product = _products[id];
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
      if (!allProductIds.contains(p.productID)) {
        // The Billing plugin can report a cancelled (or failed) purchase
        // with an empty productID. Only Pro products ever start a purchase
        // here, so that event still ends ours; otherwise the paywall would
        // spin forever. It never grants anything.
        if (p.status == PurchaseStatus.canceled) _purchasePending = false;
        if (p.status == PurchaseStatus.error) {
          _lastError = p.error?.message ?? 'purchase error';
          _purchasePending = false;
        }
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
          await _grant(p.productID);
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

  Future<void> _grant(String id) {
    // Counted at once, so a revoke queued behind an earlier write sees it.
    _grants++;
    return _serialized(() async {
      _isPro = true;
      await _prefs.setBool(prefsKey, true);
      await _prefs.setString(ownedProductKey, id);
      // Play has the purchase, so any earlier empty answers were transient.
      await _prefs.setInt(emptyQueriesKey, 0);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
