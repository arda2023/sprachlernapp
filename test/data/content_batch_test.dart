import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/domain/content.dart';

class QueryCounts extends QueryInterceptor {
  final counts = <String, int>{}, micros = <String, int>{};
  int maxParameters = 0;
  void reset() {
    counts.clear();
    micros.clear();
    maxParameters = 0;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor e,
    String s,
    List<Object?> a,
  ) async {
    final kind = s.contains('FROM sentence_tokens')
        ? 'tokens'
        : s.contains('FROM form_targets')
        ? 'forms'
        : s.contains('FROM card_sentences')
        ? 'sentences'
        : 'other';
    counts.update(kind, (v) => v + 1, ifAbsent: () => 1);
    if (a.length > maxParameters) maxParameters = a.length;
    final sw = Stopwatch()..start();
    try {
      return await e.runSelect(s, a);
    } finally {
      micros.update(
        kind,
        (v) => v + sw.elapsedMicroseconds,
        ifAbsent: () => sw.elapsedMicroseconds,
      );
    }
  }
}

Object? form(FormTarget? f) => f == null
    ? null
    : [f.id, f.cardId, f.senseId, f.form, f.function, f.lexicalTargetId];
Object card(ContentCard c) => [
  c.id,
  c.lang,
  c.form,
  c.formNorm,
  c.lemmaId,
  c.lemma,
  c.pos,
  c.identityFunction,
  c.introductionScope,
  c.lexicalTargetId,
  c.senseKey,
  c.senseId,
  c.formKind,
  c.formLabelDe,
  c.translationDe,
  c.cefrBand,
  form(c.formTarget),
  if (c.learning case final l?)
    [l.groupId, l.primaryCardId, l.topic, l.related, l.note],
];
Object sentence(CardSentence s) => [
  s.cardId,
  s.sentenceId,
  s.position,
  s.text,
  s.translationDe,
  s.gapStart,
  s.gapEnd,
  s.validAlternatives,
  [
    for (final t in s.tokens) [t.start, t.end, t.surface, t.translation],
  ],
];
Object item(PracticeItem i) => [
  card(i.card),
  i.sentences.map(sentence).toList(),
  i.otherFormsOfLemma.toList()..sort(),
];
String digest(Object value) =>
    sha256.convert(utf8.encode(jsonEncode(value))).toString();
