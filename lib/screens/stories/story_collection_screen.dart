import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/story_learning_diagnostics.dart';
import '../../presentation/providers/story_collection_provider.dart';
import '../../presentation/providers/story_learning_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/action_buttons.dart';
import '../decks/deck_practice_screen.dart';
import '../words/word_list_screen.dart';

/// A personal view over existing card IDs; never a pack deck or a second SRS.
class StoryCollectionScreen extends ConsumerWidget {
  const StoryCollectionScreen({super.key, this.preview});
  final List<StoryCollectionWord>? preview;

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    CupertinoPageRoute<void>(builder: (_) => const StoryCollectionScreen()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = preview == null
        ? ref.watch(storyCollectionProvider)
        : AsyncData(preview!);
    final colors = context.appColors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackBar(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: data.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (_, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          const StoryLearningFailure(
                            StoryLearningStep.collection,
                          ).message,
                        ),
                      ),
                      CupertinoButton(
                        onPressed: () {
                          ref.invalidate(practiceResolverProvider);
                          ref.invalidate(storyCollectionProvider);
                        },
                        child: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
                data: (words) => ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Aus Storys',
                        style: AppType.editorial(
                          size: 32,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${words.length} Wörter · Deine persönliche Sammlung',
                      style: AppType.meta(color: colors.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Hier findest du die Wörter, die du beim Lesen zum Lernen hinzugefügt hast. Dein Lernstand gilt überall.',
                      style: AppType.chrome(color: colors.textMuted),
                    ),
                    const SizedBox(height: 20),
                    if (words.isNotEmpty)
                      PrimaryActionButton(
                        label: 'Mit diesen Wörtern lernen',
                        onPressed:
                            preview != null ||
                                !words.any(
                                  (w) => w.state.isActive && w.item != null,
                                )
                            ? null
                            : () => DeckPracticeScreen.open(
                                context,
                                deckId: storyCollectionId,
                              ),
                      ),
                    if (words.isEmpty)
                      const Text(
                        'Füge in einer Story ein Wort zum Lernen hinzu.',
                      ),
                    const SizedBox(height: 20),
                    for (final word in words)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: colors.raisedInk,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                word.item?.card.form ?? 'Gespeichertes Wort',
                                style: AppType.editorial(
                                  size: 24,
                                  color: colors.textPrimary,
                                ),
                              ),
                              if (word.item?.card.translationDe
                                  case final translation?)
                                Text(
                                  translation,
                                  style: AppType.chrome(
                                    color: colors.textPrimary,
                                  ),
                                ),
                              if (word.item case final item?) ...[
                                const SizedBox(height: 10),
                                Text(
                                  item.practiceSentence.text,
                                  style: AppType.chrome(
                                    color: colors.textMuted,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                word.status,
                                style: AppType.meta(color: colors.textMuted),
                              ),
                              if (preview == null)
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => WordListScreen.openTarget(
                                    context,
                                    word.state.cardId,
                                  ),
                                  child: const Text('In Wortliste ansehen'),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StoryCollectionEntry extends ConsumerWidget {
  const StoryCollectionEntry({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(storyCollectionIdsProvider)
      .when(
        loading: () => const SizedBox.shrink(),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: CupertinoButton(
            onPressed: () => ref.invalidate(practiceResolverProvider),
            child: const Text('Sammlung nicht geladen · Erneut versuchen'),
          ),
        ),
        data: (ids) => ids.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(18),
                  color: context.appColors.raisedInk,
                  borderRadius: BorderRadius.circular(20),
                  onPressed: () => StoryCollectionScreen.open(context),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.book,
                        color: context.appColors.textPrimary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aus Storys',
                              style: AppType.chrome(
                                color: context.appColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${ids.length} Wörter · Persönliche Sammlung',
                              style: AppType.meta(
                                color: context.appColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_right,
                        color: context.appColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
      );
}
