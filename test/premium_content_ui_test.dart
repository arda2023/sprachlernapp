import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/domain/preferences.dart';
import 'package:sprachapp/models/grammar_models.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/news_models.dart';
import 'package:sprachapp/models/practice_models.dart';
import 'package:sprachapp/models/reading_history.dart';
import 'package:sprachapp/models/sample_content.dart';
import 'package:sprachapp/presentation/providers/premium_access_provider.dart';
import 'package:sprachapp/presentation/providers/preferences_provider.dart';
import 'package:sprachapp/presentation/providers/purchase_provider.dart';
import 'package:sprachapp/presentation/providers/reading_providers.dart';
import 'package:sprachapp/screens/content/content_dashboard_screen.dart';
import 'package:sprachapp/screens/content/text_library_screen.dart';
import 'package:sprachapp/screens/content/widgets/exercise_choice_sheet.dart';
import 'package:sprachapp/screens/content/widgets/text_exercise_shelf.dart';
import 'package:sprachapp/screens/grammar/grammar_rule_detail_screen.dart';
import 'package:sprachapp/screens/home/widgets/story_carousel.dart';
import 'package:sprachapp/screens/onboarding/paywall_screen.dart';
import 'package:sprachapp/screens/stories/story_library_screen.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/premium_content_gate.dart';
import 'package:sprachapp/widgets/story_cover.dart';

class _MemoryPreferencesController extends PreferencesController {
  @override
  Future<PracticePreferences> build() async => const PracticePreferences();
}

class _IdlePurchaseController extends PurchaseController {
  @override
  PurchaseState build() => const PurchaseState();

