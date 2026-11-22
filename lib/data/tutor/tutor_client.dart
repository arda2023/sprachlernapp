import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../http/platform_http_client.dart';

import '../../domain/tutor.dart';
import 'tutor_codec.dart';
import '../personal_learning_client.dart';

class TutorFailure implements Exception {
  const TutorFailure(
    this.code,
    this.message, {
    this.status,
    this.uncertain = false,
    this.premiumRequired = false,
  });

  final String code, message;
  final int? status;
  final bool uncertain, premiumRequired;
}

/// Transport only: a suggestion response never creates a learning card.
class TutorClient {
  TutorClient({required this.access, HttpClient Function()? createClient})
    : createClient = createClient ?? createPlatformHttpClient;

  final PersonalLearningClient access;
  final HttpClient Function() createClient;

  Future<List<TutorItem>> generate(TutorGenerationRequest request) async {
    try {
      request.validate();
    } on FormatException {
      throw const TutorFailure(
        'INPUT_INVALID',
        'Die Aufgabenanfrage ist ungültig.',
      );
    }
    try {
      return decodeTutorItems(
        await _send('tutor-generate', request.toJson()),
        request,
      );
    } on FormatException {
      throw const TutorFailure(
        'RESPONSE_INVALID',
        'Die Antwort konnte nicht geprüft werden.',
        uncertain: true,
      );
    }
  }

  Future<TutorGrade> grade({
    required String attemptId,
    required TutorItem item,
    required String answer,
  }) async {
    if (!tutorUuid.hasMatch(attemptId) ||
        !tutorUuid.hasMatch(item.id) ||
        answer.trim().isEmpty ||
        answer.trim().length > 300) {
      throw const TutorFailure(
        'INPUT_INVALID',
        'Bitte eine Antwort mit 1–300 Zeichen eingeben.',
      );
    }
    try {
      return decodeTutorGrade(
        await _send('tutor-grade', {
          'consent': 1,
          'attempt_id': attemptId,
          'item_id': item.id,
          'answer': answer.trim(),
        }),
        item,
      );
    } on FormatException {
      throw const TutorFailure(
        'RESPONSE_INVALID',
        'Die Antwort konnte nicht geprüft werden.',
        uncertain: true,
      );
    }
  }

  Future<Object?> _send(String endpoint, Map<String, Object> body) async {
    final epoch = access.revision(), consentEpoch = access.consentRevision;
    HttpClient? client;
    var sent = false, active = true;
    void verify() {
      if (!active ||
          epoch != access.revision() ||
          consentEpoch != access.consentRevision) {
        throw const TutorFailure(
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
          throw const TutorFailure('AUTH_REQUIRED', 'Bitte zuerst anmelden.');
        }
        Future<void> authorize() async {
          verify();
          final current = await access.owner();
          verify();
          if (current != owner) {
            throw const TutorFailure(
              'ACCESS_CHANGED',
              'Konto oder KI-Freigabe geändert. Bitte erneut öffnen.',
            );
          }
          final allowed = await access.consent();
          verify();
          final after = await access.owner();
          verify();
          if (after != owner) {
            throw const TutorFailure(
              'ACCESS_CHANGED',
              'Konto oder KI-Freigabe geändert. Bitte erneut öffnen.',
            );
          }
          if (!allowed) {
            throw const TutorFailure(
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
          throw const TutorFailure(
            'NOT_CONFIGURED',
            'Der AI-Tutor ist noch nicht eingerichtet.',
          );
        }
        await authorize();
        final token = await access.token();
        await authorize();
        if (token.trim().isEmpty) {
          throw const TutorFailure('AUTH_REQUIRED', 'Bitte zuerst anmelden.');
        }
        final uri = base.resolve('/functions/v1/$endpoint');
        client = createClient()
          ..connectionTimeout = const Duration(seconds: 10);
        await authorize();
        final outgoing = await client!.postUrl(uri);
        outgoing.followRedirects = false;
        await authorize();
        outgoing.headers.set('apikey', access.publicKey);
        outgoing.headers.set('Authorization', 'Bearer $token');
        outgoing.headers.contentType = ContentType.json;
        outgoing.write(jsonEncode(body));
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
        await authorize();
        return json;
      })().timeout(const Duration(seconds: 120));
    } on TutorFailure {
      rethrow;
    } on TimeoutException {
      throw TutorFailure(
        'TIMEOUT',
        'Die Anfrage hat zu lange gedauert. Bitte erneut versuchen.',
        uncertain: sent,
      );
    } on SocketException {
      throw TutorFailure(
        'NETWORK_UNAVAILABLE',
        'Keine Verbindung. Bitte später erneut versuchen.',
        uncertain: sent,
      );
    } on FormatException {
      throw TutorFailure(
        'RESPONSE_INVALID',
        'Die Antwort konnte nicht geprüft werden. Bitte erneut versuchen.',
        uncertain: sent,
      );
    } catch (_) {
      throw TutorFailure(
        'SERVICE_UNAVAILABLE',
        'Der AI-Tutor ist derzeit nicht verfügbar.',
        uncertain: sent,
      );
    } finally {
      active = false;
      client?.close(force: true);
    }
  }
}

TutorFailure _serverFailure(int status, Object? json) {
  const codes = {
    'AUTH_REQUIRED',
    'ACCOUNT_UNVERIFIED',
    'CONSENT_REQUIRED',
    'TUTOR_DAILY_LIMIT',
    'AI_MONTHLY_LIMIT',
    'AI_BUDGET_UNAVAILABLE',
    'MODEL_INVALID',
    'MODEL_FAILED',
    'CONFLICT',
    'REQUEST_CONFLICT',
    'REQUEST_PENDING',
    'REQUEST_UNCERTAIN',
    'RATE_LIMIT',
    'INPUT_INVALID',
    'NOT_CONFIGURED',
    'STORAGE_UNAVAILABLE',
    'TIMEOUT',
    'SERVICE_UNAVAILABLE',
  };
  final raw = json is Map ? json['error'] : null;
  final code = raw is String && codes.contains(raw)
      ? raw
      : status == 401
      ? 'AUTH_REQUIRED'
      : 'SERVICE_UNAVAILABLE';
  return TutorFailure(
    code,
    switch (code) {
      'AUTH_REQUIRED' => 'Bitte zuerst anmelden.',
      'ACCOUNT_UNVERIFIED' => 'Bitte zuerst die E-Mail-Adresse bestätigen.',
      'CONSENT_REQUIRED' => 'Bitte die KI-Verarbeitung zuerst freigeben.',
      'TUTOR_DAILY_LIMIT' => 'Das Tageskontingent ist erreicht.',
      'AI_MONTHLY_LIMIT' => 'Das monatliche KI-Limit ist erreicht. Ab dem nächsten Monat geht es weiter.',
      'CONFLICT' ||
      'REQUEST_CONFLICT' => 'Diese Anfrage gehört zu einer anderen Eingabe.',
      'MODEL_INVALID' => 'Die Antwort konnte nicht geprüft werden.',
      _ => 'Der AI-Tutor ist derzeit nicht verfügbar.',
    },
    status: status,
    premiumRequired:
        code == 'TUTOR_DAILY_LIMIT' &&
        json is Map &&
        json['premium_required'] == true,
    uncertain: {
      'TIMEOUT',
      'SERVICE_UNAVAILABLE',
      'REQUEST_PENDING',
      'REQUEST_UNCERTAIN',
      'STORAGE_UNAVAILABLE',
    }.contains(code),
  );
}
