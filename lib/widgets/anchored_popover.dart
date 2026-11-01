import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A speech-bubble panel whose arrow points at the widget that opened it
/// (progress tiles, flame, daily goal). Same colour as the highlighted
/// anchor, no dimming, tap outside to close.
Future<T?> showAnchoredPopover<T>({
  required BuildContext anchorContext,
  required Color color,
  required WidgetBuilder builder,
  String barrierLabel = 'Schließen',
  double maxWidth = 440,
}) {
  final box = anchorContext.findRenderObject()! as RenderBox;
  return showAnchoredPopoverAt<T>(
    context: anchorContext,
    anchor: box.localToGlobal(Offset.zero) & box.size,
    color: color,
    builder: builder,
    barrierLabel: barrierLabel,
    maxWidth: maxWidth,
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
  double maxWidth = 440,
  EdgeInsets padding = const EdgeInsets.all(20),
}) => Navigator.of(context).push(
  _PopoverRoute<T>(
    anchor: anchor,
    color: color,
    builder: builder,
    barrierLabel: barrierLabel,
    maxWidth: maxWidth,
    padding: padding,
  ),
);

typedef _PopoverGeometry = ({double maxWidth, EdgeInsets padding});

/// Lets the content of an open popover change the bubble's width and inner
/// padding, e.g. a sentence bubble that turns into the small Premium card
/// or a menu that opens a wider page. The bubble animates to the new size.
abstract final class PopoverResize {
  static void to(
    BuildContext context, {
    required double maxWidth,
    required EdgeInsets padding,
  }) {
    context
        .getInheritedWidgetOfExactType<_PopoverGeometryScope>()
        ?.geometry
        .value = (
      maxWidth: maxWidth,
      padding: padding,
    );
  }
}

class _PopoverGeometryScope extends InheritedWidget {
  const _PopoverGeometryScope({required this.geometry, required super.child});

  final ValueNotifier<_PopoverGeometry> geometry;

  @override
  bool updateShouldNotify(_PopoverGeometryScope oldWidget) =>
      geometry != oldWidget.geometry;
}

class _PopoverRoute<T> extends PopupRoute<T> {
  _PopoverRoute({
    required this.anchor,
    required this.color,
    required this.builder,
    required this.barrierLabel,
    required double maxWidth,
    required EdgeInsets padding,
  }) : _geometry = ValueNotifier((maxWidth: maxWidth, padding: padding));

  final Rect anchor;
  final Color color;
  final WidgetBuilder builder;

  /// Menus stay narrow; info bubbles may use the full phone width. The
  /// content may change both while the popover shows ([PopoverResize]).
  final ValueNotifier<_PopoverGeometry> _geometry;

  @override
  void dispose() {
    _geometry.dispose();
    super.dispose();
  }

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
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 340);
    return ValueListenableBuilder<_PopoverGeometry>(
      valueListenable: _geometry,
      builder: (context, geometry, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: geometry.maxWidth),
        duration: duration,
        curve: Curves.easeOutCubic,
        builder: (context, width, _) => TweenAnimationBuilder<EdgeInsets>(
          tween: EdgeInsetsTween(end: geometry.padding),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, padding, _) => _PopoverLayout(
            anchor: anchor,
            color: color,
            builder: (context) => _PopoverGeometryScope(
              geometry: _geometry,
              child: Builder(builder: builder),
            ),
            maxWidth: width,
            padding: padding,
          ),
        ),
      ),
    );
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
    required this.maxWidth,
    required this.padding,
  });

  static const gutter = 16.0;
  static const gap = 8.0;

  final Rect anchor;
  final Color color;
  final WidgetBuilder builder;
  final double maxWidth;
  final EdgeInsets padding;

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
    final width = (screen.width - 2 * gutter).clamp(0.0, maxWidth);
    final left = (anchor.center.dx - width / 2).clamp(
      gutter,
      screen.width - gutter - width,
    );
    final below = _below(context, anchor);
    // The arrow stays on the straight edge, off the rounded corners.
    final minArrow = PopoverBubble.minArrowX(PopoverBubble.defaultRadius);
    final arrowX = (anchor.center.dx - left)
        .clamp(minArrow, math.max(minArrow, width - minArrow))
        .toDouble();
    // A text field inside (the word note) brings up the keyboard: the
    // bubble then ends above it, so the focused field can scroll into view.
    final floor = math.max(media.padding.bottom, media.viewInsets.bottom);
    final bottom = below
        ? null
        : math.max(screen.height - anchor.top + gap, floor + gutter);
    final maxHeight =
        (below
                ? screen.height - floor - anchor.bottom - gap - gutter
                : screen.height - bottom! - media.padding.top - gutter)
            .clamp(0.0, double.infinity);

    final bubble = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: PopoverBubble(
        color: color,
        arrowX: arrowX,
        arrowUp: below,
        child: SingleChildScrollView(
          padding: padding,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: IconTheme.merge(
              data: const IconThemeData(color: Colors.white),
              child: Builder(builder: builder),
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
          bottom: bottom,
          child: Material(type: MaterialType.transparency, child: bubble),
        ),
      ],
    );
  }
}

/// The speech bubble itself: a [color] panel with a small rounded arrow at
/// [arrowX] on its top edge ([arrowUp]) or bottom edge, pointing at what
/// opened it. Shared by the anchored popovers and the practice word bubble,
/// so every orange bubble in the app has the same shape.
class PopoverBubble extends StatelessWidget {
  const PopoverBubble({
    super.key,
    required this.color,
    required this.arrowX,
    required this.arrowUp,
    required this.child,
    this.radius = defaultRadius,
  });

  static const arrowHeight = 10.0;
  static const defaultRadius = 22.0;

  /// Keeps the arrow off the rounded corners.
  static double minArrowX(double radius) => radius + _BubbleBorder.arrowHalf;

  final Color color;
  final double arrowX;
  final bool arrowUp;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: color,
      shape: _BubbleBorder(arrowX: arrowX, arrowUp: arrowUp, radius: radius),
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
        top: arrowUp ? arrowHeight : 0,
        bottom: arrowUp ? 0 : arrowHeight,
      ),
      child: child,
    ),
  );
}

/// Rounded panel with a small rounded arrow at [arrowX] on the top (or
/// bottom) edge.
class _BubbleBorder extends ShapeBorder {
  const _BubbleBorder({
    required this.arrowX,
    required this.arrowUp,
    required this.radius,
  });

  final double arrowX;
  final bool arrowUp;
  final double radius;

  static const arrowHalf = 11.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const h = PopoverBubble.arrowHeight;
    final body = arrowUp
        ? Rect.fromLTRB(rect.left, rect.top + h, rect.right, rect.bottom)
        : Rect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom - h);
    final x = rect.left + arrowX;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(body, Radius.circular(radius)));
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
