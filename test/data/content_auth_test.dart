import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sprachapp/data/content/content_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
