from test_editor_http import server,request,bootstrap
from test_editor_service import setup
from sprachpipe.authoring_service import ROOT


def test_preview_is_authenticated_and_confirmation_cannot_supply_paths(server):
    server.service.asset_directory=ROOT/'assets/content/en'
    assert request(server,'/api/v1/baseline-adoption')[0]==401
    headers=bootstrap(server)
    status,_,view=request(server,'/api/v1/baseline-adoption',headers=headers)
    assert status==200 and view['cloud_state']=='not_checked'
    for index,data in enumerate([{}, {'accepted':False,'preview_sha256':view['sha256']},
                                {'accepted':True,'preview_sha256':view['sha256'],'path':'C:/elsewhere'}]):
        status,_,result=request(server,'/api/v1/baseline-adoption','POST',data,
                                {**headers,'Idempotency-Key':'baseline-request-'+str(index)})
        assert status==422 and result['code']=='ADOPTION_CONFIRMATION_REQUIRED'
    assert server.service.store.list('releases')==[]
    assert server.service.store.list('jobs')==[]
