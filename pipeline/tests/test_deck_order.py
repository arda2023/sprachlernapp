from sprachpipe.pack import assemble_pack, build_rows


def card(form, key, rank, usage, index, band):
    accepted = []
    slots = []
    for n in range(1):
        text = f"{form}."
        gap = (0, len(form))
        a = {"text": text, "translation_de": "x", "gap": gap, "qa_status": "ok",
             "lint": [], "blind": "passed", "blind_answer": form,
             "tokens": [{"idx":0,"start_pos":0,"end_pos":len(form),"surface":form,"lemma":form,"pos":"VERB","gloss_de":key,"card":True},{"idx":1,"start_pos":len(form),"end_pos":len(form)+1,"surface":"."}], "meaning_check": key}
        accepted.append(a)
        slots.append([a])
    return {"form": form, "lemma": form, "pos": "VERB", "sense_key": key,
            "gloss_de": key, "form_kind": "base", "form_label_de": "Verb",
            "translation_de": key, "cefr_band": band, "rank": rank,
            "usage": usage, "sense_index": index, "accepted": accepted, "slots": slots}


def test_deck_positions_use_weighted_rank_then_inventory_order():
    cards = [card("alpha", "a#one", 10, "neben", 1, "anfaenger"),
             card("beta", "b#one", 150, "haupt", 1, "mittel"),
             card("gamma", "g#one", 250, "haupt", 1, "mittel")]
    pack = assemble_pack("en", cards, model="fake", version="test")
    assert pack["decks"][0]["cefr_band"] == "mittel"
    by_ref = {c["ref"]: c["form"] for c in pack["cards"]}
    assert [by_ref[d["card"]] for d in pack["deck_cards"]] == ["beta", "alpha", "gamma"]
    assert [d["position"] for d in pack["deck_cards"]] == [1, 2, 3]
    assert len(build_rows(pack)["deck_cards"]) == 3
