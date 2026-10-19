import 'dart:async';
import 'dart:convert';
import 'dart:io';

bool hasStoredTranslation(String value) =>
    value.trim().isNotEmpty &&
    !{
      'Übersetzung folgt',
      'Übersetzung folgt.',
      'Übersetzung nicht verfügbar',
    }.contains(value.trim());

class RuntimeTranslation {
  const RuntimeTranslation(this.text, this.model, this.requestId);
  final String text, model, requestId;
}

class TranslationFailure implements Exception {
  const TranslationFailure(this.message);
  final String message;
}

class RuntimeTranslationClient {
  RuntimeTranslationClient(
    this.url,
    this.publicKey,
    this.token, {
    HttpClient Function()? createClient,
  }) : _createClient = createClient ?? HttpClient.new;
  final HttpClient Function() _createClient;
  final String url, publicKey;
  final Future<String> Function() token;
  Future<RuntimeTranslation> translate({
    required String lang,
    required String text,
    String? form,
  }) async {
    if (!{'en', 'pt-BR'}.contains(lang) ||
        text.isEmpty ||
        text.length > 600 ||
        text.contains('\n')) {
      throw const TranslationFailure(
        'Dieser Text kann nicht übersetzt werden.',
      );
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || publicKey.isEmpty) {
      throw const TranslationFailure(
        'Übersetzungsserver ist noch nicht eingerichtet.',
      );
    }
    final String access;
    try {
      access = await token().timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const TranslationFailure(
        'Bitte zuerst in den Einstellungen anmelden.',
      );
    }
    final client = _createClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        final request = await client.postUrl(
          uri.resolve(
            '/functions/v1/${form == null ? 'translate-sentence' : 'lookup-word'}',
          ),
        );
        request.followRedirects = false;
        request.headers.set('apikey', publicKey);
        request.headers.set('Authorization', 'Bearer $access');
        request.headers.contentType = ContentType.json;
        request.write(
          jsonEncode({
            'lang': lang,
            'target_lang': 'de',
            if (form == null) 'text': text,
            if (form != null) ...{'form': form, 'sentence': text},
          }),
        );
        final response = await request.close();
        if (response.statusCode != 200) {
          throw TranslationFailure(switch (response.statusCode) {
            401 || 403 => 'Anmeldung oder Sprachfreigabe erforderlich.',
            429 => 'Übersetzungslimit erreicht. Bitte später versuchen.',
            504 => 'Die Übersetzung hat zu lange gedauert.',
            _ => 'Übersetzung derzeit nicht verfügbar.',
          });
        }
        final bytes = <int>[];
        await for (final part in response) {
          bytes.addAll(part);
          if (bytes.length > 16384) {
            throw const TranslationFailure('Ungültige Übersetzungsantwort.');
          }
        }
        final value = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        if (value['provider'] != 'anthropic' ||
            value['model'] != 'claude-haiku-5-5' ||
            value['request_id'] is! String) {
          throw const TranslationFailure('Ungültige Übersetzungsantwort.');
        }
        final String translated;
        if (form == null) {
          translated = value['translation_de'] as String;
        } else {
          final senses = value['senses'] as List;
          if (senses.length != 1 || value['form'] != form) {
            throw const TranslationFailure('Ungültige Übersetzungsantwort.');
          }
          translated = senses.single['gloss_de'] as String;
        }
        if (translated.trim().isEmpty || translated.length > 1200) {
          throw const TranslationFailure('Ungültige Übersetzungsantwort.');
        }
        return RuntimeTranslation(
          translated,
          value['model'] as String,
          value['request_id'] as String,
        );
      })().timeout(const Duration(seconds: 30));
    } on TranslationFailure {
      rethrow;
    } on TimeoutException {
      throw const TranslationFailure('Die Übersetzung hat zu lange gedauert.');
    } catch (_) {
      throw const TranslationFailure(
        'Übersetzung derzeit nicht verfügbar. Bitte Verbindung prüfen.',
      );
    } finally {
      client.close(force: true);
    }
  }
}
