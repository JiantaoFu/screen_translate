import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
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

/// Whether the lite user owns the one-time `pro_unlock` product.
///
/// - Purchased/restored `pro_unlock` grants Pro and is remembered locally,
///   so Pro works offline and right at launch.
/// - Every purchase update that needs it is completed, which acknowledges it
///   on Google Play (unacknowledged purchases are refunded after 3 days).
/// - [init] restores purchases, so a reinstall or a new phone gets Pro back
///   without a tap; the paywall also has a Restore button.
/// - The price shown is Play's localized [ProductDetails.price], never a
///   hard-coded string.
class ProEntitlement extends ChangeNotifier {
  static const productId = 'pro_unlock';
  static const prefsKey = 'lite_pro_unlocked';

  final SharedPreferences _prefs;
  final StoreGateway _store;

  /// Called once for a new purchase (not for restores): analytics.
  final void Function(PurchaseDetails purchase)? onPurchased;

  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _isPro;
  bool _storeAvailable = false;
  bool _purchasePending = false;
  bool _initialized = false;
  ProductDetails? _product;
  String? _lastError;

  ProEntitlement(this._prefs, {StoreGateway? store, this.onPurchased})
      : _store = store ?? InAppPurchaseGateway(),
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
    _isPro = true;
    await _prefs.setBool(prefsKey, true);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
