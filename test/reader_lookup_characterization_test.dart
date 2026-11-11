// Characterization tests for StoryReaderScreen._lookUp: which overlay a word
// tap opens and when the personal "Zum Lernen hinzufügen" action is offered.
// They pin today's behavior before the method is split up.
//
// Already covered elsewhere and not repeated here: the WordPopover's own add,
// double-tap and failure states (story_learning_flow_test), the selection
// highlight (story_highlight_selection_test), the translation bubble's
// offline/cloud rules (offline_translation_flow_test) and the exact word
// occurrence of a plain text (runtime_translation_test).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sprachapp/data/personal_learning_client.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/story_learning.dart';
import 'package:sprachapp/domain/story_learning_diagnostics.dart';
import 'package:sprachapp/models/home_models.dart';
import 'package:sprachapp/models/story_models.dart';
import 'package:sprachapp/presentation/providers/offline_translation_provider.dart';
import 'package:sprachapp/presentation/providers/personal_learning_provider.dart';
import 'package:sprachapp/presentation/providers/runtime_translation_provider.dart';
import 'package:sprachapp/presentation/providers/story_learning_providers.dart';
import 'package:sprachapp/screens/stories/story_reader_screen.dart';
import 'package:sprachapp/screens/stories/widgets/word_popover.dart';
import 'package:sprachapp/theme/app_theme.dart';
import 'package:sprachapp/widgets/personal_learning_button.dart';
import 'package:sprachapp/widgets/runtime_translation_sheet.dart';

import 'fixtures/deck_repositories.dart';
import 'fixtures/offline_translation.dart';
import 'fixtures/story_learning.dart';
import 'personal_learning_flow_test.dart'
    show WidgetConsentStore, WidgetLearningService;
import 'runtime_translation_test.dart' show FakeTranslations, tapWord;

const _text = 'Clara puts her backpack on a table in Berlin.';

StoryToken _token(
  int index,
  String surface, {
  String? pos,
  String? gloss,
  bool complete = false,
}) {
  final start = _text.indexOf(surface);
  return StoryToken(
    index: index,
    start: start,
    end: start + surface.length,
    surface: surface,
    lemmaId: 'lemma-$surface',
    lemma: surface.toLowerCase(),
    pos: pos,
    gloss: gloss,
    senseId: complete ? 'sense-$surface' : null,
    senseKey: complete ? '$surface#1' : null,
    definition: complete ? 'Eine Definition.' : null,
    contextApproved: complete,
  );
}

/// Clara: proper noun without translation. puts: no translation.
/// backpack: completely annotated. table: translated, but not completely
/// annotated. Berlin: translated proper noun.
final _sentence = StorySentence(
  id: 's1',
  text: _text,
  translation: 'Clara stellt ihren Rucksack auf einen Tisch in Berlin.',
  paragraph: 0,
  tokens: [
    _token(0, 'Clara', pos: 'PROPN'),
    _token(1, 'puts', pos: 'VERB'),
    _token(2, 'backpack', pos: 'NOUN', gloss: 'Rucksack', complete: true),
    _token(3, 'table', pos: 'NOUN', gloss: 'Tisch'),
    _token(4, 'Berlin', pos: 'PROPN', gloss: 'Berlin'),
  ],
);

final _document = StoryDocument(
  const StorySummary(
    id: 'story',
    title: 'Story',
    titleDe: 'Story',
    level: 'A2',
    minutes: 1,
  ),
  'fixture-v1',
  [_sentence],
);

const _story = Story(
  id: 'story',
  title: 'Story',
  topic: 'Alltag',
  level: 'A2',
  readingMinutes: 1,
);

/// Records the reader's calls and answers from the fields set by a test.
class _Service extends StoryLearningService {
  _Service(super.ref, this.script);
  final _Script script;

