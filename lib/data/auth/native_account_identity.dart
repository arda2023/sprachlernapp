import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

enum AccountIdentityProvider { apple, google }

class AccountLoginCancelled implements Exception {
  const AccountLoginCancelled();
}

typedef NativeAccountCredential = ({String idToken, String nonce});

class NativeAccountIdentity {
  NativeAccountIdentity({String? googleClientId, String? googleServerClientId})
    : _googleClientId =
          googleClientId ??
          const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      _googleServerClientId =
          googleServerClientId ??
          const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  static final _random = Random.secure();
  static String _nonce() =>
      base64Url.encode(List<int>.generate(32, (_) => _random.nextInt(256)));
  static String _hash(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  final String _googleClientId;
  final String _googleServerClientId;

  // The platform interface's init call carries the nonce used by the next
  // authenticate call. Keep those calls serialized so parallel attempts cannot
  // replace each other's nonce between initialization and authentication.
  static Future<void> _googleAttemptTail = Future<void>.value();

  Future<NativeAccountCredential> signIn(
    AccountIdentityProvider provider,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw StateError(
        'Diese Anmeldung ist auf dieser Plattform noch nicht eingerichtet.',
      );
    }
    switch (provider) {
      case AccountIdentityProvider.apple:
        final nonce = _nonce();
        try {
          final result = await SignInWithApple.getAppleIDCredential(
            scopes: [AppleIDAuthorizationScopes.email],
            nonce: _hash(nonce),
          );
          final token = result.identityToken;
          if (token == null || token.isEmpty) {
            throw StateError('Apple hat die Anmeldung nicht bestätigt.');
          }
          return (idToken: token, nonce: nonce);
        } on SignInWithAppleAuthorizationException catch (error) {
          if (error.code == AuthorizationErrorCode.canceled) {
            throw const AccountLoginCancelled();
          }
          rethrow;
        }
      case AccountIdentityProvider.google:
        if (_googleClientId.isEmpty || _googleServerClientId.isEmpty) {
          throw StateError('Google-Anmeldung noch nicht eingerichtet.');
        }
        final nonce = _nonce();
        final previousAttempt = _googleAttemptTail;
        final attemptFinished = Completer<void>();
        _googleAttemptTail = attemptFinished.future;
        try {
          await previousAttempt;
          await GoogleSignInPlatform.instance.init(
            InitParameters(
              clientId: _googleClientId,
              serverClientId: _googleServerClientId,
              nonce: _hash(nonce),
            ),
          );
          final result = await GoogleSignInPlatform.instance.authenticate(
            const AuthenticateParameters(),
          );
          final token = result.authenticationTokens.idToken;
          if (token == null || token.isEmpty) {
            throw StateError('Google hat die Anmeldung nicht bestätigt.');
          }
          return (idToken: token, nonce: nonce);
        } on GoogleSignInException catch (error) {
          if (error.code == GoogleSignInExceptionCode.canceled) {
            throw const AccountLoginCancelled();
          }
          rethrow;
        } finally {
          attemptFinished.complete();
        }
    }
  }
}
