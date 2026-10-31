import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_auth_test.dart' show sessionFixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  test('public code signup is separate from invited-only login and verifies a session', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final bodies = <String, List<Map<String, dynamic>>>{};
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      (bodies[request.uri.path] ??= []).add(body);
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(
          request.uri.path.endsWith('/verify')
              ? sessionFixture(9999999999)
              : {},
        ),
      );
      await request.response.close();
    });
    final auth = ContentAuthRepository(
      'http://127.0.0.1:${server.port}',
      'public-test',
    );
    addTearDown(() async {
      await auth.close();
      await server.close(force: true);
    });
    await auth.requestAccountCode(' person@example.test ');
    expect(auth.signedIn, false);
    expect(bodies['/auth/v1/otp']!.single['create_user'], true);
    await auth.requestCode('invited@example.test');
    expect(bodies['/auth/v1/otp']!.last['create_user'], false);
    await auth.verifyCode(' person@example.test ', ' 123456 ');
    expect(auth.signedIn, true);
    expect(auth.userId, '11111111-1111-4111-8111-111111111111');
    expect(bodies['/auth/v1/verify']!.single['token'], '123456');
    final saved = (await const FlutterSecureStorage().readAll()).values.single;
    expect(saved, isNot(contains('123456')));
  });

  for (final provider in [OAuthProvider.apple, OAuthProvider.google]) {
    test(
      '$provider verifies token and nonce before persisting; logout revokes locally',
      () async {
        FlutterSecureStorage.setMockInitialValues({});
        final calls = <String>[];
        Map<String, dynamic>? exchange;
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((request) async {
          calls.add(request.uri.toString());
          if (request.uri.path.endsWith('/logout')) {
            await request.drain<void>();
            expect(
              request.headers.value('authorization'),
              startsWith('Bearer '),
            );
            request.response.statusCode = 204;
          } else {
            exchange = jsonDecode(
              await utf8.decoder.bind(request).join(),
            ) as Map<String, dynamic>;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(sessionFixture(9999999999)));
          }
          await request.response.close();
        });
        final auth = ContentAuthRepository(
          'http://127.0.0.1:${server.port}',
          'public-test',
        );
        addTearDown(() async {
          await auth.close();
          await server.close(force: true);
        });
        await auth.signInWithIdToken(
          provider: provider,
          idToken: 'synthetic-id-token',
          nonce: 'synthetic-raw-nonce',
        );
        expect(exchange!['provider'], provider.name);
        expect(exchange!['id_token'], 'synthetic-id-token');
        expect(exchange!['nonce'], 'synthetic-raw-nonce');
        expect(auth.signedIn, true);
        final saved =
            (await const FlutterSecureStorage().readAll()).values.single;
        expect(saved, isNot(contains('synthetic-id-token')));
        await auth.signOut();
        expect(calls.last, '/auth/v1/logout?scope=local');
        expect(auth.signedIn, false);
        expect(await const FlutterSecureStorage().readAll(), isEmpty);
      },
    );
  }

  test('rejected native proof never creates a local session', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await request.drain<void>();
      request.response.statusCode = 400;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({'error_code': 'bad_jwt', 'msg': 'Invalid ID token'}),
      );
      await request.response.close();
    });
    final auth = ContentAuthRepository(
      'http://127.0.0.1:${server.port}',
      'public-test',
    );
    addTearDown(() async {
      await auth.close();
      await server.close(force: true);
    });
    await expectLater(
      auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: 'rejected',
        nonce: 'wrong',
      ),
      throwsA(isA<AuthException>()),
    );
    expect(auth.signedIn, false);
    expect(auth.localOwner, isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });
}
