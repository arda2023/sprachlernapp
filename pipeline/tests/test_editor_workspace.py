from test_editor_service import setup
from sprachpipe.editor.service import EditorService
from sprachpipe.authoring_service import AuthoringError
import pytest


def test_selection_survives_restart_without_touching_draft(setup):
    service,base=setup
    draft=service.new_draft('en');deck=base['decks'][0]['ref']
    selected={'lang':'en','draft_id':draft['draft_id'],'deck':deck,'page':'content'}
    view=service.workspace_view(selected)
    root,source,assets=service.store.root,service.source,service.asset_directory
    service.close()
    reopened=EditorService(root,source=source,asset_directory=assets)
    try:
        assert reopened.workspace_view()==view
        assert reopened.store.load_draft(draft['draft_id'])==draft
        # Navigation never increments a draft revision or bypasses stale CAS.
        changed=reopened.store.save_draft({**draft,'test_marker':'new revision'},reopened.store.etag(draft))
        reopened.workspace_view(selected)
        with pytest.raises(AuthoringError,match='anderer Tab'):
            reopened.save_operations(draft['draft_id'],[],reopened.store.etag(draft))
        assert reopened.store.load_draft(draft['draft_id'])==changed
    finally:reopened.close()


def test_missing_selection_falls_back_and_language_isolation(setup):
    service,base=setup
    draft=service.new_draft('en')
    service.create_language({'lang':'qaa','display_name':'Synthetisch'})
    view=service.workspace_view({'lang':'qaa','draft_id':draft['draft_id'],'deck':'absent'})
    assert view['selection']=={'lang':'qaa','draft_id':None,'deck':None,'page':'content'}
    assert view['warning']
    view=service.workspace_view({'lang':'zzz','draft_id':'missing'})
    assert view['selection']['lang']=='en' and view['warning']
    service.discard(draft['draft_id'],service.store.etag(draft))
    view=service.workspace_view({'lang':'en','draft_id':draft['draft_id']})
    assert view['selection']['draft_id'] is None and view['warning']
    assert service.store.load_draft(draft['draft_id'])['state']=='discarded'
