import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import '../../models/home_models.dart';
import '../../models/news_models.dart';
import '../../models/story_category.dart';
import '../../presentation/providers/reading_providers.dart';
import '../../presentation/providers/premium_access_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/popover_trigger.dart';
import '../../widgets/premium_content_gate.dart';
import '../../widgets/section_heading.dart';
import '../../widgets/story_cover.dart';
import '../home/widgets/story_carousel.dart';
import 'widgets/import_panel.dart';
import 'widgets/news_carousel.dart';

/// The Stories tab: news on top, then "Weiterlesen" (started stories with
/// their progress), the learner's own imported texts, and one carousel per
/// category. "Importieren" opens a popover with the import sources.
class StoryLibraryScreen extends ConsumerWidget {
  const StoryLibraryScreen({
    super.key,
    required this.stories,
    required this.onOpenStory,
    this.status,
    this.collection,
    this.news = const [],
    this.onOpenNews,
    this.progress = const {},
    this.imported = const [],
    this.onOpenImported,
    this.onDeleteImported,
    this.onImportText,
    this.onImported,
    this.scrollController,
  });

  /// Main vertical scroll view; the tab bar scrolls it to the top on re-tap.
  final ScrollController? scrollController;

  static const _gutter = EdgeInsets.symmetric(horizontal: 20);
  static const newsSubheading =
      'Kurze Meldungen zum Einlesen – derzeit Beispielinhalte.';

  final List<Story> stories;
  final Widget? status;
  final Widget? collection;
  final ValueChanged<Story> onOpenStory;

  /// One article per desk; the section is left out when empty.
  final List<NewsArticle> news;
  final ValueChanged<NewsArticle>? onOpenNews;

  /// Reading position per story or imported text id.
  final Map<String, ReadingEntry> progress;

  final List<ImportedText> imported;
  final ValueChanged<ImportedText>? onOpenImported;
  final ValueChanged<ImportedText>? onDeleteImported;

  /// Stores a pasted text; returns an error message or null.
  final String? Function(String text)? onImportText;

  /// Called after a successful import (e.g. to open the new text).
  final VoidCallback? onImported;

