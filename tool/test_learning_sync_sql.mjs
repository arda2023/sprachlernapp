// macOS Terminal and Windows PowerShell:
// node tool/test_learning_sync_sql.mjs <external-pglite-dist-index.js>
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { pathToFileURL } from 'node:url';
const { PGlite } = await import(pathToFileURL(process.argv[2]).href);
const db = new PGlite();
const a = '11111111-1111-4111-8111-111111111111';
const b = '22222222-2222-4222-8222-222222222222';
const unverified = '33333333-3333-4333-8333-333333333333';
const hash = 'a'.repeat(64), newer = 'b'.repeat(64);
const row = (key, changed_at = 1000, digest = hash, kind = 'user_cards') => ({kind,key,data:{card_id:key,box:2},changed_at,hash:digest});
const push = rows => db.query('select public.push_learning_rows($1::jsonb)', [JSON.stringify(rows)]);
const pull = async (after = null) => (await db.query('select public.pull_learning_rows($1) as rows', [after])).rows[0].rows;
async function login(id) { await db.query("select set_config('request.jwt.claim.sub',$1,false)", [id ?? '']); }
try {
  await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
    create schema app; create schema auth;
    create table auth.users(id uuid primary key,email_confirmed_at timestamptz,is_anonymous boolean default false);
    create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    insert into auth.users values ('${a}',now(),false),('${b}',now(),false),('${unverified}',null,false);`);
  await db.exec(await readFile(new URL('../supabase/migrations/20261107000001_learning_sync.sql', import.meta.url), 'utf8'));
  await login(null); await assert.rejects(push([row('x')])); await assert.rejects(pull());
  await login(unverified); await assert.rejects(push([row('x')]));
  await login(a); await push([row('x')]); assert.equal((await pull()).length,1);
  await login(b); assert.deepEqual(await pull(),[]); await push([row('x',2000,newer)]);
  await login(a); assert.equal((await pull())[0].hash,hash);
  await push([row('x',500,newer)]); assert.equal((await pull())[0].hash,hash);
  await push([row('x',1000,newer)]); assert.equal((await pull())[0].hash,newer);
  await push([row('review',1000,hash,'review_log')]);
  await assert.rejects(push([row('review',2000,newer,'review_log')]));
  await assert.rejects(push([row('invalid',1000,hash,'private_translation_cache')]));
  await assert.rejects(push([row('future',Date.now()+172800000)]));
  // Direct authenticated updates are denied even on own rows.
  await db.exec('set role authenticated');
  await assert.rejects(db.query("update app.learning_sync_rows set hash=$1",[hash]));
  await db.exec('reset role');
  for (let batch=0;batch<6;batch++) await push(Array.from({length:100},(_,i)=>row(`page-${String(batch*100+i).padStart(4,'0')}`)));
  const first=await pull(); assert.equal(first.length,500);
  const last=first.at(-1); const second=await pull(last.kind+'\x1f'+last.key); assert.equal(second.length,102);
  assert.equal(new Set([...first,...second].map(r=>r.kind+'\x1f'+r.key)).size,602);
  await db.query('delete from auth.users where id=$1',[a]);
  assert.equal((await db.query('select count(*)::int as n from app.learning_sync_rows where user_id=$1',[a])).rows[0].n,0);
  await login(b); assert.equal((await pull()).length,1);
  console.log('PASS: verified auth, account isolation, LWW/tie ordering, immutable reviews, allowlist, clock guard, grants, pagination, account deletion');
} finally { await db.close(); }
