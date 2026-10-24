import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {onePersonalSentence} from './personal_sentence.ts';
test('bounded en/pt-BR replacement segmentation shared corpus',()=>{
 for(const [text,expected] of JSON.parse(readFileSync(new URL('../../../test/fixtures/personal_sentence_cases.json',import.meta.url),'utf8')))assert.equal(onePersonalSentence(text),expected,text);
});
