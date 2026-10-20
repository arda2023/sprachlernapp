import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'anchored_popover.dart';

/// Opens an anchored popover from its child and tells the child while the
/// popover is open, so the trigger can turn the popover colour (Redesign
/// rule: whatever opened the bubble is highlighted in the same orange).
class PopoverTrigger<T> extends StatefulWidget {
  const PopoverTrigger({
    super.key,
    required this.builder,
    required this.popover,
    this.onClosed,
  });

  /// [open] is true while the popover shows; call [show] to open it.
  final Widget Function(BuildContext context, bool open, VoidCallback show)
  builder;
  final WidgetBuilder popover;

  /// Receives the value the popover was closed with.
  final ValueChanged<T?>? onClosed;

  @override
  State<PopoverTrigger<T>> createState() => _PopoverTriggerState<T>();
}

class _PopoverTriggerState<T> extends State<PopoverTrigger<T>> {
  bool _open = false;

  Future<void> _show() async {
    if (_open) return;
    HapticFeedback.selectionClick();
    setState(() => _open = true);
    final result = await showAnchoredPopover<T>(
      anchorContext: context,
      color: context.appColors.popover,
      builder: widget.popover,
    );
    if (mounted) setState(() => _open = false);
    widget.onClosed?.call(result);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _open, _show);
}
