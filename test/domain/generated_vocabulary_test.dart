import 'package:flutter_test/flutter_test.dart';
import 'package:sprachapp/domain/generated_vocabulary.dart';

const requestId = '12345678-1234-4234-8234-123456789abc';
GeneratedVocabularyRequest request({
  String lang = 'en',
  String prompt = 'Reise',
  int count = 5,
  String id = requestId,
}) => GeneratedVocabularyRequest(
  requestId: id,
  lang: lang,
  prompt: prompt,
  count: count,
);

Map<String, Object?> item({
  String form = 'ticket',
  String sentence = 'Buy a ticket today.',
  int start = 6,
}) => {
  'form': form,
  'lemma': form,
  'pos': 'NOUN',
  'gloss_de': 'Fahrkarte',
  'definition_de': 'Ein Nachweis für eine bezahlte Fahrt.',
  'form_detail': 'Singular',
  'sentence': sentence,
  'translation_de': 'Kaufe heute eine Fahrkarte.',
  'start': start,
};

Map<String, Object?> response({
  String lang = 'en',
  String id = requestId,
  List<Object?>? items,
}) => {
  'contract': 1,
  'request_id': id,
  'lang': lang,
  'items': items ?? [item()],
};

void main() {
  for (final lang in GeneratedVocabularyRequest.languages) {
    test('accepts request and partial response for $lang', () {
      final req = request(lang: lang, prompt: '  Reise?! Essen.  ');
      expect(req.prompt, 'Reise?! Essen.');
      expect(req.toJson(), {
        'contract': 1,
        'request_id': requestId,
        'lang': lang,
        'prompt': 'Reise?! Essen.',
        'count': 5,
        'consent': 1,
      });
      final parsed = GeneratedVocabularyResponse.fromJson(
        response(lang: lang),
        request: req,
      );
      expect(parsed.items.single.toJson(), item());
      expect(parsed.toJson(), response(lang: lang));
      expect(() => parsed.items.clear(), throwsUnsupportedError);
    });
  }

  test('validates request bounds, language, UUID and sentence groups', () {
    for (final prompt in ['', 'a' * 401, 'A. B! C?', 'A. B. C', 'A\nB']) {
      expect(() => request(prompt: prompt), throwsFormatException);
    }
    expect(request(prompt: 'a' * 400).prompt.length, 400);
    expect(request(prompt: 'Wohin?! Wann...').prompt, 'Wohin?! Wann...');
    expect(() => request(prompt: '😀' * 201), throwsFormatException);
    for (final count in [0, 51]) {
      expect(() => request(count: count), throwsFormatException);
    }
    expect(() => request(lang: 'de'), throwsFormatException);
    expect(() => request(id: 'not-uuid'), throwsFormatException);
  });

  test('rejects malformed or cross-request response with FormatException', () {
    final bad = <Object?>[
      null,
      [],
      'json',
      {},
      {...response(), 'extra': 1},
      {...response(), 'contract': 1.0},
      response(lang: 'es'),
      response(id: '87654321-1234-4234-8234-123456789abc'),
      {...response(), 'items': null},
      response(items: []),
      response(items: List.generate(6, (_) => item())),
      response(items: [null]),
      response(
        items: [
          {...item(), 'extra': 1},
        ],
      ),
    ];
    for (final json in bad) {
      expect(
        () => GeneratedVocabularyResponse.fromJson(json, request: request()),
        throwsFormatException,
        reason: '$json',
      );
    }
  });

  test('rejects malformed item fields, unsafe sentences and answer hints', () {
    final bad = <Object?>[
      null,
      [],
      {},
      {...item(), 'start': 6.0},
      {...item(), 'start': -1},
      {...item(), 'start': 9999},
      {...item(), 'pos': 'PROPN'},
      {...item(), 'lemma': 7},
      {...item(), 'form_detail': ' '},
      {...item(), 'gloss_de': 'a' * 201},
      {...item(), 'definition_de': 'a' * 301},
      {...item(), 'gloss_de': 'ein TICKET'},
      {...item(), 'translation_de': 'Das Ticket ist bezahlt.'},
      {...item(), 'translation_de': 'Fahrt\u0000'},
      item(form: 'two words'),
      item(sentence: 'Buy a ticket. Go now.'),
      item(sentence: 'Buy a ticket; go today.'),
      item(sentence: 'Buy a ticket—go today.'),
      item(sentence: 'Buy a ticket'),
      item(sentence: 'A ticket.', start: 2),
      item(form: 'tick', sentence: 'Buy a ticket today.'),
    ];
    for (final json in bad) {
      expect(
        () => GeneratedVocabularyItem.fromJson(json),
        throwsFormatException,
        reason: '$json',
      );
    }
    expect(
      GeneratedVocabularyItem.fromJson(item(sentence: 'Buy a ticket?!')).form,
      'ticket',
    );
  });

  test('uses UTF16 offsets and NFC case comparison for hints', () {
    final json = item(sentence: '😀 Buy a ticket today.', start: 9);
    final parsed = GeneratedVocabularyItem.fromJson(json);
    expect(parsed.start, 9);
    expect(parsed.end, 15);
    expect(
      () => GeneratedVocabularyItem.fromJson({...json, 'start': 8}),
      throwsFormatException,
    );
    final cafe = item(
      form: 'café',
      sentence: 'Visit the café today.',
      start: 10,
    );
    expect(
      () =>
          GeneratedVocabularyItem.fromJson({...cafe, 'gloss_de': 'CAFE\u0301'}),
      throwsFormatException,
    );
  });

  test('duplicate normalized forms fail and identity spans requests', () {
    final upper = item(form: 'TICKET', sentence: 'Buy a TICKET today.');
    expect(
      () => GeneratedVocabularyResponse.fromJson(
        response(items: [item(), upper]),
        request: request(),
      ),
      throwsFormatException,
    );
    final lower = GeneratedVocabularyItem.fromJson(item());
    final capitalized = GeneratedVocabularyItem.fromJson({
      ...upper,
      'lemma': 'ticket',
    });
    expect(lower.identity('en'), capitalized.identity('en'));
    expect(lower.identity('en'), isNot(lower.identity('es')));
    final req2 = request(id: '87654321-1234-4234-8234-123456789abc');
    final parsed = GeneratedVocabularyResponse.fromJson(
      response(id: req2.requestId),
      request: req2,
    );
    expect(parsed.items.single.identity('en'), lower.identity('en'));
    final changed = GeneratedVocabularyItem.fromJson({
      ...item(),
      'definition_de': 'Ein anderer Sinn.',
    });
    expect(changed.identity('en'), isNot(lower.identity('en')));
  });
}
