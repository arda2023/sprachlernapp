import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/content.dart';
import 'package:sprachapp/domain/grammar_hint.dart';
import 'package:sprachapp/domain/part_of_speech.dart';

ContentCard _card({
  String lang = 'it',
  String form = 'casa',
  String lemma = 'casa',
  String pos = 'NOUN',
  String? formKind,
  String? label,
}) => ContentCard(
  id: 'c',
  lang: lang,
  form: form,
  formNorm: form,
  lemmaId: 'l',
  lemma: lemma,
  pos: pos,
  formKind: formKind,
  formLabelDe: label,
  translationDe: 'Haus',
);

void main() {
  test('raw UD tags are shown in German, editorial labels unchanged', () {
    expect(germanPartOfSpeech('NOUN'), 'Substantiv');
    expect(germanPartOfSpeech('ADP'), 'Präposition');
    expect(germanPartOfSpeech('Verb, Vergangenheit'), 'Verb, Vergangenheit');
    expect(_card().exerciseLabel, 'Substantiv');
    expect(_card(label: 'NOUN').exerciseLabel, 'Substantiv');
    expect(_card(label: 'Substantiv, Plural').exerciseLabel, 'Substantiv, Plural');
  });

  test('a non-English card gets a word-specific hint without the answer', () {
    final hint = grammarHint(_card(), solved: false).explanation;
    expect(hint, startsWith('Gesucht ist ein Substantiv in der Einzahl.'));
    expect(hint, contains('benennt eine Person'));
    expect(hint, contains('à, è, é, ì, ò, ù'));
    expect(hint, isNot(contains('casa')));
    expect(hint, isNot(contains('Setze die gesuchte Wortform')));

    final verb = grammarHint(
      _card(form: 'piegare', lemma: 'piegare', pos: 'VERB'),
      solved: false,
    ).explanation;
    expect(verb, startsWith('Gesucht ist ein Verb in der Grundform (Infinitiv).'));

    final inflected = _card(lang: 'es', form: 'casas', lemma: 'casa');
    expect(
      grammarHint(inflected, solved: false).explanation,
      allOf(contains('nicht in der Grundform'), isNot(contains('casa'))),
    );
    expect(
      grammarHint(inflected, solved: true).explanation,
      contains('Grundform: „casa“.'),
    );
  });

  test('Portuguese keeps its required accents', () {
    final hint = grammarHint(
      _card(lang: 'pt-BR', form: 'ação', lemma: 'ação'),
      solved: false,
    ).explanation;
    expect(hint, contains('gehören zur richtigen Antwort: ã, õ, ç'));
  });
}
