import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/leitner.dart';
import '../../../models/word_list_models.dart';
import '../../../presentation/providers/learning_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/popover_content.dart';
import '../../../widgets/speak_button.dart';
import 'memory_level_indicator.dart';

/// Everything about one word as the second page of the word's "Mehr"
/// bubble (user request 01.11.2026, replaces the bottom sheet): level,
/// headword with speaker, translation and word class, and three review
/// facts. The word card already shows the example sentence.
class WordDetailsPage extends ConsumerWidget {
  const WordDetailsPage({
    super.key,
    required this.initialWord,
    required this.now,
    required this.onBack,
  });

  final VocabWord initialWord;
  final DateTime now;

  /// Back to the menu page of the same bubble.
  final VoidCallback onBack;

  /// "5.11." this year, "5.11.2027" otherwise.
  String _date(DateTime date) {
    final local = date.toLocal();
    final day = '${local.day}.${local.month}.';
    return local.year == now.year ? day : '$day${local.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word =
        ref
            .watch(wordListProvider)
            .value
            ?.where((w) => w.id == initialWord.id)
            .firstOrNull ??
        initialWord;
    final entry = word.entry;
    final level = Semantics(
      label:
          'Erinnerungsstufe ${word.box} von $leitnerBoxCount: '
          '${memoryLevelTitle(word.box)}',
      excludeSemantics: true,
      child: Row(
        children: [
          MemoryLevelIndicator(
            level: word.box,
            litColor: popoverInk,
            offColor: const Color(0x59FFFFFF),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              memoryLevelTitle(word.box),
              style: PopoverText.caption(),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            MergeSemantics(
              child: CupertinoButton(
                onPressed: onBack,
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 44),
                alignment: Alignment.centerLeft,
                child: Semantics(
                  label: 'Zurück',
                  button: true,
                  excludeSemantics: true,
                  child: const Icon(
                    CupertinoIcons.chevron_left,
                    size: 20,
                    color: popoverInk,
                  ),
                ),
              ),
            ),
            Expanded(child: level),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                entry.headword,
                style: AppType.editorial(color: popoverInk, size: 24),
              ),
            ),
            SpeakButton(
              text: entry.headword,
              diameter: 36,
              label: '${entry.headword} anhören',
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            Text(
              entry.translation,
              style: AppType.editorial(
                color: popoverInk,
                size: 17,
                weight: FontWeight.w400,
                height: 1.3,
                letterSpacing: 0,
              ),
            ),
            if (entry.partOfSpeech.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(entry.partOfSpeech, style: PopoverText.caption()),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const PopoverDivider(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Fact(
              value: lastSeenLabel(word.lastSeenAt, now),
              label: word.box == 0 ? 'Hinzugefügt' : 'Zuletzt',
            ),
            _Fact(value: reviewCountLabel(word.reviewCount), label: 'Geübt'),
            _Fact(
              value: word.dueAt == null ? 'Offen' : _date(word.dueAt!),
              label: 'Nächste',
            ),
          ],
        ),
      ],
    );
  }
}

/// One review fact: the value large, what it is small below.
class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppType.chrome(
              size: 17,
              weight: FontWeight.w800,
              color: popoverInk,
              tabular: true,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: PopoverText.caption()),
        ],
      ),
    ),
  );
}
