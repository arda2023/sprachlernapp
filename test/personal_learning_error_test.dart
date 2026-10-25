import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/personal_learning_client.dart';
import 'personal_learning_test.dart' show target;
import 'runtime_translation_test.dart' show LoopbackClient;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final code in ['MODEL_INVALID', 'private text Bearer secret', 'x' * 2048]) {
    test('failure code allowlist, no success or automatic retry: ${code.length}', () async {
      HttpOverrides.global = null;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var calls = 0;
      server.listen((r) async {
        calls++;
        await r.drain<void>();
        r.response.statusCode = 502;
        r.response.write(jsonEncode({'error':code,'provider_response':'private provider text'}));
        await r.response.close();
      });
      final client = PersonalLearningClient(url:'https://synthetic.invalid',publicKey:'public',token:() async=>'synthetic',owner:() async=>'synthetic',revision:()=>0,
        store:PersonalConsentStore(() async=>sqlite3.openInMemory()),createClient:()=>LoopbackClient(server.port));
      addTearDown(client.close);
      await client.setConsent(true);
      await expectLater(client.create(target(), []),throwsA(isA<PersonalLearningFailure>().having((e)=>e.message,'safe message',allOf(
        contains('Kein Hinzufügen bestätigt'),
        isNot(contains('private')),isNot(contains('secret')),isNot(contains('provider_response')),
        code=='MODEL_INVALID'?contains('(MODEL_INVALID)'):isNot(contains('(')),
      ))));
      expect(calls,1);
    });
  }
}
