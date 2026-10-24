// Local PostgreSQL semantics without a Supabase server. Install @electric-sql/pglite
// in an external test directory; pass its absolute dist/index.js path as argv[2].
// No cloud connection, secrets, real user data or repository dependencies.
import {readFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
const {PGlite}=await import(pathToFileURL(process.argv[2]).href);
const db=new PGlite();
try {
  await db.exec(`create role anon; create role authenticated; create role service_role;
    create schema auth; create table auth.users(id uuid primary key,email text);
    create function auth.uid() returns uuid language sql as $$select null::uuid$$;
    create schema storage; create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint);`);
  for(const file of ['20261003000001_schemas.sql','20261003000002_content_tables.sql','20261010000001_form_targets.sql','20261003000003_app_tables.sql','20261017000002_content_distribution.sql','20261019000001_runtime_translation_limits.sql','20261024000001_private_translation_cache.sql','20261024000002_personal_learning.sql']) {
    await db.exec(await readFile(new URL('../supabase/migrations/'+file,import.meta.url),'utf8'));
  }
  for(const file of ['runtime_translation.test.sql','translation_cache.test.sql','personal_learning.test.sql']) {
    let sql=await readFile(new URL('../supabase/tests/database/'+file,import.meta.url),'utf8');
    // Only the pgTAP presentation wrapper is omitted. DO assertions run unchanged.
    sql=sql.replace(/^create extension.*$/gm,'').replace(/^select plan\(.*$/gm,'').replace(/^select pass\(.*$/gm,'').replace(/^select \* from finish\(\);$/gm,'');
    await db.exec(sql);
    console.log('PASS PostgreSQL/PGlite: '+file);
  }
} finally {await db.close();}
