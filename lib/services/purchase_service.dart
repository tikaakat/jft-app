import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config.dart';
import '../data/progress_store.dart';

enum PlanPeriod { yearly, monthly, other }

/// A purchasable plan as shown on the paywall. Prices come from Google Play,
/// so per-country pricing set in Play Console is shown automatically.
class Plan {
  const Plan({
    required this.id,
    required this.period,
    required this.price,
    this.raw,
  });
  final String id;
  final PlanPeriod period;

  /// Localized price string from the store (e.g. "Rp 99.000").
  final String price;
  final Object? raw;
}

enum BuyResult { success, cancelled, error }

/// Billing abstraction. [isPremium] is the single source of truth for
/// unlocking content.
abstract class PurchaseService {
  ValueListenable<bool> get isPremium;

  /// False when billing is not configured (no API key) or failed to start.
  bool get available;

  Future<void> init();
  Future<List<Plan>> plans();
  Future<BuyResult> buy(Plan plan);

  /// Returns true if an active premium entitlement was found.
  Future<bool> restore();
}

/// RevenueCat + Google Play Billing implementation.
class RevenueCatPurchaseService implements PurchaseService {
  RevenueCatPurchaseService(this._store, {this.apiKey = kRevenueCatApiKey})
    : _premium = ValueNotifier(_store.isPremium || kUnlockAll);

  final ProgressStore _store;
  final String apiKey;
  final ValueNotifier<bool> _premium;
  bool _available = false;

  @override
  ValueListenable<bool> get isPremium => _premium;

  @override
  bool get available => _available;

  @override
  Future<void> init() async {
    if (apiKey.isEmpty) {
      debugPrint('RevenueCat API key not set: billing disabled.');
      return;
    }
    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener(_apply);
      _available = true;
      _apply(await Purchases.getCustomerInfo());
    } catch (e) {
      // Offline etc.: keep the cached premium state.
      debugPrint('RevenueCat init failed: $e');
    }
  }

  void _apply(CustomerInfo info) {
    final active = info.entitlements.active.containsKey(kEntitlementId);
    _store.setPremium(active); // cache for offline start
    _premium.value = active || kUnlockAll;
  }

  @override
  Future<List<Plan>> plans() async {
    if (!_available) return const [];
    try {
      final offering = (await Purchases.getOfferings()).current;
      if (offering == null) return const [];
      final list = [
        for (final p in offering.availablePackages)
          Plan(
            id: p.identifier,
            period: switch (p.packageType) {
              PackageType.annual => PlanPeriod.yearly,
              PackageType.monthly => PlanPeriod.monthly,
              _ => PlanPeriod.other,
            },
            price: p.storeProduct.priceString,
            raw: p,
          ),
      ];
      // Yearly first: it is the plan we want to promote.
      list.sort((a, b) => a.period.index.compareTo(b.period.index));
      return list;
    } catch (e) {
      debugPrint('getOfferings failed: $e');
      return const [];
    }
  }

  @override
  Future<BuyResult> buy(Plan plan) async {
    try {
      final result = await Purchases.purchase(
        PurchaseParams.package(plan.raw! as Package),
      );
      _apply(result.customerInfo);
      return _premium.value ? BuyResult.success : BuyResult.error;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return BuyResult.cancelled;
      }
      debugPrint('purchase failed: $e');
      return BuyResult.error;
    }
  }

  @override
  Future<bool> restore() async {
    if (!_available) return _premium.value;
    try {
      _apply(await Purchases.restorePurchases());
    } catch (e) {
      debugPrint('restore failed: $e');
    }
    return _premium.value;
  }
}
