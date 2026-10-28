"""Historical and new private-channel profile identities stay independently bound."""
import copy
import pytest
from sprachpipe.editor.published_base import channel_binding
from sprachpipe.authoring_service import AuthoringError
from sprachpipe.language_profiles import get_profile
from sprachpipe.word_registry import digest

@pytest.mark.parametrize('lang,profile_id', [('en','en-legacy-v1'),('pt-BR','pt-BR-editorial-v1'),
    ('pt-BR','pt-BR-editorial-v2'),('nb','nb-editorial-v1'),('it','it-editorial-v1'),('es','es-editorial-v1')])
def test_channel_accepts_exact_installed_profile_and_rejects_changed_hash(lang,profile_id):
    p=get_profile(lang,profile_id)
    release='11111111-1111-4111-8111-111111111111'
    manifest={'lang':lang,'profile_id':p.id,'profile_sha256':p.sha256,'channel':'internal',
        'schema_version':5,'release_id':release,'generation':1,'version':'test','size_bytes':1,
        **{k:'a'*64 for k in ('sha256','pack_json_sha256','pack_canonical_sha256','registry_sha256',
            'history_inventory_sha256','editorial_reviews_sha256')}}
    channel={'release_id':release,'generation':1,'manifest':manifest,'manifest_sha256':digest(manifest)}
    assert channel_binding(channel,lang)['release_id']==release
    broken=copy.deepcopy(channel);broken['manifest']['profile_sha256']='b'*64
    broken['manifest_sha256']=digest(broken['manifest'])
    with pytest.raises(AuthoringError):channel_binding(broken,lang)
