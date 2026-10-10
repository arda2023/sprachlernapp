// Read-only report; never opens learner databases. Windows PowerShell / macOS:
// dart run tool/report_learning_groups.dart
import 'dart:convert';
import 'dart:io';

import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/domain/learning_groups.dart';
import 'package:sprachapp/domain/new_card_selection.dart';

Future<void> main() async {
  final result = <String, Object>{};
  for (final entry in {
    'before': 'reisen_batch_5_v1',
    'after': 'learning_groups_v1',
  }.entries) {
    final repo = DriftContentRepository(
      ContentDatabase.open(
        File('pipeline/out/${entry.value}/content.sqlite'),
        lang: 'en',
      ),
    );
    try {
      final cards = {
        for (final c in await repo.selectionCards(await repo.allCardIds()))
          c.id: c,
      };
      final decks = await repo.decks();
      final ids = {for (final d in decks) d.slug: await repo.deckCardIds(d.id)};
      ids['mixed'] = [for (final d in decks) ...ids[d.slug]!];
      final reports = <String, Object>{};
      for (final entry in ids.entries) {
        final projected = LearningGroups(cards, {}).project(entry.value);
        final trace = <Map<String, Object>>[];
        selectNewCards(
          candidates: [for (final id in projected) cards[id]!],
          knownLemmas: {},
          limit: 30,
          onSelected: (card, gap) => trace.add({
            'position': trace.length + 1,
            'card_id': card.id,
            'form': card.form,
            'group': card.learningGroup,
            'topic': card.learning?.topic ?? 'legacy',
            'reason': card.learning == null
                ? 'Legacy: Eingangsfolge, neues Lemma, Inhalts-/Funktionsquote'
                : 'Gruppenkopf; neues Lemma; ${isContentWord(card) ? 'Inhaltswort' : 'Funktionswort'}; Mindestabstand $gap',
          }),
        );
        reports[entry.key] = {
          'raw_words': entry.value.length,
          'learning_targets': projected.length,
          'first30': trace,
        };
      }
      result[entry.key] = reports;
    } finally {
      await repo.close();
    }
  }
  final file = File('build/learning_groups_checks/selection.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(result)}\n',
  );
  stdout.writeln(file.readAsStringSync());
}