  /// The newest day among daily articles; null for the bundled samples.
  DateTime? get _edition => news
      .map((a) => a.edition)
      .whereType<DateTime>()
      .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);

  /// "Heute", "Gestern" or "30.10.".
  String _editionLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(DateTime(day.year, day.month, day.day)).inDays;
    return switch (days) {
      0 => 'Heute',
      1 => 'Gestern',
      _ => '${day.day}.${day.month}.',
    };
  }

  /// Any import entry: opens the import popover and turns orange meanwhile.
  Widget _importTrigger(
    Widget Function(bool open, VoidCallback onPressed) builder,
  ) => PopoverTrigger<bool>(
    popover: (_) => ImportPanel(onImportText: onImportText),
    onClosed: (done) {
      if (done == true) onImported?.call();
    },
    builder: (context, open, show) => builder(open, show),
  );

  /// Feature and image covers, with tall cards replacing the former ranked list.
  Widget _shelf(
    int index,
    List<Story> stories,
    Map<String, double> started,
    Set<String> finished,
    bool premiumLocked,
    VoidCallback onUpgrade,
  ) => switch (stories.length < 3 ? 1 : index % 4) {
    0 => StoryFeatureShelf(
      stories: stories,
      onOpen: onOpenStory,
      progress: started,
      finished: finished,
      premiumLocked: premiumLocked,
      onUpgrade: onUpgrade,
    ),
    2 => StoryCarousel(
      stories: stories,
      onOpen: onOpenStory,
      progress: started,
      finished: finished,
      premiumLocked: premiumLocked,
      onUpgrade: onUpgrade,
    ),
    3 => StoryCarousel(
      stories: stories,
      onOpen: onOpenStory,
      progress: started,
      finished: finished,
      premiumLocked: premiumLocked,
      onUpgrade: onUpgrade,
      width: 232,
      height: 132,
    ),
    _ => StoryCarousel(
      stories: stories,
      onOpen: onOpenStory,
      progress: started,
      finished: finished,
      premiumLocked: premiumLocked,
      onUpgrade: onUpgrade,
    ),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumLocked = !ref.watch(premiumContentAccessProvider);
    void upgrade() => showPremiumContentPaywall(context, interest: 'Stories');
    final groups = <String, List<Story>>{};
    for (final category in StoryCategory.all) {
      groups[category.name] = [];
    }
    for (final story in stories) {
      (groups[StoryCategory.of(story.topic).name] ??= []).add(story);
    }
    groups.removeWhere((_, list) => list.isEmpty);

    final started = {
      for (final MapEntry(:key, :value) in progress.entries)
        if (value.inProgress) key: value.fraction,
    };
    final finished = {
      for (final MapEntry(:key, :value) in progress.entries)
        if (value.finished) key,
    };
    final resume = <(Object, ReadingEntry)>[
      for (final story in stories)
        if (progress[story.id] case final entry? when entry.inProgress)
          (story, entry),
      for (final text in imported)
        if (progress[text.id] case final entry? when entry.inProgress)
          (text, entry),
    ]..sort((a, b) => b.$2.updatedAt.compareTo(a.$2.updatedAt));

    return SafeArea(
      bottom: false,
      child: ListView(
        controller: scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 40),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Stories',
                      style: AppType.editorial(
                        color: context.appColors.textPrimary,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Flexible for large Dynamic Type; Align keeps the pill at
                // the trailing edge instead of mid-row.
                Flexible(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _importTrigger(
                      (open, onPressed) =>
                          _ImportPill(open: open, onPressed: onPressed),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ?collection,
          if (status != null) Padding(padding: _gutter, child: status!),
          if (news.isNotEmpty) ...[
            const SizedBox(height: 18),
            Padding(
              padding: _gutter,
              child: SectionHeading(
                title: 'Nachrichten',
                trailing: switch (_edition) {
                  null => const _DemoChip(),
                  final day => _Count(_editionLabel(day)),
                },
              ),
            ),
            // Only the bundled samples need saying so.
            if (_edition == null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: _gutter,
                child: Text(
                  newsSubheading,
                  style: AppType.meta(color: context.appColors.textMuted),
                ),
              ),
            ],
            const SizedBox(height: 14),
            NewsDesks(articles: news, onOpen: (a) => onOpenNews?.call(a)),
          ],
          if (resume.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Padding(
              padding: _gutter,
              child: SectionHeading(title: 'Weiterlesen'),
            ),
            const SizedBox(height: 12),
            ContinueReadingPages(
              children: [
                for (final (item, entry) in resume)
                  switch (item) {
                    Story story => ContinueReadingTile(
                      story: story,
                      title: story.title,
                      meta: story.topic,
                      category: StoryCategory.of(story.topic),
                      fraction: entry.fraction,
                      onTap: () => onOpenStory(story),
                      premiumLocked: premiumLocked,
                      onUpgrade: upgrade,
                    ),
                    ImportedText text => ContinueReadingTile(
                      title: text.title,
                      meta: 'Eigener Text',
                      category: _importCategory,
                      fraction: entry.fraction,
                      onTap: () => onOpenImported?.call(text),
                      premiumLocked: premiumLocked,
                      onUpgrade: upgrade,
                    ),
                    _ => const SizedBox.shrink(),
                  },
              ],
            ),
          ],
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: SectionHeading(
              title: 'Deine Texte',
              trailing: imported.isEmpty
                  ? null
                  : _Count(
                      imported.length == 1
                          ? '1 Text'
                          : '${imported.length} Texte',
                    ),
            ),
          ),
          const SizedBox(height: 12),
          if (imported.isEmpty)
            Padding(
              padding: _gutter,
              child: _ImportPrompt(trigger: _importTrigger),
            )
          else
            SizedBox(
              height: _ImportedCard.height,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: _gutter,
                children: [
                  _importTrigger(
                    (open, onPressed) =>
                        _AddTextCard(open: open, onPressed: onPressed),
                  ),
                  for (final text in imported) ...[
                    const SizedBox(width: 12),
                    _ImportedCard(
                      text: text,
                      progress: progress[text.id],
                      onTap: () => onOpenImported?.call(text),
                      premiumLocked: premiumLocked,
                      onUpgrade: upgrade,
                      onDelete: onDeleteImported == null
                          ? null
                          : () => onDeleteImported!(text),
                    ),
                  ],
                ],
              ),
            ),
          // Categories keep their image-led shelves; compact ranked rows belong
          // to the text exercises under Inhalte (01.11.2026).
          for (final (i, MapEntry(key: topic, value: group))
              in groups.entries.indexed) ...[
            const SizedBox(height: 28),
            Padding(
              padding: _gutter,
              child: SectionHeading(
                title: topic,
                trailing: _Count(
                  group.length == 1 ? '1 Story' : '${group.length} Stories',
                ),
              ),
            ),
            const SizedBox(height: 12),
            _shelf(
              i,
              shelfOrder(group, progress: started, finished: finished),
              started,
              finished,
              premiumLocked,
              upgrade,
            ),
          ],
        ],
      ),
    );
  }
}

