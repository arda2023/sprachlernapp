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
import '../../widgets/count_format.dart';
import '../home/widgets/deck_tile.dart';
import 'deck_practice_screen.dart';

/// One deck (Redesign 20.10.2026): icon in its progress gauge, title and
/// description, the counts side by side, then one orange "practise" button,
/// the daily-mix switch, the Stapel-Revue as a row and the recent forms.
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
          child: watchContentStable(ref, decksProvider).when(
            skipLoadingOnReload: false,
            skipLoadingOnRefresh: false,
            skipError: false,
            loading: () => const Center(child: CupertinoActivityIndicator()),
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
                        const SizedBox(height: 22),
                        _ProgressLegend(deck: deck),
                        const SizedBox(height: 20),
                        PrimaryActionButton(
                          label: 'Mit diesem Stapel üben',
                          onPressed: () =>
                              _practise(context, DeckPracticeMode.learn),
                        ),
                        const SizedBox(height: 12),
                        _ToggleRow(
                          label: 'In die tägliche Übung',
                          detail:
                              'Neue Wörter dieses Stapels kommen in „Lernen“. Aus: keine neuen Wörter daraus, Gelerntes wird weiter wiederholt.',
                          value: activation.values[deck.id] ?? deck.isActive,
                          onChanged: (v) => ref
                              .read(deckActiveControllerProvider.notifier)
                              .setActive(deck.id, v),
                        ),
                        if (activation.errors.containsKey(deck.id))
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
                        _ReviewCard(
                          onReview: () =>
                              _practise(context, DeckPracticeMode.review),
                        ),
                        if (deck.recentWords.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _RecentWords(
                            words: deck.recentWords.take(5).toList(),
                          ),
                        ],
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
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DeckGauge(deck: deck, size: 84),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.raisedInk,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The visible level name is the label; bolts repeat it.
                  Text(
                    deck.difficulty.label,
                    style: AppType.meta(color: colors.textMuted),
                  ),
                  const SizedBox(width: 6),
                  ExcludeSemantics(
                    child: DifficultyBolts(difficulty: deck.difficulty),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Semantics(
          header: true,
          child: Text(
            deck.name,
            style: AppType.editorial(
              color: colors.textPrimary,
              size: 32,
              height: 1.15,
            ),
          ),
        ),
        if (deck.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            deck.description,
            style: AppType.editorial(
              size: 17,
              weight: FontWeight.w400,
              height: 1.45,
              letterSpacing: 0,
              color: colors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// The counts side by side (stat cells) over one bar: violet for mastered,
/// orange for practised but not yet mastered.
class _ProgressLegend extends StatelessWidget {
  const _ProgressLegend({required this.deck});

  final Deck deck;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final seen = formatCountDe(deck.seenWords);
    final total = formatCountDe(deck.totalWords);
    final mastered = formatCountDe(deck.masteredWords);
    final building = deck.seenWords - deck.masteredWords;
    final rest = deck.totalWords - deck.seenWords;

    Widget cell(String value, String label, Color? ink) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (ink != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.meta(color: colors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppType.chrome(
              size: 20,
              weight: FontWeight.w800,
              color: colors.textPrimary,
              tabular: true,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      label: '$seen von $total Übungen gesehen, $mastered Übungen gemeistert',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: colors.raisedInk,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                cell('$seen / $total', 'Geübt', colors.active),
                cell(mastered, 'Gemeistert', colors.mastered),
                cell(formatCountDe(rest), 'Noch neu', null),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: ColoredBox(
                  color: colors.hairline,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (deck.masteredWords > 0)
                        Expanded(
                          flex: deck.masteredWords,
                          child: ColoredBox(color: colors.mastered),
                        ),
                      if (building > 0)
                        Expanded(
                          flex: building,
                          child: ColoredBox(color: colors.active),
                        ),
                      if (rest > 0)
                        Expanded(flex: rest, child: const SizedBox()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Whether new words of this deck join the daily mix ("Lernen").
class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String detail;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MergeSemantics(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: colors.raisedInk,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppType.chrome(
                        color: colors.textPrimary,
                        size: 16,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: AppType.chrome(size: 13, color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              CupertinoSwitch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: colors.active,
                inactiveTrackColor: colors.hairline,
                thumbColor: const Color(0xFFFFFFFF),
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
    final title = switch (words.length) {
      0 => 'Deine zuletzt geübten Formen',
      1 => 'Deine zuletzt geübte Form',
      _ => 'Deine letzten ${words.length} geübten Formen',
    };

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.raisedInk,
        borderRadius: BorderRadius.circular(20),
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
                              'Noch keine Übungen aus diesem Stapel gemacht.',
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
        border: Border(
          top: BorderSide(
            color: context.appColors.hairline.withValues(alpha: 0.6),
          ),
        ),
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

/// Stapel-Revue as one row: review everything practised in this deck
/// without waiting for the schedule.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.onReview});

  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onReview,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        pressedOpacity: 0.75,
        child: Semantics(
          label: 'Stapel-Revue: Stapel nochmals durchsehen',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            decoration: BoxDecoration(
              color: colors.raisedInk,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.activeTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_2_circlepath,
                    size: 20,
                    color: colors.active,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stapel-Revue',
                        style: AppType.chrome(
                          color: colors.textPrimary,
                          size: 16,
                          weight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Geübte Karten nochmals durchsehen – ohne auf den '
                        'Plan zu warten.',
                        style: AppType.chrome(
                          size: 13,
                          color: colors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
