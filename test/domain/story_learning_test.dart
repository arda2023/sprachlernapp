import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/domain/srs_state.dart';
import '../fixtures/story_learning.dart';
void main() {
 test('semantic identity folds case/Unicode, never different meanings/languages',(){
  expect(storyCandidate(surface:'Backpack').identity.localId,storyCandidate().identity.localId);
  expect(storyCandidate(sense:'other').identity.localId,isNot(storyCandidate().identity.localId));
  expect(const LearningIdentity('de','backpack','sense-bag').localId,isNot(storyCandidate().identity.localId));
  expect(contentFormNorm('CAFE\u0301'),contentFormNorm('café'));
 });
 test('exact repeated Unicode target and context evidence required',(){
  final c=storyCandidate(text:'🎒 backpack and backpack.',start:16);
  expect(c.sentence.text.substring(c.token.start,c.token.end),'backpack');
  expect(c.unavailableReason,isNull);
  expect(storyCandidate(approved:false).unavailableReason,isNotNull);
  expect(storyCandidate(card:exactCard(sense:'wrong')).unavailableReason,isNotNull);
 });
 test('explicit story choices reserve actual queue slots ahead of 4:1; box zero remains eligible',(){
  final now=DateTime(2026,10,4);final fn=ContentCard(id:'fn',lang:'en',form:'and',formNorm:'and',lemmaId:'and',lemma:'and',pos:'CCONJ');
  final lexical=exactCard(id:'lex');
  final states={'fn':UserCardState(cardId:'fn',box:0,dueAt:null)};
  final q=buildMixedQueue(activeDeckCardIds:['lex'],cards:{'fn':fn,'lex':lexical},states:states,now:now,size:1,storyAdditions:{'fn':now});
  expect(q.single.cardId,'fn');
  final count=deriveVocabBreakdown(activeDeckCardIds:{},cards:states,knownCardIds:{'fn'},now:now,explicitStoryIds:{'fn'});
  expect(count.unseen,1);
  expect(deriveVocabBreakdown(activeDeckCardIds:{},cards:states,knownCardIds:{},now:now,explicitStoryIds:{'fn'}).total,0);
 });
}
