import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/speak_button.dart';

/// The tapped word's translation in practice: the same orange bubble as
/// every popover, sized to its content, with the arrow on the word and a
/// pronunciation button. It sits above the word (the keyboard is below) and
/// stays inside the visible safe area.
class TranslationBubble extends StatefulWidget {
  const TranslationBubble({
    super.key,
    required this.anchor,
    required this.text,
  });

  /// The tapped word, in the coordinates of the enclosing [Stack].
  final Rect anchor;
  final String text;

  static const radius = 14.0;
  static const gap = 6.0;

  @override
  State<TranslationBubble> createState() => _TranslationBubbleState();
}

class _TranslationBubbleState extends State<TranslationBubble>
    with SingleTickerProviderStateMixin {
  late final _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void didUpdateWidget(TranslationBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Another word: grow out of its arrow again.
    if (oldWidget.anchor != widget.anchor || oldWidget.text != widget.text) {
      _intro.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const white = Color(0xFFFFFFFF);
    const speaker = 34.0, tap = 44.0, start = 14.0, end = 4.0, gap = 8.0;
    const vertical = 4.0;
    final anchor = widget.anchor;
    final media = MediaQuery.of(context);
    final left = media.padding.left + 16;
    final right = media.size.width - media.padding.right - 16;
    final top = media.padding.top + 8;
    final bottom = math.max(
      top + 1,
      media.size.height -
          math.max(media.viewInsets.bottom, media.padding.bottom) -
          8,
    );
    final style = AppType.editorial(
      color: white,
      size: 19,
      height: 1.3,
      letterSpacing: 0,
    );
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      textDirection: Directionality.of(context),
      textScaler: media.textScaler,
    )..layout(maxWidth: math.max(1, right - left - start - gap - tap - end));
    final width = math.min(
      right - left,
      painter.width.ceilToDouble() + start + gap + tap + end,
    );
    final height = math.min(
      bottom - top,
      math.max(tap, painter.height.ceilToDouble()) +
          2 * vertical +
          PopoverBubble.arrowHeight,
    );
    painter.dispose();
    final above = anchor.top - TranslationBubble.gap - height >= top;
    final y = (above
            ? anchor.top - TranslationBubble.gap - height
            : anchor.bottom + TranslationBubble.gap)
        .clamp(top, math.max(top, bottom - height))
        .toDouble();
    final x = (anchor.center.dx - width / 2)
        .clamp(left, math.max(left, right - width))
        .toDouble();
    final minArrow = PopoverBubble.minArrowX(TranslationBubble.radius);
    final arrowX = (anchor.center.dx - x)
        .clamp(minArrow, math.max(minArrow, width - minArrow))
        .toDouble();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final curved = CurvedAnimation(parent: _intro, curve: Curves.easeOutBack);
    Widget bubble = Material(
      key: const ValueKey('translation-bubble'),
      type: MaterialType.transparency,
      child: PopoverBubble(
        color: context.appColors.popover,
        arrowX: arrowX,
        arrowUp: !above,
        radius: TranslationBubble.radius,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(start, vertical, end, vertical),
          child: Row(
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Text(widget.text, style: style),
                ),
              ),
              const SizedBox(width: gap),
              const SpeakButton(diameter: speaker),
            ],
          ),
        ),
      ),
    );
    if (!reduceMotion) {
      bubble = ScaleTransition(
        scale: Tween(begin: 0.9, end: 1.0).animate(curved),
        // Grow out of the arrow's tip.
        alignment: Alignment((arrowX / width) * 2 - 1, above ? 1 : -1),
        child: bubble,
      );
    }
    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
        child: bubble,
      ),
    );
  }
}
