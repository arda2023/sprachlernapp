import 'package:drift/native.dart';
import 'package:sprachapp/data/learning/personal_learning_service.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';

import 'data/support.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/personal_learning_client.dart';

import 'personal_learning_test.dart' show target, reply;
import 'personal_learning_flow_test.dart' show WidgetConsentStore;
import 'runtime_translation_test.dart' show LoopbackClient;

void main() {
  test('retry ticket only sent on next explicit call; same payload; parallel dedup; no auto retry', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final bodies = <Map<String, dynamic>>[];
    const ticket = '12345678-1234-4234-8234-123456789abc';
    final unblock = Completer<void>();
    server.listen((r) async {
      final b =
          jsonDecode(await utf8.decoder.bind(r).join()) as Map<String, dynamic>;
      bodies.add(b);
      r.response.headers.contentType = ContentType.json;
      if (bodies.length == 1) {
        r.response.statusCode = 409;
        r.response.write(
          jsonEncode({'error': 'REQUEST_UNCERTAIN', 'retry_ticket': ticket}),
        );
      } else {
        await unblock.future;
        r.response.write(jsonEncode(reply(target())));
      }
      await r.response.close();
    });
    final client = PersonalLearningClient(
      url: 'https://synthetic.invalid',
      publicKey: 'public',
      token: () async => 'fixture',
      owner: () async => 'a',
      revision: () => 0,
      store: WidgetConsentStore()..values['a'] = true,
      createClient: () => LoopbackClient(server.port),
    );
    addTearDown(client.close);
    await expectLater(
      client.create(target(), []),
      throwsA(
        isA<PersonalLearningFailure>()
            .having((e) => e.retryTicket, 'ticket', ticket)
            .having((e) => e.retryable, 'retryable', true),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bodies.length, 1);
    final requests = List.generate(8, (_) => client.create(target(), []));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(bodies.length, 2);
    expect(bodies[1].remove('retry_ticket'), ticket);
    expect(bodies[1], bodies[0]);
    unblock.complete();
    await Future.wait(requests);
    await client.create(target(), []);
    expect(bodies.last.containsKey('retry_ticket'), isFalse);
  });

  test('server saved but connection lost: explicit recovery stores one collection card', () async {
    final dir = Directory.systemTemp.createTempSync('retry-lost-response');
    addTearDown(() => dir.deleteSync(recursive: true));
    final content = await fixtureInstaller(
      dir,
      Directory('${dir.path}/support'),
    ).open();
    addTearDown(content.close);
    final user = DriftUserRepository(
      UserDatabase(NativeDatabase.memory()),
      lang: 'en',
      contentIds: (_) => content.allCardIds(),
    );
    addTearDown(user.close);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var modelCalls = 0, requests = 0;
    Map<String, dynamic>? stored;
    server.listen((r) async {
      await utf8.decoder.bind(r).join();
      requests++;
      if (stored == null) {
        modelCalls++;
        stored = reply(target());
        final socket = await r.response.detachSocket(writeHeaders: false);
        socket.destroy();
        return;
      }
      r.response.headers.contentType = ContentType.json;
      r.response.write(jsonEncode(stored));
      await r.response.close();
    });
    final client = PersonalLearningClient(
      url: 'https://synthetic.invalid',
      publicKey: 'public',
      token: () async => 'fixture',
      owner: () async => 'a',
      revision: () => 0,
      store: WidgetConsentStore()..values['a'] = true,
      createClient: () => LoopbackClient(server.port),
    );
    addTearDown(client.close);
    final service = PersonalLearningService(
      content: content,
      user: user,
      client: client,
      verify: () {},
      release: () async => {
        'release_id': '12345678-1234-4234-8234-123456789abc',
        'manifest_sha256': 'a' * 64,
        'sqlite_sha256': 'b' * 64,
      },
    );
    await expectLater(
      service.add(target()),
      throwsA(isA<PersonalLearningFailure>()),
    );
    expect(await user.allCardStates(), isEmpty);
    expect(requests, 1);
    final saved = await service.add(target());
    final again = await service.add(target());
    expect(saved.cardId, again.cardId);
    expect(modelCalls, 1);
    expect(requests, 2);
    expect(await user.allCardStates(), hasLength(1));
    expect(await user.reviewsFor(saved.cardId!), isEmpty);
    final resolver = await PracticeItemResolver.load(user, content);
    expect(resolver.storyCollectionIds, [saved.cardId]);
    expect(await user.localPracticeItems(), hasLength(1));
  });
}
