import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'http/platform_http_client.dart';

import '../domain/generated_vocabulary.dart';
import 'personal_learning_client.dart';

class GeneratedVocabularyFailure implements Exception {
  const GeneratedVocabularyFailure(
    this.code,
    this.message, {
    this.status,
    this.uncertain = false,
  });

  final String code, message;
  final int? status;
  final bool uncertain;
}

/// Transport only: a suggestion response never creates a learning card.
class GeneratedVocabularyClient {
  GeneratedVocabularyClient({
    required this.access,
    HttpClient Function()? createClient,
  }) : createClient = createClient ?? createPlatformHttpClient;

  final PersonalLearningClient access;
  final HttpClient Function() createClient;

  Future<GeneratedVocabularyResponse> generate(
    GeneratedVocabularyRequest request, {
    bool statusOnly = false,
  }) async {
    final epoch = access.revision(), consentEpoch = access.consentRevision;
    HttpClient? client;
    var sent = false, active = true;
    void verify() {
      if (!active ||
          epoch != access.revision() ||
          consentEpoch != access.consentRevision) {
        throw const GeneratedVocabularyFailure(
          'ACCESS_CHANGED',
          'Konto oder KI-Freigabe geändert. Bitte erneut öffnen.',
        );
      }
    }

    try {
      return await (() async {
        verify();
        final owner = await access.owner();
        verify();
        if (owner == null || owner.isEmpty) {
          throw const GeneratedVocabularyFailure(
            'AUTH_REQUIRED',
            'Bitte zuerst anmelden.',
          );
        }
        Future<void> authorize() async {
          verify();
          final current = await access.owner();
          verify();
          if (current != owner) {
            throw const GeneratedVocabularyFailure(
              'ACCESS_CHANGED',
              'Konto oder KI-Freigabe geändert. Bitte erneut öffnen.',
            );
          }
          final allowed = await access.consent();
          verify();
          final after = await access.owner();
          verify();
          if (after != owner) {
            throw const GeneratedVocabularyFailure(
              'ACCESS_CHANGED',
              'Konto oder KI-Freigabe geändert. Bitte erneut öffnen.',
            );
          }
          if (!allowed) {
            throw const GeneratedVocabularyFailure(
              'CONSENT_REQUIRED',
              'Bitte die KI-Verarbeitung zuerst freigeben.',
            );
          }
        }

        final base = Uri.tryParse(access.url);
        if (base == null ||
            base.scheme != 'https' ||
            base.host.isEmpty ||
            base.userInfo.isNotEmpty ||
            access.publicKey.isEmpty) {
          throw const GeneratedVocabularyFailure(
            'NOT_CONFIGURED',
            'Wortvorschläge sind noch nicht eingerichtet.',
          );
        }
        await authorize();
        final token = await access.token();
        await authorize();
        if (token.trim().isEmpty) {
          throw const GeneratedVocabularyFailure(
            'AUTH_REQUIRED',
            'Bitte zuerst anmelden.',
          );
        }
        final uri = base
            .resolve('/functions/v1/generate-vocabulary')
            .replace(query: statusOnly ? 'status=1' : null);
        client = createClient()
          ..connectionTimeout = const Duration(seconds: 10);
        await authorize();
        final outgoing = await client!.postUrl(uri);
        outgoing.followRedirects = false;
        await authorize();
        outgoing.headers.set('apikey', access.publicKey);
        outgoing.headers.set('Authorization', 'Bearer $token');
        outgoing.headers.contentType = ContentType.json;
        outgoing.write(jsonEncode(request.toJson()));
        await authorize();
        sent = true;
        final incoming = await outgoing.close();
        await authorize();
        if (incoming.contentLength > 300000) {
          throw const FormatException('Response limit');
        }
        final bytes = <int>[];
        final iterator = StreamIterator<List<int>>(incoming);
        try {
          while (true) {
            await authorize();
            final more = await iterator.moveNext();
            await authorize();
            if (!more) break;
            final chunk = iterator.current;
            if (bytes.length + chunk.length > 300000) {
              throw const FormatException('Response limit');
            }
            bytes.addAll(chunk);
          }
        } finally {
          // Cancellation must not hide an account/consent failure.
          unawaited(iterator.cancel().catchError((Object _) {}));
        }
        Object? json;
        try {
          json = jsonDecode(utf8.decode(bytes));
        } on FormatException {
          if (incoming.statusCode != 200) {
            throw _serverFailure(incoming.statusCode, null);
          }
          rethrow;
        }
        await authorize();
        if (incoming.statusCode != 200) {
          throw _serverFailure(incoming.statusCode, json);
        }
        final result = GeneratedVocabularyResponse.fromJson(
          json,
          request: request,
        );
        await authorize();
        return result;
      })().timeout(const Duration(seconds: 120));
    } on GeneratedVocabularyFailure {
      rethrow;
    } on TimeoutException {
      throw GeneratedVocabularyFailure(
        'TIMEOUT',
        'Die Anfrage hat zu lange gedauert. Bitte den Status dieser Anfrage prüfen.',
        uncertain: sent,
      );
    } on SocketException {
      throw GeneratedVocabularyFailure(
        'NETWORK_UNAVAILABLE',
        'Keine Verbindung. Bitte später den Status dieser Anfrage prüfen.',
        uncertain: sent,
      );
    } on FormatException {
      throw GeneratedVocabularyFailure(
        'RESPONSE_INVALID',
        'Die Antwort konnte nicht geprüft werden. Bitte den Status dieser Anfrage prüfen.',
        uncertain: sent,
      );
    } catch (_) {
      throw GeneratedVocabularyFailure(
        'SERVICE_UNAVAILABLE',
        'Wortvorschläge sind derzeit nicht verfügbar.',
        uncertain: sent,
      );
    } finally {
      active = false;
      client?.close(force: true);
    }
  }
}

