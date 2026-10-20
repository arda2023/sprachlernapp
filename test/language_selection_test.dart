import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/preferences.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/language_selection_provider.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/providers/preferences_provider.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';

import 'fixtures/language_selection.dart';
import 'fixtures/story_learning.dart';

import 'package:sprachapp/domain/story_learning.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LanguageHarness h;
  late ProviderContainer c;
  setUp(() {
    h = LanguageHarness(
      Directory.systemTemp.createTempSync('language-selection-'),
    );
    c = h.scope();
  });
  tearDown(() async {
    c.dispose();
    await h.close();
  });

  test('en -> absent pt-BR -> restart -> en preserves all personal rows and preferences', () async {
    final user = await c.read(userRepositoryProvider.future);
    await c.read(contentRepositoryProvider.future);
    final now = DateTime(2026, 10, 18);
    await user.ensureCards(['card-went'], now: now, origin: CardOrigin.deck);
    await user.setCardFlags(
      'card-went',
      favorite: true,
      inPlaylist: true,
      note: 'Meine Notiz',
    );
    await user.setDeckActive('deck-allg', false, now: now);
    await user.savePreferences(
      const PracticePreferences(includeDiacritics: false, dailyGoal: 17),
    );
    await user.recordReview(
      ReviewRecord(
        id: 'en-review',
        cardId: 'card-went',
        createdAt: now,
        mode: ReviewMode.deck,
        sentenceId: 'historical-en',
        firstAttemptCorrect: true,
        errorCount: 0,
        revealed: false,
        hintUsed: false,
        boxBefore: 0,
        boxAfter: 3,
        dueAtAfter: now.add(const Duration(days: 7)),
        responseMs: 12,
        appVersion: 'synthetic',
        deviceId: 'synthetic',
      ),
    );
    await DriftUserRepository(
      h.db,
      lang: 'en',
      ownsDatabase: false,
    ).addStoryWord(storyCandidate(), now: now);
    await user.saveSubmission(
      LocalSubmission(
        id: 'saved-report',
        createdAt: now,
        text: 'Existing English feedback',
        category: 'Grammatik',
        cardId: 'card-went',
      ),
    );
    final tables = [
      'user_cards',
      'review_log',
      'deck_settings',
      'language_learning_preferences',
      'card_contexts',
      'story_learning_additions',
      'story_word_sources',
      'learning_identity_bindings',
      'form_identity_bindings',
      'local_submissions',
    ];
    Future<Map<String, Object>> snapshot() async => {
      for (final t in tables)
        t:
            (await h.db
                    .customSelect(
                      "SELECT * FROM $t ${t == 'language_learning_preferences' ? "WHERE lang='en'" : ''} ORDER BY rowid",
                    )
                    .get())
                .map((r) => r.data)
                .toList(),
    };
    final before = await snapshot();
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      true,
    );
    expect(await c.read(selectedContentLanguageProvider.future), 'pt-BR');
    expect(
      await c.read(languageInstallationProvider('pt-BR').future),
      'Noch nicht installiert',
    );
    await expectLater(
      c.read(contentRepositoryProvider.future),
      throwsA(isA<ContentUnavailable>()),
    );
    expect(
      await (await c.read(userRepositoryProvider.future)).allCardStates(),
      isEmpty,
    );
    expect(await c.read(wordListProvider.future), isEmpty);
    expect((await c.read(vocabBreakdownProvider.future)).unseen, 0);
    c.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    c = h.scope();
    expect(await c.read(selectedContentLanguageProvider.future), 'pt-BR');
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('en'),
      true,
    );
    expect((await c.read(contentRepositoryProvider.future)).info.lang, 'en');
    expect(await snapshot(), before);
    expect((await c.read(preferencesProvider.future)).includeDiacritics, false);
    expect((await c.read(preferencesProvider.future)).dailyGoal, 17);
  });

  test(
    'held content or update lease refuses immediately, no deferred switch',
    () async {
      for (final reason in ['content', 'update']) {
        final release = contentTransitionGate.acquire(reason: reason);
        expect(
          await c
              .read(languageSelectionProvider.notifier)
              .selectLanguage('pt-BR'),
          false,
        );
        expect(
          c.read(languageSelectionProvider).message,
          contains(reason == 'update' ? 'Inhaltsupdateaktion' : 'Wortdetails'),
        );
        release();
        await Future<void>.delayed(Duration.zero);
        expect(await c.read(selectedContentLanguageProvider.future), 'en');
      }
    },
  );

  test('real session lease blocks language change until disposal', () async {
    const args = (deckId: 'deck-allg', kind: DeckSessionKind.learn, size: 1);
    final subscription = c.listen(
      deckSessionControllerProvider(args),
      (_, _) {},
    );
    for (
      var i = 0;
      i < 40 && c.read(deckSessionControllerProvider(args)).pass == null;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(c.read(deckSessionControllerProvider(args)).pass, isNotNull);
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      false,
    );
    expect(c.read(languageSelectionProvider).message, contains('Übung'));
    subscription.close();
    c.invalidate(deckSessionControllerProvider(args));
    await Future<void>.delayed(Duration.zero);
    expect(await c.read(selectedContentLanguageProvider.future), 'en');
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      true,
    );
  });

  test('unsupported selection cannot overwrite persisted language', () async {
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-PT'),
      false,
    );
    expect(await c.read(selectedContentLanguageProvider.future), 'en');
    expect(
      (await c.read(userRepositoryProvider.future)) is DriftUserRepository,
      true,
    );
  });
  test('same surface and semantic anchor in en and pt-BR create distinct local identities', () async {
    final en = await c.read(userRepositoryProvider.future);
    final source = storyCandidate(surface: 'ação');
    final enResult = await DriftUserRepository(
      h.db,
      lang: 'en',
      ownsDatabase: false,
    ).addStoryWord(source, now: DateTime(2026));
    await en.setCardFlags(
      enResult.cardId!,
      note: 'English note',
      favorite: true,
    );
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      true,
    );
    final pt = await c.read(userRepositoryProvider.future);
    final candidate = StoryLearningCandidate(
      storyId: source.storyId,
      revision: source.revision,
      lang: 'pt-BR',
      sentence: source.sentence,
      token: source.token,
    );
    final ptResult = await DriftUserRepository(
      h.db,
      lang: 'pt-BR',
      ownsDatabase: false,
    ).addStoryWord(candidate, now: DateTime(2026));
    expect(ptResult.cardId, isNot(enResult.cardId));
    await pt.setCardFlags(ptResult.cardId!, note: 'Portuguese note');
    expect((await pt.allCardStates()).keys, [ptResult.cardId]);
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('en'),
      true,
    );
    final restored = await (await c.read(userRepositoryProvider.future))
        .allCardStates();
    expect(restored.keys, [enResult.cardId]);
    expect(restored[enResult.cardId]!.note, 'English note');
    expect(restored[enResult.cardId]!.favorite, true);
  });
}
