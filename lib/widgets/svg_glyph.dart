import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A single-path SVG icon, drawn without an SVG package (no new
/// dependencies in the redesign copy). Path data is copied verbatim from the
/// source files; [viewBox] is the SVG's square view box size.
class SvgGlyph {
  const SvgGlyph(
    this.pathData, {
    required this.viewBox,
    this.strokeWidth,
    this.evenOdd = false,
  });

  final String pathData;
  final double viewBox;

  /// Set for outline icons (stroke instead of fill), in view-box units.
  final double? strokeWidth;
  final bool evenOdd;
}

/// Icons supplied for the redesign (Downloads, 20.10.2026).
abstract final class AppGlyphs {
  /// target-fill.svg — daily goal.
  static const target = SvgGlyph(
    'M12 2a1 1 0 1 1 0 2a8 8 0 1 0 8 8a1 1 0 1 1 2 0c0 5.523-4.477 10-10 '
    '10S2 17.523 2 12S6.477 2 12 2m0 4a1 1 0 1 1 0 2a4 4 0 1 0 4 4a1 1 0 1 '
    '1 2 0a6 6 0 1 1-6-6m6.571-3.9a.5.5 0 0 1 .5.5v1.83a.5.5 0 0 0 .5.499H'
    '21.4a.5.5 0 0 1 .5.5v.915l-1.888 1.888a2 2 0 0 1-1.414.586h-2l-3.89 '
    '3.889a1 1 0 0 1-1.414-1.414l3.89-3.889v-2a2 2 0 0 1 .585-1.414l1.89-'
    '1.89z',
    viewBox: 24,
  );

  /// star-1-solid.svg — earned week star.
  static const starSolid = SvgGlyph(
    'M7 .277a1.04 1.04 0 0 0-.94.596L4.472 4.078a.495.495 0 0 0-.012.023a'
    '.486.486 0 0 0-.023.004L.94 4.623a1.04 1.04 0 0 0-.617 1.788l2.56 '
    '2.469l.006.005a.03.03 0 0 1 .009.027v.004l-.61 3.568v.001a1.05 1.05 0 '
    '0 0 1.526 1.107l3.15-1.665a.09.09 0 0 1 .072 0l3.15 1.664a1.049 1.049 '
    '0 0 0 1.527-1.106l-.61-3.57v-.003c-.002-.004-.001-.01 0-.014a.03.03 0 '
    '0 1 .008-.013l.006-.005l2.559-2.47a1.04 1.04 0 0 0-.617-1.787l-3.496-'
    '.518a.486.486 0 0 0-.023-.004a.495.495 0 0 0-.012-.023L7.94.873A1.04 '
    '1.04 0 0 0 7 .277',
    viewBox: 14,
    evenOdd: true,
  );

  /// star-1-remix.svg — open week star (outline).
  static const starOutline = SvgGlyph(
    'M6.745 11.274a.58.58 0 0 1 .51 0l3.1 1.638a.54.54 0 0 0 .784-.569l-'
    '.598-3.501a.52.52 0 0 1 .157-.471l2.51-2.422a.53.53 0 0 0-.323-.913l-'
    '3.443-.51a.5.5 0 0 1-.402-.294L7.48 1.084a.53.53 0 0 0-.96 0L4.96 '
    '4.232a.5.5 0 0 1-.402.294l-3.442.51a.53.53 0 0 0-.324.913l2.51 2.422a'
    '.52.52 0 0 1 .158.47l-.599 3.502a.54.54 0 0 0 .785.569z',
    viewBox: 14,
    strokeWidth: 1.25,
  );

  /// check-mark.svg — a practised streak day.
  static const check = SvgGlyph(
    'M28.21 2.4a3.5 3.5 0 0 1 1.344 4.763l-11.51 20.554a4 4 0 0 1-6.135 '
    '1.047L3.186 21.08a3.5 3.5 0 0 1 4.628-5.252l5.936 5.23l9.696-17.314A3.5 '
    '3.5 0 0 1 28.21 2.4Z',
    viewBox: 32,
  );

  /// cross-mark.svg — a missed streak day.
  static const cross = SvgGlyph(
    'M24.879 2.879A3 3 0 1 1 29.12 7.12l-8.79 8.79a.125.125 0 0 0 0 .177l8.79 '
    '8.79a3 3 0 1 1-4.242 4.243l-8.79-8.79a.125.125 0 0 0-.177 0l-8.79 8.79a3 '
    '3 0 1 1-4.243-4.242l8.79-8.79a.125.125 0 0 0 0-.177l-8.79-8.79A3 3 0 0 1 '
    '7.12 2.878l8.79 8.79a.125.125 0 0 0 .177 0l8.79-8.79Z',
    viewBox: 32,
  );
}

class GlyphIcon extends StatelessWidget {
  const GlyphIcon(this.glyph, {super.key, required this.size, this.color});

  final SvgGlyph glyph;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _GlyphPainter(
        glyph,
        color ?? IconTheme.of(context).color ?? const Color(0xFF000000),
      ),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph, this.color);

  final SvgGlyph glyph;
  final Color color;

  static final _cache = Expando<Path>();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _cache[glyph] ??= parseSvgPath(glyph.pathData);
    final scale = size.shortestSide / glyph.viewBox;
    canvas.save();
    canvas.scale(scale);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    if (glyph.strokeWidth case final w?) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    } else {
      path.fillType = glyph.evenOdd
          ? ui.PathFillType.evenOdd
          : ui.PathFillType.nonZero;
    }
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.glyph != glyph || old.color != color;
}

