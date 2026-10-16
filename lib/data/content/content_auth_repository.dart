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
  Future<void>? _initializing;
  String get _key => 'sprachapp.content.auth.${Uri.parse(url).host}';
  bool get configured => url.isNotEmpty && publicKey.isNotEmpty;
  bool get signedIn => _client?.auth.currentSession != null;
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
      authOptions: const AuthClientOptions(autoRefreshToken: false),
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

  Future<void> verifyCode(String email, String code) async {
    await initialize();
    if (_client == null) throw StateError('Privater Inhaltsserver fehlt.');
    await _client!.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.email,
    );
    await _persist();
  }

  Future<void> _persist() async {
    final session = _client?.auth.currentSession;
    if (session == null) {
      await _storage.delete(key: _key);
    } else {
      await _storage.write(key: _key, value: jsonEncode(session.toJson()));
    }
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
    await _storage.delete(key: _key);
    await _client?.dispose();
    _client = configured ? _create() : null;
  }

  Future<void> close() async {
    await _client?.dispose();
  }
}
