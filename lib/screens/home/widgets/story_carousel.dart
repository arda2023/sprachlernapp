import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../models/home_models.dart';
import '../../../models/story_category.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/press_scale.dart';
import '../../../widgets/story_cover.dart';

/// Level and reading time are no longer shown on covers or in the reader
/// (user decision 29.10.2026); VoiceOver still hears them.
String storySemanticsLabel(Story story) =>
    '${story.title}. ${story.topic}, ${story.readingMinutes} Minuten '
    'Lesezeit, Niveau ${story.level}';

/// The order inside one shelf: started stories first, then unread ones,
/// finished stories at the far end so new ones stay in view (user request
/// 31.10.2026).
List<Story> shelfOrder(
  List<Story> stories, {
  Map<String, double> progress = const {},
  Set<String> finished = const {},
}) => [
  for (final s in stories)
    if (!finished.contains(s.id) && progress.containsKey(s.id)) s,
  for (final s in stories)
    if (!finished.contains(s.id) && !progress.containsKey(s.id)) s,
  for (final s in stories)
    if (finished.contains(s.id)) s,
];

/// A mix across categories for Home: one story per category in turn, so
/// covers of different colours follow each other (user request 31.10.2026).
List<Story> mixedByCategory(
  List<Story> stories, {
  Map<String, double> progress = const {},
  Set<String> finished = const {},
}) {
  final groups = <String, List<Story>>{};
  for (final story in shelfOrder(
    stories,
    progress: progress,
    finished: finished,
  )) {
    (groups[StoryCategory.of(story.topic).name] ??= []).add(story);
  }
  final queues = groups.values.toList();
  final started = [
    for (final s in stories)
      if (!finished.contains(s.id) && progress.containsKey(s.id)) s,
  ];
  final mixed = <Story>[...started];
  for (var round = 0; queues.any((q) => q.length > round); round++) {
    for (final queue in queues) {
      if (round < queue.length && !mixed.contains(queue[round])) {
        mixed.add(queue[round]);
      }
    }
  }
  return mixed;
}

/// Horizontal row of story covers. [progress] maps story ids to the reading
/// position (0–1); finished stories carry a check.
class StoryCarousel extends StatelessWidget {
  const StoryCarousel({
    super.key,
    required this.stories,
    required this.onOpen,
    this.progress = const {},
    this.finished = const {},
    this.onOpenFrom,
    this.width = cardWidth,
    this.height = cardHeight,
  });

  static const cardWidth = 150.0;
  static const cardHeight = 212.0;

  final List<Story> stories;
  final ValueChanged<Story> onOpen;

  /// Instead of [onOpen], when the tap opens a popover at the card: also
  /// passes the tapped card's context, for the popover's arrow.
  final void Function(Story story, BuildContext card)? onOpenFrom;
  final Map<String, double> progress;
  final Set<String> finished;

  /// Card size: tall covers by default, wide and short for a shelf row.
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: stories.length,
        itemBuilder: (context, i) => Padding(
          padding: EdgeInsets.only(right: i == stories.length - 1 ? 0 : 12),
          child: Builder(
            builder: (card) => StoryCard(
              story: stories[i],
              progress: progress[stories[i].id],
              finished: finished.contains(stories[i].id),
              width: width,
              height: height,
              onTap: () => onOpenFrom != null
                  ? onOpenFrom!(stories[i], card)
                  : onOpen(stories[i]),
            ),
          ),
        ),
      ),
    );
  }
}

/// One category as a featured story above a row of wide, short cards from
/// the same category (Mobbin: Speechify, ElevenReader).
class StoryFeatureShelf extends StatelessWidget {
  const StoryFeatureShelf({
    super.key,
    required this.stories,
    required this.onOpen,
    this.progress = const {},
    this.finished = const {},
  });

  final List<Story> stories;
  final ValueChanged<Story> onOpen;
  final Map<String, double> progress;
  final Set<String> finished;

