"""Offline reference tests, only synthetic data and Python standard library."""
import copy
import unittest
from deck_display_patch import apply_deck_display_patch, canonical_sha256


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
