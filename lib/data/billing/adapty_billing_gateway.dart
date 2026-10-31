import 'package:adapty_flutter/adapty_flutter.dart';
import 'package:flutter/foundation.dart';

/// Kept behind an interface so startup and network failures can be tested
/// without a store account or native purchase sheet.
abstract interface class BillingGateway {
  Future<void> activate();
  Future<void> bindCustomerUserId(String? customerUserId);
  Future<BillingProfileSnapshot> readProfile();
  Stream<BillingProfileSnapshot> get profileUpdates;
}

/// Serializes store operations with Adapty identity changes.
///
/// A purchase is executed only while the expected authenticated account is the
/// identity currently bound to the Adapty profile. Keeping the operation in
/// the same queue as identify/logout prevents an account switch from changing
/// the customer attribution while a store sheet is active.
abstract interface class BillingIdentityRunner {
  Future<T> runForCustomerUserId<T>(
    String? customerUserId,
    Future<T> Function() operation, {
    bool Function()? isCurrent,
  });
}

/// Entitlement data tagged with the identity Adapty returned it for.
typedef BillingProfileSnapshot = ({
  String? customerUserId,
  bool premiumActive,
  String? activeProductId,
  DateTime? expiresAt,
});

class AdaptyBillingGateway implements BillingGateway, BillingIdentityRunner {
  AdaptyBillingGateway(this.publicSdkKey);

  final String publicSdkKey;
  static Future<void>? _activation;
  Future<void> _identityOperations = Future<void>.value();
  String? _boundCustomerUserId;
  bool _identityKnown = false;

  static const placementId = 'premium';
  static const accessLevelId = 'premium';

  @override
  Future<void> activate() => _activation ??= _activate();

  Future<void> _activate() async {
    try {
      if (await Adapty().isActivated()) {
        if (kDebugMode) Adapty().setupAfterHotRestart();
        return;
      }
      await Adapty().activate(
        configuration: AdaptyConfiguration(apiKey: publicSdkKey)
          ..withActivateUI(false)
          ..withAppleIdfaCollectionDisabled(true)
          ..withGoogleAdvertisingIdCollectionDisabled(true)
          ..withIpAddressCollectionDisabled(true)
          ..withAdaptyAttributionEnabled(false)
          ..withLogLevel(AdaptyLogLevel.error),
      );
      // Activation may restore an existing identified profile from the SDK's
      // disk cache, so resolve it before deciding whether identify/logout can
      // be skipped.
      _identityKnown = false;
    } catch (_) {
      _activation = null;
      rethrow;
    }
  }

  @override
  Future<void> bindCustomerUserId(String? customerUserId) {
    final operation = _identityOperations.then((_) async {
      try {
        final currentUserId = _identityKnown
            ? _boundCustomerUserId
            : (await Adapty().getProfile()).customerUserId;
        if (currentUserId != customerUserId) {
          if (customerUserId == null) {
            await Adapty().logout();
          } else {
            await Adapty().identify(customerUserId);
          }
        }
        _boundCustomerUserId = customerUserId;
        _identityKnown = true;
      } catch (_) {
        // The native call can partially update Adapty before reporting an
        // error. Resolve the actual profile again on the next request.
        _boundCustomerUserId = null;
        _identityKnown = false;
        rethrow;
      }
    });
    // Keep the queue usable after one failed native call, while returning that
    // failure to its caller so the provider can clear the entitlement state.
    _identityOperations = operation.catchError((Object _) {});
    return operation;
  }

  @override
  Future<T> runForCustomerUserId<T>(
    String? customerUserId,
    Future<T> Function() operation, {
    bool Function()? isCurrent,
  }) {
    final queued = _identityOperations.then((_) async {
      final boundCustomerUserId = _identityKnown
          ? _boundCustomerUserId
          : (await Adapty().getProfile()).customerUserId;
      if (boundCustomerUserId != customerUserId) {
        _boundCustomerUserId = null;
        _identityKnown = false;
        throw StateError(
          'Adapty-Konto stimmt nicht mit dem App-Konto überein.',
        );
      }
      // Recheck the app session after this operation reaches the head of the
      // same queue as identify/logout. The identity may have changed while
      // this operation was waiting behind a native SDK call.
      if (isCurrent != null && !isCurrent()) {
        throw StateError(
          'Das App-Konto hat sich vor dem Store-Aufruf geändert.',
        );
      }
      _boundCustomerUserId = customerUserId;
      _identityKnown = true;
      return operation();
    });
    // A failed store operation must not poison the identity queue.
    _identityOperations = queued.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return queued;
  }

  @override
  Future<BillingProfileSnapshot> readProfile() async =>
      _snapshot(await Adapty().getProfile());

  @override
  Stream<BillingProfileSnapshot> get profileUpdates =>
      Adapty().didUpdateProfileStream.map(_snapshot);

  BillingProfileSnapshot _snapshot(AdaptyProfile profile) {
    final accessLevel = profile.accessLevels[accessLevelId];
    return (
      customerUserId: profile.customerUserId,
      premiumActive: accessLevel?.isActive ?? false,
      activeProductId: accessLevel?.isActive == true
          ? accessLevel!.vendorProductId
          : null,
      expiresAt: accessLevel?.expiresAt,
    );
  }
}
