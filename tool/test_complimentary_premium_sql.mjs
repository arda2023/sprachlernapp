// Run real entitlement, translation and generation SQL in local PostgreSQL.
// Pass an external @electric-sql/pglite dist/index.js path as argv[2].
// Only Supabase auth/roles and the pgTAP presentation shell are substituted.
import {readFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';

const {PGlite} = await import(pathToFileURL(process.argv[2]).href);
const db = new PGlite();
try {
  await db.exec(`
    create role anon;
    create role authenticated;
    create role service_role bypassrls;
    create schema auth;
    create table auth.users (
      id uuid primary key, email text,
      email_confirmed_at timestamptz, is_anonymous boolean default false
    );
    create function auth.uid() returns uuid language sql as $$select null::uuid$$;
    create schema storage;
    create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint);
  `);
  for (const file of [
    '20261003000001_schemas.sql',
    '20261003000003_app_tables.sql',
    '20261017000002_content_distribution.sql',
    '20261019000001_runtime_translation_limits.sql',
    '20261024000001_private_translation_cache.sql',
    '20261031000001_adapty_entitlements.sql',
    '20261031000002_translation_subscription_budget.sql',
    '20261031000004_generated_vocabulary.sql',
    '20261101000001_sandbox_translation_budget.sql',
    '20261101000002_keep_translations.sql',
    '20261101000003_generated_vocabulary_premium.sql',
    '20261101000004_complimentary_premium.sql',
  ]) {
    await db.exec(await readFile(new URL('../supabase/migrations/' + file, import.meta.url), 'utf8'));
  }
  await db.exec('grant usage on schema app to authenticated,service_role;');
  for (const file of [
    'translation_subscription_budget.test.sql',
    'generated_vocabulary_test.sql',
    'complimentary_premium.test.sql',
  ]) {
    let sql = await readFile(new URL('../supabase/tests/database/' + file, import.meta.url), 'utf8');
    sql = sql.replace(/^create extension.*$/gm, '')
      .replace(/^select plan\(.*$/gm, '')
      .replace(/^select pass\(.*$/gm, '')
      .replace(/^select \* from finish\(\);$/gm, '');
    await db.exec(sql);
    console.log('PASS PostgreSQL/PGlite: ' + file);
  }
} finally {
  await db.close();
}
