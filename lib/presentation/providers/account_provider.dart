import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth/native_account_identity.dart';
import '../../data/content/content_auth_repository.dart';
import 'content_update_provider.dart';

export '../../data/auth/native_account_identity.dart'
    show AccountIdentityProvider, AccountLoginCancelled;

typedef AccountSession = ({String id, String? email});

typedef AccountIdentityReader = Future<String?> Function();

/// Reads the initialized Supabase identity at security-sensitive action
/// boundaries instead of trusting a potentially stale widget snapshot.
final accountIdentityReaderProvider = Provider<AccountIdentityReader>((ref) {
  final auth = ref.watch(contentAuthProvider);
  return () async {
    await auth.initialize();
    return auth.userId;
  };
});

abstract interface class AccountActions {
  Future<void> signIn(AccountIdentityProvider provider);
  Future<void> sendCode(String email);
  Future<void> verifyCode(String email, String code);
  Future<void> signOut();
}

class SupabaseAccountActions implements AccountActions {
  SupabaseAccountActions(this.auth, this.identity, {this.onChanged});
  final ContentAuthRepository auth;
  final NativeAccountIdentity identity;
  final void Function()? onChanged;

  @override
  Future<void> signIn(AccountIdentityProvider provider) async {
    if (!auth.configured) {
      throw StateError('Anmeldung noch nicht eingerichtet.');
    }
    final credential = await identity.signIn(provider);
    await auth.signInWithIdToken(
      provider: switch (provider) {
        AccountIdentityProvider.apple => OAuthProvider.apple,
        AccountIdentityProvider.google => OAuthProvider.google,
      },
      idToken: credential.idToken,
      nonce: credential.nonce,
    );
    onChanged?.call();
  }

  @override
  Future<void> sendCode(String email) => auth.requestAccountCode(email);
  @override
  Future<void> verifyCode(String email, String code) async {
    await auth.verifyCode(email, code);
    onChanged?.call();
  }

  @override
  Future<void> signOut() async {
    await auth.signOut();
    onChanged?.call();
  }
}

final accountActionsProvider = Provider<AccountActions>(
  (ref) => SupabaseAccountActions(
    ref.watch(contentAuthProvider),
    NativeAccountIdentity(),
    onChanged: () {
      if (ref.mounted) ref.invalidate(contentUpdateProvider);
    },
  ),
);

final accountSessionProvider = StreamProvider<AccountSession?>((ref) {
  final auth = ref.watch(contentAuthProvider);
  // Subscribe before initializing so no identity change can fall in a gap.
  return Stream<AccountSession?>.multi((sink) {
    var ready = false;
    AccountSession? snapshot() => auth.signedIn && auth.userId != null
        ? (id: auth.userId!, email: auth.email)
        : null;
    final subscription = auth.identityChanges.listen((_) {
      if (ready) sink.add(snapshot());
    });
    var cancelled = false;
    sink.onCancel = () async {
      cancelled = true;
      await subscription.cancel();
    };
    unawaited(() async {
      try {
        await auth.initialize();
        if (cancelled) return;
        ready = true;
        sink.add(snapshot());
      } catch (error, stack) {
        if (!cancelled) sink.addError(error, stack);
      }
    }());
  });
});
