import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/deck_store.dart';
import '../models/home_models.dart';
import '../models/reading_history.dart';
import '../models/sample_content.dart';
import '../models/word_list_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import 'content/content_dashboard_screen.dart';
import 'content/text_library_screen.dart';
import 'decks/deck_details_screen.dart';
import 'decks/deck_library_screen.dart';
import 'grammar/grammar_rules_screen.dart';
import 'home/home_screen.dart';
import 'home/widgets/daily_goal_sheet.dart';
import 'stories/story_library_screen.dart';
import 'stories/story_reader_screen.dart';
import 'words/word_list_screen.dart';

/// Hosts the tab screens under the notched bar, keeps each tab's scroll
/// position while switching, and owns the placeholder app state (decks,
/// daily goal) until Riverpod arrives.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _tabs = [
    AppTab.home,
    AppTab.stories,
    AppTab.words,
    AppTab.content,
  ];

  final _decks = DeckStore(sampleDecks);
  final _history = ReadingHistory(sampleReadStoryIds);
  final _words = WordListStore(sampleVocabulary(DateTime.now()));
  AppTab _tab = AppTab.home;
  DailyGoal _goal = sampleGoal;

  @override
  void dispose() {
    _decks.dispose();
    _history.dispose();
    _words.dispose();
    super.dispose();
  }

  void _select(AppTab tab) => setState(() => _tab = tab);

  void _openStory(Story story) {
    _history.markRead(story.id);
    StoryReaderScreen.open(context, story);
  }

  void _browseDecks() =>
      DeckLibraryScreen.open(context, decks: _decks, onOpenDeck: _openDeck);

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
    // TODO: build these categories.
    const ContentCategory(title: 'Hören', icon: CupertinoIcons.headphones),
    const ContentCategory(title: 'Grammatik', icon: CupertinoIcons.textformat),
    ContentCategory(
      title: 'Grammatikregeln',
      icon: CupertinoIcons.book,
      detail: '${sampleGrammarRules.length} Regeln',
      onOpen: () => GrammarRulesScreen.open(context, sampleGrammarRules),
    ),
  ];

  void _openDeck(Deck deck) => DeckDetailsScreen.open(context, _decks, deck.id);

  Future<void> _editGoal() async {
    final target = await DailyGoalSheet.show(context, current: _goal.target);
    if (target == null || !mounted) return;
    setState(() => _goal = DailyGoal(done: _goal.done, target: target));
  }

  // TODO: route to the mixed practice session, profile and settings once
  // they exist.
  void _notYetRouted() {}

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.raisedInk,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: IndexedStack(
          index: _tabs.indexOf(_tab),
          children: [
            HomeScreen(
              decks: _decks,
              goal: _goal,
              week: sampleWeek,
              onOpenStory: _openStory,
              onBrowseStories: () => _select(AppTab.stories),
              onOpenDeck: _openDeck,
              onBrowseDecks: _browseDecks,
              onEditGoal: _editGoal,
              onProfile: _notYetRouted,
              onSettings: _notYetRouted,
            ),
            StoryLibraryScreen(
              stories: sampleStories,
              continueReading: sampleContinueReading,
              onOpenStory: _openStory,
            ),
            WordListScreen(store: _words),
            ContentDashboardScreen(
              decks: _decks,
              categories: _categories,
              onOpenDeck: _openDeck,
              onBrowseDecks: _browseDecks,
            ),
          ],
        ),
        floatingActionButton: PracticeButton(
          goal: _goal,
          onPressed: _notYetRouted,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: AppBottomBar(
          current: _tab,
          onTabSelected: _select,
          onStartPractice: _notYetRouted,
        ),
      ),
    );
  }
}
