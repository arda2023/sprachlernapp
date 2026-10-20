import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_release_client.dart';
import 'package:sprachapp/data/content/content_update_diagnosis.dart';
import 'package:sprachapp/data/content/content_update_service.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';

const _token = 'synthetic-secret-access-token';

/// Local stand-in for content-release and signed Storage downloads. Only the
/// real [ContentReleaseClient] (dart:io HttpClient) talks to it.
class _Server {
  _Server(this.server, this.files);
  final HttpServer server;
  final Map<String, List<int>> files;
  late Map<String, dynamic> offer;
  int latestStatus = 200, linkStatus = 200, storageStatus = 200;
  String errorBody = '{}';
  bool corrupt = false;
  final paths = <String>[];
  Uri get uri => Uri.parse('http://127.0.0.1:${server.port}');

  static Future<_Server> start(Map<String, List<int>> files) async {
    final s = _Server(
      await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
      files,
    );
    s.server.listen(s._handle);
    return s;
  }

  Future<void> _handle(HttpRequest r) async {
    final path = r.uri.path, id = offer['manifest']['release_id'];
    paths.add('${r.method} $path');
    void fail(int status) {
      r.response.statusCode = status;
      r.response.write(errorBody);
    }

    // Signed Storage URLs carry their own token; functions require the JWT.
    if (path.startsWith('/functions/') &&
        r.headers.value('Authorization') != 'Bearer $_token') {
      fail(401);
    } else if (path == '/functions/v1/content-release') {
      final generation = int.parse(r.uri.queryParameters['generation']!);
      latestStatus != 200
          ? fail(latestStatus)
          : r.response.write(
              jsonEncode({
                'update': generation >= offer['manifest']['generation']
                    ? null
                    : offer,
              }),
            );
    } else if (path == '/functions/v1/content-release/$id/download') {
      linkStatus != 200
          ? fail(linkStatus)
          : r.response.write(
              jsonEncode({
                'manifest_sha256': offer['manifest_sha256'],
                'urls': {
                  for (final n in files.keys)
                    n: '/object/sign/content-private/$id/$n?token=signed-secret',
                },
              }),
            );
    } else if (path.startsWith('/storage/v1/object/sign/content-private/')) {
      if (r.headers.value('Authorization') != null) {
        fail(418);
      } else if (storageStatus != 200) {
        fail(storageStatus);
      } else {
        final bytes = List<int>.of(files[path.split('/').last]!);
        if (corrupt) bytes[100] ^= 1;
        r.response.add(bytes);
      }
    } else {
      fail(404);
    }
    await r.response.close();
  }
}

