import 'package:flutter/cupertino.dart';
import 'package:rive/rive.dart' as rive;

import '../../../theme/app_theme.dart';
import '../../onboarding/widgets/onboarding_art.dart';

/// User supplied Rivetober flame, tinted with the app's orange.
class CompletionFlame extends StatefulWidget {
  const CompletionFlame({super.key});

  @override
  State<CompletionFlame> createState() => _CompletionFlameState();
}

class _CompletionFlameState extends State<CompletionFlame> {
  rive.FileLoader? _loader;

  @override
  void dispose() {
    _loader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = Icon(
      CupertinoIcons.flame_fill,
      size: 32,
      color: context.appColors.active,
    );
    final animate =
        OnboardingArt.riveReady && !MediaQuery.disableAnimationsOf(context);
    return SizedBox(
      width: 38,
      height: 38,
      child: ExcludeSemantics(
        child: !animate
            ? still
            : ColorFiltered(
                colorFilter: ColorFilter.mode(
                  context.appColors.active,
                  BlendMode.srcIn,
                ),
                child: rive.RiveWidgetBuilder(
                  fileLoader: _loader ??= rive.FileLoader.fromAsset(
                    'assets/rive/completion_flame.riv',
                    riveFactory: rive.Factory.flutter,
                  ),
                  builder: (context, state) => switch (state) {
                    rive.RiveLoaded() => rive.RiveWidget(
                      controller: state.controller,
                      fit: rive.Fit.contain,
                    ),
                    _ => still,
                  },
                ),
              ),
      ),
    );
  }
}