/// Parses SVG path data (M L H V C S Q T A Z, absolute and relative).
Path parseSvgPath(String data) {
  final path = Path();
  final tokens = _tokenize(data);
  var i = 0;
  var x = 0.0, y = 0.0;
  var startX = 0.0, startY = 0.0;
  double? ctrlX, ctrlY; // last cubic/quadratic control point
  String? command;
  String? previous;

  bool hasNumber() => i < tokens.length && tokens[i] is double;
  double next() => tokens[i++] as double;
  bool flag() => next() != 0;

  while (i < tokens.length) {
    if (tokens[i] is String) {
      command = tokens[i++] as String;
    } else if (command == null) {
      throw FormatException('Path data must start with a command', data);
    }
    final c = command;
    final rel = c.toLowerCase() == c;
    final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
    switch (c.toUpperCase()) {
      case 'M':
        x = ox + next();
        y = oy + next();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        // Further pairs are implicit line-tos.
        command = rel ? 'l' : 'L';
      case 'L':
        x = ox + next();
        y = oy + next();
        path.lineTo(x, y);
      case 'H':
        x = ox + next();
        path.lineTo(x, y);
      case 'V':
        y = oy + next();
        path.lineTo(x, y);
      case 'C':
        final x1 = ox + next(), y1 = oy + next();
        final x2 = ox + next(), y2 = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        ctrlX = x2;
        ctrlY = y2;
      case 'S':
        final reflect = previous != null && 'CcSs'.contains(previous);
        final x1 = reflect ? 2 * x - ctrlX! : x;
        final y1 = reflect ? 2 * y - ctrlY! : y;
        final x2 = ox + next(), y2 = oy + next();
        x = ox + next();
        y = oy + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        ctrlX = x2;
        ctrlY = y2;
      case 'Q':
        final x1 = ox + next(), y1 = oy + next();
        x = ox + next();
        y = oy + next();
        path.quadraticBezierTo(x1, y1, x, y);
        ctrlX = x1;
        ctrlY = y1;
      case 'T':
        final reflect = previous != null && 'QqTt'.contains(previous);
        final x1 = reflect ? 2 * x - ctrlX! : x;
        final y1 = reflect ? 2 * y - ctrlY! : y;
        x = ox + next();
        y = oy + next();
        path.quadraticBezierTo(x1, y1, x, y);
        ctrlX = x1;
        ctrlY = y1;
      case 'A':
        final rx = next(), ry = next(), rotation = next();
        final large = flag(), sweep = flag();
        x = ox + next();
        y = oy + next();
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: large,
          clockwise: sweep,
        );
      case 'Z':
        path.close();
        x = startX;
        y = startY;
      default:
        throw FormatException('Unsupported path command $c', data);
    }
    previous = c;
    if (c.toUpperCase() == 'Z' && hasNumber()) {
      throw FormatException('Numbers after Z', data);
    }
  }
  return path;
}

final _number = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?');

List<Object> _tokenize(String data) {
  final tokens = <Object>[];
  var i = 0;
  while (i < data.length) {
    final ch = data[i];
    if (' ,\n\r\t'.contains(ch)) {
      i++;
    } else if (RegExp('[A-Za-z]').hasMatch(ch)) {
      tokens.add(ch);
      i++;
    } else {
      final match = _number.matchAsPrefix(data, i);
      if (match == null) throw FormatException('Bad path data', data, i);
      tokens.add(double.parse(match[0]!));
      i = match.end;
    }
  }
  return tokens;
}