GeneratedVocabularyFailure _serverFailure(int status, Object? json) {
  const safeCodes = {
    'ACCOUNT_UNVERIFIED',
    'AUTH_REQUIRED',
    'RATE_LIMIT',
    'PREMIUM_REQUIRED',
    'AI_MONTHLY_LIMIT',
    'AI_BUDGET_UNAVAILABLE',
    'TOPIC_NOT_ALLOWED',
    'REQUEST_CONFLICT',
    'REQUEST_PENDING',
    'REQUEST_UNCERTAIN',
    'REQUEST_FAILED',
    'REQUEST_EXPIRED',
    'REQUEST_MISSING',
    'NOT_CONFIGURED',
    'STORAGE_UNAVAILABLE',
    'GENERATION_UNAVAILABLE',
    'GENERATION_INVALID',
    'TOPIC_UNSUITABLE',
    'TIMEOUT',
    'SERVICE_UNAVAILABLE',
    'BODY_INVALID',
    'BODY_LIMIT',
    'JSON_INVALID',
    'INPUT_INVALID',
    'METHOD_NOT_ALLOWED',
  };
  final candidate = json is Map ? json['error'] : null;
  final code = candidate is String && safeCodes.contains(candidate)
      ? candidate
      : 'SERVICE_UNAVAILABLE';
  final message = switch (code) {
    'ACCOUNT_UNVERIFIED' => 'Bitte zuerst die E-Mail-Adresse bestätigen.',
    'AUTH_REQUIRED' => 'Bitte zuerst anmelden.',
    'AI_MONTHLY_LIMIT' => 'Dein monatliches KI-Limit ist erreicht. Neue Anfragen sind ab dem nächsten Monat wieder möglich.',
    'TOPIC_NOT_ALLOWED' => 'Bitte nenne nur ein Vokabelthema, zum Beispiel „Urlaub am Meer“. Fragen und andere Aufgaben sind hier nicht möglich.',
    'PREMIUM_REQUIRED' => 'Eigene Vokabelthemen benötigen Premium.',
    'RATE_LIMIT' => 'Das Tageslimit ist erreicht. Bitte später versuchen.',
    'REQUEST_PENDING' => 'Diese Anfrage wird noch bearbeitet.',
    'REQUEST_UNCERTAIN' || 'TIMEOUT' =>
      'Der Ausgang dieser Anfrage ist unklar. Bitte ihren Status prüfen.',
    'REQUEST_CONFLICT' => 'Diese Anfrage gehört zu einer anderen Eingabe.',
    'REQUEST_FAILED' => 'Diese Anfrage konnte nicht abgeschlossen werden.',
    'REQUEST_EXPIRED' => 'Die gespeicherte Antwort ist abgelaufen.',
    'REQUEST_MISSING' => 'Für diese Anfrage ist keine Antwort gespeichert.',
    'TOPIC_UNSUITABLE' =>
      'Für dieses Thema wurden keine passenden Wörter gefunden.',
    _ => 'Wortvorschläge sind derzeit nicht verfügbar.',
  };
  return GeneratedVocabularyFailure(
    code,
    message,
    status: status,
    uncertain: {
      'REQUEST_UNCERTAIN',
      'REQUEST_PENDING',
      'TIMEOUT',
      'STORAGE_UNAVAILABLE',
      'SERVICE_UNAVAILABLE',
    }.contains(code),
  );
}
