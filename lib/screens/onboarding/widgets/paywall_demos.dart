import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show listEquals;

import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart' show PopoverBubble;
import '../../../widgets/light_sweep.dart';
import '../../../widgets/speaker_icon.dart';
import '../../content/widgets/generation_progress_bar.dart';

/// Scripted, non-interactive demonstrations of the paywall benefits (user
/// request 21.11.2026). They imitate the real practice, reader and topic
/// surfaces, never write learning progress and never call a service.

/// The examples in the learner's language. The prompts and translations are
/// German, like the app.
class PaywallExamples {
  const PaywallExamples({
    required this.gap,
    required this.reading,
    required this.glosses,
    required this.languageName,
    required this.answer,
    required this.better,
    required this.words,
  });

  /// A practice sentence: text before the gap, the answer, text after it.
  final (String, String, String) gap;

  /// A reading sentence and two of its words with their translation.
  final String reading;
  final List<(String, String)> glosses;

  /// "Übersetze ins …" for the tutor task.
  final String languageName;

  /// The learner's translation of [tutorPrompt] and the tutor's suggestion.
  final String answer, better;

  /// Generated words about [topicPrompt] with their German gloss.
  final List<(String, String)> words;

  static const tutorPrompt =
      'Gestern habe ich zufällig meinen alten Lehrer getroffen.';
  static const topicPrompt = 'Vokabeln über Tiere im Wald';

  static PaywallExamples of(String language) => switch (language) {
    'pt-BR' => const PaywallExamples(
      gap: ('Todas as manhãs ela ', 'toma', ' uma xícara de chá.'),
      reading: 'A velha livraria tem cheiro de papel e chuva.',
      glosses: [('livraria', 'Buchhandlung'), ('chuva', 'Regen')],
      languageName: 'Portugiesische',
      answer: 'Ontem encontrei meu antigo professor por acaso.',
      better: 'Ontem esbarrei com meu antigo professor.',
      words: [
        ('raposa', 'Fuchs'),
        ('coruja', 'Eule'),
        ('ouriço', 'Igel'),
        ('esquilo', 'Eichhörnchen'),
      ],
    ),
    'es' => const PaywallExamples(
      gap: ('Cada mañana ella ', 'toma', ' una taza de té.'),
      reading: 'La vieja librería huele a papel y lluvia.',
      glosses: [('librería', 'Buchhandlung'), ('lluvia', 'Regen')],
      languageName: 'Spanische',
      answer: 'Ayer me encontré con mi antiguo profesor por casualidad.',
      better: 'Ayer me topé con mi antiguo profesor.',
      words: [
        ('zorro', 'Fuchs'),
        ('búho', 'Eule'),
        ('erizo', 'Igel'),
        ('ardilla', 'Eichhörnchen'),
      ],
    ),
    'it' => const PaywallExamples(
      gap: ('Ogni mattina lei ', 'beve', ' una tazza di tè.'),
      reading: 'La vecchia libreria profuma di carta e pioggia.',
      glosses: [('libreria', 'Buchhandlung'), ('pioggia', 'Regen')],
      languageName: 'Italienische',
      answer: 'Ieri ho incontrato per caso il mio vecchio professore.',
      better: 'Ieri ho incrociato il mio vecchio professore.',
      words: [
        ('volpe', 'Fuchs'),
        ('gufo', 'Eule'),
        ('riccio', 'Igel'),
        ('scoiattolo', 'Eichhörnchen'),
      ],
    ),
    'nb' => const PaywallExamples(
      gap: ('Hver morgen ', 'drikker', ' hun en kopp te.'),
      reading: 'Den gamle bokhandelen lukter papir og regn.',
      glosses: [('bokhandelen', 'die Buchhandlung'), ('regn', 'Regen')],
      languageName: 'Norwegische',
      answer: 'I går møtte jeg tilfeldigvis min gamle lærer.',
      better: 'I går støtte jeg på min gamle lærer.',
      words: [
        ('rev', 'Fuchs'),
        ('ugle', 'Eule'),
        ('pinnsvin', 'Igel'),
        ('ekorn', 'Eichhörnchen'),
      ],
    ),
    _ => const PaywallExamples(
      gap: ('Every morning she ', 'drinks', ' a cup of tea.'),
      reading: 'The old bookshop smells of paper and rain.',
      glosses: [('bookshop', 'Buchhandlung'), ('rain', 'Regen')],
      languageName: 'Englische',
      answer: 'Yesterday I met my old teacher by chance.',
      better: 'I ran into my old teacher yesterday.',
      words: [
        ('fox', 'Fuchs'),
        ('owl', 'Eule'),
        ('hedgehog', 'Igel'),
        ('squirrel', 'Eichhörnchen'),
      ],
    ),
  };
}

