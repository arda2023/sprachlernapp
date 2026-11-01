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
  await db.exec(await readFile(new URL('../supabase/migrations/20261003000001_schemas.sql',import.meta.url),'utf8'));
  // Parked until the news return (user decision 01.11.2026).
  await db.exec(await readFile(new URL('../supabase/drafts/daily-news/20261101000004_daily_news.sql',import.meta.url),'utf8'));
  let sql=await readFile(new URL('../supabase/tests/database/daily_news.test.sql',import.meta.url),'utf8');
  // Only the pgTAP presentation wrapper is omitted. DO assertions run unchanged.
  sql=sql.replace(/^create extension.*$/gm,'').replace(/^select plan\(.*$/gm,'').replace(/^select pass\(.*$/gm,'').replace(/^select \* from finish\(\);$/gm,'');
  await db.exec(sql);
  console.log('PASS PostgreSQL/PGlite: daily_news.test.sql');
} finally {await db.close();}
