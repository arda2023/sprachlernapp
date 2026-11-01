import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import '../../data/runtime_translation_client.dart';
import '../../data/translation_cache.dart';
import 'content_update_provider.dart';

final runtimeTranslationProvider = Provider<RuntimeTranslationClient>((ref) {
  final auth = ref.watch(contentAuthProvider);
  final client = CachedRuntimeTranslationClient(
    remote: RuntimeTranslationClient(
      auth.url,
      auth.publicKey,
      auth.accessToken,
    ),
    store: TranslationCache(() async {
      final support = await getApplicationSupportDirectory();
      await support.create(recursive: true);
      return sqlite3.open(
        path.join(support.path, 'private_translations.sqlite'),
      );
    }),
    owner: auth.cacheOwner,
    revision: () => auth.identityRevision,
    identityChanges: auth.identityChanges,
  );
  ref.onDispose(() => unawaited(client.close()));
  return client;
});

/// Set once the server reports the free AI translations as used up, so the
/// next tap shows the Premium card at once instead of a request that can
/// only fail. Memory only; an account or storage change clears it.
final freeTranslationsUsedUpProvider =
    NotifierProvider<FreeTranslationsUsedUp, bool>(FreeTranslationsUsedUp.new);

class FreeTranslationsUsedUp extends Notifier<bool> {
  @override
  bool build() {
    final changes = ref
        .watch(runtimeTranslationProvider)
        .changes
        .listen((_) => state = false);
    ref.onDispose(changes.cancel);
    return false;
  }

  void markUsedUp() => state = true;
}
