import copy
import hashlib
import json
import sqlite3
import pytest
from sprachpipe.learning_groups import apply_learning_groups, validate_learning
from sprachpipe.pack import build_rows
from sprachpipe.export import export_sqlite
from test_content_contract import pack


def fixture():
    value = pack()
    data = json.dumps(value).encode()
    cards = build_rows(value)['cards']
    registry = {'version': 'en.learning_groups.v1',
        'source_pack_sha256': hashlib.sha256(data).hexdigest(),
        'cards': [dict(card_ref=c['ref'], card_id=r['id'], primary_card_ref=c['ref'],
            primary_card_id=r['id'], group_id='fixture', topic='animals', related=[], note='Own target')
            for c, r in zip(value['cards'], cards)]}
    return data, registry


def test_extension_preserves_ids_sentences_ownership_and_sqlite_contract(tmp_path):
    data, registry = fixture()
    before = json.loads(data)
    after = apply_learning_groups(data, registry)
    assert after['release']['schema_version'] == 3
    for table in ('sentences','sentence_tokens','card_sentences','deck_cards','deck_words','word_aliases'):
        assert after.get(table) == before.get(table)
    assert [r['id'] for r in build_rows(before)['cards']] == [r['id'] for r in build_rows(after)['cards']]
    path = tmp_path/'content.sqlite'
    export_sqlite(after,path)
    with sqlite3.connect(path) as db:
        values = [json.loads(r[0]) for r in db.execute('select learning from cards')]
    assert values == [c['learning'] for c in after['cards']]
    assert data == json.dumps(before).encode()


@pytest.mark.parametrize('mutation', ['hash','missing','duplicate','card_id','primary','empty','related','cycle'])
def test_bad_extension_rejected_before_export(mutation):
    data, registry = fixture()
    e = registry['cards'][0]
    if mutation == 'hash': registry['source_pack_sha256'] = '0'*64
    if mutation == 'missing': registry['cards'].clear()
    if mutation == 'duplicate': registry['cards'].append(copy.deepcopy(e))
    if mutation == 'card_id': e['card_id'] = 'wrong'
    if mutation == 'primary': e['primary_card_id'] = 'missing'
    if mutation == 'empty': e['group_id'] = ''
    if mutation == 'related': e['related'] = ['x','x']
    if mutation == 'cycle': e['primary_card_ref'] = 'unknown'
    with pytest.raises((ValueError, KeyError)):
        apply_learning_groups(data,registry)


def test_group_cannot_have_two_heads_or_cross_language_members():
    def card(id, head='a', lang='en'):
        return dict(id=id,lang=lang,learning=dict(group_id='g',primary_card_id=head,topic='t',related=[],note='r'))
    validate_learning([card('a'),card('b')])
    with pytest.raises(ValueError): validate_learning([card('a'),card('b','b')])
    with pytest.raises(ValueError): validate_learning([card('a'),card('b',lang='de')])


def test_checked_in_editorial_registry_is_complete_and_precise():
    from pathlib import Path
    registry=json.loads((Path(__file__).parents[1]/'data/learning_groups/en.v1.json').read_text(encoding='utf-8'))
    entries=registry['cards']
    assert len({e['card_id'] for e in entries}) == len(entries) == 764
    primary={e['card_ref'].split('|')[0]:e for e in entries if e['was_primary']}
    for group in [('trip','travel','journey'),('luggage','baggage'),('backpack','rucksack'),('excursion','outing'),('rent','hire'),('booking','reservation'),('book','reserve'),('landscape','scenery')]:
        assert {primary[w]['primary_card_id'] for w in group} == {primary[group[0]]['card_id']}
    for a,b in [('shade','shadow'),('a','an'),('be','was'),('have','had'),('close','fasten')]:
        assert primary[a]['group_id'] != primary[b]['group_id']
    assert sum(e['was_primary'] and e['card_id']==e['primary_card_id'] for e in entries)==649
