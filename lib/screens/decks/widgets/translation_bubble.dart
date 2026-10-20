import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// Content-sized overlay constrained to the visible safe area above the keyboard.
class TranslationBubble extends StatelessWidget {
  const TranslationBubble({
    super.key,
    required this.anchor,
    required this.text,
  });
  final Rect anchor;
  final String text;

  @override
  Widget build(BuildContext context) {
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
    final style = Theme.of(context).textTheme.bodyMedium!
        .merge(AppType.chrome(color: Colors.white));
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: media.textScaler,
    )..layout(maxWidth: math.max(1, right - left - 24));
    final width = math.min(right - left, painter.width.ceilToDouble() + 25);
    final height = math.min(bottom - top, painter.height.ceilToDouble() + 24);
    painter.dispose();
    final preferredTop = anchor.top - height - 8 >= top
        ? anchor.top - height - 8
        : anchor.bottom + 8;
    return Positioned(
      left: (anchor.center.dx - width / 2).clamp(
        left,
        math.max(left, right - width),
      ),
      top: preferredTop.clamp(top, math.max(top, bottom - height)),
      width: width,
      height: height,
      child: Material(
        key: const ValueKey('translation-bubble'),
        textStyle: style,
        color: context.appColors.popover,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Text(text, textAlign: TextAlign.center, style: style),
        ),
      ),
    );
  }
}
