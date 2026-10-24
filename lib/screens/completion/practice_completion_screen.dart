import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/streak.dart';
import '../../models/home_models.dart';
import '../../presentation/celebration_sounds.dart';
import '../../presentation/providers/streak_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/svg_glyph.dart';
import 'widgets/stacked_word_cards.dart';
import 'widgets/streak_charge_bar.dart';
import 'widgets/completion_flame.dart';

/// Shown after a deck practice session once the daily goal is reached
/// (docs/redesign/design-system.md › Abschluss). The streak bar appears in
/// the middle and charges up to today – checks pop one after another, the
/// phone buzzes while it charges, day seven flips the star – while the
/// headline fades in above it. Then both glide to the top and the rest
/// settles below: streak and daily goal side by side, the session's words as
/// stacked cards, "Weiter".
class PracticeCompletionScreen extends ConsumerStatefulWidget {
  const PracticeCompletionScreen({
    super.key,
    required this.streak,
    required this.goal,
    required this.words,
  });

  final StreakSummary streak;
  final DailyGoal goal;
  final List<CompletionWord> words;

  static Route<void> route({
    required StreakSummary streak,
    required DailyGoal goal,
    required List<CompletionWord> words,
  }) => CupertinoPageRoute<void>(
    builder: (_) =>
        PracticeCompletionScreen(streak: streak, goal: goal, words: words),
  );

  @override
  ConsumerState<PracticeCompletionScreen> createState() =>
      _PracticeCompletionScreenState();
}

