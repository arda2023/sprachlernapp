import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;

import '../../../theme/app_theme.dart';
import '../../../widgets/action_buttons.dart';

/// What the gap asks for: the word class and form ("Substantiv, Plural")
/// and how that form is built. It never names the answer, so it opens at
/// any time; once the word is known it also leads to the word's details.
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

  static Future<void> show(
    BuildContext context, {
    required String label,
    required String explanation,
    VoidCallback? onShowWord,
    List<String> examples = const [],
    List<String> forms = const [],
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    useSafeArea: true,
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
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: Semantics(
                  label: 'Schließen',
                  child: const Icon(CupertinoIcons.xmark),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Semantics(
              header: true,
              child: Text(
                label,
                style: AppType.editorial(
                  color: context.appColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              explanation,
              style: AppType.editorial(
                color: context.appColors.textPrimary,
                size: 17,
                weight: FontWeight.w400,
                height: 1.45,
                letterSpacing: 0,
              ),
            ),
            if (examples.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  examples.join(' · '),
                  style: AppType.editorial(
                    size: 20,
                    color: context.appColors.memoryLevel2,
                  ),
                ),
              ),
            if (forms.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Vorhandene Formen',
                style: AppType.chrome(color: context.appColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                forms.join(' · '),
                style: AppType.editorial(
                  size: 20,
                  color: context.appColors.memoryLevel2,
                ),
              ),
            ],
            if (onShowWord case final onShowWord?) ...[
              const SizedBox(height: 20),
              OutlineActionButton(
                label: 'Wort-Details ansehen',
                onPressed: () {
                  Navigator.of(context).pop();
                  onShowWord();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
