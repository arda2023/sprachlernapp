import '../web/web_reading_viewport.dart';

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/learning_milestone.dart';
import '../../domain/streak.dart';
import '../../domain/review_request.dart';
import '../../models/home_models.dart';
import '../../presentation/celebration_sounds.dart';
import '../../presentation/notifications/learning_reminder_invitation.dart';
import '../../presentation/providers/streak_providers.dart';
import '../../presentation/providers/auth_providers.dart';
import '../../presentation/providers/review_request_provider.dart';
import '../../presentation/providers/onboarding_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_buttons.dart';
import '../../widgets/learning_milestone_card.dart';
import '../../widgets/success_premium_invitation.dart';
import '../../widgets/svg_glyph.dart';
import 'widgets/completion_panda.dart';
import 'widgets/stacked_word_cards.dart';
import 'widgets/streak_charge_bar.dart';

/// Shown after a deck practice session once the daily goal is reached
/// (docs/redesign/design-system.md › Abschluss). The streak bar appears in
/// the middle, the panda climbs up to watch, and the bar charges to today.
/// On day seven the star flips. The panda and bar glide upwards together,
/// leaving room for the stats, stacked recap cards and "Weiter".
class PracticeCompletionScreen extends ConsumerStatefulWidget {
  const PracticeCompletionScreen({
    super.key,
    required this.streak,
    required this.goal,
    required this.words,
    this.offerReview = false,
    this.achievement,
  });

  final StreakSummary streak;
  final DailyGoal goal;
  final List<CompletionWord> words;
  // Only the real practice route opts in; previews never request reviews.
  final bool offerReview;
  final Future<PracticeMilestoneResult>? achievement;

  static Route<void> route({
    required StreakSummary streak,
    required DailyGoal goal,
    required List<CompletionWord> words,
    Future<PracticeMilestoneResult>? achievement,
  }) => CupertinoPageRoute<void>(
    builder: (_) => WebReadingViewport(
      child: PracticeCompletionScreen(
        streak: streak,
        goal: goal,
        words: words,
        offerReview: true,
        achievement: achievement,
      ),
    ),
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
  late final _pandaIntro = AnimationController(
    vsync: this,
    duration: CompletionPanda.introDuration,
  );

  /// The first quarter is a pause before header and bar glide up.
  late final _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final _glide = CurveTween(
    curve: const Interval(0.28, 1, curve: Curves.easeInOutCubic),
  ).animate(_settle);
  late final _content = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  final _celebrate = ValueNotifier(false);
  final _pandaReady = Completer<bool>();
  Timer? _pandaDeadline;
  TickerFuture? _pandaEntering;
  bool _stillPanda = false;
  Timer? _buzz;
  int _popped = 0;
  bool _barFull = false;
  bool _started = false;
  bool _done = false;
  Future<void>? _starFlip;
  final _reviewSession = Object();
  bool _reviewScheduled = false;
  String? _reviewOwner;

  CelebrationSounds get _sounds => ref.read(celebrationSoundsProvider);

  @override
  void initState() {
    super.initState();
    if (widget.offerReview) {
      _reviewOwner = ref.read(contentAuthProvider).localOwner;
    }
    _charge.addListener(_onCharge);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _stillPanda = !CompletionPanda.hasNativeRuntime;
      if (!MediaQuery.disableAnimationsOf(context)) unawaited(_run());
    }
    if (!_done && MediaQuery.disableAnimationsOf(context)) {
      _skipToEnd();
    }
  }

  void _onPandaIntro() {
    if (_stillPanda || _pandaReady.isCompleted) return;
    _pandaEntering = _pandaIntro.forward();
    _finishPandaLoading(true);
  }

  void _finishPandaLoading(bool ready) {
    _pandaDeadline?.cancel();
    if (!_pandaReady.isCompleted) _pandaReady.complete(ready);
  }

  /// Reduced motion: final state at once, one confirming tap, no sound.
  void _skipToEnd() {
    _done = true;
    _stillPanda = true;
    _finishPandaLoading(false);
    _pandaIntro.stop();
    _buzz?.cancel();
    if (_charge.isAnimating && !_barFull) _sounds.stopCharge();
    _shimmer.stop();
    _celebrate.value = true;
    _charge.removeListener(_onCharge);
    for (final c in [_appear, _charge, _star, _settle, _content]) {
      c.value = 1;
    }
    _glowOff.value = 0;
    _barFull = true;
    _popped = _target;
    HapticFeedback.mediumImpact();
    _scheduleReview();
  }