Future<DriftContentRepository> measured(
  File file,
  ContentInfo info,
  QueryCounts counter,
) async => DriftContentRepository(
  ContentDatabase.forTesting(
    NativeDatabase.createInBackground(
      file,
      enableMigrations: false,
      setup: (raw) => raw.execute('PRAGMA query_only=ON'),
    ).interceptWith(counter),
    info,
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final lang in ['en', 'pt-BR']) {
    test('bounded form and token queries, ordering and duplicate input $lang', () async {
      final dir = Directory.systemTemp.createTempSync('batch-test-');
      final file = File('${dir.path}/fixture.sqlite');
      final raw = sql.sqlite3.open(file.path);
      raw.execute(File('test/fixtures/form_content_v4.sql').readAsStringSync());
      final source = Map<String, Object?>.from(
        raw.select('SELECT * FROM cards LIMIT 1').single,
      );
      final sourceId = source['id'];
      final target = Map<String, Object?>.from(
        raw.select('SELECT * FROM form_targets WHERE card_id=?', [
          sourceId,
        ]).single,
      );
      final link = Map<String, Object?>.from(
        raw.select('SELECT * FROM card_sentences WHERE card_id=?', [
          sourceId,
        ]).single,
      );
      final oldSentence = link['sentence_id'];
      final sent = Map<String, Object?>.from(
        raw.select('SELECT * FROM sentences WHERE id=?', [oldSentence]).single,
      );
      final tokens = raw
          .select('SELECT * FROM sentence_tokens WHERE sentence_id=?', [
            oldSentence,
          ])
          .map((r) => Map<String, Object?>.from(r))
          .toList();
      void insert(String table, Map<String, Object?> value) => raw.execute(
        'INSERT INTO $table (${value.keys.join(',')}) VALUES (${List.filled(value.length, '?').join(',')})',
        value.values.toList(),
      );
      for (var i = 0; i < 805; i++) {
        insert('cards', {...source, 'id': 'batch-$i', 'lang': lang});
        insert('form_targets', {
          ...target,
          'id': 'target-$i',
          'card_id': 'batch-$i',
        });
        insert('sentences', {...sent, 'id': 'sentence-$i', 'lang': lang});
        insert('card_sentences', {
          ...link,
          'id': 'link-$i',
          'card_id': 'batch-$i',
          'sentence_id': 'sentence-$i',
        });
        for (var j = 0; j < tokens.length; j++) {
          insert('sentence_tokens', {
            ...tokens[j],
            'id': 'token-$i-$j',
            'sentence_id': 'sentence-$i',
          });
        }
      }
      raw.close();
      final counter = QueryCounts();
      final repo = await measured(
        file,
        ContentInfo(
          lang: lang,
          version: 'test',
          schemaVersion: 4,
          notes: 'synthetic',
        ),
        counter,
      );
      addTearDown(() async {
        await repo.close();
        dir.deleteSync(recursive: true);
      });
      final ids = [for (var i = 804; i >= 0; i--) 'batch-$i'];
      final cards = await repo.selectionCards([...ids, ids.first, 'absent']);
      expect(cards.map((c) => c.id), ids);
      expect(cards.every((c) => c.lang == lang), isTrue);
      expect(cards.every((c) => c.formTarget!.cardId == c.id), isTrue);
      expect(counter.counts['forms'], 3);
      expect(counter.maxParameters, lessThanOrEqualTo(999));
      counter.reset();
      final all = await repo.practiceItems(ids);
      expect(all.map((i) => i.card.id), ids);
      expect(counter.counts['tokens'], 3);
      expect(counter.counts['forms'], 3);
      expect(counter.counts['sentences'], 3);
      expect(counter.maxParameters, lessThanOrEqualTo(999));
      // Full objects agree with separately requested items, including offsets/glosses.
      for (final index in [0, 399, 400, 799, 804]) {
        expect(
          item(all[index]),
          item((await repo.practiceItems([ids[index]])).single),
        );
      }
      await expectLater(repo.practiceItems(['absent']), throwsArgumentError);
    });
  }
  test(
    'real pack query measurement',
    () async {
      final dir = Directory.systemTemp.createTempSync('batch-real-');
      final file = File('assets/content/en/content.sqlite')
          .copySync('${dir.path}/pack.sqlite');
      final checked = ContentDatabase.open(file, lang: 'en');
      final info = checked.info;
      await checked.close();
      final count = QueryCounts();
      final repo = await measured(file, info, count);
      addTearDown(() async {
        await repo.close();
        dir.deleteSync(recursive: true);
      });
      final results = <String, Object>{};
      Future<T> phase<T>(String name, Future<T> Function() action) async {
        count.reset();
        final sw = Stopwatch()..start();
        final value = await action();
        debugPrint(
          '$name ms=${sw.elapsedMilliseconds} queries=${count.counts} sql_us=${count.micros} parameters=${count.maxParameters}',
        );
        return value;
      }

      final ids = (await repo.allCardIds()).toList();
      final cards = await phase('selection', () => repo.selectionCards(ids));
      results['cards'] = cards.map(card).toList();
      final catalog = await phase('catalog', () => PracticeCatalog.load(repo));
      results['decks'] = [
        for (final d in catalog.decks)
          [
            d.id,
            d.slug,
            d.titleDe,
            d.descriptionDe,
            d.cefrBand,
            d.practiceKind,
            d.cardCount,
          ],
      ];
      results['targets'] = {
        for (final e in catalog.targets.entries)
          e.key: [
            for (final t in e.value) [t.cardId, form(t.formTarget)],
          ],
      };
      final items = await phase('all-practice', () => repo.practiceItems(ids));
      results['items'] = items.map(item).toList();
      final raw = sql.sqlite3.open(file.path, mode: sql.OpenMode.readOnly);
      final refs = raw.select(
        'SELECT card_id,sentence_id FROM card_sentences ORDER BY card_id,sentence_id',
      );
      raw.close();
      results['history'] = await phase(
        'all-history',
        () async => [
          for (final r in refs)
            sentence(
              (await repo.historicalSentence(
                r['card_id'] as String,
                r['sentence_id'] as String,
              ))!,
            ),
        ],
      );
      final fingerprints = {
        for (final e in results.entries) e.key: digest(e.value),
      };
      debugPrint(
        'RESULTS cards=${cards.length} decks=${catalog.decks.length} items=${items.length} history=${refs.length} fingerprints=$fingerprints',
      );
      const output = String.fromEnvironment('BATCH_OUTPUT');
      if (output.isNotEmpty) {
        File(output).writeAsStringSync(jsonEncode(fingerprints));
      }
    },
    skip: !const bool.fromEnvironment('BATCH_MEASURE'),
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
