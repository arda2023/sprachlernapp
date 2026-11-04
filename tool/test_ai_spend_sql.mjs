// macOS and PowerShell: node tool/test_ai_spend_sql.mjs <external-pglite-index.js>
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
import { randomUUID } from 'node:crypto';
const { PGlite } = await import(pathToFileURL(process.argv[2]).href);
const db = new PGlite();
const user = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
let checks = 0;
async function rpc(name, params) {
  const result = await db.query(`select public.${name}(${params.map((_, i) => '$' + (i + 1)).join(',')}) as value`, params);
  return result.rows[0].value;
}
const reserve = (who = user, id = randomUUID(), feature = 'generated-vocabulary') => rpc('reserve_ai_spend', [who, id, feature]);
const used = async (who = user) => (await db.query('select used_micros from app.ai_spend_months where user_id=$1 order by month_start desc limit 1', [who])).rows[0]?.used_micros;
try {
  await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
    create schema app; create schema auth;
    create table auth.users(id uuid primary key,email_confirmed_at timestamptz,is_anonymous boolean default false);
    insert into auth.users values ('${user}',now(),false),('${other}',now(),false);`);
  await db.exec(await readFile(new URL('../supabase/migrations/20261101000005_ai_monthly_spend.sql', import.meta.url), 'utf8'));
  // Keep the suite valid after the real tariff review date without altering the migration.
  await db.exec("update app.ai_spend_policy set valid_until=now()+interval '1 day'");
  const attempt = randomUUID();
  assert.equal((await reserve(user, attempt)).status, 'reserved');
  assert.equal(await used(), 1080000);
  assert.equal((await reserve(user, attempt)).status, 'replay');
  assert.equal((await reserve(other, attempt)).status, 'replay');
  assert.equal((await rpc('settle_ai_spend', [other, attempt, 5, 3])).status, 'missing');
  assert.equal(await used(), 1080000); checks++;
  await assert.rejects(rpc('settle_ai_spend', [user, attempt, -1, 3]));
  await assert.rejects(rpc('settle_ai_spend', [user, attempt, 1000001, 3]));
  assert.equal(await used(), 1080000); checks++;
  await rpc('settle_ai_spend', [user, attempt, 6, 3]);
  assert.equal(await used(), 5); // round input UP, never floating currency
  await rpc('settle_ai_spend', [user, attempt, 0, 0]);
  assert.equal(await used(), 5); checks++;
  // All endpoints share one balance. PGlite serializes connections; real
  // overlapping sessions are a separate live check, not claimed by this test.
  const results = await Promise.all(Array.from({ length: 10 }, (_, i) => reserve(user, randomUUID(),
    ['lookup-word','translate-sentence','personal-learning','topic-check','generated-vocabulary'][i % 5])));
  assert.equal(results.filter(r => r.status === 'reserved').length, 4);
  assert.ok(await used() <= 5000000);
  assert.equal((await reserve()).status, 'limit');
  assert.equal((await reserve(other)).status, 'reserved'); checks++;
  await db.exec('set role authenticated');
  await assert.rejects(reserve());
  await assert.rejects(db.query('select * from app.ai_spend_months'));
  await assert.rejects(rpc('settle_ai_spend', [user, attempt, 0, 0]));
  await db.exec('reset role; set role anon');
  await assert.rejects(reserve());
  await db.exec('reset role'); checks++;
  await db.exec("update app.ai_spend_policy set valid_until=now()-interval '1 second'");
  assert.equal((await reserve(other)).status, 'unavailable');
  await db.exec("update app.ai_spend_policy set valid_until=now()+interval '1 day',enabled=false");
  assert.equal((await reserve(other)).status, 'unavailable'); checks++;
  await db.exec('update app.ai_spend_policy set enabled=true');
  await db.query('update auth.users set is_anonymous=true where id=$1', [other]);
  assert.equal((await reserve(other)).status, 'forbidden');
  await db.query('update auth.users set is_anonymous=false,email_confirmed_at=null where id=$1', [other]);
  assert.equal((await reserve(other)).status, 'forbidden'); checks++;
  // An old, unresolved hold remains in its original month and cannot consume
  // this month's allowance. Late settlement credits that ORIGINAL month only.
  const old = randomUUID();
  await db.query("insert into app.ai_spend_months values($1,'2020-01-01',1001920)", [user]);
  await db.query("insert into app.ai_spend_attempts(attempt_id,user_id,month_start,feature,max_output,reserved_micros) values($1,$2,'2020-01-01','lookup-word',384,1001920)",[old,user]);
  const current = await used();
  await rpc('settle_ai_spend',[user,old,100001,4]);
  assert.equal(await used(),current);
  assert.equal((await db.query("select used_micros from app.ai_spend_months where month_start='2020-01-01'")).rows[0].used_micros,100021); checks++;
  await db.exec(await readFile(new URL('../supabase/migrations/20261031000004_generated_vocabulary.sql', import.meta.url), 'utf8'));
  const personal = await readFile(new URL('../supabase/migrations/20261024000002_personal_learning.sql', import.meta.url), 'utf8');
  await db.exec(personal.slice(0, personal.indexOf('-- Service-only:')));
  const retention = await readFile(new URL('../supabase/migrations/20261101000006_private_ai_retention.sql', import.meta.url), 'utf8');
  // pg_cron is validated on Supabase; execute the exact purge function locally.
  await db.exec(retention.slice(0, retention.indexOf('create extension')));
  for (const age of [31, 1]) await db.query(`insert into app.generated_vocabulary_requests
    (user_id,request_id,lang,input_hash,item_count,state,response,created_at)
    values($1,$2,'en',repeat('a',64),1,'ready','{"items":[]}',now()-$3*interval '1 day')`,[user,randomUUID(),age]);
  await db.query(`insert into app.personal_learning_jobs values($1,repeat('b',64),$2,'ready',now(),now()-interval '1 day','{"private":true}')`,[user,randomUUID()]);
  const beforePurge = await used();
  assert.equal((await db.query('select app.purge_expired_private_ai() as n')).rows[0].n,2);
  const retained = (await db.query('select state,response from app.generated_vocabulary_requests order by created_at')).rows;
  assert.equal(retained[0].state,'expired'); assert.equal(retained[0].response,null);
  const personalAfter = (await db.query('select state,response from app.personal_learning_jobs')).rows[0];
  assert.equal(personalAfter.state,'uncertain'); assert.equal(personalAfter.response,null);
  assert.equal(retained[1].state,'ready'); assert.equal(await used(),beforePurge);
  assert.equal((await db.query("select * from app.ai_spend_months where month_start='2020-01-01'")).rows.length,0); checks++;
  await db.exec('set role authenticated');
  await assert.rejects(db.query('select app.purge_expired_private_ai()'));
  await db.exec('reset role'); checks++;
  await db.query('delete from auth.users where id=$1',[user]);
  assert.equal((await db.query('select * from app.ai_spend_attempts where user_id=$1',[user])).rows.length,0); checks++;
  console.log(`PASS PostgreSQL/PGlite: ${checks} AI spending assertion groups`);
} finally { await db.close(); }
