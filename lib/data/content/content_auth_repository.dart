import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth is optional and independent from offline learning. Only the public
/// project key is configured in the app; tokens live in platform secure storage.
class ContentAuthRepository {
  ContentAuthRepository(
    this.url,
    this.publicKey, {
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();
  final String url, publicKey;
  final FlutterSecureStorage _storage;
  SupabaseClient? _client;
  final _identityChanges = StreamController<void>.broadcast(sync: true);
  Stream<void> get identityChanges => _identityChanges.stream;
  int identityRevision = 0;
  String? _lastIdentity;
  String? get localOwner {
    final user = _client?.auth.currentUser;
    return user == null || user.isAnonymous
        ? null
        : '${Uri.parse(url).host}:${user.id}';
  }

  Future<String?> cacheOwner() async {
    await initialize();
    return localOwner;
  }

  void _notifyIdentity() {
    if (_lastIdentity == localOwner) return;
    _lastIdentity = localOwner;
    identityRevision++;
    _identityChanges.add(null);
  }

  Future<void>? _initializing;
  String get _key => 'sprachapp.content.auth.${Uri.parse(url).host}';
  bool get configured => url.isNotEmpty && publicKey.isNotEmpty;
  bool get signedIn => _client?.auth.currentSession != null;
  String? get userId => _client?.auth.currentUser?.id;
  String? get email => _client?.auth.currentUser?.email;
  SupabaseClient _create() {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https' &&
        !(uri.scheme == 'http' &&
            ['localhost', '127.0.0.1'].contains(uri.host))) {
      throw StateError('Privater Inhaltsserver benötigt HTTPS.');
    }
    if (publicKey.startsWith('sb_secret_')) {
      throw StateError('Nur öffentlicher App-Schlüssel erlaubt.');
    }
    if (publicKey.startsWith('ey')) {
      final role = jsonDecode(
        utf8.decode(
          base64Url.decode(base64Url.normalize(publicKey.split('.')[1])),
        ),
      )['role'];
      if (role == 'service_role') {
        throw StateError('Service-Schlüssel im Client nicht erlaubt.');
      }
    }
    return SupabaseClient(
      url,
      publicKey,
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: _AccountProofStorage(),
      ),
    );
  }

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    if (!configured) return;
    _client = _create();
    final saved = await _storage.read(key: _key);
    if (saved != null) {
      try {
        await _client!.auth.setInitialSession(saved);
      } catch (_) {
        await _storage.delete(key: _key);
      }
    }
    _lastIdentity = localOwner;
  }

  Future<void> requestCode(String email) async {
    await initialize();
    if (_client == null) {
      throw StateError('Privater Inhaltsserver noch nicht eingerichtet.');
    }
    await _client!.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: false,
    );
  }

  /// Public passwordless account flow. The invited-content login above keeps
  /// its original no-signup contract; creating an account grants no reader role.
  Future<void> requestAccountCode(String email) async {
    await initialize();
    if (_client == null) throw StateError('Anmeldung noch nicht eingerichtet.');
    await _client!.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
    );
  }

  Future<void> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    required String nonce,
  }) async {
    await initialize();
    if (_client == null) throw StateError('Anmeldung noch nicht eingerichtet.');
    final response = await _client!.auth.signInWithIdToken(
      provider: provider,
      idToken: idToken,
      nonce: nonce,
    );
    if (response.session == null || response.user == null) {
      throw const AuthException('Anmeldung nicht bestätigt.');
    }
    await _persist();
  }

  Future<void> verifyCode(String email, String code) async {
    await initialize();
    if (_client == null) throw StateError('Privater Inhaltsserver fehlt.');
    final response = await _client!.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.email,
    );
    if (response.session == null || response.user == null) {
      throw const AuthException('Anmeldung nicht bestätigt.');
    }
    await _persist();
  }

  Future<void> signInWithPassword(String email, String password) async {
    await initialize();
    if (_client == null) {
      throw StateError('Privater Inhaltsserver noch nicht eingerichtet.');
    }
    if (!email.contains('@') || password.isEmpty) {
      throw const AuthException(
        'E-Mail-Adresse und Passwort angeben.',
        code: 'credentials_required',
      );
    }
    final response = await _client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    if (response.session == null || response.user == null) {
      throw const AuthException('Anmeldung nicht bestätigt.');
    }
    await _persist();
  }

  Future<void> _persist() async {
    final session = _client?.auth.currentSession;
    if (session == null) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(key: _key, value: jsonEncode(session.toJson()));
    }
    _notifyIdentity();
  }

  Future<String> accessToken() async {
    await initialize();
    var session = _client?.auth.currentSession;
    if (session == null) {
      throw StateError('Bitte mit der eingeladenen E-Mail-Adresse anmelden.');
    }
    if ((session.expiresAt ?? 0) <=
        DateTime.now().millisecondsSinceEpoch ~/ 1000 + 60) {
      session = (await _client!.auth.refreshSession()).session;
      await _persist();
    }
    if (session == null) throw StateError('Anmeldung abgelaufen.');
    return session.accessToken;
  }

  Future<void> signOut() async {
    await initialize();
    final previous = _client;
    _client = configured ? _create() : null;
    Object? storageFailure;
    StackTrace? storageFailureStack;
    try {
      await _storage.delete(key: _key);
    } catch (error, stackTrace) {
      storageFailure = error;
      storageFailureStack = stackTrace;
    } finally {
      // Listeners must see the local identity change only after secure storage
      // has been updated (or its failure is known).
      _notifyIdentity();
    }
    try {
      // Revoke this session when reachable. Local logout must still work offline.
      await previous?.auth
          .signOut(scope: SignOutScope.local)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Offline logout cannot promise server revocation; local tokens are gone.
    } finally {
      await previous?.dispose();
    }
    if (storageFailure != null) {
      Error.throwWithStackTrace(storageFailure, storageFailureStack!);
    }
  }

  Future<void> close() async {
    await _client?.dispose();
    await _identityChanges.close();
  }
}

/// Ephemeral PKCE proofs for the SDK's email request. OTP confirmation uses
/// the typed code; no redirect-based token processing is added to this app.
class _AccountProofStorage extends GotrueAsyncStorage {
  final _values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => _values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _values.remove(key);
  }
}
