"""Reuse the existing sentence fixture; no new authored corpus."""
import copy
import pytest
from test_content_contract import fixture
from import_editorial_patch import create_content
from sprachpipe.pack import build_rows


@pytest.mark.parametrize('failure', [None, 'missing', 'unknown_head', 'wrong_group'])
def test_create_preserves_schema3_and_requires_resolvable_learning(failure):
    source, entry, registry, sha = fixture()
    source['release']['schema_version'] = 3
    cid = registry['words'][0]['primary_card_id']
    learning = {'group_id': 'en:card:'+cid, 'primary_card_id': cid,
                'topic': 'pets', 'related': [], 'note': 'Independent target.'}
    entry['add']['cards'][0]['learning'] = learning
    if failure == 'missing': del entry['add']['cards'][0]['learning']
    if failure == 'unknown_head': learning['primary_card_id'] = 'missing'
    if failure == 'wrong_group': learning['group_id'] = ''
    before = copy.deepcopy(source)
    if failure:
        with pytest.raises(ValueError, match='learning'):
            create_content(source, entry, registry, source_hash=sha)
    else:
        result = create_content(source, entry, registry, source_hash=sha)
        assert result['release']['schema_version'] == 3
        assert build_rows(result)['cards'][0]['learning'] == learning
        # Follow-up create with no new content must preserve existing groups too.
        from sprachpipe.word_registry import digest
        next_registry = dict(registry, version='followup', parent_sha256=digest(registry))
        followup = dict(entry, version='followup', registry_sha256=digest(next_registry), add={}, reviews=[])
        second = create_content(result, followup, next_registry, source_hash=sha)
        assert second['cards'] == result['cards']
    assert source == before
