import copy
import hashlib
import json
import sqlite3
import uuid
import time
from pathlib import Path

import pytest
from test_editor_service import setup
from sprachpipe.editor.publisher import Publisher,inspect_bundle
from sprachpipe.authoring_service import AuthoringError,draft_content_hash
from sprachpipe.word_registry import digest


def wait(service,job):
    # Windows does not allow replacement while an ordinary Python reader holds
    # the destination open. Coordinate fixture polling with the existing writer
    # mutex; keep the original 90-second deadline and terminal-state assertions.
    deadline=time.monotonic()+90
    while time.monotonic()<deadline:
        with service.store.mutex:current=service.store.get('jobs',job['job_id'])
        if current['state'] not in ('queued','running'):return current
        time.sleep(.02)
    raise AssertionError('job did not finish')


def test_finalize_wire_body_is_json_object_and_get_body_stays_empty(monkeypatch):
    """Exercise the real urllib serialization, not only a transport stub."""
    import urllib.request
    requests=[]
    class Response:
        def __enter__(self):return self
        def __exit__(self,*args):pass
        def read(self,limit):return b'{"status":"verifying"}'
    class Opener:
        def open(self,request,timeout):requests.append(request);return Response()
    monkeypatch.setattr(urllib.request,'build_opener',lambda *args:Opener())
    publisher=Publisher('https://synthetic.invalid','public-test')
    monkeypatch.setattr(publisher,'_token',lambda:'synthetic-access')
    publisher.call('11111111-1111-4111-8111-111111111111/finalize')
    publisher.channel('en')
    publisher.call('start',{'request_id':'synthetic'})
    assert requests[0].data==b'{}' and requests[0].method=='POST'
    assert requests[0].get_header('Content-type')=='application/json'
    assert requests[1].data is None and requests[1].method=='GET'
    assert json.loads(requests[2].data)=={'request_id':'synthetic'}


@pytest.mark.parametrize('raw,code,reason',[
    (b'{"code":"REQUEST_FAILED","message":"secret-token <script> https://signed.invalid/?token=secret"}',
     'REQUEST_FAILED','Server konnte die Anfrage nicht verarbeiten.'),
    (b'{"code":"OBJECT_HASH"}','OBJECT_HASH','Prüfsumme'),
    (b'{"message":"Invalid JWT"}',None,'Invalid JWT'),
    (b'{"code":401,"message":"Invalid JWT"}',401,'Invalid JWT'),
    (b'{"code":"secret-token","message":"secret-token"}',None,'Kein freigegebener'),
    (b'<html>secret-token</html>',None,'Kein freigegebener'),
    (b'\xffsecret-token',None,'Kein freigegebener'),
    (b'[]',None,'Kein freigegebener'),
    (b'{"code":"REQUEST_FAILED","padding":"'+b'x'*16384+b'"}',None,'Kein freigegebener'),
])
def test_http_diagnostic_is_bounded_structured_and_never_reflects_remote_text(monkeypatch,raw,code,reason):
    import io
    import urllib.error
    import urllib.request
    reads=[]
    class Body(io.BytesIO):
        def read(self,size=-1):reads.append(size);return super().read(size)
    class Opener:
        def open(self,*args,**kwargs):
            raise urllib.error.HTTPError('https://signed.invalid/?token=secret-token',400,
                'secret-token',{'Set-Cookie':'secret-token'},Body(raw))
    monkeypatch.setattr(urllib.request,'build_opener',lambda *args:Opener())
    publisher=Publisher('https://synthetic.invalid','public-test')
    with pytest.raises(AuthoringError) as error:
        publisher._http('POST','/functions/v1/content-publish/11111111-1111-4111-8111-111111111111/finalize',{},token='secret-token')
    finding=error.value.finding()
    assert finding['code']=='PUBLISH_HTTP_400' and finding['retryable'] is False
    assert finding['diagnostic']['step']=='Serverprüfung'
    assert finding['diagnostic']['http_status']==400 and finding['diagnostic']['server_code']==code
    assert reason in finding['diagnostic']['reason'] and 'HTTP 400' in finding['message']
    assert all(value not in json.dumps(finding) for value in ('secret-token','<script>','<html>','signed.invalid','Set-Cookie'))
    assert reads==[16385]


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


@pytest.mark.parametrize('http_status',[400,546])
def test_finalize_diagnostic_persists_and_retry_keeps_existing_upload(setup,monkeypatch,http_status):
    import io
    import urllib.error
    import urllib.request
    service,_=setup;_,record,_=bundle(service)
    remote=Remote();remote.fail_upload=False;service.publisher=remote
    assert wait(service,service.publish_release(record['release_id'],'upload'))['state']=='succeeded'
    before=service.store.get('releases',record['release_id'])
    attempts=[];fail=True
    class Response:
        def __enter__(self):return self
        def __exit__(self,*args):pass
        def read(self,limit):return b'{"status":"ready"}'
    class Opener:
        def open(self,request,timeout):
            attempts.append(request)
            if fail:
                raise urllib.error.HTTPError('https://synthetic.invalid',http_status,'redacted',{},
                    io.BytesIO(b'{"code":"REQUEST_FAILED","details":"secret-token"}'))
            return Response()
    monkeypatch.setattr(urllib.request,'build_opener',lambda *args:Opener())
    publisher=Publisher('https://synthetic.invalid','public-test')
    monkeypatch.setattr(publisher,'_token',lambda:'synthetic-access');service.publisher=publisher
    failed=wait(service,service.publish_release(record['release_id'],'finalize'))
    assert failed['state']=='failed' and failed['result'] is None and failed['processed']==0
    assert failed['error']['diagnostic']['server_code']=='REQUEST_FAILED'
    assert failed['error']['diagnostic']['http_status']==http_status
    assert len(attempts)==1  # No automatic retry, including on resource abort.
    if http_status==546:assert 'Ressourcenlimit' in failed['error']['message']
    current=service.store.get('releases',record['release_id'])
    assert current['publication']['status']=='uploaded'
    assert current['publication']['upload_id']==before['publication']['upload_id']==remote.upload_id
    assert current['publication']['last_error']==failed['error']
    assert 'secret-token' not in json.dumps(failed)
    fail=False
    retried=wait(service,service.publish_release(record['release_id'],'finalize'))
    assert retried['state']=='succeeded' and retried['result']['status']=='ready'
    assert 'last_error' not in retried['result']
    assert retried['result']['upload_id']==remote.upload_id
    assert len(attempts)==2 and all(r.data==b'{}' and r.full_url.endswith('/'+remote.upload_id+'/finalize') for r in attempts)
