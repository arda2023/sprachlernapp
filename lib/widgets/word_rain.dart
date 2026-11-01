import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'launch_splash.dart';

/// "Hello" in every learning language, for the paywall's header.
const greetings = ['Hello', 'Olá', 'Hei', 'Ciao', 'Hola'];

/// Four words per learning language for the language switch.
List<String> wordsFor(String lang) => switch (lang) {
  'pt-BR' => ['Olá', 'História', 'Ler', 'Aprender'],
  'nb' => ['Hei', 'Historie', 'Lese', 'Lære'],
  'it' => ['Ciao', 'Storia', 'Leggere', 'Imparare'],
  'es' => ['Hola', 'Historia', 'Leer', 'Aprender'],
  _ => ['Hello', 'Story', 'Read', 'Learn'],
};

/// The dim ember tone of the big words: the popover orange sunk into the
/// night page, the way Babbel sets its "Hello".
Color emberOf(AppPalette colors) =>
    Color.lerp(colors.popover, colors.nightPage, 0.55)!;

/// One huge serif word at a time, cropped at the right edge. Each word
/// slides in from below or above (alternating), rests, and fades out while
/// the next one arrives. Reduced motion shows the first word still.
class WordCycle extends StatefulWidget {
  const WordCycle({
    super.key,
    required this.words,
    required this.height,
    this.color,
    this.period = const Duration(milliseconds: 1900),
  });

  final List<String> words;
  final double height;
  final Color? color;

  /// Time each word holds the stage, entry included.
  final Duration period;

  @override
  State<WordCycle> createState() => _WordCycleState();
}

class _WordCycleState extends State<WordCycle>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: widget.period * widget.words.length,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Widget tests (no LaunchSplash.enabled) get the still word, so
    // pumpAndSettle does not wait for the loop.
    if (!LaunchSplash.enabled || MediaQuery.disableAnimationsOf(context)) {
      _clock
        ..stop()
        ..value = _entry / widget.words.length;
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  /// Share of a period the entry (and the overlapping exit) takes.
  static const _entry = 0.32;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? emberOf(context.appColors);
    final size = widget.height * 0.86;
    final n = widget.words.length;
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              // Global time in periods; each word k starts at k and is on
              // stage from k - _entry (arriving) until k + 1 (gone).
              final t = _clock.value * n;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (var k = 0; k < n; k++)
                    if (_local(t, k, n) case final lt
                        when lt >= -_entry && lt <= 1)
                      _word(widget.words[k], lt, k.isEven, size, color),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Time since word [k]'s start, wrapped so the first word arrives while
  /// the last one leaves.
  static double _local(double t, int k, int n) =>
      ((t - k + _entry) % n + n) % n - _entry;

  Widget _word(String text, double lt, bool fromBelow, double size, Color c) {
    final h = widget.height;
    final double dy, opacity;
    if (lt < 0) {
      final e = Curves.easeOutCubic.transform((lt + _entry) / _entry);
      dy = (fromBelow ? 1 : -1) * h * (1 - e);
      opacity = 1;
    } else if (lt > 1 - _entry) {
      final x = (lt - (1 - _entry)) / _entry;
      dy = (fromBelow ? -1 : 1) * h * 0.18 * Curves.easeIn.transform(x);
      opacity = 1 - Curves.easeIn.transform(x);
    } else {
      dy = 0;
      opacity = 1;
    }
    return Positioned(
      left: -size * 0.04,
      top: (h - size * 1.05) / 2 + dy,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: _BigWord(text: text, size: size, color: c),
      ),
    );
  }
}

/// Four large, light words in [lang] enter in sequence from alternating
/// edges. Two are cropped at the side; all keep drifting while content loads.
class WordWall extends StatefulWidget {
  const WordWall({super.key, required this.lang});

  final String lang;

  /// Until the last word has entered; the gentle drift continues.
  static const settle = Duration(milliseconds: 1070);

  @override
  State<WordWall> createState() => _WordWallState();
}

