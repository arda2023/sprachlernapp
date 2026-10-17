import http.client
import json
import threading
import pytest
from test_editor_service import setup
from sprachpipe.editor.server import EditorHTTPServer


@pytest.fixture
def server(setup):
    service,_=setup;server=EditorHTTPServer(service)
    thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
    yield server
    server.shutdown();server.server_close();thread.join()


def request(server,path,method='GET',data=None,headers=None):
    connection=http.client.HTTPConnection('127.0.0.1',server.server_port)
    body=json.dumps(data).encode() if data is not None else None
    connection.request(method,path,body,headers or {})
    response=connection.getresponse();raw=response.read();result=(response.status,dict(response.getheaders()),json.loads(raw))
    connection.close();return result


def bootstrap(server):
    status,headers,result=request(server,'/api/v1/session/bootstrap','POST',{'token':server.bootstrap_token},
        {'Origin':server.origin,'Content-Type':'application/json'})
    assert status==200
    return {'Cookie':headers['Set-Cookie'].split(';')[0],'Origin':server.origin,
            'X-CSRF-Token':result['csrf'],'Content-Type':'application/json','Idempotency-Key':'request-12345'}


def test_loopback_origin_cookie_csrf_and_bootstrap_once(server):
    assert request(server,'/api/v1/languages')[0]==401
    assert request(server,'/api/v1/languages',headers={'Host':'evil.example'})[0]==403
    token=server.bootstrap_token;headers=bootstrap(server)
    assert 'Set-Cookie' not in request(server,'/api/v1/session',headers=headers)[1]
    assert request(server,'/api/v1/session/bootstrap','POST',{'token':token},{'Origin':server.origin,'Content-Type':'application/json'})[0]==401
    assert request(server,'/api/v1/languages',headers=headers)[0]==200
    assert request(server,'/api/v1/drafts','POST',{'lang':'en'},{**headers,'Origin':'null'})[0]==403
    assert request(server,'/api/v1/drafts','POST',{'lang':'en'},{**headers,'X-CSRF-Token':'wrong'})[0]==403
    first=request(server,'/api/v1/drafts','POST',{'lang':'en'},headers)
    assert first[0]==200 and 'ETag' in first[1]
    assert request(server,'/api/v1/drafts','POST',{'lang':'en'},headers)[2]==first[2]
    assert request(server,'/api/v1/drafts','POST',{'lang':'qaa'},headers)[0]==409


def test_missing_and_stale_etag_do_not_mutate(server):
    headers=bootstrap(server);_,response,draft=request(server,'/api/v1/drafts','POST',{'lang':'en'},headers)
    path='/api/v1/drafts/'+draft['draft_id']+'/operations'
    headers['Idempotency-Key']='different-key'
    assert request(server,path,'POST',{'operations':[]},headers)[0]==428
    assert request(server,path,'POST',{'operations':[]},{**headers,'If-Match':'"old"'})[0]==409
    assert request(server,path,'POST',{'operations':[]},{**headers,'If-Match':response['ETag']})[0]==200


def test_verification_status_and_explicit_resume_routes(server,monkeypatch):
    headers=bootstrap(server);calls=[]
    monkeypatch.setattr(server.service,'publication_status',lambda identifier:{'upload_id':'same','processed':4,'total':14})
    def resume(identifier,phase,confirmation):
        calls.append((identifier,phase,confirmation));return {'job_id':'synthetic-job'}
    monkeypatch.setattr(server.service,'publish_release',resume)
    status,_,body=request(server,'/api/v1/releases/test/publication',headers=headers)
    assert status==200 and body['processed']==4
    path='/api/v1/releases/test/publish/resume'
    assert request(server,path,'POST',{'accepted':True},{**headers,'X-CSRF-Token':'invalid'})[0]==403
    assert not calls
    assert request(server,path,'POST',{'accepted':True},headers)[0]==202
    assert calls==[('test','resume',{'accepted':True})]
