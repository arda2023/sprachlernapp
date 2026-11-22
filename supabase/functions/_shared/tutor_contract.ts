import catalog from './tutor_skills.json' with { type: 'json' };
import { TranslationError } from './runtime_errors.ts';

export type TutorLanguage = keyof typeof catalog.languages;
export type TutorKind = 'translate' | 'situation';
export type TutorScores = { meaning: number; grammar: number; naturalness: number };
export type TutorError = { skill: string; severity: 'minor' | 'major'; quote: string; fix: string };
export type TutorOutcome = 'correct' | 'acceptable' | 'incorrect';
export type TutorItemSpec = { skills: string[]; kind?: TutorKind; parent_item_id?: string };
export type TutorGenerateRequest = {
  request_id: string; lang: TutorLanguage; items: TutorItemSpec[]; avoid_topics: string[]; consent: 1;
};
export type TutorGradeRequest = { attempt_id: string; item_id: string; answer: string; consent: 1 };
export type TutorItem = {
  id: string; kind: TutorKind; prompt_de: string; reference_answer: string; skills: string[]; topic: string;
};
export type TutorGrade = {
  scores: TutorScores; outcome: TutorOutcome; errors: TutorError[]; feedback_de: string; ideal_answer: string;
};
export { catalog as tutorCatalog };

/** Precedence is intentional: the correct rule is evaluated before the major-error rule. */
export function tutorOutcome(
  scores: TutorScores, errors: readonly TutorError[], targetSkills: readonly string[],
): TutorOutcome {
  if (scores.meaning === 2 && scores.grammar === 2 && scores.naturalness >= 1) return 'correct';
  if (scores.meaning >= 1 && scores.grammar >= 1 && scores.naturalness >= 1 &&
    !errors.some(error => error.severity === 'major' && targetSkills.includes(error.skill))) return 'acceptable';
  return 'incorrect';
}

