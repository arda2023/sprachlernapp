import json

from test_editor_http import server, request, bootstrap
from test_editor_service import setup
from sprachpipe.editor.publisher import Publisher


def test_password_route_requires_csrf_has_no_cache_and_never_returns_credentials(server, capsys):
    def transport(method,path,body=None,**kwargs):
        assert path=='/auth/v1/token?grant_type=password'
        assert body=={'email':'existing@example.test','password':'synthetic-password'}
        return {'access_token':'synthetic-access','refresh_token':'synthetic-refresh',
                'user':{'id':'existing-uid'},'expires_at':9999999999}
    server.service.publisher=Publisher('https://synthetic.invalid','public',transport=transport)
    path='/api/v1/publisher/password'
    data={'email':'existing@example.test','password':'synthetic-password'}
    headers=bootstrap(server)
    assert request(server,path,'POST',data,{**headers,'X-CSRF-Token':'bad'})[0]==403
    assert request(server,path+'?password=forbidden','POST',data,headers)[0]==400
    assert request(server,path,headers=headers)[0]==404
    status,response,result=request(server,path,'POST',data,headers)
    assert status==200 and result['signed_in']
    assert response['Cache-Control']=='no-store'
    assert server.requests=={}
    assert 'synthetic' not in json.dumps(result)
    assert request(server,'/api/v1/publisher/logout','POST',{},headers)[2]['signed_in'] is False
    assert request(server,path,'POST',data,headers)[2]['signed_in']  # Same request key cannot replay logout/login.
    assert server.requests=={}
    assert capsys.readouterr().out==''


def test_malformed_password_is_not_echoed_or_cached(server):
    server.service.publisher=Publisher('https://synthetic.invalid','public')
    status,_,result=request(server,'/api/v1/publisher/password','POST',
        {'email':'existing@example.test','password':{'synthetic-secret':'bad'}},bootstrap(server))
    assert status==422 and result['code']=='PASSWORD_INVALID'
    assert 'synthetic-secret' not in json.dumps(result) and server.requests=={}
