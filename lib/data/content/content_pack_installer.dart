import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/content.dart';
import 'content_database.dart';
import 'drift_content_repository.dart';
import 'content_install_journal.dart';
import 'content_update_service.dart';
import 'context_revision_validation.dart';

/// Loads a bundled asset by key; null when the asset doesn't exist.
typedef AssetLoader = Future<Uint8List?> Function(String key);

/// Pins the bundled asset as an immutable bootstrap generation on first use.
/// Later starts prefer the journal's active generation; an app-bundled asset
/// must never replace a newer installed release or its historical identities.
/// All files stay under `<support>/content/<lang>/`; user.db is untouched.
class ContentPackInstaller {
  ContentPackInstaller({
    required this.loadAsset,
    required this.supportDirectory,
    this.lang = 'en',
    this.validationRegistry,
  });

  final AssetLoader loadAsset;
  final Directory supportDirectory;
  final String lang;
  final ProcessValidationRegistry? validationRegistry;

  String get assetDirectory => 'assets/content/$lang';
  String get manifestAsset => '$assetDirectory/content.manifest.json';
  String get databaseAsset => '$assetDirectory/content.sqlite';

  File get installedFile =>
      File(p.join(supportDirectory.path, 'content', lang, 'content.sqlite'));

  /// The installer of the running app: assets from the bundle, files under
  /// the application support directory.
  static Future<ContentPackInstaller> forApp({String lang = 'en'}) async {
    final support = await getApplicationSupportDirectory();
    return ContentPackInstaller(
      loadAsset: _loadBundled, supportDirectory: support, lang: lang,
      validationRegistry: await ProcessValidationRegistry.forAppSupport(support),
    );
  }

  /// Complete routing identity without opening any database. An uninstalled
  /// bundled pack uses its manifest identity so its first install keeps the key.
  Future<({int generation, String fingerprint})> routingIdentity() async {
    final state = await resolveInstalledState(ContentInstallJournal(supportDirectory, lang));
    if (state.offer != null) return (generation: state.offer!.generation, fingerprint: state.fingerprint!);
    final String? text;
    if (state.pointer != null) {
      text = jsonEncode(state.pointer!['manifest']);
    } else {
      final bytes = await loadAsset(manifestAsset);
      text = bytes == null ? null : utf8.decode(bytes);
    }
    if (text == null) return (generation: 0, fingerprint: 'missing:$lang');
    final manifest = ContentManifest.parse(text, lang: lang);
    return (generation: 0, fingerprint: contextCanonicalHash(jsonDecode(manifest.toJson())));
  }

  /// Metadata only: never install, hash, recover or open a content reader here.
  Future<String> readInstallationMetadata() async {
    final journal = ContentInstallJournal(supportDirectory, lang);
    final state = await resolveInstalledState(journal);
    if (state.prepared) return 'Wiederherstellung beim Öffnen erforderlich';
    if (state.pointer == null) return 'Noch nicht installiert';
    final file = await journal.currentFile();
    if (file == null || !await file.exists()) return 'Installation beschädigt';
    if (state.offer != null && !await File('${journal.generation(state.offer!.id).path}/history_inventory.json').exists()) {
      return 'Installation beschädigt';
    }
    final version = state.offer?.manifest['version'] ??
      ContentManifest.parse(jsonEncode(state.pointer!['manifest']), lang: lang).version;
    return 'Installiert · $version · Prüfung beim Öffnen';
  }

