import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/models/grammar_models.dart';
import 'package:sprachapp/models/practice_models.dart';
import 'package:sprachapp/models/practice_order.dart';
import 'package:sprachapp/models/reading_history.dart';
import 'package:sprachapp/screens/content/content_dashboard_screen.dart';
import 'package:sprachapp/screens/practice/practice_library_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';

List<ChoiceExercise> exercises(String language, PracticeKind kind) => [
  for (var i = 0; i < 4; i++)
    ChoiceExercise(
      id: '$language-${kind.name}-$i',
      kind: kind,
      title: '$language exercise $i',
      summary: 'Summary $i',
      topic: 'Topic',
      level: 1,
      prompt: 'Prompt',
      options: const ['answer', 'other'],
      answer: 'answer',
      explanation: 'Explanation',
      targetLanguage: language,
    ),
];

Widget host(Widget child) => ProviderScope(
  overrides: [premiumContentAccessProvider.overrideWithValue(true)],
  child: MaterialApp(
    theme: buildAppTheme(),
    home: Scaffold(body: child),
  ),
);

List<String> renderedTitles(WidgetTester tester, List<ChoiceExercise> items) {
  final titles = items.map((e) => e.title).toSet();
  return tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where(titles.contains)
      .toList();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final language in ['en', 'es', 'it', 'nb', 'pt-BR']) {
    for (final kind in PracticeKind.values) {
      test(
        '$language ${kind.name}: stable partition preserves original list',
        () {
          final items = exercises(language, kind);
          final original = List<ChoiceExercise>.of(items);
          final progress = PracticeProgress([items[0].id, items[2].id]);
          addTearDown(progress.dispose);
          expect(unfinishedPracticeFirst(items, progress), [
            items[1],
            items[3],
            items[0],
            items[2],
          ]);
          expect(items, orderedEquals(original));
          progress.complete(items[1].id);
          expect(unfinishedPracticeFirst(items, progress), [
            items[3],
            items[0],
            items[1],
            items[2],
          ]);
          progress.complete(items[3].id);
          expect(unfinishedPracticeFirst(items, progress), original);
          expect(unfinishedPracticeFirst(const [], progress), isEmpty);
        },
      );

      testWidgets('$language ${kind.name}: library reacts to completion', (
        t,
      ) async {
        t.view.physicalSize = const Size(500, 1200);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final items = exercises(language, kind);
        final progress = PracticeProgress([items[0].id, items[2].id]);
        addTearDown(progress.dispose);
        await t.pumpWidget(
          host(
            PracticeLibraryScreen(
              kind: kind,
              exercises: items,
              progress: progress,
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(renderedTitles(t, items), [
          items[1].title,
          items[3].title,
          items[0].title,
          items[2].title,
        ]);
        progress.complete(items[1].id);
        await t.pumpAndSettle();
        expect(renderedTitles(t, items), [
          items[3].title,
          items[0].title,
          items[1].title,
          items[2].title,
        ]);
        expect(t.takeException(), isNull);
      });

      testWidgets('$language ${kind.name}: dashboard reacts to completion', (
        t,
      ) async {
        t.view.physicalSize = const Size(800, 1200);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final items = exercises(language, kind);
        final progress = PracticeProgress([items[0].id, items[2].id]);
        final history = ReadingHistory();
        addTearDown(progress.dispose);
        addTearDown(history.dispose);
        await t.pumpWidget(
          host(
            ContentDashboardScreen(
              texts: const [],
              history: history,
              listening: kind == PracticeKind.listening ? items : const [],
              grammar: kind == PracticeKind.grammar ? items : const [],
              progress: progress,
              rules: const [],
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(renderedTitles(t, items), [
          items[1].title,
          items[3].title,
          items[0].title,
          items[2].title,
        ]);
        progress.complete(items[1].id);
        await t.pumpAndSettle();
        expect(renderedTitles(t, items), [
          items[3].title,
          items[0].title,
          items[1].title,
          items[2].title,
        ]);
        expect(t.takeException(), isNull);
      });
    }
  }

  testWidgets('Dashboard rule cards omit minutes visually and in semantics', (
    t,
  ) async {
    final progress = PracticeProgress();
    final history = ReadingHistory();
    addTearDown(progress.dispose);
    addTearDown(history.dispose);
    const rule = GrammarRule(
      id: 'rule',
      title: 'Artikel',
      summary: 'a, an und the',
      level: GrammarLevel.beginner,
      sections: [],
    );
    await t.pumpWidget(
      host(
        ContentDashboardScreen(
          texts: const [],
          history: history,
          listening: const [],
          grammar: const [],
          progress: progress,
          rules: const [rule],
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Artikel'), findsOneWidget);
    expect(find.textContaining(RegExp(r'\bMin(?:uten)?\b')), findsNothing);
    expect(
      find.bySemanticsLabel('Artikel, a, an und the, Anfänger'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Min(?:uten)?|Lesezeit')),
      findsNothing,
    );
    expect(t.takeException(), isNull);
  });
}