class _WordWallState extends State<WordWall> with TickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: WordWall.settle,
  );
  late final _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );
  late final _motion = Listenable.merge([_entrance, _drift]);
  static const _easeOut = Cubic(0.23, 1, 0.32, 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance
        ..stop()
        ..value = 1;
      _drift
        ..stop()
        ..value = 0;
    } else {
      if (_entrance.value == 0 && !_entrance.isAnimating) {
        _entrance.forward();
      }
      if (!_drift.isAnimating) _drift.repeat();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final words = wordsFor(widget.lang);
    final ember = emberOf(colors);
    return ColoredBox(
      color: colors.nightPage,
      child: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Semantics(
          label: 'Lernsprache wird gewechselt',
          excludeSemantics: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screen = constraints.biggest;
              final pad = MediaQuery.paddingOf(context);
              final rows = words.length;
              final rowHeight = (screen.height - pad.top - pad.bottom) / rows;
              final size = math.min(
                148.0,
                math.min(rowHeight * 0.64, screen.width * 0.34),
              );
              return ClipRect(
                child: Stack(
                  children: [
                    for (var i = 0; i < rows; i++)
                      _row(
                        words[i],
                        index: i,
                        top: pad.top + i * rowHeight,
                        rowHeight: rowHeight,
                        screenWidth: screen.width,
                        size: size,
                        // The greeting glows, the rest stays ember.
                        color: i == 0
                            ? colors.popover
                            : i.isOdd
                            ? ember
                            : Color.lerp(ember, colors.popover, 0.35)!,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(
    String word, {
    required int index,
    required double top,
    required double rowHeight,
    required double screenWidth,
    required double size,
    required Color color,
  }) {
    final fromBelow = index.isOdd;
    final distance = fromBelow ? rowHeight : -rowHeight;
    final cropped = index.isOdd;
    final alignment = !cropped
        ? Alignment.center
        : index == 1
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final style = AppType.chrome(
      color: color,
      size: size,
      weight: FontWeight.w400,
      height: 1.1,
    );
    final measure = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout();
    final width = math.min(
      measure.width,
      cropped ? screenWidth / 0.7 : screenWidth - 56,
    );
    measure.dispose();
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      height: rowHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _motion,
          // The words are laid out once; only their transform changes per frame.
          child: OverflowBox(
            alignment: alignment,
            maxWidth: double.infinity,
            child: FractionalTranslation(
              translation: Offset(
                !cropped
                    ? 0
                    : index == 1
                    ? 0.3
                    : -0.3,
                0,
              ),
              child: SizedBox(
                width: width,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    word,
                    maxLines: 1,
                    softWrap: false,
                    textScaler: TextScaler.noScaling,
                    style: style,
                  ),
                ),
              ),
            ),
          ),
          builder: (context, child) {
            // Each 650 ms entry starts 140 ms after the previous one.
            final elapsed = _entrance.value * WordWall.settle.inMilliseconds;
            final p = ((elapsed - index * 140) / 650).clamp(0.0, 1.0);
            final entryY = distance * (1 - _easeOut.transform(p));
            final angle = _drift.value * 2 * math.pi;
            // Add the drift during entry too, so arriving never freezes.
            final driftY =
                math.sin(angle) *
                math.min(36.0, rowHeight * 0.14) *
                (fromBelow ? -1 : 1);
            final phase = index * 0.8;
            final driftX = (math.sin(angle + phase) - math.sin(phase)) * 12;
            return Transform.translate(
              offset: Offset(driftX, entryY + driftY),
              child: child,
            );
          },
        ),
      ),
    );
  }
}

class _BigWord extends StatelessWidget {
  const _BigWord({required this.text, required this.size, required this.color});

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.visible,
    textScaler: TextScaler.noScaling,
    style: AppType.editorial(
      color: color,
      size: size,
      weight: FontWeight.w700,
      height: 1.05,
      letterSpacing: -size / 40,
    ),
  );
}
