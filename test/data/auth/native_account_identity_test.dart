import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:sprachapp/data/auth/native_account_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GoogleSignInPlatform previousPlatform;
  late _FakeGoogleSignInPlatform platform;

  setUp(() {
    previousPlatform = GoogleSignInPlatform.instance;
    platform = _FakeGoogleSignInPlatform();
    GoogleSignInPlatform.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    GoogleSignInPlatform.instance = previousPlatform;
    debugDefaultTargetPlatformOverride = null;
  });

  test('Google sends a fresh hashed nonce for every iOS attempt', () async {
    final identity = NativeAccountIdentity(
      googleClientId: 'ios-client-id',
      googleServerClientId: 'server-client-id',
    );

    final first = await identity.signIn(AccountIdentityProvider.google);
    final second = await identity.signIn(AccountIdentityProvider.google);

    expect(platform.initializations, hasLength(2));
    expect(platform.authenticationCount, 2);
    expect(first.nonce, isNot(second.nonce));
    expect(first.idToken, 'test-id-token-1');
    expect(second.idToken, 'test-id-token-2');
    expect(
      platform.initializations.map((params) => params.clientId),
      everyElement('ios-client-id'),
    );
    expect(
      platform.initializations.map((params) => params.serverClientId),
      everyElement('server-client-id'),
    );
    expect(platform.initializations.map((params) => params.nonce), [
      sha256.convert(utf8.encode(first.nonce)).toString(),
      sha256.convert(utf8.encode(second.nonce)).toString(),
    ]);
    expect(platform.authenticationNonces, [
      platform.initializations[0].nonce,
      platform.initializations[1].nonce,
    ]);
  });

  test(
    'concurrent Google attempts keep each init and auth pair together',
    () async {
      final identity = NativeAccountIdentity(
        googleClientId: 'ios-client-id',
        googleServerClientId: 'server-client-id',
      );

      final credentials = await Future.wait([
        identity.signIn(AccountIdentityProvider.google),
        identity.signIn(AccountIdentityProvider.google),
      ]);

      expect(credentials[0].nonce, isNot(credentials[1].nonce));
      expect(platform.authenticationNonces, [
        platform.initializations[0].nonce,
        platform.initializations[1].nonce,
      ]);
    },
  );

  test('Google is safely unavailable off iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final identity = NativeAccountIdentity(
      googleClientId: 'ios-client-id',
      googleServerClientId: 'server-client-id',
    );

    await expectLater(
      identity.signIn(AccountIdentityProvider.google),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('noch nicht eingerichtet'),
        ),
      ),
    );
    expect(platform.initializations, isEmpty);
    expect(platform.authenticationCount, 0);
  });

  test('Google cancellation stays a user cancellation', () async {
    platform.cancelNextAuthentication = true;
    final identity = NativeAccountIdentity(
      googleClientId: 'ios-client-id',
      googleServerClientId: 'server-client-id',
    );

    await expectLater(
      identity.signIn(AccountIdentityProvider.google),
      throwsA(isA<AccountLoginCancelled>()),
    );
  });
}

class _FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  final List<InitParameters> initializations = [];
  final List<String?> authenticationNonces = [];
  var authenticationCount = 0;
  var cancelNextAuthentication = false;
  String? _activeNonce;

  @override
  Future<void> init(InitParameters params) async {
    initializations.add(params);
    _activeNonce = params.nonce;
  }

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    authenticationNonces.add(_activeNonce);
    if (cancelNextAuthentication) {
      cancelNextAuthentication = false;
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
    }
    authenticationCount++;
    return AuthenticationResults(
      user: const GoogleSignInUserData(
        email: 'user@example.test',
        id: 'user-id',
      ),
      authenticationTokens: AuthenticationTokenData(
        idToken: 'test-id-token-$authenticationCount',
      ),
    );
  }

  @override
  Future<AuthenticationResults?> attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) async => null;

  @override
  bool supportsAuthenticate() => true;

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<void> signOut(SignOutParams params) async {}

  @override
  Future<void> disconnect(DisconnectParams params) async {}
}
