// Only fixed protocol metadata leaves this boundary. No exception messages,
// request keys, identities, content, URLs or provider bodies are logged.
export type PersonalStage = 'input'|'auth'|'release'|'pack'|'references'|'claim'|'cached_response'|'configuration'|'model_request'|'model_envelope'|'model_json'|'validation'|'storage'|'complete';
const codes = new Set(['AUTH_REQUIRED','READER_REQUIRED','REFERENCE_INVALID','RATE_LIMIT','REQUEST_UNCERTAIN','STORAGE_UNAVAILABLE','NOT_CONFIGURED','PROVIDER_RATE_LIMIT','MODEL_FAILED','MODEL_INVALID','CACHE_CONFLICT','MEANING_BLOCKED','SENTENCE_INVALID','ORIGINAL_CHANGED','SHORT_CONTEXT','REASON_INVALID','ANSWER_LEAK','CARD_INVALID','BODY_LIMIT','METHOD_NOT_ALLOWED','TIMEOUT','SERVICE_UNAVAILABLE']);
export class PersonalTrace {
  readonly id = crypto.randomUUID();
  private stage: PersonalStage = 'input';
  private began = performance.now();
  private started = this.began;
  constructor(private emit: (line:string)=>void = console.log) { this.write('start'); }
  enter(stage: PersonalStage) {
    this.write('ok'); this.stage=stage; this.started=performance.now(); this.write('start');
  }
  finish() { this.write('ok'); }
  fail(code:string, status:number) { this.write('error', codes.has(code)?code:'SERVICE_UNAVAILABLE',status); }
  providerStatus(status:number) { this.write('provider_status',undefined,status); }
  private write(event:string,code?:string,status?:number) {
    const record={component:'personal_learning',diagnostic_id:this.id,stage:this.stage,event,
      elapsed_ms:Math.round(performance.now()-this.began),stage_ms:Math.round(performance.now()-this.started),
      ...(code?{code}:{}),...(Number.isInteger(status)&&status!>=100&&status!<=599?{http_status:status}:{})};
    try { this.emit(JSON.stringify(record)); } catch { /* Telemetry never changes a learning outcome. */ }
  }
}
