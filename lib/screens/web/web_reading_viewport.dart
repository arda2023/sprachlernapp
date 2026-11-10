import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Editorial line lengths on desktop, while the phone reader keeps its layout.
class WebReadingViewport extends StatelessWidget {
  const WebReadingViewport({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return ColoredBox(
      color: context.appColors.nightPage,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: LayoutBuilder(
            builder: (context, constraints) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