  static Future<Uint8List?> _loadBundled(String key) async {
    try {
      final data = await rootBundle.load(key);
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on FlutterError {
      return null; // not bundled
    }
  }

  /// Installs (if needed) and returns the installed file and its manifest.
  Future<({File file, ContentManifest manifest})> install() async {
    final journal = ContentInstallJournal(supportDirectory, lang);
    final active = await recoverContentInstallation(journal);
    if (active != null) {
      return (file: File('${journal.generation(active.id).path}/content.sqlite'), manifest: active.contentManifest);
    }
    final pointer=await journal.read('active');
    final pinned=pointer?['bootstrap']==true
        ? ContentManifest.parse(jsonEncode(pointer!['manifest']),lang:lang) : null;
    if(pinned!=null && await _matches(journal.bootstrapFile(pinned),pinned.sha256)) {
      return (file:journal.bootstrapFile(pinned),manifest:pinned);
    }
    final manifestBytes = await loadAsset(manifestAsset);
    if (manifestBytes == null && pointer != null) {
      throw const ContentUnavailable(ContentUnavailableReason.corrupt,
        'Installierter Inhaltsbestand beschädigt. Reparatur erforderlich.');
    }
    if (manifestBytes == null) {
      throw ContentUnavailable(
        ContentUnavailableReason.missing,
        'Kein Inhaltspaket installiert ($manifestAsset fehlt)',
      );
    }
    final String manifestText;
    try {
      manifestText = utf8.decode(manifestBytes);
    } on FormatException {
      throw const ContentUnavailable(
        ContentUnavailableReason.corrupt,
        'Manifest ist kein UTF-8',
      );
    }
    final manifest = ContentManifest.parse(manifestText, lang: lang);
    final bytes = await loadAsset(databaseAsset);
    if (bytes == null) {
      throw ContentUnavailable(
        ContentUnavailableReason.missing,
        'Kein Inhaltspaket installiert ($databaseAsset fehlt)',
      );
    }
    if (bytes.length != manifest.sizeBytes ||
        sha256.convert(bytes).toString() != manifest.sha256) {
      throw const ContentUnavailable(
        ContentUnavailableReason.corrupt,
        'Inhaltspaket passt nicht zur Prüfsumme im Manifest',
      );
    }
    if(pinned!=null && pinned.sha256!=manifest.sha256) {
      throw const ContentUnavailable(ContentUnavailableReason.corrupt,'Bootstrap beschädigt; vorhandene Historie erfordert eine kompatible Reparatur.');
    }
    final target = journal.bootstrapFile(manifest);
    if (!await _matches(target, manifest.sha256)) {
      await target.parent.create(recursive: true);
      final tmp = File('${target.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      // Validate the candidate before replacing a previously usable pack.
      final candidate = await ContentDatabase.openInBackground(tmp, lang: lang);
      try {
        if (candidate.info.version != manifest.version ||
            candidate.info.schemaVersion != manifest.schemaVersion) {
          throw const ContentUnavailable(
            ContentUnavailableReason.incompatible,
            'Version/Schema passt nicht zum Manifest',
          );
        }
      } finally {
        await candidate.close();
      }
      await tmp.rename(target.path);
    }
    await journal.write('active',{'bootstrap':true,'generation':0,'manifest':jsonDecode(manifest.toJson())});
    return (file: target, manifest: manifest);
  }

  /// Hashes off the UI isolate: the pack is tens of megabytes.
  static Future<bool> _matches(File file, String sha) async {
    if (!await file.exists()) return false;
    final path = file.path;
    return await Isolate.run(
          () async => (await sha256.bind(File(path).openRead()).first).toString(),
        ) ==
        sha;
  }

  /// Installs and opens the pack read-only. The release row must name the
  /// manifest version.
  Future<DriftContentRepository> open({
    String? expectedFingerprint,
    ReadCancellation? cancellation,
    bool Function()? isCurrent,
  }) async {
    final registry = validationRegistry;
    if (registry == null) return DriftContentRepository(await _openLegacyDatabase());
    final cancel = cancellation ?? ReadCancellation();
    final current = isCurrent ?? () => true;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final bound = await openRecoveredContent(
          ContentInstallJournal(supportDirectory, lang), registry,
          expectedFingerprint: expectedFingerprint,
          cancellation: cancel, isCurrent: current,
        );
        if (bound != null) return DriftContentRepository(ContentDatabase.fromBoundReader(bound));
        final reservation = registry.reserveExternalReader();
        ContentDatabase? db;
        try {
          db = await _openLegacyDatabase(reservation: reservation);
          if (cancel.isCancelled || !current()) throw StateError('Inhaltsöffnung abgebrochen.');
          if (expectedFingerprint != null && (await routingIdentity()).fingerprint != expectedFingerprint) {
            throw const RecoveredGenerationChanged();
          }
          if (cancel.isCancelled || !current()) throw StateError('Inhaltsöffnung abgebrochen.');
          return DriftContentRepository(db);
        } catch (_) {
          await db?.close();
          await reservation.closeAfter(() async {});
          rethrow;
        }
      } on RecoveredGenerationChanged {
        // Product owners must re-resolve their key outside this installer.
        if (expectedFingerprint != null || attempt == 1 || cancel.isCancelled || !current()) rethrow;
      }
    }
    throw StateError('Inhaltsgeneration wiederholt geändert.');
  }

  Future<ContentDatabase> _openLegacyDatabase({ReaderReservation? reservation}) async {
    final installed = await install();
    final db = await ContentDatabase.openInBackground(installed.file, lang: lang);
    if (reservation != null) db.bindExternalReservation(reservation);
    if (db.info.version != installed.manifest.version ||
        db.info.schemaVersion != installed.manifest.schemaVersion) {
      await db.close();
      throw ContentUnavailable(
        ContentUnavailableReason.incompatible,
        'Version ${db.info.version} im Paket, ${installed.manifest.version} '
        'im Manifest',
      );
    }
    return db;
  }
}
