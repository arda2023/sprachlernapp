// Existing synthetic BR fixture, served through the real installer/update path.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';

class PortugueseTransport implements ContentReleaseTransport {
  PortugueseTransport(Directory work) {
    final file = File('${work.path}/ptbr.sqlite');
    final sql = sqlite3.open(file.path);
    sql.execute(
      File('test/fixtures/portuguese_release/second.sql').readAsStringSync(),
    );
    sql.close();
    files = {
      'content.sqlite': file.readAsBytesSync(),
      'history_inventory.json': File(
        'test/fixtures/portuguese_release/second/history_inventory.json',
      ).readAsBytesSync(),
    };
    final manifest = jsonDecode(
      File('test/fixtures/portuguese_release/second/content.manifest.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    manifest.remove('local_only');
    manifest.addAll({
      'release_id': '11111111-1111-4111-8111-111111111111',
      'generation': 1,
      'channel': 'internal',
      'parent_release_id': null,
      'parent_manifest_sha256': null,
      'sha256': sha256.convert(files['content.sqlite']!).toString(),
      'size_bytes': files['content.sqlite']!.length,
    });
    offer = ReleaseOffer.parse({
      'manifest': manifest,
      'manifest_sha256': contextCanonicalHash(manifest),
      'objects': {
        for (final e in files.entries)
          e.key: {
            'sha256': sha256.convert(e.value).toString(),
            'size_bytes': e.value.length,
          },
      },
    }, 'pt-BR');
  }
  late ReleaseOffer offer;
  late Map<String, List<int>> files;
  final requests = <String>[];
  bool interrupt = false, badHash = false;
  Completer<void>? pending;
  @override
  Future<ReleaseOffer?> latest(String lang, int generation) async {
    requests.add(lang);
    await pending?.future;
    return lang == 'pt-BR' && generation == 0 ? offer : null;
  }

  @override
  Future<Map<String, Uri>> downloads(ReleaseOffer offer) async => {
    for (final key in files.keys)
      key: Uri.parse('https://synthetic.invalid/$key'),
  };
  @override
  Stream<List<int>> bytes(Uri uri) async* {
    final bytes = files[uri.path.substring(1)]!;
    if (interrupt) {
      yield bytes.sublist(0, 100);
      throw const SocketException('synthetic interruption');
    }
    yield badHash ? [0, ...bytes.skip(1)] : bytes;
  }
}
