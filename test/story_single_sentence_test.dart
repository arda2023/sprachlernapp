import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprachapp/data/content/content_database.dart';
import 'package:sprachapp/data/content/drift_content_repository.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';
import 'package:sprachapp/data/learning/practice_item_resolver.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/domain/review_pass.dart';
import 'package:sprachapp/domain/srs_state.dart';
import 'package:sprachapp/presentation/providers/database_providers.dart';
import 'package:sprachapp/presentation/providers/learning_providers.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026,10,16,12);
  late DriftContentRepository oldPack, newPack;
  late StoryDocument doc;
  setUpAll(() async {
    oldPack = DriftContentRepository(ContentDatabase.open(File('pipeline/out/story_contexts_v1/content.sqlite'),lang:'en'));
    newPack = DriftContentRepository(ContentDatabase.open(File('pipeline/out/story_single_sentence_v1/content.sqlite'),lang:'en'));
    doc = await newPack.storyDocument((await newPack.storySummaries()).single.id);
  });
  tearDownAll(() async {await oldPack.close();await newPack.close();});
  Future<StoryLearningCandidate> candidate(DriftContentRepository pack,int sentence,int token) =>
    pack.resolveStoryWord(doc.summary.id,doc.sentences[sentence].id,token);

  test('all 14 approved targets use exact original and translation; six matching contexts unchanged', () async {
    final dir=Directory.systemTemp.createTempSync('single-all-');
    final user=DriftUserRepository(UserDatabase.file(File('${dir.path}/user.db')),lang:'en');
    addTearDown(() async {await user.close();dir.deleteSync(recursive:true);});
    const targets=[(0,1),(0,5),(1,0),(1,1),(2,2),(2,3),(2,5),(4,1),(4,3),(4,4),(4,6),(5,0),(5,1),(5,2)];
    var changed=0;
    for(final (s,t) in targets) {
      final before=await candidate(oldPack,s,t), after=await candidate(newPack,s,t);
      expect(after.unavailableReason,isNull);
      expect(after.card,isNull);
      expect(after.identity.key,before.identity.key);
      expect(after.practiceSentence.text,doc.sentences[s].text);
      expect(after.practiceSentence.translation,doc.sentences[s].translation);
      expect(after.practiceToken.start,after.token.start);
      expect(after.practiceToken.end,after.token.end);
      expect(after.practiceSentence.text.substring(after.practiceToken.start,after.practiceToken.end),after.token.surface);
      if(before.practiceContext!.fingerprint!=after.practiceContext!.fingerprint) changed++;
      expect((await user.addStoryWord(after,now:now)).state,StoryAddState.added);
    }
    expect(changed,8);
    expect(await user.allCardStates(),hasLength(13)); // She/she reuse.
    expect(await newPack.storyContextCorrections(),hasLength(8));
    for(final (s,t) in [(0,4),(1,3),(5,5)]) {
      final before=await candidate(oldPack,s,t),after=await candidate(newPack,s,t);
      expect(after.card!.id,before.card!.id);
      expect((await user.addStoryWord(after,now:now)).cardId,after.card!.id);
    }
    for(final (s,t) in [(0,0),(4,0),(5,9)]) {
      expect((await candidate(newPack,s,t)).unavailableReason,isNotNull);
    }
  });

  for(final (s,t,word) in [(4,3,'safely'),(5,0,'Then')]) {
    test('$word: update existing card, preserve all state/history and frozen pass; restart/idempotence', () async {
      final dir=Directory.systemTemp.createTempSync('single-existing-');
      final file=File('${dir.path}/user.db');
      var db=UserDatabase.file(file);
      var user=DriftUserRepository(db,lang:'en');
      try {
        final before=await candidate(oldPack,s,t),after=await candidate(newPack,s,t);
        final id=(await user.addStoryWord(before,now:now)).cardId!;
        final frozen=await PracticeItemResolver.load(user,oldPack);
        final item=(await frozen.practiceItems([id])).single;
        final oldSentence=item.practiceSentence;
        final pass=ReviewPass(id:'old-$word',item:item,sentence:oldSentence,
          state:frozen.states[id],mode:ReviewMode.mixed,startedAt:now);
        pass.submit(word,now);
        await user.recordReview(pass.complete(now:now,appVersion:'test',deviceId:await user.deviceId())!);
        await user.setCardFlags(id,favorite:true,note:'Unverändert 😀',inPlaylist:true,disabled:word=='Then');
        final stateBefore=Map<String,Object?>.from((await db.customSelect('SELECT * FROM user_cards').getSingle()).data)..remove('primary_context_id');
        final reviewsBefore=(await db.customSelect('SELECT * FROM review_log').get()).map((r)=>r.data).toList();
        final contextsBefore=(await db.select(db.cardContexts).get()).single;
        final running=ReviewPass(id:'running-$word',item:item,sentence:oldSentence,
          state:(await user.allCardStates())[id],mode:ReviewMode.early,startedAt:now);
        final scope=ProviderContainer(overrides:[
          userRepositoryProvider.overrideWith((_)=>user),contentRepositoryProvider.overrideWith((_)=>newPack),
          clockProvider.overrideWithValue(()=>now),
        ]);
        final words=await scope.read(wordListProvider.future);
        expect(words.map((w)=>w.id),contains(id));
        expect(words.singleWhere((w)=>w.id==id).sentence,after.sentence.text);
        expect(words.singleWhere((w)=>w.id==id).sentenceTranslation,after.sentence.translation);
        final updated=await scope.read(practiceResolverProvider.future);
        expect(updated.contentError,isNull);
        final active=(await updated.practiceItems([id])).single.practiceSentence;
        scope.dispose();
        expect(active.text,after.sentence.text);
        expect(active.translationDe,after.sentence.translation);
        expect(active.sentenceId,isNot(oldSentence.sentenceId));
        expect(active.text.substring(active.gapStart,active.gapEnd),word);
        expect((await frozen.practiceItems([id])).single.practiceSentence.text,oldSentence.text);
        expect(running.sentence.sentenceId,oldSentence.sentenceId);
        expect((await updated.historicalSentence(id,oldSentence.sentenceId))!.text,oldSentence.text);
        expect((await db.select(db.cardContexts).get()).firstWhere((c)=>c.id==oldSentence.sentenceId),contextsBefore);
        expect((await db.customSelect('SELECT * FROM review_log').get()).map((r)=>r.data).toList(),reviewsBefore);
        final stateAfter=Map<String,Object?>.from((await db.customSelect('SELECT * FROM user_cards').getSingle()).data)..remove('primary_context_id');
        expect(stateAfter,stateBefore);
        await Future.wait([user.applyStoryContextCorrections(await newPack.storyContextCorrections()),user.applyStoryContextCorrections(await newPack.storyContextCorrections())]);
        expect(await db.select(db.cardContexts).get(),hasLength(2));
        running.submit(word,now);
        final runningReview=running.complete(now:now,appVersion:'test',deviceId:await user.deviceId())!;
        expect(runningReview.sentenceId,oldSentence.sentenceId);
        await user.recordReview(runningReview);
        await user.close();
        db=UserDatabase.file(file);user=DriftUserRepository(db,lang:'en');
        final restarted=await PracticeItemResolver.load(user,newPack);
        expect((await restarted.practiceItems([id])).single.practiceSentence.sentenceId,active.sentenceId);
        expect((await restarted.historicalSentence(id,oldSentence.sentenceId))!.text,oldSentence.text);
        final expected=word=='Then'?StoryAddState.disabled:StoryAddState.added;
        for(final r in await Future.wait([user.addStoryWord(after,now:now),user.addStoryWord(after,now:now)])) {
          expect(r.cardId,id);expect(r.state,expected);
        }
        expect(await user.allCardStates(),hasLength(1));
        expect(await db.select(db.cardContexts).get(),hasLength(2));
        expect(await user.reviewsFor(id),hasLength(2));
      } finally {await user.close();dir.deleteSync(recursive:true);}
    });
  }

  test('same identity with different origin or custom context is never overwritten', () async {
    final corrections=await newPack.storyContextCorrections();
    final old=await candidate(oldPack,4,3);
    for(final custom in [false,true]) {
      final dir=Directory.systemTemp.createTempSync('single-no-match-');
      final db=UserDatabase.file(File('${dir.path}/user.db'));
      final user=DriftUserRepository(db,lang:'en');
      try {
        final context=old.practiceContext!;
        final changed=StoryPracticeContext(StorySentence(id:context.sentence.id,
          text:context.sentence.text,translation:'Individuelle Übersetzung.',paragraph:0,
          tokens:context.sentence.tokens),context.token);
        final other=StoryLearningCandidate(storyId:custom?old.storyId:'other-story',
          revision:old.revision,lang:old.lang,sentence:old.sentence,token:old.token,
          practiceContext:custom?changed:context,otherForms:old.otherForms);
        await user.addStoryWord(other,now:now);
        final saved=(await user.localPracticeItems()).single.practiceSentence;
        await user.applyStoryContextCorrections(corrections);
        expect((await user.localPracticeItems()).single.practiceSentence.sentenceId,saved.sentenceId);
        expect(await db.select(db.cardContexts).get(),hasLength(1));
      } finally {await user.close();dir.deleteSync(recursive:true);}
    }
  });
}
