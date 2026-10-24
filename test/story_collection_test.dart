import 'dart:io';
import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/domain/story_learning_diagnostics.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/presentation/practice/deck_session_controller.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/story_collection_provider.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import 'package:sprachapp/screens/stories/story_collection_screen.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/stories/widgets/word_popover.dart';
import 'package:sprachapp/theme/app_theme.dart';

import 'fixtures/deck_repositories.dart';
import 'fixtures/story_learning.dart';

const sensitive = 'private story https://secret.invalid/?token=PRIVATE';
final now = DateTime(2026, 10, 24, 12);

class StoryFixture extends TestContent implements StoryContentRepository {
  StoryFixture(this.c);
  final StoryLearningCandidate c;
  bool fail = false;
  @override
  ContentInfo get info =>
      ContentInfo(lang: c.lang, version: 'test', schemaVersion: 1);
  StoryDocument get doc => StoryDocument(
    const StorySummary(
      id: 'story',
      title: 'Test story',
      titleDe: 'Test',
      level: 'A2',
      minutes: 1,
    ),
    c.revision,
    [c.sentence],
  );
  @override
  Future<List<StorySummary>> storySummaries() async => [doc.summary];
  @override
  Future<StoryDocument> storyDocument(String id) async => doc;
  @override
  Future<StoryLearningCandidate> resolveStoryWord(
    String story,
    String sentence,
    int token,
  ) async {
    if (fail) throw StateError(sensitive);
    return c;
  }

  @override
  Future<List<ContentCard>> selectionCards(Iterable<String> ids) async => [];
}

class FaultUser extends DriftUserRepository {
  FaultUser() : super(UserDatabase(NativeDatabase.memory()), lang: 'en');
  bool failStatus = false, failSave = false, failLocalOnce = false;
  int localReads = 0;
  @override
  Future<List<PracticeItem>> localPracticeItems() {
    localReads++;
    if (failLocalOnce && localReads == 1) throw StateError(sensitive);
    return super.localPracticeItems();
  }

  @override
  Future<StoryAddResult> storyLearningStatus(StoryLearningCandidate c) {
    if (failStatus) throw StateError(sensitive);
    return super.storyLearningStatus(c);
  }

  @override
  Future<StoryAddResult> addStoryWord(
    StoryLearningCandidate c, {
    required DateTime now,
  }) {
    if (failSave) throw StateError(sensitive);
    return super.addStoryWord(c, now: now);
  }
}

class StatusOnceService extends StoryLearningService {
  StatusOnceService(super.ref);
  int reads = 0;
  @override
  Future<StoryAddResult> status(StoryLearningCandidate c) {
    if (++reads > 1) throw const StoryLearningFailure(StoryLearningStep.status);
    return super.status(c);
  }
}

class MeasuredPack extends DriftContentRepository {
  MeasuredPack(super.db);
  int fullLists = 0, selected = 0, practiceBatches = 0;
  @override
  Future<Set<String>> allCardIds() {
    fullLists++;
    return super.allCardIds();
  }

  @override
  Future<List<ContentCard>> selectionCards(Iterable<String> ids) {
    selected += ids.length;
    return super.selectionCards(ids);
  }

  @override
  Future<List<PracticeItem>> practiceItems(List<String> ids) {
    practiceBatches++;
    return super.practiceItems(ids);
  }
}

