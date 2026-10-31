import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/foundation.dart';

import 'adapty_billing_gateway.dart';

enum PurchasePlan { monthly, yearly }

/// Store-localized product details safe to pass to presentation code.
class PurchaseProduct {
  const PurchaseProduct({
    required this.productId,
    required this.plan,
    required this.localizedPrice,
    required this.localizedPeriod,
    required this.isRecommended,
    this.priceAmount,
    this.trialDays,
  });

  final String productId;
  final PurchasePlan plan;
  final String localizedPrice;
  final String? localizedPeriod;
  final bool isRecommended;

  /// Numeric store price, for the per-month equivalent and the saving.
  final double? priceAmount;

  /// Length of a free introductory trial the store offers this account;
  /// null when there is none (never offered, or already used).
  final int? trialDays;

  /// [amount] written the way the store wrote [localizedPrice]: same
  /// currency symbol, position and decimal separator.
  String formatLike(double amount) {
    final number = RegExp(r'\d[\d.,\s ]*\d|\d').firstMatch(localizedPrice);
    if (number == null) return amount.toStringAsFixed(2);
    final digits = number.group(0)!;
    final comma = digits.length > 3 && digits[digits.length - 3] == ',';
    final value = amount.toStringAsFixed(2).replaceAll('.', comma ? ',' : '.');
    return localizedPrice.replaceRange(number.start, number.end, value);
  }
}

/// The store's free-trial length in days for one introductory phase, or
/// null for any other kind of offer.
int? freeTrialDays({
  required bool introductory,
  required List<({bool freeTrial, String unit, int units, int periods})> phases,
}) {
  if (!introductory || phases.length != 1 || !phases.single.freeTrial) {
    return null;
  }
  final phase = phases.single;
  final perUnit = switch (phase.unit) {
    'day' => 1,
    'week' => 7,
    _ => null,
  };
  if (perUnit == null) return null;
  final days = perUnit * phase.units * phase.periods;
  return days > 0 ? days : null;
}

enum PurchaseOutcome { success, cancelled, pending }

enum RestoreOutcome { restored, noPurchases }

abstract interface class PurchaseGateway {
  Future<List<PurchaseProduct>> loadCatalog({required String? customerUserId});

  Future<PurchaseOutcome> purchase({
    required String customerUserId,
    required String productId,
    bool Function()? isCurrent,
  });

  Future<RestoreOutcome> restore({
    required String customerUserId,
    bool Function()? isCurrent,
  });
}

/// Adapty-backed catalog and purchase implementation for the custom paywall.
///
/// Products are fetched from the `premium` placement so prices always come
/// from the current storefront. The app's configured product IDs are checked
/// against each returned item to prevent an unrelated dashboard product from
/// appearing in this paywall.
class AdaptyPurchaseGateway implements PurchaseGateway {
  AdaptyPurchaseGateway(this.identityRunner);

  final BillingIdentityRunner identityRunner;
  final Map<String, AdaptyPaywallProduct> _storeProducts = {};

  static const placementId = 'premium';
  static const monthlyProductId = 'com.ardasayar.linglossa.premium.monthly';
  static const yearlyProductId = 'com.ardasayar.linglossa.premium.yearly';

