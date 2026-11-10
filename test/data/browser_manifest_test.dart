import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/domain/content.dart';

void main() {
  test(
    'legacy browser bundle never probes a missing release on SPA hosting',
    () async {
      final requested = <String>[];
      final installer = ContentPackInstaller(
        supportDirectory: Directory.systemTemp,
        loadAsset: (key) async {
          requested.add(key);
          final file = File(key);
          return await file.exists()
              ? file.readAsBytes()
              : Uint8List.fromList(
                  utf8.encode('<!doctype html><title>Linglossa</title>'),
                );
        },
      );
      final manifest = await installer.browserManifest();
      expect(manifest!.lang, 'en');
      expect(requested, ['assets/content/en/content.manifest.json']);
    },
  );
  for (final language in ['en', 'pt-BR', 'nb', 'it', 'es']) {
    test('browser resolves validated bundled $language manifest', () async {
      final installer = ContentPackInstaller(
        lang: language,
        supportDirectory: Directory.systemTemp,
        loadAsset: (key) async {
          final file = File(key);
          return await file.exists() ? file.readAsBytes() : null;
        },
      );
      final manifest = await installer.browserManifest();
      expect(manifest, isNotNull);
      expect(manifest!.lang, language);
      final bytes = await File(installer.databaseAsset).readAsBytes();
      expect(manifest.sizeBytes, bytes.length);
      expect(manifest.sha256, sha256.convert(bytes).toString());
      if (language != 'en') {
        // The legacy parser remains strict; browser resolution uses the release
        // validator, not relaxed format/profile/security checks.
        expect(
          () => ContentManifest.parse(
            File(installer.manifestAsset).readAsStringSync(),
            lang: language,
          ),
          throwsA(isA<ContentUnavailable>()),
        );
      }
    });
  }
}
