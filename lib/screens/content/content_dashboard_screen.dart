import 'package:flutter/cupertino.dart';

import '../../models/exercise_models.dart';
import '../../models/grammar_models.dart';
import '../../models/home_models.dart';
import '../../models/practice_models.dart';
import '../../models/reading_history.dart';
import '../../theme/app_theme.dart';
import '../../widgets/difficulty_bolts.dart';
import '../../widgets/more_button.dart';
import '../../widgets/section_heading.dart';
import '../grammar/grammar_rule_detail_screen.dart';
import '../grammar/grammar_rules_screen.dart';
import '../home/widgets/story_carousel.dart';
import '../practice/choice_exercise_screen.dart';
import '../practice/practice_library_screen.dart';
import 'text_library_screen.dart';

/// The "Inhalte" tab (docs/redesign/design-system.md): one section per
/// category, each showing its content right away and "Mehr anzeigen" for
/// the full list. Every section has its own shape so the page doesn't read
/// as four identical carousels: Texte as covers, Hören as a wide "next up"
/// card over a row of tiles, Grammatik as paged columns of rows,
/// Grammatikregeln as a two-column grid.
class ContentDashboardScreen extends StatelessWidget {
  const ContentDashboardScreen({
    super.key,
    required this.texts,
    required this.history,
    required this.listening,
    required this.grammar,
    required this.progress,
    required this.rules,
  });

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);

  /// How much of a section the dashboard shows before "Mehr anzeigen".
  static const _maxTexts = 8;
  static const _maxTiles = 8;
  static const _maxGrammar = 9;
  static const _maxRules = 4;

  final List<ExerciseText> texts;
  final ReadingHistory history;
  final List<ChoiceExercise> listening;
  final List<ChoiceExercise> grammar;
  final PracticeProgress progress;
  final List<GrammarRule> rules;

  void _openExercise(
    BuildContext context,
    ChoiceExercise exercise,
    List<ChoiceExercise> queue,
  ) => ChoiceExerciseScreen.open(
    context,
    exercise: exercise,
    queue: queue,
    progress: progress,
  );

  void _openLibrary(BuildContext context, PracticeKind kind) =>
      PracticeLibraryScreen.open(
        context,
        kind: kind,
        exercises: kind == PracticeKind.listening ? listening : grammar,
        progress: progress,
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: Listenable.merge([history, progress]),
        builder: (context, _) => ListView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.only(top: 8, bottom: 40),
          children: [
            Padding(
              padding: _gutter,
              child: Semantics(
                header: true,
                child: Text(
                  'Inhalte',
                  style: AppType.editorial(
                    color: context.appColors.textPrimary,
                    size: 32,
                  ),
                ),
              ),
            ),
            if (texts.isNotEmpty) ..._texts(context),
            if (listening.isNotEmpty) ..._listening(context),
            if (grammar.isNotEmpty) ..._grammar(context),
            if (rules.isNotEmpty) ..._rules(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _texts(BuildContext context) {
    // Texts from stories the learner has opened come first.
    final read = history.storyIds;
    final ordered = [
      ...texts.where((t) => read.contains(t.sourceStoryId)),
      ...texts.where((t) => !read.contains(t.sourceStoryId)),
    ].take(_maxTexts).toList();
    return [
      const SizedBox(height: 20),
      _SectionHeader(
        title: 'Texte',
        moreLabel: 'Alle Texte anzeigen',
        onMore: () =>
            TextLibraryScreen.open(context, texts: texts, history: history),
      ),
      const SizedBox(height: 12),
      StoryCarousel(
        stories: [for (final t in ordered) t.info],
        onOpen: (story) => TextLibraryScreen.start(
          context,
          ordered.firstWhere((t) => t.info.id == story.id),
        ),
      ),
    ];
  }

  List<Widget> _listening(BuildContext context) {
    final done = listening.where((e) => progress.isDone(e.id)).length;
    // The first open exercise is "next up"; once all are solved, the first.
    final next = listening.firstWhere(
      (e) => !progress.isDone(e.id),
      orElse: () => listening.first,
    );
    final rest = [
      for (final e in listening)
        if (e != next) e,
    ].take(_maxTiles).toList();
    return [
      const SizedBox(height: 36),
      _SectionHeader(
        title: 'Hören',
        moreLabel: 'Alle Hörübungen anzeigen',
        onMore: () => _openLibrary(context, PracticeKind.listening),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: _gutter,
        child: _ListeningFeature(
          exercise: next,
          allDone: done == listening.length,
          onTap: () => _openExercise(context, next, listening),
        ),
      ),
      if (rest.isNotEmpty) ...[
        const SizedBox(height: 12),
        _HorizontalRow(
          children: [
            for (final e in rest)
              _ListeningTile(
                exercise: e,
                done: progress.isDone(e.id),
                onTap: () => _openExercise(context, e, listening),
              ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _grammar(BuildContext context) {
    final shown = grammar.take(_maxGrammar).toList();
    return [
      const SizedBox(height: 36),
      _SectionHeader(
        title: 'Grammatik',
        moreLabel: 'Alle Grammatikübungen anzeigen',
        onMore: () => _openLibrary(context, PracticeKind.grammar),
      ),
      const SizedBox(height: 8),
      _GrammarColumns(
        exercises: shown,
        isDone: progress.isDone,
        onOpen: (e) => _openExercise(context, e, grammar),
      ),
    ];
  }

  List<Widget> _rules(BuildContext context) {
    final shown = rules.take(_maxRules).toList();
    return [
      const SizedBox(height: 36),
      _SectionHeader(
        title: 'Grammatikregeln',
        moreLabel: 'Alle Grammatikregeln anzeigen',
        onMore: () => GrammarRulesScreen.open(context, rules),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: _gutter,
        child: _RuleGrid(
          rules: shown,
          onOpen: (rule) => GrammarRuleDetailScreen.open(context, rule),
        ),
      ),
    ];
  }
}

/// Level 1–3 as the deck difficulty, so all content shares one bolt scale.
DeckDifficulty _difficulty(int level) =>
    DeckDifficulty.values[(level - 1).clamp(0, 2)];

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.moreLabel,
    required this.onMore,
  });

  final String title;
  final String moreLabel;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8),
      child: SectionHeading(
        title: title,
        trailing: MoreButton(
          label: 'Mehr anzeigen',
          semanticLabel: moreLabel,
          onPressed: onMore,
        ),
      ),
    );
  }
}

/// A horizontal row whose cards share the height of the tallest one, so
/// large Dynamic Type grows the cards instead of clipping them.
class _HorizontalRow extends StatelessWidget {
  const _HorizontalRow({required this.children, this.spacing = 12});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, child) in children.indexed) ...[
              if (i > 0) SizedBox(width: spacing),
              child,
            ],
          ],
        ),
      ),
    );
  }
}

