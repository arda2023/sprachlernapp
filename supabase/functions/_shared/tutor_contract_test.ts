import { test } from 'node:test';
import assert from 'node:assert/strict';
import { tutorOutcome, tutorGenerateRequest, tutorGradeRequest, tutorGeneratedItems, tutorGradedAnswer,
  validateTutorPrompt, tutorCatalog, type TutorError } from './tutor_contract.ts';
import { TranslationError } from './runtime_errors.ts';

const request_id = '12345678-1234-4234-8234-123456789abc';
const input = { request_id, lang: 'en', items: [{ skills: ['past_simple'] }], avoid_topics: [], consent: 1 };
const candidate = { kind: 'translate', prompt_de: 'Ich ging gestern ins Kino.', reference_answer: 'I went to the cinema yesterday.',
  skills: ['past_simple'], topic: 'kultur' };
const invalid = (fn: () => unknown, code = 'INPUT_INVALID') => assert.throws(fn,
  (error: unknown) => error instanceof TranslationError && error.code === code);

test('multiline answers normalize before validation and hashing', () => {
  const payload = { attempt_id: request_id, item_id: request_id, consent: 1 };
  assert.deepEqual(tutorGradeRequest({ ...payload, answer: '  I\n\t go   home. ' }),
    tutorGradeRequest({ ...payload, answer: 'I go home.' }));
  invalid(() => tutorGradeRequest({ ...payload, answer: 'I\u0000 go home.' }));
});
test('ordinals dates and German abbreviations are not sentence boundaries', () => {
  for (const prompt of ['Die 2. Verbform ist hier richtig. Die Bedeutung bleibt erhalten.',
    'Am 1. Mai fahre ich ans Meer.', 'Am 1. Mai fahre ich ans Meer. Am 2. Mai komme ich heim.',
    'Ich kaufe z. B. Brot. Es ist frisch.']) {
    assert.equal(validateTutorPrompt(prompt, 'translate'), prompt);
  }
  invalid(() => validateTutorPrompt('Am 1. Mai komme ich. Dann gehe ich. Jetzt schlafe ich.', 'translate'), 'MODEL_INVALID');
});
test('feedback keeps first two sentences without rejecting ordinals or abbreviations', () => {
  const raw = { scores: { meaning: 2, grammar: 2, naturalness: 2 }, errors: [], ideal_answer: 'I go home.' };
  const feedback = 'Die 2. Verbform ist hier richtig. Die Bedeutung bleibt erhalten.';
  assert.equal(tutorGradedAnswer({ ...raw, feedback_de: feedback }, 'en', ['past_simple'], 'I go home.').feedback_de, feedback);
  const abbreviation = 'Nutze z. B. die 2. Verbform. Die Bedeutung stimmt.';
  assert.equal(tutorGradedAnswer({ ...raw, feedback_de: abbreviation + ' Noch ein Hinweis.' },
    'en', ['past_simple'], 'I go home.').feedback_de, abbreviation);
  invalid(() => tutorGradedAnswer({ ...raw, feedback_de: 'a'.repeat(221) + '.' }, 'en', ['past_simple'], 'answer'), 'MODEL_INVALID');
});

