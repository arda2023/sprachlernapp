import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../domain/srs_state.dart' show LexicalBreakdown, VocabBreakdown;
import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/count_format.dart';
import '../../../widgets/popover_content.dart';

/// One tile per progress measure (title, number, bar). Tapping highlights the
/// tile and explains the measure in a popover pointing at it. All values stay
/// derived from card state.
class ProgressTiles extends StatefulWidget {
  const ProgressTiles({super.key, required this.breakdown, this.lexical});

  final VocabBreakdown breakdown;

  /// Without word counts only the two exercise tiles show.
  final LexicalBreakdown? lexical;

  @override
  State<ProgressTiles> createState() => _ProgressTilesState();
}

class _ProgressTilesState extends State<ProgressTiles> {
  ProgressKind? _selected;

  List<ProgressMeasure> get _measures => [
    ProgressMeasure.building(widget.breakdown),
    ProgressMeasure.mastered(widget.breakdown),
    if (widget.lexical case final l?)
      ProgressMeasure.words(l, widget.breakdown),
  ];

  Future<void> _open(BuildContext tileContext, ProgressMeasure m) async {
    HapticFeedback.selectionClick();
    setState(() => _selected = m.kind);
    final all = _measures;
    await showAnchoredPopover<void>(
      anchorContext: tileContext,
      color: context.appColors.popover,
      builder: (_) => _Explanation(shown: m, all: all),
    );
    if (mounted) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final items = _measures;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth / items.length < 108 || scale > 1.3;
        final tiles = [
          for (final m in items)
            Builder(
              builder: (tileContext) => _Tile(
                measure: m,
                selected: _selected == m.kind,
                onTap: () => _open(tileContext, m),
              ),
            ),
        ];
        if (stacked) {
          return Column(
            children: [
              for (final (i, t) in tiles.indexed)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                  child: t,
                ),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, t) in tiles.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: t),
              ],
            ],
          ),
        );
      },
    );
  }
}

enum ProgressKind { building, mastered, words }

class ProgressMeasure {
  const ProgressMeasure({
    required this.kind,
    required this.title,
    required this.value,
    required this.total,
    required this.unit,
    required this.explanation,
  });

  // Explanations are kept about equally long; the popover is sized to the
  // longest anyway, so all three open at the same size.
  factory ProgressMeasure.building(VocabBreakdown b) => ProgressMeasure(
    kind: ProgressKind.building,
    title: 'Im Aufbau',
    value: b.building,
    total: b.total,
    unit: 'Übungen',
    explanation:
        'Übungen, die du schon kennst, die aber noch nicht sicher sitzen '
        '(Stufe 1–4). Jede richtige Wiederholung hebt sie eine Stufe höher.',
  );

  factory ProgressMeasure.mastered(VocabBreakdown b) => ProgressMeasure(
    kind: ProgressKind.mastered,
    title: 'Gemeistert',
    value: b.mastered,
    total: b.total,
    unit: 'Übungen',
    explanation:
        'Übungen auf der höchsten Stufe (Stufe 5). Sie kommen nur noch selten '
        'zur Kontrolle wieder – ungefähr alle drei Monate einmal.',
  );

  factory ProgressMeasure.words(LexicalBreakdown l, VocabBreakdown b) =>
      ProgressMeasure(
        kind: ProgressKind.words,
        title: 'Wörter geübt',
        value: l.practiced,
        total: l.total,
        unit: 'Wörtern',
        explanation:
            'Wörter, von denen du schon eine Form beantwortet hast. Ein Wort '
            'kann mehrere Übungen haben – zum Beispiel go, went und gone.',
      );

  final ProgressKind kind;
  final String title;
  final int value;
  final int total;
  final String unit;
  final String explanation;

  double get fraction => total == 0 ? 0 : (value / total).clamp(0.0, 1.0);

  String get summary =>
      '${formatCountDe(value)} von ${formatCountDe(total)} $unit';

  Color ink(AppPalette colors) => switch (kind) {
    ProgressKind.building => colors.progressBuilding,
    ProgressKind.mastered => colors.progressMastered,
    ProgressKind.words => colors.progressWords,
  };
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.measure,
    required this.selected,
    required this.onTap,
  });

  final ProgressMeasure measure;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final m = measure;
    const white = Color(0xFFFFFFFF);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = Duration(milliseconds: reduced ? 0 : 180);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        pressedOpacity: 0.85,
        child: Semantics(
          label: '${m.title}: ${m.summary}. Erklärung öffnen',
          excludeSemantics: true,
          child: AnimatedScale(
            scale: selected ? 1.06 : 1,
            duration: duration,
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: duration,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected ? colors.popover : colors.raisedInk,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.meta(
                      color: selected ? white : colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCountDe(m.value),
                    style: AppType.chrome(
                      size: 24,
                      weight: FontWeight.w800,
                      color: selected ? white : colors.textPrimary,
                      tabular: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Bar(
                    fraction: m.fraction,
                    color: selected ? white : m.ink(colors),
                    track: selected
                        ? white.withValues(alpha: 0.3)
                        : colors.hairline,
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

class _Bar extends StatelessWidget {
  const _Bar({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: SizedBox(
      height: 6,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: track),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            // A started measure never looks empty.
            widthFactor: fraction == 0 ? 0 : fraction.clamp(0.04, 1.0),
            child: ColoredBox(color: color),
          ),
        ],
      ),
    ),
  );
}

/// All explanations are laid out on top of each other so the popover has the
/// same size for every tile; only [shown] is visible.
class _Explanation extends StatelessWidget {
  const _Explanation({required this.shown, required this.all});

  final ProgressMeasure shown;
  final List<ProgressMeasure> all;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final m in all)
          Visibility(
            visible: m.kind == shown.kind,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: _ExplanationBody(measure: m),
          ),
      ],
    );
  }
}

class _ExplanationBody extends StatelessWidget {
  const _ExplanationBody({required this.measure});

  final ProgressMeasure measure;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    final m = measure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            m.title,
            style: AppType.chrome(
              size: 20,
              weight: FontWeight.w800,
              color: white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          m.summary,
          style: AppType.chrome(
            size: 15,
            weight: FontWeight.w700,
            color: white,
            tabular: true,
          ),
        ),
        const SizedBox(height: 10),
        Text(m.explanation, style: PopoverText.small()),
      ],
    );
  }
}
