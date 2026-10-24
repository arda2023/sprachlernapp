import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

import '../../data/runtime_translation_client.dart';
import '../../data/translation_cache.dart';
import 'content_update_provider.dart';

final runtimeTranslationProvider = Provider<RuntimeTranslationClient>((ref) {
  final auth = ref.read(contentAuthProvider);
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
