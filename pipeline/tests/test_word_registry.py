import copy
import json
from pathlib import Path
import pytest
from sprachpipe.word_registry import load_registry, validate_selection, index_registry, digest


def registry():
    return {'format_version': 1, 'normalization': 'NFC-lower-apostrophe-v1', 'words': [
        {'lang': 'en', 'form_norm': 'table', 'aliases': ['tablè'], 'owner_deck_ref': 'travel', 'primary_card_id': 'exact'}]}


@pytest.mark.parametrize('form', ['table', 'Table', 'TABLE', 'tablè', 'tablè'])
def test_conflict_reports_both_places_and_owner(form):
    with pytest.raises(ValueError, match=r'registry\[0\] owner travel.*selection\[0\] owner work'):
        validate_selection([{'form': form, 'sense': 'different'}], registry(), lang='en', owner='work')


def test_reservation_requires_exact_card_and_owner():
    validate_selection([{'form': 'Table', 'card_id': 'exact'}], registry(), lang='en', owner='travel', allow_reserved=True)
    with pytest.raises(ValueError):
        validate_selection([{'form': 'table', 'card_id': 'other-sense'}], registry(), lang='en', owner='travel', allow_reserved=True)
    validate_selection([{'form': 'table'}], registry(), lang='fr', owner='work')
    validate_selection([{'form': 'tables'}, {'form': 'went'}], registry(), lang='en', owner='work')


def test_duplicates_in_one_selection_and_across_registry():
    with pytest.raises(ValueError, match=r'selection\[0\].*selection\[1\]'):
        validate_selection([{'form': 'bank'}, {'form': 'Bank'}], registry(), lang='en', owner='work')
    r = registry(); r['words'].append(dict(r['words'][0], owner_deck_ref='work'))
    with pytest.raises(ValueError, match='travel.*work'): index_registry(r)


def test_source_is_hash_bound_and_not_mutated(tmp_path):
    r = registry(); before = copy.deepcopy(r)
    p = tmp_path/'registry.json'; p.write_text(json.dumps(r), encoding='utf8')
    assert load_registry(p, expected_hash=digest(r)) == before
    with pytest.raises(ValueError, match='hash'): load_registry(p, expected_hash='0'*64)
    assert r == before


def test_editorial_53_decisions_and_mandatory_primaries():
    r = load_registry(); words = {w['form_norm']: w for w in r['words']}
    assert len(words) == 160
    assert sum(len(w['sense_card_ids']) > 1 for w in words.values()) == 53
    assert sum(len(w['sense_card_ids']) for w in words.values()) == 264
    for form, key in {'like':'like#moegen', 'so':'so#so_sehr', 'will':'will#zukunft',
                      'the':'the#bestimmter_artikel', 'and':'and#und', 'can':'can#koennen',
                      'time':'time#zeit', 'in':'in#in_raeumlich', 'of':'of#genitiv_besitz', 'they':'they#sie_plural'}.items():
        assert words[form]['sense_key'] == key
    assert all(w['reason'] and w['primary_card_id'] in w['sense_card_ids'] for w in words.values())