/// The next open listening exercise as a wide card on the playback tone,
/// with a large faint waveform and an orange play circle.
class _ListeningFeature extends StatelessWidget {
  const _ListeningFeature({
    required this.exercise,
    required this.allDone,
    required this.onTap,
  });

  final ChoiceExercise exercise;
  final bool allDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final kicker = allDone ? 'Noch einmal hören' : 'Als Nächstes';
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.8,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label:
              '$kicker: ${exercise.title}. ${exercise.summary}. '
              '${exercise.meta}',
          excludeSemantics: true,
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: colors.playback,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: -20,
                  child: Icon(
                    CupertinoIcons.waveform,
                    size: 150,
                    color: colors.textPrimary.withValues(alpha: 0.07),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.headphones,
                            size: 16,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              kicker,
                              style: AppType.meta(color: colors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        exercise.title,
                        style: AppType.editorial(
                          color: colors.textPrimary,
                          size: 26,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.summary,
                        style: AppType.chrome(color: colors.textMuted),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          DifficultyBolts(
                            difficulty: _difficulty(exercise.level),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exercise.topic,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.meta(color: colors.textMuted),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.active,
                            ),
                            child: const Icon(
                              CupertinoIcons.play_fill,
                              size: 22,
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A listening exercise as a small square-ish tile: speaker badge, title,
/// bolts and topic. Solved tiles carry a green check.
class _ListeningTile extends StatelessWidget {
  const _ListeningTile({
    required this.exercise,
    required this.done,
    required this.onTap,
  });

  static const width = 156.0;

  final ChoiceExercise exercise;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label:
              '${exercise.title}. ${exercise.summary}. ${exercise.meta}'
              '${done ? ', fertig' : ''}',
          excludeSemantics: true,
          child: Container(
            width: width,
            constraints: const BoxConstraints(minHeight: 140),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.raisedInk,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.playback,
                      ),
                      child: Icon(
                        CupertinoIcons.speaker_2_fill,
                        size: 17,
                        color: colors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (done)
                      Icon(
                        CupertinoIcons.checkmark_alt_circle_fill,
                        size: 22,
                        color: colors.progressWords,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Spacer(),
                Text(
                  exercise.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.chrome(
                    color: colors.textPrimary,
                    size: 16,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DifficultyBolts(
                  difficulty: _difficulty(exercise.level),
                  size: 12,
                ),
                const SizedBox(height: 4),
                Text(
                  exercise.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.meta(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grammar exercises as horizontally scrolling columns of three rows, like
/// the App Store's app lists. Each column is a little narrower than the
/// screen, so the next one peeks in.
class _GrammarColumns extends StatelessWidget {
  const _GrammarColumns({
    required this.exercises,
    required this.isDone,
    required this.onOpen,
  });

  static const _perColumn = 3;

  final List<ChoiceExercise> exercises;
  final bool Function(String id) isDone;
  final ValueChanged<ChoiceExercise> onOpen;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    final single = exercises.length <= _perColumn;
    final width = single ? screen - 40 : (screen - 40) * 0.88;
    return _HorizontalRow(
      spacing: 16,
      children: [
        for (var i = 0; i < exercises.length; i += _perColumn)
          SizedBox(
            width: width,
            child: Column(
              children: [
                for (final e in exercises.skip(i).take(_perColumn))
                  _GrammarRow(
                    exercise: e,
                    done: isDone(e.id),
                    onTap: () => onOpen(e),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _GrammarRow extends StatelessWidget {
  const _GrammarRow({
    required this.exercise,
    required this.done,
    required this.onTap,
  });

  final ChoiceExercise exercise;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 56),
        child: Semantics(
          label:
              '${exercise.title}, ${exercise.summary}, ${exercise.meta}'
              '${done ? ', fertig' : ''}',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: done ? colors.successTint : colors.activeTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    done
                        ? CupertinoIcons.checkmark_alt
                        : CupertinoIcons.textformat,
                    size: 22,
                    color: done ? colors.success : colors.active,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.chrome(
                          color: colors.textPrimary,
                          size: 16,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exercise.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.meta(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                DifficultyBolts(
                  difficulty: _difficulty(exercise.level),
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two columns of rule cards; rows size to their tallest card.
class _RuleGrid extends StatelessWidget {
  const _RuleGrid({required this.rules, required this.onOpen});

  final List<GrammarRule> rules;
  final ValueChanged<GrammarRule> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rules.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _RuleCard(
                      rule: rules[i],
                      onTap: () => onOpen(rules[i]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < rules.length
                        ? _RuleCard(
                            rule: rules[i + 1],
                            onTap: () => onOpen(rules[i + 1]),
                          )
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A rule as an index card: level bolts and reading time, right below the
/// rule name in serif and its one-line summary.
class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.onTap});

  final GrammarRule rule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label:
              '${rule.title}, ${rule.summary}, ${rule.level.label}, '
              '${rule.minutes} Minuten Lesezeit',
          excludeSemantics: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.raisedInk,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DifficultyBolts(
                      difficulty: _difficulty(rule.level.index + 1),
                      size: 12,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${rule.minutes} Min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.meta(color: colors.textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  rule.title,
                  style: AppType.editorial(
                    color: colors.textPrimary,
                    size: 20,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rule.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.meta(color: colors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
