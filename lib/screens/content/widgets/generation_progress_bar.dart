import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';

/// Thin rounded bar at the top of the topic field while words are being
/// generated (user request 01.11.2026, replaces the progress button). Its
/// fill is an estimate, never a measured percentage: it eases towards 90 %
/// and only fills completely once the server answered.
class GenerationProgressBar extends StatefulWidget {
  const GenerationProgressBar({
    super.key,
    required this.busy,
    required this.complete,
  });

  final bool busy;
  final bool complete;

  static const height = 5.0;

  @override
  State<GenerationProgressBar> createState() => _GenerationProgressBarState();
}

class _GenerationProgressBarState extends State<GenerationProgressBar>
    with SingleTickerProviderStateMixin {
  late final _fill = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(GenerationProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.busy != widget.busy ||
        oldWidget.complete != widget.complete) {
      _sync();
    }
  }

  void _sync() {
    if (widget.complete) {
      if (_reduceMotion) {
        _fill.value = 1;
      } else {
        _fill.animateTo(
          1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } else if (!widget.busy) {
      _fill.reset();
    } else if (_reduceMotion) {
      _fill
        ..stop()
        ..value = 0.12;
    } else {
      if (_fill.value >= 1) _fill.reset();
      if (!_fill.isAnimating && _fill.value < 0.9) {
        _fill.animateTo(0.9, curve: Curves.easeOut);
      }
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final visible = widget.busy || widget.complete;
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: GenerationProgressBar.height,
        child: ColoredBox(
          color: colors.hairline,
          child: AnimatedBuilder(
            animation: _fill,
            builder: (context, _) => Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                key: const ValueKey('generation-progress-fill'),
                widthFactor: _fill.value,
                heightFactor: 1,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                    gradient: LinearGradient(
                      colors: [Color(0xFFE26C00), AppColors.active],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      // Announced from the first frame, while it still fades in.
      alwaysIncludeSemantics: true,
      duration: _reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      child: visible
          ? Semantics(
              liveRegion: true,
              label: widget.complete ? 'Bereit' : 'Wird generiert',
              value: widget.complete ? null : 'In Bearbeitung',
              child: ExcludeSemantics(child: bar),
            )
          : ExcludeSemantics(child: bar),
    );
  }
}
