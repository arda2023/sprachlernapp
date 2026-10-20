"""Install both distribution migrations in a disposable DB on the owned test stack."""
from pathlib import Path
import subprocess
import uuid

ROOT = Path(__file__).resolve().parents[3]
CONTAINER = 'supabase_db_sprachapp_native_v2'


def main():
    database = 'native_migration_' + uuid.uuid4().hex

    def sql(database, source):
        result = subprocess.run(['docker', 'exec', '-i', CONTAINER, 'psql', '-U',
                                 'postgres', '-d', database, '-v', 'ON_ERROR_STOP=1'],
                                input=source, text=True, capture_output=True)
        if result.returncode:
            raise RuntimeError(result.stderr)
        return result.stdout

    sql('postgres', 'create database ' + database)
    try:
        sql(database, 'create schema auth; create table auth.users(id uuid primary key);'
            'create schema storage; create table storage.buckets(id text primary key, name text, public boolean, file_size_limit bigint);')
        for name in ['20261017000002_content_distribution.sql', '20261018000001_content_verification_runs.sql']:
            sql(database, (ROOT / 'supabase/migrations' / name).read_text(encoding='utf8'))
        sql(database, """
do $$
declare actor uuid=gen_random_uuid(); upload uuid=gen_random_uuid();
begin
  if has_function_privilege('authenticated','public.content_verification_transition(uuid,uuid,text,jsonb)','execute')
    or not has_function_privilege('service_role','public.content_verification_transition(uuid,uuid,text,jsonb)','execute')
    or has_table_privilege('service_role','public.content_verification_runs','update') then
    raise exception 'Unexpected verification privileges'; end if;
  insert into auth.users values(actor);
  insert into public.content_publishers values(actor);
  insert into public.content_release_uploads(id,request_id,owner_id,lang,channel,expected_generation,draft_manifest,objects)
    values(upload,gen_random_uuid(),actor,'en','internal',0,'{}','{}');
  begin
    update public.content_release_uploads set status='ready',manifest='{}',manifest_sha256=repeat('a',64),verified_objects=objects where id=upload;
    raise exception 'Legacy ready writer bypassed verification';
  exception when sqlstate 'PV409' then null; end;
  begin
    perform public.publish_content_release(upload,0,null,gen_random_uuid(),actor);
    raise exception 'Legacy commit bypassed verification';
  exception when sqlstate '55000' then null; end;
end $$;
""")
        print('PASS: fresh migration; client RPC denied/server RPC allowed/direct run update denied; legacy ready and commit blocked.')
    finally:
        sql('postgres', 'drop database ' + database)


if __name__ == '__main__':
    main()
