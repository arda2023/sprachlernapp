import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/language_profile.dart';
import '../../presentation/providers/language_selection_provider.dart';
import '../../widgets/popover_trigger.dart';
import '../home/widgets/language_panel.dart';
import '../../models/home_models.dart';
import '../../presentation/providers/learning_sync_provider.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/providers/reading_providers.dart';
import '../../presentation/providers/story_learning_providers.dart';
import '../../theme/app_theme.dart';
import '../decks/deck_details_screen.dart';
import '../decks/deck_practice_screen.dart';
import '../decks/deck_library_screen.dart';
import '../settings/settings_screen.dart';
import '../stories/story_library_screen.dart';
import '../shell_reading_actions.dart';

/// Browser workspace: existing learning screens and repositories, two destinations.
class WebLearningShell extends ConsumerStatefulWidget {
  const WebLearningShell({super.key});
  @override
  ConsumerState<WebLearningShell> createState() => _WebLearningShellState();
}

class _WebLearningShellState extends ConsumerState<WebLearningShell> {
  int _selected = 0;
  bool _startingPractice = false;
  final _readerScroll = ScrollController();
  @override
  void dispose() {
    _readerScroll.dispose();
    super.dispose();
  }

  void _openStory(Story story) =>
      openStoryFromShell(context, ref, story, isMounted: () => mounted);

  void _openImported(ImportedText text) =>
      openImportedFromShell(context, ref, text, isMounted: () => mounted);

  String? _importText(String text) => importTextFromShell(ref, text);