  @override
  Future<void> load() async {}
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  void phone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
  }

  Widget host(Widget child, {bool premium = false, double scale = 1}) =>
      ProviderScope(
        overrides: [
          premiumContentAccessProvider.overrideWithValue(premium),
          preferencesProvider.overrideWith(
            () => _MemoryPreferencesController(),
          ),
          purchaseProvider.overrideWith(() => _IdlePurchaseController()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: true,
            ),
            child: child!,
          ),
          home: Scaffold(body: child),
        ),
      );

  const story = Story(
    id: 'test-story',
    title: 'A story to read',
    topic: 'Alltag',
    level: 'A2',
    readingMinutes: 3,
  );
  const rule = GrammarRule(
    id: 'rule',
    title: 'Freie Grammatikregel',
    summary: 'Eine Erklärung',
    level: GrammarLevel.beginner,
    sections: [],
  );

  testWidgets(
    'a locked StoryCard invokes the upgrade, never its reading action',
    (t) async {
      phone(t);
      var reads = 0, upgrades = 0;
      await t.pumpWidget(
        host(
          Center(
            child: StoryCard(
              story: story,
              onTap: () => reads++,
              premiumLocked: true,
              onUpgrade: () => upgrades++,
            ),
          ),
        ),
      );
      await t.tap(find.byType(StoryCard));
      expect(reads, 0);
      expect(upgrades, 1);
      expect(find.byType(PremiumLockBadge), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('mit Premium freischalten')),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('news remain free while saved own texts open the Premium offer', (
    t,
  ) async {
    phone(t);
    var newsReads = 0, ownReads = 0;
    await t.pumpWidget(
      host(
        StoryLibraryScreen(
          stories: const [story],
          onOpenStory: (_) {},
          news: const [
            NewsArticle(
              id: 'news',
              category: NewsCategory.economy,
              title: 'Freie Nachricht',
              level: 'A2',
              readingMinutes: 2,
              sections: [],
            ),
          ],
          onOpenNews: (_) => newsReads++,
          imported: [
            ImportedText(
              id: 'own',
              title: 'Mein gespeicherter Text',
              body: 'A text.',
              source: ImportSource.pasted,
              createdAt: DateTime(2026, 11, 1),
            ),
          ],
          onOpenImported: (_) => ownReads++,
        ),
      ),
    );
    expect(find.byType(PremiumUnlockCard), findsNothing);
    expect(find.text('Alle Stories freischalten'), findsNothing);
    await t.tap(find.text('Freie Nachricht').hitTestable().first);
    expect(newsReads, 1);
    final own = find.text('Mein gespeicherter Text');
    await t.scrollUntilVisible(
      own,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.ensureVisible(own);
    await t.pumpAndSettle();
    await t.tap(own);
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(ownReads, 0);
    expect(find.byType(PaywallScreen), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Economy and everyday shelves use large covers instead of ranked rows',
    (t) async {
      phone(t);
      final stories = [
        for (final topic in [
          'Gesellschaft',
          'Wissenschaft',
          'Wirtschaft',
          'Technik',
          'Reisen',
          'Restaurant',
          'Alltag',
        ])
          for (var i = 0; i < 3; i++)
            Story(
              id: '$topic-$i',
              title: '$topic story $i',
              topic: topic,
              level: 'A2',
              readingMinutes: 3,
            ),
      ];
      await t.pumpWidget(
        host(
          StoryLibraryScreen(stories: stories, onOpenStory: (_) {}),
          premium: true,
        ),
      );
      for (final topic in ['Wirtschaft', 'Alltag']) {
        final card = find.byWidgetPredicate(
          (w) => w is StoryCard && w.story.id == '$topic-0',
        );
        await t.scrollUntilVisible(
          card,
          240,
          scrollable: find.byType(Scrollable).first,
        );
        final widget = t.widget<StoryCard>(card);
        expect(widget.height, greaterThanOrEqualTo(180));
        expect(widget.width, greaterThanOrEqualTo(150));
      }
      expect(find.byType(StoryListShelf), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'compact text exercises have no images, grow at 2x, and stay locked',
    (t) async {
      phone(t);
      final history = ReadingHistory();
      final progress = PracticeProgress();
      addTearDown(history.dispose);
      addTearDown(progress.dispose);
      await t.pumpWidget(
        host(
          ContentDashboardScreen(
            texts: sampleExerciseTexts,
            history: history,
            listening: const [],
            grammar: const [],
            progress: progress,
            rules: const [],
          ),
          scale: 2,
        ),
      );
      expect(find.byType(PremiumUnlockCard), findsNothing);
      expect(find.text('Alle Übungen freischalten'), findsNothing);
      final shelf = find.byType(TextExerciseShelf);
      await t.scrollUntilVisible(
        shelf,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(of: shelf, matching: find.byType(StoryCover)),
        findsNothing,
      );
      expect(
        find.descendant(of: shelf, matching: find.byType(Image)),
        findsNothing,
      );
      expect(find.byType(PremiumLockBadge), findsWidgets);
      expect(t.takeException(), isNull);
      final text = find.text(sampleExerciseTexts.first.info.title);
      await t.ensureVisible(text);
      await t.pumpAndSettle();
      await t.tap(text);
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.byType(ExerciseChoiceSheet), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  for (final kind in PracticeKind.values) {
    testWidgets('${kind.name} exercises and More open Premium while locked', (
      t,
    ) async {
      phone(t);
      final history = ReadingHistory();
      final progress = PracticeProgress();
      addTearDown(history.dispose);
      addTearDown(progress.dispose);
      final items = kind == PracticeKind.listening
          ? sampleListeningExercises
          : sampleGrammarExercises;
      Widget dashboard() => ContentDashboardScreen(
        texts: const [],
        history: history,
        listening: kind == PracticeKind.listening ? items : const [],
        grammar: kind == PracticeKind.grammar ? items : const [],
        progress: progress,
        rules: const [],
      );
      for (final more in [false, true]) {
        await t.pumpWidget(host(dashboard()));
        await t.pump();
        final target = more
            ? find.text('Mehr anzeigen')
            : find.text(items.first.title);
        await t.scrollUntilVisible(
          target,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await t.tap(target);
        await t.pump();
        await t.pump(const Duration(seconds: 1));
        expect(find.byType(PaywallScreen), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox.shrink());
      }
    });
  }

  testWidgets('grammar rules stay free at double text size', (t) async {
    phone(t);
    final history = ReadingHistory();
    final progress = PracticeProgress();
    addTearDown(history.dispose);
    addTearDown(progress.dispose);
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
        scale: 2,
      ),
    );
    final title = find.text(rule.title);
    await t.scrollUntilVisible(
      title,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.ensureVisible(title);
    await t.pumpAndSettle();
    await t.tap(title);
    await t.pumpAndSettle();
    expect(find.byType(GrammarRuleDetailScreen), findsOneWidget);
    expect(find.byType(PaywallScreen), findsNothing);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'direct text start checks Premium before showing exercise choices',
    (t) async {
      phone(t);
      await t.pumpWidget(
        host(
          Builder(
            builder: (context) => CupertinoButton(
              onPressed: () =>
                  TextLibraryScreen.start(context, sampleExerciseTexts.first),
              child: const Text('Text starten'),
            ),
          ),
        ),
      );
      await t.tap(find.text('Text starten'));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(find.byType(PaywallScreen), findsOneWidget);
      expect(find.byType(ExerciseChoiceSheet), findsNothing);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Premium allows text exercise choices', (t) async {
    phone(t);
    await t.pumpWidget(
      host(
        Builder(
          builder: (context) => CupertinoButton(
            onPressed: () =>
                TextLibraryScreen.start(context, sampleExerciseTexts.first),
            child: const Text('Text starten'),
          ),
        ),
        premium: true,
      ),
    );
    await t.tap(find.text('Text starten'));
    await t.pumpAndSettle();
    expect(find.byType(ExerciseChoiceSheet), findsOneWidget);
    expect(find.byType(PaywallScreen), findsNothing);
    expect(t.takeException(), isNull);
  });
}
