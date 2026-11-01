import 'package:flutter/cupertino.dart';

import 'premium_content_gate.dart';

/// The shared Premium lock, leaving the deck's topic symbol visible.
class DeckPremiumBadge extends StatelessWidget {
  const DeckPremiumBadge({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) => PremiumLockBadge(size: size);
}
