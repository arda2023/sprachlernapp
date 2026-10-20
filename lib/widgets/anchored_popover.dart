import 'package:flutter/material.dart';

/// A speech-bubble panel whose arrow points at the widget that opened it
/// (progress tiles, flame, daily goal). Same colour as the highlighted
/// anchor, no dimming, tap outside to close.
Future<T?> showAnchoredPopover<T>({
  required BuildContext anchorContext,
  required Color color,
  required WidgetBuilder builder,
  String barrierLabel = 'Schließen',
}) {
  final box = anchorContext.findRenderObject()! as RenderBox;
  return showAnchoredPopoverAt<T>(
    context: anchorContext,
    anchor: box.localToGlobal(Offset.zero) & box.size,
    color: color,
    builder: builder,
    barrierLabel: barrierLabel,
  );
}

/// Same as [showAnchoredPopover], pointing at a global [anchor] rectangle,
/// e.g. the line of a tapped word in running text.
Future<T?> showAnchoredPopoverAt<T>({
  required BuildContext context,
  required Rect anchor,
  required Color color,
  required WidgetBuilder builder,
  String barrierLabel = 'Schließen',
}) => Navigator.of(context).push(
  _PopoverRoute<T>(
    anchor: anchor,
    color: color,
    builder: builder,
    barrierLabel: barrierLabel,
  ),
);

class _PopoverRoute<T> extends PopupRoute<T> {
  _PopoverRoute({
    required this.anchor,
    required this.color,
    required this.builder,
    required this.barrierLabel,
  });

  final Rect anchor;
  final Color color;
  final WidgetBuilder builder;

  @override
  final String barrierLabel;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 220);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _PopoverLayout(anchor: anchor, color: color, builder: builder);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: reduced
          ? child
          : ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(curved),
              alignment: _PopoverLayout.scaleOrigin(context, anchor),
              child: child,
            ),
    );
  }
}

class _PopoverLayout extends StatelessWidget {
  const _PopoverLayout({
    required this.anchor,
    required this.color,
    required this.builder,
  });

  static const gutter = 16.0;
  static const gap = 8.0;
  static const arrowHeight = 10.0;

  final Rect anchor;
  final Color color;
  final WidgetBuilder builder;

  static bool _below(BuildContext context, Rect anchor) {
    final media = MediaQuery.of(context);
    final below = media.size.height - media.padding.bottom - anchor.bottom;
    final above = anchor.top - media.padding.top;
    return below >= 320 || below >= above;
  }

  /// Grow out of the arrow's tip.
  static Alignment scaleOrigin(BuildContext context, Rect anchor) {
    final width = MediaQuery.sizeOf(context).width;
    final x = (anchor.center.dx / width) * 2 - 1;
    return Alignment(x, _below(context, anchor) ? -1 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    final width = (screen.width - 2 * gutter).clamp(0.0, 440.0);
    final left = (anchor.center.dx - width / 2).clamp(
      gutter,
      screen.width - gutter - width,
    );
    final below = _below(context, anchor);
    final arrowX = (anchor.center.dx - left).clamp(28.0, width - 28.0);
    final maxHeight =
        (below
                ? screen.height -
                      media.padding.bottom -
                      anchor.bottom -
                      gap -
                      gutter
                : anchor.top - media.padding.top - gap - gutter)
            .clamp(0.0, double.infinity);

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: color,
          shape: _BubbleBorder(arrowX: arrowX, arrowUp: below),
          shadows: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: below ? arrowHeight : 0,
            bottom: below ? 0 : arrowHeight,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        Positioned(
          left: left,
          width: width,
          top: below ? anchor.bottom + gap : null,
          bottom: below ? null : screen.height - anchor.top + gap,
          child: Material(type: MaterialType.transparency, child: bubble),
        ),
      ],
    );
  }
}

/// Rounded panel with a small rounded arrow at [arrowX] on the top (or
/// bottom) edge.
class _BubbleBorder extends ShapeBorder {
  const _BubbleBorder({required this.arrowX, required this.arrowUp});

  final double arrowX;
  final bool arrowUp;

  static const radius = 22.0;
  static const arrowHalf = 11.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const h = _PopoverLayout.arrowHeight;
    final body = arrowUp
        ? Rect.fromLTRB(rect.left, rect.top + h, rect.right, rect.bottom)
        : Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - h);
    final x = rect.left + arrowX;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(radius)));
    final arrow = Path();
    if (arrowUp) {
      arrow
        ..moveTo(x - arrowHalf, body.top + 1)
        ..quadraticBezierTo(x - 3, body.top - h + 2, x, body.top - h)
        ..quadraticBezierTo(
          x + 3,
          body.top - h + 2,
          x + arrowHalf,
          body.top + 1,
        )
        ..close();
    } else {
      arrow
        ..moveTo(x - arrowHalf, body.bottom - 1)
        ..quadraticBezierTo(x - 3, body.bottom + h - 2, x, body.bottom + h)
        ..quadraticBezierTo(
          x + 3,
          body.bottom + h - 2,
          x + arrowHalf,
          body.bottom - 1,
        )
        ..close();
    }
    return Path.combine(PathOperation.union, path, arrow);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