test('outcome: all 27 score triples and major-error combinations match the shared rubric', () => {
  const cases: { errors: TutorError[]; targetMajor: boolean }[] = [
    { errors: [], targetMajor: false },
    { errors: [{ skill: 'past_simple', severity: 'minor', quote: 'x', fix: 'y' }], targetMajor: false },
    { errors: [{ skill: 'past_simple', severity: 'major', quote: 'x', fix: 'y' }], targetMajor: true },
    { errors: [{ skill: 'articles', severity: 'major', quote: 'x', fix: 'y' }], targetMajor: false },
    { errors: [{ skill: 'other', severity: 'major', quote: 'x', fix: 'y' }], targetMajor: false },
  ];
  // Rows meaning/grammar; columns naturalness 0,1,2. The correct branch wins
  // even for inconsistent provider errors, exactly as specified by section 5.
  const baseline = [
    ['incorrect', 'incorrect', 'incorrect'], ['incorrect', 'incorrect', 'incorrect'], ['incorrect', 'incorrect', 'incorrect'],
    ['incorrect', 'incorrect', 'incorrect'], ['incorrect', 'acceptable', 'acceptable'], ['incorrect', 'acceptable', 'acceptable'],
    ['incorrect', 'incorrect', 'incorrect'], ['incorrect', 'acceptable', 'acceptable'], ['incorrect', 'correct', 'correct'],
  ];
  for (let meaning = 0; meaning <= 2; meaning++) for (let grammar = 0; grammar <= 2; grammar++) {
    for (let naturalness = 0; naturalness <= 2; naturalness++) for (const row of cases) {
      const base = baseline[meaning * 3 + grammar][naturalness];
      assert.equal(tutorOutcome({ meaning, grammar, naturalness }, row.errors, ['past_simple']),
        base === 'acceptable' && row.targetMajor ? 'incorrect' : base);
    }
  }
});
test('requests validate consent, UUIDs, catalog by language, bounds and exact fields', () => {
  assert.equal(tutorGenerateRequest(input).lang, 'en');
  for (const consent of [undefined, 0, false, '1']) {
    invalid(() => tutorGenerateRequest({ ...input, consent }), 'CONSENT_REQUIRED');
    invalid(() => tutorGradeRequest({ consent }), 'CONSENT_REQUIRED');
  }
  for (const patch of [{ lang: 'de' }, { lang: '__proto__' }, { request_id: 'bad' }, { extra: true },
    { items: [] }, { items: Array(6).fill(input.items[0]) }, { items: [{ skills: ['presente'] }] },
    { items: [{ skills: ['past_simple', 'past_simple'] }] }, { items: [{ skills: [] }] },
    { items: [{ skills: ['past_simple'], kind: 'quiz' }] }, { items: [{ skills: ['past_simple'], parent_item_id: 'x' }] },
    { avoid_topics: ['unknown'] }, { avoid_topics: tutorCatalog.topics.slice(0, 9) }]) {
    invalid(() => tutorGenerateRequest({ ...input, ...patch }));
  }
  for (const [lang, entries] of Object.entries(tutorCatalog.languages)) {
    for (const skill of entries) assert.equal(tutorGenerateRequest({ ...input, lang,
      items: [{ skills: [skill.id] }] }).items[0].skills[0], skill.id);
  }
  const grade = { attempt_id: request_id, item_id: request_id, answer: '  I went.  ', consent: 1 };
  assert.equal(tutorGradeRequest(grade).answer, 'I went.');
  for (const answer of ['', ' ', 'x'.repeat(301), 'x\u200by', 'a\u0000b']) invalid(() => tutorGradeRequest({ ...grade, answer }));
  invalid(() => tutorGradeRequest({ ...grade, prompt_de: 'spoof' }));
});
test('provider prompt prefixes and wrappers are rejected, not silently stripped', () => {
  for (const prefix of ['Übersetze: ', 'Übersetzen Sie: ', 'Translate: ', 'Bitte ', 'Aufgabe: ', 'Label: ']) {
    invalid(() => validateTutorPrompt(prefix + candidate.prompt_de, 'translate'), 'MODEL_INVALID');
  }
  for (const prompt of ['"Ich gehe nach Hause."', '„Ich gehe nach Hause.“', 'Ich gehe nach Hause',
    'Ein Satz. Noch einer. Ein dritter.', 'Ich\u200b gehe nach Hause.', 'Hallo!!!']) {
    invalid(() => validateTutorPrompt(prompt, 'translate'), 'MODEL_INVALID');
  }
  assert.equal(validateTutorPrompt(candidate.prompt_de, 'translate'), candidate.prompt_de);
  assert.equal(validateTutorPrompt('Wie fragst du nach dem Weg?', 'situation'), 'Wie fragst du nach dem Weg?');
  invalid(() => validateTutorPrompt(candidate.prompt_de, 'situation'), 'MODEL_INVALID');
});
test('generated output enforces requested skills, kinds, topics, counts and answer boundaries', () => {
  const req = tutorGenerateRequest(input);
  assert.equal(tutorGeneratedItems({ items: [candidate] }, req).length, 1);
  for (const patch of [{ skills: ['presente'] }, { skills: ['articles'] }, { skills: [] }, { topic: 'made_up' },
    { reference_answer: candidate.prompt_de }, { reference_answer: 'x'.repeat(201) }, { id: request_id }]) {
    invalid(() => tutorGeneratedItems({ items: [{ ...candidate, ...patch }] }, req), 'MODEL_INVALID');
  }
  invalid(() => tutorGeneratedItems({ items: [candidate] }, { ...req, avoid_topics: ['kultur'] }), 'MODEL_INVALID');
  invalid(() => tutorGeneratedItems({ items: [] }, req), 'MODEL_INVALID');
  invalid(() => tutorGeneratedItems({ items: [candidate] }, { ...req, items: [{ skills: ['past_simple'], kind: 'situation' }] }), 'MODEL_INVALID');
});
test('grading rejects catalog invention, fabricated quotes, invalid scores and long feedback', () => {
  const raw = { scores: { meaning: 2, grammar: 1, naturalness: 1 }, errors: [],
    feedback_de: 'Die Aussage ist verständlich.', ideal_answer: 'I went home.' };
  assert.equal(tutorGradedAnswer(raw, 'en', ['past_simple'], 'I goed home.').outcome, 'acceptable');
  for (const patch of [{ scores: { meaning: 3, grammar: 2, naturalness: 2 } },
    { scores: { meaning: 1.5, grammar: 2, naturalness: 2 } }, { outcome: 'correct' },
    { feedback_de: 'x'.repeat(220) + '.' },
    { ideal_answer: 'x'.repeat(201) }, { errors: [{ skill: 'presente', severity: 'major', quote: 'goed', fix: 'went' }] }]) {
    invalid(() => tutorGradedAnswer({ ...raw, ...patch }, 'en', ['past_simple'], 'I goed home.'), 'MODEL_INVALID');
  }
  // A quote the answer does not contain is dropped instead of voiding the reserved grade.
  const fabricated = tutorGradedAnswer({ ...raw, errors: [{ skill: 'past_simple', severity: 'major', quote: 'swimmed', fix: 'swam' }] },
    'en', ['past_simple'], 'I goed home.');
  assert.equal(fabricated.errors[0].quote, '');
  assert.equal(tutorGradedAnswer({ ...raw, errors: [{ skill: 'past_simple', severity: 'major', quote: 'I GOED  home', fix: 'I went home' }] },
    'en', ['past_simple'], 'I goed home.').errors[0].quote, 'I GOED  home');
  // German abbreviations do not count as sentence ends.
  assert.equal(tutorGradedAnswer({ ...raw, feedback_de: 'Nutze hier eine unregelmäßige Form, z. B. went. Sonst passt alles.' },
    'en', ['past_simple'], 'I goed home.').feedback_de.startsWith('Nutze'), true);
  const errors = [{ skill: 'past_simple', severity: 'major', quote: 'goed', fix: 'went' }];
  assert.equal(tutorGradedAnswer({ ...raw, scores: { meaning: 2, grammar: 0, naturalness: 1 }, errors },
    'en', ['past_simple'], 'I goed home.').outcome, 'incorrect');
});