/// Plays a script while it is on screen: [passes] times, then it rests on
/// [rest]. Scrolling it out of view rewinds it, so it starts over when it
/// comes back. Reduced motion shows [rest] only.
class DemoLoop extends StatefulWidget {
  const DemoLoop({
    super.key,
    required this.length,
    required this.rest,
    required this.builder,
    this.passes = 2,
  });

  /// One pass of the script.
  final Duration length;

  /// The still frame: the result of the demonstration.
  final Duration rest;
  final int passes;

  /// Builds the frame [seconds] into the script.
  final Widget Function(BuildContext context, double seconds) builder;

  @override
  State<DemoLoop> createState() => _DemoLoopState();
}

class _DemoLoopState extends State<DemoLoop>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: widget.length,
  );
  ScrollableState? _scrollable;
  bool _still = false, _visible = false;
  int _played = 0;

  double get _restValue =>
      widget.rest.inMicroseconds / widget.length.inMicroseconds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != _scrollable) {
      _scrollable?.position.removeListener(_check);
      _scrollable = scrollable?..position.addListener(_check);
    }
    if (_still) {
      _controller
        ..stop()
        ..value = _restValue;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _scrollable?.position.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  /// At least 60 % of the demo (or of the viewport) is visible.
  bool _onScreen() {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return false;
    final viewport = _scrollable?.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return true;
    final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final shown =
        math.min(top + box.size.height, viewport.size.height) -
        math.max(top, 0.0);
    return shown >= math.min(box.size.height, viewport.size.height) * 0.6;
  }

  void _check() {
    if (!mounted) return;
    final visible = _onScreen();
    if (visible == _visible) return;
    _visible = visible;
    if (_still) return;
    if (visible) {
      _played = 0;
      _play();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  void _play() {
    if (!mounted || !_visible || _still) return;
    final last = ++_played >= widget.passes;
    _controller.value = 0;
    // A stopped pass never completes, so nothing restarts off screen.
    (last ? _controller.animateTo(_restValue) : _controller.forward()).then((
      _,
    ) {
      if (!last) _play();
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => widget.builder(
      context,
      _controller.value * widget.length.inMicroseconds / 1e6,
    ),
  );
}

/// 0 before [from], 1 after [to], linear in between.
double _span(double s, double from, double to) =>
    ((s - from) / (to - from)).clamp(0.0, 1.0);

/// Letters of [text] typed at [s], starting at [from], [step] seconds each.
int _typed(String text, double s, double from, double step) =>
    ((s - from) / step).floor().clamp(0, text.length);

/// A typing caret that blinks while idle. Zero width, so typing never
/// changes where a line wraps.
class _Caret extends StatelessWidget {
  const _Caret({required this.height, required this.color, required this.on});

  final double height;
  final Color color;
  final bool on;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 0,
    height: height,
    child: OverflowBox(
      maxWidth: 2,
      alignment: Alignment.centerLeft,
      child: Container(width: 2, height: height, color: on ? color : null),
    ),
  );
}

bool _blink(double s) => (s * 2).floor().isEven;

/// [text] up to [shown] letters with a caret after them; the rest is laid
/// out invisibly, so the box keeps its final size while typing. The caret
/// height is unscaled: a WidgetSpan scales its child with the text.
InlineSpan _typedSpan(
  String text,
  int shown,
  TextStyle style, {
  required Color caret,
  required bool caretOn,
  required double caretHeight,
  double opacity = 1,
}) => TextSpan(
  style: style,
  children: [
    TextSpan(
      text: text.substring(0, shown),
      style: style.copyWith(
        color: style.color!.withValues(alpha: style.color!.a * opacity),
      ),
    ),
    WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: _Caret(height: caretHeight, color: caret, on: caretOn),
    ),
    TextSpan(
      text: text.substring(shown),
      style: style.copyWith(color: const Color(0x00000000)),
    ),
  ],
);

/// Benefit 1: a practice sentence whose gap is typed and turns green.
class RecallDemo extends StatelessWidget {
  const RecallDemo({super.key, required this.examples});
  final PaywallExamples examples;

  static const length = Duration(milliseconds: 6000);
  static const rest = Duration(milliseconds: 3000);

  @override
  Widget build(BuildContext context) {
    final (before, answer, after) = examples.gap;
    return Semantics(
      label:
          'Beispiel einer Stapelübung: In die Lücke wird „$answer“ '
          'getippt, die Lücke wird grün.',
      child: ExcludeSemantics(
        child: DemoLoop(
          length: length,
          rest: rest,
          builder: (context, s) => _PracticeCard(
            child: _GapSentence(
              before: before,
              answer: answer,
              after: after,
              shown: _typed(answer, s, 0.5, 0.15),
              solved: _span(s, 1.7, 1.95) * (1 - _span(s, 5.2, 5.5)),
              fade: 1 - _span(s, 5.2, 5.5),
              caretOn: s < 1.7 && ((s >= 0.5 && s < 1.4) || _blink(s)),
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  const _PracticeCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
    decoration: BoxDecoration(
      color: context.appColors.raisedInk,
      borderRadius: BorderRadius.circular(24),
    ),
    child: child,
  );
}

/// Words of a sentence as spans: words carry the practice sentence's dotted
/// underline, spaces and punctuation do not.
List<InlineSpan> _sentenceSpans(String text, TextStyle word) => [
  for (final match in RegExp(
    r"[\p{L}\p{M}\p{N}]+(?:['’\-][\p{L}\p{M}\p{N}]+)*|[^\p{L}\p{M}\p{N}]+",
    unicode: true,
  ).allMatches(text))
    RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(match[0]!)
        ? TextSpan(text: match[0], style: word)
        : TextSpan(text: match[0]),
];

/// The practice sentence (DeckPracticeScreen › PracticeSentence): serif 24
/// in the practice blue, the gap as a tinted field that turns green.
class _GapSentence extends StatelessWidget {
  const _GapSentence({
    required this.before,
    required this.answer,
    required this.after,
    required this.shown,
    required this.solved,
    required this.fade,
    required this.caretOn,
  });

  final String before, answer, after;
  final int shown;
  final double solved, fade;
  final bool caretOn;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final colors = context.appColors;
      final scaler = MediaQuery.textScalerOf(context);
      final style = AppType.editorial(
        size: 24,
        weight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0,
        color: colors.memoryLevel2,
      );
      final word = style.copyWith(
        decoration: TextDecoration.underline,
        decorationStyle: TextDecorationStyle.dotted,
        decorationColor: colors.textMuted.withValues(alpha: .45),
      );
      final painter = TextPainter(
        text: TextSpan(text: answer, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      final width = math.min(
        constraints.maxWidth,
        math.max(64.0, painter.width + 22),
      );
      painter.dispose();
      final ink = Color.lerp(colors.memoryLevel2, colors.success, solved)!;
      final field = Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: Color.lerp(
            colors.memoryLevel2.withValues(alpha: .12),
            colors.successTint,
            solved,
          ),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                answer.substring(0, shown),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.clip,
                style: style.copyWith(
                  color: ink.withValues(alpha: fade),
                ),
              ),
            ),
            _Caret(
              height: scaler.scale(24) * 1.15,
              color: colors.memoryLevel2,
              on: caretOn,
            ),
          ],
        ),
      );
      // As in the exercise: the inner Text widgets scale themselves, the
      // paragraph gets its scaled size directly.
      return Text.rich(
        TextSpan(
          style: style.copyWith(fontSize: scaler.scale(style.fontSize!)),
          children: [
            ..._sentenceSpans(
              before,
              word.copyWith(fontSize: scaler.scale(style.fontSize!)),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: field,
            ),
            ..._sentenceSpans(
              after,
              word.copyWith(fontSize: scaler.scale(style.fontSize!)),
            ),
          ],
        ),
        textScaler: TextScaler.noScaling,
      );
    },
  );
}

/// Benefit 2: a tap on a word lights it up in popover orange and shows its
/// translation in the orange bubble, first one word, then another.
class GlossDemo extends StatefulWidget {
  const GlossDemo({super.key, required this.examples});
  final PaywallExamples examples;

  static const length = Duration(milliseconds: 8000);
  static const rest = Duration(milliseconds: 2000);

  /// When each word is tapped and when its bubble closes again.
  static const _taps = [(0.6, 3.4), (4.0, 7.2)];

  @override
  State<GlossDemo> createState() => _GlossDemoState();
}

class _GlossDemoState extends State<GlossDemo> {
  final _stack = GlobalKey();
  late List<GlobalKey> _keys = _newKeys();
  List<Rect>? _anchors;

  List<GlobalKey> _newKeys() => [
    for (final _ in widget.examples.glosses) GlobalKey(),
  ];

  @override
  void didUpdateWidget(GlossDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.examples != widget.examples) {
      _keys = _newKeys();
      _anchors = null;
    }
  }

  /// The tapped words' boxes in the stack, measured after layout.
  void _measure() {
    if (!mounted) return;
    final stack = _stack.currentContext?.findRenderObject();
    if (stack is! RenderBox || !stack.hasSize) return;
    final anchors = <Rect>[];
    for (final key in _keys) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      anchors.add(box.localToGlobal(Offset.zero, ancestor: stack) & box.size);
    }
    if (!listEquals(anchors, _anchors)) setState(() => _anchors = anchors);
  }

  @override
  Widget build(BuildContext context) {
    final examples = widget.examples;
    final first = examples.glosses.first;
    return Semantics(
      label:
          'Beispiel beim Lesen: Ein Tipp auf „${first.$1}“ zeigt die '
          'Übersetzung „${first.$2}“.',
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
            final room = _BubbleLayout.height(
              context,
              [for (final (_, translation) in examples.glosses) translation],
              constraints.maxWidth - 40,
            );
            return DemoLoop(
              length: GlossDemo.length,
              rest: GlossDemo.rest,
              builder: (context, s) => _PracticeCard(
                child: Stack(
                  key: _stack,
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: room + 6),
                      child: _ReadingSentence(
                        text: examples.reading,
                        glosses: examples.glosses,
                        keys: _keys,
                        lit: [
                          for (final (from, to) in GlossDemo._taps)
                            _span(s, from + 0.15, from + 0.29) *
                                (1 - _span(s, to, to + 0.14)),
                        ],
                      ),
                    ),
                    if (_anchors case final anchors?)
                      for (final (i, (from, to)) in GlossDemo._taps.indexed)
                        if (i < anchors.length && s >= from && s < to + 0.2)
                          ..._tap(
                            context,
                            anchor: anchors[i],
                            translation: examples.glosses[i].$2,
                            width: constraints.maxWidth - 40,
                            s: s,
                            from: from,
                            to: to,
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The finger's ripple on the word, then the bubble above it.
  List<Widget> _tap(
    BuildContext context, {
    required Rect anchor,
    required String translation,
    required double width,
    required double s,
    required double from,
    required double to,
  }) {
    final ripple = _span(s, from, from + 0.35);
    final open = _span(s, from + 0.15, from + 0.37);
    final close = _span(s, to, to + 0.18);
    final layout = _BubbleLayout(context, translation, anchor, width);
    return [
      if (ripple > 0 && ripple < 1)
        Positioned(
          left: anchor.center.dx - 22,
          top: anchor.center.dy - 22,
          width: 44,
          height: 44,
          child: Transform.scale(
            scale: 0.5 + 0.5 * Curves.easeOut.transform(ripple),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.appColors.textPrimary.withValues(
                  alpha: 0.28 * (1 - ripple),
                ),
              ),
            ),
          ),
        ),
      if (open > 0 && close < 1)
        Positioned(
          left: layout.x,
          top: layout.y,
          width: layout.width,
          height: layout.bubbleHeight,
          child: Opacity(
            opacity: Curves.easeOut.transform(open) * (1 - close),
            child: Transform.scale(
              scale: 0.9 + 0.1 * Curves.easeOutBack.transform(open),
              // Grows out of the arrow's tip, like the real bubble.
              alignment: Alignment((layout.arrowX / layout.width) * 2 - 1, 1),
              child: layout.bubble(),
            ),
          ),
        ),
    ];
  }
}

/// TranslationBubble's geometry, kept inside the demo card.
class _BubbleLayout {
  _BubbleLayout(BuildContext context, this.text, Rect anchor, double maxWidth) {
    final painter = _painter(context, text, maxWidth);
    width = math.min(
      maxWidth,
      painter.width.ceilToDouble() + _start + _gap + _tap + _end,
    );
    bubbleHeight = _heightFor(painter);
    painter.dispose();
    x = (anchor.center.dx - width / 2)
        .clamp(0.0, math.max(0.0, maxWidth - width))
        .toDouble();
    y = anchor.top - 6 - bubbleHeight;
    final minArrow = PopoverBubble.minArrowX(_radius);
    arrowX = (anchor.center.dx - x)
        .clamp(minArrow, math.max(minArrow, width - minArrow))
        .toDouble();
  }

  final String text;
  late final double width, bubbleHeight, x, y, arrowX;

  static const _radius = 14.0, _start = 14.0, _end = 4.0, _gap = 8.0;
  static const _tap = 44.0, _speaker = 34.0, _vertical = 4.0;

  static TextStyle get _style => AppType.editorial(
    color: AppColors.onActive,
    size: 20,
    height: 1.35,
    letterSpacing: 0,
  );

  static TextPainter _painter(
    BuildContext context,
    String text,
    double maxWidth,
  ) => TextPainter(
    text: TextSpan(text: text, style: _style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: math.max(1, maxWidth - _start - _gap - _tap - _end));

  static double _heightFor(TextPainter painter) =>
      math.max(_tap, painter.height.ceilToDouble()) +
      2 * _vertical +
      PopoverBubble.arrowHeight;

  /// The room the tallest bubble needs above the first line.
  static double height(
    BuildContext context,
    List<String> texts,
    double maxWidth,
  ) {
    var tallest = 0.0;
    for (final text in texts) {
      final painter = _painter(context, text, maxWidth);
      tallest = math.max(tallest, _heightFor(painter));
      painter.dispose();
    }
    return tallest;
  }

  Widget bubble() => PopoverBubble(
    color: AppColors.active,
    arrowX: arrowX,
    arrowUp: false,
    radius: _radius,
    shadow: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(_start, _vertical, _end, _vertical),
      child: Row(
        children: [
          Flexible(child: Text(text, style: _style)),
          const SizedBox(width: _gap),
          SizedBox.square(
            dimension: _tap,
            child: Center(
              child: Container(
                width: _speaker,
                height: _speaker,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x33FFFFFF),
                ),
                child: const SpeakerIcon(
                  size: _speaker * 0.5,
                  color: Color(0xFFFFFFFF),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A reading sentence; the glossed words are inline boxes that can be lit.
class _ReadingSentence extends StatelessWidget {
  const _ReadingSentence({
    required this.text,
    required this.glosses,
    required this.keys,
    required this.lit,
  });

  final String text;
  final List<(String, String)> glosses;
  final List<GlobalKey> keys;
  final List<double> lit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final scaler = MediaQuery.textScalerOf(context);
    final style = AppType.editorial(
      size: 24,
      weight: FontWeight.w400,
      height: 1.45,
      letterSpacing: 0,
      color: colors.memoryLevel2,
    );
    final word = style.copyWith(
      decoration: TextDecoration.underline,
      decorationStyle: TextDecorationStyle.dotted,
      decorationColor: colors.textMuted.withValues(alpha: .45),
    );
    final spans = <InlineSpan>[];
    for (final match in RegExp(
      r"[\p{L}\p{M}\p{N}]+(?:['’\-][\p{L}\p{M}\p{N}]+)*|[^\p{L}\p{M}\p{N}]+",
      unicode: true,
    ).allMatches(text)) {
      final piece = match[0]!;
      final index = glosses.indexWhere((g) => g.$1 == piece);
      if (index < 0) {
        spans.add(
          RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(piece)
              ? TextSpan(
                  text: piece,
                  style: word.copyWith(fontSize: scaler.scale(24)),
                )
              : TextSpan(text: piece),
        );
        continue;
      }
      final t = lit[index];
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: CustomPaint(
            key: keys[index],
            painter: t == 0
                ? null
                : _PlatePainter(colors.popover.withValues(alpha: t)),
            child: Text(
              piece,
              style: t > 0.5
                  ? style.copyWith(color: AppColors.onActive)
                  : word,
            ),
          ),
        ),
      );
    }
    return Text.rich(
      TextSpan(
        style: style.copyWith(fontSize: scaler.scale(24)),
        children: spans,
      ),
      textScaler: TextScaler.noScaling,
    );
  }
}

/// PracticeSentence's plate behind a tapped word, painted outside the
/// word's box so the sentence never reflows.
class _PlatePainter extends CustomPainter {
  const _PlatePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTRB(-5, size.height * 0.12, size.width + 5, size.height * 0.94),
      const Radius.circular(8),
    ),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_PlatePainter old) => old.color != color;
}

/// Benefit 3: a German sentence, its translation typed below, the answer
/// turns green and the tutor adds one sentence of feedback.
class TutorDemo extends StatelessWidget {
  const TutorDemo({super.key, required this.examples});
  final PaywallExamples examples;

  static const length = Duration(milliseconds: 11000);
  static const rest = Duration(milliseconds: 6500);

  static const _typeFrom = 0.6, _step = 0.06;

  String get feedback => 'Richtig! Noch natürlicher: „${examples.better}“';

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Beispiel AI-Tutor: „${PaywallExamples.tutorPrompt}“ wird als '
        '„${examples.answer}“ übersetzt. Feedback: $feedback',
    child: ExcludeSemantics(
      child: DemoLoop(
        length: length,
        rest: rest,
        builder: (context, s) {
          final colors = context.appColors;
          final answer = examples.answer;
          final typedUntil = _typeFrom + answer.length * _step;
          final out = _span(s, 10.2, 10.6);
          final solved = _span(s, typedUntil + 0.35, typedUntil + 0.6);
          final card = _span(s, typedUntil + 0.8, typedUntil + 1.1) * (1 - out);
          final text = _span(s, typedUntil + 1.5, typedUntil + 1.75);
          final style = AppType.editorial(
            size: 20,
            weight: FontWeight.w400,
            height: 1.45,
            letterSpacing: 0,
            color: Color.lerp(
              colors.memoryLevel2,
              colors.success,
              solved * (1 - out),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PracticeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _TutorChip(),
                    const SizedBox(height: 14),
                    Text(
                      'Übersetze ins ${examples.languageName}',
                      style: AppType.meta(color: colors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      PaywallExamples.tutorPrompt,
                      style: AppType.editorial(
                        size: 24,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          colors.memoryLevel2.withValues(alpha: .12),
                          colors.successTint,
                          solved * (1 - out),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text.rich(
                        _typedSpan(
                          answer,
                          _typed(answer, s, _typeFrom, _step),
                          style,
                          caret: colors.memoryLevel2,
                          caretOn:
                              s < typedUntil + 0.35 &&
                              (s >= _typeFrom || _blink(s)),
                          caretHeight: 20 * 1.2,
                          opacity: 1 - out,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Always laid out, so nothing below moves when it appears.
              Opacity(
                opacity: card,
                child: Transform.translate(
                  offset: Offset(0, 8 * (1 - card)),
                  child: _TutorFeedback(
                    text: feedback,
                    thinking: s < typedUntil + 1.5,
                    textOpacity: text,
                    seconds: s,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _TutorChip extends StatelessWidget {
  const _TutorChip();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: colors.activeTint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.sparkles, size: 15, color: colors.active),
          const SizedBox(width: 6),
          Text(
            'AI-Tutor',
            style: AppType.chrome(
              size: 13,
              weight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The tutor's answer: three pulsing dots while it "thinks", then one
/// sentence. The sentence is always laid out to keep the height.
class _TutorFeedback extends StatelessWidget {
  const _TutorFeedback({
    required this.text,
    required this.thinking,
    required this.textOpacity,
    required this.seconds,
  });

  final String text;
  final bool thinking;
  final double textOpacity, seconds;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.raisedInk,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.activeTint,
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.sparkles, size: 15, color: colors.active),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              children: [
                Opacity(
                  opacity: thinking ? 0 : textOpacity,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      text,
                      style: AppType.chrome(
                        color: colors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                if (thinking)
                  Padding(
                    padding: const EdgeInsets.only(top: 11),
                    child: Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.textMuted.withValues(
                                alpha:
                                    0.35 +
                                    0.65 *
                                        (0.5 +
                                            0.5 *
                                                math.sin(
                                                  seconds * 9 - i * 0.9,
                                                )),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Benefit 4: the topic field (TopicVocabularyComposer): a topic is typed,
/// "Generieren" is pressed, the bar fills while the text glints, then four
/// words appear.
class TopicDemo extends StatelessWidget {
  const TopicDemo({super.key, required this.examples});
  final PaywallExamples examples;

  static const length = Duration(milliseconds: 12000);
  static const rest = Duration(milliseconds: 8500);

  static const _typeFrom = 0.4, _step = 0.065;

  /// Room above the text for the progress bar, as in the composer.
  static const _fieldTop = 26.0;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Beispiel Vokabelgenerierung: Zum Thema „${PaywallExamples.topicPrompt}“ '
        'entstehen ${[for (final (word, gloss) in examples.words) '$word, $gloss'].join('; ')}.',
    child: ExcludeSemantics(
      child: DemoLoop(
        length: length,
        rest: rest,
        builder: (context, s) {
          final colors = context.appColors;
          final scaler = MediaQuery.textScalerOf(context);
          const prompt = PaywallExamples.topicPrompt;
          final typedUntil = _typeFrom + prompt.length * _step;
          final press = typedUntil + 0.35;
          final start = press + 0.2;
          final done = start + 2.9;
          final busy = s >= start && s < done + 0.3;
          final out = _span(s, 11.2, 11.6);
          final shown = _typed(prompt, s, _typeFrom, _step);
          final pressed = _span(s, press, press + 0.08) *
              (1 - _span(s, press + 0.12, press + 0.2));
          final button = shown > 0 && !busy && out < 1;
          final style = AppType.chrome(
            color: busy ? colors.textMuted : colors.textPrimary,
            height: 1.35,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.raisedInk,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LightSweep(
                          enabled: busy && s < done,
                          highlight: colors.textPrimary,
                          child: Container(
                            constraints: BoxConstraints(
                              minHeight: 3 * scaler.scale(15) * 1.35,
                            ),
                            padding: const EdgeInsets.fromLTRB(
                              18,
                              _fieldTop,
                              18,
                              8,
                            ),
                            child: Text.rich(
                              _typedSpan(
                                prompt,
                                shown,
                                style,
                                caret: colors.active,
                                caretOn:
                                    s < press &&
                                    ((s >= _typeFrom && s < typedUntil) ||
                                        _blink(s)),
                                caretHeight: 15 * 1.3,
                                opacity: 1 - out,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 8, 8),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 4,
                            children: [
                              IgnorePointer(
                                child: Opacity(
                                  opacity: busy ? 0.45 : 1,
                                  child: CupertinoSlidingSegmentedControl<int>(
                                    groupValue: 25,
                                    thumbColor: colors.hairline,
                                    backgroundColor: colors.nightPage,
                                    padding: const EdgeInsets.all(3),
                                    children: {
                                      for (final n in [10, 25, 50])
                                        n: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 4,
                                          ),
                                          child: Text(
                                            '$n',
                                            style: AppType.chrome(
                                              size: 15,
                                              weight: FontWeight.w600,
                                              color: colors.textPrimary,
                                            ),
                                          ),
                                        ),
                                    },
                                    onValueChanged: (_) {},
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 44,
                                child: Center(
                                  widthFactor: 1,
                                  child: Opacity(
                                    opacity: button
                                        ? _span(s, _typeFrom, _typeFrom + 0.18)
                                        : 0,
                                    child: Transform.scale(
                                      scale: 1 - 0.06 * pressed,
                                      child: const _GeneratePill(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      top: (_fieldTop - GenerationProgressBar.height) / 2,
                      left: 18,
                      right: 18,
                      child: GenerationProgressBar(
                        busy: busy && s < done,
                        complete: s >= done && s < done + 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Always laid out, so nothing below moves when words appear.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (i, (word, gloss)) in examples.words.indexed)
                    Builder(
                      builder: (context) {
                        final t =
                            Curves.easeOutCubic.transform(
                              _span(
                                s,
                                done + 0.35 + i * 0.12,
                                done + 0.65 + i * 0.12,
                              ),
                            ) *
                            (1 - out);
                        return Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - t)),
                            child: _WordChip(word: word, gloss: gloss),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// The orange "Generieren" pill of the topic field.
class _GeneratePill extends StatelessWidget {
  const _GeneratePill();

  @override
  Widget build(BuildContext context) => Container(
    height: 36,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: AppColors.active,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Center(
      widthFactor: 1,
      child: Text(
        'Generieren',
        style: AppType.chrome(
          size: 15,
          weight: FontWeight.w700,
          color: AppColors.onActive,
        ),
      ),
    ),
  );
}

/// GeneratedWordChip, selected and without interaction.
class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.gloss});
  final String word, gloss;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
      decoration: BoxDecoration(
        color: colors.raisedInk,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            word,
            style: AppType.editorial(
              size: 17,
              height: 1.2,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            gloss,
            style: AppType.chrome(
              size: 13,
              weight: FontWeight.w500,
              color: colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
