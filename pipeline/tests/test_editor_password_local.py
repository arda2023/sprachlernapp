"""Opt-in real loopback Auth/Functions test. Never accepts a cloud endpoint/key."""
import json
import os
import shutil
import subprocess
import urllib.error
import urllib.request
import uuid
from pathlib import Path

import pytest

from sprachpipe.authoring_service import AuthoringError
from sprachpipe.editor.publisher import Publisher, NoRedirect


@pytest.mark.skipif(os.environ.get('SPRACHAPP_TEST_LOCAL_AUTH')!='1',reason='Explicit local Supabase integration only')
def test_real_local_password_permissions_refresh_logout_and_rejections():
    result=subprocess.run([shutil.which('supabase'),'status','-o','json'],cwd=Path(__file__).parents[2],
                          capture_output=True,text=True,timeout=30,check=True)
    config=json.loads(result.stdout)
    url=config['API_URL']
    if url!='http://127.0.0.1:54321':pytest.fail('Local endpoint mismatch; no Auth request made.')
    public,secret=config['ANON_KEY'],config['SERVICE_ROLE_KEY']
    opener=urllib.request.build_opener(NoRedirect())
    def admin(method,path,body=None):
        request=urllib.request.Request(url+'/auth/v1/admin/users'+path,
            data=None if body is None else json.dumps(body).encode(),method=method,
            headers={'apikey':secret,'Authorization':'Bearer '+secret,'Content-Type':'application/json'})
        with opener.open(request,timeout=15) as response:return json.loads(response.read())
    users=[]
    try:
        for confirmed in (True,False):
            email='password-login-'+uuid.uuid4().hex+'@example.test';password=uuid.uuid4().hex+'-Aa1!'
            user=admin('POST','',{'email':email,'password':password,'email_confirm':confirmed})
            users.append(user['id'])
            publisher=Publisher(url,public)
            if not confirmed:
                with pytest.raises(AuthoringError,match='noch nicht bestätigt'):publisher.sign_in_with_password(email,password)
                assert not publisher.status()['signed_in'];continue
            with pytest.raises(AuthoringError,match='Passwort ist falsch'):publisher.sign_in_with_password(email,'wrong-synthetic-password')
            assert not publisher.status()['signed_in']
            assert publisher.sign_in_with_password(email,password)['signed_in']
            assert publisher._session['user_id']==user['id']
            with pytest.raises(AuthoringError) as denied:publisher.channel('en')
            assert denied.value.status==403,denied.value.code  # Login alone has no publisher grant.
            with pytest.raises(AuthoringError) as denied:
                publisher._http('GET','/functions/v1/content-release/current?lang=en&channel=internal',token=publisher._token())
            assert denied.value.status==403  # Nor a reader grant / private download.
            publisher._session['expires_at']=0
            assert publisher._token()
            publisher.sign_out();assert publisher._session is None
            with pytest.raises(AuthoringError):publisher.channel('en')
            admin('PUT','/'+user['id'],{'ban_duration':'1h'})
            with pytest.raises(AuthoringError,match='gesperrt'):publisher.sign_in_with_password(email,password)
    finally:
        for user_id in users:admin('DELETE','/'+user_id)
