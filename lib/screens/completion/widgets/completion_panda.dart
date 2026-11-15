import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:rive/rive.dart' as rive;

import '../../onboarding/widgets/onboarding_art.dart';

/// The panda's bottom edge sits flush with the streak bar. Flutter owns the
/// movement of both widgets; the Rive state machine animates the panda itself.
class CompletionPanda extends StatefulWidget {
  const CompletionPanda({
    super.key,
    required this.celebrate,
    required this.still,
    required this.onIntroStarted,
    required this.onLoadFailed,
  });

  static const aspectRatio = 420 / 400;
  static const introDuration = Duration(milliseconds: 1200);
  static const asset = 'assets/rive/panda_completion.riv';
  static const stillAsset = 'assets/rive/panda_completion_still.png';

  static bool get hasNativeRuntime => OnboardingArt.riveReady;

  final bool celebrate;
  final bool still;
  final VoidCallback onIntroStarted;
  final VoidCallback onLoadFailed;

  @override
  State<CompletionPanda> createState() => _CompletionPandaState();
}

class _CompletionPandaState extends State<CompletionPanda> {
  rive.File? _file;
  rive.RiveWidgetController? _controller;
  rive.ViewModelInstance? _model;
  rive.ViewModelInstanceBoolean? _celebrate;
  bool _loading = false;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadIfNeeded();
  }

  void _loadIfNeeded() {
    if (!widget.still &&
        CompletionPanda.hasNativeRuntime &&
        !_loading &&
        !_loadFailed &&
        _controller == null) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    _loading = true;
    rive.File? file;
    rive.RiveWidgetController? controller;
    rive.ViewModelInstance? model;
    try {
      file = await rive.File.asset(
        CompletionPanda.asset,
        riveFactory: rive.Factory.rive,
      );
      if (!mounted || widget.still) return;
      if (file == null) throw StateError('Panda artboard could not be decoded');
      controller = rive.RiveWidgetController(
        file,
        artboardSelector: rive.ArtboardSelector.byName('PandaCompletion'),
        stateMachineSelector: rive.StateMachineSelector.byName('Completion'),
      );
      model = controller.dataBind(rive.DataBind.byName('Panda'));
      final celebrate = model.boolean('celebrate');
      final reducedMotion = model.boolean('reducedMotion');
      if (celebrate == null || reducedMotion == null) {
        throw StateError('Panda animation inputs are missing');
      }
      celebrate.value = widget.celebrate;
      // If we first become visible with the celebration already complete,
      // start straight in its final pose instead of running the climb again.
      reducedMotion.value = widget.celebrate;
      setState(() {
        _file = file;
        _controller = controller;
        _model = model;
        _celebrate = celebrate;
      });
      // Count the intro from when the asset first reaches the widget tree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.still && !widget.celebrate) {
          widget.onIntroStarted();
        }
      });
    } catch (error) {
      debugPrint('Could not load the completion panda: $error');
      if (mounted) {
        setState(() => _loadFailed = true);
        widget.onLoadFailed();
      }
    } finally {
      _loading = false;
      if (_file == null) {
        controller?.dispose();
        model?.dispose();
        file?.dispose();
      }
    }
  }

  @override
  void didUpdateWidget(CompletionPanda oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.still && !widget.still) _loadIfNeeded();
    if (oldWidget.celebrate != widget.celebrate) {
      _celebrate?.value = widget.celebrate;
      _controller?.scheduleRepaint();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _model?.dispose();
    _file?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ExcludeSemantics(
      child: widget.still || _loadFailed || !CompletionPanda.hasNativeRuntime
          ? Image.asset(
              CompletionPanda.stillAsset,
              alignment: Alignment.bottomCenter,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            )
          : switch (_controller) {
              final controller? => rive.RiveWidget(
                controller: controller,
                fit: rive.Fit.contain,
                alignment: Alignment.bottomCenter,
              ),
              null => const SizedBox.shrink(),
            },
    ),
  );
}
