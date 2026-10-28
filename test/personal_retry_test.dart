import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:sprachapp/data/personal_learning_client.dart';
import 'package:sprachapp/data/learning/personal_learning_service.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/personal_learning.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/presentation/providers/personal_learning_provider.dart';
import 'package:sprachapp/widgets/personal_learning_button.dart';

import 'data/support.dart';
import 'personal_learning_test.dart' show target;
import 'personal_learning_flow_test.dart' show WidgetConsentStore;

class RetryService extends PersonalLearningService {
  RetryService({
    required super.content,
    required super.user,
    required super.client,
  }) : super(verify: () {});
  int calls = 0;
  final done = Completer<StoryAddResult>();
  @override
  Future<StoryAddResult?> saved(PersonalTarget t) async => null;
  @override
  Future<StoryAddResult> add(PersonalTarget t) async {
    calls++;
    if (calls == 1) {
      throw const PersonalLearningFailure(
        'Fehlgeschlagen (ANSWER_LEAK)',
        retryable: true,
      );
    }
    return done.future;
  }
}

void main() {
  testWidgets(
    'failed Add enables explicit retry; double tap blocked; no success before save',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('retry-widget');
      addTearDown(() => dir.deleteSync(recursive: true));
      final content = (await tester.runAsync(
        () => fixtureInstaller(dir, Directory('${dir.path}/support')).open(),
      ))!;
      addTearDown(content.close);
      final user = DriftUserRepository(
        UserDatabase(NativeDatabase.memory()),
        lang: 'en',
        contentIds: (_) => content.allCardIds(),
      );
      addTearDown(user.close);
      final client = PersonalLearningClient(
        url: 'https://fixture.invalid',
        publicKey: 'public',
        token: () async => 'fixture',
        owner: () async => 'a',
        revision: () => 0,
        store: WidgetConsentStore()..values['a'] = true,
      );
      addTearDown(client.close);
      final service = RetryService(
        content: content,
        user: user,
        client: client,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            personalLearningClientProvider.overrideWithValue(client),
            personalLearningServiceProvider.overrideWith((_) => service),
          ],
          child: MaterialApp(
            home: Scaffold(body: PersonalLearningButton(target: target())),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.calls, 0);
      await tester.tap(find.text('Zum Lernen hinzufügen'));
      await tester.pumpAndSettle();
      expect(find.text('Erneut versuchen'), findsOneWidget);
      expect(find.text('Hinzugefügt'), findsNothing);
      expect(service.calls, 1);
      await tester.tap(find.text('Erneut versuchen'));
      await tester.tap(find.text('Erneut versuchen'));
      await tester.pump();
      expect(service.calls, 2);
      service.done.complete(const StoryAddResult(StoryAddState.added));
      await tester.pumpAndSettle();
      expect(find.text('Hinzugefügt'), findsOneWidget);
    },
  );
}
