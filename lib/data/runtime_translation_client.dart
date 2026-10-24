import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'translation_request.dart';
export 'translation_request.dart';

bool hasStoredTranslation(String value) =>
    value.trim().isNotEmpty &&
    !{
      'Übersetzung folgt',
      'Übersetzung folgt.',
      'Übersetzung nicht verfügbar',
    }.contains(value.trim());

enum WordCloudConsent { unknown, enabled, disabled }

class RuntimeTranslationClient {
  RuntimeTranslationClient(
    this.url,
    this.publicKey,
    this.token, {
    HttpClient Function()? createClient,
    this.identityRevision,
  }) : _createClient = createClient ?? HttpClient.new;
  final HttpClient Function() _createClient;
  final int Function()? identityRevision;
  final String url, publicKey;
  final Future<String> Function() token;
  Stream<void> get changes => const Stream.empty();
  Future<RuntimeTranslation?> cached({
    required String lang,
    required String text,
    String? form,
    int? start,
    String? senseRef,
    String? formRef,
  }) async => null;
  Future<WordCloudConsent> wordCloudConsent() async => WordCloudConsent.unknown;
  Future<void> setWordCloudConsent(bool enabled) async {
    throw const TranslationFailure(
      'Bitte zuerst in den Einstellungen anmelden.',
    );
  }

  Future<RuntimeTranslation> translateWordOnTap({
    required String lang,
    required String text,
    required String form,
    int? start,
    String? senseRef,
    String? formRef,
  }) async {
    throw const TranslationFailure(
      'Automatische Cloudübersetzung ist ausgeschaltet.',
    );
  }

  Future<void> clearSaved() async {
    await _send('translate-sentence', method: 'DELETE');
  }

  Future<RuntimeTranslation> translate({
    required String lang,
    required String text,
    String? form,
    int? start,
    String? senseRef,
    String? formRef,
    Future<void> Function()? authorize,
  }) async {
    final TranslationRequest input;
    try {
      input = TranslationRequest(
        lang: lang,
        text: text,
        form: form,
        start: start,
        senseRef: senseRef,
        formRef: formRef,
      );
    } catch (_) {
      throw const TranslationFailure(
        'Dieser Text kann nicht übersetzt werden.',
      );
    }
    final value = await _send(
      input.kind,
      body: input.body,
      authorize: authorize,
    );
    try {
      return RuntimeTranslation.parse(value, input);
    } catch (_) {
      throw const TranslationFailure('Ungültige Übersetzungsantwort.');
    }
  }

  Future<Map<String, dynamic>> _send(
    String path, {
    String method = 'POST',
    Map<String, dynamic>? body,
    Future<void> Function()? authorize,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || publicKey.isEmpty) {
      throw const TranslationFailure(
        'Übersetzungsserver ist noch nicht eingerichtet.',
      );
    }
    await authorize?.call();
    final identity = identityRevision?.call();
    final String access;
    try {
      access = await token().timeout(const Duration(seconds: 30));
    } catch (_) {
      throw const TranslationFailure(
        'Anmeldung konnte nicht bestätigt werden. Bitte Anmeldung und Verbindung prüfen.',
      );
    }
    if (identity != identityRevision?.call()) {
      throw const TranslationFailure('Konto geändert. Bitte erneut öffnen.');
    }
    await authorize?.call();
    final client = _createClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      return await (() async {
        final target = uri.resolve('/functions/v1/$path');
        final request = method == 'POST'
            ? await client.postUrl(target)
            : await client.deleteUrl(target);
        request.followRedirects = false;
        request.headers.set('apikey', publicKey);
        request.headers.set('Authorization', 'Bearer $access');
        request.headers.contentType = ContentType.json;
        await authorize?.call();
        if (body != null) request.write(jsonEncode(body));
        final response = await request.close();
        if (response.statusCode != 200) {
          throw TranslationFailure(switch (response.statusCode) {
            401 || 403 => 'Anmeldung oder Sprachfreigabe erforderlich.',
            409 => 'Diese Anfrage läuft bereits oder ihr Ausgang ist unklar. Es wird nicht automatisch erneut übersetzt. Bitte später versuchen.',
            429 => 'Übersetzungslimit erreicht. Bitte später versuchen.',
            504 => 'Die Übersetzung hat zu lange gedauert. Keine automatische Wiederholung.',
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
        return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      })().timeout(const Duration(seconds: 30));
    } on TranslationFailure {
      rethrow;
    } on TimeoutException {
      throw const TranslationFailure(
        'Die Übersetzung hat zu lange gedauert. Keine automatische Wiederholung.',
      );
    } on SocketException {
      throw const TranslationFailure(
        'Offline: Keine passende Übersetzung gespeichert. Für eine neue Übersetzung bitte verbinden.',
      );
    } catch (_) {
      throw const TranslationFailure(
        'Übersetzung derzeit nicht verfügbar. Bitte Verbindung prüfen.',
      );
    } finally {
      client.close(force: true);
    }
  }
}
