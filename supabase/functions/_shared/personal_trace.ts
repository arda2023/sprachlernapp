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
  validationRule(rule:number) {
    // Fixed validator positions only; never accept field names or values.
    if(Number.isInteger(rule)&&((rule>=1&&rule<=30)||(rule>=100&&rule<=109)))
      this.write('validation_rule','RULE_'+rule);
  }
  finish() { this.write('ok'); }
  fail(code:string, status:number) { this.write('error', codes.has(code)?code:'SERVICE_UNAVAILABLE',status); }
  providerFailure(payload:unknown) {
    // Only fixed categories leave this boundary. Never log provider messages,
    // request IDs, schema paths, input, credentials or response fragments.
    const error=(payload as {error?:{type?:unknown;message?:unknown}}|null)?.error;
    const type=error?.type;
    const message=typeof error?.message==='string'?error.message:'';
    let code='PROVIDER_ERROR_UNCLASSIFIED';
    if(type==='invalid_request_error') {
      code='PROVIDER_INVALID_REQUEST';
      if(/credit balance is too low|insufficient credits/i.test(message))code='PROVIDER_CREDIT';
      else if(/schema is too complex for compilation/i.test(message))code='PROVIDER_SCHEMA_COMPLEXITY';
      else if(/(?:invalid|unsupported) (?:json )?schema|(?:output_config|output_format)\.format|json_schema/i.test(message))code='PROVIDER_SCHEMA';
    } else if(type==='authentication_error')code='PROVIDER_AUTH';
    else if(type==='permission_error')code='PROVIDER_PERMISSION';
    else if(type==='not_found_error')code='PROVIDER_NOT_FOUND';
    else if(type==='rate_limit_error')code='PROVIDER_RATE_LIMIT';
    else if(type==='overloaded_error')code='PROVIDER_OVERLOADED';
    else if(type==='api_error')code='PROVIDER_API';
    this.write('provider_error',code);
  }
  providerStatus(status:number) { this.write('provider_status',undefined,status); }
  private write(event:string,code?:string,status?:number) {
    const record={component:'personal_learning',diagnostic_id:this.id,stage:this.stage,event,
      elapsed_ms:Math.round(performance.now()-this.began),stage_ms:Math.round(performance.now()-this.started),
      ...(code?{code}:{}),...(Number.isInteger(status)&&status!>=100&&status!<=599?{http_status:status}:{})};
    try { this.emit(JSON.stringify(record)); } catch { /* Telemetry never changes a learning outcome. */ }
  }
}