const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const controls = /[\p{Cc}\p{Cf}]/u;
function requireValid(ok: unknown, model = false): asserts ok {
  if (!ok) throw new TranslationError(model ? 'MODEL_INVALID' : 'INPUT_INVALID', model ? 502 : 422);
}
function object(raw: unknown, keys: string[], optional: string[] = [], model = false): Record<string, unknown> {
  requireValid(raw && typeof raw === 'object' && !Array.isArray(raw), model);
  const value = raw as Record<string, unknown>;
  requireValid(keys.every(k => Object.hasOwn(value, k)) &&
    Object.keys(value).every(k => keys.includes(k) || optional.includes(k)), model);
  return value;
}
function text(raw: unknown, min: number, max: number, model = false): string {
  requireValid(typeof raw === 'string' && raw.trim().length >= min && raw.trim().length <= max && !controls.test(raw), model);
  return raw.trim();
}
function id(raw: unknown): string {
  requireValid(typeof raw === 'string' && uuid.test(raw));
  return raw.toLowerCase();
}
/** Sentence ends, ignoring common German abbreviations such as "z. B." or "bzw.". */
function sentenceEnds(value: string): number {
  return sentenceBoundaries(value).length;
}
function sentenceBoundaries(value: string): number[] {
  const plain = value
    .replace(/(?<!\p{L})(?:z\.\s?B|d\.\s?h|u\.\s?a|bzw|ca|usw|etc|vgl|evtl|ggf|inkl|Nr)\./giu,
      match => match.replaceAll('.', ' '))
    .replace(/(?<![\p{L}\p{N}])\d+\.(?=\s|$)/gu, match => match.replace('.', ' '));
  return [...plain.matchAll(/[.!?]+(?=\s|$)/gu)].map(match => match.index! + match[0].length);
}
/** Loose comparison so typographic quotes, case or spacing never void a grade. */
function looseText(value: string): string {
  return value.normalize('NFC').replace(/[‘’ʼ`´]/gu, "'").replace(/\s+/gu, ' ').toLowerCase();
}
function consent(raw: unknown): void {
  if (!raw || typeof raw !== 'object' || (raw as Record<string, unknown>).consent !== 1) {
    throw new TranslationError('CONSENT_REQUIRED', 403);
  }
}
function skills(raw: unknown, lang: TutorLanguage, model = false): string[] {
  requireValid(Array.isArray(raw) && raw.length >= 1 && raw.length <= 2 &&
    new Set(raw).size === raw.length && raw.every(s => catalog.languages[lang].some(k => k.id === s)), model);
  return raw as string[];
}
export function tutorGenerateRequest(raw: unknown): TutorGenerateRequest {
  consent(raw);
  const v = object(raw, ['request_id', 'lang', 'items', 'avoid_topics', 'consent']);
  requireValid(typeof v.lang === 'string' && Object.hasOwn(catalog.languages, v.lang));
  const lang = v.lang as TutorLanguage;
  requireValid(Array.isArray(v.items) && v.items.length >= 1 && v.items.length <= 5);
  const items = v.items.map(rawItem => {
    const item = object(rawItem, ['skills'], ['kind', 'parent_item_id']);
    requireValid(item.kind === undefined || item.kind === 'translate' || item.kind === 'situation');
    return { skills: skills(item.skills, lang),
      ...(item.kind === undefined ? {} : { kind: item.kind as TutorKind }),
      ...(item.parent_item_id === undefined ? {} : { parent_item_id: id(item.parent_item_id) }) };
  });
  requireValid(Array.isArray(v.avoid_topics) && v.avoid_topics.length <= 8 &&
    new Set(v.avoid_topics).size === v.avoid_topics.length &&
    v.avoid_topics.every(t => typeof t === 'string' && catalog.topics.includes(t)));
  return { request_id: id(v.request_id), lang, items, avoid_topics: v.avoid_topics as string[], consent: 1 };
}
export function tutorGradeRequest(raw: unknown): TutorGradeRequest {
  consent(raw);
  const v = object(raw, ['attempt_id', 'item_id', 'answer', 'consent']);
  const answer = typeof v.answer === 'string' ? v.answer.replace(/\s+/gu, ' ').trim() : v.answer;
  return { attempt_id: id(v.attempt_id), item_id: id(v.item_id), answer: text(answer, 1, 300), consent: 1 };
}

/** Reject bad provider prompts; never silently turn an instruction into an exercise. */
export function validateTutorPrompt(raw: unknown, kind: TutorKind): string {
  const value = text(raw, 8, 160, true);
  requireValid(!/^(?:übersetz\p{L}*|translate\p{L}*|bitte)\b/iu.test(value) &&
    !/^[\p{L}\p{N}\s_\-]{1,60}:/u.test(value) &&
    !/^["'„“”‘’«»‹›`]/u.test(value) && !/["'„“”‘’«»‹›`]$/u.test(value) &&
    /[.!?]$/u.test(value) && (kind !== 'situation' || value.endsWith('?')) &&
    sentenceEnds(value) <= 2 &&
    (value.match(/\p{L}+/gu)?.length ?? 0) >= 2, true);
  return value;
}
export function tutorGeneratedItems(raw: unknown, request: TutorGenerateRequest): TutorItem[] {
  const v = object(raw, ['items'], [], true);
  requireValid(Array.isArray(v.items) && v.items.length === request.items.length, true);
  return v.items.map((rawItem, index) => {
    const item = object(rawItem, ['kind', 'prompt_de', 'reference_answer', 'skills', 'topic'], [], true);
    const spec = request.items[index];
    requireValid((item.kind === 'translate' || item.kind === 'situation') &&
      (spec.kind === undefined || item.kind === spec.kind), true);
    const kind = item.kind as TutorKind;
    const prompt_de = validateTutorPrompt(item.prompt_de, kind);
    const reference_answer = text(item.reference_answer, 2, 200, true);
    const targetSkills = skills(item.skills, request.lang, true);
    requireValid(reference_answer.toLowerCase() !== prompt_de.toLowerCase() &&
      targetSkills.every(s => spec.skills.includes(s)) && targetSkills[0] === spec.skills[0] &&
      (!spec.parent_item_id || JSON.stringify(targetSkills) === JSON.stringify(spec.skills)) &&
      typeof item.topic === 'string' && catalog.topics.includes(item.topic) &&
      !request.avoid_topics.includes(item.topic), true);
    return { id: crypto.randomUUID(), kind, prompt_de, reference_answer, skills: targetSkills, topic: item.topic as string };
  });
}
export function tutorGradedAnswer(raw: unknown, lang: TutorLanguage, targets: string[], answer: string): TutorGrade {
  const v = object(raw, ['scores', 'errors', 'feedback_de', 'ideal_answer'], [], true);
  const s = object(v.scores, ['meaning', 'grammar', 'naturalness'], [], true);
  requireValid(Object.values(s).every(n => Number.isInteger(n) && Number(n) >= 0 && Number(n) <= 2), true);
  requireValid(Array.isArray(v.errors) && v.errors.length <= 4, true);
  const errors: TutorError[] = v.errors.map(rawError => {
    const e = object(rawError, ['skill', 'severity', 'quote', 'fix'], [], true);
    requireValid((e.skill === 'other' || catalog.languages[lang].some(k => k.id === e.skill)) &&
      (e.severity === 'minor' || e.severity === 'major'), true);
    // A quote the answer does not contain is dropped, not fatal: the learner's
    // daily sentence is already reserved, and the scores remain valid.
    const quoted = text(e.quote, 1, 60, true);
    const quote = looseText(answer).includes(looseText(quoted)) ? quoted : '';
    return { skill: e.skill as string, severity: e.severity as 'minor' | 'major', quote, fix: text(e.fix, 1, 60, true) };
  });
  let feedback_de = text(v.feedback_de, 1, 220, true);
  requireValid(!/^(?:[-*•]|\d+[.)])\s/u.test(feedback_de) && /[.!?]$/u.test(feedback_de), true);
  const boundaries = sentenceBoundaries(feedback_de);
  if (boundaries.length > 2) feedback_de = feedback_de.slice(0, boundaries[1]);
  const scores = s as TutorScores;
  return { scores, outcome: tutorOutcome(scores, errors, targets), errors, feedback_de,
    ideal_answer: text(v.ideal_answer, 1, 200, true) };
}
