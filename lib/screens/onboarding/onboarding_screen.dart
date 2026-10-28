import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Scaffold, ScaffoldMessenger, SnackBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/story_category.dart';
import '../../presentation/onboarding_sounds.dart';
import '../../theme/app_theme.dart';
import '../decks/widgets/practice_chrome.dart' show SessionTrack;
import 'paywall_screen.dart';
import 'widgets/account_sheet.dart';
import 'widgets/onboarding_art.dart';
import 'widgets/onboarding_motion.dart';

/// What the onboarding hands back: the topic picked on page 2 (also the
/// sample sentence on page 4) and the daily goal from page 3.
typedef OnboardingResult = ({String interest, int dailyGoal});

/// First start (docs/redesign/design-system.md › Onboarding): five pages,
/// value before any account or price. Welcome → topic → daily goal → tap a
/// word → "Dein Start steht"; then the plan pill flies into the closable
/// paywall while the onboarding recedes behind it.
///
/// Pages swipe with a parallax lag; swiping forward is blocked until the
/// page has what it needs. Texts cascade in the first time a page shows.
/// Every tap and swipe has a haptic (see [Haptic]).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final ValueChanged<OnboardingResult> onDone;

  static const pageCount = 5;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _pages = PageController();

  /// The onboarding steps back (scale, dim) while the paywall rises.
  late final _handoff = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: const Duration(milliseconds: 360),
  );

  int _page = 0;
  final _visited = <int>{0};
  bool _programmatic = false;
  _Interest? _interest;
  int _goal = 10;
  int? _tapped;
  bool _planReady = false;

  _Interest get _topic => _interest ?? _Interest.everyday;

  OnboardingSounds get _sounds => ref.read(onboardingSoundsProvider);

  OnboardingResult get _result =>
      (interest: _topic.category.name, dailyGoal: _goal);

  /// The furthest page a swipe may reach right now.
  int get _maxPage => _page == 1 && _interest == null
      ? 1
      : math.min(_page + 1, OnboardingScreen.pageCount - 1);

  @override
  void dispose() {
    _pages.dispose();
    _handoff.dispose();
    super.dispose();
  }

  Future<void> _go(int page) async {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
      return;
    }
    _programmatic = true;
    await _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
    _programmatic = false;
  }

  void _onPageChanged(int page) {
    // Buttons already gave their haptic; a finger swipe gets its own.
    if (!_programmatic) Haptic.select();
    setState(() {
      _page = page;
      _visited.add(page);
    });
  }

  Future<void> _openPaywall() async {
    final result = _result;
    var finished = false;
    _sounds.paywall();
    if (!MediaQuery.disableAnimationsOf(context)) unawaited(_handoff.forward());
    await Navigator.of(context).push(
      PaywallScreen.route(
        plan: (interest: _topic.label, dailyGoal: _goal),
        onContinue: () {
          finished = true;
          widget.onDone(result);
        },
      ),
    );
    // Back without a decision: the onboarding comes forward again.
    if (mounted && !finished) unawaited(_handoff.reverse());
  }

  /// "Ich habe schon ein Konto": the sign-in is a placeholder, so the app
  /// says so and starts without an account.
  Future<void> _signIn() async {
    final provider = await AccountSheet.show(context, AccountReason.signIn);
    if (provider == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Anmeldung mit ${provider.label} kommt bald. '
          'Du startest erst einmal ohne Konto.',
        ),
      ),
    );
    widget.onDone(_result);
  }

  @override
  Widget build(BuildContext context) {
    final (label, onPressed) = switch (_page) {
      0 => ('Los geht’s', () => _go(1)),
      1 => ('Weiter', _interest == null ? null : () => _go(2)),
      2 => ('Weiter', () => _go(3)),
      3 => ('Weiter', () => _go(4)),
      _ => ('Weiter', _planReady ? _openPaywall : null),
    };
    final pages = [
      _WelcomePage(active: _visited.contains(0)),
      _InterestPage(
        active: _visited.contains(1),
        selected: _interest,
        onSelect: (i) {
          _sounds.select();
          setState(() {
            _interest = i;
            _tapped = null;
          });
        },
      ),
      _GoalPage(
        active: _visited.contains(2),
        goal: _goal,
        onSelect: (g) {
          _sounds.select();
          setState(() => _goal = g);
        },
      ),
      _TryPage(
        active: _visited.contains(3),
        interest: _topic,
        tapped: _tapped,
        onTap: (i) => setState(() => _tapped = i),
      ),
      _PlanPage(
        active: _visited.contains(4),
        interest: _topic,
        goal: _goal,
        tapped: _tapped,
        onTick: _sounds.tick,
        onReady: () => setState(() => _planReady = true),
      ),
    ];
    return Scaffold(
      body: AnimatedBuilder(
        animation: _handoff,
        builder: (context, child) {
          final t = Curves.easeInOutCubic.transform(_handoff.value);
          return Transform.scale(
            scale: 1 - 0.06 * t,
            child: Opacity(opacity: 1 - 0.6 * t, child: child),
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                page: _page,
                onBack: _page == 0 ? null : () => _go(_page - 1),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  physics: _GatedPagePhysics(maxPage: () => _maxPage),
                  onPageChanged: _onPageChanged,
                  itemCount: pages.length,
                  itemBuilder: (context, i) =>
                      _Parallax(controller: _pages, index: i, child: pages[i]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlowButton(label: label, onPressed: onPressed),
                      if (_page == 0)
                        TextAction(
                          label: 'Ich habe schon ein Konto',
                          onTap: _signIn,
                          strong: true,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page physics that refuse to scroll past [maxPage], so a swipe cannot
/// skip a page that still needs an answer. Swiping back always works.
///
/// [maxPage] is read on every scroll: Scrollable keeps the first physics
/// instance as long as the runtime type stays the same, so a plain int
/// would freeze at its initial value.
class _GatedPagePhysics extends PageScrollPhysics {
  const _GatedPagePhysics({required this.maxPage, super.parent});

  final int Function() maxPage;

  @override
  _GatedPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _GatedPagePhysics(maxPage: maxPage, parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    final limit = maxPage() * position.viewportDimension;
    if (value > position.pixels && position.pixels >= limit) {
      return value - position.pixels;
    }
    if (position.pixels < limit && value > limit) return value - limit;
    return super.applyBoundaryConditions(position, value);
  }
}

/// While a page slides, its content lags behind the page edge and fades,
/// so pages feel layered rather than glued side by side.
class _Parallax extends StatelessWidget {
  const _Parallax({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        var delta = 0.0;
        if (controller.hasClients && controller.position.haveDimensions) {
          delta = (controller.page ?? 0) - index;
        }
        final width = MediaQuery.sizeOf(context).width;
        return Opacity(
          opacity: (1 - delta.abs() * 0.8).clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(delta * width * 0.35, 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Back and the orange step segments, as in the practice session.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.page, required this.onBack});

  final int page;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: onBack == null ? 0 : 1,
              child: Pressable(
                label: 'Zurück',
                haptic: Haptic.light,
                onTap: onBack,
                child: Icon(
                  CupertinoIcons.chevron_back,
                  size: 24,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: 'Schritt ${page + 1} von ${OnboardingScreen.pageCount}',
              excludeSemantics: true,
              child: SessionTrack(
                done: page + 1,
                total: OnboardingScreen.pageCount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrolls when the content outgrows the page (large Dynamic Type).
class _Page extends StatelessWidget {
  const _Page({required this.children, this.center = false});

  final List<Widget> children;
  final bool center;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Column(
          mainAxisAlignment: center
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text, {this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: AppType.editorial(
        color: context.appColors.textPrimary,
        size: 30,
        height: 1.15,
      ),
    ),
  );
}

// ---------------------------------------------------------------- 1 Welcome

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return _Page(
      center: true,
      children: [
        // The wordmark is a logo, not reading text: capped like chrome.
        Reveal(
          active: active,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const OnboardingArt(OnboardingArtboard.logo, height: 44),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Lingvist',
                    style: AppType.editorial(
                      color: context.appColors.textPrimary,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Reveal(
          active: active,
          order: 1,
          child: const Center(
            child: OnboardingArt(OnboardingArtboard.welcome, height: 250),
          ),
        ),
        const SizedBox(height: 28),
        Reveal(
          active: active,
          order: 2,
          child: const _Title('Lerne Englisch mit Geschichten', center: true),
        ),
        const SizedBox(height: 10),
        Reveal(
          active: active,
          order: 3,
          child: Text(
            'Tippe ein Wort an, verstehe den Satz und übe ihn später wieder.',
            textAlign: TextAlign.center,
            style: AppType.chrome(size: 16, color: context.appColors.textMuted),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- 2 Interest

/// The topics offered on page 2, each with a sample sentence for page 4.
/// Onboarding-only demo text; no content pack or learning state.
enum _Interest {
  travel(
    StoryCategory.travel,
    [
      'Our',
      'train',
      'leaves',
      'at',
      'nine,',
      'so',
      'we',
      'have',
      'time',
      'for',
      'breakfast.',
    ],
    {1: 'der Zug', 2: 'fährt ab', 8: 'die Zeit', 10: 'das Frühstück'},
  ),
  work(
    StoryCategory.work,
    [
      'Could',
      'you',
      'send',
      'me',
      'the',
      'report',
      'before',
      'the',
      'meeting?',
    ],
    {2: 'schicken', 5: 'der Bericht', 6: 'vor', 8: 'die Besprechung'},
  ),
  everyday(
    StoryCategory.everyday,
    ['I', 'buy', 'fresh', 'bread', 'at', 'the', 'market', 'every', 'Saturday.'],
    {1: 'kaufen', 2: 'frisch', 3: 'das Brot', 6: 'der Markt'},
  ),
  culture(
    StoryCategory.culture,
    ['The', 'old', 'theatre', 'shows', 'a', 'new', 'play', 'every', 'month.'],
    {1: 'alt', 2: 'das Theater', 6: 'das Theaterstück', 8: 'der Monat'},
  );

  const _Interest(this.category, this.words, this.glossary);

  final StoryCategory category;
  final List<String> words;

  /// Word index → German.
  final Map<int, String> glossary;

  String get label => switch (this) {
    work => 'Beruf',
    _ => category.name,
  };

  /// A tapped word without punctuation, e.g. "breakfast".
  String word(int i) => words[i].replaceAll(RegExp(r'[^\w’]'), '');
}

class _InterestPage extends StatelessWidget {
  const _InterestPage({
    required this.active,
    required this.selected,
    required this.onSelect,
  });

  final bool active;
  final _Interest? selected;
  final ValueChanged<_Interest> onSelect;

  @override
  Widget build(BuildContext context) {
    const all = _Interest.values;
    return _Page(
      children: [
        const SizedBox(height: 24),
        Reveal(
          active: active,
          child: const _Title('Wofür lernst du Englisch?'),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < all.length; i += 2)
          Reveal(
            active: active,
            order: 1 + i ~/ 2,
            child: Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (j, interest)
                        in all.skip(i).take(2).indexed) ...[
                      if (j > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _InterestTile(
                          interest: interest,
                          selected: interest == selected,
                          onTap: () => onSelect(interest),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A topic in its story colour; picked = orange ring and a check that pops.
class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.interest,
    required this.selected,
    required this.onTap,
  });

  final _Interest interest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    final colors = context.appColors;
    final color = interest.category.color;
    return Pressable(
      label: interest.label,
      selected: selected,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, white, 0.12)!,
              Color.lerp(color, const Color(0xFF000000), 0.3)!,
            ],
          ),
          // The border carries the selected state (DESIGN.md).
          border: Border.all(
            color: selected ? colors.active : const Color(0x00000000),
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              top: -12,
              child: Icon(
                interest.category.icon,
                size: 74,
                color: white.withValues(alpha: 0.18),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: selected ? Curves.easeOutBack : Curves.easeIn,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.active,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 16,
                    color: white,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const SizedBox(height: 56),
                Text(
                  interest.label,
                  style: AppType.editorial(color: white, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- 3 Daily goal

class _GoalPage extends StatelessWidget {
  const _GoalPage({
    required this.active,
    required this.goal,
    required this.onSelect,
  });

  final bool active;
  final int goal;
  final ValueChanged<int> onSelect;

  static const _options = [
    (5, 'Locker'),
    (10, 'Normal'),
    (15, 'Ernsthaft'),
    (20, 'Intensiv'),
  ];

  @override
  Widget build(BuildContext context) {
    return _Page(
      children: [
        const SizedBox(height: 8),
        Reveal(
          active: active,
          child: const Center(
            child: OnboardingArt(OnboardingArtboard.goal, height: 150),
          ),
        ),
        const SizedBox(height: 16),
        Reveal(
          active: active,
          order: 1,
          child: const _Title('Wie viel möchtest du täglich üben?'),
        ),
        const SizedBox(height: 20),
        for (final (i, (words, name)) in _options.indexed)
          Reveal(
            active: active,
            order: 2 + i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GoalOption(
                name: name,
                words: words,
                selected: words == goal,
                onTap: () => onSelect(words),
              ),
            ),
          ),
      ],
    );
  }
}

/// Selected = popover orange with white content, like the app's other
/// chosen states.
class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.name,
    required this.words,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final int words;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    final colors = context.appColors;
    return Pressable(
      label: '$name, $words Wörter pro Tag',
      selected: selected,
      onTap: onTap,
      minSize: const Size(44, 56),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colors.popover : colors.raisedInk,
          borderRadius: BorderRadius.circular(18),
        ),
        // Name left, amount right; at large text sizes the amount wraps
        // under the name instead of overflowing.
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 2,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppType.chrome(
                size: 17,
                weight: FontWeight.w600,
                color: selected ? white : colors.textPrimary,
              ),
              child: Text(name),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppType.chrome(
                size: 15,
                color: selected ? white : colors.textMuted,
              ),
              child: Text('$words Wörter / Tag'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- 4 Try it

/// The core moment before any price: tap a word in a sentence from the
/// chosen topic and see its German meaning in the orange bubble.
class _TryPage extends StatelessWidget {
  const _TryPage({
    required this.active,
    required this.interest,
    required this.tapped,
    required this.onTap,
  });

  final bool active;
  final _Interest interest;
  final int? tapped;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final first = interest.glossary.keys.first;
    return _Page(
      children: [
        const SizedBox(height: 24),
        Reveal(active: active, child: const _Title('Tippe auf ein Wort')),
        const SizedBox(height: 24),
        Reveal(
          active: active,
          order: 1,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            decoration: BoxDecoration(
              color: colors.raisedInk,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      interest.category.icon,
                      size: 16,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      interest.label,
                      style: AppType.meta(color: colors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 4,
                  children: [
                    for (final (i, word) in interest.words.indexed)
                      _Word(
                        word: word,
                        glossed: interest.glossary.containsKey(i),
                        hinted: active && tapped == null && i == first,
                        selected: tapped == i,
                        onTap: () => onTap(i),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutBack,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(animation),
              alignment: Alignment.topLeft,
              child: child,
            ),
          ),
          child: tapped == null
              ? const SizedBox(key: ValueKey('none'), height: 84)
              : _MeaningBubble(
                  key: ValueKey(tapped),
                  word: interest.word(tapped!),
                  meaning: interest.glossary[tapped]!,
                ),
        ),
      ],
    );
  }
}

class _Word extends StatefulWidget {
  const _Word({
    required this.word,
    required this.glossed,
    required this.hinted,
    required this.selected,
    required this.onTap,
  });

  final String word;
  final bool glossed, hinted, selected;
  final VoidCallback onTap;

  @override
  State<_Word> createState() => _WordState();
}

/// A word in the sample sentence. Glossed words are underlined like in the
/// reader; the first one pulses a few times until anything is tapped.
class _WordState extends State<_Word> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Word oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.hinted && !_pulse.isAnimating && _pulse.value == 0) {
      // A few soft pulses, then it rests without highlight.
      _pulse.repeat(reverse: true, count: 4).whenComplete(() {
        if (mounted && _pulse.value > 0) _pulse.animateBack(0);
      });
    } else if (!widget.hinted && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final style = AppType.editorial(
      color: widget.selected ? const Color(0xFFFFFFFF) : colors.textPrimary,
      size: 24,
      weight: FontWeight.w500,
    );
    // Every word gets the 44 pt row of the tappable ones, so all baselines
    // line up.
    final text = SizedBox(
      height: 44,
      child: Center(
        widthFactor: 1,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) => AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: widget.selected
                  ? colors.popover
                  : colors.active.withValues(alpha: 0.22 * _pulse.value),
              borderRadius: BorderRadius.circular(6),
            ),
            child: child,
          ),
          child: Text(
            widget.word,
            style: widget.glossed && !widget.selected
                ? style.copyWith(
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationColor: colors.textMuted,
                  )
                : style,
          ),
        ),
      ),
    );
    if (!widget.glossed) return text;
    return Pressable(
      label: '${widget.word}, Übersetzung anzeigen',
      selected: widget.selected,
      haptic: Haptic.light,
      onTap: widget.onTap,
      minSize: const Size(32, 44),
      child: text,
    );
  }
}

/// The orange word bubble from the reader, as a still card.
class _MeaningBubble extends StatelessWidget {
  const _MeaningBubble({super.key, required this.word, required this.meaning});

  final String word;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    return Semantics(
      liveRegion: true,
      label: '$word: $meaning',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        decoration: BoxDecoration(
          color: context.appColors.popover,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word, style: AppType.editorial(color: white, size: 22)),
            const SizedBox(height: 2),
            Text(
              meaning,
              style: AppType.chrome(
                size: 17,
                weight: FontWeight.w600,
                color: white.withValues(alpha: 0.92),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- 5 Your start

/// "Dein Start steht": the answers come back as a checklist that ticks off
/// one row after another (each with a tap), then "Weiter" lights up. The
/// pill on top flies into the paywall.
class _PlanPage extends StatefulWidget {
  const _PlanPage({
    required this.active,
    required this.interest,
    required this.goal,
    required this.tapped,
    required this.onTick,
    required this.onReady,
  });

  final bool active;
  final _Interest interest;
  final int goal;
  final int? tapped;

  /// Each row ticking off (sound; the haptic is played here).
  final VoidCallback onTick;
  final VoidCallback onReady;

  @override
  State<_PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<_PlanPage>
    with SingleTickerProviderStateMixin {
  static const _rows = 3;

  /// The first 30 % lets the card settle; then one row every ~280 ms.
  late final _ticks = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..addListener(_onTick);

  int _done = 0;

  static double _at(int row) => 0.3 + row * 0.22;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _start();
  }

  @override
  void didUpdateWidget(_PlanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _start();
  }

  void _start() {
    if (!widget.active || !_ticks.isDismissed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _ticks.value = 1;
    } else {
      _ticks.forward();
    }
  }

  void _onTick() {
    var changed = false;
    while (_done < _rows && _ticks.value >= _at(_done)) {
      _done++;
      changed = true;
      if (!MediaQuery.disableAnimationsOf(context)) {
        Haptic.select();
        widget.onTick();
      }
    }
    if (changed) {
      setState(() {});
      if (_done == _rows) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onReady();
        });
      }
    }
  }

  @override
  void dispose() {
    _ticks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final i = widget.interest;
    final tapped = widget.tapped;
    final rows = [
      (i.category.icon, 'Geschichten zu ${i.label}'),
      (CupertinoIcons.flame, '${widget.goal} Wörter am Tag'),
      (
        CupertinoIcons.text_cursor,
        tapped == null
            ? 'Wörter per Tippen verstehen'
            : 'Erstes Wort: ${i.word(tapped)} · ${i.glossary[tapped]}',
      ),
    ];
    return _Page(
      children: [
        const SizedBox(height: 24),
        Reveal(active: widget.active, child: const _Title('Dein Start steht')),
        const SizedBox(height: 24),
        Reveal(
          active: widget.active,
          order: 1,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            decoration: BoxDecoration(
              color: colors.raisedInk,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: paywallHeroTag,
                  child: PlanSummaryPill(
                    plan: (interest: i.label, dailyGoal: widget.goal),
                  ),
                ),
                const SizedBox(height: 12),
                for (final (n, (icon, text)) in rows.indexed)
                  _PlanRow(icon: icon, text: text, done: n < _done),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.icon, required this.text, required this.done});

  final IconData icon;
  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: '$text${done ? ', bereit' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? colors.active : colors.hairline,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutBack,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: done
                    ? const Icon(
                        CupertinoIcons.checkmark_alt,
                        key: ValueKey(true),
                        size: 18,
                        color: Color(0xFFFFFFFF),
                      )
                    : Icon(
                        icon,
                        key: const ValueKey(false),
                        size: 16,
                        color: colors.textMuted,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppType.chrome(
                  size: 16,
                  weight: FontWeight.w600,
                  color: done ? colors.textPrimary : colors.textMuted,
                ),
                child: Text(text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
