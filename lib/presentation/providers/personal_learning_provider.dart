import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../data/content/bundled_content_updates.dart';
import '../../data/platform/sqlite_platform.dart';

import '../../data/personal_learning_client.dart';
import '../../data/learning/personal_learning_service.dart';
import 'content_update_provider.dart';
import 'database_providers.dart';
import 'runtime_translation_provider.dart';
import '../../data/content/content_install_journal.dart';
import '../../data/content/content_database.dart';
import '../../data/learning/personal_translation_hints.dart';

final personalLearningClientProvider = Provider<PersonalLearningClient>((ref) {
  final auth = ref.watch(contentAuthProvider);
  final store = PersonalConsentStore(() => openPrivateDatabase('private_learning_consent.sqlite'));
  final client = PersonalLearningClient(
    url: auth.url,
    publicKey: auth.publicKey,
    token: auth.accessToken,
    owner: auth.cacheOwner,
    revision: () => auth.identityRevision,
    identityChanges: auth.identityChanges,
    store: store,
  );
  ref.onDispose(() => unawaited(client.close()));
  return client;
});
final personalLearningServiceProvider = FutureProvider<PersonalLearningService>(
  (ref) async {
    var active = true;
    ref.onDispose(() => active = false);
    final content = await ref.watch(contentRepositoryProvider.future);
    final user = await ref.watch(userRepositoryProvider.future);
    final cache = ref.watch(runtimeTranslationProvider);
    return PersonalLearningService(
      content: content,
      user: user,
      translationHints: (target) => personalTranslationHints(cache, target),
      release: () => ref.read(personalReleaseReferenceProvider.future),
      client: ref.watch(personalLearningClientProvider),
      verify: () {
        if (!active) {
          throw const PersonalLearningFailure(
            'Inhalt oder Sprache geändert. Bitte erneut öffnen.',
          );
        }
      },
    );
  },
  retry: (_, _) => null,
);

final personalReleaseReferenceProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final content = await ref.watch(contentRepositoryProvider.future);
  final key = await ref.watch(activeContentKeyProvider.future);
  final installer = await ref.watch(
    contentInstallerProvider(content.info.lang).future,
  );
  final offer = kIsWeb
      ? await BundledContentTransport(installer.loadAsset, content.info.lang)
          .latest(content.info.lang, 0)
      : await ContentInstallJournal(
          installer.supportDirectory,
          content.info.lang,
        ).active();
  if (offer == null ||
      offer.contentManifest.version != content.info.version ||
      (kIsWeb ? offer.sha : GenerationIdentity.fromOffer(offer).fingerprint) !=
          key.fingerprint) {
    throw const PersonalLearningFailure(
      'Inhaltspack geändert oder noch nicht veröffentlicht. Bitte Inhalte aktualisieren.',
    );
  }
  return {
    'release_id': offer.id,
    'manifest_sha256': offer.manifestHash,
    'sqlite_sha256': offer.sha,
  };
}, retry: (_, _) => null);
