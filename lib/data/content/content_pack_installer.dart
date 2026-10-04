import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/content.dart';
import 'content_database.dart';
import 'drift_content_repository.dart';

/// Loads a bundled asset by key; null when the asset doesn't exist.
typedef AssetLoader = Future<Uint8List?> Function(String key);

/// Installs the bundled content pack (`assets/content/<lang>/content.sqlite`
/// + `content.manifest.json`, staged by tool/stage_content_pack.dart) into
/// `<support>/content/<lang>/content.sqlite` and opens it read-only.
///
/// The asset must match the manifest checksum. The installed copy is
/// replaced only when its checksum differs (temporary file, then rename);
/// nothing outside `<support>/content/<lang>/` is touched, so user.db
/// survives every install. Close an opened repository before installing
/// again: Windows can't replace a file that is still open.
class ContentPackInstaller {
  ContentPackInstaller({
    required this.loadAsset,
    required this.supportDirectory,
    this.lang = 'en',
  });

  final AssetLoader loadAsset;
  final Directory supportDirectory;
  final String lang;

  String get assetDirectory => 'assets/content/$lang';
  String get manifestAsset => '$assetDirectory/content.manifest.json';
  String get databaseAsset => '$assetDirectory/content.sqlite';

  File get installedFile =>
      File(p.join(supportDirectory.path, 'content', lang, 'content.sqlite'));

  /// The installer of the running app: assets from the bundle, files under
  /// the application support directory.
  static Future<ContentPackInstaller> forApp({String lang = 'en'}) async =>
      ContentPackInstaller(
        loadAsset: _loadBundled,
        supportDirectory: await getApplicationSupportDirectory(),
        lang: lang,
      );

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
    final manifestBytes = await loadAsset(manifestAsset);
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
    final target = installedFile;
    if (!await _matches(target, manifest.sha256)) {
      await target.parent.create(recursive: true);
      final tmp = File('${target.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(target.path);
    }
    return (file: target, manifest: manifest);
  }

  static Future<bool> _matches(File file, String sha) async =>
      await file.exists() &&
      sha256.convert(await file.readAsBytes()).toString() == sha;

  /// Installs and opens the pack read-only. The release row must name the
  /// manifest version.
  Future<DriftContentRepository> open() async {
    final installed = await install();
    final db = ContentDatabase.open(installed.file, lang: lang);
    if (db.info.version != installed.manifest.version) {
      await db.close();
      throw ContentUnavailable(
        ContentUnavailableReason.incompatible,
        'Version ${db.info.version} im Paket, ${installed.manifest.version} '
        'im Manifest',
      );
    }
    return DriftContentRepository(db);
  }
}
