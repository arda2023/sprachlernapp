import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';
import 'launch_splash.dart';

/// "Hello" in every learning language, for the paywall's header.
const greetings = ['Hello', 'Olá', 'Hei', 'Ciao', 'Hola'];

/// A few warm words per learning language for the language switch
/// (user request 31.10.2026: like Babbel's "Hello", with more words).
List<String> wordsFor(String lang) => switch (lang) {
  'pt-BR' => ['Olá', 'História', 'Ler', 'Palavras', 'Viagem', 'Aprender'],
  'nb' => ['Hei', 'Historie', 'Lese', 'Ord', 'Reise', 'Lære'],
  'it' => ['Ciao', 'Storia', 'Leggere', 'Parole', 'Viaggio', 'Imparare'],
  'es' => ['Hola', 'Historia', 'Leer', 'Palabras', 'Viaje', 'Aprender'],
  _ => ['Hello', 'Story', 'Read', 'Words', 'Journey', 'Learn'],
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

/// A full screen of big words in [lang]: each row's word travels in from
/// the bottom or top edge (alternating), one after another, until the wall
/// stands. Used over the app while another learning language loads.
class WordWall extends StatefulWidget {
  const WordWall({super.key, required this.lang});

  final String lang;

  /// Until the last word has landed.
  static const settle = Duration(milliseconds: 1250);

  @override
  State<WordWall> createState() => _WordWallState();
}

class _WordWallState extends State<WordWall>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: WordWall.settle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.value = 1;
    } else if (_clock.value == 0 && !_clock.isAnimating) {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
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
              final size = math.min(rowHeight * 0.92, screen.width * 0.42);
              return ClipRect(
                child: AnimatedBuilder(
                  animation: _clock,
                  builder: (context, _) => Stack(
                    children: [
                      for (var i = 0; i < rows; i++)
                        _row(
                          words[i],
                          index: i,
                          rows: rows,
                          top: pad.top + i * rowHeight,
                          rowHeight: rowHeight,
                          screenHeight: screen.height,
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
    required int rows,
    required double top,
    required double rowHeight,
    required double screenHeight,
    required double size,
    required Color color,
  }) {
    // Rows start 90 ms apart; each travel takes 60 % of the clock.
    const travel = 0.6;
    final start = rows == 1 ? 0.0 : index * (1 - travel) / (rows - 1);
    final p = ((_clock.value - start) / travel).clamp(0.0, 1.0);
    final e = Curves.easeOutCubic.transform(p);
    final fromBelow = index.isOdd;
    final distance = fromBelow ? screenHeight - top : -(top + rowHeight);
    // Odd rows lean right so the words do not line up like a list.
    final left = index.isOdd ? size * 0.35 : -size * 0.05;
    return Positioned(
      left: left,
      top: top + (rowHeight - size * 1.05) / 2 + distance * (1 - e),
      child: _BigWord(text: word, size: size, color: color),
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
