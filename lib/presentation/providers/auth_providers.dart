import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/content/content_auth_repository.dart';

final contentAuthProvider = Provider<ContentAuthRepository>((ref) {
  final auth = ContentAuthRepository(
    const String.fromEnvironment('SUPABASE_URL'),
    const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  ref.onDispose(() => unawaited(auth.close()));
  return auth;
});

typedef AccountSession = ({String id, String? email});

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