Map<String, dynamic> _offer(
  Map<String, List<int>> files,
  String id,
  int generation,
) {
  final m = jsonDecode(
    File('test/fixtures/private_release/content.manifest.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  m.remove('local_only');
  m.addAll({
    'release_id': id,
    'channel': 'internal',
    'generation': generation,
    'parent_release_id': null,
    'parent_manifest_sha256': null,
    'sha256': sha256.convert(files['content.sqlite']!).toString(),
    'size_bytes': files['content.sqlite']!.length,
  });
  return {
    'manifest': m,
    'manifest_sha256': contextCanonicalHash(m),
    'objects': {
      for (final e in files.entries)
        e.key: {
          'sha256': sha256.convert(e.value).toString(),
          'size_bytes': e.value.length,
        },
    },
  };
}

void main() {
  late Directory tmp;
  late _Server server;
  late ContentInstallJournal journal;
  late ContentReleaseClient client;
  late ContentUpdateService service;
  var tokenFails = false;

  setUp(() async {
    tokenFails = false;
    tmp = Directory.systemTemp.createTempSync('content-diagnosis-test-');
    final file = File('${tmp.path}/fixture.sqlite');
    final db = sqlite3.open(file.path);
    db.execute(
      File('test/fixtures/private_release/content.sql').readAsStringSync(),
    );
    db.close();
    final files = {
      'content.sqlite': file.readAsBytesSync(),
      'history_inventory.json': File(
        'test/fixtures/private_release/history_inventory.json',
      ).readAsBytesSync(),
    };
    server = await _Server.start(files);
    server.offer = _offer(files, '11111111-1111-4111-8111-111111111111', 1);
    journal = ContentInstallJournal(tmp, 'en');
    client = ContentReleaseClient(server.uri, 'public-anon', () async {
      if (tokenFails) throw StateError('refresh failed');
      return _token;
    });
    service = ContentUpdateService(
      journal,
      client,
      gate: ContentTransitionGate(),
      currentFile: journal.currentFile,
      closeReaders: () async {},
      openReaders: () async {},
    );
  });
  tearDown(() async {
    client.close();
    await server.server.close(force: true);
    tmp.deleteSync(recursive: true);
  });

  void expectSafe(ContentUpdateDiagnosis? d) {
    final text = d!.describe();
    for (final secret in [
      _token,
      'signed-secret',
      'Bearer',
      'token=',
      '127.0.0.1',
      'person@example.com',
      tmp.path,
    ]) {
      expect(text, isNot(contains(secret)));
    }
  }

  test(
    'real HTTP client downloads, verifies in an isolate and activates',
    () async {
      // Regression: the validation isolate closure used to capture the service
      // context (live HttpClient) and failed with "object is unsendable".
      await service.check();
      expect(service.available, isNotNull);
      await service.download();
      expect(service.lastDiagnosis, isNull);
      expect(await journal.read('pending'), isNotNull);
      // Erneut prüfen with a pending candidate re-verifies it, no re-download.
      final downloads = server.paths.where((p) => p.startsWith('POST')).length;
      await service.check();
      expect(server.paths.where((p) => p.startsWith('POST')).length, downloads);
      expect(service.ready?.id, server.offer['manifest']['release_id']);
      await service.activate();
      expect(
        (await journal.active())!.id,
        server.offer['manifest']['release_id'],
      );
    },
  );

  test('server HTTP errors keep status and allowlisted code only', () async {
    server
      ..latestStatus = 403
      ..errorBody = jsonEncode({'code': 'READER_REQUIRED'});
    await expectLater(service.check(), throwsStateError);
    var d = service.lastDiagnosis!;
    expect(
      [d.step, d.httpStatus, d.code],
      ['release_check', 403, 'READER_REQUIRED'],
    );
    expect(
      d.describe(),
      'Schritt: release_check · HTTP 403 · Server: READER_REQUIRED',
    );

    server
      ..latestStatus = 500
      ..errorBody = jsonEncode({
        'code': 'leak person@example.com',
        'message': 'Bearer $_token',
      });
    await expectLater(service.check(), throwsStateError);
    d = service.lastDiagnosis!;
    expect(
      [d.step, d.httpStatus, d.code],
      ['release_check', 500, unknownServerCode],
    );
    expectSafe(d);

    server
      ..latestStatus = 546
      ..errorBody = 'not json';
    await expectLater(service.check(), throwsStateError);
    expect(service.lastDiagnosis!.code, unknownServerCode);
    expect(service.lastDiagnosis!.httpStatus, 546);
  });

  test('download link and storage failures name their step', () async {
    await service.check();
    server
      ..linkStatus = 404
      ..errorBody = jsonEncode({'code': 'NOT_FOUND'});
    await expectLater(service.download(), throwsStateError);
    var d = service.lastDiagnosis!;
    expect([d.step, d.httpStatus, d.code], ['download_link', 404, 'NOT_FOUND']);

    server
      ..linkStatus = 200
      ..storageStatus = 400
      ..errorBody = jsonEncode({
        'statusCode': '400',
        'error': 'InvalidJWT',
        'message': 'signed-secret expired',
      });
    await expectLater(service.download(), throwsStateError);
    d = service.lastDiagnosis!;
    expect(
      [d.step, d.httpStatus, d.code],
      ['download_transfer', 400, 'InvalidJWT'],
    );
    expectSafe(d);
    expect(await journal.read('pending'), isNull);
    expect(
      await journal.generation(server.offer['manifest']['release_id']).exists(),
      isFalse,
    );
  });

  test('local failures have codes without HTTP status', () async {
    tokenFails = true;
    await expectLater(service.check(), throwsStateError);
    var d = service.lastDiagnosis!;
    expect([d.step, d.httpStatus, d.code], ['auth', null, 'AUTH_SESSION']);
    expect(d.describe(), 'Schritt: auth · Lokal: AUTH_SESSION');

    tokenFails = false;
    await service.check();
    server.corrupt = true;
    await expectLater(service.download(), throwsFormatException);
    d = service.lastDiagnosis!;
    expect(
      [d.step, d.httpStatus, d.code],
      ['download_transfer', null, 'FORMAT_INVALID'],
    );
  });

  test(
    'failed newer download keeps active generation and user data bytes',
    () async {
      await service.check();
      await service.download();
      await service.activate();
      final active = await journal.read('active');
      final activeFile = (await journal.currentFile())!;
      final activeBytes = await activeFile.readAsBytes();
      final userDb = File('${tmp.path}/user.db')
        ..writeAsBytesSync(utf8.encode('synthetic learner state'));
      server.offer = _offer(
        server.files,
        '22222222-2222-4222-8222-222222222222',
        2,
      );
      server.corrupt = true;
      await service.check();
      expect(service.available?.generation, 2);
      await expectLater(service.download(), throwsFormatException);
      expect(service.lastDiagnosis!.step, 'download_transfer');
      expect(await journal.read('active'), active);
      expect(await journal.read('pending'), isNull);
      expect(await activeFile.readAsBytes(), activeBytes);
      expect(utf8.decode(userDb.readAsBytesSync()), 'synthetic learner state');
      expect(
        await journal
            .generation('22222222-2222-4222-8222-222222222222')
            .exists(),
        isFalse,
      );
    },
  );
}
