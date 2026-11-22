// Windows PowerShell and macOS Terminal: node supabase/tests/run_tutor_sql.mjs
// Requires Docker. Disposable PostgreSQL, no ports, network, credentials or live project.
// Auth/entitlement prerequisites are synthetic; the actual migration and pgTAP
// file are executed unchanged. Also proves competing sessions, unlike PGlite.
import { execFileSync, execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { readFile } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import assert from 'node:assert/strict';
const exec = promisify(execFile);
const container = 'sprachapp-tutor-test-' + randomUUID().slice(0, 8);
const image = 'public.ecr.aws/supabase/postgres:17.11.0.018';
const migration = name => readFile(new URL('../migrations/' + name, import.meta.url), 'utf8');
const docker = (...args) => execFileSync('docker', args, { encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
const psqlArgs = ['exec', '-i', container, 'psql', '-U', 'supabase_admin', '-d', 'postgres', '-v', 'ON_ERROR_STOP=1', '-X', '-q', '-A', '-t'];
const sql = input => execFileSync('docker', psqlArgs, { input, encoding: 'utf8' });
let started = false;
try {
  docker('run', '--rm', '--name', container, '--network', 'none', '-e', 'POSTGRES_HOST_AUTH_METHOD=trust', '-d', image);
  started = true;
  for (let i = 0; ; i++) {
    try { docker('exec', container, 'pg_isready', '-h', '127.0.0.1', '-U', 'postgres'); break; }
    catch (error) { if (i === 40) throw error; await new Promise(resolve => setTimeout(resolve, 250)); }
  }
  sql(`create schema app; grant usage on schema app to authenticated,service_role;
    alter table auth.users add column if not exists email_confirmed_at timestamptz;
    alter table auth.users add column if not exists is_anonymous boolean default false;`);
  const entitlements = await migration('20261031000001_adapty_entitlements.sql');
  sql(entitlements.slice(entitlements.indexOf('create table app.verified_entitlements'),
    entitlements.indexOf('create table app.adapty_webhook_events')));
  sql(`alter table app.verified_entitlements drop constraint verified_entitlements_product_id_check;
    alter table app.verified_entitlements add check(product_id in (
      'com.ardasayar.linglossa.premium.monthly','com.ardasayar.linglossa.premium.yearly',
      'com.ardasayar.linglossa.premium.complimentary'));`);
  sql(await migration('20261031000004_generated_vocabulary.sql'));
  const personal = await migration('20261024000002_personal_learning.sql');
  sql(personal.slice(0, personal.indexOf('-- Service-only:')));
  sql(await migration('20261101000005_ai_monthly_spend.sql'));
  const retention = await migration('20261101000006_private_ai_retention.sql');
  sql(retention.slice(0, retention.indexOf('create extension')));
  sql(await migration('20261122000001_ai_tutor.sql'));
  const result = sql(await readFile(new URL('./database/tutor_test.sql', import.meta.url), 'utf8'));
  console.log(result.trim());
  assert.ok(!/^not ok/m.test(result) && /^1\.\.13$/m.test(result));

  // Each exec starts a separate PostgreSQL session. Only three claims may win.
  const actor = randomUUID(), item = randomUUID(), req = randomUUID();
  sql(`insert into auth.users(id,email,email_confirmed_at,is_anonymous) values('${actor}','parallel@example.test',now(),false);
    insert into app.tutor_items(user_id,id,request_id,lang,kind,prompt_de,reference_answer,skills,topic)
    values('${actor}','${item}','${req}','en','translate','Ich ging nach Hause.','I went home.',array['past_simple'],'alltag');`);
  const concurrent = async statement => (await exec('docker', [...psqlArgs.filter(x => x !== '-i'), '-c', statement])).stdout.trim();
  const results = await Promise.all(Array.from({ length: 12 }, () => concurrent(
    `select public.claim_tutor('${actor}','${randomUUID()}','tutor-grade',repeat('a',64),1,null,'${item}')->>'status'`)));
  assert.equal(results.filter(r => r === 'claimed').length, 3);
  assert.equal(results.filter(r => r === 'limit').length, 9);
  const generateResults = await Promise.all(Array.from({ length: 12 }, () => concurrent(
    `select public.claim_tutor('${actor}','${randomUUID()}','tutor-generate',repeat('a',64),2,'en',null)->>'status'`)));
  assert.equal(generateResults.filter(r => r === 'claimed').length, 3);
  assert.equal(generateResults.filter(r => r === 'limit').length, 9);
  // Competing identical IDs reserve once, even before a stored result exists.
  const duplicateActor = randomUUID(), duplicate = randomUUID();
  sql(`insert into auth.users(id,email,email_confirmed_at,is_anonymous) values('${duplicateActor}','duplicate@example.test',now(),false);`);
  const duplicates = await Promise.all(Array.from({ length: 8 }, () => concurrent(
    `select public.claim_tutor('${duplicateActor}','${duplicate}','tutor-generate',repeat('a',64),1,'en',null)->>'status'`)));
  assert.equal(duplicates.filter(r => r === 'claimed').length, 1);
  assert.equal(duplicates.filter(r => r === 'busy').length, 7);
  console.log('PASS PostgreSQL: 13 pgTAP groups; concurrent grade 3/12, generation 3/12 (2 items each), identical ID 1/8.');
} finally {
  if (started) docker('stop', container);
}
