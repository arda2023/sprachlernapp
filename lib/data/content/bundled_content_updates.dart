import 'dart:convert';
import 'dart:io';

import '../../domain/language_profile.dart';
import 'content_database.dart';
import 'content_install_journal.dart';
import 'content_pack_installer.dart';
import 'content_release_client.dart';
import 'content_update_service.dart';

/// A release shipped with this app, using the same validated contract as a
/// remote release. Authorization is the immutable app bundle, never a login.
class BundledContentTransport implements ContentReleaseTransport {
  BundledContentTransport(this.loadAsset, this.lang);
  final AssetLoader loadAsset;
  final String lang;
  String get directory => 'assets/content/$lang';

  @override
  Future<ReleaseOffer?> latest(String lang, int generation) async {
    if (lang != this.lang) throw ArgumentError('Falsche Inhaltssprache');
    final bytes = await loadAsset('$directory/bundled-release.json');
    if (bytes == null) return null;
    final offer = ReleaseOffer.parse(
      jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      lang,
      allowBundled: true,
    );
    if (!offer.isBundled) {
      throw const FormatException(
        'Gebündeltes Angebot benötigt eigene Herkunft.',
      );
    }
    // An app downgrade must never replace a newer installed release.
    return offer.generation < generation ? null : offer;
  }

  @override
  Future<Map<String, Uri>> downloads(ReleaseOffer offer) async {
    final bundled = await latest(lang, 0);
    if (bundled == null || bundled.manifestHash != offer.manifestHash) {
      throw const FormatException('Gebündelte Versionsfreigabe geändert.');
    }
    return {
      for (final name in ['content.sqlite', 'history_inventory.json'])
        name: Uri(scheme: 'asset', path: '$directory/$name'),
    };
  }

  @override
  Stream<List<int>> bytes(Uri uri) async* {
    if (uri.scheme != 'asset' ||
        uri.hasAuthority ||
        ![
          '$directory/content.sqlite',
          '$directory/history_inventory.json',
        ].contains(uri.path)) {
      throw const FormatException('Ungültiger gebündelter Inhaltspfad.');
    }
    final data = await loadAsset(uri.path);
    if (data == null) {
      throw const FormatException('Gebündelte Inhaltsdatei fehlt.');
    }
    yield data;
  }
}

/// Cold-start only: call before runApp and before any content reader is opened.
/// Runs the existing full history validation and journalled activation without
/// touching user.db. A failed candidate leaves the previous generation usable.
/// The caller can display returned failures after starting the app.
Future<Map<String, Object>> applyBundledContentUpdates({
  required AssetLoader loadAsset,
  required Directory supportDirectory,
  Iterable<String> languages = const ['pt-BR', 'nb', 'it', 'es'],
}) async {
  final failures = <String, Object>{};
  for (final lang in languages) {
    try {
      if (ContentLanguageProfile.forLanguage(lang) == null) {
        throw ArgumentError('Nicht unterstützte Inhaltssprache: $lang');
      }
      final transport = BundledContentTransport(loadAsset, lang);
      final journal = ContentInstallJournal(supportDirectory, lang);
      final bundled = await transport.latest(lang, 0);
      if (bundled == null) continue;
      final state = await resolveInstalledState(journal);
      final active = state.prepared
          ? await recoverContentInstallation(journal)
          : state.offer;
      if (active != null) {
        if (active.cloudGeneration > bundled.cloudGeneration) continue;
        if (active.cloudGeneration != bundled.cloudGeneration ||
            active.cloudManifestHash != bundled.cloudManifestHash) {
          throw const FormatException(
            'Gebündeltes Paket gehört zu einer anderen Cloudbasis.',
          );
        }
        if (active.isBundled && active.generation > bundled.generation) {
          continue;
        }
      }
      if (active?.manifestHash == bundled.manifestHash) continue;
      final pending = await journal.read('pending');
      if (pending != null &&
          pending['manifest_sha256'] != bundled.manifestHash) {
        throw StateError('Eine andere Inhaltsversion wartet auf Aktivierung.');
      }
      final service = ContentUpdateService(
        journal,
        transport,
        bundled: true,
        currentFile: journal.currentFile,
        gate: ContentTransitionGate(),
        // There are no live readers during cold-start initialization.
        closeReaders: () async {},
        openReaders: () async {
          final file = await journal.currentFile();
          if (file == null) throw StateError('Aktivierter Inhalt fehlt.');
          final db = await ContentDatabase.openInBackground(file, lang: lang);
          await db.close();
        },
      );
      await service.check();
      if (service.available == null) continue;
      await service.download();
      await service.activate();
    } catch (error) {
      failures[lang] = error;
    }
  }
  return failures;
}
