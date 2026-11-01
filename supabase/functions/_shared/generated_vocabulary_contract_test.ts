import { test } from 'node:test';
import assert from 'node:assert/strict';
import { generatedRequest, generatedResponse, GenerationValidationError, normalForm } from './generated_vocabulary_contract.ts';

const requestId = '12345678-1234-4234-8234-123456789abc';
const request = (changes = {}) => ({
  contract: 1, request_id: requestId, lang: 'en', prompt: 'Reise', count: 5, consent: 1, ...changes,
});
const item = (changes = {}) => ({
  form: 'ticket', lemma: 'ticket', pos: 'NOUN', gloss_de: 'Fahrkarte',
  definition_de: 'Ein Nachweis für eine bezahlte Fahrt.', form_detail: 'Singular',
  sentence: 'Buy a ticket today.', translation_de: 'Kaufe heute eine Fahrkarte.', start: 6, ...changes,
});
const response = (changes = {}) => ({
  contract: 1, request_id: requestId, lang: 'en', items: [item()], ...changes,
});

for (const lang of ['en', 'es', 'it', 'nb', 'pt-BR']) {
  test(`valid request and partial response for ${lang}`, () => {
    const req = generatedRequest(request({ lang, prompt: '  Reise?! Essen.  ' }));
    assert.equal(req.prompt, 'Reise?! Essen.');
    assert.deepEqual(generatedResponse(response({ lang }), req), response({ lang }));
  });
}

test('request has exact wire fields, explicit consent and bounded strings', () => {
  for (const raw of [null, [], {}, { ...request(), extra: 1 },
    request({ contract: 2 }), request({ consent: 0 }), request({ request_id: 'abc' }),
    request({ count: 0 }), request({ count: 51 }), request({ count: 2.5 }),
    request({ count: '5' }), request({ lang: 'de' }), request({ prompt: null }),
    ...['', 'a'.repeat(401), '😀'.repeat(201), 'A. B! C?', 'A. B. C', 'A\nB', 'A\u200bB']
      .map(prompt => request({ prompt })),
  ]) assert.throws(() => generatedRequest(raw), GenerationValidationError);
  assert.equal(generatedRequest(request({ prompt: 'a'.repeat(400) })).prompt.length, 400);
  assert.equal(generatedRequest(request({ prompt: 'Wohin?! Wann...' })).prompt, 'Wohin?! Wann...');
  assert.equal(generatedRequest(request({ prompt: 'a.b.c' })).prompt, 'a.b.c');
});

test('response is exact, request bound and has a nonempty bounded item list', () => {
  for (const raw of [null, [], {}, { ...response(), extra: true },
    response({ contract: 2 }), response({ lang: 'es' }), response({ request_id: 'other' }),
    response({ items: null }), response({ items: [] }),
    response({ items: Array.from({ length: 6 }, () => item()) }),
    response({ items: [null] }), response({ items: [{ ...item(), extra: 1 }] }),
  ]) assert.throws(() => generatedResponse(raw, generatedRequest(request())), GenerationValidationError);
});

test('strict item types, bounds, word offsets and sentence rules', () => {
  const bad = [
    { start: 6.1 }, { start: -1 }, { start: 9999 }, { pos: 'PROPN' },
    { lemma: 7 }, { form_detail: ' ' }, { gloss_de: 'a'.repeat(201) },
    { definition_de: 'a'.repeat(301) }, { form: 'a'.repeat(81) },
    { sentence: 'a'.repeat(601) }, { translation_de: 'a'.repeat(1201) },
    { gloss_de: 'ein TICKET' }, { translation_de: 'Das Ticket ist bezahlt.' },
    { translation_de: 'Fahrt\u0000' }, { form: 'two words' },
    { sentence: 'Buy a ticket. Go now.' }, { sentence: 'Buy a ticket; go today.' },
    { sentence: 'Buy a ticket—go today.' }, { sentence: 'Buy a ticket' },
    { sentence: 'A ticket.', start: 2 }, { form: 'tick' },
  ];
  for (const changes of bad) assert.throws(() => generatedResponse(
    response({ items: [item(changes)] }), generatedRequest(request())), GenerationValidationError);
  assert.equal(generatedResponse(response({ items: [item({ sentence: 'Buy a ticket?!' })] }),
    generatedRequest(request())).items[0].form, 'ticket');
});

test('UTF16 offsets match Dart and normalization handles NFC/case/apostrophe', () => {
  const changes = { sentence: '😀 Buy a ticket today.', start: 9 };
  assert.equal(generatedResponse(response({ items: [item(changes)] }),
    generatedRequest(request())).items[0].start, 9);
  assert.throws(() => generatedResponse(response({ items: [item({ ...changes, start: 8 })] }),
    generatedRequest(request())), GenerationValidationError);
  assert.equal(normalForm('CAFE\u0301'), 'café');
  assert.equal(normalForm('L’EAU'), "l'eau");
  assert.throws(() => generatedResponse(response({ items: [item({
    form: 'café', sentence: 'Visit the café today.', start: 10, gloss_de: 'CAFE\u0301',
  })] }), generatedRequest(request())), GenerationValidationError);
});

test('duplicate normalized forms fail', () => {
  assert.throws(() => generatedResponse(response({ items: [item(), item({
    form: 'TICKET', sentence: 'Buy a TICKET today.',
  })] }), generatedRequest(request())), GenerationValidationError);
});
