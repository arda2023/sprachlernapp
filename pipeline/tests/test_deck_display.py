"""Offline reference tests, only synthetic data and Python standard library."""
import copy
import unittest
from sprachpipe.deck_display import apply_deck_display_patch, canonical_sha256


def fixture():
    pack = {
        'decks': [{'ref': 'reisen'}, {'ref': 'other'}],
        'deck_cards': [{'deck': 'other', 'card': 'outside', 'position': 1}],
        'deck_words': [{'deck': 'other', 'primary_card': 'outside', 'form_norm': 'outside', 'position': 1}],
        'sentences': [{'ref': 'existing', 'text': 'Keep this sentence.'}],
        'cards': [{'ref': k, 'unchanged': True} for k in ['a', 'b', 'c', 'd']],
        'word_registry': {'words': [{'form_norm': 'a', 'position': 1}, {'form_norm': 'b', 'position': 26}]},
        'release': {'version': 'test'},
    }
    originals = [1, 26, 6, 31]
    for pos, card in enumerate('abcd', 1):
        pack['deck_cards'].append({'deck': 'reisen', 'card': card, 'position': pos})
        pack['deck_words'].append({'deck': 'reisen', 'primary_card': card, 'form_norm': card, 'position': pos})
    rows = [{'card_ref': c, 'form_norm': c, 'original_position': original,
             'expected_position': pos, 'position': [1, 3, 2, 4][pos - 1]}
            for pos, (c, original) in enumerate(zip('abcd', originals), 1)]
    patch = {'format': 'sprachapp.deck-display-patch', 'format_version': 1,
             'operation_id': 'test', 'deck': 'reisen', 'source_sha256': 'a'*64,
             'create_sha256': 'b'*64, 'registry_sha256': 'c'*64,
             'expected_before_sha256': {k: canonical_sha256([r for r in pack[k] if r['deck'] == 'reisen'])
                                        for k in ['deck_cards', 'deck_words']}, 'rows': rows}
    hashes = {'source_sha256': 'a'*64, 'create_sha256': 'b'*64, 'registry_sha256': 'c'*64}
    pack['lang'] = 'en'
    snapshot = {'format_version': 1, 'normalization': 'NFC-lower-apostrophe-v1',
                'words': [{'lang': 'en', 'form_norm': r['form_norm'], 'owner_deck_ref': 'reisen',
                           'primary_card_ref': r['card_ref'], 'position': r['original_position']}
                          for r in rows]}
    pack['word_registry'] = {'snapshot': snapshot, 'sha256': canonical_sha256(snapshot)}
    patch['registry_sha256'] = hashes['registry_sha256'] = canonical_sha256(snapshot)
    return pack, patch, hashes


