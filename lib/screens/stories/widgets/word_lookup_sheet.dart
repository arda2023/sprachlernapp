import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show showModalBottomSheet;

import '../../../models/story_models.dart';
import '../../../theme/app_theme.dart';

/// Dictionary sheet for a tapped word: headword (serif, it is content),
/// word class and translation, and one neutral action.
class WordLookupSheet extends StatefulWidget {
  const WordLookupSheet({
    super.key,
    required this.surface,
    required this.entry,
    required this.mark,
    required this.onAdd,
  });

  /// The word as it appears in the text, e.g. 'arrived'.
  final String surface;
  final WordEntry entry;
  final WordMark? mark;
  final VoidCallback onAdd;

  static Future<void> show(
    BuildContext context, {
    required String surface,
    required WordEntry entry,
    required WordMark? mark,
    required VoidCallback onAdd,
  }) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => WordLookupSheet(
      surface: surface,
      entry: entry,
      mark: mark,
      onAdd: onAdd,
    ),
  );

  @override
  State<WordLookupSheet> createState() => _WordLookupSheetState();
}

class _WordLookupSheetState extends State<WordLookupSheet> {
  late WordMark? _mark = widget.mark;

  void _add() {
    widget.onAdd();
    setState(() => _mark = WordMark.active);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final ink = switch (_mark) {
      WordMark.active => AppColors.active,
      WordMark.mastered => AppColors.mastered,
      null => null,
    };
    final inflected = widget.surface.toLowerCase() != entry.headword;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: entry.headword,
                    style: AppType.editorial(size: 28).copyWith(
                      decoration: ink == null ? null : TextDecoration.underline,
                      decorationColor: ink,
                      decorationThickness: 2,
                    ),
                  ),
                  const TextSpan(text: '   '),
                  TextSpan(text: entry.partOfSpeech, style: AppType.meta()),
                ],
              ),
            ),
            if (inflected) ...[
              const SizedBox(height: 4),
              Text('im Text: ${widget.surface}', style: AppType.meta()),
            ],
            const SizedBox(height: 20),
            const ColoredBox(
              color: AppColors.hairline,
              child: SizedBox(height: 1),
            ),
            const SizedBox(height: 16),
            Text('Deutsch', style: AppType.meta()),
            const SizedBox(height: 4),
            Text(
              entry.translation,
              style: AppType.editorial(
                size: 22,
                weight: FontWeight.w400,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 28),
            AddToLearningButton(
              mark: _mark,
              onPressed: _mark == null ? _add : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Neutral Chrome Rule: prominent through size and placement, never through
/// a status ink. Night Page fill sits inset on the Raised Ink sheet.
class AddToLearningButton extends StatelessWidget {
  const AddToLearningButton({
    super.key,
    required this.mark,
    required this.onPressed,
  });

  final WordMark? mark;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (mark) {
      null => ('Zum Lernen hinzufügen', CupertinoIcons.plus),
      WordMark.active => ('Wird gelernt', CupertinoIcons.checkmark),
      WordMark.mastered => ('Bereits gemeistert', CupertinoIcons.checkmark),
    };
    final color = onPressed == null
        ? AppColors.textMuted
        : AppColors.textPrimary;

    return MergeSemantics(
      child: CupertinoButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        pressedOpacity: 0.7,
        minimumSize: const Size(44, 52),
        child: Semantics(
          label: label,
          enabled: onPressed != null,
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.nightPage,
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppType.chrome(
                      weight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