const _importCategory = StoryCategory(
  'Eigener Text',
  Color(0xFF6B5A43),
  CupertinoIcons.doc_text,
);

class _Count extends StatelessWidget {
  const _Count(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppType.meta(color: context.appColors.textMuted));
}

class _DemoChip extends StatelessWidget {
  const _DemoChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: context.appColors.raisedInk,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      'Demo',
      style: AppType.meta(color: context.appColors.textMuted),
    ),
  );
}

/// "Text importieren": the same pill at the top of the tab and in the
/// empty "Deine Texte" (user request 01.11.2026). Orange text on Active
/// Tint; popover orange with white text while the import popover is open.
class _ImportPill extends StatelessWidget {
  const _ImportPill({required this.onPressed, this.open = false});
  final VoidCallback onPressed;
  final bool open;

  static const height = 40.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final ink = open ? const Color(0xFFFFFFFF) : colors.active;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: 'Text importieren',
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: height),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: open ? colors.popover : colors.activeTint,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.plus, size: 16, color: ink),
                const SizedBox(width: 6),
                // Large Dynamic Type shortens the label; semantics stay whole.
                Flexible(
                  child: Text(
                    'Text importieren',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.chrome(weight: FontWeight.w700, color: ink),
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

/// Empty "Deine Texte": a small import symbol as tall as the pill beside it;
/// no explanation, the pill says it (user request 01.11.2026).
class _ImportPrompt extends StatelessWidget {
  const _ImportPrompt({required this.trigger});
  final Widget Function(Widget Function(bool open, VoidCallback onPressed))
  trigger;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.raisedInk,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: _ImportPill.height,
              height: _ImportPill.height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.nightPage,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                CupertinoIcons.square_arrow_down,
                size: 20,
                color: colors.active,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: trigger(
              (open, onPressed) =>
                  _ImportPill(open: open, onPressed: onPressed),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTextCard extends StatelessWidget {
  const _AddTextCard({required this.onPressed, this.open = false});
  final VoidCallback onPressed;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: 'Weiteren Text importieren',
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 96,
            height: _ImportedCard.height,
            decoration: BoxDecoration(
              color: open ? colors.popover : colors.raisedInk,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.plus,
                  size: 28,
                  color: open ? const Color(0xFFFFFFFF) : colors.active,
                ),
                const SizedBox(height: 6),
                Text(
                  'Import',
                  style: AppType.meta(
                    color: open ? const Color(0xFFFFFFFF) : colors.textMuted,
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

/// A learner's own text: paper-coloured card with the source and length.
class _ImportedCard extends StatelessWidget {
  const _ImportedCard({
    required this.text,
    required this.onTap,
    this.progress,
    this.onDelete,
    this.premiumLocked = false,
    this.onUpgrade,
  });

  static const height = 168.0;
  static const _paper = Color(0xFFF3EDE2);
  static const _ink = Color(0xFF2A2621);

  final ImportedText text;
  final ReadingEntry? progress;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool premiumLocked;
  final VoidCallback? onUpgrade;

  Future<void> _confirmDelete(BuildContext context) async {
    final delete = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(text.title),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Text löschen'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
      ),
    );
    if (delete == true) onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (text.source) {
      ImportSource.youtube => CupertinoIcons.play_rectangle,
      ImportSource.web => CupertinoIcons.globe,
      _ => CupertinoIcons.doc_text,
    };
    final entry = progress;
    final started = entry != null && entry.inProgress;
    return Semantics(
      customSemanticsActions: {
        if (onDelete != null)
          const CustomSemanticsAction(label: 'Löschen'): () =>
              _confirmDelete(context),
      },
      child: GestureDetector(
        onLongPress: onDelete == null ? null : () => _confirmDelete(context),
        child: MergeSemantics(
          child: CupertinoButton(
            onPressed: premiumLocked ? onUpgrade : onTap,
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            pressedOpacity: 0.8,
            child: Semantics(
              label:
                  'Eigener Text: ${text.title}, ${text.wordCount} Wörter'
                  '${started ? ', ${(entry.fraction * 100).round()} Prozent gelesen' : ''}'
                  '${premiumLocked ? ', mit Premium freischalten' : ''}',
              excludeSemantics: true,
              child: Container(
                width: 150,
                height: height,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 22, color: const Color(0xFF8A6E4B)),
                        const Spacer(),
                        if (premiumLocked) const PremiumLockBadge(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        text.title,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.editorial(
                          color: _ink,
                          size: 17,
                          height: 1.25,
                        ),
                      ),
                    ),
                    Text(
                      started
                          ? '${(entry.fraction * 100).round()} % gelesen'
                          : '${text.wordCount} Wörter',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.meta(color: const Color(0xFF6E6457)),
                    ),
                    if (started) ...[
                      const SizedBox(height: 6),
                      ReadingBar(fraction: entry.fraction),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Weiterlesen": up to three tiles stacked. More scroll sideways in pages
/// of at most three, spread evenly so no page stands half empty: 4 → 2 + 2,
/// 5 → 3 + 2, 7 → 3 + 2 + 2 (user request 01.11.2026). The next page peeks
/// in from the right; the row is as tall as its fullest page.
class ContinueReadingPages extends StatefulWidget {
  const ContinueReadingPages({super.key, required this.children});

  final List<Widget> children;

  static const perPage = 3;
  static const _gap = 10.0;
  static const _gutter = 20.0;
  static const _viewportFraction = 0.9;

  /// How many tiles each page holds, earlier pages first.
  static List<int> pageSizes(int count) {
    if (count <= 0) return const [];
    final pages = (count + perPage - 1) ~/ perPage;
    return [
      for (var i = 0; i < pages; i++)
        count ~/ pages + (i < count % pages ? 1 : 0),
    ];
  }

  @override
  State<ContinueReadingPages> createState() => _ContinueReadingPagesState();
}

class _ContinueReadingPagesState extends State<ContinueReadingPages> {
  final _pages = PageController(
    viewportFraction: ContinueReadingPages._viewportFraction,
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Widget _column(List<Widget> tiles) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, tile) in tiles.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : ContinueReadingPages._gap),
          child: tile,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final tiles = widget.children;
    final sizes = ContinueReadingPages.pageSizes(tiles.length);
    if (sizes.length <= 1) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ContinueReadingPages._gutter,
        ),
        child: _column(tiles),
      );
    }
    final pages = <List<Widget>>[];
    var start = 0;
    for (final size in sizes) {
      pages.add(tiles.sublist(start, start + size));
      start += size;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth * ContinueReadingPages._viewportFraction -
            ContinueReadingPages._gutter;
        // An invisible copy of every page sets the height: the tallest
        // page wins, whatever its titles wrap to.
        return Stack(
          children: [
            ExcludeSemantics(
              child: Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: ContinueReadingPages._gutter,
                  ),
                  child: IndexedStack(
                    children: [
                      for (final page in pages)
                        SizedBox(width: width, child: _column(page)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: PageView(
                controller: _pages,
                padEnds: false,
                physics: const BouncingScrollPhysics(),
                children: [
                  for (final page in pages)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: ContinueReadingPages._gutter,
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(width: width, child: _column(page)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Started story or text: small cover, title, category and the reading
/// position as a bar with percent.
class ContinueReadingTile extends StatelessWidget {
  const ContinueReadingTile({
    super.key,
    required this.title,
    required this.meta,
    required this.category,
    required this.fraction,
    required this.onTap,
    this.story,
    this.premiumLocked = false,
    this.onUpgrade,
  });

  final Story? story;
  final String title;
  final String meta;
  final StoryCategory category;
  final double fraction;
  final VoidCallback onTap;
  final bool premiumLocked;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final percent = (fraction * 100).round();
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: premiumLocked ? onUpgrade : onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.75,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label:
              'Weiterlesen: $title, $meta, $percent Prozent gelesen'
              '${premiumLocked ? ', mit Premium freischalten' : ''}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.raisedInk,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                if (story case final story?)
                  StoryCover(
                    story: story,
                    width: 56,
                    height: 72,
                    radius: 12,
                    texture: false,
                  )
                else
                  Container(
                    width: 56,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          category.color,
                          Color.lerp(
                            category.color,
                            const Color(0xFF000000),
                            0.35,
                          )!,
                        ],
                      ),
                    ),
                    child: Icon(
                      category.icon,
                      size: 28,
                      color: const Color(0xCCFFFFFF),
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.editorial(
                          color: colors.textPrimary,
                          size: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(meta, style: AppType.meta(color: colors.textMuted)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ReadingBar(fraction: fraction, height: 5),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$percent %',
                            style: AppType.chrome(
                              size: 13,
                              weight: FontWeight.w800,
                              color: colors.textPrimary,
                              tabular: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                if (premiumLocked)
                  const PremiumLockBadge()
                else
                  Icon(
                    CupertinoIcons.play_circle_fill,
                    size: 32,
                    color: colors.active,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