class _PracticeCompletionScreenState
    extends ConsumerState<PracticeCompletionScreen>
    with TickerProviderStateMixin {
  /// Time the pill needs per day, and how long the last check keeps
  /// popping after the pill has stopped.
  static const _perDay = Duration(milliseconds: 420);
  static const _tail = 1.4;

  late final int _target = widget.streak.starToday
      ? streakBarDays + 1
      : widget.streak.barFilled.clamp(0, streakBarDays);

  late final _appear = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final _charge = AnimationController(
    vsync: this,
    duration: _perDay * (_target + _tail),
  );
  late final _days = _charge.drive(Tween(begin: 0.0, end: _target + _tail));
  late final _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final _glowOff = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
    value: 1,
  );
  late final _star = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  );
  late final _title = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  /// The first quarter is a pause before header and bar glide up.
  late final _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final _glide = CurvedAnimation(
    parent: _settle,
    curve: const Interval(0.28, 1, curve: Curves.easeInOutCubic),
  );
  late final _content = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  final _headerKey = GlobalKey();
  double? _headerHeight;
  Timer? _buzz;
  int _popped = 0;
  bool _barFull = false;
  bool _started = false;
  bool _done = false;
  Future<void>? _starFlip;

  CelebrationSounds get _sounds => ref.read(celebrationSoundsProvider);

  @override
  void initState() {
    super.initState();
    _charge.addListener(_onCharge);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        _skipToEnd();
      } else {
        unawaited(_run());
      }
    }
  }

  void _measure() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && mounted) {
      setState(() => _headerHeight = box.size.height);
    }
  }

  /// Reduced motion: final state at once, one confirming tap, no sound.
  void _skipToEnd() {
    _done = true;
    _charge.removeListener(_onCharge);
    for (final c in [_appear, _charge, _star, _title, _settle, _content]) {
      c.value = 1;
    }
    _glowOff.value = 0;
    _barFull = true;
    _popped = _target;
    HapticFeedback.mediumImpact();
  }

  Future<void> _run() async {
    await _appear.forward();
    if (!mounted) return;
    if (_target > 0) {
      _sounds.charge();
      _shimmer.repeat();
      // A steady buzz while the battery charges.
      _buzz = Timer.periodic(
        const Duration(milliseconds: 55),
        (_) => HapticFeedback.lightImpact(),
      );
      await _charge.forward();
    } else {
      await _title.forward();
    }
    if (!mounted) return;
    if (widget.streak.starToday) await _starMoment();
    if (!mounted) return;
    await _settle.forward();
    if (!mounted) return;
    await _content.forward();
    if (mounted) setState(() => _done = true);
  }

  /// Checks pop as the pill passes them; the buzz and the charge sound stop
  /// when the pill arrives; the star flips once it is reached.
  void _onCharge() {
    final days = _days.value;
    // The headline follows shortly after the bar starts.
    if (days >= 0.6 && _title.isDismissed) _title.forward();
    final checks = _target.clamp(0, streakBarDays);
    while (_popped < checks && days >= _popped + StreakChargeBar.popAt) {
      _popped++;
      _sounds.check();
      HapticFeedback.mediumImpact();
    }
    if (!_barFull && days >= _target) {
      _barFull = true;
      _buzz?.cancel();
      _sounds.stopCharge();
      _glowOff.reverse().whenComplete(_shimmer.stop);
      if (widget.streak.starToday) unawaited(_starMoment());
    }
  }

  /// Starts the flip once; every caller waits for the same run.
  Future<void> _starMoment() => _starFlip ??= _flipStar();

  Future<void> _flipStar() async {
    _sounds.star();
    HapticFeedback.heavyImpact();
    // The Home star moment must not play this star again.
    if (widget.streak.latestStar case final day?) {
      unawaited(
        ref
            .read(celebrationMarksProvider)
            .markCelebrated(day)
            .catchError((Object _) {}),
      );
    }
    // A second tap when the filled side turns to the front.
    void landing() {
      if (_star.value >= 0.5) {
        _star.removeListener(landing);
        HapticFeedback.mediumImpact();
      }
    }

    _star.addListener(landing);
    await _star.forward();
  }

  @override
  void dispose() {
    _buzz?.cancel();
    _charge.removeListener(_onCharge);
    for (final c in [
      _appear,
      _charge,
      _shimmer,
      _glowOff,
      _star,
      _title,
      _settle,
      _content,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _headline =>
      widget.streak.starToday ? 'Wochenstern geholt!' : 'Sehr gut!';

  String get _subtitle {
    final s = widget.streak;
    if (s.starToday) return 'Sieben Tage am Stück – das ist dein Wochenstern.';
    if (s.current <= 1) return 'Tagesziel geschafft – Tag 1 deiner Serie.';
    final left = s.daysToStar;
    return 'Tag ${s.current} in Folge. Noch $left '
        '${left == 1 ? 'Tag' : 'Tage'} bis zum Wochenstern.';
  }

  /// Staggered entrance for the parts below the header.
  Animation<double> _part(double from, double to) => CurvedAnimation(
    parent: _content,
    curve: Interval(from, to, curve: Curves.easeOutCubic),
  );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const top = 28.0;
                  final header = _headerHeight ?? 210;
                  // Starts in the middle of the screen, ends at the top.
                  final centred = (constraints.maxHeight - header) / 2 - top;
                  return AnimatedBuilder(
                    animation: _settle,
                    builder: (context, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, top, 20, 0),
                          child: Transform.translate(
                            offset: Offset(0, centred * (1 - _glide.value)),
                            child: _Header(
                              key: _headerKey,
                              appear: _appear,
                              title: _title,
                              headline: _headline,
                              subtitle: _subtitle,
                              semantics:
                                  'Streak ${widget.streak.current} '
                                  '${widget.streak.current == 1 ? 'Tag' : 'Tage'}'
                                  '${widget.streak.starToday ? ', Wochenstern geholt' : ', ${widget.streak.barFilled} von 7 Tagen dieser Woche'}',
                              bar: StreakChargeBar(
                                target: _target,
                                days: _days,
                                shimmer: _shimmer,
                                star: _star,
                                charging: _glowOff,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: _Rise(
                            animation: _part(0, 0.45),
                            child: _Stats(
                              streak: widget.streak.current,
                              goal: widget.goal,
                            ),
                          ),
                        ),
                        if (widget.words.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                            child: _Rise(
                              animation: _part(0.2, 0.65),
                              child: Semantics(
                                header: true,
                                child: Text(
                                  widget.words.any((w) => w.isNew)
                                      ? 'Neue Wörter'
                                      : 'Heute geübt',
                                  style: AppType.editorial(
                                    color: colors.textPrimary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _Rise(
                              animation: _part(0.35, 1),
                              child: LayoutBuilder(
                                builder: (context, cardConstraints) =>
                                    CustomScrollView(
                                      key: const ValueKey(
                                        'completion-word-scroll',
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                      physics: _done
                                          ? const BouncingScrollPhysics(
                                              parent:
                                                  AlwaysScrollableScrollPhysics(),
                                            )
                                          : const NeverScrollableScrollPhysics(),
                                      slivers: [
                                        SliverToBoxAdapter(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              20,
                                              12,
                                              20,
                                              0,
                                            ),
                                            child: Column(
                                              children: [
                                                StackedWordCards(
                                                  words: widget.words,
                                                ),
                                                SizedBox(
                                                  height:
                                                      cardConstraints.maxHeight,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                        ] else
                          const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _Rise(
                animation: _part(0.5, 1),
                child: PrimaryActionButton(
                  label: 'Weiter',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fades and lifts a part into place.
class _Rise extends StatelessWidget {
  const _Rise({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) => IgnorePointer(
      // Not tappable while it is still invisible.
      ignoring: animation.value == 0,
      child: Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - animation.value)),
          child: child,
        ),
      ),
    ),
    child: child,
  );
}

class _Header extends StatelessWidget {
  const _Header({
    super.key,
    required this.appear,
    required this.title,
    required this.headline,
    required this.subtitle,
    required this.semantics,
    required this.bar,
  });

  final Animation<double> appear;
  final Animation<double> title;
  final String headline;
  final String subtitle;
  final String semantics;
  final Widget bar;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final titleIn = CurvedAnimation(parent: title, curve: Curves.easeOutCubic);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: titleIn,
          builder: (context, child) => Opacity(
            opacity: titleIn.value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - titleIn.value)),
              child: child,
            ),
          ),
          child: Column(
            children: [
              Semantics(
                header: true,
                child: Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: AppType.editorial(color: colors.textPrimary, size: 32),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: AppType.chrome(
                  size: 16,
                  color: colors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        AnimatedBuilder(
          animation: appear,
          builder: (context, child) {
            final t = Curves.easeOutBack.transform(appear.value);
            return Opacity(
              opacity: appear.value,
              child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
            );
          },
          child: Semantics(
            label: semantics,
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                color: colors.raisedInk,
                borderRadius: BorderRadius.circular(20),
              ),
              child: bar,
            ),
          ),
        ),
      ],
    );
  }
}

/// Streak (flame) and daily goal side by side.
class _Stats extends StatelessWidget {
  const _Stats({required this.streak, required this.goal});

  final int streak;
  final DailyGoal goal;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(
              label: streak == 1 ? 'Tag in Folge' : 'Tage in Folge',
              value: '$streak',
              semantics:
                  'Streak: $streak ${streak == 1 ? 'Tag' : 'Tage'} in Folge',
              icon: const CompletionFlame(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: 'Tagesziel',
              value: '${goal.done}/${goal.target}',
              semantics:
                  'Tagesziel: ${goal.done} von ${goal.target} Wörtern geübt',
              icon: GlyphIcon(
                AppGlyphs.target,
                size: 24,
                color: colors.progressWords,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.semantics,
    required this.icon,
  });

  final String label;
  final String value;
  final String semantics;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: colors.raisedInk,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppType.meta(color: colors.textMuted)),
            const SizedBox(height: 8),
            Row(
              children: [
                icon,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value,
                    style: AppType.chrome(
                      size: 28,
                      weight: FontWeight.w800,
                      color: colors.textPrimary,
                      tabular: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