Future<void> settleSession(
  ProviderContainer scope,
  DeckSessionArgs args,
) async {
  for (
    var i = 0;
    i < 100 && scope.read(deckSessionControllerProvider(args)).loading;
    i++
  ) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(scope.read(deckSessionControllerProvider(args)).loading, isFalse);
  expect(scope.read(deckSessionControllerProvider(args)).error, isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test(
    'classification preserves validators: existing/context/annotation/deferred',
    () {
      expect(
        storyAvailability(storyCandidate(card: exactCard(), approved: false)),
        StoryLearningAvailability.existingCard,
      );
      expect(
        storyAvailability(storyCandidate()),
        StoryLearningAvailability.approvedContext,
      );
      expect(
        storyAvailability(storyCandidate(approved: false)),
        StoryLearningAvailability.missingContext,
      );
      expect(
        storyAvailability(storyCandidate(retired: true)),
        StoryLearningAvailability.deferred,
      );
      final c = storyCandidate();
      final missing = StoryLearningCandidate(
        storyId: c.storyId,
        revision: c.revision,
        lang: c.lang,
        sentence: c.sentence,
        token: StoryToken(
          index: 3,
          start: c.token.start,
          end: c.token.end,
          surface: c.token.surface,
        ),
      );
      expect(
        storyAvailability(missing),
        StoryLearningAvailability.missingAnnotation,
      );
      expect(missing.validationProblem(), isNotNull);
    },
  );

  test(
    'technical failures expose only step/code and never become missing context',
    () async {
      final user = FaultUser(), content = StoryFixture(storyCandidate());
      final scope = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith((_) => user),
          contentRepositoryProvider.overrideWith((_) => content),
        ],
      );
      addTearDown(() async {
        scope.dispose();
        await user.close();
      });
      final service = scope.read(storyLearningServiceProvider);
      Future<void> failure(
        Future<Object?> Function() action,
        StoryLearningStep step,
      ) async {
        try {
          await action();
          fail('must throw');
        } on StoryLearningFailure catch (e) {
          expect(e.step, step);
          expect(e.message, contains(step.code));
          expect(e.toString(), isNot(contains('PRIVATE')));
          expect(e.message, isNot(contains('Kontext')));
        }
      }

      content.fail = true;
      await failure(
        () => service.candidate('story', 'sentence', 3),
        StoryLearningStep.context,
      );
      content.fail = false;
      user.failStatus = true;
      await failure(() => service.status(content.c), StoryLearningStep.status);
      user.failStatus = false;
      user.failSave = true;
      await failure(() => service.add(content.c), StoryLearningStep.save);
      expect(await user.allCardStates(), isEmpty);
    },
  );

  test('technical user read is not swallowed by offline fallback', () async {
    final user = FaultUser()..failLocalOnce = true;
    final scope = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWith((_) => user),
        contentRepositoryProvider.overrideWith(
          (_) => StoryFixture(storyCandidate()),
        ),
      ],
    );
    addTearDown(() async {
      scope.dispose();
      await user.close();
    });
    await expectLater(
      scope.read(storyCollectionProvider.future),
      throwsA(
        isA<StoryLearningFailure>().having(
          (e) => e.step,
          'step',
          StoryLearningStep.collection,
        ),
      ),
    );
    expect(user.localReads, 1);
  });

  test('collection shows corrected local sentence while reviews keep original snapshot', () async {
    final before = DriftContentRepository(
      ContentDatabase.open(
        File('pipeline/out/story_contexts_v1/content.sqlite'),
        lang: 'en',
      ),
    );
    final after = DriftContentRepository(
      ContentDatabase.open(
        File('pipeline/out/story_single_sentence_v1/content.sqlite'),
        lang: 'en',
      ),
    );
    final user = DriftUserRepository(
      UserDatabase(NativeDatabase.memory()),
      lang: 'en',
    );
    final doc = await before.storyDocument(
      (await before.storySummaries()).single.id,
    );
    final sentence = doc.sentences.firstWhere(
      (s) => s.tokens.any((t) => t.surface == 'safely'),
    );
    final token = sentence.tokens.firstWhere((t) => t.surface == 'safely');
    final c = await before.resolveStoryWord(
      doc.summary.id,
      sentence.id,
      token.index,
    );
    final id = (await user.addStoryWord(c, now: now)).cardId!;
    final old = (await user.localPracticeItems()).single;
    final pass = ReviewPass(
      id: 'historic',
      item: old,
      sentence: old.practiceSentence,
      state: (await user.cardStates([id]))[id],
      mode: ReviewMode.mixed,
      startedAt: now,
    );
    pass.submit(old.card.form, now);
    await user.recordReview(
      pass.complete(now: now, appVersion: 'test', deviceId: 'test')!,
    );
    final scope = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWith((_) => user),
        contentRepositoryProvider.overrideWith((_) => after),
      ],
    );
    addTearDown(() async {
      scope.dispose();
      await user.close();
      await before.close();
      await after.close();
    });
    final current = (await scope.read(storyCollectionProvider.future)).single;
    expect(current.state.cardId, id);
    expect(
      current.item!.practiceSentence.text,
      isNot(old.practiceSentence.text),
    );
    final review = (await user.reviewsFor(id)).single;
    expect(review.sentenceId, old.practiceSentence.sentenceId);
    final resolver = await scope.read(practiceResolverProvider.future);
    expect(
      (await resolver.historicalSentence(id, review.sentenceId))!.text,
      old.practiceSentence.text,
    );
    expect(current.state.box, 3);
  });

  test('arrives early pocket safely: real pack/provider save, duplicate, restart, bounded lookup', () async {
    final dir = Directory.systemTemp.createTempSync('story-collection-real-');
    final file = File('${dir.path}/user.db');
    final content = MeasuredPack(
      ContentDatabase.open(
        File('assets/content/en/content.sqlite'),
        lang: 'en',
      ),
    );
    var user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
    var scope = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWith((_) => user),
        contentRepositoryProvider.overrideWith((_) => content),
      ],
    );
    addTearDown(() async {
      scope.dispose();
      await user.close();
      await content.close();
      dir.deleteSync(recursive: true);
    });
    final doc = await content.storyDocument(
      (await content.storySummaries()).single.id,
    );
    expect(
      (await scope.read(practiceResolverProvider.future)).storyCollectionIds,
      isEmpty,
    );
    content.fullLists = 0;
    content.selected = 0;
    final service = scope.read(storyLearningServiceProvider);
    final ids = <String>{};
    final kinds = <StoryLearningAvailability>{};
    for (final word in ['arrives', 'early', 'pocket', 'safely']) {
      final sentence = doc.sentences.firstWhere(
        (s) => s.tokens.any((t) => t.surface == word),
      );
      final token = sentence.tokens.firstWhere((t) => t.surface == word);
      final c = await service.candidate(
        doc.summary.id,
        sentence.id,
        token.index,
      );
      kinds.add(storyAvailability(c));
      expect(
        (await service.status(c)).canAdd,
        isTrue,
        reason: '$word: ${c.unavailableReason}',
      );
      final results = await Future.wait([service.add(c), service.add(c)]);
      expect(results.every((r) => r.state == StoryAddState.added), isTrue);
      expect(results.first.cardId, results.last.cardId);
      ids.add(results.first.cardId!);
      expect(await user.reviewsFor(results.first.cardId!), isEmpty);
    }
    expect(
      content.fullLists,
      0,
      reason: 'word lookup must not enumerate the pack',
    );
    expect(
      content.selected,
      lessThan(100),
      reason: 'only exact learning-group members',
    );
    expect(
      kinds,
      containsAll([
        StoryLearningAvailability.existingCard,
        StoryLearningAvailability.approvedContext,
      ]),
    );
    scope.dispose();
    await user.close();
    user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
    scope = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWith((_) => user),
        contentRepositoryProvider.overrideWith((_) => content),
      ],
    );
    final words = await scope.read(storyCollectionProvider.future);
    expect(words.map((w) => w.state.cardId).toSet(), ids);
    expect(words.where((w) => w.state.localOnly), isNotEmpty);
    expect(words.where((w) => !w.state.localOnly), isNotEmpty);
    expect((await user.allCardStates()).length, ids.length);
    expect(
      words.every((w) => w.item!.practiceSentence.gapText.isNotEmpty),
      isTrue,
    );
  });

  test('known deck state gains membership without copies, reviews or resetting flags', () async {
    final content = TestContent(),
        user = DriftUserRepository(
          UserDatabase(NativeDatabase.memory()),
          lang: 'en',
        );
    addTearDown(user.close);
    final card = exactCard(id: 'deck-0/0');
    final base = storyCandidate(surface: card.form, sense: card.senseId!);
    final c = StoryLearningCandidate(
      storyId: base.storyId,
      revision: base.revision,
      lang: 'en',
      sentence: base.sentence,
      token: base.token,
      card: card,
    );
    await user.ensureCards([card.id], now: now, origin: CardOrigin.deck);
    final item = content.item(card.id);
    final pass = ReviewPass(
      id: 'known',
      item: item,
      sentence: item.practiceSentence,
      state: (await user.cardStates([card.id]))[card.id],
      mode: ReviewMode.deck,
      startedAt: now,
    );
    pass.submit(item.card.form, now);
    await user.recordReview(
      pass.complete(now: now, appVersion: 'test', deviceId: 'test')!,
    );
    await user.setCardFlags(card.id, favorite: true, note: 'keep');
    final before = (await user.cardStates([card.id]))[card.id]!;
    expect((await user.storyLearningStatus(c)).state, StoryAddState.available);
    expect((await user.addStoryWord(c, now: now)).cardId, card.id);
    final after = (await user.cardStates([card.id]))[card.id]!;
    expect(
      [after.box, after.dueAt, after.favorite, after.note, after.origin],
      [before.box, before.dueAt, before.favorite, before.note, before.origin],
    );
    expect((await user.reviewsFor(card.id)).length, 1);
    expect(
      (await PracticeItemResolver.load(user, content)).storyCollectionIds,
      [card.id],
    );
    await user.setCardFlags(card.id, disabled: true);
    expect(
      (await user.addStoryWord(c, now: now)).state,
      StoryAddState.disabled,
    );
    expect(
      (await PracticeItemResolver.load(user, content)).storyCollectionIds,
      [card.id],
    );
  });

  test('legacy sources without addition rows and story origins remain included, language isolated', () async {
    final db = UserDatabase(NativeDatabase.memory());
    final en = DriftUserRepository(db, lang: 'en', ownsDatabase: false);
    final pt = DriftUserRepository(db, lang: 'pt-BR', ownsDatabase: false);
    addTearDown(db.close);
    final c = storyCandidate(card: exactCard());
    await en.ensureCards(['curated'], now: now, origin: CardOrigin.deck);
    await en.addStoryWord(c, now: now);
    await db
        .delete(db.storyLearningAdditions)
        .go(); // historical source-only membership
    expect((await PracticeItemResolver.load(en, null)).storyCollectionIds, [
      'curated',
    ]);
    expect(
      (await PracticeItemResolver.load(pt, null)).storyCollectionIds,
      isEmpty,
    );
    final local = storyCandidate();
    // A separate local legacy origin; no source/addition remains.
    await en.addStoryWord(storyCandidate(sense: 'other'), now: now);
    await db.delete(db.storyLearningAdditions).go();
    await db.delete(db.storyWordSources).go();
    expect(
      (await PracticeItemResolver.load(en, null)).storyCollectionIds,
      hasLength(1),
    );
    expect(
      (await en.storyLearningStatus(local)).state,
      StoryAddState.available,
    );
  });

  test(
    'collection uses daily remaining and writes the same review; works offline',
    () async {
      final user = DriftUserRepository(
        UserDatabase(NativeDatabase.memory()),
        lang: 'en',
      );
      final c = storyCandidate();
      await user.addStoryWord(c, now: now);
      final scope = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith((_) => user),
          contentRepositoryProvider.overrideWith(
            (_) async => throw StateError('offline'),
          ),
          appInfoProvider.overrideWith((_) => 'test'),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(() async {
        scope.dispose();
        await user.close();
      });
      const args = (
        deckId: storyCollectionId,
        kind: DeckSessionKind.learn,
        size: 0,
      );
      final sub = scope.listen(deckSessionControllerProvider(args), (_, _) {});
      addTearDown(sub.close);
      await settleSession(scope, args);
      expect(
        scope.read(deckSessionControllerProvider(args)).pass!.item.card.id,
        c.identity.localId,
      );
      scope
          .read(deckSessionControllerProvider(args).notifier)
          .submit(c.token.surface);
      for (
        var i = 0;
        i < 100 && !scope.read(deckSessionControllerProvider(args)).saved;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect((await user.reviewsFor(c.identity.localId)).length, 1);
      expect((await user.allCardStates()).length, 1);
      scope.invalidate(practiceResolverProvider);
      final words = await scope.read(storyCollectionProvider.future);
      expect(words.single.state.box, 3);
      sub.close();
      final restart = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith((_) => user),
          contentRepositoryProvider.overrideWith(
            (_) async => throw StateError('offline'),
          ),
          appInfoProvider.overrideWith((_) => 'test'),
          clockProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(restart.dispose);
      final second = restart.listen(
        deckSessionControllerProvider(args),
        (_, _) {},
      );
      addTearDown(second.close);
      await settleSession(restart, args);
      expect(
        restart.read(deckSessionControllerProvider(args)).pass,
        isNull,
        reason: 'already completed today, not introduced twice',
      );
    },
  );

  Future<void> openFixture(
    WidgetTester t,
    ProviderContainer scope,
    StoryFixture content,
  ) async {
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: CupertinoButton(
                child: const Text('Open'),
                onPressed: () => StoryReaderScreen.open(
                  context,
                  Story(
                    id: 'story',
                    title: 'Test story',
                    topic: 'Alltag',
                    level: 'A2',
                    readingMinutes: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Open'));
    await t.pumpAndSettle();
  }

  testWidgets(
    'Portuguese local story mark survives reopen: en lookup was wrong',
    (t) async {
      final en = storyCandidate(surface: 'mochila');
      final c = StoryLearningCandidate(
        storyId: en.storyId,
        revision: en.revision,
        lang: 'pt-BR',
        sentence: en.sentence,
        token: en.token,
      );
      final content = StoryFixture(c);
      final user = DriftUserRepository(
        UserDatabase(NativeDatabase.memory()),
        lang: 'pt-BR',
      );
      await user.addStoryWord(c, now: now);
      final scope = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith((_) => user),
          contentRepositoryProvider.overrideWith((_) => content),
        ],
      );
      addTearDown(() async {
        scope.dispose();
        await user.close();
      });
      final resolver = await scope.read(practiceResolverProvider.future);
      expect(resolver.storyStateId('en', c.token), isNull);
      expect(resolver.storyStateId('pt-BR', c.token), c.identity.localId);
      await openFixture(t, scope, content);
      final reader = t.widget<StoryReaderScreen>(
        find.byType(StoryReaderScreen),
      );
      expect(reader.sourceLanguage, 'pt-BR');
      expect(
        reader.initialMarks.keys,
        contains('${c.sentence.id}/${c.token.index}'),
      );
      expect(
        (await scope.read(storyCollectionProvider.future))
            .single
            .item!
            .card
            .lang,
        'pt-BR',
      );
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'committed save stays successful when a second status read would fail',
    (t) async {
      final content = StoryFixture(storyCandidate());
      final user = DriftUserRepository(
        UserDatabase(NativeDatabase.memory()),
        lang: 'en',
      );
      late StatusOnceService service;
      final scope = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith((_) => user),
          contentRepositoryProvider.overrideWith((_) => content),
          storyLearningServiceProvider.overrideWith(
            (ref) => service = StatusOnceService(ref),
          ),
        ],
      );
      addTearDown(() async {
        scope.dispose();
        await user.close();
      });
      await openFixture(t, scope, content);
      final finder = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == content.c.sentence.text,
      );
      final p = t.renderObject<RenderParagraph>(finder.first);
      final boxes = p.getBoxesForSelection(
        TextSelection(
          baseOffset: content.c.token.start,
          extentOffset: content.c.token.end,
        ),
      );
      await t.tapAt(p.localToGlobal(boxes.first.toRect().center));
      await t.pumpAndSettle();
      await t.tap(find.text('Zum Lernen hinzufügen'));
      await t.pumpAndSettle();
      expect(find.text('Zum Lernen hinzugefügt'), findsOneWidget);
      // Close via navigator, then give the former follow-up path time to run.
      Navigator.of(t.element(find.byType(WordPopover))).pop();
      await t.pumpAndSettle();
      expect(service.reads, 1);
      expect(find.byType(WordPopover), findsNothing);
      expect((await user.explicitStoryAdditions()).keys, [
        content.c.identity.localId,
      ]);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final step in [StoryLearningStep.context, StoryLearningStep.status]) {
    testWidgets('technical ${step.code} never shows missing annotation text', (
      t,
    ) async {
      final content = StoryFixture(storyCandidate())
        ..fail = step == StoryLearningStep.context;
      final user = FaultUser()..failStatus = step == StoryLearningStep.status;
      final scope = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith((_) => user),
          contentRepositoryProvider.overrideWith((_) => content),
        ],
      );
      addTearDown(() async {
        scope.dispose();
        await user.close();
      });
      await openFixture(t, scope, content);
      final f = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == content.c.sentence.text,
      );
      final p = t.renderObject<RenderParagraph>(f.first);
      final box = p
          .getBoxesForSelection(
            TextSelection(
              baseOffset: content.c.token.start,
              extentOffset: content.c.token.end,
            ),
          )
          .first;
      await t.tapAt(p.localToGlobal(box.toRect().center));
      await t.pumpAndSettle();
      expect(find.textContaining(step.code), findsOneWidget);
      expect(find.textContaining('geprüften Lernreferenzen'), findsNothing);
      expect(find.textContaining('PRIVATE'), findsNothing);
      expect(await user.allCardStates(), isEmpty);
      await t.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'collection layout at narrow width and large text; preview performs no writes',
    (t) async {
      final item = TestContent().item('deck-0/0');
      final words = [
        StoryCollectionWord(
          const UserCardState(cardId: 'deck-0/0', box: 0, dueAt: null),
          item,
        ),
      ];
      final boundary = GlobalKey();
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(),
            home: RepaintBoundary(
              key: boundary,
              child: StoryCollectionScreen(preview: words),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.runAsync(() async {
        final pixels =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final png = await pixels.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/story_collection_preview.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(png!.buffer.asUint8List());
        pixels.dispose();
      });
      expect(t.takeException(), isNull);
      t.view.physicalSize = const Size(320, 740);
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: StoryCollectionScreen(preview: words),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'empty collection hidden; successful saved word reveals entry and current context',
    (t) async {
      final user = DriftUserRepository(
        UserDatabase(NativeDatabase.memory()),
        lang: 'en',
      );
      final scope = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWith((_) => user),
          contentRepositoryProvider.overrideWith(
            (_) => StoryFixture(storyCandidate()),
          ),
        ],
      );
      addTearDown(() async {
        scope.dispose();
        await user.close();
      });
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: MaterialApp(
            theme: buildAppTheme(),
            home: const Scaffold(body: StoryCollectionEntry()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Aus Storys'), findsNothing);
      await t.runAsync(() => user.addStoryWord(storyCandidate(), now: now));
      scope.invalidate(practiceResolverProvider);
      await t.pumpAndSettle();
      await t.tap(find.text('Aus Storys'));
      await t.pumpAndSettle();
      expect(find.byType(StoryCollectionScreen), findsOneWidget);
      expect(find.text(storyCandidate().sentence.text), findsOneWidget);
      expect(find.text('Mit diesen Wörtern lernen'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox.shrink());
    },
  );
}
