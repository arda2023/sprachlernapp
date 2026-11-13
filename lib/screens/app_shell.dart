import '../models/localized_practice_content.dart';
import '../domain/app_launch_intent.dart';
import '../presentation/providers/app_launch_intent_provider.dart';
import '../presentation/providers/premium_access_provider.dart';
import '../presentation/providers/purchase_provider.dart';
import 'content/topic_vocabulary_composer.dart';
import '../domain/language_profile.dart';
import '../presentation/providers/database_providers.dart';
import '../presentation/providers/language_selection_provider.dart';
import '../presentation/content_unavailable_view.dart';
import 'settings/content_updates_screen.dart';
import 'settings/settings_screen.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/home_models.dart';
import '../models/practice_models.dart';
import '../models/reading_history.dart';
import '../models/sample_content.dart';
import '../presentation/providers/reading_providers.dart';
import '../presentation/providers/learning_providers.dart';
import '../presentation/providers/story_learning_providers.dart';
import '../presentation/providers/preferences_provider.dart';
import 'decks/deck_practice_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_bar.dart';
import 'content/content_dashboard_screen.dart';
import 'decks/deck_details_screen.dart';
import 'decks/deck_library_screen.dart';
import 'home/home_screen.dart';
import 'stories/story_library_screen.dart';
import 'stories/story_collection_screen.dart';
import 'words/word_list_screen.dart';
import 'shell_reading_actions.dart';

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
  final _scroll = {for (final t in _tabs) t: ScrollController()};
  bool _launchScheduled = false;

  void _tryLaunch(PendingAppLaunch? launch) {
    if (launch == null || !mounted || !_launchReady(launch)) return;
    _scheduleLaunch();
  }

  bool _launchReady(PendingAppLaunch launch) {
    final selected = ref.read(selectedContentLanguageProvider);
    if (selected.isLoading || ref.read(languageSelectionProvider).switching) {
      return false;
    }
    final info = selected.asData?.value == 'en'
        ? null
        : ref.read(contentInfoProvider);
    if (info?.isLoading == true) return false;
    if (launch.intent.target == AppLaunchTarget.story &&
        launch.intent.language == selected.asData?.value) {
      final purchase = ref.read(purchaseProvider);
      if (purchase.phase.isBusy || purchase.isSyncing) return false;
      if (ref.read(premiumContentAccessProvider) &&
          (ref.read(libraryStoriesProvider).isLoading ||
              ref.read(readingProgressReadyProvider).isLoading)) {
        return false;
      }
    }
    return true;
  }

  void _scheduleLaunch() {
    if (_launchScheduled) return;
    _launchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchScheduled = false;
      if (!mounted) return;
      // Recheck the latest tap and store after a possible account/language change.
      final launch = ref.read(appLaunchIntentProvider);
      if (launch == null || !_launchReady(launch)) return;
      if (!ref.read(appLaunchIntentProvider.notifier).consume(launch)) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() => _tab = AppTab.home);
      final selected = ref.read(selectedContentLanguageProvider);
      final info = selected.asData?.value == 'en'
          ? null
          : ref.read(contentInfoProvider);
      final canPractice = !selected.hasError && info?.hasError != true;
      if (launch.intent.target == AppLaunchTarget.practice && canPractice) {
        _startMixed();
      } else if (launch.intent.target == AppLaunchTarget.story &&
          canPractice &&
          launch.intent.language ==
              ref.read(selectedContentLanguageProvider).asData?.value &&
          ref.read(premiumContentAccessProvider) &&
          ref.read(readingProgressReadyProvider).asData != null) {
        final stories = ref.read(libraryStoriesProvider).asData?.value;
        final story = stories
            ?.where((story) => story.id == launch.intent.storyId)
            .firstOrNull;
        if (story != null) _openStory(story);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    for (final c in _scroll.values) {
      c.dispose();
    }
    _history.dispose();
    _practice.dispose();
    super.dispose();
  }

  /// Re-tapping the active tab scrolls it to the top; other tabs keep
  /// their position.
  void _select(AppTab tab) {
    if (tab != _tab) {
      setState(() => _tab = tab);
      return;
    }
    final c = _scroll[tab]!;
    if (!c.hasClients || c.offset <= c.position.minScrollExtent) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      c.jumpTo(0);
    } else {
      c.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openStory(Story story) => openStoryFromShell(
    context,
    ref,
    story,
    isMounted: () => mounted,
    onOpened: _history.markRead,
  );

  void _openImported(ImportedText text) =>
      openImportedFromShell(context, ref, text, isMounted: () => mounted);

  String? _importText(String text) => importTextFromShell(ref, text);

  void _browseDecks() => DeckLibraryScreen.open(context, onOpenDeck: _openDeck);

  void _openDeck(Deck deck) => DeckDetailsScreen.open(context, deck.id);

  Future<void> _setGoal(int target) async {
    try {
      final preferences = await ref.read(preferencesProvider.future);
      if (target == preferences.dailyGoal) return;
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

  Future<void> _startMixed() async {
    if (ref.read(languageSelectionProvider).switching) return;
    final lang = ref.read(selectedContentLanguageProvider);
    if (lang.isLoading && lang.hasValue) return;
    if (lang.asData?.value != 'en') {
      final content = ref.read(contentInfoProvider);
      if (content.isLoading || content.hasError) return;
    }
    DeckPracticeScreen.open(context, deckId: '', mode: DeckPracticeMode.mixed);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(languageSelectionProvider, (_, selection) {
      if (selection.message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(selection.message!)));
      }
    });
    ref.listen(uiStorageErrorProvider, (_, error) {
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lesestand oder Text nicht gespeichert. Bitte erneut versuchen.',
            ),
          ),
        );
      }
    });
    final selected = ref.watch(selectedContentLanguageProvider);
    final lang = selected.asData?.value ?? 'en';
    final hasEnglishSamples = lang == 'en';
    final switching =
        ref.watch(languageSelectionProvider).switching ||
        selected.isLoading && selected.hasValue;
    final info = !hasEnglishSamples ? ref.watch(contentInfoProvider) : null;
    final unavailable =
        !hasEnglishSamples && (info!.isLoading || info.hasError);
    // Notification taps also need to reach the shell beneath a pushed route.
    // Riverpod pauses watch subscriptions there, while listen stays active.
    ref.listen(appLaunchIntentProvider, (_, launch) => _tryLaunch(launch));
    ref.listen(selectedContentLanguageProvider, (_, _) {
      _tryLaunch(ref.read(appLaunchIntentProvider));
    });
    ref.listen(languageSelectionProvider, (_, _) {
      _tryLaunch(ref.read(appLaunchIntentProvider));
    });
    ref.listen(contentInfoProvider, (_, _) {
      _tryLaunch(ref.read(appLaunchIntentProvider));
    });
    ref.listen(libraryStoriesProvider, (_, _) {
      _tryLaunch(ref.read(appLaunchIntentProvider));
    });
    ref.listen(readingProgressReadyProvider, (_, _) {
      _tryLaunch(ref.read(appLaunchIntentProvider));
    });
    ref.listen(purchaseProvider, (_, _) {
      _tryLaunch(ref.read(appLaunchIntentProvider));
    });
    _tryLaunch(ref.read(appLaunchIntentProvider));
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
        body: switching
            ? const Center(child: CircularProgressIndicator())
            : unavailable
            ? SafeArea(
                child: ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Text(
                        ContentLanguageProfile.forLanguage(lang)!.displayName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () => SettingsScreen.open(context),
                      child: const Text('Lernsprache ändern'),
                    ),
                    if (info.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      ContentUnavailableView(
                        error: info.error!,
                        onRetry: () =>
                            ref.invalidate(contentRepositoryProvider),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ContentUpdatesScreen(),
                          ),
                        ),
                        child: const Text('Zu Inhaltsupdates'),
                      ),
                    ],
                  ],
                ),
              )
            : IndexedStack(
                index: _tabs.indexOf(_tab),
                children: [
                  TickerMode(
                    enabled: _tab == AppTab.home,
                    child: HomeScreen(
                      onOpenStory: _openStory,
                      onBrowseStories: () => _select(AppTab.stories),
                      onOpenDeck: _openDeck,
                      onBrowseDecks: _browseDecks,
                      onSetGoal: _setGoal,
                      onSettings: () => SettingsScreen.open(context),
                      scrollController: _scroll[AppTab.home],
                    ),
                  ),
                  StoryLibraryScreen(
                    scrollController: _scroll[AppTab.stories],
                    collection: const StoryCollectionEntry(),
                    stories: ref.watch(libraryStoriesProvider).isLoading
                        ? []
                        : ref.watch(libraryStoriesProvider).asData?.value ?? [],
                    progress: ref.watch(readingProgressProvider),
                    imported: ref.watch(importedTextsProvider),
                    onOpenImported: _openImported,
                    onDeleteImported: (text) => ref
                        .read(importedTextsProvider.notifier)
                        .remove(text.id),
                    onImportText: _importText,
                    onImported: () {
                      final texts = ref.read(importedTextsProvider);
                      if (texts.isNotEmpty) _openImported(texts.first);
                    },

                    status: ref
                        .watch(libraryStoriesProvider)
                        .when(
                          skipLoadingOnReload: false,
                          skipLoadingOnRefresh: false,
                          data: (stories) => stories.isEmpty
                              ? Text(
                                  'Für ${ContentLanguageProfile.forLanguage(lang)!.displayName} sind noch keine Stories verfügbar.',
                                )
                              : const SizedBox.shrink(),
                          loading: () => const CupertinoActivityIndicator(),
                          error: (_, _) => CupertinoButton(
                            onPressed: () =>
                                ref.invalidate(storySummariesProvider),
                            child: const Text(
                              'Stories nicht verfügbar · Erneut versuchen',
                            ),
                          ),
                        ),
                    onOpenStory: _openStory,
                    // No "Nachrichten" for now: the section returns later
                    // with the daily news (user decision 01.11.2026,
                    // docs/daily-news.md).
                  ),
                  TickerMode(
                    enabled: _tab == AppTab.words,
                    child: WordListScreen(
                      scrollController: _scroll[AppTab.words],
                    ),
                  ),
                  ContentDashboardScreen(
                    scrollController: _scroll[AppTab.content],
                    texts: hasEnglishSamples
                        ? sampleExerciseTexts
                        : localizedPracticeContent[lang]!.texts,
                    history: _history,
                    listening: hasEnglishSamples
                        ? sampleListeningExercises
                        : localizedPracticeContent[lang]!.listening,
                    grammar: hasEnglishSamples
                        ? sampleGrammarExercises
                        : localizedPracticeContent[lang]!.grammar,
                    progress: _practice,
                    rules: hasEnglishSamples
                        ? sampleGrammarRules
                        : localizedPracticeContent[lang]!.rules,
                    generator: TopicVocabularyComposer(
                      key: ValueKey('generate:$lang'),
                      lang: lang,
                    ),
                  ),
                ],
              ),
        floatingActionButton:
            switching ||
                unavailable ||
                MediaQuery.viewInsetsOf(context).bottom > 0
            ? null
            : ref
                  .watch(learningProgressProvider)
                  .when(
                    data: (p) =>
                        PracticeButton(goal: p.goal, onPressed: _startMixed),
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
