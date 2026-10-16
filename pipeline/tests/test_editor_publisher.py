import copy
import hashlib
import json
import sqlite3
import uuid
from pathlib import Path

import pytest
from test_editor_service import setup,wait
from sprachpipe.editor.publisher import Publisher,inspect_bundle
from sprachpipe.authoring_service import AuthoringError,draft_content_hash
from sprachpipe.word_registry import digest


def test_auth_is_private_refreshes_and_never_returns_tokens():
    calls=[]
    def transport(method,path,body=None,**kwargs):
        calls.append((method,path,body,kwargs))
        if path=='/auth/v1/otp':return {}
        if path.startswith('/auth/v1/'):
            return {'access_token':'synthetic-access','refresh_token':'synthetic-refresh','user':{'id':'synthetic-user'},'expires_at':0 if path=='/auth/v1/verify' else 9999999999}
        return {'generation':0}
    p=Publisher('https://synthetic.invalid','public-test-key',transport=transport)
    p.request_otp('publisher@example.test');p.verify_otp('publisher@example.test','123456');p.channel('en')
    assert calls[0][2]['create_user'] is False
    assert any(c[1].startswith('/auth/v1/token') for c in calls)
    assert calls[-1][3]['token']=='synthetic-access'
    assert 'synthetic-access' not in json.dumps(p.status())
    p.sign_out()
    with pytest.raises(AuthoringError):p.channel('en')
    with pytest.raises(AuthoringError):Publisher('http://external.invalid','public')
    with pytest.raises(AuthoringError):Publisher('https://synthetic.invalid','sb_secret_forbidden')
    with pytest.raises(AuthoringError):p.upload('https://external.invalid/object/upload/sign/content-private/x','unused')


def test_password_login_reuses_refresh_logout_and_does_not_grant_publication():
    calls=[]
    def transport(method,path,body=None,**kwargs):
        calls.append((method,path,body))
        if path.startswith('/auth/v1/token'):
            return {'access_token':'synthetic-access','refresh_token':'synthetic-refresh',
                    'user':{'id':'synthetic-existing-user'},'expires_at':0 if path.endswith('=password') else 9999999999,
                    'password':'must-not-be-retained'}
        raise AuthoringError('PUBLISHER_REQUIRED','Publisherrecht fehlt.',status=403)
    publisher=Publisher('https://synthetic.invalid','public-test-key',transport=transport)
    result=publisher.sign_in_with_password(' publisher@example.test ',' synthetic-password ')
    assert result['signed_in'] and 'synthetic' not in json.dumps(result)
    assert publisher._session['user_id']=='synthetic-existing-user'
    assert 'password' not in publisher._session
    assert calls==[('POST','/auth/v1/token?grant_type=password',
                    {'email':'publisher@example.test','password':' synthetic-password '})]
    with pytest.raises(AuthoringError) as error:publisher.channel('en')
    assert error.value.status==403
    assert calls[1][1].endswith('grant_type=refresh_token')
    assert calls[1][2]=={'refresh_token':'synthetic-refresh'}
    publisher.sign_out()
    assert publisher._session is None
    with pytest.raises(AuthoringError):publisher.channel('en')


@pytest.mark.parametrize('remote_code,message',[
    ('invalid_credentials','E-Mail-Adresse oder Passwort ist falsch.'),
    ('email_not_confirmed','E-Mail-Adresse noch nicht bestätigt.'),
    ('user_banned','Dieses Konto ist gesperrt.'),
    ('unexpected','Anmeldung fehlgeschlagen.'),
])
def test_password_auth_errors_are_safe_and_leave_no_session(monkeypatch,remote_code,message):
    import io
    import urllib.error
    import urllib.request
    class Reject:
        def open(self,*args,**kwargs):
            raise urllib.error.HTTPError('https://synthetic.invalid',400,'remote-secret-message',{},
                io.BytesIO(json.dumps({'error_code':remote_code,'msg':'synthetic-password'}).encode()))
    monkeypatch.setattr(urllib.request,'build_opener',lambda *args:Reject())
    publisher=Publisher('https://synthetic.invalid','public-test-key')
    with pytest.raises(AuthoringError) as error:
        publisher.sign_in_with_password('publisher@example.test','synthetic-password')
    assert message in error.value.message and error.value.status==401
    assert 'synthetic-password' not in json.dumps(error.value.finding())
    assert 'remote-secret-message' not in str(error.value)
    assert not publisher.status()['signed_in']


