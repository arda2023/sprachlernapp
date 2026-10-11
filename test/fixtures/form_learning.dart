// Isolated synthetic schema-4 fixtures. Never accesses app support or assets.
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/story_learning.dart';

DriftContentRepository formContent(Directory dir) {
  final file = File('${dir.path}/forms.sqlite');
  final db = sqlite3.open(file.path);
  db.execute(File('test/fixtures/form_content_v4.sql').readAsStringSync());
  db.close();
  return DriftContentRepository(ContentDatabase.open(file, lang: 'en'));
}

StoryLearningCandidate formCandidate(
  ContentCard card, {
  bool local = false,
  bool approved = true,
  bool explicit = true,
  String source = 'synthetic',
}) {
  final text = switch (card.formFunction) {
    'past' => 'Yesterday they ${card.form} paper.',
    'past_participle' => 'They have ${card.form} paper.',
    _ => 'They ${card.form} paper.',
  };
  final at = text.indexOf(card.form);
  final words = RegExp(r'\w+|[^\w\s]').allMatches(text).toList();
  final index = words.indexWhere((m) => m.start == at);
  final token = StoryToken(
    index: index,
    start: at,
    end: at + card.form.length,
    surface: card.form,
    lemmaId: card.lemmaId,
    lemma: card.lemma,
    pos: card.pos,
    senseId: card.senseId,
    senseKey: card.senseKey,
    gloss: 'Test',
    definition: 'Synthetic meaning',
    cardId: local ? null : card.id,
    formTarget: local || !explicit ? null : card.formTarget,
    formFunction: local && explicit ? card.formFunction : null,
    lexicalTargetId: explicit ? card.lexicalTargetId : null,
    contextApproved: approved,
  );
  return StoryLearningCandidate(
    storyId: source,
    revision: 'fixture',
    lang: 'en',
    sentence: StorySentence(
      id: '${card.id}-context',
      text: text,
      translation: 'Synthetischer Testsatz.',
      paragraph: 0,
      tokens: [
        for (var i = 0; i < words.length; i++)
          if (i == index)
            token
          else
            StoryToken(
              index: i,
              start: words[i].start,
              end: words[i].end,
              surface: words[i].group(0)!,
              lemmaId: 'aux-$i',
              lemma: 'aux-$i',
              pos: 'PRON',
              senseId: 'aux-$i',
              senseKey: 'aux-$i',
              gloss: 'Test',
              definition: 'Synthetic',
            ),
      ],
    ),
    token: token,
    card: local ? null : card,
  );
}