  Future<void> _startMixed() async {
    if (_startingPractice || ref.read(languageSelectionProvider).switching) {
      return;
    }
    final language = ref.read(selectedContentLanguageProvider);
    if (language.isLoading || language.hasError) return;
    final selectedLanguage = language.requireValue;
    _startingPractice = true;
    try {
      await ref.read(contentInfoProvider.future);
      if (!mounted ||
          ref.read(languageSelectionProvider).switching ||
          ref.read(selectedContentLanguageProvider).asData?.value !=
              selectedLanguage) {
        return;
      }
      await DeckPracticeScreen.open(
        context,
        deckId: '',
        mode: DeckPracticeMode.mixed,
      );
    } catch (_) {
      if (mounted &&
          !ref.read(languageSelectionProvider).switching &&
          ref.read(selectedContentLanguageProvider).asData?.value ==
              selectedLanguage) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Übung konnte nicht geöffnet werden. Bitte erneut versuchen.',
            ),
          ),
        );
      }
    } finally {
      _startingPractice = false;
    }
  }

  void _openDeck(Deck deck) => DeckDetailsScreen.open(context, deck.id);

  @override
  Widget build(BuildContext context) {
    final selection = ref.watch(languageSelectionProvider);
    final stories = selection.switching
        ? const AsyncValue<List<Story>>.loading()
        : ref.watch(libraryStoriesProvider);
    ref.listen(languageSelectionProvider, (_, next) {
      if (next.message != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.message!)));
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
    return WebWorkspaceFrame(
      selectedIndex: _selected,
      onPractice: selection.switching ? null : _startMixed,
      status: const _SyncStatus(),
      languageSelector: const WebLanguageSelector(),
      onSelect: (index) {
        if (_selected == index && index == 0 && _readerScroll.hasClients) {
          if (MediaQuery.disableAnimationsOf(context)) {
            _readerScroll.jumpTo(0);
          } else {
            _readerScroll.animateTo(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        }
        setState(() => _selected = index);
      },
      onSettings: () => SettingsScreen.open(context),
      child: selection.switching
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selected,
              children: [
                StoryLibraryScreen(
                  scrollController: _readerScroll,
                  stories: stories.asData?.value ?? [],
                  progress: ref.watch(readingProgressProvider),
                  imported: ref.watch(importedTextsProvider),
                  onOpenStory: _openStory,
                  onOpenImported: _openImported,
                  onImportText: _importText,
                  onDeleteImported: (text) =>
                      ref.read(importedTextsProvider.notifier).remove(text.id),
                  onImported: () {
                    final texts = ref.read(importedTextsProvider);
                    if (texts.isNotEmpty) _openImported(texts.first);
                  },
                  status: stories.when(
                    data: (items) => items.isEmpty
                        ? const Text(
                            'Noch keine Stories in dieser Sprache verfügbar.',
                          )
                        : const SizedBox.shrink(),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => TextButton(
                      onPressed: () => ref.invalidate(storySummariesProvider),
                      child: const Text('Stories erneut laden'),
                    ),
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: DeckLibraryScreen(onOpenDeck: _openDeck),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Layout is kept separate so all breakpoints can be tested without a backend.
class WebWorkspaceFrame extends StatelessWidget {
  const WebWorkspaceFrame({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onSettings,
    required this.child,
    this.onPractice,
    this.status,
    this.languageSelector,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onSettings;
  final VoidCallback? onPractice;
  final Widget child;
  final Widget? status;
  final Widget? languageSelector;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final navigation = [
          _destination(context, 0, Icons.auto_stories_outlined, 'Lesemodus'),
          _destination(context, 1, Icons.layers_outlined, 'Stapel'),
        ];
        final settings = IconButton(
          tooltip: 'Konto und Einstellungen',
          onPressed: onSettings,
          icon: const Icon(Icons.settings_outlined),
        );
        return Scaffold(
          backgroundColor: colors.nightPage,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (wide)
                  Container(
                    key: const ValueKey('web-sidebar'),
                    width: 240,
                    color: colors.raisedInk,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        Text(
                          'Linglossa',
                          style: AppType.editorial(
                            size: 28,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ?languageSelector,
                        const SizedBox(height: 20),
                        ...navigation,
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: onPractice,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Alle aktiven Stapel üben'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(44, 52),
                            backgroundColor: colors.active,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        ?status,
                        const SizedBox(height: 12),
                        Align(alignment: Alignment.centerLeft, child: settings),
                      ],
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      if (!wide)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Linglossa',
                                  style: AppType.editorial(
                                    size: 24,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                              settings,
                            ],
                          ),
                        ),
                      if (!wide && languageSelector != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: languageSelector!,
                            ),
                          ),
                        ),
                      if (!wide && status != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: status!,
                        ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1080),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: wide ? 24 : 0,
                                vertical: wide ? 24 : 0,
                              ),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    key: const ValueKey('web-bottom-navigation'),
                    color: colors.raisedInk,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: navigation[0]),
                        IconButton.filled(
                          tooltip: 'Alle aktiven Stapel üben',
                          onPressed: onPractice,
                          icon: const Icon(Icons.play_arrow_rounded, size: 30),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(52, 52),
                            backgroundColor: colors.active,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        Expanded(child: navigation[1]),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _destination(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final colors = context.appColors;
    final selected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Semantics(
        selected: selected,
        child: TextButton.icon(
          onPressed: () => onSelect(index),
          icon: Icon(icon, size: 22),
          label: Text(label),
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 52),
            foregroundColor: selected ? colors.active : colors.textPrimary,
            backgroundColor: selected
                ? colors.active.withValues(alpha: 0.12)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ),
    );
  }
}

class _SyncStatus extends ConsumerWidget {
  const _SyncStatus();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(learningSyncProvider);
    final (icon, label) = switch (phase) {
      LearningSyncPhase.syncing => (Icons.sync, 'Lernstand wird abgeglichen'),
      LearningSyncPhase.current => (
        Icons.cloud_done_outlined,
        'Lernstand abgeglichen',
      ),
      LearningSyncPhase.offline => (
        Icons.cloud_off_outlined,
        'Abgleich ausstehend',
      ),
      LearningSyncPhase.accountMismatch => (
        Icons.person_outline,
        'Konto erneut prüfen',
      ),
      LearningSyncPhase.signedOut => (
        Icons.hourglass_empty,
        'Lernstand wird geladen',
      ),
    };
    return Semantics(
      liveRegion: true,
      child: TextButton.icon(
        onPressed:
            phase == LearningSyncPhase.syncing ||
                phase == LearningSyncPhase.signedOut
            ? null
            : () => ref.read(learningSyncProvider.notifier).synchronize(),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          foregroundColor: context.appColors.textPrimary,
        ),
      ),
    );
  }
}

/// Uses the same validated, persisted language transition and picker as Home.
class WebLanguageSelector extends ConsumerWidget {
  const WebLanguageSelector({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(selectedContentLanguageProvider);
    final selection = ref.watch(languageSelectionProvider);
    final profile = ContentLanguageProfile.forLanguage(
      language.asData?.value ?? '',
    );
    final name = profile?.displayName ?? 'Lernsprache laden';
    final colors = context.appColors;
    return PopoverTrigger<void>(
      maxWidth: 340,
      popover: (_) => LanguagePanel(current: name),
      builder: (context, open, show) => Semantics(
        label: 'Zielsprache: $name. Sprache wählen',
        button: true,
        excludeSemantics: true,
        child: TextButton(
          onPressed: selection.switching || profile == null ? null : show,
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            backgroundColor: open
                ? colors.popover
                : colors.active.withValues(alpha: 0.12),
            foregroundColor: open ? Colors.white : colors.textPrimary,
          ),
          child: Row(
            children: [
              const Icon(Icons.language, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: AppType.chrome(
                    size: 15,
                    weight: FontWeight.w600,
                    color: open ? Colors.white : colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
