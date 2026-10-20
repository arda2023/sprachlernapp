import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 16, 12);
  late DriftContentRepository content;
  late StoryDocument doc;
  setUpAll(() async {
    content = DriftContentRepository(ContentDatabase.open(
      File('pipeline/out/story_single_sentence_v1/content.sqlite'), lang: 'en'));
    doc = await content.storyDocument((await content.storySummaries()).single.id);
  });
  tearDownAll(() => content.close());

  for (var sentenceIndex = 0; sentenceIndex < 6; sentenceIndex++) {
    test('all real lookups in sentence ${sentenceIndex + 1}: Add and repeat', () async {
      final dir = Directory.systemTemp.createTempSync('story-context-all-');
      final user = DriftUserRepository(UserDatabase.file(File('${dir.path}/user.db')), lang: 'en');
      addTearDown(() async { await user.close(); dir.deleteSync(recursive: true); });
      final s = doc.sentences[sentenceIndex];
      final result = <Map<String, Object?>>[];
      for (final t in s.tokens) {
        final c = await content.resolveStoryWord(doc.summary.id, s.id, t.index);
        final excluded = t.pos == 'PROPN' || !t.annotated;
        if (excluded) {
          expect(c.unavailableReason, isNotNull);
        } else {
          expect(c.unavailableReason, isNull, reason: '${t.surface}: ${c.unavailableReason}');
          final added = await user.addStoryWord(c, now: now);
          expect(added.state, StoryAddState.added);
          final repeated = await user.addStoryWord(c, now: now);
          expect(repeated.cardId, added.cardId);
          expect((await user.storyLearningStatus(c)).state, StoryAddState.added);
          expect(await user.reviewsFor(added.cardId!), isEmpty);
          result.add({'index':t.index, 'surface':t.surface, 'id':added.cardId,
            'kind':c.card != null ? 'existing' : 'reviewed-local',
            'exercise':c.card != null ? (await content.practiceItems([added.cardId!])).single.practiceSentence.text : c.practiceSentence.text});
        }
      }
      final out = File('build/story_single_sentence/add-s${sentenceIndex + 1}.json');
      out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));
    });
  }

  for (final entry in [(0, 'station'), (0, 'early'), (4, 'safely'), (5, 'Then')]) {
    test('${entry.$2}: isolated restart, exact list ID, mixed and one review', () async {
      final dir = Directory.systemTemp.createTempSync('story-context-restart-');
      final file = File('${dir.path}/user.db');
      var user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
      final s = doc.sentences[entry.$1];
      final t = s.tokens.singleWhere((t) => t.surface == entry.$2);
      final c = await content.resolveStoryWord(doc.summary.id, s.id, t.index);
      final results = await Future.wait([
        user.addStoryWord(c, now: now), user.addStoryWord(c, now: now)]);
      final id = results.first.cardId!;
      expect(results.last.cardId, id);
      expect(await user.allCardStates(), hasLength(1));
      final before = (await PracticeItemResolver.load(user, content)).practiceItems([id]);
      final saved = (await before).single.practiceSentence;
      if (c.card == null) {
        expect(saved.text, c.practiceSentence.text);
        expect(saved.translationDe, c.practiceSentence.translation);
        expect(saved.text.substring(saved.gapStart, saved.gapEnd), t.surface);
        expect(saved.validAlternatives, isEmpty);
      }
      await user.close();
      user = DriftUserRepository(UserDatabase.file(file), lang: 'en');
      final scope = ProviderContainer(overrides: [
        userRepositoryProvider.overrideWith((_) => user),
        contentRepositoryProvider.overrideWith((_) => content),
        clockProvider.overrideWithValue(() => now),
      ]);
      try {
        final words = await scope.read(wordListProvider.future);
        expect(words.map((w) => w.id), [id]);
        final resolver = await PracticeItemResolver.load(user, content);
        final queue = buildMixedQueue(targetsResolved: true, activeDeckCardIds: [],
          storyAdditions: resolver.additions, cards: resolver.cards,
          states: resolver.states, now: now, size: 10);
        expect(queue.map((q) => q.cardId), [id]);
        final item = (await resolver.practiceItems([id])).single;
        expect(item.practiceSentence.text, saved.text);
        expect(item.practiceSentence.sentenceId, saved.sentenceId);
        final pass = ReviewPass(id:'review-${entry.$2}', item:item,
          sentence:item.practiceSentence, state:resolver.states[id]!,
          mode:ReviewMode.mixed, startedAt:now);
        pass.submit(item.card.form, now);
        final review = pass.complete(now:now, appVersion:'test', deviceId:await user.deviceId())!;
        await user.recordReview(review);
        await user.recordReview(review);
        expect(await user.reviewsFor(id), hasLength(1));
        expect((await user.addStoryWord(c, now:now)).cardId, id);
      } finally {
        scope.dispose(); await user.close(); dir.deleteSync(recursive:true);
      }
    });
  }

  test('same identity from two story sentences retains the first context', () async {
    final dir = Directory.systemTemp.createTempSync('story-context-identity-');
    final user = DriftUserRepository(UserDatabase.file(File('${dir.path}/user.db')), lang:'en');
    try {
      final a = await content.resolveStoryWord(doc.summary.id,doc.sentences[1].id,0);
      final b = await content.resolveStoryWord(doc.summary.id,doc.sentences[5].id,1);
      expect(a.identity.key,b.identity.key);
      final first=await user.addStoryWord(a,now:now);
      final old=(await user.localPracticeItems()).single.practiceSentence;
      expect((await user.addStoryWord(b,now:now)).cardId,first.cardId);
      expect(await user.allCardStates(),hasLength(1));
      expect((await user.localPracticeItems()).single.practiceSentence.text,old.text);
    } finally { await user.close(); dir.deleteSync(recursive:true); }
  });
}
