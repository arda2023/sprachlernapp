// Local answer check (docs/srs.md, Prüfreihenfolge; PRODUCT.md typo rule).

import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/answer_check.dart';

void main() {
  AnswerVerdict check(
    String input,
    String target, {
    List<String> alternatives = const [],
    Set<String> forms = const {},
  }) => evaluateAnswer(
    input,
    target: target,
    alternatives: alternatives,
    otherFormsOfLemma: forms,
  );

  group('target form', () {
    test('ignores case, surrounding spaces and the typographic apostrophe', () {
      expect(check(' WENT ', 'went'), AnswerVerdict.target);
      expect(check('don’t', "don't"), AnswerVerdict.target);
      expect(check("Don't", 'don’t'), AnswerVerdict.target);
    });

    test('inner spaces are not trimmed: one is an extra character', () {
      expect(check('w ent', 'went'), AnswerVerdict.almost);
      expect(check('w e nt', 'went'), AnswerVerdict.wrong);
    });
  });

  group('typo ("Fast richtig") on forms of four letters or more', () {
    test('missing, extra and substituted letter', () {
      expect(check('wet', 'went'), AnswerVerdict.almost); // missing
      expect(check('wennt', 'went'), AnswerVerdict.almost); // extra
      expect(check('wint', 'went'), AnswerVerdict.almost); // substituted
    });

    test('two swapped neighbouring letters', () {
      expect(check('wnet', 'went'), AnswerVerdict.almost);
      expect(check('abuot', 'about'), AnswerVerdict.almost);
      expect(isNearMiss('ab', 'ba'), isFalse); // short
    });

    test('two edits or a distant swap are wrong', () {
      expect(check('wnte', 'went'), AnswerVerdict.wrong);
      expect(check('tnew', 'went'), AnswerVerdict.wrong);
      expect(check('abtuo', 'about'), AnswerVerdict.wrong);
      expect(check('wentss', 'went'), AnswerVerdict.wrong);
    });

    test('short forms get no tolerance', () {
      expect(check('teh', 'the'), AnswerVerdict.wrong);
      expect(check('rn', 'ran'), AnswerVerdict.wrong);
      expect(check('an', 'a'), AnswerVerdict.wrong);
      expect(check('i', 'a'), AnswerVerdict.wrong);
    });

    test('the text-exercise check shares the rule', () {
      expect(checkAnswer('dresed', 'dressed'), AnswerResult.almost);
      expect(checkAnswer('drseesd', 'dressed'), AnswerResult.wrong);
      expect(checkAnswer('dressde', 'dressed'), AnswerResult.almost);
      expect(checkAnswer('teh', 'the'), AnswerResult.wrong);
    });
  });

  group('checked alternative', () {
    const alternatives = ['around', 'approximately'];

    test('matches like the target form', () {
      expect(
        check(' Around ', 'about', alternatives: alternatives),
        AnswerVerdict.alternative,
      );
    });

    test('takes precedence over the typo check', () {
      // "abut" is one edit from "about"; as a checked alternative it is a hint.
      expect(
        check('abut', 'about', alternatives: ['abut']),
        AnswerVerdict.alternative,
      );
      expect(check('abut', 'about'), AnswerVerdict.almost);
    });

    test('a typo of an alternative is no hint', () {
      expect(
        check('arround', 'about', alternatives: alternatives),
        AnswerVerdict.wrong,
      );
    });

    test('alternatives of another gap do not count', () {
      expect(check('around', 'about'), AnswerVerdict.wrong);
    });

    test('the target form still wins if it were listed', () {
      expect(
        check('about', 'about', alternatives: ['about']),
        AnswerVerdict.target,
      );
    });
  });

  group('wrong form of the same lemma', () {
    const forms = {'go', 'goes', 'gone'};

    test('counts as wrong form', () {
      expect(check('goes', 'went', forms: forms), AnswerVerdict.wrongForm);
      expect(check('Gone', 'went', forms: forms), AnswerVerdict.wrongForm);
    });

    test('known forms take precedence over typos without guessing forms', () {
      expect(
        check('walk', 'walks', forms: {'walk', 'walked'}),
        AnswerVerdict.wrongForm,
      );
      expect(check('walk', 'walks'), AnswerVerdict.almost);
      expect(check('wents', 'went'), AnswerVerdict.almost);
      expect(
        check('walk', 'walks', forms: {'walk'}, alternatives: ['walk']),
        AnswerVerdict.alternative,
      );
    });

    test('anything else is wrong', () {
      expect(check('walked', 'went', forms: forms), AnswerVerdict.wrong);
      expect(check('', 'went', forms: forms), AnswerVerdict.wrong);
    });
  });

  group('hint texts', () {
    test('synonym hint names the first letter of the target', () {
      expect(
        synonymHint('approximately', 'about'),
        'Approximately passt hier auch. Gesucht ist ein anderes Wort: a…',
      );
      expect(
        synonymHint('  around ', 'about'),
        'Around passt hier auch. Gesucht ist ein anderes Wort: a…',
      );
    });

    test('a one-letter target gives no letter away', () {
      expect(
        synonymHint('one', 'a'),
        'One passt hier auch. Gesucht ist ein anderes Wort.',
      );
    });

    test('wrong-form hint names lemma and form', () {
      expect(
        wrongFormHint('go', 'Verb, Vergangenheit'),
        'Andere Form von „go“ – gesucht: Verb, Vergangenheit',
      );
      expect(wrongFormHint('go', null), 'Andere Form von „go“');
    });
  });
}
