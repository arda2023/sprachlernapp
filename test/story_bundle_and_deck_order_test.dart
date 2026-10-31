import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/mixed_introduction_order.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/presentation/providers/bundled_stories_provider.dart';

void main() {
  for (final lang in ['en', 'es', 'it', 'nb', 'pt-BR']) {
    test('$lang: bundled text matches every authored story', () {
      final stories = BundledStory.decode(
        File('assets/content/$lang/stories.json').readAsStringSync(), lang);
      final sources = Directory('story_library/$lang').listSync()
          .whereType<File>().where((f) => f.path.endsWith('.txt')).toList();
      expect(stories.length, sources.length);
      expect(stories.map((s) => s.story.id).toSet().length, stories.length);
      for (final item in stories) {
        final id = item.story.id.split(':').last;
        final source = File('story_library/$lang/$id.txt').readAsStringSync();
        expect(item.story.title, source.split('\n').first);
        expect(item.text.paragraphs.join('\n\n'), source.substring(source.indexOf('\n')).trim());
        expect(item.language, lang);
        expect(item.story.topic, isNotEmpty);
      }
    });
    test('$lang: introduction disperses letters, survives restart and excludes learned cards', () {
      final cards = <String, ContentCard>{};
      for (final letter in ['a', 'b', 'c', 'd']) {
        for (var i = 0; i < 20; i++) {
          final id = '$lang/$letter$i';
          cards[id] = ContentCard(id: id, lang: lang, form: '$letter$i',
            formNorm: '$letter$i', lemmaId: id, lemma: '$letter$i', pos: 'NOUN');
        }
      }
      final input = cards.keys.toList();
      final result = mixedIntroductionOrder(input, cards, 'general');
      expect(result.toSet(), input.toSet());
      expect(result, isNot(input));
      expect(result, mixedIntroductionOrder(input.reversed.toList(), cards, 'general'));
      for (var i = 1; i < 60; i++) {
        expect(cards[result[i]]!.form[0], isNot(cards[result[i - 1]]!.form[0]));
      }
      final picked = selectNewTargets(sources: [NewWordSource('general', input)],
        cards: cards, states: {}, limit: 12);
      expect(picked.map((p) => p.cardId), result.take(12));
      expect(input, cards.keys.toList());
    });
  }
  test('only general is implicit; manual choices survive reopening', () async {
    final dir = Directory.systemTemp.createTempSync('deck_defaults');
    final file = File('${dir.path}/user.db');
    DriftUserRepository open() => DriftUserRepository(UserDatabase.file(file),
      lang: 'en', defaultActiveDeckIds: () async => {'general'});
    var repo = open();
    try {
      expect(await repo.activeDeckIds(['general', 'travel']), {'general'});
      await repo.setDeckActive('travel', true, now: DateTime(2026));
      await repo.setDeckActive('general', false, now: DateTime(2026));
      await repo.close();
      repo = open();
      expect(await repo.activeDeckIds(['general', 'travel', 'work']), {'travel'});
    } finally {
      await repo.close();
      dir.deleteSync(recursive: true);
    }
  });
}