def test_password_requires_authoritative_session_and_refresh_failure_clears_tokens():
    publisher=Publisher('https://synthetic.invalid','public',transport=lambda *a,**k:{'user':{'id':'fake'}})
    with pytest.raises(AuthoringError):publisher.sign_in_with_password('p@example.test','synthetic')
    assert not publisher.status()['signed_in']
    for email,password in [('bad','synthetic'),('p@example.test',''),('p@example.test',{'bad':'synthetic'})]:
        with pytest.raises(AuthoringError):publisher.sign_in_with_password(email,password)
    def transport(method,path,body=None,**kwargs):
        if path.endswith('=password'):
            return {'access_token':'synthetic','refresh_token':'synthetic','user':{'id':'existing'},'expires_at':0}
        raise AuthoringError('AUTH_REQUIRED','Refresh abgewiesen.',status=401)
    publisher._transport=transport
    publisher.sign_in_with_password('p@example.test','synthetic')
    with pytest.raises(AuthoringError):publisher.channel('en')
    assert publisher._session is None


def bundle(service):
    draft=service.new_draft('en');identifier=str(uuid.uuid4());directory=service.store.root/'bundles'/identifier;directory.mkdir(parents=True)
    fixture=Path(__file__).resolve().parents[2]/'test/fixtures/private_release'
    for path in fixture.glob('*.json'):(directory/path.name).write_bytes(path.read_bytes())
    with sqlite3.connect(directory/'content.sqlite') as db:db.executescript((fixture/'content.sql').read_text())
    manifest=json.loads((directory/'content.manifest.json').read_text())
    raw=(directory/'content.sqlite').read_bytes();manifest.update(sha256=hashlib.sha256(raw).hexdigest(),size_bytes=len(raw))
    reviews=json.loads((directory/'editorial_reviews.json').read_text());reviews[0]['payload_sha256']=draft_content_hash(draft)
    manifest['editorial_reviews_sha256']=digest(reviews)
    report=json.loads((directory/'finalization_report.json').read_text());report['validation']['content_sha256']=draft_content_hash(draft)
    for name,value in [('content.manifest.json',manifest),('editorial_reviews.json',reviews),('finalization_report.json',report)]:
        (directory/name).write_text(json.dumps(value))
    record={'release_id':identifier,'draft_id':draft['draft_id'],'draft_etag':service.store.etag(draft),'lang':'en','version':manifest['version'],'manifest':manifest,'path':str(directory.relative_to(service.store.root)),'status':'verified'}
    service.store.put('releases',identifier,record)
    return directory,record,draft


class Remote:
    def __init__(self):self.calls=[];self.fail_upload=True;self.upload_id=str(uuid.uuid4())
    def channel(self,lang):return {'generation':0,'release_id':None,'manifest_sha256':None,'manifest':None}
    def call(self,path,body=None):
        self.calls.append((path,copy.deepcopy(body)))
        if path=='start':return {'upload_id':self.upload_id,'status':'uploading','uploads':{'content.sqlite':'signed-private-token'}}
        if path.endswith('/finalize'):return {'status':'ready'}
        if path.endswith('/commit'):return {'release_id':self.upload_id,'generation':1}
        raise AssertionError(path)
    def upload(self,url,file):
        if self.fail_upload:self.fail_upload=False;raise AuthoringError('PUBLISH_NETWORK','Synthetic interrupted upload')


def test_upload_retry_finalize_explicit_commit_and_stale_revision(setup):
    service,_=setup;directory,record,draft=bundle(service);remote=Remote();service.publisher=remote
    first=wait(service,service.publish_release(record['release_id'],'upload'));assert first['state']=='failed'
    assert not any(p.endswith('/commit') for p,_ in remote.calls)
    retry=wait(service,service.publish_release(record['release_id'],'upload'));assert retry['state']=='succeeded'
    starts=[body for p,body in remote.calls if p=='start'];assert starts[0]==starts[1]
    assert wait(service,service.publish_release(record['release_id'],'finalize'))['state']=='succeeded'
    result=wait(service,service.publish_release(record['release_id'],'commit'));assert result['state']=='succeeded'
    assert service.store.get('releases',record['release_id'])['publication']['status']=='published'
    assert 'signed-private-token' not in json.dumps(service.store.get('releases',record['release_id']))
    service.store.save_draft({**draft,'synthetic_change':True},service.store.etag(draft))
    with pytest.raises(AuthoringError,match='Entwurfsrevision'):service.publish_release(record['release_id'],'commit')


def test_changed_bytes_and_unapproved_export_are_rejected(setup):
    service,_=setup;directory,record,draft=bundle(service)
    inspect_bundle(directory,record,draft)
    with (directory/'content.sqlite').open('ab') as stream:stream.write(b'changed')
    with pytest.raises(AuthoringError,match='Exportdateien'):inspect_bundle(directory,record,draft)
    report=json.loads((directory/'finalization_report.json').read_text());report['validation']['editorial']='open'
    (directory/'finalization_report.json').write_text(json.dumps(report))
    with pytest.raises(AuthoringError,match='bestätigt'):inspect_bundle(directory,record,draft)
