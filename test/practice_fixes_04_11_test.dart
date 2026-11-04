import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/content/content_pack_installer.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/screens/decks/widgets/practice_input.dart';
import 'package:sprachapp/screens/decks/widgets/practice_sentence.dart';
import 'package:sprachapp/theme/app_theme.dart';

/// User requests of 04.11.2026: the typed word sits exactly on the ghost,
/// the field never wraps, a deactivated deck stays out of Mixed, and
/// "Business" is part of "Beruf".
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('practice field', () {
    Future<void> pump(
      WidgetTester tester,
      PracticeInputController input, {
      String text = 'Emma meets her colleague on the bus.',
      int gapStart = 15,
      int gapEnd = 24,
      bool solved = false,
      bool error = false,
    }) => tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: PracticeSentence(
              sentence: CardSentence(
                cardId: 'c',
                sentenceId: 's',
                position: 1,
                text: text,
                gapStart: gapStart,
                gapEnd: gapEnd,
              ),
              input: input,
              focus: FocusNode(),
              solved: solved,
              error: error,
              onSubmit: () {},
              onChanged: () {},
              onWord: (_) {},
            ),
          ),
        ),
      ),
    );

    testWidgets(
      'typed letters sit exactly on the ghost word',
      (tester) async {
        final input = PracticeInputController();
        for (var i = 0; i < 4; i++) {
          input.showWrong('x', 'colleague');
        }
        await pump(tester, input);
        input.value = const TextEditingValue(
          text: 'co',
          selection: TextSelection.collapsed(offset: 2),
        );
        await tester.pump();
        final editable = tester
            .state<EditableTextState>(find.byType(EditableText))
            .renderEditable;
        final ghost = tester.renderObject<RenderParagraph>(
          find.byKey(const ValueKey('practice-ghost')),
        );
        expect(
          editable.localToGlobal(Offset.zero),
          ghost.localToGlobal(Offset.zero),
        );
        expect(
          editable.getLocalRectForCaret(const TextPosition(offset: 2)).left,
          moreOrLessEquals(
            ghost
                .getOffsetForCaret(const TextPosition(offset: 2), Rect.zero)
                .dx,
            epsilon: 1,
          ),
        );
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.iOS,
        TargetPlatform.android,
      }),
    );

    testWidgets('a solved answer wider than what was typed stays on one line', (
      tester,
    ) async {
      final input = PracticeInputController();
      const text = 'Draw a picture of your house with these coloured pencils.';
      await pump(tester, input, text: text, gapStart: 0, gapEnd: 4);
      input.value = const TextEditingValue(
        text: 'draw',
        selection: TextSelection.collapsed(offset: 4),
      );
      await tester.pump();
      final field = find.byKey(const ValueKey('practice-input'));
      final typing = tester.getSize(field);
      await pump(
        tester,
        input,
        text: text,
        gapStart: 0,
        gapEnd: 4,
        solved: true,
      );
      expect(tester.getSize(field).height, typing.height);
    });

    testWidgets('a hint after a short wrong answer does not wrap', (
      tester,
    ) async {
      final input = PracticeInputController();
      const text = 'Noah, please walk quietly inside the library.';
      await pump(tester, input, text: text, gapStart: 13, gapEnd: 17);
      input.value = const TextEditingValue(
        text: 'w',
        selection: TextSelection.collapsed(offset: 1),
      );
      await tester.pump();
      final field = find.byKey(const ValueKey('practice-input'));
      final typing = tester.getSize(field);
      input
        ..showWrong('w', 'walk')
        ..showWrong('w', 'walk');
      expect(input.hint, 'wa…');
      // The field still shakes red while the hint shows.
      await pump(
        tester,
        input,
        text: text,
        gapStart: 13,
        gapEnd: 17,
        error: true,
      );
      expect(tester.getSize(field).height, typing.height);
      expect(tester.getSize(field).width, greaterThan(typing.width));
    });
  });

  group('deactivated deck', () {
    final now = DateTime(2026, 11, 4, 12);
    ContentCard card(String id) => ContentCard(
      id: id,
      lang: 'en',
      form: id,
      formNorm: id,
      lemmaId: id,
      lemma: id,
      pos: 'NOUN',
    );
    final cards = {
      for (final id in ['off1', 'off2', 'on1']) id: card(id),
    };
    final states = {
      for (final id in cards.keys)
        id: UserCardState(
          cardId: id,
          box: 2,
          dueAt: now.subtract(const Duration(days: 1)),
        ),
    };

    test('Mixed shows none of its due words', () {
      final queue = buildMixedQueue(
        activeDeckCardIds: const [],
        deckSources: [
          NewWordSource('on', ['on1']),
        ],
        cards: cards,
        states: states,
        now: now,
        hiddenIds: {'off1', 'off2'},
      );
      expect(queue.map((e) => e.cardId), ['on1']);
    });

    test('the counters leave its words out', () {
      final all = deriveVocabBreakdown(
        activeDeckCardIds: {'on1'},
        cards: states,
        knownCardIds: cards.keys.toSet(),
        now: now,
      );
      final shown = deriveVocabBreakdown(
        activeDeckCardIds: {'on1'},
        cards: states,
        knownCardIds: cards.keys.toSet(),
        now: now,
        hiddenIds: {'off1', 'off2'},
      );
      expect(all.due, 3);
      expect(shown.due, 1);
      expect(shown.total, 1);
    });
  });

  final asset = File('assets/content/en/content.sqlite');
  test('Business is part of Beruf', () async {
    final tmp = Directory.systemTemp.createTempSync('merged_deck_');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final repo = await ContentPackInstaller(
      supportDirectory: tmp,
      loadAsset: (key) async {
        final file = File(key);
        return file.existsSync()
            ? Uint8List.fromList(file.readAsBytesSync())
            : null;
      },
    ).open();
    final decks = {for (final d in await repo.decks()) d.slug: d};
    expect(decks.containsKey('business-email'), isFalse);
    final work = decks['arbeit-bildung']!;
    final targets = await repo.deckPracticeTargets(work.id);
    expect(targets.map((t) => t.cardId).toSet(), hasLength(targets.length));
    // 252 work and 579 business cards in the English pack, none shared.
    expect((await repo.deckCardIds(work.id)).length, 252 + 579);
    expect(work.cardCount, greaterThan(579));
  }, skip: asset.existsSync() ? false : 'no staged English pack');
}
