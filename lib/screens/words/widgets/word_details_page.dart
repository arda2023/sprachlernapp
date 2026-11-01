import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/leitner.dart';
import '../../../models/word_list_models.dart';
import '../../../presentation/providers/database_providers.dart';
import '../../../presentation/providers/learning_providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/popover_content.dart';
import '../../../widgets/speak_button.dart';
import 'memory_level_indicator.dart';

/// Everything about one word as the second page of the word's "Mehr"
/// bubble (user request 01.11.2026, replaces the bottom sheet): level,
/// headword with speaker, translation and word class, three review facts,
/// the example sentence with its translation, and the learner's note. No
/// heading and no field labels; the content says what it is.
class WordDetailsPage extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<WordDetailsPage> createState() => _WordDetailsPageState();
}

class _WordDetailsPageState extends ConsumerState<WordDetailsPage> {
  late final void Function() _releaseContent;
  late final _note = TextEditingController(text: widget.initialWord.note);
  Future<void> _pending = Future.value();
  bool _noteError = false;

  @override
  void initState() {
    super.initState();
    _releaseContent = contentTransitionGate.acquire();
  }

  void _saveNote(String text) {
    final actions = ref.read(wordActionsProvider);
    _pending = _pending.then((_) async {
      try {
        await actions.save(widget.initialWord.id, note: text);
        if (mounted) setState(() => _noteError = false);
      } catch (_) {
        if (mounted) setState(() => _noteError = true);
      }
    });
  }

  @override
  void dispose() {
    _pending.whenComplete(_releaseContent);
    _note.dispose();
    super.dispose();
  }

  /// "5.11." this year, "5.11.2027" otherwise.
  String _date(DateTime date) {
    final local = date.toLocal();
    final day = '${local.day}.${local.month}.';
    return local.year == widget.now.year ? day : '$day${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final word =
        ref
            .watch(wordListProvider)
            .value
            ?.where((w) => w.id == widget.initialWord.id)
            .firstOrNull ??
        widget.initialWord;
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
                onPressed: widget.onBack,
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
                style: AppType.editorial(color: popoverInk, size: 26),
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
                size: 18,
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
              value: lastSeenLabel(word.lastSeenAt, widget.now),
              label: word.box == 0 ? 'Hinzugefügt' : 'Zuletzt',
            ),
            _Fact(value: reviewCountLabel(word.reviewCount), label: 'Geübt'),
            _Fact(
              value: word.dueAt == null ? 'Offen' : _date(word.dueAt!),
              label: 'Nächste',
            ),
          ],
        ),
        const SizedBox(height: 12),
        const PopoverDivider(),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                word.sentence,
                style: AppType.editorial(
                  color: popoverInk,
                  size: 17,
                  weight: FontWeight.w400,
                  height: 1.4,
                  letterSpacing: 0,
                ),
              ),
            ),
            SpeakButton(
              text: word.sentence,
              diameter: 32,
              label: 'Satz anhören: ${word.sentence}',
            ),
          ],
        ),
        if (word.sentenceTranslation.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(word.sentenceTranslation, style: PopoverText.small()),
        ],
        const SizedBox(height: 14),
        CupertinoTextField(
          controller: _note,
          onChanged: _saveNote,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          placeholder: 'Notiz hinzufügen',
          placeholderStyle: PopoverText.small(),
          style: PopoverText.small(),
          cursorColor: popoverInk,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          prefix: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(CupertinoIcons.pencil, size: 16, color: popoverInk),
          ),
          decoration: BoxDecoration(
            color: const Color(0x29FFFFFF),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        if (_noteError)
          CupertinoButton(
            onPressed: () => _saveNote(_note.text),
            padding: const EdgeInsets.only(top: 8),
            minimumSize: const Size(44, 44),
            alignment: Alignment.centerLeft,
            child: Text(
              'Notiz nicht gespeichert. Erneut versuchen',
              style: PopoverText.small(),
            ),
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
              size: 16,
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
