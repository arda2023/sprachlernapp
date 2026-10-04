import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/deck_providers.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/content_unavailable_view.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/services.dart';

import '../../models/home_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/back_bar.dart';
import '../../widgets/difficulty_bolts.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/section_heading.dart';
import '../home/widgets/vocab_progress.dart' show formatCountDe;
import 'deck_practice_screen.dart';

/// One deck: orientation (title, description, progress) first, then the
/// actions (toggle, practice, recent words, Stapel-Revue).
class DeckDetailsScreen extends ConsumerWidget {
  const DeckDetailsScreen({super.key, required this.deckId});

  final String deckId;

  static Future<void> open(BuildContext context, String deckId) =>
      Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => DeckDetailsScreen(deckId: deckId),
        ),
      );

  void _practise(BuildContext context, DeckPracticeMode mode) =>
      DeckPracticeScreen.open(context, deckId: deckId, mode: mode);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (context.appColors.light
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light)
              .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: ref
              .watch(decksProvider)
              .when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                error: (error, _) => Column(
                  children: [
                    BackBar(onBack: () => Navigator.of(context).maybePop()),
                    ContentUnavailableView(
                      error: error,
                      onRetry: () {
                        retryDatabases(ref);
                        ref.invalidate(decksProvider);
                      },
                    ),
                  ],
                ),
                data: (decks) {
                  final deck = decks.where((d) => d.id == deckId).firstOrNull;
                  if (deck == null) {
                    return Column(
                      children: [
                        BackBar(onBack: () => Navigator.of(context).maybePop()),
                        Text(
                          'Dieser Stapel ist nicht mehr verfügbar.',
                          style: AppType.chrome(
                            color: context.appColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  }
                  final activation = ref.watch(deckActiveControllerProvider);
                  return Column(
                    children: [
                      BackBar(onBack: () => Navigator.of(context).maybePop()),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                          children: [
                            _Masthead(deck: deck),
                            const SizedBox(height: 20),
                            _ProgressLegend(deck: deck),
                            const SizedBox(height: 28),
                            _ToggleRow(
                              label: 'Stapel lernen',
                              value: deck.isActive,
                              onChanged: activation.isLoading
                                  ? null
                                  : (v) => ref
                                        .read(
                                          deckActiveControllerProvider.notifier,
                                        )
                                        .setActive(deck.id, v),
                            ),
                            if (activation.hasError)
                              CupertinoButton(
                                onPressed: () => ref
                                    .read(deckActiveControllerProvider.notifier)
                                    .setActive(deck.id, !deck.isActive),
                                child: Text(
                                  'Aktivierung nicht gespeichert. Wiederholen',
                                  style: AppType.chrome(
                                    color: context.appColors.textPrimary,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            PrimaryActionButton(
                              label: 'Lerne mit diesem Stapel',
                              onPressed: () =>
                                  _practise(context, DeckPracticeMode.learn),
                            ),
                            const SizedBox(height: 12),
                            if (deck.recentWords.isNotEmpty)
                              _RecentWords(
                                words: deck.recentWords.take(5).toList(),
                              ),
                            const SizedBox(height: 22),
                            const SectionHeading(title: 'Mehr davon'),
                            const SizedBox(height: 4),
                            Text(
                              'Inhalte rund um diesen Stapel',
                              style: AppType.chrome(
                                color: context.appColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _ReviewCard(
                              onReview: () =>
                                  _practise(context, DeckPracticeMode.review),
                            ),
                            const SizedBox(height: 20),
                            if (ref
                                    .watch(contentInfoProvider)
                                    .asData
                                    ?.value
                                    .isInternalTestPack ??
                                false)
                              Text(
                                'Internes Test-Pack',
                                style: AppType.meta(
                                  color: context.appColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ExcludeSemantics(
              child: ProgressRing(
                fraction: deck.masteredFraction,
                size: 56,
                color: context.appColors.mastered,
                child: Icon(
                  deck.icon,
                  size: 24,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            const Spacer(),
            // The visible level name is the label; bolts only repeat it.
            Text(
              deck.difficulty.label,
              style: AppType.meta(color: context.appColors.textMuted),
            ),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: DifficultyBolts(difficulty: deck.difficulty),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            deck.name,
            style: AppType.editorial(
              color: context.appColors.textPrimary,
              size: 32,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          deck.description,
          style: AppType.editorial(
            size: 17,
            weight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0,
            color: context.appColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Counts carry ink underlines, the track the same two inks: violet for
/// mastered, orange for seen but not yet mastered.
class _ProgressLegend extends StatelessWidget {
  const _ProgressLegend({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final seen = formatCountDe(deck.seenWords);
    final total = formatCountDe(deck.totalWords);
    final mastered = formatCountDe(deck.masteredWords);
    final building = deck.seenWords - deck.masteredWords;
    final rest = deck.totalWords - deck.seenWords;

    TextSpan count(String text, Color ink) => TextSpan(
      text: text,
      style: AppType.chrome(
        color: context.appColors.textPrimary,
        weight: FontWeight.w700,
        tabular: true,
        decoration: TextDecoration.underline,
        decorationColor: ink,
      ),
    );

    return Semantics(
      container: true,
      label: '$seen von $total neuen Wörtern gesehen, $mastered Wörter gelernt',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              style: AppType.chrome(color: context.appColors.textMuted),
              children: [
                count(seen, context.appColors.active),
                TextSpan(text: ' von $total neuen Wörtern'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: AppType.chrome(color: context.appColors.textMuted),
              children: [
                count(mastered, context.appColors.mastered),
                const TextSpan(text: ' Wörter gelernt'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: ColoredBox(
                color: context.appColors.hairline,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (deck.masteredWords > 0)
                      Expanded(
                        flex: deck.masteredWords,
                        child: ColoredBox(color: context.appColors.mastered),
                      ),
                    if (building > 0)
                      Expanded(
                        flex: building,
                        child: ColoredBox(color: context.appColors.active),
                      ),
                    if (rest > 0) Expanded(flex: rest, child: const SizedBox()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Neutral toggle: textMuted track when on, hairline when off, never an ink.
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          decoration: BoxDecoration(
            color: context.appColors.raisedInk,
            border: Border.all(color: context.appColors.hairline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppType.chrome(
                    color: context.appColors.textPrimary,
                    size: 17,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: context.appColors.textMuted,
                inactiveTrackColor: context.appColors.hairline,
                thumbColor: context.appColors.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentWords extends StatefulWidget {
  const _RecentWords({required this.words});

  final List<SeenWord> words;

  @override
  State<_RecentWords> createState() => _RecentWordsState();
}

class _RecentWordsState extends State<_RecentWords> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    final title = words.isEmpty
        ? 'Deine zuletzt gesehenen Wörter'
        : 'Deine letzten ${words.length} gesehenen Wörter';

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.raisedInk,
        border: Border.all(color: context.appColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: CupertinoButton(
              onPressed: () => setState(() => _open = !_open),
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 52),
              child: Semantics(
                label: title,
                expanded: _open,
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppType.chrome(
                            color: context.appColors.textPrimary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          CupertinoIcons.chevron_down,
                          size: 18,
                          color: context.appColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (words.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Noch keine Wörter aus diesem Stapel gesehen.',
                              style: AppType.chrome(
                                color: context.appColors.textMuted,
                              ),
                            ),
                          ),
                        for (final w in words) _WordRow(word: w),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _WordRow extends StatelessWidget {
  const _WordRow({required this.word});

  final SeenWord word;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.appColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              word.word,
              style: AppType.editorial(
                color: context.appColors.textPrimary,
                size: 17,
                weight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              word.translation,
              textAlign: TextAlign.end,
              style: AppType.chrome(color: context.appColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.onReview});

  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.appColors.raisedInk,
        border: Border.all(color: context.appColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Stapel-Revue',
            style: AppType.chrome(
              color: context.appColors.textPrimary,
              size: 17,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sieh die Karten wiederholt durch, ohne darauf zu warten, dass '
            'der Algorithmus sie dir wieder zeigt.',
            style: AppType.chrome(
              color: context.appColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          OutlineActionButton(
            label: 'Stapel nochmals durchsehen',
            onPressed: onReview,
          ),
        ],
      ),
    );
  }
}
