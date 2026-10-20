import copy
import io
import json
import zipfile
import pytest
from sprachpipe.authoring_service import AuthoringError, empty_pack
from sprachpipe.editor.exchange import template_delivery, write_zip, read_delivery, archive_entries


def test_template_has_all_250_targets_and_no_invented_content():
    delivery,context=template_delivery(empty_pack('en','English'),250)
    assert len(delivery['expected_target_refs'])==250
    assert [len(x['target_refs']) for x in delivery['selection']['batches']]==[100,100,50]
    assert all(c['form'] is None for c in delivery['add']['cards'])
    assert read_delivery(write_zip(delivery,context),'template.zip','en')==delivery


@pytest.mark.parametrize('name',['../delivery.json','/delivery.json','C:/delivery.json','nested.zip','evil.py'])
def test_zip_rejects_paths_and_executables(name):
    out=io.BytesIO()
    with zipfile.ZipFile(out,'w') as z:z.writestr(name,b'{}')
    with pytest.raises(AuthoringError):archive_entries(out.getvalue())


def test_duplicate_keys_language_and_hash_tampering():
    with pytest.raises(AuthoringError):read_delivery(b'{"format":1,"format":2}','a.json','en')
    delivery,context=template_delivery(empty_pack('en','English'),1)
    with pytest.raises(AuthoringError,match='anderen Lernsprache'):read_delivery(json.dumps(delivery).encode(),'a.json','fr')
    entries=archive_entries(write_zip(delivery,context,include_xlsx=False));entries['delivery.json']+=b' '
    out=io.BytesIO()
    with zipfile.ZipFile(out,'w') as z:
        for n,b in entries.items():z.writestr(n,b)
    with pytest.raises(AuthoringError,match='Hash'):read_delivery(out.getvalue(),'a.zip','en')


def test_existing_roundtrip_cells_become_guarded_revision(tmp_path):
    import copy
    from targeted_fixture import fixture
    from sprachpipe import authoring_service as author
    from sprachpipe.editor.exchange import delivery_for_draft
    from sprachpipe.editor.xlsx import write_workbook,read_workbook
    base=fixture(tmp_path)[0]
    draft={'draft_id':'roundtrip','lang':'en','base':author.base_fingerprint(base),'target_refs':['cut-other'],'operations':[],'add':{}}
    delivery=delivery_for_draft(draft,base)
    assert any(r['ref']=='cut-other' and r['existing_id'] for r in delivery['add']['cards'])
    parsed=read_workbook(write_workbook(delivery),'en')
    assert parsed==delivery
    unchanged=author.resolve_roundtrip(base,parsed)
    assert not unchanged['operations'] and not any(unchanged['add'].values())
    next(r for r in parsed['add']['cards'] if r['ref']=='cut-other')['translation_de']='Konkreter Hinweis'
    next(r for r in parsed['add']['sentences'] if r['ref']=='other-exercise')['translation_de']='Sie kürzen täglich.'
    resolved=author.resolve_roundtrip(base,parsed)
    assert {o['kind'] for o in resolved['operations']}=={'revise_context','set_solution_hint'}
    draft.update(add=resolved['add'],operations=resolved['operations'],revision=1,translation_lang='de')
    result=author.validate_draft(draft,base)
    assert result['technical']=='valid',result
    modified=copy.deepcopy(parsed);modified['add']['cards'][0]['form']='other'
    with pytest.raises(author.AuthoringError,match='Identität'):author.resolve_roundtrip(base,modified)
