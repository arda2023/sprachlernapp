// Synthetic isolated installation and user-data harness. No app support path.
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/data/content/content_auth_repository.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/presentation/providers/content_update_provider.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/repositories.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';

import '../data/support.dart';

class LanguageHarness {
  LanguageHarness(this.root)
    : db = UserDatabase.file(File('${root.path}/user.sqlite')) {
    final en = buildFixturePack(root).readAsBytesSync();
    english = installerFor(root, db: en, manifest: manifestFor(en));
  }
  final Directory root;
  final UserDatabase db;
  late ContentPackInstaller english;
  ContentPackInstaller? portuguese;
  ContentAuthRepository? auth;
  final transports = <String, ContentReleaseTransport>{};
  final owners = <ContentRepositoryKey, RepositoryOwner<ContentRepository>>{};
  ContentPackInstaller installer(String lang) =>
      lang == 'en' ? english : portuguese ?? installerFor(root, lang: 'pt-BR');
  ProviderContainer scope() => ProviderContainer(
    overrides: [
      if (auth != null) contentAuthProvider.overrideWithValue(auth!),
      if (transports.isNotEmpty)
        contentReleaseTransportProvider.overrideWith(
          (ref, lang) => transports[lang]!,
        ),
      userDatabaseProvider.overrideWith((ref) async => db),
      contentInstallerProvider.overrideWith(
        (ref, lang) async => installer(lang),
      ),
      activeContentKeyProvider.overrideWith(
        (ref) async => contentKeyFor(
          installer(await ref.watch(selectedContentLanguageProvider.future)),
        ),
      ),
      contentOwnerProvider.overrideWith(
        (ref, key) => owners.putIfAbsent(
          key,
          () => createContentOwner(key, () async => installer(key.lang)),
        ),
      ),
      appInfoProvider.overrideWith((ref) async => 'synthetic'),
    ],
  );
  Future<void> close() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await db.close();
    root.deleteSync(recursive: true);
  }
}
