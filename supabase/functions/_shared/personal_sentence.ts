// Kept contract-equivalent with lib/domain/personal_sentence.dart; shared cases.
export function onePersonalSentence(text:string):boolean {
  if(/[\r\n]/.test(text))return false;
  let s=text.trim().replace(/(?<=\d)\.(?=\d)/g,'·');
  s=s.replace(/\b(?:Mr|Mrs|Ms|Dr|Prof|Sr|Sra|Srta|Dra|Eng|St)\.(?=\s+\p{L})/giu,m=>m.replaceAll('.','·'));
  s=s.replace(/\b(?:[A-Za-z]\.){2,}(?=\s+\p{L})/gu,m=>m.replaceAll('.','·'));
  s=s.replace(/\b[A-Z]\.(?=\s+[A-Z][\p{L}]+)/gu,m=>m.replaceAll('.','·'));
  s=s.replace(/\b(?:etc|approx|ex)\.(?=\s+[a-záéíóúãõç])/gi,m=>m.replaceAll('.','·'));
  const ends=[...s.matchAll(/[.!?…]+["'”’»)]*\s*/g)];
  return ends.length===1&&ends[0].index!+ends[0][0].length===s.length;
}
