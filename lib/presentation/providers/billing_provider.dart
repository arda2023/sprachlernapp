import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/billing/adapty_billing_gateway.dart';
import 'account_provider.dart';

/// Public client configuration is injected at build time, never checked in.
/// Android remains disabled until its separate store connection is ready.
final billingGatewayProvider = Provider<BillingGateway?>((ref) {
  const key = String.fromEnvironment('ADAPTY_PUBLIC_SDK_KEY');
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS || key.isEmpty) {
    return null;
  }
  if (!key.startsWith('public_')) {
    throw StateError('Adapty benötigt den öffentlichen SDK-Schlüssel.');
  }
  return AdaptyBillingGateway(key);
});

enum BillingPhase { disabled, connecting, ready, unknown }

class BillingState {
  const BillingState(
    this.phase, {
    this.premiumActive,
    this.activeProductId,
    this.expiresAt,
  });

  final BillingPhase phase;

  /// Null means unknown, never "free". This client snapshot must not authorize
  /// server-side translations or quotas; those need verified backend access.
  final bool? premiumActive;
  final String? activeProductId;
  final DateTime? expiresAt;
}

final billingProvider = NotifierProvider<BillingController, BillingState>(
  BillingController.new,
);

class BillingController extends Notifier<BillingState> {
  int _generation = 0;

  @override
  BillingState build() {
    final gateway = ref.watch(billingGatewayProvider);
    final account = ref.watch(accountSessionProvider);
    final generation = ++_generation;
    StreamSubscription<BillingProfileSnapshot>? subscription;
    ref.onDispose(() {
      _generation++;
      unawaited(subscription?.cancel());
    });
    if (gateway == null) return const BillingState(BillingPhase.disabled);
    // Do not expose an anonymous or previous account's entitlement while the
    // persisted Supabase session is still being restored.
    if (account.isLoading) return const BillingState(BillingPhase.connecting);
    if (account.hasError) return const BillingState(BillingPhase.unknown);
    final customerUserId = account.value?.id;

    bool current() => ref.mounted && generation == _generation;
    // Do not block runApp, the launch curtain, or local content initialization.
    unawaited(
      Future<void>(() async {
        try {
          await gateway.activate();
          if (!current()) return;
          await gateway.bindCustomerUserId(customerUserId);
          if (!current()) return;
          var profileRevision = 0;
          subscription = gateway.profileUpdates.listen(
            (profile) {
              if (!current()) return;
              // A late profile event from the identity Adapty just left must
              // never be shown as the current account's access.
              if (profile.customerUserId != customerUserId) return;
              profileRevision++;
              state = BillingState(
                BillingPhase.ready,
                premiumActive: profile.premiumActive,
                activeProductId: profile.activeProductId,
                expiresAt: profile.expiresAt,
              );
            },
            onError: (Object _, StackTrace _) {
              if (!current()) return;
              profileRevision++;
              state = const BillingState(BillingPhase.unknown);
            },
          );
          final revision = profileRevision;
          try {
            final profile = await gateway.readProfile();
            if (current() && revision == profileRevision) {
              if (profile.customerUserId == customerUserId) {
                state = BillingState(
                  BillingPhase.ready,
                  premiumActive: profile.premiumActive,
                  activeProductId: profile.activeProductId,
                  expiresAt: profile.expiresAt,
                );
              } else {
                state = const BillingState(BillingPhase.unknown);
              }
            }
          } catch (_) {
            // A late failed read must not overwrite a newer stream result.
            if (current() && revision == profileRevision) {
              state = const BillingState(BillingPhase.unknown);
            }
          }
        } catch (_) {
          if (current()) state = const BillingState(BillingPhase.unknown);
        }
      }),
    );
    return const BillingState(BillingPhase.connecting);
  }
}
