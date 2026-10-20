import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sprachapp/data/content/content_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  passwordAuthTests();
  test('secure session is restored offline, logout removes persisted and memory tokens', () async {
    final token =
        '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({'exp': 9999999999})))}.synthetic';
    FlutterSecureStorage.setMockInitialValues({
      'sprachapp.content.auth.synthetic.invalid': jsonEncode({
        'access_token': token,
        'refresh_token': 'synthetic-refresh',
        'token_type': 'bearer',
        'expires_in': 3600,
        'expires_at': 9999999999,
        'user': {
          'id': '11111111-1111-4111-8111-111111111111',
          'aud': 'authenticated',
          'created_at': '2026-10-16T00:00:00Z',
          'app_metadata': {},
          'user_metadata': {},
        },
      }),
    });
    final auth = ContentAuthRepository(
      'https://synthetic.invalid',
      'public-test-key',
    );
    await auth.initialize();
    expect(auth.signedIn, isTrue);
    expect(await auth.accessToken(), token);
    await auth.signOut();
    expect(auth.signedIn, isFalse);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
    await expectLater(auth.accessToken(), throwsStateError);
    await auth.close();
  });
  test('no configured service does not block offline startup; privileged client key rejected', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final offline = ContentAuthRepository('', '');
    await offline.initialize();
    expect(offline.configured, isFalse);
    await offline.close();
    final privileged = ContentAuthRepository(
      'https://synthetic.invalid',
      'sb_secret_forbidden',
    );
    await expectLater(privileged.initialize(), throwsStateError);
    await privileged.close();
    final insecure = ContentAuthRepository('http://external.invalid', 'public');
    await expectLater(insecure.initialize(), throwsStateError);
    await insecure.close();
  });
}

Map<String, dynamic> sessionFixture(int expiresAt) => {
  'access_token':
      '${base64Url.encode(utf8.encode('{}'))}.${base64Url.encode(utf8.encode(jsonEncode({'exp': expiresAt})))}.synthetic',
  'refresh_token': 'synthetic-refresh',
  'token_type': 'bearer',
  'expires_in': 3600,
  'expires_at': expiresAt,
  'user': {
    'id': '11111111-1111-4111-8111-111111111111',
    'aud': 'authenticated',
    'email': 'existing@example.test',
    'created_at': '2026-10-16T00:00:00Z',
    'app_metadata': {},
    'user_metadata': {},
  },
};

void passwordAuthTests() {
  // This suite only connects to its own loopback fake Auth server.
  HttpOverrides.global = null;
  test('password uses Auth response, secure storage, refresh, restart and offline logout', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final calls = <Map<String, dynamic>>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      calls.add({'uri': request.uri.toString(), 'body': body});
      final refresh =
          request.uri.queryParameters['grant_type'] == 'refresh_token';
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(
          sessionFixture(
            refresh
                ? 9999999999
                : DateTime.now().millisecondsSinceEpoch ~/ 1000 + 30,
          ),
        ),
      );
      await request.response.close();
    });
    final url = 'http://127.0.0.1:${server.port}';
    final auth = ContentAuthRepository(url, 'public-test-key');
    addTearDown(() async {
      await auth.close();
      await server.close(force: true);
    });
    await auth.signInWithPassword(
      ' existing@example.test ',
      ' synthetic-password ',
    );
    expect(calls.single['uri'], '/auth/v1/token?grant_type=password');
    expect(calls.single['body']['email'], 'existing@example.test');
    expect(calls.single['body']['password'], ' synthetic-password ');
    expect(auth.signedIn, isTrue);
    expect(
      await auth.accessToken(),
      sessionFixture(9999999999)['access_token'],
    );
    expect(calls.last['body'], {'refresh_token': 'synthetic-refresh'});
    final stored = (await const FlutterSecureStorage().readAll()).values.single;
    expect(stored, isNot(contains('synthetic-password')));
    expect(
      jsonDecode(stored)['user']['id'],
      '11111111-1111-4111-8111-111111111111',
    );
    final restored = ContentAuthRepository(url, 'public-test-key');
    await restored.initialize();
    expect(restored.signedIn, isTrue);
    expect(
      await restored.accessToken(),
      sessionFixture(9999999999)['access_token'],
    );
    await restored.signOut();
    expect(restored.signedIn, isFalse);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
    await restored.close();
    await auth.signOut();
    await expectLater(auth.accessToken(), throwsStateError);
  });

  for (final code in [
    'invalid_credentials',
    'email_not_confirmed',
    'user_banned',
  ]) {
    test(
      'password $code rejects session without persistence or mail request',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        final paths = <String>[];
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((request) async {
          paths.add(request.uri.toString());
          await request.drain<void>();
          request.response.statusCode = 400;
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({'error_code': code, 'msg': 'Synthetic rejection'}),
          );
          await request.response.close();
        });
        final auth = ContentAuthRepository(
          'http://127.0.0.1:${server.port}',
          'public-test-key',
        );
        addTearDown(() async {
          await auth.close();
          await server.close(force: true);
        });
        await expectLater(
          auth.signInWithPassword(
            'existing@example.test',
            'synthetic-password',
          ),
          throwsA(isA<AuthException>().having((e) => e.code, 'code', code)),
        );
        expect(auth.signedIn, isFalse);
        expect(await const FlutterSecureStorage().readAll(), isEmpty);
        expect(paths, ['/auth/v1/token?grant_type=password']);
      },
    );
  }
}
