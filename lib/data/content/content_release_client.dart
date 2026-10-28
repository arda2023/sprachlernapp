import 'dart:convert';
import 'dart:io';

import '../../domain/language_profile.dart';
import 'context_revision_validation.dart';
import 'content_database.dart';
import 'content_update_diagnosis.dart';

const maxContentDownloadBytes = 256 * 1024 * 1024;

class ReleaseOffer {
  ReleaseOffer(this.manifest, this.manifestHash, this.objects);
  final Map<String, dynamic> manifest, objects;
  final String manifestHash;
  String get lang => manifest['lang'] as String;
  String get id => manifest['release_id'] as String;
  int get generation => manifest['generation'] as int;
  bool get isBundled => manifest['origin'] == 'bundle';
  int get cloudGeneration =>
      isBundled ? manifest['cloud_generation'] as int : generation;
  String? get cloudManifestHash =>
      isBundled ? manifest['cloud_manifest_sha256'] as String? : manifestHash;
  String get sha => manifest['sha256'] as String;
  int get size => manifest['size_bytes'] as int;
  ContentManifest get contentManifest => ContentManifest(
    lang: lang,
    version: manifest['version'],
    schemaVersion: manifest['schema_version'],
    sha256: sha,
    sizeBytes: size,
    internalTestPack: true,
    notes: manifest['notes'],
  );

  factory ReleaseOffer.parse(
    Map<String, dynamic> value,
    String lang, {
    ContentLanguageProfile? profile,
    bool allowBundled = false,
  }) {
    final m = value['manifest'];
    final expected = profile;
    void check(bool valid, String message) {
      if (!valid) throw FormatException(message);
    }

    check(
      m is Map<String, dynamic> && value['objects'] is Map<String, dynamic>,
      'Unvollständiges Versionsangebot.',
    );
    final data = m as Map<String, dynamic>;
    check(
      value['manifest_sha256'] == contextCanonicalHash(data),
      'Manifest-Prüfsumme stimmt nicht.',
    );
    check(
      data['format'] == 2 &&
          data['lang'] == lang &&
          data['translation_lang'] == 'de' &&
          data['channel'] == 'internal' &&
          data['internal_test_pack'] == true,
      'Falscher Sprach- oder Freigabebereich.',
    );
    final bundled = data['origin'] == 'bundle';
    check(
      bundled
          ? allowBundled &&
                data['cloud_generation'] is int &&
                data['cloud_generation'] >= 0 &&
                (data['cloud_generation'] == 0
                    ? data['cloud_manifest_sha256'] == null
                    : data['cloud_manifest_sha256'] is String &&
                          RegExp(r'^[0-9a-f]{64}$')
                              .hasMatch(data['cloud_manifest_sha256']))
          : !data.containsKey('origin') &&
                !data.containsKey('cloud_generation') &&
                !data.containsKey('cloud_manifest_sha256'),
      'Inhaltsherkunft oder Cloudcursor nicht unterstützt.',
    );
    check(
      data['schema_version'] == 5 &&
          data['min_reader_version'] is int &&
          data['min_reader_version'] <= 5,
      'App-Aktualisierung erforderlich: Inhaltsschema nicht unterstützt.',
    );
    check(
      expected != null
          ? expected.lang == lang &&
                data['profile_id'] == expected.id &&
                data['profile_sha256'] == expected.sha256
          : ContentLanguageProfile.resolve(
                  lang,
                  data['profile_id'],
                  data['profile_sha256'],
                ) !=
                null,
      'App-Aktualisierung erforderlich: Sprachprofil nicht unterstützt.',
    );
    check(
      data['required_features'] is List &&
          (data['required_features'] as List).length == 1 &&
          data['required_features'][0] == 'immutable-contexts-v1',
      'App-Aktualisierung erforderlich: Inhaltsfähigkeit nicht unterstützt.',
    );
    check(
      data['generation'] is int &&
          data['generation'] > 0 &&
          data['size_bytes'] is int &&
          data['size_bytes'] > 0 &&
          data['size_bytes'] <= maxContentDownloadBytes,
      'Ungültige Generation oder Paketgröße.',
    );
    check(
      data['release_id'] is String &&
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
          ).hasMatch(data['release_id']),
      'Ungültige Versionsreferenz.',
    );
    for (final key in [
      'sha256',
      'pack_json_sha256',
      'registry_sha256',
      'history_inventory_sha256',
      'editorial_reviews_sha256',
    ]) {
      check(
        data[key] is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(data[key]),
        'Ungültige Prüfsumme.',
      );
    }
    final objects = value['objects'] as Map<String, dynamic>;
    for (final key in ['content.sqlite', 'history_inventory.json']) {
      final d = objects[key];
      check(
        d is Map &&
            d['sha256'] is String &&
            RegExp(r'^[0-9a-f]{64}$').hasMatch(d['sha256']) &&
            d['size_bytes'] is int &&
            d['size_bytes'] > 0 &&
            d['size_bytes'] <= maxContentDownloadBytes,
        'Unvollständiger Dateivertrag.',
      );
    }
    check(
      objects['content.sqlite']['sha256'] == data['sha256'] &&
          objects['content.sqlite']['size_bytes'] == data['size_bytes'],
      'Paketvertrag widersprüchlich.',
    );
    return ReleaseOffer(
      Map.unmodifiable(data),
      value['manifest_sha256'],
      Map.unmodifiable(objects),
    );
  }
  Map<String, dynamic> toJson() => {
    'manifest': manifest,
    'manifest_sha256': manifestHash,
    'objects': objects,
  };
}

