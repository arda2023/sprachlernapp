import 'settings/settings_screen.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_models.dart';
import '../models/practice_models.dart';
import '../models/reading_history.dart';
import '../models/sample_content.dart';
import '../presentation/providers/learning_providers.dart';
import '../presentation/providers/story_learning_providers.dart';
import '../presentation/providers/preferences_provider.dart';
import 'decks/deck_practice_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import 'content/content_dashboard_screen.dart';
import 'content/text_library_screen.dart';
import 'decks/deck_details_screen.dart';
import 'decks/deck_library_screen.dart';
import 'grammar/grammar_rules_screen.dart';
import 'home/home_screen.dart';
import 'home/widgets/daily_goal_sheet.dart';
import 'practice/practice_library_screen.dart';
import 'stories/story_library_screen.dart';
import 'stories/story_reader_screen.dart';
import 'words/word_list_screen.dart';

/// Hosts the tab screens under the notched bar, keeps each tab's scroll
/// position while switching. Non-deck features retain their existing stores.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  static const _tabs = [
    AppTab.home,
    AppTab.stories,
    AppTab.words,
    AppTab.content,
  ];

  final _history = ReadingHistory(sampleReadStoryIds);
  final _practice = PracticeProgress(sampleCompletedPracticeIds);
  AppTab _tab = AppTab.home;

  @override
  void dispose() {
    _history.dispose();
    _practice.dispose();
    super.dispose();
  }

  void _select(AppTab tab) => setState(() => _tab = tab);

  void _openStory(Story story) {
    _history.markRead(story.id);
    StoryReaderScreen.open(context, story);
  }

  void _browseDecks() => DeckLibraryScreen.open(context, onOpenDeck: _openDeck);

  void _openTexts() => TextLibraryScreen.open(
    context,
    texts: sampleExerciseTexts,
    history: _history,
  );

  List<ContentCategory> get _categories => [
    ContentCategory(
      title: 'Texte',
      icon: CupertinoIcons.doc_text,
      detail: '${sampleExerciseTexts.length} Texte',
      onOpen: _openTexts,
    ),
    ContentCategory(
      title: 'Hören',
      icon: CupertinoIcons.headphones,
      detail: '${sampleListeningExercises.length} Übungen',
      onOpen: () => PracticeLibraryScreen.open(
        context,
        kind: PracticeKind.listening,
        exercises: sampleListeningExercises,
        progress: _practice,
      ),
    ),
    ContentCategory(
      title: 'Grammatik',
      icon: CupertinoIcons.textformat,
      detail: '${sampleGrammarExercises.length} Übungen',
      onOpen: () => PracticeLibraryScreen.open(
        context,
        kind: PracticeKind.grammar,
        exercises: sampleGrammarExercises,
        progress: _practice,
      ),
    ),
    ContentCategory(
      title: 'Grammatikregeln',
      icon: CupertinoIcons.book,
      detail: '${sampleGrammarRules.length} Regeln',
      onOpen: () => GrammarRulesScreen.open(context, sampleGrammarRules),
    ),
  ];

  void _openDeck(Deck deck) => DeckDetailsScreen.open(context, deck.id);

  Future<void> _editGoal() async {
    try {
      final preferences = await ref.read(preferencesProvider.future);
      if (!mounted) return;
      final target = await DailyGoalSheet.show(
        context,
        current: preferences.dailyGoal,
      );
      if (target == null || !mounted) return;
      await ref
          .read(preferencesProvider.notifier)
          .save(preferences.copyWith(dailyGoal: target));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tagesziel nicht geladen oder gespeichert. Bitte erneut versuchen.',
            ),
          ),
        );
      }
    }
  }

  // Profile remains outside this integration.
  void _notYetRouted() {}
  void _startMixed() => DeckPracticeScreen.open(
    context,
    deckId: '',
    mode: DeckPracticeMode.mixed,
  );

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (context.appColors.light
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light)
              .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: context.appColors.raisedInk,
                systemNavigationBarIconBrightness: Brightness.light,
              ),
      child: Scaffold(
        body: IndexedStack(
          index: _tabs.indexOf(_tab),
          children: [
            HomeScreen(
              goal: null,
              week: null,
              onOpenStory: _openStory,
              onBrowseStories: () => _select(AppTab.stories),
              onOpenDeck: _openDeck,
              onBrowseDecks: _browseDecks,
              onEditGoal: _editGoal,
              onProfile: _notYetRouted,
              onSettings: () => SettingsScreen.open(context),
            ),
            StoryLibraryScreen(
              stories: ref.watch(libraryStoriesProvider).value ?? [],

              status: ref
                  .watch(libraryStoriesProvider)
                  .when(
                    data: (stories) => stories.isEmpty
                        ? const Text('Noch keine Stories im Inhaltspaket.')
                        : const SizedBox.shrink(),
                    loading: () => const CupertinoActivityIndicator(),
                    error: (_, _) => CupertinoButton(
                      onPressed: () => ref.invalidate(storySummariesProvider),
                      child: const Text(
                        'Stories nicht verfügbar · Erneut versuchen',
                      ),
                    ),
                  ),
              onOpenStory: _openStory,
              news: sampleNews,
              onOpenNews: (article) =>
                  StoryReaderScreen.openNews(context, article),
            ),
            const WordListScreen(),
            ContentDashboardScreen(categories: _categories),
          ],
        ),
        floatingActionButton: ref
            .watch(learningProgressProvider)
            .when(
              data: (p) => PracticeButton(goal: p.goal, onPressed: _startMixed),
              loading: () => null,
              error: (_, _) => null,
            ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AppBottomBar(
          current: _tab,
          onTabSelected: _select,
          onStartPractice: _startMixed,
        ),
      ),
    );
  }
}