  @override
  Widget build(BuildContext context) {
    final lead = stories.first;
    final rest = stories.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) => StoryCard(
              story: lead,
              progress: progress[lead.id],
              finished: finished.contains(lead.id),
              width: constraints.maxWidth,
              height: 196,
              onTap: () => onOpen(lead),
            ),
          ),
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 12),
          StoryCarousel(
            stories: rest,
            onOpen: onOpen,
            progress: progress,
            finished: finished,
            width: 232,
            height: 124,
          ),
        ],
      ],
    );
  }
}

/// One category as numbered rows, three per column, paged sideways
/// (Mobbin: Apple Books "Top Free").
class StoryListShelf extends StatelessWidget {
  const StoryListShelf({
    super.key,
    required this.stories,
    required this.onOpen,
    this.progress = const {},
    this.finished = const {},
  });

  static const rowHeight = 84.0;
  static const rowGap = 12.0;

  final List<Story> stories;
  final ValueChanged<Story> onOpen;
  final Map<String, double> progress;
  final Set<String> finished;

  @override
  Widget build(BuildContext context) {
    final columns = <List<(int, Story)>>[];
    for (final (i, story) in stories.indexed) {
      if (i % 3 == 0) columns.add([]);
      columns.last.add((i + 1, story));
    }
    final width = MediaQuery.sizeOf(context).width - 72;
    final rows = math.min(3, stories.length);
    return SizedBox(
      height: rows * rowHeight + (rows - 1) * rowGap,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: columns.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, c) => SizedBox(
          width: columns.length == 1 ? width + 32 : width,
          child: Column(
            children: [
              for (final (j, (rank, story)) in columns[c].indexed) ...[
                if (j > 0) const SizedBox(height: rowGap),
                _StoryListRow(
                  rank: rank,
                  story: story,
                  progress: progress[story.id],
                  finished: finished.contains(story.id),
                  onTap: () => onOpen(story),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryListRow extends StatelessWidget {
  const _StoryListRow({
    required this.rank,
    required this.story,
    required this.progress,
    required this.finished,
    required this.onTap,
  });

  final int rank;
  final Story story;
  final double? progress;
  final bool finished;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final started = !finished && (progress ?? 0) >= 0.02;
    return MergeSemantics(
      child: PressScale(
        child: CupertinoButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          pressedOpacity: 0.85,
          minimumSize: const Size(44, 44),
          child: Semantics(
            label: _semantics(story, progress, finished),
            excludeSemantics: true,
            child: SizedBox(
              height: StoryListShelf.rowHeight,
              child: Row(
                children: [
                  _Cover(
                    story: story,
                    width: 62,
                    height: StoryListShelf.rowHeight,
                    radius: 12,
                    texture: false,
                    finished: finished,
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$rank',
                      style: AppType.editorial(
                        color: colors.textMuted,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.editorial(
                            color: finished
                                ? colors.textMuted
                                : colors.textPrimary,
                            size: 17,
                            height: 1.2,
                          ),
                        ),
                        if (started) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: 120,
                            child: ReadingBar(fraction: progress!),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (finished) ...[
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      size: 22,
                      color: colors.progressWords,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _semantics(Story story, double? progress, bool finished) {
  final started = !finished && (progress ?? 0) >= 0.02;
  final percent = ((progress ?? 0) * 100).round();
  return '${storySemanticsLabel(story)}'
      '${finished
          ? ', gelesen'
          : started
          ? ', $percent Prozent gelesen'
          : ''}';
}

/// A closed, always-dark cover in the category colour: the title's first
/// word set huge as a faint serif texture, the category icon small in the
/// corner. Started stories carry a progress bar along the bottom edge;
/// finished ones dim and get a check (user request 31.10.2026). Text is
/// fixed white, so it reads in both motifs.
class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.story,
    required this.onTap,
    this.progress,
    this.finished = false,
    this.width = StoryCarousel.cardWidth,
    this.height = StoryCarousel.cardHeight,
  });

  final Story story;
  final VoidCallback onTap;

  /// Reading position; shown as a bar when the story is started.
  final double? progress;
  final bool finished;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    final started = !finished && (progress ?? 0) >= 0.02;
    final wide = width > height * 1.4;
    final featured = width >= 300 && height >= 180;
    final titleSize = featured
        ? 26.0
        : wide
        ? 18.0
        : 17.0;
    return MergeSemantics(
      // Cards sink slightly under the finger (press feedback).
      child: PressScale(
        child: CupertinoButton(
          onPressed: onTap,
          padding: EdgeInsets.zero,
          pressedOpacity: 0.9,
          minimumSize: const Size(44, 44),
          child: Semantics(
            label: _semantics(story, progress, finished),
            excludeSemantics: true,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Cover(
                    story: story,
                    width: width,
                    height: height,
                    radius: 18,
                    texture: true,
                    finished: finished,
                  ),
                  if (finished)
                    const Positioned(
                      top: 10,
                      right: 10,
                      child: _FinishedBadge(),
                    ),
                  Positioned(
                    left: featured ? 18 : 12,
                    right: featured ? 18 : 12,
                    bottom: started ? 18 : (featured ? 16 : 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          maxLines: wide ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.editorial(
                            color: finished
                                ? white.withValues(alpha: 0.75)
                                : white,
                            size: titleSize,
                            height: 1.2,
                          ),
                        ),
                        if (started) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${((progress ?? 0) * 100).round()} %',
                            style: AppType.meta(
                              color: white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Reading position along the bottom edge.
                  if (started)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(18),
                        ),
                        child: ReadingBar(
                          fraction: progress!,
                          onDark: true,
                          height: 5,
                          square: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The cover art behind a card or list row.
class _Cover extends StatelessWidget {
  const _Cover({
    required this.story,
    required this.width,
    required this.height,
    required this.radius,
    required this.texture,
    required this.finished,
  });

  final Story story;
  final double width;
  final double height;
  final double radius;
  final bool texture;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    return StoryCover(
      story: story,
      width: width,
      height: height,
      radius: radius,
      texture: texture,
      finished: finished,
    );
  }
}

class _FinishedBadge extends StatelessWidget {
  const _FinishedBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFFFFFFFF),
    ),
    child: Icon(
      CupertinoIcons.checkmark_alt,
      size: 16,
      color: context.appColors.progressWords,
    ),
  );
}

/// Thin rounded reading-progress bar (orange fill).
class ReadingBar extends StatelessWidget {
  const ReadingBar({
    super.key,
    required this.fraction,
    this.onDark = false,
    this.height = 4,
    this.square = false,
  });

  final double fraction;
  final bool onDark;
  final double height;

  /// Flush along a card's edge: no rounded ends.
  final bool square;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(square ? 0 : 99),
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: onDark
                ? const Color(0x40FFFFFF)
                : context.appColors.hairline,
          ),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.03, 1.0),
            child: ColoredBox(color: context.appColors.active),
          ),
        ],
      ),
    ),
  );
}

/// Stand-in cover until stories and news ship with artwork: the topic set
/// as a faint serif masthead on a neutral tone.
class TypeCover extends StatelessWidget {
  const TypeCover({
    super.key,
    required this.topic,
    required this.tone,
    this.size = 52,
  });

  static const _tones = [
    Color(0xFF1A1D26),
    Color(0xFF20242F),
    Color(0xFF161922),
  ];

  final String topic;
  final int tone;

  /// Masthead size; the cover crops it, so it reads as texture.
  final double size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _tones[tone % _tones.length],
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: size * 0.2,
            top: size * 0.58,
            child: Text(
              topic,
              maxLines: 1,
              softWrap: false,
              textScaler: TextScaler.noScaling,
              style: AppType.editorial(
                size: size,
                weight: FontWeight.w700,
                height: 1,
                letterSpacing: -size / 52,
                color: AppColors.textPrimary.withValues(alpha: 0.09),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
