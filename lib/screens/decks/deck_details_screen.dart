import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Scaffold;
import 'package:flutter/services.dart';

import '../../models/deck_store.dart';
import '../../models/home_models.dart';
import '../../models/word_list_store.dart';
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
class DeckDetailsScreen extends StatelessWidget {
  const DeckDetailsScreen({
    super.key,
    required this.decks,
    required this.deckId,
    required this.words,
  });

  final DeckStore decks;
  final String deckId;

  /// The vocabulary the practice session draws from and reports to.
  final WordListStore words;

  static Future<void> open(
    BuildContext context,
    DeckStore decks,
    String deckId,
    WordListStore words,
  ) => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (_) =>
          DeckDetailsScreen(decks: decks, deckId: deckId, words: words),
    ),
  );

  // TODO: draw the session from this deck's words once decks own words.
  void _practise(BuildContext context, DeckPracticeMode mode) =>
      DeckPracticeScreen.open(context, store: words, mode: mode);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: ListenableBuilder(
            listenable: decks,
            builder: (context, _) {
              final deck = decks.byId(deckId);
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
                          onChanged: (v) => decks.setActive(deck.id, v),
                        ),
                        const SizedBox(height: 12),
                        PrimaryActionButton(
                          label: 'Lerne mit diesem Stapel',
                          onPressed: () =>
                              _practise(context, DeckPracticeMode.learn),
                        ),
                        const SizedBox(height: 12),
                        _RecentWords(words: deck.recentWords.take(5).toList()),
                        const SizedBox(height: 22),
                        const SectionHeading(title: 'Mehr davon'),
                        const SizedBox(height: 4),
                        Text(
                          'Inhalte rund um diesen Stapel',
                          style: AppType.chrome(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),
                        _ReviewCard(
                          onReview: () =>
                              _practise(context, DeckPracticeMode.review),
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
                color: AppColors.mastered,
                child: Icon(deck.icon, size: 24, color: AppColors.textPrimary),
              ),
            ),
            const Spacer(),
            // The visible level name is the label; bolts only repeat it.
            Text(deck.difficulty.label, style: AppType.meta()),
            const SizedBox(width: 8),
            ExcludeSemantics(
              child: DifficultyBolts(difficulty: deck.difficulty),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(deck.name, style: AppType.editorial(size: 32)),
        ),
        const SizedBox(height: 8),
        Text(
          deck.description,
          style: AppType.editorial(
            size: 17,
            weight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0,
            color: AppColors.textMuted,
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
              style: AppType.chrome(color: AppColors.textMuted),
              children: [
                count(seen, AppColors.active),
                TextSpan(text: ' von $total neuen Wörtern'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: AppType.chrome(color: AppColors.textMuted),
              children: [
                count(mastered, AppColors.mastered),
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
                color: AppColors.hairline,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (deck.masteredWords > 0)
                      Expanded(
                        flex: deck.masteredWords,
                        child: const ColoredBox(color: AppColors.mastered),
                      ),
                    if (building > 0)
                      Expanded(
                        flex: building,
                        child: const ColoredBox(color: AppColors.active),
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
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.raisedInk,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppType.chrome(size: 17, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppColors.textMuted,
                inactiveTrackColor: AppColors.hairline,
                thumbColor: AppColors.textPrimary,
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
        color: AppColors.raisedInk,
        border: Border.all(color: AppColors.hairline),
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
                          style: AppType.chrome(weight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: _open ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          CupertinoIcons.chevron_down,
                          size: 18,
                          color: AppColors.textMuted,
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
                              style: AppType.chrome(color: AppColors.textMuted),
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
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              word.word,
              style: AppType.editorial(
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
              style: AppType.chrome(color: AppColors.textMuted),
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
        color: AppColors.raisedInk,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Stapel-Revue',
            style: AppType.chrome(size: 17, weight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Sieh die Karten wiederholt durch, ohne darauf zu warten, dass '
            'der Algorithmus sie dir wieder zeigt.',
            style: AppType.chrome(color: AppColors.textMuted, height: 1.4),
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
