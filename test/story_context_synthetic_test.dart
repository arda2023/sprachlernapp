import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/data/user/user_database.dart';
import 'package:sprachapp/data/user/drift_user_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('synthetic Unicode repeated multiword target uses selected span and persists provenance', () async {
    const text = '😀 take off, take off.';
    StoryToken word(int index, int start) => StoryToken(index:index,
      start:start,end:start+8,surface:'take off',lemmaId:'take-off',lemma:'take off',
      pos:'VERB',senseId:'depart',senseKey:'take-off#depart',gloss:'abheben',definition:'Vom Boden abheben.');
    final first=word(1,text.indexOf('take off'));
    final second=word(3,text.lastIndexOf('take off'));
    final tokens=[const StoryToken(index:0,start:0,end:2,surface:'😀'),first,
      StoryToken(index:2,start:first.end,end:first.end+1,surface:','),second,
      StoryToken(index:4,start:second.end,end:second.end+1,surface:'.')];
    final sentence=StorySentence(id:'synthetic-sentence',text:text,
      translation:'Synthetischer Offset-Prüffall, keine Inhaltsfreigabe.',paragraph:0,tokens:tokens);
    StoryLearningCandidate candidate({StoryPracticeContext? context,bool retired=false}) => StoryLearningCandidate(
      storyId:'synthetic-story',revision:'test-v1',lang:'en',sentence:sentence,
      token:second,practiceContext:context,retired:retired);
    final context=StoryPracticeContext(sentence,second);
    expect(context.validationProblem(second),isNull);
    expect(candidate().unavailableReason,contains('geprüfter Übungskontext'));
    expect(candidate(context:context,retired:true).unavailableReason,contains('nicht mehr'));
    final invalid=StoryPracticeContext(StorySentence(id:sentence.id,text:text,
      translation:sentence.translation,paragraph:0,tokens:[first,second]),second);
    expect(invalid.validationProblem(second),isNotNull);
    final c=candidate(context:context);
    expect(c.identity.key,candidate().identity.key);
    expect(c.sourceFingerprint,isNot(candidate().sourceFingerprint));
    final dir=Directory.systemTemp.createTempSync('story-unicode-');
    final file=File('${dir.path}/user.db');
    var user=DriftUserRepository(UserDatabase.file(file),lang:'en');
    final result=await user.addStoryWord(c,now:DateTime(2026,10,16));
    await user.close();
    user=DriftUserRepository(UserDatabase.file(file),lang:'en');
    try {
      final item=(await user.localPracticeItems()).single;
      expect(item.card.id,result.cardId);
      expect(item.practiceSentence.gapStart,text.lastIndexOf('take off'));
      expect(item.practiceSentence.gapEnd,second.end);
      expect(item.practiceSentence.tokens.map((t)=>t.surface),tokens.map((t)=>t.surface));
      expect(await user.reviewsFor(result.cardId!),isEmpty);
    } finally {await user.close();dir.deleteSync(recursive:true);}
  });
}
