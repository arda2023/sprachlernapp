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
        freeTrialDays(introductory: true, phases: [phase('day', 3, free: false)]),
        isNull,
      );
      expect(freeTrialDays(introductory: false, phases: [phase('day', 3)]), isNull);
      expect(
        freeTrialDays(
          introductory: true,
          phases: [phase('day', 3), phase('month', 1, free: false)],
        ),
        isNull,
      );
      expect(freeTrialDays(introductory: true, phases: [phase('month', 1)]), isNull);
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

  testWidgets('word wall builds the target language words', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const WordWall(lang: 'es'),
      ),
    );
    await tester.pumpAndSettle();
    for (final word in wordsFor('es')) {
      expect(find.text(word), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Lernsprache wird gewechselt'), findsOneWidget);
  });
}
