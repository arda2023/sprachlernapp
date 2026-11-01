// Run the real generation migrations and SQL assertions without a Supabase
// server. Pass an external @electric-sql/pglite dist/index.js path as argv[2].
// Only the Supabase auth/role shell and pgTAP presentation are substituted.
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
      id uuid primary key,
      email text,
      email_confirmed_at timestamptz,
      is_anonymous boolean default false
    );
    create function auth.uid() returns uuid language sql as $$select null::uuid$$;
  `);
  for (const file of [
    '20261003000001_schemas.sql',
    '20261031000001_adapty_entitlements.sql',
    '20261031000004_generated_vocabulary.sql',
    '20261101000003_generated_vocabulary_premium.sql',
  ]) {
    await db.exec(await readFile(new URL('../supabase/migrations/' + file, import.meta.url), 'utf8'));
  }
  await db.exec('grant usage on schema app to authenticated,service_role;');
  let sql = await readFile(new URL('../supabase/tests/database/generated_vocabulary_test.sql', import.meta.url), 'utf8');
  // Every DO-block assertion runs unchanged; omit only the pgTAP output shell.
  sql = sql.replace(/^create extension.*$/gm, '')
    .replace(/^select plan\(.*$/gm, '')
    .replace(/^select pass\(.*$/gm, '')
    .replace(/^select \* from finish\(\);$/gm, '');
  await db.exec(sql);
  console.log('PASS PostgreSQL/PGlite: generated_vocabulary_test.sql (10 assertion groups)');
} finally {
  await db.close();
}
