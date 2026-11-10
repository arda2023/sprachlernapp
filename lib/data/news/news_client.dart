import 'dart:convert';
import 'dart:io';

import '../http/platform_http_client.dart';

import 'package:path_provider/path_provider.dart';

import '../../models/news_models.dart';

/// Reads the daily news (`latest_news`, user decision 01.11.2026) with the
/// public key: news are free and need no account. The last good answer per
/// language stays on disk, so the section is filled offline too.
class NewsClient {
  NewsClient(
    this.projectUri,
    this.publicKey, {
    Future<Directory> Function()? directory,
    HttpClient Function()? createClient,
  }) : _directory = directory ?? getApplicationSupportDirectory,
       _createClient = createClient ?? createPlatformHttpClient;

  final Uri? projectUri;
  final String publicKey;
  final Future<Directory> Function() _directory;
  final HttpClient Function() _createClient;

  static const _maxBytes = 2 * 1024 * 1024;

  bool get configured => projectUri != null && publicKey.isNotEmpty;

  /// The server's newest articles, else the saved ones, else none.
  Future<List<NewsArticle>> latest(String lang) async {
    if (configured) {
      try {
        final body = await _fetch(lang);
        final articles = parse(body, lang);
        await _save(lang, body);
        return articles;
      } catch (_) {
        // Offline or server trouble: fall back to the saved edition.
      }
    }
    final saved = await _saved(lang);
    if (saved == null) return const [];
    try {
      return parse(saved, lang);
    } on FormatException {
      return const [];
    }
  }

  /// Malformed single articles are skipped; a malformed list throws.
  static List<NewsArticle> parse(String body, String lang) {
    final value = jsonDecode(body);
    if (value is! List) throw const FormatException('Nachrichten');
    return [
      for (final item in value)
        if (item is Map<String, dynamic>) ?_article(item, lang),
    ];
  }

  static NewsArticle? _article(Map<String, dynamic> json, String lang) {
    try {
      return NewsArticle.fromJson(json, lang);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<String> _fetch(String lang) async {
    final client = _createClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client
          .postUrl(projectUri!.resolve('/rest/v1/rpc/latest_news'))
          .timeout(const Duration(seconds: 15));
      request.followRedirects = false;
      request.headers.set('apikey', publicKey);
      request.headers.set('Authorization', 'Bearer $publicKey');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'p_lang': lang}));
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode != 200) {
        throw HttpException('Nachrichten: ${response.statusCode}');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        if (bytes.length + chunk.length > _maxBytes) {
          throw const FormatException('Nachrichten zu groß.');
        }
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes);
    } finally {
      client.close(force: true);
    }
  }

  Future<File?> _file(String lang) async {
    try {
      final dir = await _directory();
      return File('${dir.path}/news/$lang.json');
    } catch (_) {
      return null;
    }
  }

  Future<void> _save(String lang, String body) async {
    final file = await _file(lang);
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(body, flush: true);
    } on FileSystemException {
      // Not saved: the next start fetches again.
    }
  }

  Future<String?> _saved(String lang) async {
    final file = await _file(lang);
    try {
      return file != null && await file.exists()
          ? await file.readAsString()
          : null;
    } on FileSystemException {
      return null;
    }
  }
}
