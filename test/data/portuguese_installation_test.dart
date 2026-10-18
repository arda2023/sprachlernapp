import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_install_journal.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/data/content/content_update_service.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/repositories.dart';
import 'package:sprachapp/domain/answer_check.dart';
import 'package:sprachapp/domain/language_profile.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/grammar_hint.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/deck_providers.dart';
import 'package:sprachapp/presentation/providers/language_selection_provider.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';

import '../fixtures/language_selection.dart';
import '../fixtures/portuguese_installation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late PortugueseTransport transport;
  late ContentInstallJournal journal;
  late ContentUpdateService service;
  late ContentTransitionGate gate;
  var failOpen = false;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('ptbr-installation-');
    transport = PortugueseTransport(tmp);
    journal = ContentInstallJournal(tmp, 'pt-BR');
    gate = ContentTransitionGate();
    failOpen = false;
    service = ContentUpdateService(
      journal,
      transport,
      currentFile: journal.currentFile,
      gate: gate,
      closeReaders: () async {},
      openReaders: () async {
        if (failOpen) {
          failOpen = false;
          throw StateError('synthetic open failure');
        }
      },
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));
  test('real download, activation, installed language facade, restart and English return', () async {
    final h = LanguageHarness(Directory('${tmp.path}/app')..createSync());
    // Keep the real installed BR generation in the harness support directory.
    h.portuguese = ContentPackInstaller(
      loadAsset: (_) async => null,
      supportDirectory: tmp,
      lang: 'pt-BR',
    );
    var c = h.scope();
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      true,
    );
    await service.check();
    await service.download();
    await service.activate();
    c.invalidate(contentRepositoryProvider);
    c.invalidate(languageInstallationProvider('pt-BR'));
    final content = await c.read(contentRepositoryProvider.future);
    final item = (await content.practiceItems(
      (await content.allCardIds()).toList(),
    )).single;
    expect(item.card.form, 'ação');
    expect(item.card.lang, 'pt-BR');
    expect(
      (await c.read(decksProvider.future)).single.name,
      'SYNTHETISCH – NICHT VERÖFFENTLICHEN',
    );
    expect(await c.read(storySummariesProvider.future), isEmpty);
    final ptUser = await c.read(userRepositoryProvider.future);
    await ptUser.ensureCards(
      [item.card.id],
      now: DateTime(2026, 10, 18),
      origin: CardOrigin.deck,
    );
    await ptUser.setCardFlags(
      item.card.id,
      note: 'Notiz pt-BR',
      favorite: true,
    );
    final ptStates = await ptUser.allCardStates();
    expect(ptStates.keys, [item.card.id]);
    c.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    c = h.scope();
    expect(await c.read(selectedContentLanguageProvider.future), 'pt-BR');
    expect(
      (await c.read(contentRepositoryProvider.future)).info.version,
      'synthetic_ptbr_2',
    );
    expect(
      (await (await c.read(
        userRepositoryProvider.future,
      )).allCardStates())[item.card.id]!.note,
      'Notiz pt-BR',
    );
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('en'),
      true,
    );
    expect(
      (await (await c.read(userRepositoryProvider.future)).allCardStates()),
      isEmpty,
    );
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      true,
    );
    expect(
      (await (await c.read(
        userRepositoryProvider.future,
      )).allCardStates())[item.card.id]!.note,
      'Notiz pt-BR',
    );
    c.dispose();
    await h.close();
  });
  test(
    'interrupted transfer and wrong hash keep pointers empty; retry succeeds',
    () async {
      await service.check();
      transport.interrupt = true;
      await expectLater(service.download(), throwsA(isA<SocketException>()));
      expect(await journal.active(), isNull);
      expect(await journal.read('pending'), isNull);
      transport.interrupt = false;
      transport.badHash = true;
      await expectLater(service.download(), throwsFormatException);
      expect(await journal.active(), isNull);
      expect(await journal.read('pending'), isNull);
      transport.badHash = false;
      await service.download();
      expect(await journal.read('pending'), isNotNull);
    },
  );
  test(
    'activation open failure restores pointer and retains retryable pending',
    () async {
      await service.check();
      await service.download();
      failOpen = true;
      await expectLater(service.activate(), throwsStateError);
      expect(await journal.active(), isNull);
      expect(await journal.read('pending'), isNotNull);
      await service.activate();
      expect((await journal.active())!.lang, 'pt-BR');
    },
  );
  test('corrupt installed BR refuses selection and keeps English reader and setting', () async {
    final h = LanguageHarness(Directory('${tmp.path}/app')..createSync());
    h.portuguese = ContentPackInstaller(
      loadAsset: (_) async => null,
      supportDirectory: tmp,
      lang: 'pt-BR',
    );
    final c = h.scope();
    final before = await c.read(contentRepositoryProvider.future);
    await service.check();
    await service.download();
    await service.activate();
    await File('${journal.generation(transport.offer.id).path}/content.sqlite')
        .writeAsString('damaged');
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      false,
    );
    expect(await c.read(selectedContentLanguageProvider.future), 'en');
    expect(
      identical(await c.read(contentRepositoryProvider.future), before),
      true,
    );
    c.dispose();
    await h.close();
  });
  test('language switch rolls persisted selection back if new reader fails after preflight', () async {
    final h = LanguageHarness(Directory('${tmp.path}/app')..createSync());
    h.portuguese = ContentPackInstaller(
      loadAsset: (_) async => null,
      supportDirectory: tmp,
      lang: 'pt-BR',
    );
    await service.check();
    await service.download();
    await service.activate();
    h.owners[(
      lang: 'pt-BR',
      generation: 1,
    )] = RepositoryOwner<ContentRepository>(
      () async => throw StateError('synthetic target reader failure'),
      (r) => r.close(),
    );
    final c = h.scope();
    expect((await c.read(contentRepositoryProvider.future)).info.lang, 'en');
    expect(
      await c.read(languageSelectionProvider.notifier).selectLanguage('pt-BR'),
      false,
    );
    expect(await c.read(selectedContentLanguageProvider.future), 'en');
    expect((await c.read(contentRepositoryProvider.future)).info.lang, 'en');
    c.dispose();
    await h.close();
  });
  test('profile freezes accent policy, Unicode equality, alternatives and English regression', () {
    const profile = ContentLanguageProfile.portugueseBrazil;
    for (final pair in [
      ('acao', 'ação'),
      ('cafe', 'café'),
      ('nao', 'não'),
      ('poe', 'põe'),
      ('a', 'ã'),
      ('c', 'ç'),
      ('só', 'sô'),
    ]) {
      expect(
        evaluateAnswer(
          pair.$1,
          target: pair.$2,
          profile: profile,
          includeDiacritics: false,
        ),
        isNot(AnswerVerdict.target),
      );
    }
    expect(
      evaluateAnswer(
        ' AC\u0327A\u0303O ',
        target: 'ação',
        profile: profile,
        includeDiacritics: false,
      ),
      AnswerVerdict.target,
    );
    expect(
      evaluateAnswer(
        'acao',
        target: 'ação',
        profile: profile,
        includeDiacritics: false,
      ),
      AnswerVerdict.wrong,
    );
    expect(
      evaluateAnswer(
        'cafe',
        target: 'café',
        profile: profile,
        includeDiacritics: false,
      ),
      AnswerVerdict.almost,
    );
    expect(
      evaluateAnswer('cafe', target: 'café', includeDiacritics: false),
      AnswerVerdict.target,
    );
    expect(
      evaluateAnswer(
        'café',
        target: 'ação',
        alternatives: ['café'],
        profile: profile,
      ),
      AnswerVerdict.alternative,
    );
    const card = ContentCard(
      id: 'pt-acao',
      lang: 'pt-BR',
      form: 'ação',
      formNorm: 'ação',
      lemmaId: 'lemma',
      lemma: 'ação',
      pos: 'NOUN',
      formKind: 'past',
    );
    const sentence = CardSentence(
      cardId: 'pt-acao',
      sentenceId: 'sentence',
      position: 1,
      text: 'ação',
      gapStart: 0,
      gapEnd: 4,
    );
    final pass = ReviewPass(
      id: 'pass',
      item: const PracticeItem(
        card: card,
        sentences: [sentence],
        otherFormsOfLemma: {},
      ),
      sentence: sentence,
      state: null,
      mode: ReviewMode.deck,
      startedAt: DateTime(2026),
    );
    expect(pass.profile, profile);
    expect(
      pass.submit('acao', DateTime(2026), includeDiacritics: false)!.verdict,
      AnswerVerdict.wrong,
    );
    expect(pass.solved, false);
    expect(
      pass
          .submit('AC\u0327A\u0303O', DateTime(2026), includeDiacritics: false)!
          .verdict,
      AnswerVerdict.target,
    );
    expect(
      pass
          .complete(
            now: DateTime(2026),
            appVersion: 'synthetic',
            deviceId: 'synthetic',
          )!
          .boxAfter,
      1,
    );
    expect(grammarHint(card, solved: false).examples, isEmpty);
    expect(
      grammarHint(card, solved: false).explanation,
      isNot(contains('-ed')),
    );
  });
}
