import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../models/home_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/popover_trigger.dart';
import '../../../widgets/svg_glyph.dart';
import 'language_panel.dart';

/// Language, daily goal (target + "2/10"), streak flame and settings.
/// Language, goal and flame open popovers pointing at them and turn orange
/// while open. The profile button is gone until a profile exists.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.flag,
    required this.languageName,
    required this.goal,
    required this.streak,
    required this.goalPopover,
    required this.streakPopover,
    required this.onSettings,
  });

  final String flag;
  final String languageName;

  /// Null while loading.
  final DailyGoal? goal;
  final int? streak;
  final WidgetBuilder goalPopover;
  final WidgetBuilder streakPopover;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final items = <Widget>[
          // Takes the free space, truncates only when there is none.
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: PopoverTrigger<void>(
                popover: (_) => LanguagePanel(current: languageName),
                builder: (context, open, show) => _LanguageChip(
                  flag: flag,
                  name: languageName,
                  open: open,
                  onTap: show,
                ),
              ),
            ),
          ),
          if (goal case final g?)
            PopoverTrigger<void>(
              popover: goalPopover,
              builder: (context, open, show) =>
                  GoalBadge(goal: g, open: open, onTap: show),
            ),
          if (streak case final days?)
            PopoverTrigger<void>(
              popover: streakPopover,
              builder: (context, open, show) =>
                  _StreakButton(days: days, open: open, onTap: show),
            ),
          MergeSemantics(
            child: CupertinoButton(
              onPressed: onSettings,
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              child: Semantics(
                label: 'Einstellungen',
                excludeSemantics: true,
                child: Icon(
                  CupertinoIcons.gear_alt,
                  size: 24,
                  color: context.appColors.textMuted,
                ),
              ),
            ),
          ),
        ];
        // One row on every phone; the language chip truncates first. Only
        // very narrow widths or large Dynamic Type move goal and streak to
        // a second line.
        if (constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.5) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [items.first, items.last]),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: items.sublist(1, items.length - 1),
              ),
            ],
          );
        }
        return Row(children: items);
      },
    );
  }
}

/// Target icon with "done/target". Turns the "Wörter geübt" green with a
/// short pop the first time the goal is reached while Home is on screen.
class GoalBadge extends StatefulWidget {
  const GoalBadge({
    super.key,
    required this.goal,
    required this.onTap,
    this.open = false,
  });

  final DailyGoal goal;
  final VoidCallback onTap;

  /// Its popover is showing: orange pill, white content.
  final bool open;

  @override
  State<GoalBadge> createState() => _GoalBadgeState();
}

class _GoalBadgeState extends State<GoalBadge>
    with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  ValueListenable<TickerModeData>? _tickerMode;
  bool _pending = false;

  bool get _reached => widget.goal.done >= widget.goal.target;

  @override
  void initState() {
    super.initState();
    // Already reached on first build: shown green, no animation.
    if (_reached) _pop.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = TickerMode.getValuesNotifier(context);
    if (notifier != _tickerMode) {
      _tickerMode?.removeListener(_maybePlay);
      _tickerMode = notifier..addListener(_maybePlay);
    }
  }

  @override
  void didUpdateWidget(GoalBadge old) {
    super.didUpdateWidget(old);
    final was = old.goal.done >= old.goal.target;
    if (!was && _reached) {
      _pending = true;
      _maybePlay();
    } else if (was && !_reached) {
      _pending = false;
      _pop.value = 0; // goal raised above today's count
    }
  }

  /// Waits until Home is actually visible (not under a practice session).
  void _maybePlay() {
    if (!_pending || !(_tickerMode?.value.enabled ?? false)) return;
    _pending = false;
    if (MediaQuery.disableAnimationsOf(context)) {
      _pop.value = 1;
      return;
    }
    HapticFeedback.lightImpact();
    _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _tickerMode?.removeListener(_maybePlay);
    _pop.dispose();
    super.dispose();
  }

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 35),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.45,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final g = widget.goal;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: widget.onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label:
              'Tagesziel: ${g.done} von ${g.target} Wörtern geübt. '
              'Details öffnen',
          excludeSemantics: true,
          child: _Pill(
            open: widget.open,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pop,
                  builder: (context, _) => Transform.scale(
                    scale: _pop.isAnimating ? _scale.transform(_pop.value) : 1,
                    child: GlyphIcon(
                      AppGlyphs.target,
                      size: 22,
                      color: widget.open
                          ? const Color(0xFFFFFFFF)
                          : Color.lerp(
                              colors.iconOff,
                              colors.progressWords,
                              Curves.easeOut.transform(
                                _pop.value.clamp(0.0, 1.0),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${g.done}/${g.target}',
                  style: AppType.chrome(
                    size: 17,
                    weight: FontWeight.w800,
                    color: widget.open
                        ? const Color(0xFFFFFFFF)
                        : colors.textPrimary,
                    tabular: true,
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

class _StreakButton extends StatelessWidget {
  const _StreakButton({
    required this.days,
    required this.onTap,
    this.open = false,
  });

  final int days;
  final VoidCallback onTap;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final lit = days > 0;
    const white = Color(0xFFFFFFFF);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label:
              'Streak: ${days == 1 ? '1 Tag' : '$days Tage'}. Kalender öffnen',
          excludeSemantics: true,
          child: _Pill(
            open: open,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.flame_fill,
                  size: 22,
                  color: open
                      ? white
                      : lit
                      ? colors.active
                      : colors.iconOff,
                ),
                const SizedBox(width: 4),
                Text(
                  '$days',
                  style: AppType.chrome(
                    size: 17,
                    weight: FontWeight.w800,
                    color: open
                        ? white
                        : lit
                        ? colors.textPrimary
                        : colors.textMuted,
                    tabular: true,
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

/// Header item background: clear at rest, popover orange while open.
class _Pill extends StatelessWidget {
  const _Pill({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: open ? context.appColors.popover : null,
      borderRadius: BorderRadius.circular(99),
    ),
    child: child,
  );
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.flag,
    required this.name,
    required this.onTap,
    this.open = false,
  });

  final String flag;
  final String name;
  final VoidCallback onTap;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const white = Color(0xFFFFFFFF);
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: 'Zielsprache: $name. Sprache wählen',
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: open ? colors.popover : colors.raisedInk,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '$flag  $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.chrome(
                      size: 13,
                      weight: FontWeight.w600,
                      color: open ? white : colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 12,
                  color: open ? white : colors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
