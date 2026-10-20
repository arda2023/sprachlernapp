// Generated Python import/export fixture; no production content or learner DB.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/domain/content.dart';

import '../../tool/stage_content_pack.dart';
import 'support.dart';

void main() {
  late Directory tmp;
  late File file;
  setUp(() {
    tmp = Directory.systemTemp.createTempSync('form-content-');
    file = File('${tmp.path}/content.sqlite');
    final db = sqlite3.open(file.path);
    db.execute(File('test/fixtures/form_content_v4.sql').readAsStringSync());
    db.close();
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('full Python export reads typed form identities, memberships and Story reference', () async {
    final repo = DriftContentRepository(ContentDatabase.open(file, lang: 'en'));
    addTearDown(repo.close);
    final cards = await repo.selectionCards(await repo.allCardIds());
    expect(repo.info.schemaVersion, 4);
    expect(cards, hasLength(9));
    expect(cards.map((c) => c.lexicalTargetId).toSet(), hasLength(3));
    expect(
      cards.where((c) => c.form == 'cut').map((c) => c.id).toSet(),
      hasLength(3),
    );
    expect(
      cards
          .where((c) => c.form == 'run')
          .map((c) => c.formTarget!.function)
          .toSet(),
      {'base', 'past_participle'},
    );
    final old = cards.singleWhere((c) => c.identityFunction == null);
    expect(old.form, 'cut');
    expect(old.introductionScope, 'ordinary');
    expect(old.formTarget!.function, 'base');
    expect(
      (await repo.practiceItems([old.id])).single.sentences.single.text,
      'They cut paper.',
    );
    final decks = await repo.decks();
    final base = decks.singleWhere((d) => d.slug == 'base');
    final again = decks.singleWhere((d) => d.slug == 'base-again');
    expect(
      (await repo.deckPracticeTargets(base.id)).map((t) => t.cardId),
      (await repo.deckPracticeTargets(again.id)).map((t) => t.cardId),
    );
    var memberships = 0;
    for (final d in decks.where((d) => d.practiceKind != 'ordinary')) {
      final targets = await repo.deckPracticeTargets(d.id);
      memberships += targets.length;
      expect(targets.every((t) => t.formTarget != null), isTrue);
      expect(d.cardCount, 3);
      expect(
        await repo.practiceItems(targets.map((t) => t.cardId).toList()),
        hasLength(3),
      );
    }
    expect(memberships, 12);
    final owner = decks.singleWhere((d) => d.practiceKind == 'ordinary');
    expect(await repo.deckCardIds(owner.id), hasLength(6));
    expect(await repo.deckPracticeTargets(owner.id), hasLength(1));
    final story = (await repo.storySummaries()).single;
    final doc = await repo.storyDocument(story.id);
    final sentence = doc.sentences.single;
    final token = sentence.tokens.singleWhere((t) => t.formTarget != null);
    expect(token.surface, 'run');
    expect(token.formTarget!.function, 'past_participle');
    final candidate = await repo.resolveStoryWord(
      story.id,
      sentence.id,
      token.index,
    );
    expect(candidate.card!.id, token.formTarget!.cardId);
    expect(candidate.unavailableReason, isNull);
  });

  test('dictionary card alone cannot choose among equal-surface functions',() async {
    final raw=sqlite3.open(file.path);
    final source=raw.select('SELECT sentence_id FROM story_sentences').single['sentence_id'];
    for(final table in ['sentences','sentence_tokens']) {
      final rows=raw.select(table=='sentences'?'SELECT * FROM sentences WHERE id=?':'SELECT * FROM sentence_tokens WHERE sentence_id=?',[source]);
      for(final row in rows) {
        final values=Map<String,dynamic>.from(row);
        values['id']='story-only-${values['id']}';
        if(table=='sentence_tokens') {values['sentence_id']='story-only-$source';values['form_target_id']=null;}
        raw.execute('INSERT INTO $table (${values.keys.join(',')}) VALUES (${List.filled(values.length,'?').join(',')})',values.values.toList());
      }
    }
    raw.execute('UPDATE story_sentences SET sentence_id=?',['story-only-$source']);raw.close();
    final repo=DriftContentRepository(ContentDatabase.open(file,lang:'en'));addTearDown(repo.close);
    final story=(await repo.storySummaries()).single;
    final sentence=(await repo.storyDocument(story.id)).sentences.single;
    final token=sentence.tokens.singleWhere((t)=>t.surface=='run');
    final candidate=await repo.resolveStoryWord(story.id,sentence.id,token.index);
    expect(candidate.unavailableReason,isNotNull);
    expect(candidate.token.gloss,isNotEmpty);
  });

  test('schema 4 preserves nullable legacy sense definitions', () {
    final db = sqlite3.open(file.path);
    try {
      db.execute('UPDATE senses SET definition_de=NULL');
      expect(validateContentSchema(db, lang: 'en').schemaVersion, 4);
      db.execute("UPDATE senses SET gloss_de='' ");
      expect(() => validateContentSchema(db, lang: 'en'),
          throwsA(isA<ContentUnavailable>()));
    } finally {
      db.close();
    }
  });

  const mutations = {
    'duplicate target token': "INSERT INTO sentence_tokens SELECT 'duplicate',sentence_id,idx,start_pos,end_pos,surface,lemma_id,sense_id,card_id,removed_in,replaced_by,form_target_id FROM sentence_tokens WHERE card_id IS NOT NULL LIMIT 1",
    'missing coverage': 'DELETE FROM sentence_tokens WHERE idx=0',
    'shifted coverage': 'UPDATE sentence_tokens SET idx=idx+1',
    'inactive target tokens': "UPDATE sentence_tokens SET removed_in='gone' WHERE card_id IS NOT NULL",
    'inactive dictionary candidates': "UPDATE dictionary_forms SET removed_in='gone'",
    'unnormalized stored dictionary form': "UPDATE dictionary_forms SET form_norm=upper(form_norm)",
    'second owner': "INSERT INTO deck_words SELECT 'other',lang,form_norm,deck_id,primary_card_id,position,removed_in,replaced_by FROM deck_words LIMIT 1",
    'duplicate identity': "INSERT INTO form_targets SELECT 'duplicate',lang,sense_id,form,form_norm,function,card_id,lexical_target_id,note,removed_in,replaced_by FROM form_targets LIMIT 1",
    'wrong function':
        "UPDATE decks SET practice_kind='verb_past' WHERE slug='base'",
    'wrong sense':
        "UPDATE form_targets SET sense_id='missing' WHERE function='past'",
    'no fixed sentence': 'DELETE FROM card_sentences',
    'two fixed sentences': "INSERT INTO card_sentences SELECT 'duplicate',card_id,sentence_id,position,gap_start,gap_end,accepted,removed_in,replaced_by,valid_alternatives FROM card_sentences LIMIT 1",
    'retired lexical': "UPDATE lexical_targets SET removed_in='gone'",
    'missing lexical': 'DELETE FROM card_lexical_targets',
    'wrong token': "UPDATE sentence_tokens SET form_target_id='missing' WHERE form_target_id IS NOT NULL",
    'ambiguous dictionary': "INSERT INTO dictionary_forms SELECT 'duplicate',lang,form_norm,sense_id,card_id,gloss_de,rank,removed_in,replaced_by FROM dictionary_forms LIMIT 1",
    'unknown version': 'UPDATE content_releases SET schema_version=99',
  };
  for (final m in mutations.entries) {
    test('rejects ${m.key}', () {
      final db = sqlite3.open(file.path);
      try {
        db.execute(m.value);
        expect(
          () => validateContentSchema(db, lang: 'en'),
          throwsA(isA<ContentUnavailable>()),
        );
      } finally {
        db.close();
      }
    });
  }

  test('production staging and installation preserve existing files', () async {
    final db = sqlite3.open(file.path);
    final counts = {
      for (final r in db.select(
        "SELECT name FROM sqlite_master WHERE type='table'",
      ))
        r['name'] as String: db
            .select('SELECT count(*) AS n FROM "${r['name']}"')
            .single['n'],
    };
    db.close();
    File(
      '${tmp.path}/finalization_report.json',
    ).writeAsStringSync(jsonEncode({'status': 'ok', 'sqlite_counts': counts}));
    final target = Directory('${tmp.path}/target')..createSync();
    stageContentPack(from:tmp,to:target,lang:'en',sourceLabel:'synthetic');
    expect(File('${target.path}/content.sqlite').readAsBytesSync(),file.readAsBytesSync());
    final staged=jsonDecode(File('${target.path}/content.manifest.json').readAsStringSync()) as Map<String,dynamic>;
    expect(staged['schema_version'],4);
    expect(counts,hasLength(22));
    final support = Directory('${tmp.path}/support')..createSync();
    final bytes=file.readAsBytesSync();
    final repo=await installerFor(support,db:bytes,manifest:jsonEncode(staged)).open();
    expect(repo.info.schemaVersion,4);
    expect(await repo.allCardIds(),hasLength(9));
    await repo.close();
    final installed=File('${support.path}/content/en/generations/bootstrap-${staged['sha256']}/content.sqlite');
    final before=installed.readAsBytesSync();
    for(final bad in ['hash','version','content']) {
      final manifest=Map<String,dynamic>.from(staged);
      var badBytes=bytes;
      if(bad=='hash') manifest['sha256']='0'*64;
      if(bad=='version') manifest['schema_version']=99;
      if(bad=='content') {
        final raw=sqlite3.open(file.path);
        raw.execute("UPDATE form_targets SET function='unknown'");raw.close();
        badBytes=file.readAsBytesSync();
        manifest['sha256']=sha256Of(file);manifest['size_bytes']=badBytes.length;
      }
      final pinned=await installerFor(support,db:badBytes,manifest:jsonEncode(manifest)).open();
      expect(await pinned.allCardIds(),hasLength(9));
      await pinned.close();
      await expectLater(installerFor(Directory('${tmp.path}/invalid-fresh-$bad'),db:badBytes,manifest:jsonEncode(manifest)).open(),throwsA(isA<ContentUnavailable>()));
      expect(installed.readAsBytesSync(),before);
    }
  });
}
