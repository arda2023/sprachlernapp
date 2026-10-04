// Test helpers: the synthetic content pack (test/fixtures/content_mini.sql),
// its manifest and an installer that serves them like bundled assets.
// No pipeline/out/, no network.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';

/// Builds the fixture pack as `<dir>/<name>`; [tweak] may change it.
File buildFixturePack(
  Directory dir, {
  void Function(Database db)? tweak,
  String name = 'fixture.sqlite',
}) {
  final file = File('${dir.path}/$name');
  if (file.existsSync()) file.deleteSync();
  final db = sqlite3.open(file.path);
  try {
    db.execute(File('test/fixtures/content_mini.sql').readAsStringSync());
    tweak?.call(db);
  } finally {
    db.close();
  }
  return file;
}

String manifestFor(
  Uint8List bytes, {
  String lang = 'en',
  String version = 'mini-v1',
}) => ContentManifest(
  lang: lang,
  version: version,
  schemaVersion: supportedContentSchemaVersion,
  sha256: sha256.convert(bytes).toString(),
  sizeBytes: bytes.length,
  internalTestPack: true,
  notes: 'INTERNES TEST-PACK: synthetische Fixture',
).toJson();

/// An installer whose "bundle" holds [db] and [manifest] (null = missing).
ContentPackInstaller installerFor(
  Directory support, {
  Uint8List? db,
  String? manifest,
  String lang = 'en',
}) => ContentPackInstaller(
  supportDirectory: support,
  lang: lang,
  loadAsset: (key) async {
    if (key == 'assets/content/$lang/content.sqlite') return db;
    if (key == 'assets/content/$lang/content.manifest.json') {
      return manifest == null
          ? null
          : Uint8List.fromList(utf8.encode(manifest));
    }
    return null;
  },
);

/// Installer for the unchanged fixture with a matching manifest.
ContentPackInstaller fixtureInstaller(Directory work, Directory support) {
  final bytes = buildFixturePack(work).readAsBytesSync();
  return installerFor(support, db: bytes, manifest: manifestFor(bytes));
}

String sha256Of(File file) => sha256.convert(file.readAsBytesSync()).toString();