  @override
  Future<List<PurchaseProduct>> loadCatalog({
    required String? customerUserId,
  }) => identityRunner.runForCustomerUserId(customerUserId, () async {
    var stage = 'placement';
    late final List<AdaptyPaywallProduct> products;
    try {
      final flow = await Adapty().getFlow(placementId: placementId);
      stage = 'store products';
      products = await Adapty().getPaywallProducts(flow: flow);
    } on AdaptyError catch (error) {
      // Only the stage and numeric SDK code: no account data or credentials.
      if (kDebugMode) {
        debugPrint('Billing catalog: $stage failed (Adapty ${error.code}).');
      }
      rethrow;
    }
    _storeProducts.clear();
    // Product IDs and skip reasons only: tells a store gap from a filter.
    void skipped(AdaptyPaywallProduct product, String reason) {
      if (kDebugMode) {
        debugPrint('Billing catalog: ${product.vendorProductId} $reason.');
      }
    }

    if (kDebugMode) {
      final ids = products.map((product) => product.vendorProductId);
      debugPrint('Billing catalog: store returned ${ids.join(', ')}.');
    }

    final result = <PurchaseProduct>[];
    for (final product in products) {
      final plan = switch (product.vendorProductId) {
        monthlyProductId => PurchasePlan.monthly,
        yearlyProductId => PurchasePlan.yearly,
        _ => null,
      };
      if (plan == null || product.accessLevelId != 'premium') {
        skipped(product, 'skipped (unknown ID or access level)');
        continue;
      }
      // Only a plain free introductory trial is surfaced (user decision
      // 31.10.2026); StoreKit attaches it only while the account is
      // eligible. Any other offer keeps the product off this paywall.
      final offer = product.subscription?.offer;
      final trialDays = offer == null
          ? null
          : freeTrialDays(
              introductory:
                  offer.identifier.type ==
                  AdaptySubscriptionOfferType.introductory,
              phases: [
                for (final phase in offer.phases)
                  (
                    freeTrial: phase.paymentMode == AdaptyPaymentMode.freeTrial,
                    unit: phase.subscriptionPeriod.unit.name,
                    units: phase.subscriptionPeriod.numberOfUnits,
                    periods: phase.numberOfPeriods,
                  ),
              ],
            );
      if (offer != null && offer.phases.isNotEmpty && trialDays == null) {
        skipped(product, 'skipped (offer other than a free trial)');
        continue;
      }
      final localizedPrice = product.price.localizedString;
      if (localizedPrice == null || localizedPrice.isEmpty) {
        skipped(product, 'skipped (no localized price)');
        continue;
      }

      _storeProducts[product.vendorProductId] = product;
      result.add(
        PurchaseProduct(
          productId: product.vendorProductId,
          plan: plan,
          localizedPrice: localizedPrice,
          localizedPeriod: product.subscription?.localizedPeriod,
          isRecommended: plan == PurchasePlan.yearly,
          priceAmount: product.price.amount,
          trialDays: trialDays,
        ),
      );
    }
    result.sort((a, b) => a.plan.index.compareTo(b.plan.index));
    return List.unmodifiable(result);
  });

  @override
  Future<PurchaseOutcome> purchase({
    required String customerUserId,
    required String productId,
    bool Function()? isCurrent,
  }) => identityRunner.runForCustomerUserId(customerUserId, () async {
    final product = _storeProducts[productId];
    if (product == null) {
      throw StateError('Das ausgewählte Premium-Abo ist nicht mehr verfügbar.');
    }
    final result = await Adapty().makePurchase(product: product);
    return switch (result) {
      AdaptyPurchaseResultSuccess(:final profile)
          when profile.customerUserId == customerUserId =>
        PurchaseOutcome.success,
      AdaptyPurchaseResultSuccess() => throw StateError(
        'Der Kauf wurde einem anderen App-Konto zugeordnet.',
      ),
      AdaptyPurchaseResultUserCancelled() => PurchaseOutcome.cancelled,
      AdaptyPurchaseResultPending() => PurchaseOutcome.pending,
    };
  }, isCurrent: isCurrent);

  @override
  Future<RestoreOutcome> restore({
    required String customerUserId,
    bool Function()? isCurrent,
  }) => identityRunner.runForCustomerUserId(customerUserId, () async {
    final profile = await Adapty().restorePurchases();
    if (profile.customerUserId != customerUserId) {
      throw StateError(
        'Die Wiederherstellung gehört zu einem anderen App-Konto.',
      );
    }
    final premiumActive = profile.accessLevels['premium']?.isActive ?? false;
    return premiumActive ? RestoreOutcome.restored : RestoreOutcome.noPurchases;
  }, isCurrent: isCurrent);
}
