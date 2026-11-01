import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/billing/purchase_gateway.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/story_category.dart';
import 'package:sprachapp/screens/decks/widgets/practice_input.dart';
import 'package:sprachapp/screens/home/widgets/story_carousel.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/word_rain.dart';

/// User requests of 31.10.2026: trial paywall, story shelves, ghost hint,
/// language word wall.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('free trial', () {
    ({bool freeTrial, String unit, int units, int periods}) phase(
      String unit,
      int units, {
      bool free = true,
      int periods = 1,
    }) => (freeTrial: free, unit: unit, units: units, periods: periods);

    test('days from one free introductory phase only', () {
      expect(freeTrialDays(introductory: true, phases: [phase('day', 3)]), 3);
      expect(freeTrialDays(introductory: true, phases: [phase('week', 1)]), 7);
      expect(
        freeTrialDays(
          introductory: true,
          phases: [phase('day', 1, periods: 3)],
        ),
        3,
      );
      // Paid intro prices, promotions and multi-phase offers are no trial.
      expect(
        freeTrialDays(
          introductory: true,
          phases: [phase('day', 3, free: false)],
        ),
        isNull,
      );
      expect(
        freeTrialDays(introductory: false, phases: [phase('day', 3)]),
        isNull,
      );
      expect(
        freeTrialDays(
          introductory: true,
          phases: [phase('day', 3), phase('month', 1, free: false)],
        ),
        isNull,
      );
      expect(
        freeTrialDays(introductory: true, phases: [phase('month', 1)]),
        isNull,
      );
    });

    test('per-month price written like the store price', () {
      PurchaseProduct product(String price) => PurchaseProduct(
        productId: 'y',
        plan: PurchasePlan.yearly,
        localizedPrice: price,
        localizedPeriod: null,
        isRecommended: true,
      );
      expect(product('49,99 €').formatLike(49.99 / 12), '4,17 €');
      expect(product(r'$39.99').formatLike(39.99 / 12), r'$3.33');
      expect(product('CHF 49.00').formatLike(4.0833), 'CHF 4.08');
    });
  });

  group('story shelves', () {
    Story story(String id, String topic) =>
        Story(id: id, title: id, topic: topic, level: '', readingMinutes: 2);

    test('started first, finished at the far end', () {
      final stories = [
        story('a', 'Technik'),
        story('b', 'Technik'),
        story('c', 'Technik'),
        story('d', 'Technik'),
      ];
      final order = shelfOrder(
        stories,
        progress: {'c': 0.4},
        finished: {'a'},
      ).map((s) => s.id);
      expect(order, ['c', 'b', 'd', 'a']);
    });

    test('Home mixes the categories instead of grouping them', () {
      final stories = [
        story('g1', 'Gesellschaft'),
        story('g2', 'Gesellschaft'),
        story('g3', 'Gesellschaft'),
        story('w1', 'Wissenschaft'),
        story('w2', 'Wissenschaft'),
        story('t1', 'Technik'),
      ];
      final mixed = mixedByCategory(stories, progress: {'w2': 0.3});
      expect(mixed.first.id, 'w2');
      final topics = mixed.skip(1).take(3).map((s) => s.topic).toSet();
      expect(topics, hasLength(3));
      expect(mixed, hasLength(stories.length));
    });

    test('every bundled topic has its own colour, none falls back to grey', () {
      for (final topic in [
        'Wirtschaft',
        'Technik',
        'Wissenschaft',
        'Gesellschaft',
        'Kultur',
        'Gesundheit',
        'Kriminalfälle',
        'Reisen',
        'Restaurant',
        'Alltag',
        'Arbeit',
      ]) {
        expect(
          StoryCategory.all.map((c) => c.name),
          contains(topic),
          reason: topic,
        );
      }
    });
  });

  group('wrong answers', () {
    test('third shows the whole word until typing, fourth keeps it', () {
      final c = PracticeInputController();
      addTearDown(c.dispose);
      c.showWrong('x', 'table');
      c.showWrong('x', 'table');
      expect(c.hint, 'ta…');
      c.showWrong('x', 'table');
      expect(c.feedback, InputFeedback.prefix);
      expect(c.hint, 'table');
      expect(c.ghost, isEmpty);
      c.value = const TextEditingValue(
        text: 't',
        selection: TextSelection.collapsed(offset: 1),
      );
      expect(c.hint, isEmpty);
      c.showWrong('tx', 'table');
      expect(c.feedback, InputFeedback.ghost);
      expect(c.text, isEmpty);
      c.value = const TextEditingValue(
        text: 'ta',
        selection: TextSelection.collapsed(offset: 2),
      );
      // The ghost word stays while typing.
      expect(c.ghost, 'table');
      expect(c.text, 'ta');
      c.reset();
      expect(c.ghost, isEmpty);
    });
  });

  testWidgets(
    'word wall shows four larger light words with selective side crops',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final language in ['en', 'pt-BR', 'nb', 'it', 'es']) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: WordWall(key: ValueKey(language), lang: language),
            ),
          ),
        );
        await tester.pump(WordWall.settle);
        expect(wordsFor(language), hasLength(4));
        for (final (index, word) in wordsFor(language).indexed) {
          final finder = find.text(word);
          expect(finder, findsOneWidget);
          final text = tester.widget<Text>(finder);
          expect(text.style!.fontFamily, contains('Figtree'));
          expect(text.style!.fontWeight, FontWeight.w400);
          expect(text.style!.fontSize, greaterThan(90));
          final rect = tester.getRect(finder);
          if (index.isOdd) {
            final visible = rect.intersect(const Rect.fromLTWH(0, 0, 320, 568));
            expect(visible.width / rect.width, closeTo(0.7, 0.025));
            expect(index == 1 ? rect.right > 320 : rect.left < 0, isTrue);
          } else {
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(320));
          }
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThanOrEqualTo(568));
        }
        expect(tester.takeException(), isNull);
      }
      expect(
        find.bySemanticsLabel('Lernsprache wird gewechselt'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'word wall enters in sequence before all four words reach the center',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: const WordWall(lang: 'es'),
        ),
      );
      final firstBefore = tester.getTopLeft(find.text('Hola')).dy;
      final height = tester.getSize(find.byType(WordWall)).height;
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.getTopLeft(find.text('Hola')).dy, greaterThan(firstBefore));
      expect(find.text('Historia').hitTestable(), findsNothing);
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.text('Aprender').hitTestable(), findsNothing);
      await tester.pump(WordWall.settle - const Duration(milliseconds: 380));
      for (final word in wordsFor('es')) {
        expect(
          tester.getCenter(find.text(word)).dy,
          inExclusiveRange(0, height),
        );
      }
    },
  );

  testWidgets('word wall keeps a visible flowing drift after entry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const WordWall(lang: 'es'),
      ),
    );
    await tester.pump(WordWall.settle);
    final first = tester.getTopLeft(find.text('Hola'));
    await tester.pump(const Duration(seconds: 1));
    final second = tester.getTopLeft(find.text('Hola'));
    await tester.pump(const Duration(seconds: 1));
    final third = tester.getTopLeft(find.text('Hola'));
    expect((second - first).distance, inExclusiveRange(3, 25));
    expect((third - second).distance, inExclusiveRange(3, 25));

    // The slow loop also has no jump when its clock wraps around.
    await tester.pump(const Duration(milliseconds: 10910));
    final beforeWrap = tester.getTopLeft(find.text('Hola'));
    await tester.pump(const Duration(milliseconds: 40));
    final afterWrap = tester.getTopLeft(find.text('Hola'));
    expect((afterWrap - beforeWrap).distance, lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('word wall is still when motion is reduced', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: WordWall(lang: 'es'),
        ),
      ),
    );
    final before = [
      for (final word in wordsFor('es')) tester.getTopLeft(find.text(word)),
    ];
    await tester.pump(const Duration(seconds: 2));
    final after = [
      for (final word in wordsFor('es')) tester.getTopLeft(find.text(word)),
    ];
    expect(after, before);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
