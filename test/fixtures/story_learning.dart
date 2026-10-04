import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/story_learning.dart';

StoryLearningCandidate storyCandidate({String surface='backpack',String sense='sense-bag',String story='story',ContentCard? card,bool approved=true,bool retired=false,String? text,int? start}) {
 final body=text ?? 'She puts her $surface on a table.';
 final at=start ?? body.indexOf(surface);
 final token=StoryToken(index:3,start:at,end:at+surface.length,surface:surface,lemmaId:'lemma-bag',lemma:'backpack',pos:'NOUN',senseId:sense,senseKey:'backpack#bag',gloss:'Rucksack',definition:'Eine auf dem Rücken getragene Tasche.',contextApproved:approved);
 return StoryLearningCandidate(storyId:story,revision:'fixture-v1',lang:'en',sentence:StorySentence(id:'sentence',text:body,translation:'Sie stellt ihren Rucksack auf einen Tisch.',paragraph:0,tokens:[token]),token:token,card:card,retired:retired);
}
ContentCard exactCard({String id='curated',String sense='sense-bag'}) => ContentCard(id:id,lang:'en',form:'backpack',formNorm:'backpack',lemmaId:'lemma-bag',lemma:'backpack',pos:'NOUN',senseId:sense,senseKey:'backpack#bag',translationDe:'Rucksack');
