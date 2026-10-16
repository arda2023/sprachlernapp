"""Run the existing SQL commit function in a disposable local Docker database.

No HTTP, credentials, cloud calls or existing local application tables are used.
The production migration is applied unchanged to a minimal auth/storage shell.
"""
import concurrent.futures
import json
import subprocess
import uuid
from pathlib import Path

CONTAINER='supabase_db_sprachapp'


def main():
    database='adoption_test_'+uuid.uuid4().hex
    def sql(statement,db=database,check=True):
        result=subprocess.run(['docker','exec','-i',CONTAINER,'psql','-U','postgres','-d',db,
                               '-v','ON_ERROR_STOP=1','-At'],input=statement,text=True,capture_output=True)
        if check and result.returncode:raise AssertionError(result.stderr)
        return result
    sql('CREATE DATABASE '+database+';',db='postgres')
    try:
        sql('CREATE SCHEMA auth; CREATE TABLE auth.users(id uuid PRIMARY KEY);'
            'CREATE SCHEMA storage; CREATE TABLE storage.buckets(id text PRIMARY KEY,name text,public boolean,file_size_limit bigint);')
        migration=Path(__file__).resolve().parents[2]/'supabase/migrations/20261017000002_content_distribution.sql'
        sql(migration.read_text(encoding='utf-8'))
        actor=str(uuid.uuid4());outsider=str(uuid.uuid4())
        sql(f"INSERT INTO auth.users VALUES ('{actor}'),('{outsider}'); INSERT INTO public.content_publishers VALUES ('{actor}');")
        uploads=[str(uuid.uuid4()),str(uuid.uuid4())];requests=[str(uuid.uuid4()),str(uuid.uuid4())]
        for identifier in uploads:
            manifest=json.dumps({'lang':'en','channel':'internal','release_id':identifier,'generation':1,
                                 'parent_manifest_sha256':None,'parent_release_id':None,
                                 'publication_kind':'internal-baseline-adoption-v1'})
            sql(f"""INSERT INTO public.content_release_uploads
                (id,request_id,owner_id,lang,channel,expected_generation,draft_manifest,objects,verified_objects,manifest,manifest_sha256,status)
                VALUES ('{identifier}','{uuid.uuid4()}','{actor}','en','internal',0,'{{}}','{{}}','{{}}','{manifest}','{'a'*64}','ready');""")
        def commit(index,who=actor,generation=0,parent='NULL'):
            return sql(f"SELECT public.publish_content_release('{uploads[index]}',{generation},{parent},'{requests[index]}','{who}');",check=False)
        denied=commit(0,outsider);assert denied.returncode and 'Publisher permission required' in denied.stderr
        wrong=commit(0,generation=1);assert wrong.returncode and 'Upload basis mismatch' in wrong.stderr
        wrong=commit(0,parent="'"+'b'*64+"'");assert wrong.returncode and 'Upload basis mismatch' in wrong.stderr
        # Concurrent sessions race for the same absent channel. One SQL
        # transaction inserts/locks it; the other must observe generation 1.
        with concurrent.futures.ThreadPoolExecutor(2) as pool:
            results=list(pool.map(commit,range(2)))
        assert sorted(r.returncode for r in results)==[0,3],[(r.returncode,r.stderr) for r in results]
        loser=next(r for r in results if r.returncode)
        assert 'Channel changed; build on the latest release' in loser.stderr,loser.stderr
        assert sql("SELECT generation FROM public.content_channels WHERE lang='en';").stdout.strip()=='1'
        assert sql('SELECT count(*) FROM public.content_release_catalog;').stdout.strip()=='1'
        winner=next(i for i,r in enumerate(results) if not r.returncode)
        assert commit(winner).returncode==0
        print('CAS: 2 concurrent generation-0 commits; 1 winner, 1 conflict; generation=1; catalog=1; retry idempotent.')
        print('Denied publisher, wrong generation and wrong parent rejected. Existing migration unchanged.')
    finally:
        sql('DROP DATABASE '+database+';',db='postgres')
        print('Disposable local test database removed.')


if __name__=='__main__':main()
