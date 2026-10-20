import 'dart:async';
import 'dart:io';
import 'dart:isolate';

/// Server codes that may be shown verbatim. Everything else, including any
/// free-text message or body, is reduced to [unknownServerCode].
const allowedServerCodes = {
  // content-release / content-publish DistributionError codes
  'AUTH_REQUIRED',
  'READER_REQUIRED',
  'SCOPE_INVALID',
  'GENERATION_INVALID',
  'CATALOG_INVALID',
  'NOT_FOUND',
  'BACKEND_UNAVAILABLE',
  'CONFLICT',
  'REQUEST_FAILED',
  // Supabase Edge gateway
  'WORKER_LIMIT',
  'WORKER_ERROR',
  'BOOT_ERROR',
  // Supabase Storage signed object download
  'InvalidJWT',
  'InvalidSignature',
  'NoSuchKey',
  'not_found',
};
const unknownServerCode = 'SERVER_UNKNOWN';

/// Non-200 response. Keeps the previous user message; adds only the real
/// status and an allowlisted code, never headers, URLs or the response body.
class ContentHttpException extends StateError {
  ContentHttpException(super.message, this.status, String? code)
    : serverCode = allowedServerCodes.contains(code)
          ? code!
          : unknownServerCode;
  final int status;
  final String serverCode;
}

/// The session token could not be obtained locally (missing or refresh failed).
class ContentAuthSessionException extends StateError {
  ContentAuthSessionException()
    : super('Anmeldung erforderlich oder abgelaufen.');
}

class ContentUpdateDiagnosis {
  const ContentUpdateDiagnosis(
    this.step,
    this.code, {
    this.httpStatus,
    this.osErrorCode,
  });
  final String step, code;
  final int? httpStatus, osErrorCode;

  factory ContentUpdateDiagnosis.from(String step, Object error) {
    if (error is ContentHttpException) {
      return ContentUpdateDiagnosis(
        step,
        error.serverCode,
        httpStatus: error.status,
      );
    }
    if (error is ContentAuthSessionException) {
      return const ContentUpdateDiagnosis('auth', 'AUTH_SESSION');
    }
    if (error is FileSystemException) {
      return ContentUpdateDiagnosis(
        step,
        'FILE_SYSTEM',
        osErrorCode: error.osError?.errorCode,
      );
    }
    final code = switch (error) {
      TlsException() => 'TLS',
      SocketException() => 'NETWORK',
      TimeoutException() => 'TIMEOUT',
      HttpException() => 'HTTP_PROTOCOL',
      RemoteError() => 'ISOLATE_ERROR',
      ArgumentError(:final message)
          when '$message'.contains('isolate message') =>
        'ISOLATE_TRANSFER',
      ArgumentError() => 'ARGUMENT',
      FormatException() => 'FORMAT_INVALID',
      StateError() => 'STATE',
      _ => 'UNEXPECTED',
    };
    return ContentUpdateDiagnosis(step, code);
  }

  /// Safe for UI and logs: fixed identifiers and integers only.
  String describe() => [
    'Schritt: $step',
    if (httpStatus != null) 'HTTP $httpStatus',
    '${httpStatus != null ? 'Server' : 'Lokal'}: $code',
    if (osErrorCode != null) 'OS $osErrorCode',
  ].join(' · ');
}
