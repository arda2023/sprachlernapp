import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

/// One haptic per role, so every tap and swipe in the onboarding and the
/// paywall feels the same (docs/redesign/design-system.md › Onboarding).
abstract final class Haptic {
  /// Picking an option, a plan, a page by swiping.
  static void select() => HapticFeedback.selectionClick();

  /// Back, close, secondary links, tapping a word.
  static void light() => HapticFeedback.lightImpact();

  /// The orange primary action.
  static void primary() => HapticFeedback.mediumImpact();
}

/// Fades and lifts its child in once [active] first turns true. [order]
/// staggers siblings by 60 ms (headline, subline, content …). Reduced
/// motion shows the child at once.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.active,
    required this.child,
    this.order = 0,
    this.offset = 18,
  });

  final bool active;
  final int order;
  final double offset;
  final Widget child;

  static const step = Duration(milliseconds: 60);
  static const travel = Duration(milliseconds: 420);

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: Reveal.travel + Reveal.step * widget.order,
  );

  /// The delay is the leading part of one controller, so no timer is
  /// left behind when the page goes away.
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Interval(
      (Reveal.step * widget.order).inMicroseconds /
          _controller.duration!.inMicroseconds,
      1,
      curve: Curves.easeOutCubic,
    ),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (!widget.active || !_controller.isDismissed) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _curve,
    builder: (context, child) => Opacity(
      opacity: _curve.value,
      child: Transform.translate(
        offset: Offset(0, widget.offset * (1 - _curve.value)),
        child: child,
      ),
    ),
    child: widget.child,
  );
}

/// A tappable surface with press feedback: it settles to 97 % while held
/// (120 ms) and fires its haptic on release. Semantics follow the app's
/// pattern: one button node with [label], children excluded.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.haptic = Haptic.select,
    this.selected,
    this.minSize = const Size(44, 44),
  });

  final String label;
  final VoidCallback? onTap;
  final VoidCallback haptic;
  final bool? selected;
  final Size minSize;
  final Widget child;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  void _tap() {
    widget.haptic();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: widget.selected,
      label: widget.label,
      onTap: enabled ? _tap : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        onTap: enabled ? _tap : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize.width,
            minHeight: widget.minSize.height,
          ),
          child: AnimatedScale(
            scale: _down ? 0.97 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// The orange primary action of the onboarding and the paywall: a pill in
/// popover orange with a soft ember glow underneath (the glow is the only
/// depth on these screens). Dimmed and silent while [onPressed] is null.
class GlowButton extends StatelessWidget {
  const GlowButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final enabled = onPressed != null;
    return Pressable(
      label: label,
      onTap: onPressed,
      haptic: Haptic.primary,
      minSize: const Size(44, 56),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1 : 0.4,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 56),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: colors.popover,
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: colors.popover.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              key: ValueKey(label),
              textAlign: TextAlign.center,
              style: AppType.chrome(
                size: 17,
                weight: FontWeight.w700,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet text action (secondary path, legal links).
class TextAction extends StatelessWidget {
  const TextAction({
    super.key,
    required this.label,
    required this.onTap,
    this.strong = false,
    this.size = 15,
  });

  final String label;
  final VoidCallback onTap;
  final bool strong;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Pressable(
      label: label,
      onTap: onTap,
      haptic: Haptic.light,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppType.chrome(
            size: size,
            weight: FontWeight.w600,
            color: strong ? colors.textPrimary : colors.textMuted,
          ),
        ),
      ),
    );
  }
}
