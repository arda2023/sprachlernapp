import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Icons, Scaffold, ScaffoldMessenger, SnackBar;

import '../../models/story_category.dart';
import '../../theme/app_theme.dart';
import '../../widgets/action_buttons.dart';
import '../decks/widgets/practice_chrome.dart' show SessionTrack;
import 'widgets/onboarding_art.dart';

/// What the onboarding hands back: the topic picked on page 2 (also the
/// sample sentence on page 4) and the daily goal from page 3.
typedef OnboardingResult = ({String interest, int dailyGoal});

/// First start (docs/redesign/design-system.md › Onboarding): five pages,
/// value before the account. Welcome → topic → daily goal → try tapping a
/// word → account. Sign-in is a placeholder: every option finishes the
/// onboarding and the app keeps learning locally (PRODUCT.md › Accounts).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final ValueChanged<OnboardingResult> onDone;

  static const pageCount = 5;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;
  _Interest? _interest;
  int _goal = 10;
  int? _tapped;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int page) {
    setState(() => _page = page);
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _pages.jumpToPage(page);
    } else {
      _pages.animateToPage(
        page,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _finish({String? notice}) {
    if (notice != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(notice)));
    }
    widget.onDone((
      interest: (_interest ?? _Interest.everyday).category.name,
      dailyGoal: _goal,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final interest = _interest ?? _Interest.everyday;
    final (label, onPressed) = switch (_page) {
      0 => ('Los geht’s', () => _go(1)),
      1 => ('Weiter', _interest == null ? null : () => _go(2)),
      2 => ('Weiter', () => _go(3)),
      3 => ('Weiter', () => _go(4)),
      _ => (null, null),
    };
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              page: _page,
              onBack: _page == 0 ? null : () => _go(_page - 1),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const _WelcomePage(),
                  _InterestPage(
                    selected: _interest,
                    onSelect: (i) => setState(() {
                      _interest = i;
                      _tapped = null;
                    }),
                  ),
                  _GoalPage(
                    goal: _goal,
                    onSelect: (g) => setState(() => _goal = g),
                  ),
                  _TryPage(
                    interest: interest,
                    tapped: _tapped,
                    onTap: (i) => setState(() => _tapped = i),
                  ),
                  _AccountPage(
                    onAccount: (provider) => _finish(
                      notice:
                          'Anmeldung mit $provider kommt bald. Bis dahin lernst '
                          'du auf diesem Gerät.',
                    ),
                    onSkip: () => _finish(),
                  ),
                ],
              ),
            ),
            if (label != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dimmed until the page has what it needs.
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: onPressed == null ? 0.4 : 1,
                      child: PrimaryActionButton(
                        label: label,
                        onPressed: onPressed,
                      ),
                    ),
                    if (_page == 0)
                      CupertinoButton(
                        onPressed: () => _go(OnboardingScreen.pageCount - 1),
                        minimumSize: const Size(44, 44),
                        child: Text(
                          'Ich habe schon ein Konto',
                          style: AppType.chrome(
                            size: 15,
                            weight: FontWeight.w600,
                            color: context.appColors.textPrimary,
                          ),
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

/// Back and the orange step segments, as in the practice session.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.page, required this.onBack});

  final int page;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: onBack == null
                ? null
                : CupertinoButton(
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    child: Semantics(
                      label: 'Zurück',
                      excludeSemantics: true,
                      child: Icon(
                        CupertinoIcons.chevron_back,
                        size: 24,
                        color: context.appColors.textPrimary,
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
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return _Page(
      center: true,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const OnboardingArt(OnboardingArtboard.logo, height: 44),
            const SizedBox(width: 6),
            Text(
              'Lingvist',
              style: AppType.editorial(
                color: context.appColors.textPrimary,
                size: 26,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Center(
          child: OnboardingArt(OnboardingArtboard.welcome, height: 260),
        ),
        const SizedBox(height: 28),
        const _Title('Lerne Englisch mit Geschichten', center: true),
        const SizedBox(height: 10),
        Text(
          'Tippe ein Wort an, verstehe den Satz und übe ihn später wieder.',
          textAlign: TextAlign.center,
          style: AppType.chrome(size: 16, color: context.appColors.textMuted),
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
}

class _InterestPage extends StatelessWidget {
  const _InterestPage({required this.selected, required this.onSelect});

  final _Interest? selected;
  final ValueChanged<_Interest> onSelect;

  @override
  Widget build(BuildContext context) {
    const all = _Interest.values;
    return _Page(
      children: [
        const SizedBox(height: 24),
        const _Title('Wofür lernst du Englisch?'),
        const SizedBox(height: 24),
        for (var i = 0; i < all.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (j, interest) in all.skip(i).take(2).indexed) ...[
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
      ],
    );
  }
}

/// A topic in its story colour; picked = orange ring and check.
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
    final color = interest.category.color;
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.8,
        minimumSize: const Size(44, 44),
        child: Semantics(
          label: interest.label,
          selected: selected,
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            // Fill the grid column; the button would otherwise shrink-wrap.
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
              // A border carries the selected state (DESIGN.md: borders only
              // where they mean something).
              border: Border.all(
                color: selected
                    ? context.appColors.active
                    : const Color(0x00000000),
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
                if (selected)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.appColors.active,
                      ),
                      child: const Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 16,
                        color: white,
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
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- 3 Daily goal

class _GoalPage extends StatelessWidget {
  const _GoalPage({required this.goal, required this.onSelect});

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
        const Center(
          child: OnboardingArt(OnboardingArtboard.goal, height: 150),
        ),
        const SizedBox(height: 16),
        const _Title('Wie viel möchtest du täglich üben?'),
        const SizedBox(height: 20),
        for (final (words, name) in _options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _GoalOption(
              name: name,
              words: words,
              selected: words == goal,
              onTap: () => onSelect(words),
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
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.8,
        minimumSize: const Size(44, 56),
        child: Semantics(
          label: '$name, $words Wörter pro Tag',
          selected: selected,
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? colors.popover : colors.raisedInk,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: AppType.chrome(
                      size: 17,
                      weight: FontWeight.w600,
                      color: selected ? white : colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$words Wörter / Tag',
                  style: AppType.chrome(
                    size: 15,
                    color: selected ? white : colors.textMuted,
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

// ----------------------------------------------------------------- 4 Try it

/// The core moment before any account: tap a word in a sentence from the
/// chosen topic and see its German meaning in the orange bubble.
class _TryPage extends StatelessWidget {
  const _TryPage({
    required this.interest,
    required this.tapped,
    required this.onTap,
  });

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
        const _Title('Tippe auf ein Wort'),
        const SizedBox(height: 24),
        Container(
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
                      hinted: tapped == null && i == first,
                      selected: tapped == i,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
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
                  word: interest.words[tapped!].replaceAll(
                    RegExp(r'[^\w’]'),
                    '',
                  ),
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
      // A few soft pulses, then it rests highlighted-free.
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
    final text = AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) => Container(
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
    );
    // Every word gets the 44 pt row of the tappable ones, so all baselines
    // line up.
    if (!widget.glossed) {
      return SizedBox(
        height: 44,
        child: Center(widthFactor: 1, child: text),
      );
    }
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: widget.onTap,
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        pressedOpacity: 0.7,
        child: Semantics(
          label: '${widget.word}, Übersetzung anzeigen',
          selected: widget.selected,
          excludeSemantics: true,
          child: text,
        ),
      ),
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

// ---------------------------------------------------------------- 5 Account

class _AccountPage extends StatelessWidget {
  const _AccountPage({required this.onAccount, required this.onSkip});

  final ValueChanged<String> onAccount;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _Page(
      center: true,
      children: [
        const Center(
          child: OnboardingArt(OnboardingArtboard.logo, height: 120),
        ),
        const SizedBox(height: 20),
        const _Title('Speichere deinen Fortschritt', center: true),
        const SizedBox(height: 28),
        _SignInButton(
          label: 'Mit Apple fortfahren',
          icon: const Icon(Icons.apple, size: 22, color: Color(0xFF000000)),
          fill: const Color(0xFFFFFFFF),
          foreground: const Color(0xFF000000),
          onPressed: () => onAccount('Apple'),
        ),
        const SizedBox(height: 10),
        _SignInButton(
          label: 'Mit Google fortfahren',
          icon: Text(
            'G',
            style: AppType.chrome(
              size: 19,
              weight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          fill: colors.raisedInk,
          foreground: colors.textPrimary,
          onPressed: () => onAccount('Google'),
        ),
        const SizedBox(height: 10),
        _SignInButton(
          label: 'Mit E-Mail fortfahren',
          icon: Icon(CupertinoIcons.mail, size: 20, color: colors.textPrimary),
          fill: colors.raisedInk,
          foreground: colors.textPrimary,
          onPressed: () => onAccount('E-Mail'),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: onSkip,
          minimumSize: const Size(44, 44),
          child: Text(
            'Ohne Konto weiter',
            style: AppType.chrome(
              size: 15,
              weight: FontWeight.w600,
              color: colors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.label,
    required this.icon,
    required this.fill,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Widget icon;
  final Color fill, foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.8,
        minimumSize: const Size(44, 54),
        child: Semantics(
          label: label,
          excludeSemantics: true,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 24, child: Center(child: icon)),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppType.chrome(
                      size: 17,
                      weight: FontWeight.w600,
                      color: foreground,
                    ),
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
