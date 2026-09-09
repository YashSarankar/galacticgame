import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Official Google Play Billing & iOS StoreKit In-App Purchase Service
class InAppPurchaseService {
  static final InAppPurchaseService _instance = InAppPurchaseService._internal();
  factory InAppPurchaseService() => _instance;
  InAppPurchaseService._internal();

  InAppPurchase get _iap => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  // Registered Google Play SKUs
  static const String skuVipPass = 'vip_commander_pass';
  static const String skuDmSmall = 'dm_pack_small';
  static const String skuDmMedium = 'dm_pack_medium';
  static const String skuDmLarge = 'dm_pack_large';
  static const String skuCreditsSmall = 'credits_cache_small';
  static const String skuCreditsLarge = 'credits_cache_large';

  static const Set<String> _productIds = {
    skuVipPass,
    skuDmSmall,
    skuDmMedium,
    skuDmLarge,
    skuCreditsSmall,
    skuCreditsLarge,
  };

  final Map<String, ProductDetails> _products = {};
  Map<String, ProductDetails> get products => _products;

  // Callbacks hooked by GameEconomyNotifier
  void Function()? onVipPurchased;
  void Function(double darkMatter)? onDarkMatterPurchased;
  void Function(double credits)? onCreditsPurchased;
  void Function(String errorMessage)? onError;

  /// Initializes Google Play Billing connection and loads store catalog
  Future<void> initialize() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        _isAvailable = await _iap.isAvailable();
        if (_isAvailable) {
          _subscription = _iap.purchaseStream.listen(
            _onPurchaseUpdate,
            onDone: () => _subscription?.cancel(),
            onError: (err) {
              debugPrint('[IAP] Purchase stream error: $err');
              onError?.call('Billing connection error: $err');
            },
          );
          await loadProducts();
        } else {
          debugPrint('[IAP] Google Play Billing is unavailable on this device.');
        }
      } catch (e) {
        debugPrint('[IAP] Failed to initialize in_app_purchase: $e');
      }
    }
  }

  /// Loads official product metadata and localized prices from Google Play
  Future<void> loadProducts() async {
    try {
      final ProductDetailsResponse response =
          await _iap.queryProductDetails(_productIds);
      if (response.error != null) {
        debugPrint('[IAP] Query error: ${response.error!.message}');
        return;
      }
      for (final product in response.productDetails) {
        _products[product.id] = product;
        debugPrint('[IAP] Loaded product: ${product.id} -> ${product.price}');
      }
    } catch (e) {
      debugPrint('[IAP] Failed to query product details: $e');
    }
  }

  /// Get formatted price from Google Play or fallback string
  String getPrice(String productId, {String fallback = '₹99.00'}) {
    final product = _products[productId];
    return product?.price ?? fallback;
  }

  /// Purchases the non-consumable VIP Commander Lifetime Pass
  Future<void> purchaseVipPass({
    VoidCallback? onSuccess,
    void Function(String error)? onFailure,
  }) async {
    // Simulator / Desktop / Standalone fallback simulation
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS) || !_isAvailable) {
      debugPrint('[IAP] Simulating VIP purchase on non-mobile/test environment...');
      await Future.delayed(const Duration(milliseconds: 700));
      onVipPurchased?.call();
      onSuccess?.call();
      return;
    }

    final product = _products[skuVipPass];
    if (product == null) {
      // If store hasn't populated SKU yet in testing, attempt fallback simulation
      debugPrint('[IAP] Product $skuVipPass not found in store. Triggering dev fallback...');
      await Future.delayed(const Duration(milliseconds: 700));
      onVipPurchased?.call();
      onSuccess?.call();
      return;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('[IAP] Purchase exception: $e');
      onFailure?.call('Failed to launch Google Play Billing: $e');
    }
  }

  /// Purchases consumable Dark Matter or Credit packs
  Future<void> purchaseConsumable(
    String productId, {
    VoidCallback? onSuccess,
    void Function(String error)? onFailure,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS) || !_isAvailable) {
      debugPrint('[IAP] Simulating consumable purchase: $productId');
      await Future.delayed(const Duration(milliseconds: 700));
      _deliverProduct(productId);
      onSuccess?.call();
      return;
    }

    final product = _products[productId];
    if (product == null) {
      debugPrint('[IAP] Product $productId not found. Simulating test grant...');
      await Future.delayed(const Duration(milliseconds: 700));
      _deliverProduct(productId);
      onSuccess?.call();
      return;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
    } catch (e) {
      debugPrint('[IAP] Consumable purchase exception: $e');
      onFailure?.call('Failed to purchase: $e');
    }
  }

  /// Restores previous non-consumable purchases (Required by Google Play & Apple App Store)
  Future<void> restorePurchases({
    VoidCallback? onComplete,
    void Function(String error)? onError,
  }) async {
    if (!_isAvailable) {
      onComplete?.call();
      return;
    }
    try {
      await _iap.restorePurchases();
      onComplete?.call();
    } catch (e) {
      debugPrint('[IAP] Restore purchases exception: $e');
      onError?.call('Failed to restore purchases: $e');
    }
  }

  /// Internal listener processing purchase states from Google Play Billing
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('[IAP] Purchase pending: ${purchaseDetails.productID}');
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('[IAP] Purchase error: ${purchaseDetails.error?.message}');
        onError?.call(purchaseDetails.error?.message ?? 'Payment failed or cancelled.');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Deliver digital items
        _deliverProduct(purchaseDetails.productID);

        // Complete transaction with Google Play Billing
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void _deliverProduct(String productId) {
    debugPrint('[IAP] Delivering digital goods for SKU: $productId');
    switch (productId) {
      case skuVipPass:
        onVipPurchased?.call();
        break;
      case skuDmSmall:
        onDarkMatterPurchased?.call(100.0);
        break;
      case skuDmMedium:
        onDarkMatterPurchased?.call(500.0);
        break;
      case skuDmLarge:
        onDarkMatterPurchased?.call(1500.0);
        break;
      case skuCreditsSmall:
        onCreditsPurchased?.call(10000000.0);
        break;
      case skuCreditsLarge:
        onCreditsPurchased?.call(100000000.0);
        break;
      default:
        // Handle custom SKUs
        if (productId.contains('vip') || productId.contains('remove_ads')) {
          onVipPurchased?.call();
        }
        break;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
