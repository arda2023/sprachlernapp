import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';

void main() {
  test('inventory every current story token through the real resolver', () async {
    final repo = DriftContentRepository(ContentDatabase.open(
      File('assets/content/en/content.sqlite'), lang: 'en'));
    addTearDown(repo.close);
    final rows = <Map<String, Object?>>[];
    for (final story in await repo.storySummaries()) {
      final doc = await repo.storyDocument(story.id);
      for (final sentence in doc.sentences) {
        for (final token in sentence.tokens) {
          final c = await repo.resolveStoryWord(story.id, sentence.id, token.index);
          rows.add({
            'story_id': story.id, 'title': story.title, 'sentence_id': sentence.id,
            'text': sentence.text, 'translation': sentence.translation,
            'index': token.index, 'start_utf16': token.start, 'end_utf16': token.end,
            'surface': token.surface, 'sense_id': token.senseId, 'sense': token.senseKey,
            'pos': token.pos, 'function': token.function, 'binding': token.cardId,
            'resolved_card': c.card?.id, 'local_id': c.identity.localId,
            'approved': token.contextApproved, 'annotated': token.annotated,
            'retired': c.retired, 'reason': c.unavailableReason,
          });
        }
      }
    }
    const phase = String.fromEnvironment('STORY_INVENTORY', defaultValue: 'current');
    final out = File('build/story_contexts/$phase.json');
    out.parent.createSync(recursive: true);
    out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
    // ignore: avoid_print
    print('Inventory: ${rows.length} tokens; ${rows.where((r) => r['reason'] == null).length} available');
    expect(rows, isNotEmpty);
  });
}