class DisplayPatchTests(unittest.TestCase):
    def test_only_positions_change_and_inputs_are_unchanged(self):
        pack, patch, hashes = fixture()
        originals = copy.deepcopy((pack, patch, hashes))
        out = apply_deck_display_patch(pack, patch, **hashes)
        self.assertEqual((pack, patch, hashes), originals)
        self.assertEqual([r['card'] for r in sorted(out['deck_cards'][1:], key=lambda r: r['position'])], list('acbd'))
        for table in ['deck_cards', 'deck_words']:
            for row, old in zip(out[table], pack[table]):
                if row['deck'] == 'reisen':
                    self.assertEqual({k:v for k,v in row.items() if k != 'position'},
                                     {k:v for k,v in old.items() if k != 'position'})
                else:
                    self.assertEqual(row, old)
            for row, old in zip(out[table], pack[table]):
                row['position'] = old['position']
        self.assertEqual(out, pack)

    def test_wrong_input_hashes_fail(self):
        for field in ['source_sha256', 'create_sha256', 'registry_sha256']:
            with self.subTest(field=field):
                pack, patch, hashes = fixture(); hashes[field] = 'd'*64
                with self.assertRaises(ValueError): apply_deck_display_patch(pack, patch, **hashes)

    def test_changed_input_rows_fail_without_mutation(self):
        for table in ['deck_cards', 'deck_words']:
            with self.subTest(table=table):
                pack, patch, hashes = fixture(); pack[table][1]['position'] = 99
                before = copy.deepcopy(pack)
                with self.assertRaises(ValueError): apply_deck_display_patch(pack, patch, **hashes)
                self.assertEqual(pack, before)

    def test_bad_mappings_fail(self):
        mutations = [
            lambda p: p['rows'].pop(),
            lambda p: p['rows'].append(copy.deepcopy(p['rows'][0])),
            lambda p: p['rows'][0].update(position=9),
            lambda p: p['rows'][0].update(position=True),
            lambda p: p['rows'][0].update(original_position=26),
            lambda p: p['rows'][0].update(expected_position=99),
            lambda p: p['rows'][0].update(card_ref='outside'),
            lambda p: p['rows'][0].update(form_norm='wrong'),
            lambda p: p['rows'][0].update(extra='ignored'),
            lambda p: p.update(extra='ignored'),
            lambda p: p.update(deck='missing'),
            lambda p: p.update(rows=[]),
            lambda p: p.update(format_version=True),
            lambda p: p['expected_before_sha256'].update(extra='x'),
        ]
        for i, mutate in enumerate(mutations):
            with self.subTest(case=i):
                pack, patch, hashes = fixture(); mutate(patch)
                before = copy.deepcopy(pack)
                with self.assertRaises(ValueError): apply_deck_display_patch(pack, patch, **hashes)
                self.assertEqual(pack, before)

    def test_wrong_dense_order_fails(self):
        pack, patch, hashes = fixture()
        for row in patch['rows']: row['position'] = row['expected_position']
        with self.assertRaises(ValueError): apply_deck_display_patch(pack, patch, **hashes)

    def test_repeat_application_fails(self):
        pack, patch, hashes = fixture()
        result = apply_deck_display_patch(pack, patch, **hashes)
        with self.assertRaises(ValueError): apply_deck_display_patch(result, patch, **hashes)


if __name__ == '__main__':
    unittest.main()


def test_original_positions_cannot_be_forged_even_with_consistent_order():
    pack, patch, hashes = fixture()
    for row in patch['rows']:
        row['original_position'] += 1000
    import pytest
    with pytest.raises(ValueError, match='registry identity/position'):
        apply_deck_display_patch(pack, patch, **hashes)


def test_full_200_word_order():
    pack, patch, hashes = fixture()
    originals = [x for block in range(0, 500, 25) for x in range(block+1, block+6)]
    originals += [x for block in range(0, 500, 25) for x in range(block+6, block+11)]
    order = {n:i for i,n in enumerate(sorted(originals),1)}
    pack['deck_cards'] = pack['deck_cards'][:1]
    pack['deck_words'] = pack['deck_words'][:1]
    patch['rows'] = []
    snapshot = pack['word_registry']['snapshot']; snapshot['words'] = []
    for pos, original in enumerate(originals,1):
        card = f'card-{original}'
        pack['deck_cards'].append({'deck':'reisen','card':card,'position':pos})
        pack['deck_words'].append({'deck':'reisen','primary_card':card,'form_norm':card,'position':pos})
        snapshot['words'].append({'lang':'en','form_norm':card,'owner_deck_ref':'reisen','primary_card_ref':card,'position':original})
        patch['rows'].append({'card_ref':card,'form_norm':card,'original_position':original,'expected_position':pos,'position':order[original]})
    patch['registry_sha256'] = hashes['registry_sha256'] = canonical_sha256(snapshot)
    patch['expected_before_sha256'] = {t:canonical_sha256(pack[t][1:]) for t in ['deck_cards','deck_words']}
    before = copy.deepcopy(pack)
    result = apply_deck_display_patch(pack, patch, **hashes)
    assert pack == before
    assert [r['card'] for r in sorted(result['deck_cards'][1:],key=lambda r:r['position'])] == [f'card-{n}' for n in sorted(originals)]
    assert sum(a['position']!=b['position'] for a,b in zip(pack['deck_cards'][1:101],result['deck_cards'][1:101])) == 95
