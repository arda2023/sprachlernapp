import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/content/content_update_validation.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';

void main() {
  final resultFile = File('build/baseline_adoption/real-result.json');
  test(
    'real baseline offer and downloaded bundle preserve schema-4 history',
    () {
      final result =
          jsonDecode(resultFile.readAsStringSync()) as Map<String, dynamic>;
      expect(result['synthetic_confirmation_only'], isTrue);
      final directory = result['bundle'] as String;
      final file = File('$directory/content.sqlite');
      final asset = File('assets/content/en/content.sqlite');
      final assetHash = sha256.convert(asset.readAsBytesSync()).toString();
      final manifest = Map<String, dynamic>.from(result['manifest']);
      manifest.remove('local_only');
      manifest.addAll({
        'release_id': '11111111-1111-4111-8111-111111111111',
        'channel': 'internal',
        'generation': 1,
        'parent_release_id': null,
        'parent_manifest_sha256': null,
      });
      final offer = ReleaseOffer.parse({
        'manifest': manifest,
        'manifest_sha256': contextCanonicalHash(manifest),
        'objects': result['objects'],
      }, 'en');
      expect(
        offer.manifest['publication_kind'],
        'internal-baseline-adoption-v1',
      );
      expect(sha256.convert(file.readAsBytesSync()).toString(), offer.sha);
      validateDownloadedContent(file.path, offer.toJson(), asset.path);
      expect(sha256.convert(asset.readAsBytesSync()).toString(), assetHash);
      print(
        'Schema-5 adoption manifest and all-table inventory accepted; schema-4 history preserved; asset unchanged.',
      );
    },
    skip: !resultFile.existsSync()
        ? 'Run check_baseline_adoption_real.py first.'
        : false,
  );
}
