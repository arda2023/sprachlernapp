import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/screens/decks/widgets/practice_input.dart';
import 'package:sprachapp/screens/decks/widgets/practice_sentence.dart';

const retired = '1bbe26267773ad288ddd7bf7063c4437';
const keep = 'ca8c7f9b1f100ebc671639b0d71fdf64';
const like = '7e36dbaded1247f91a76a6577dfe5345';
const output = 'pipeline/out/context_quality_applied_v1/content.sqlite';

void main() {
  final oldWarn = driftRuntimeOptions.dontWarnAboutMultipleDatabases;
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });
  tearDownAll(
    () => driftRuntimeOptions.dontWarnAboutMultipleDatabases = oldWarn,
  );

  test('actual applied pack preserves due states and saved reviews while excluding so', () async {
    final before = DriftContentRepository(
      ContentDatabase.open(
        File('pipeline/out/business_email_batch_6_perf_v1/content.sqlite'),
        lang: 'en',
      ),
    );
    final after = DriftContentRepository(
      ContentDatabase.open(File(output), lang: 'en'),
    );
    final dir = Directory.systemTemp.createTempSync(
      'context-quality-synthetic-',
    );
    addTearDown(() async {
      await before.close();
      await after.close();
      dir.deleteSync(recursive: true);
    });
    final file = File('${dir.path}/synthetic-user.sqlite');
    var db = UserDatabase.file(file);
    var user = DriftUserRepository(db, lang: 'en');
    final now = DateTime.utc(2026, 10, 16);
    final past = now.subtract(const Duration(days: 20));
    final oldItems = await before.practiceItems([retired, keep, like]);
    await user.ensureCards(
      [retired, keep, like],
      now: past,
      origin: CardOrigin.deck,
    );
    for (final item in oldItems) {
      final pass = ReviewPass(
        id: 'saved-${item.card.id}',
        item: item,
        sentence: item.practiceSentence,
        state: (await user.cardStates([item.card.id]))[item.card.id]!,
        mode: ReviewMode.mixed,
        startedAt: past,
      );
      pass.submit(item.card.form, past);
      await user.recordReview(
        pass.complete(
          now: past,
          appVersion: 'synthetic',
          deviceId: await user.deviceId(),
        )!,
      );
    }
    final stateRows = [
      for (final r
          in await db
              .customSelect('SELECT * FROM user_cards ORDER BY card_id')
              .get())
        r.data,
    ];
    final reviewRows = [
      for (final r
          in await db
              .customSelect('SELECT * FROM review_log ORDER BY id')
              .get())
        r.data,
    ];
    await user.close();
    final bytes = file.readAsBytesSync();
    db = UserDatabase.file(file);
    user = DriftUserRepository(db, lang: 'en');
    try {
      final resolver = await PracticeItemResolver.load(user, after);
      expect(resolver.states[retired]!.isDue(now), isTrue);
      expect(resolver.knownIds, isNot(contains(retired)));
      expect(resolver.projectExisting([retired]), isEmpty);
      for (final kind in [DeckSessionKind.learn, DeckSessionKind.revue]) {
        expect(
          buildDeckQueue(
            deckCardIds: [retired],
            cards: resolver.cards,
            states: resolver.states,
            kind: kind,
            now: now,
            targetsResolved: true,
          ),
          isEmpty,
        );
      }
      expect(
        buildMixedQueue(
          activeDeckCardIds: [retired],
          cards: resolver.cards,
          states: resolver.states,
          now: now,
          targetsResolved: true,
        ).map((i) => i.cardId).toSet(),
        {keep, like},
      );
      final mixed = await resolver.activePrimaryIds();
      expect(
        buildMixedQueue(
          activeDeckCardIds: mixed,
          cards: resolver.cards,
          states: resolver.states,
          now: now,
          size: 50,
          targetsResolved: true,
        ).map((i) => i.cardId),
        isNot(contains(retired)),
      );
      for (final deck in await after.decks()) {
        final ids = await resolver.deckPracticeIds(deck.id);
        for (final kind in [DeckSessionKind.learn, DeckSessionKind.revue]) {
          expect(
            buildDeckQueue(
              deckCardIds: ids,
              cards: resolver.cards,
              states: resolver.states,
              kind: kind,
              now: now,
              size: 50,
              targetsResolved: true,
            ).map((i) => i.cardId),
            isNot(contains(retired)),
          );
        }
      }
      for (final old in oldItems) {
        final review = (await user.reviewsFor(old.card.id)).single;
        final history = await resolver.historicalSentence(
          review.cardId,
          review.sentenceId,
        );
        expect(history!.text, old.practiceSentence.text);
        expect(
          history.validAlternatives,
          old.practiceSentence.validAlternatives,
        );
        expect(
          history.tokens.map((t) => t.translation),
          old.practiceSentence.tokens.map(
            (t) => old.card.id == like && t.surface == 'like'
                ? 'so (umgangssprachlich als Zitateinleitung)'
                : t.translation,
          ),
        );
      }
      for (final id in [
        '6b16d298c448ea845b600cfd8eb27637',
        'd35bd278154554f67175421eda5326d1',
      ]) {
        expect(await after.historicalSentence(retired, id), isNotNull);
      }
      final items = await resolver.practiceItems([keep, like]);
      expect(
        items.singleWhere((i) => i.card.id == keep).practiceSentence.sentenceId,
        'ffc8ac9d8c30d444dc471a2c1425bbf4',
      );
      final corrected = items.singleWhere((i) => i.card.id == like);
      expect(
        corrected.card.translationDe,
        'so (umgangssprachlich als Zitateinleitung)',
      );
      final previous = oldItems.singleWhere((i) => i.card.id == like);
      expect(corrected.practiceSentence.text, previous.practiceSentence.text);
      expect(
        corrected.practiceSentence.translationDe,
        previous.practiceSentence.translationDe,
      );
      expect(
        corrected.practiceSentence.sentenceId,
        previous.practiceSentence.sentenceId,
      );
      expect([
        for (final r
            in await db
                .customSelect('SELECT * FROM user_cards ORDER BY card_id')
                .get())
          r.data,
      ], stateRows);
      expect([
        for (final r
            in await db
                .customSelect('SELECT * FROM review_log ORDER BY id')
                .get())
          r.data,
      ], reviewRows);
    } finally {
      await user.close();
    }
    expect(file.readAsBytesSync(), bytes);
  });

  testWidgets(
    'actual two-sentence exercise renders one gap and correct contextual word taps',
    (tester) async {
      final repo = DriftContentRepository(
        ContentDatabase.open(File(output), lang: 'en'),
      );
      final sentence = (await tester.runAsync(
        () async => (await repo.practiceItems([keep])).single.practiceSentence,
      ))!;
      await tester.runAsync(repo.close);
      expect(sentence.gapStart, 22);
      expect(sentence.gapEnd, 44);
      expect(sentence.gapText, "Let's keep it that way");
      expect(sentence.tokens.map((t) => t.surface), [
        'The',
        'kitchen',
        'is',
        'clean',
        '.',
        "Let's keep it that way",
        '.',
      ]);
      expect(sentence.tokens.take(4).map((t) => t.translation), [
        'die',
        'Küche',
        'ist',
        'sauber',
      ]);
      final input = PracticeInputController();
      final focus = FocusNode();
      WordAnchor? selected;
      for (final width in [320.0, 800.0]) {
        tester.view.resetPhysicalSize();
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        for (final solved in [false, true]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: PracticeSentence(
                  sentence: sentence,
                  input: input,
                  focus: focus,
                  solved: solved,
                  onSubmit: () {},
                  onChanged: () {},
                  onWord: (word) => selected = word,
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.byType(TextField), findsOneWidget);
          expect(find.text('clean.'), findsOneWidget);
          for (final pair in [
            ('The', 'die', 0),
            ('kitchen', 'Küche', 4),
            ('is', 'ist', 12),
            ('clean.', 'sauber', 15),
          ]) {
            await tester.tap(find.text(pair.$1));
            expect(selected!.translation, pair.$2);
            expect(selected!.start, pair.$3);
          }
          if (solved) {
            expect(
              tester.widget<TextField>(find.byType(TextField)).controller!.text,
              "Let's keep it that way",
            );
          }
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(const SizedBox());
      input.dispose();
      focus.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
}
