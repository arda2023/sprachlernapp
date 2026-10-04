import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;

import '../theme/app_theme.dart';

/// Original sentence and its pre-generated German translation.
class SentenceTranslationSheet extends StatelessWidget {
  const SentenceTranslationSheet({
    super.key,
    required this.original,
    required this.translation,
  });

  final String original;
  final String translation;

  static Future<void> show(
    BuildContext context, {
    required String original,
    required String translation,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        SentenceTranslationSheet(original: original, translation: translation),
  );

  @override
  Widget build(BuildContext context) {
    final body = AppType.editorial(
      color: context.appColors.textPrimary,
      size: 20,
      weight: FontWeight.w400,
      height: 1.4,
      letterSpacing: 0,
    );
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Satz',
              style: AppType.meta(color: context.appColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(original.trim(), style: body),
            const SizedBox(height: 20),
            ColoredBox(
              color: context.appColors.hairline,
              child: SizedBox(height: 1),
            ),
            const SizedBox(height: 16),
            Text(
              'Deutsch',
              style: AppType.meta(color: context.appColors.textMuted),
            ),
            const SizedBox(height: 4),
            Text(translation, style: body),
          ],
        ),
      ),
    );
  }
}
