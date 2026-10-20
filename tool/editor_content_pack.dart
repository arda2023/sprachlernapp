// Local, read-only editor acceptance through the actual application repository.
// Explicit --stage-from/--stage-to uses the existing staging implementation.
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/content/context_revision_validation.dart';
import 'package:sprachapp/domain/content.dart';

import 'stage_content_pack.dart' as staging;

Map<String, Object?> _sentence(CardSentence s) => {
  'card_id': s.cardId,
  'sentence_id': s.sentenceId,
  'text': s.text,
  'translation_de': s.translationDe,
  'gap_start': s.gapStart,
  'gap_end': s.gapEnd,
  'valid_alternatives': s.validAlternatives,
  'tokens': [
    for (final t in s.tokens)
      {
        'start': t.start,
        'end': t.end,
        'surface': t.surface,
        'translation': t.translation,
      },
  ],
};

Future<Map<String, Object?>> inspectEditorPack(File file, String lang) async {
  final db = ContentDatabase.open(file, lang: lang);
  final repository = DriftContentRepository(db);
  final raw = sqlite3.open(file.path, mode: OpenMode.readOnly);
  try {
    final ids = (await repository.allCardIds()).toList()..sort();
    final current = <Object?>[];
    for (var i = 0; i < ids.length; i += 100) {
      final end = i + 100 < ids.length ? i + 100 : ids.length;
      for (final item in await repository.practiceItems(ids.sublist(i, end))) {
        current.add({
          'id': item.card.id,
          'form': item.card.form,
          'translation_de': item.card.translationDe,
          'sentence': _sentence(item.practiceSentence),
        });
      }
    }
    final historical = <Object?>[];
    for (final link in raw.select(
      'SELECT card_id,sentence_id FROM card_sentences ORDER BY id',
    )) {
      final s = await repository.historicalSentence(
        link['card_id'] as String,
        link['sentence_id'] as String,
      );
      if (s == null) throw StateError('Historical context is not readable');
      historical.add(_sentence(s));
    }
    final globalBindings = {
      for (final r in raw.select('SELECT form_norm,sense_id FROM cards'))
        '${r['form_norm']}\u001f${r['sense_id']}',
    };
    final sources = <Object?>[];
    final storyDisplay = <Object?>[];
    for (final summary in await repository.storySummaries()) {
      final document = await repository.storyDocument(summary.id);
      for (final sentence in document.sentences) {
        storyDisplay.add({
          'story_id': summary.id,
          'sentence_id': sentence.id,
          'text': sentence.text,
          'translation': sentence.translation,
          'tokens': [
            for (final t in sentence.tokens)
              {
                'index': t.index,
                'surface': t.surface,
                'gloss': t.gloss,
                'definition': t.definition,
                'lemma': t.lemma,
                'pos': t.pos,
              },
          ],
        });
        for (final token in sentence.tokens.where(
          (t) =>
              t.annotated &&
              t.cardId == null &&
              !globalBindings.contains(
                '${contentFormNorm(t.surface)}\u001f${t.senseId}',
              ),
        )) {
          final candidate = await repository.resolveStoryWord(
            summary.id,
            sentence.id,
            token.index,
          );
          if (candidate.card == null && candidate.validationProblem() == null) {
            sources.add(encodeStoryCandidate(candidate));
          }
        }
      }
    }
    final corrections = await repository.storyContextCorrections();
    return {
      'status': 'ok',
      'lang': lang,
      'version': repository.info.version,
      'schema_version': repository.info.schemaVersion,
      'current': current,
      'historical': historical,
      'story_display': storyDisplay,
      'story_source_snapshots': sources,
      'story_corrections': [
        for (final c in corrections)
          {
            'version': c.version,
            'previous': encodeStoryCandidate(c.previous),
            'next': encodeStoryCandidate(c.current),
          },
      ],
    };
  } finally {
    raw.close();
    await repository.close();
  }
}

Future<void> main(List<String> args) async {
  final options = <String, String>{};
  if (args.length.isOdd) {
    stderr.writeln('Expected named option/value pairs');
    exitCode = 64;
    return;
  }
  for (var i = 0; i < args.length; i += 2) {
    if (!{
      '--from',
      '--out',
      '--lang',
      '--stage-from',
      '--stage-to',
    }.contains(args[i])) {
      stderr.writeln('Unknown option');
      exitCode = 64;
      return;
    }
    options[args[i]] = args[i + 1];
  }
  try {
    final lang = options['--lang'] ?? 'en';
    if (options.containsKey('--stage-from')) {
      if (!options.containsKey('--stage-to')) {
        throw ArgumentError('Explicit staging destination required');
      }
      staging.stageContentPack(
        from: Directory(options['--stage-from']!),
        to: Directory(options['--stage-to']!),
        lang: lang,
        sourceLabel: 'local-editor-verified',
      );
      staging.verifyStagedPack(Directory(options['--stage-to']!), lang: lang);
      stdout.writeln('Staging and verify: ok');
      return;
    }
    if (!options.containsKey('--from') || !options.containsKey('--out')) {
      throw ArgumentError('--from and --out required');
    }
    final report = await inspectEditorPack(File(options['--from']!), lang);
    File(options['--out']!).writeAsStringSync(jsonEncode(report));
    stdout.writeln(
      'Reader: ok; schema ${report['schema_version']}; ${(report['current'] as List).length} active targets; ${(report['historical'] as List).length} historical contexts',
    );
  } catch (e) {
    stderr.writeln(e);
    exitCode = 1;
  }
}