abstract interface class ContentReleaseTransport {
  Future<ReleaseOffer?> latest(String lang, int generation);
  Future<Map<String, Uri>> downloads(ReleaseOffer offer);
  Stream<List<int>> bytes(Uri uri);
}

class ContentReleaseClient implements ContentReleaseTransport {
  ContentReleaseClient(
    this.projectUri,
    this.publicKey,
    this.accessToken, {
    HttpClient? client,
  }) : _client = client ?? HttpClient() {
    if (projectUri.scheme != 'https' &&
        !(projectUri.scheme == 'http' &&
            ['127.0.0.1', 'localhost'].contains(projectUri.host))) {
      throw ArgumentError('Private Inhaltsupdates benötigen HTTPS.');
    }
    _client.connectionTimeout = const Duration(seconds: 20);
  }
  final Uri projectUri;
  final String publicKey;
  final Future<String> Function() accessToken;
  final HttpClient _client;
  Future<Map<String, dynamic>> _json(String path, {bool post = false}) async {
    final String token;
    try {
      token = await accessToken();
    } catch (_) {
      throw ContentAuthSessionException();
    }
    final request = await _client.openUrl(
      post ? 'POST' : 'GET',
      projectUri.resolve(path),
    );
    request.followRedirects = false;
    request.headers.set('apikey', publicKey);
    request.headers.set('Authorization', 'Bearer $token');
    if (post) {
      request.headers.contentType = ContentType.json;
      request.write('{}');
    }
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw ContentHttpException(
        response.statusCode == 401 || response.statusCode == 403
            ? 'Anmeldung oder Freigabe erforderlich.'
            : 'Inhaltsserver nicht verfügbar.',
        response.statusCode,
        await _errorCode(response),
      );
    }
    final chunks = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 30))) {
      if (chunks.length + chunk.length > 4 * 1024 * 1024) {
        throw const FormatException('Serverantwort zu groß.');
      }
      chunks.addAll(chunk);
    }
    return jsonDecode(utf8.decode(chunks)) as Map<String, dynamic>;
  }

  @override
  Future<ReleaseOffer?> latest(String lang, int generation) async {
    final response = await _json(
      '/functions/v1/content-release?lang=${Uri.encodeQueryComponent(lang)}&channel=internal&generation=$generation',
    );
    return response['update'] == null
        ? null
        : ReleaseOffer.parse(response['update'], lang);
  }

  @override
  Future<Map<String, Uri>> downloads(ReleaseOffer offer) async {
    final response = await _json(
      '/functions/v1/content-release/${offer.id}/download',
      post: true,
    );
    if (response['manifest_sha256'] != offer.manifestHash) {
      throw const FormatException('Versionsangebot wurde verändert.');
    }
    final result = <String, Uri>{};
    for (final name in ['content.sqlite', 'history_inventory.json']) {
      final path = (response['urls'] as Map)[name] as String;
      final relative = Uri.parse(path);
      if (relative.hasAuthority ||
          relative.hasScheme ||
          !relative.path.startsWith(
            '/object/sign/content-private/${offer.id}/',
          )) {
        throw const FormatException('Unerwartetes Downloadziel.');
      }
      result[name] = projectUri.resolve('/storage/v1$path');
    }
    return result;
  }

  @override
  Stream<List<int>> bytes(Uri uri) async* {
    if (uri.origin != projectUri.origin) {
      throw const FormatException('Download außerhalb des Inhaltsservers.');
    }
    final request = await _client.getUrl(uri);
    request.followRedirects = false;
    final response = await request.close().timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw ContentHttpException(
        'Download abgebrochen oder Berechtigung abgelaufen.',
        response.statusCode,
        await _errorCode(response),
      );
    }
    yield* response.timeout(const Duration(seconds: 30));
  }

  /// Reads at most 4 KiB of an error body and keeps only its `code`/`error`
  /// identifier; the caller maps it against [allowedServerCodes].
  static Future<String?> _errorCode(HttpClientResponse response) async {
    final chunks = <int>[];
    try {
      await for (final chunk in response.timeout(const Duration(seconds: 5))) {
        if (chunks.length + chunk.length > 4096) return null;
        chunks.addAll(chunk);
      }
      final body = jsonDecode(utf8.decode(chunks));
      final code = body is Map ? body['code'] ?? body['error'] : null;
      return code is String ? code : null;
    } catch (_) {
      return null;
    }
  }

  void close() => _client.close(force: true);
}