  Future<void> _run() async {
    if (!_stillPanda) {
      _pandaDeadline = Timer(
        const Duration(seconds: 2),
        () => _finishPandaLoading(false),
      );
    }
    await _appear.forward();
    if (!mounted || _done) return;
    if (!_stillPanda) {
      final ready = await _pandaReady.future;
      if (!mounted || _done) return;
      if (ready) {
        await _pandaEntering;
      } else {
        // Continue the recap even if the native asset fails to start.
        setState(() => _stillPanda = true);
      }
    }
    if (!mounted || _done) return;
    if (_target > 0) {
      _sounds.charge();
      _shimmer.repeat();
      // A steady buzz while the battery charges.
      _buzz = Timer.periodic(
        const Duration(milliseconds: 55),
        (_) => HapticFeedback.lightImpact(),
      );
      await _charge.forward();
    }
    if (!mounted) return;
    if (widget.streak.starToday) await _starMoment();
    if (!mounted) return;
    await _settle.forward();
    if (!mounted) return;
    _celebrate.value = true;
    await _content.forward();
    if (mounted) {
      setState(() => _done = true);
      _scheduleReview();
    }
  }

  void _scheduleReview() {
    if (!widget.offerReview || _reviewScheduled) return;
    _reviewScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(reviewRequestServiceProvider)
            .completeSession(
              session: _reviewSession,
              opportunity: ReviewOpportunity(
                successful:
                    widget.words.isNotEmpty && widget.streak.practicedToday,
                activeLearningDays: widget.streak.activeDays.length,
                goalReached: widget.goal.done >= widget.goal.target,
                streakMilestone: widget.streak.starToday,
              ),
              isCurrent: () =>
                  mounted &&
                  ModalRoute.of(context)?.isCurrent != false &&
                  (WidgetsBinding.instance.lifecycleState == null ||
                      WidgetsBinding.instance.lifecycleState ==
                          AppLifecycleState.resumed) &&
                  ref.read(contentAuthProvider).localOwner == _reviewOwner,
            ),
      );
    });
  }

  /// Checks pop as the pill passes them; the buzz and the charge sound stop
  /// when the pill arrives; the star flips once it is reached.
  void _onCharge() {
    final days = _days.value;
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
    _finishPandaLoading(false);
    _charge.removeListener(_onCharge);
    _celebrate.dispose();
    for (final c in [
      _appear,
      _charge,
      _shimmer,
      _glowOff,
      _star,
      _pandaIntro,
      _settle,
      _content,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Staggered entrance for the parts below the header.
  Animation<double> _part(double from, double to) =>
      CurveTween(curve: Interval(from, to, curve: Curves.easeOutCubic))
          .animate(_content);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final top = (height * 0.08).clamp(12.0, 58.0);
                  final wordTop = (height * 0.08).clamp(16.0, 48.0);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, top, 20, 0),
                        child: AnimatedBuilder(
                          animation: _glide,
                          builder: (context, child) {
                            final remaining = 1 - _glide.value;
                            return Transform.translate(
                              offset: Offset(0, (height / 2 - top) * remaining),
                              child: FractionalTranslation(
                                translation: Offset(0, -0.5 * remaining),
                                child: child,
                              ),
                            );
                          },
                          child: _Header(
                            appear: _appear,
                            celebrate: _celebrate,
                            messageIn: _part(0.12, 0.6),
                            message: widget.streak.starToday
                                ? 'Dein Wochenstern!'
                                : 'Stark gemacht!',
                            pandaMaxHeight: (height * 0.26).clamp(32.0, 136.0),
                            stillPanda:
                                _stillPanda ||
                                MediaQuery.disableAnimationsOf(context),
                            onPandaIntro: _onPandaIntro,
                            onPandaLoadFailed: () => _finishPandaLoading(false),
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
                                      if (_done && widget.achievement != null)
                                        SliverToBoxAdapter(
                                          child: _PracticeFollowUps(
                                            achievement: widget.achievement!,
                                            playSound: !widget.streak.starToday,
                                            owner: _reviewOwner,
                                          ),
                                        ),
                                      SliverToBoxAdapter(
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            20,
                                            wordTop,
                                            20,
                                            0,
                                          ),
                                          child: Column(
                                            children: [
                                              StackedWordCards(
                                                words: widget.words,
                                                stickyTop: wordTop,
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

class _PracticeFollowUps extends ConsumerWidget {
  const _PracticeFollowUps({
    required this.achievement,
    required this.playSound,
    required this.owner,
  });

  final Future<PracticeMilestoneResult> achievement;
  final bool playSound;
  final String? owner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accountSessionProvider);
    if (ref.read(contentAuthProvider).localOwner != owner) {
      return const SizedBox.shrink();
    }
    final onboarded = ref.watch(onboardingProvider).asData?.value == true;
    return FutureBuilder<PracticeMilestoneResult>(
      future: achievement,
      builder: (context, snapshot) {
        final result = snapshot.data;
        if (result == null || !result.successful) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              for (final (i, milestone) in result.milestones.indexed)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 16 : 8),
                  child: LearningMilestoneCard(
                    key: ValueKey(milestone),
                    milestone: milestone,
                    playSound: i == 0 && playSound,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LearningReminderInvitation(
                  fallback: onboarded
                      ? const SuccessPremiumInvitation(
                          opportunityId: 'first_session',
                          interest: 'Stapel',
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
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
    required this.appear,
    required this.celebrate,
    required this.messageIn,
    required this.message,
    required this.pandaMaxHeight,
    required this.stillPanda,
    required this.onPandaIntro,
    required this.onPandaLoadFailed,
    required this.semantics,
    required this.bar,
  });

  final Animation<double> appear;
  final ValueListenable<bool> celebrate;
  final Animation<double> messageIn;
  final String message;
  final double pandaMaxHeight;
  final bool stillPanda;
  final VoidCallback onPandaIntro;
  final VoidCallback onPandaLoadFailed;
  final String semantics;
  final Widget bar;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const ratio = CompletionPanda.aspectRatio;
              final messageScale = MediaQuery.textScalerOf(context).scale(17);
              final pandaShare = messageScale > 25 ? 0.30 : 0.40;
              final pandaWidth = (constraints.maxWidth * pandaShare).clamp(
                0.0,
                pandaMaxHeight * ratio,
              );
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: pandaWidth,
                    height: pandaWidth / ratio,
                    child: ValueListenableBuilder(
                      valueListenable: celebrate,
                      builder: (context, celebrate, _) => CompletionPanda(
                        celebrate: celebrate,
                        still: stillPanda,
                        onIntroStarted: onPandaIntro,
                        onLoadFailed: onPandaLoadFailed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: pandaWidth * 0.48),
                      child: FadeTransition(
                        opacity: messageIn,
                        child: _CompletionMessage(message: message),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        AnimatedBuilder(
          animation: appear,
          builder: (context, child) {
            final t = Curves.easeOutBack.transform(appear.value);
            return Opacity(
              opacity: appear.value,
              child: Transform.scale(
                scale: 0.9 + 0.1 * t,
                alignment: Alignment.topCenter,
                child: child,
              ),
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

class _CompletionMessage extends StatelessWidget {
  const _CompletionMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.appColors.popover;
    return Semantics(
      header: true,
      child: CustomPaint(
        painter: _SpeechTail(color),
        child: Padding(
          padding: const EdgeInsets.only(bottom: _SpeechTail.height),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppType.chrome(
                  size: 17,
                  weight: FontWeight.w700,
                  color: AppColors.onActive,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechTail extends CustomPainter {
  const _SpeechTail(this.color);

  static const height = 8.0;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bottom = size.height - height;
    canvas.drawPath(
      Path()
        ..moveTo(16, bottom - 9)
        ..lineTo(31, bottom - 3)
        ..quadraticBezierTo(24, bottom + 3, 11, bottom + 7)
        ..quadraticBezierTo(9, bottom + 8, 10, bottom + 5)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SpeechTail oldDelegate) => oldDelegate.color != color;
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
              value: '$streak',
              semantics:
                  'Streak: $streak ${streak == 1 ? 'Tag' : 'Tage'} in Folge',
              // The animated Rive flame rendered as a square on device; the
              // plain flame stands in for now.
              icon: Icon(
                CupertinoIcons.flame_fill,
                size: 30,
                color: colors.active,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
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
    required this.value,
    required this.semantics,
    required this.icon,
  });

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: AppType.chrome(
                    size: 28,
                    weight: FontWeight.w800,
                    color: colors.textPrimary,
                    tabular: true,
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
