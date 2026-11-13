import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/billing/adapty_billing_gateway.dart';
import '../../domain/trial_reminder.dart';
import 'auth_providers.dart';

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
    this.trial,
  });

  final BillingPhase phase;

  /// Null means unknown, never "free". This client snapshot must not authorize
  /// server-side translations or quotas; those need verified backend access.
  final bool? premiumActive;
  final String? activeProductId;
  final DateTime? expiresAt;
  final TrialSubscription? trial;
}

final billingProvider = NotifierProvider<BillingController, BillingState>(
  BillingController.new,
);

class BillingController extends Notifier<BillingState> {
  int _generation = 0;
  int _profileRevision = 0;

  @override
  BillingState build() {
    final gateway = ref.watch(billingGatewayProvider);
    final account = ref.watch(accountSessionProvider);
    final generation = ++_generation;
    _profileRevision = 0;
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
          subscription = gateway.profileUpdates.listen(
            (profile) {
              if (!current()) return;
              // A late profile event from the identity Adapty just left must
              // never be shown as the current account's access.
              if (profile.customerUserId != customerUserId) return;
              _profileRevision++;
              state = BillingState(
                BillingPhase.ready,
                premiumActive: profile.premiumActive,
                activeProductId: profile.activeProductId,
                expiresAt: profile.expiresAt,
                trial: profile.trial,
              );
            },
            onError: (Object _, StackTrace _) {
              if (!current()) return;
              _profileRevision++;
              state = const BillingState(BillingPhase.unknown);
            },
          );
          final revision = _profileRevision;
          try {
            final profile = await gateway.readProfile();
            if (current() && revision == _profileRevision) {
              if (profile.customerUserId == customerUserId) {
                state = BillingState(
                  BillingPhase.ready,
                  premiumActive: profile.premiumActive,
                  activeProductId: profile.activeProductId,
                  expiresAt: profile.expiresAt,
                  trial: profile.trial,
                );
              } else {
                state = const BillingState(BillingPhase.unknown);
              }
            }
          } catch (_) {
            // A late failed read must not overwrite a newer stream result.
            if (current() && revision == _profileRevision) {
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

  /// Refresh without rebuilding the identity-bound controller or interrupting
  /// an in-flight purchase. Newer stream events always win over this read.
  Future<void> refresh() async {
    final gateway = ref.read(billingGatewayProvider);
    final account = ref.read(accountSessionProvider);
    if (gateway == null ||
        account.isLoading ||
        account.hasError ||
        state.phase == BillingPhase.connecting ||
        state.phase == BillingPhase.disabled) {
      return;
    }
    if (state.phase == BillingPhase.unknown) {
      // Recreate failed activation/subscription as well as retrying its read.
      ref.invalidateSelf();
      return;
    }
    final generation = _generation;
    final revision = _profileRevision;
    final customerUserId = account.value?.id;
    bool current() =>
        ref.mounted &&
        generation == _generation &&
        revision == _profileRevision;
    try {
      final profile = await gateway.readProfile();
      if (!current()) return;
      if (profile.customerUserId != customerUserId) {
        state = const BillingState(BillingPhase.unknown);
        return;
      }
      state = BillingState(
        BillingPhase.ready,
        premiumActive: profile.premiumActive,
        activeProductId: profile.activeProductId,
        expiresAt: profile.expiresAt,
        trial: profile.trial,
      );
    } catch (_) {
      if (current()) state = const BillingState(BillingPhase.unknown);
    }
  }
}