  @override
  Future<StoryLearningCandidate> candidate(
    String story,
    String sentence,
    int token,
  ) async {
    script.candidateCalls.add((story, sentence, token));
    if (script.candidateError case final error?) throw error;
    return StoryLearningCandidate(
      storyId: story,
      revision: 'fixture-v1',
      lang: 'en',
      sentence: _sentence,
      token: _sentence.tokens[token],
      card: script.card,
      retired: script.retired,
      problem: script.problem,
    );
  }

  @override
  Future<StoryAddResult> status(StoryLearningCandidate c) async {
    script.statusCalls++;
    if (script.statusError case final error?) throw error;
    return script.status;
  }

  @override
  Future<StoryAddResult> add(StoryLearningCandidate old) async {
    script.added.add(old);
    return script.addResult;
  }
}

class _Script {
  final candidateCalls = <(String, String, int)>[];
  int statusCalls = 0;
  final added = <StoryLearningCandidate>[];
  Object? candidateError, statusError;
  ContentCard? card;
  bool retired = false;
  String? problem;
  StoryAddResult status = const StoryAddResult(
    StoryAddState.available,
    message: 'Ein geprüfter Übungssatz ist vorhanden.',
  );
  StoryAddResult addResult = const StoryAddResult(
    StoryAddState.added,
    cardId: 'saved-card',
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _Script script;
  setUp(() => script = _Script());

  Future<void> pumpReader(WidgetTester tester, {Widget? reader}) async {
    final content = TestContent();
    final user = TestUser();
    addTearDown(user.close);
    final client = PersonalLearningClient(
      url: 'https://fixture.invalid',
      publicKey: 'public',
      token: () async => throw StateError('no request'),
      owner: () async => null,
      revision: () => 0,
      store: WidgetConsentStore(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          offlineDictionaryProvider.overrideWithValue(EmptyDictionary()),
          runtimeTranslationProvider.overrideWithValue(FakeTranslations()),
          storyLearningServiceProvider.overrideWith(
            (ref) => _Service(ref, script),
          ),
          personalLearningClientProvider.overrideWithValue(client),
          personalLearningServiceProvider.overrideWith(
            (_) => WidgetLearningService(
              content: content,
              user: user,
              client: client,
            ),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home:
              reader ??
              StoryReaderScreen(
                story: _story,
                document: _document,
                text: const StoryText(storyId: 'story', paragraphs: [_text]),
                initialMarks: const {},
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  WordPopover popover(WidgetTester tester) =>
      tester.widget<WordPopover>(find.byType(WordPopover));
  RuntimeTranslationSheet sheet(WidgetTester tester) => tester
      .widget<RuntimeTranslationSheet>(find.byType(RuntimeTranslationSheet));

  /// The underline of [word] in the story body (the learner's status mark).
  TextDecoration? underline(WidgetTester tester, String word) {
    final body = tester.widget<RichText>(
      find
          .byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains(_text),
          )
          .first,
    );
    TextDecoration? found;
    body.text.visitChildren((span) {
      if (span is TextSpan && span.text == word) {
        found = span.style?.decoration;
        return false;
      }
      return true;
    });
    return found;
  }

  group('word without a stored translation', () {
    testWidgets('opens the translation bubble for the exact occurrence', (
      tester,
    ) async {
      await pumpReader(tester);
      await tapWord(tester, 'puts');
      expect(find.byType(WordPopover), findsNothing);
      final bubble = sheet(tester);
      expect(bubble.lang, 'en');
      expect(bubble.text, _text);
      expect(bubble.form, 'puts');
      expect(bubble.start, _text.indexOf('puts'));
      expect(bubble.wordTap, isTrue);
      expect(bubble.senseRef, isNull);
      expect(bubble.formRef, isNull);
      // A word that is no proper noun and not completely annotated may be
      // created as a personal card.
      final target = bubble.learningTarget!;
      expect(target.lang, 'en');
      expect(target.text, _text);
      expect(target.form, 'puts');
      expect(target.start, _text.indexOf('puts'));
      expect(target.source, 'story');
      // Only the personal check resolves the candidate here.
      expect(script.candidateCalls, [('story', 's1', 1)]);
      expect(script.statusCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a proper noun gets the bubble without a learning target', (
      tester,
    ) async {
      await pumpReader(tester);
      await tapWord(tester, 'Clara');
      expect(sheet(tester).form, 'Clara');
      expect(sheet(tester).learningTarget, isNull);
    });

    testWidgets('a failing candidate still opens the bubble, without target', (
      tester,
    ) async {
      script.candidateError = StateError('broken context');
      await pumpReader(tester);
      await tapWord(tester, 'puts');
      expect(find.byType(WordPopover), findsNothing);
      expect(sheet(tester).form, 'puts');
      expect(sheet(tester).learningTarget, isNull);
      expect(tester.takeException(), isNull);
    });
  });

  group('annotated story word with a translation', () {
    testWidgets('opens the word popover with the service status', (
      tester,
    ) async {
      await pumpReader(tester);
      await tapWord(tester, 'backpack');
      expect(find.byType(RuntimeTranslationSheet), findsNothing);
      final bubble = popover(tester);
      expect(bubble.surface, 'backpack');
      expect(bubble.language, 'en');
      expect(bubble.entry.headword, 'backpack');
      expect(bubble.entry.translation, 'Rucksack');
      expect(bubble.entry.partOfSpeech, 'NOUN');
      expect(bubble.status, same(script.status));
      expect(bubble.mark, isNull);
      expect(bubble.failure, isNull);
      expect(bubble.learningAvailable, isTrue);
      expect(bubble.onReactivate, isNotNull);
      // Completely annotated: the story action, no personal card.
      expect(bubble.personalAction, isNull);
      expect(find.byType(PersonalLearningButton), findsNothing);
      expect(find.bySemanticsLabel('Zum Lernen hinzufügen'), findsOneWidget);
      expect(
        find.text('Ein geprüfter Übungssatz ist vorhanden.'),
        findsOneWidget,
      );
      // Characterization: current behavior. The same candidate is resolved
      // twice, once for the personal check and once for the status.
      expect(script.candidateCalls, [('story', 's1', 2), ('story', 's1', 2)]);
      expect(script.statusCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a successful add marks the word in the text', (tester) async {
      await pumpReader(tester);
      expect(underline(tester, 'backpack'), isNull);
      await tapWord(tester, 'backpack');
      await tester.tap(find.bySemanticsLabel('Zum Lernen hinzufügen'));
      await tester.pumpAndSettle();
      expect(script.added.single.token.surface, 'backpack');
      expect(script.added.single.storyId, 'story');
      expect(
        find.bySemanticsLabel('Hinzugefügt, in Wortliste ansehen'),
        findsOneWidget,
      );
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(WordPopover), findsNothing);
      expect(underline(tester, 'backpack'), TextDecoration.underline);
      // Other words stay unmarked.
      expect(underline(tester, 'table'), isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an add that does not save leaves the word unmarked', (
      tester,
    ) async {
      script.addResult = const StoryAddResult(
        StoryAddState.unavailable,
        message:
            'Der Story-Inhalt hat sich geändert. Bitte das Wort erneut öffnen.',
      );
      await pumpReader(tester);
      await tapWord(tester, 'backpack');
      await tester.tap(find.bySemanticsLabel('Zum Lernen hinzufügen'));
      await tester.pumpAndSettle();
      expect(script.added, hasLength(1));
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(underline(tester, 'backpack'), isNull);
    });

    testWidgets('an already added word opens marked, the text stays as is', (
      tester,
    ) async {
      script.status = const StoryAddResult(
        StoryAddState.added,
        cardId: 'saved-card',
      );
      await pumpReader(tester);
      await tapWord(tester, 'backpack');
      expect(popover(tester).mark, WordMark.active);
      expect(popover(tester).status!.state, StoryAddState.added);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      // Characterization: current behavior. Only a save made in this popover
      // adds the underline; the opening status does not.
      expect(underline(tester, 'backpack'), isNull);
    });
  });

  group('story learning service fails', () {
    testWidgets('unexpected error: popover in the error state, no learning', (
      tester,
    ) async {
      script.candidateError = StateError('broken context');
      await pumpReader(tester);
      await tapWord(tester, 'backpack');
      final bubble = popover(tester);
      expect(bubble.learningAvailable, isFalse);
      expect(bubble.failure!.step, StoryLearningStep.context);
      expect(bubble.status, isNull);
      expect(bubble.mark, isNull);
      expect(bubble.personalAction, isNull);
      expect(bubble.onReactivate, isNull);
      expect((await bubble.onAdd()).state, StoryAddState.unavailable);
      expect(
        find.text(
          'Storydaten laden nicht möglich. Bitte erneut versuchen. '
          '(STORY_LOAD_01)',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Zum Lernen hinzufügen'), findsNothing);
      expect(find.text('Rucksack'), findsOneWidget);
      expect(script.statusCalls, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a StoryLearningFailure keeps its own step', (tester) async {
      script.statusError = const StoryLearningFailure(StoryLearningStep.status);
      await pumpReader(tester);
      // "table" would get the personal action; the error popover drops it.
      await tapWord(tester, 'table');
      final bubble = popover(tester);
      expect(bubble.learningAvailable, isFalse);
      expect(bubble.failure!.step, StoryLearningStep.status);
      expect(bubble.personalAction, isNull);
      expect(find.byType(PersonalLearningButton), findsNothing);
      expect(
        find.text(
          'Lernstatus laden nicht möglich. Bitte erneut versuchen. '
          '(STORY_STATUS_01)',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('personal learning button', () {
    testWidgets('is offered for a translated, incompletely annotated word', (
      tester,
    ) async {
      await pumpReader(tester);
      await tapWord(tester, 'table');
      final action = popover(tester).personalAction! as PersonalLearningButton;
      expect(action.compact, isTrue);
      expect(action.target.lang, 'en');
      expect(action.target.text, _text);
      expect(action.target.form, 'table');
      expect(action.target.start, _text.indexOf('table'));
      expect(action.target.source, 'story');
      expect(find.byType(PersonalLearningButton), findsOneWidget);
      // The story status is still read and handed to the popover.
      expect(popover(tester).status, same(script.status));
      expect(popover(tester).learningAvailable, isTrue);
      expect(tester.takeException(), isNull);
    });

    for (final (name, arrange, word)
        in <(String, void Function(_Script), String)>[
          ('retired candidate', (s) => s.retired = true, 'table'),
          (
            'candidate with a problem',
            (s) => s.problem = 'Nicht belegt.',
            'table',
          ),
          ('candidate with a card', (s) => s.card = exactCard(), 'table'),
          ('completely annotated token', (_) {}, 'backpack'),
          ('proper noun', (_) {}, 'Berlin'),
        ]) {
      testWidgets('is not offered for a $name', (tester) async {
        arrange(script);
        await pumpReader(tester);
        await tapWord(tester, word);
        expect(popover(tester).surface, word);
        expect(popover(tester).personalAction, isNull);
        expect(find.byType(PersonalLearningButton), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('own text: always offered, story learning never asked', (
      tester,
    ) async {
      await pumpReader(
        tester,
        reader: StoryReaderScreen(
          story: _story,
          text: const StoryText(storyId: 'story', paragraphs: [_text]),
          lookup: (surface) => WordEntry(
            headword: surface.toLowerCase(),
            partOfSpeech: '',
            translation: surface == 'puts' ? '' : 'Übersetzt',
          ),
          initialMarks: const {},
        ),
      );
      await tapWord(tester, 'Berlin');
      final action = popover(tester).personalAction! as PersonalLearningButton;
      expect(action.target.form, 'Berlin');
      expect(action.target.start, _text.indexOf('Berlin'));
      expect(action.target.text, _text);
      expect(action.target.source, 'story');
      expect(popover(tester).learningAvailable, isFalse);
      expect(popover(tester).status, isNull);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tapWord(tester, 'puts');
      expect(sheet(tester).learningTarget!.form, 'puts');
      expect(script.candidateCalls, isEmpty);
      expect(script.statusCalls, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
