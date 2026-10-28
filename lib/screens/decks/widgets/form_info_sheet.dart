import 'package:flutter/cupertino.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/anchored_popover.dart';
import '../../../widgets/popover_content.dart';

/// What the gap asks for: the word class and form ("Substantiv, Plural")
/// and how that form is built. It never names the answer, so it opens at
/// any time; once the word is known it also leads to the word's details.
/// Shown as the orange popover pointing at the exercise chip, like every
/// small info in the app.
class FormInfoSheet extends StatelessWidget {
  const FormInfoSheet({
    super.key,
    required this.label,
    required this.explanation,
    this.onShowWord,
    this.examples = const [],
    this.forms = const [],
  });

  final String label;
  final String explanation;
  final List<String> examples, forms;

  /// Null until the word is solved or revealed.
  final VoidCallback? onShowWord;

  /// [context] is the chip that opened it; the arrow points there.
  static Future<void> show(
    BuildContext context, {
    required String label,
    required String explanation,
    VoidCallback? onShowWord,
    List<String> examples = const [],
    List<String> forms = const [],
  }) => showAnchoredPopover<void>(
    anchorContext: context,
    color: context.appColors.popover,
    builder: (_) => FormInfoSheet(
      label: label,
      explanation: explanation,
      onShowWord: onShowWord,
      examples: examples,
      forms: forms,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final serif = AppType.editorial(
      color: popoverInk,
      size: 20,
      height: 1.3,
      letterSpacing: 0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PopoverTitle(label),
        const SizedBox(height: 8),
        Text(
          explanation,
          style: AppType.chrome(size: 16, color: popoverInk, height: 1.4),
        ),
        if (examples.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(examples.join(' · '), style: serif),
        ],
        if (forms.isNotEmpty) ...[
          const SizedBox(height: 14),
          const PopoverDivider(),
          const SizedBox(height: 12),
          Text(
            'Vorhandene Formen',
            style: AppType.meta(color: popoverInk.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 4),
          Text(forms.join(' · '), style: serif),
        ],
        if (onShowWord case final onShowWord?) ...[
          const SizedBox(height: 16),
          PopoverPillButton(
            label: 'Wort-Details ansehen',
            onPressed: () {
              Navigator.of(context).pop();
              onShowWord();
            },
          ),
        ],
      ],
    );
  }
}
