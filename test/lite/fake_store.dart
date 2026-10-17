import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:screen_translate/lite/pro_entitlement.dart';

ProductDetails proProduct({String price = r'$2.99'}) => ProductDetails(
      id: ProEntitlement.productId,
      title: 'Pro',
      description: 'Unlimited translations',
      price: price,
      rawPrice: 2.99,
      currencyCode: 'USD',
    );

PurchaseDetails purchase(PurchaseStatus status,
    {String productId = ProEntitlement.productId, bool pendingComplete = true}) {
  final p = PurchaseDetails(
    purchaseID: 'GPA.1',
    productID: productId,
    verificationData: PurchaseVerificationData(
        localVerificationData: 'l', serverVerificationData: 's', source: 'google_play'),
    transactionDate: '0',
    status: status,
  );
  p.pendingCompletePurchase = pendingComplete;
  if (status == PurchaseStatus.error) {
    p.error = IAPError(source: 'google_play', code: 'x', message: 'card declined');
  }
  return p;
}

class FakeStore implements StoreGateway {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  List<ProductDetails> products = [proProduct()];
  final completed = <PurchaseDetails>[];
  int restores = 0;
  final bought = <ProductDetails>[];

  /// What restorePurchases() emits (e.g. an owned pro_unlock on reinstall).
  List<PurchaseDetails> owned = [];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(
          productDetails: products.where((p) => ids.contains(p.id)).toList(), notFoundIDs: []);
  @override
  Future<bool> buyNonConsumable(ProductDetails product) async {
    bought.add(product);
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restores++;
    if (owned.isNotEmpty) controller.add(owned);
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async => completed.add(purchase);
}
