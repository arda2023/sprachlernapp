import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/streak.dart';
import '../../../models/word_list_models.dart';
import '../../../presentation/providers/streak_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/popover_trigger.dart';
import '../../../widgets/svg_glyph.dart';

/// The week box (like streak4): checked days merge into one filled pill, open
/// days are empty circles, a missed day is a grey circle with a cross, the
/// star is day 7. Below a faint rule, one motivating sentence. Tapping opens
/// the streak calendar.
class StreakStrip extends ConsumerStatefulWidget {
  const StreakStrip({
    super.key,
    required this.summary,
    required this.calendar,
    this.wordOfWeek,
  });

  final StreakSummary summary;

  /// Calendar popover content; the box turns orange while it is open.
  final WidgetBuilder calendar;
  final VocabWord? wordOfWeek;

  @override
  ConsumerState<StreakStrip> createState() => _StreakStripState();
}

class _StreakStripState extends ConsumerState<StreakStrip>
    with SingleTickerProviderStateMixin {
  late final _star = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  ValueListenable<TickerModeData>? _tickerMode;
  bool _checking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = TickerMode.getValuesNotifier(context);
    if (notifier != _tickerMode) {
      _tickerMode?.removeListener(_maybeCelebrate);
      _tickerMode = notifier..addListener(_maybeCelebrate);
    }
    _maybeCelebrate();
  }

  @override
  void didUpdateWidget(StreakStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeCelebrate();
  }

  /// Plays once per star day, the first time Home is actually on screen
  /// (not while a practice session still covers it).
  Future<void> _maybeCelebrate() async {
    final summary = widget.summary;
    if (!summary.starToday || _checking || _star.isAnimating) return;
    if (!(_tickerMode?.value.enabled ?? false)) return;
    final day = summary.latestStar!;
    final marks = ref.read(celebrationMarksProvider);
    _checking = true;
    try {
      if (await marks.celebrated(day) || !mounted) return;
      if (!(_tickerMode?.value.enabled ?? false)) return;
      await marks.markCelebrated(day);
      if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
      HapticFeedback.mediumImpact();
      _star.forward(from: 0);
    } finally {
      _checking = false;
    }
  }

  @override
  void dispose() {
    _tickerMode?.removeListener(_maybeCelebrate);
    _star.dispose();
    super.dispose();
  }

  /// One sentence with the important words emphasised (bold, accent).
  List<(String, bool)> get _motivation {
    final s = widget.summary;
    if (s.activeDays.isEmpty) {
      return const [
        ('Starte heute deine erste ', false),
        ('Serie', true),
        ('!', false),
      ];
    }
    if (s.starToday) {
      return const [('Wochenstern', true), (' geholt – richtig stark!', false)];
    }
    if (s.barMissed) {
      return switch (s.weeks) {
        0 => const [
          ('Neuer Anlauf – ', false),
          ('heute', true),
          (' zählt wieder.', false),
        ],
        1 => const [
          ('Neuer Anlauf – ', false),
          ('dein Stern', true),
          (' bleibt dir.', false),
        ],
        final n => [
          ('Neuer Anlauf – ', false),
          ('deine $n Sterne', true),
          (' bleiben dir.', false),
        ],
      };
    }
    if (!s.practicedToday) {
      return [
        ('Übe heute und sichere dir ', false),
        ('Tag ${s.current + 1}', true),
        ('!', false),
      ];
    }
    return switch (s.barFilled) {
      1 => const [
        ('Guter Start – ', false),
        ('Tag 1', true),
        (' ist geschafft!', false),
      ],
      2 => const [('Zwei Tage', true), (' am Stück – bleib dran!', false)],
      3 => const [
        ('Fast schon die ', false),
        ('halbe Woche', true),
        (' geschafft!', false),
      ],
      4 => const [
        ('Über die Hälfte – dein ', false),
        ('Wochenstern', true),
        (' rückt näher!', false),
      ],
      5 => const [
        ('Nur noch ', false),
        ('zwei Tage', true),
        (' bis zu deinem ', false),
        ('Wochenstern', true),
        ('!', false),
      ],
      _ => const [
        ('Morgen holst du dir deinen ', false),
        ('Wochenstern', true),
        ('!', false),
      ],
    };
  }

  String get _semantics {
    final s = widget.summary;
    final days = s.current == 1 ? '1 Tag' : '${s.current} Tage';
    final week = s.starToday
        ? 'Wochenstern heute geholt'
        : '${s.barFilled} von 7 Tagen dieser Woche'
              '${s.barMissed ? ', ein Tag verpasst' : ''}';
    final sentence = _motivation.map((p) => p.$1).join();
    return 'Streak $days. $week. $sentence Kalender öffnen';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final word = widget.wordOfWeek;
    final base = AppType.chrome(
      size: 15,
      weight: FontWeight.w600,
      color: colors.textMuted,
      height: 1.3,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PopoverTrigger<void>(
          popover: widget.calendar,
          builder: (context, open, show) {
            const white = Color(0xFFFFFFFF);
            final text = base.copyWith(
              color: open ? white.withValues(alpha: 0.9) : null,
            );
            return MergeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: show,
                child: Semantics(
                  button: true,
                  label: _semantics,
                  excludeSemantics: true,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                    decoration: BoxDecoration(
                      color: open ? colors.popover : colors.raisedInk,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WeekBar(
                          summary: widget.summary,
                          star: _star,
                          onAccent: open,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: open
                              ? white.withValues(alpha: 0.3)
                              : colors.hairline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text.rich(
                          TextSpan(
                            style: text,
                            children: [
                              for (final (part, strong) in _motivation)
                                TextSpan(
                                  text: part,
                                  style: strong
                                      ? text.copyWith(
                                          color: open ? white : colors.active,
                                          fontWeight: FontWeight.w800,
                                        )
                                      : null,
                                ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (word != null) ...[
          const SizedBox(height: 12),
          _WordOfWeek(word: word),
        ],
      ],
    );
  }
}

/// Six day slots plus the star, laid out on one grid so the pill, the
/// circles and the star always line up.
class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.summary,
    required this.star,
    this.onAccent = false,
  });

  static const _size = 32.0;
  static const _starSlot = 44.0;

  final StreakSummary summary;
  final Animation<double> star;

  /// Drawn on the orange box (calendar open): pill white, marks orange.
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const white = Color(0xFFFFFFFF);
    final pill = onAccent ? white : colors.active;
    final mark = onAccent ? colors.popover : white;
    final filled = summary.barFilled;
    final lit = summary.starToday;
    final missedSlot = summary.barMissed ? filled : null;
    return SizedBox(
      height: _size,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = (constraints.maxWidth - _starSlot) / streakBarDays;
          double centre(int i) => i < streakBarDays
              ? slot * (i + 0.5)
              : slot * streakBarDays + _starSlot / 2;
          Widget at(int i, Widget child) => Positioned(
            left: centre(i) - _size / 2,
            top: 0,
            width: _size,
            height: _size,
            child: Center(child: child),
          );
          final pillWidth = lit ? constraints.maxWidth : filled * slot;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = filled; i < streakBarDays; i++)
                if (i != missedSlot)
                  at(
                    i,
                    _Circle(
                      color: onAccent
                          ? white.withValues(alpha: 0.25)
                          : colors.hairline,
                    ),
                  ),
              if (pillWidth > 0)
                Positioned(
                  left: 2,
                  top: 0,
                  width: pillWidth - 4,
                  height: _size,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: pill,
                      borderRadius: BorderRadius.circular(_size),
                    ),
                  ),
                ),
              for (var i = 0; i < filled; i++)
                at(i, GlyphIcon(AppGlyphs.check, size: 15, color: mark)),
              if (missedSlot != null)
                at(
                  missedSlot,
                  _Circle(
                    color: colors.iconOff,
                    child: const GlyphIcon(
                      AppGlyphs.cross,
                      size: 12,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              if (missedSlot != streakBarDays)
                at(
                  streakBarDays,
                  _Star(lit: lit, animation: star, onAccent: onAccent),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.color, this.child});

  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    width: _WeekBar._size,
    height: _WeekBar._size,
    alignment: Alignment.center,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: child,
  );
}

/// Open: orange outline. Earned: white solid inside the pill; it grows,
/// turns and lights up once when the week is complete.
class _Star extends StatelessWidget {
  const _Star({
    required this.lit,
    required this.animation,
    this.onAccent = false,
  });

  final bool lit;
  final Animation<double> animation;
  final bool onAccent;

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 1.9,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.9,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]);

  static final _glow = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 70),
  ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (!lit) {
      return GlyphIcon(
        AppGlyphs.starOutline,
        size: 30,
        color: onAccent ? const Color(0xFFFFFFFF) : colors.active,
      );
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final glow = animation.isAnimating ? _glow.transform(t) : 0.0;
        return Transform.rotate(
          angle: Curves.easeInOutCubic.transform(t) * 2 * math.pi,
          child: Transform.scale(
            scale: animation.isAnimating ? _scale.transform(t) : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  if (glow > 0)
                    BoxShadow(
                      color: const Color(0xFFFFE2A8)
                          .withValues(alpha: 0.8 * glow),
                      blurRadius: 18 * glow,
                      spreadRadius: 4 * glow,
                    ),
                ],
              ),
              child: GlyphIcon(
                AppGlyphs.starSolid,
                size: 24,
                color: onAccent ? colors.popover : const Color(0xFFFFFFFF),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WordOfWeek extends StatelessWidget {
  const _WordOfWeek({required this.word});

  final VocabWord word;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final translation = word.entry.translation;
    return Semantics(
      container: true,
      label:
          'Wort der Woche: ${word.entry.headword}'
          '${translation.isEmpty ? '' : ', $translation'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.activeTint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.star_fill, size: 16, color: colors.active),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wort der Woche',
                    style: AppType.meta(color: colors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: word.entry.headword,
                          style: AppType.editorial(
                            size: 19,
                            color: colors.textPrimary,
                          ),
                        ),
                        if (translation.isNotEmpty)
                          TextSpan(
                            text: '  ·  $translation',
                            style: AppType.chrome(color: colors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
