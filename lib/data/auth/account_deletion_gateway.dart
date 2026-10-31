import 'dart:convert';
import 'dart:io';

import '../content/content_auth_repository.dart';

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => message;
}

class AccountDeletionResult {
  const AccountDeletionResult({required this.appleManualRevocationRequired});
  final bool appleManualRevocationRequired;
}

abstract interface class AccountDeletionGateway {
  Future<AccountDeletionResult> deleteAccount({required String expectedUserId});
}

class SupabaseAccountDeletionGateway implements AccountDeletionGateway {
  SupabaseAccountDeletionGateway(this.auth, {HttpClient? client})
    : _client = client ?? (HttpClient()..connectionTimeout = _requestTimeout);

  static const _requestTimeout = Duration(seconds: 20);
  static const _maximumResponseBytes = 4096;

  final ContentAuthRepository auth;
  final HttpClient _client;

  void close() => _client.close(force: true);

  @override
  Future<AccountDeletionResult> deleteAccount({
    required String expectedUserId,
  }) async {
    final token = await auth.accessToken();
    if (auth.userId != expectedUserId) {
      throw const AccountDeletionException(
        'ACCOUNT_CHANGED',
        'Das angemeldete Konto hat sich geändert. Bitte starte das Löschen für das aktuell angezeigte Konto erneut.',
      );
    }
    final endpoint = Uri.parse(auth.url)
        .resolve('/functions/v1/delete-account');
    final request = await _client.postUrl(endpoint).timeout(_requestTimeout);
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
      ..set('apikey', auth.publicKey)
      ..contentType = ContentType.json;
    request.write(jsonEncode({'confirmation': 'DELETE'}));

    final response = await request.close().timeout(_requestTimeout);
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_requestTimeout);
    if (utf8.encode(body).length > _maximumResponseBytes) {
      throw const FormatException('Ungültige Antwort beim Löschen des Kontos.');
    }

    Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(body);
      if (value is! Map<String, dynamic>) throw const FormatException();
      decoded = value;
    } on FormatException {
      throw const AccountDeletionException(
        'UNKNOWN',
        'Das Konto konnte nicht gelöscht werden. Bitte später erneut versuchen.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final code = decoded['error'] is String
          ? decoded['error'] as String
          : 'UNKNOWN';
      throw AccountDeletionException(code, _messageFor(code));
    }

    if (decoded['deleted'] != true ||
        decoded['apple_manual_revocation_required'] is! bool) {
      throw const FormatException('Ungültige Antwort beim Löschen des Kontos.');
    }
    return AccountDeletionResult(
      appleManualRevocationRequired:
          decoded['apple_manual_revocation_required'] as bool,
    );
  }

  String _messageFor(String code) => switch (code) {
    'RECENT_AUTH_REQUIRED' => 'Bitte melde dich aus Sicherheitsgründen erneut an und starte das Löschen danach innerhalb von fünf Minuten.',
    'PUBLISHER_ACCOUNT_REQUIRES_TRANSFER' => 'Dieses Konto verwaltet veröffentlichte Inhalte. Schreibe an kontakt@linglossa.de, damit die Veröffentlichungsrechte übertragen werden. Danach kannst du das Konto löschen.',
    'BILLING_PROFILE_DELETE_FAILED' => 'Das Abrechnungsprofil konnte nicht sicher gelöscht werden. Dein Konto bleibt bestehen. Bitte später erneut versuchen.',
    'NOT_CONFIGURED' => 'Die Kontolöschung ist auf dem Server noch nicht vollständig eingerichtet. Bitte den Support kontaktieren.',
    'AUTH_REQUIRED' =>
      'Deine Anmeldung ist abgelaufen. Bitte melde dich erneut an.',
    _ =>
      'Das Konto konnte nicht gelöscht werden. Bitte später erneut versuchen.',
  };
}
