import { onePersonalSentence } from './personal_sentence.ts';

export type GenerationRequest = {
  contract: 1;
  request_id: string;
  lang: string;
  prompt: string;
  count: number;
  consent: 1;
};

export type GenerationItem = {
  form: string;
  lemma: string;
  pos: string;
  gloss_de: string;
  definition_de: string;
  form_detail: string;
  sentence: string;
  translation_de: string;
  start: number;
};

export type GenerationResponse = {
  contract: 1;
  request_id: string;
  lang: string;
  items: GenerationItem[];
};

export class GenerationValidationError extends Error {
  constructor(field: string) {
    super(`Ungültige Vokabelvorschläge: ${field}`);
    this.name = 'GenerationValidationError';
  }
}

const languages = new Set(['en', 'es', 'it', 'nb', 'pt-BR']);
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const controls = /[\p{Cc}\p{Cf}]/u;
const positions = new Set([
  'ADJ', 'ADP', 'ADV', 'AUX', 'CCONJ', 'DET', 'INTJ', 'NOUN', 'NUM',
  'PART', 'PRON', 'PUNCT', 'SCONJ', 'SYM', 'VERB', 'X',
]);

function requireValue(valid: unknown, field: string): asserts valid {
  if (!valid) throw new GenerationValidationError(field);
}

function object(raw: unknown, keys: string[]): Record<string, unknown> {
  requireValue(raw !== null && typeof raw === 'object' && !Array.isArray(raw), 'fields');
  const own = Object.keys(raw);
  requireValue(own.length === keys.length && own.every(key => keys.includes(key)), 'fields');
  return raw as Record<string, unknown>;
}

function text(raw: unknown, maxLength: number, field: string): string {
  requireValue(typeof raw === 'string' && raw.trim().length > 0 &&
    raw.length <= maxLength && !controls.test(raw), field);
  return raw;
}

function words(value: string): RegExpMatchArray[] {
  return [...value.matchAll(/[\p{L}\p{M}]+(?:['’\-][\p{L}\p{M}]+)*/gu)];
}

export function normalForm(value: string): string {
  return value.normalize('NFC').toLowerCase().replaceAll('’', "'");
}

/** Validates exact wire fields and emits a trimmed, bounded request. */
export function generatedRequest(raw: unknown): GenerationRequest {
  const value = object(raw, ['contract', 'request_id', 'lang', 'prompt', 'count', 'consent']);
  requireValue(value.contract === 1 && value.consent === 1, 'contract/consent');
  const request_id = text(value.request_id, 36, 'request_id');
  requireValue(uuid.test(request_id), 'request_id');
  const lang = text(value.lang, 5, 'lang');
  requireValue(languages.has(lang), 'lang');
  requireValue(typeof value.prompt === 'string', 'prompt');
  const prompt = text(value.prompt.trim(), 400, 'prompt');
  const ends = [...prompt.matchAll(/[.!?…]+(?:\s+|$)/g)];
  const last = ends.at(-1);
  const countSentences = ends.length +
    (!last || prompt.slice(last.index! + last[0].length).trim() ? 1 : 0);
  requireValue(countSentences <= 2, 'prompt sentences');
  const count = value.count;
  requireValue(typeof count === 'number' && Number.isInteger(count) && count >= 1 && count <= 50, 'count');
  return { contract: 1, request_id, lang, prompt, count, consent: 1 };
}

function generatedItem(raw: unknown): GenerationItem {
  const value = object(raw, ['form', 'lemma', 'pos', 'gloss_de', 'definition_de',
    'form_detail', 'sentence', 'translation_de', 'start']);
  const form = text(value.form, 80, 'form');
  const lemma = text(value.lemma, 80, 'lemma');
  const pos = text(value.pos, 10, 'pos');
  const gloss_de = text(value.gloss_de, 200, 'gloss_de');
  const definition_de = text(value.definition_de, 300, 'definition_de');
  const form_detail = text(value.form_detail, 200, 'form_detail');
  const sentence = text(value.sentence, 600, 'sentence');
  const translation_de = text(value.translation_de, 1200, 'translation_de');
  requireValue(positions.has(pos), 'pos');
  const formWords = words(form);
  requireValue(formWords.length === 1 && formWords[0].index === 0 &&
    formWords[0][0].length === form.length, 'form');
  const start = value.start;
  requireValue(typeof start === 'number' && Number.isInteger(start) && start >= 0 &&
    start + form.length <= sentence.length, 'start');
  const sentenceWords = words(sentence);
  requireValue(sentence.slice(start, start + form.length) === form &&
    sentenceWords.some(word => word.index === start && word[0].length === form.length), 'word occurrence');
  requireValue(sentenceWords.length >= 3 && sentenceWords.length <= 40, 'sentence words');
  requireValue(onePersonalSentence(sentence) && !/[;\p{Pd}]/u.test(sentence), 'sentence');
  for (const hint of [gloss_de, translation_de]) {
    requireValue(!words(hint).some(word => normalForm(word[0]) === normalForm(form)), 'answer in German hint');
  }
  return { form, lemma, pos, gloss_de, definition_de, form_detail, sentence, translation_de, start };
}

/** Partial lists are allowed; malformed or mismatched output fails as a unit. */
export function generatedResponse(raw: unknown, request: GenerationRequest): GenerationResponse {
  const value = object(raw, ['contract', 'request_id', 'lang', 'items']);
  requireValue(value.contract === 1, 'contract');
  requireValue(value.request_id === request.request_id, 'request_id');
  requireValue(value.lang === request.lang, 'lang');
  requireValue(Array.isArray(value.items) && value.items.length > 0 && value.items.length <= request.count, 'items');
  const forms = new Set<string>();
  const items = value.items.map(rawItem => {
    const item = generatedItem(rawItem);
    const norm = normalForm(item.form);
    requireValue(!forms.has(norm), 'duplicate form');
    forms.add(norm);
    return item;
  });
  return { contract: 1, request_id: request.request_id, lang: request.lang, items };
}
