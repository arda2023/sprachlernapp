# POS-Korrektur kopulares „be“ (04.10.2026)

## Konvention

Maßgeblich ist die englische UD-Konvention (https://universaldependencies.org/en/pos/AUX_.html): kopulares „be“ (Zustand, Eigenschaft, Identität, Ort) ist `AUX`; „be“ im Sinn von „existieren“ ist `VERB`. Lernbegriffe wie „Vollverb“ stehen nur in `form_label_de` und sind keine POS-Angabe. Festgehalten in `pipeline/prompts/meanings.md` (`meanings-v5`) und `pipeline/prompts/meaning_check.md` (`meaning-check-v5`). Der POS-Vergleich in `generate.py` bleibt exakt; AUX und VERB werden nicht gleichgesetzt.

Anlass: Pilot 60 v1 (`out/pilot_60_v1.json`). `be#sein_existieren` (be), `be#sein_vollverb` (are, was) waren als `VERB` erfasst; die Prüfung bestimmte kopulares „be“ als `AUX` und verwarf die Sätze mit Grund „Wortart“ (are, was: 0 von 11 angenommen; be: 1 von 11). `is/be#sein_vollverb` war bereits `AUX` und im Pack.

## Änderungen

IDs aus `pipeline/src/sprachpipe/ids.py` (`stable_id`): Lemma = (`lang`, `lemma`, `pos`), Sense = (`lemma_id`, `sense_key`), Karte = (`lang`, `form`, `sense_id`). POS ist damit ID-relevant. `sense_key`, Glosse, `form_label_de`, `usage` und `status` bleiben unverändert.

| Form | sense_key | POS alt → neu | Referenz alt → neu | Karten-ID alt → **neu** | Sense-ID alt → neu | Begründung |
|---|---|---|---|---|---|---|
| are | be#sein_vollverb | VERB → AUX | `are\|be/VERB\|be#sein_vollverb` → `are\|be/AUX\|be#sein_vollverb` | `8de352bb7b769583aa91247dc72c7c44` → **`08470372ea71b7c40444c2b7bc738766`** (neu) | `2f032f6efb4656c2b32b28326304b97b` → `f47c06ceb40b579b5f6c10d8df2ed7c9` (vorhanden) | Kopula; alle Pilotversuche kopular |
| was | be#sein_vollverb | VERB → AUX | `was\|be/VERB\|be#sein_vollverb` → `was\|be/AUX\|be#sein_vollverb` | `c48c461e1f24c588b75a7a1452eadc95` → **`319aa2e30453222cf8a74fad14b00e91`** (neu) | `2f032f6efb4656c2b32b28326304b97b` → `f47c06ceb40b579b5f6c10d8df2ed7c9` (vorhanden) | „Zustand, Eigenschaft oder Identität“ = Kopula |
| be | be#sein_existieren | VERB → AUX | `be\|be/VERB\|be#sein_existieren` → `be\|be/AUX\|be#sein_existieren` | `728c107ed31ac9fbef2b3b5bdde730af` → **`7be993be34e9d87e7156cfc02256dc0f`** (neu) | `07e8c114126849d200cd019beb919aa3` → **`5af96bfad492464f10419c58c90ef7fd`** (neu) | Definition „einen Zustand, eine Eigenschaft oder Identität haben“ = Kopula; der Schlüsselname „existieren“ ist irreführend, bleibt aber stabil |
| be | be#befinden | VERB → AUX | `be\|be/VERB\|be#befinden` → `be\|be/AUX\|be#befinden` | `7194af61bee4d3bae01d152bb82975ae` → **`d2ef9df94be5dd1c9ec9e98860c00764`** (neu) | `494aed038c50e97661be88d7d85479dd` → **`179de4c158262a33f87e98b089c16d0d`** (neu) | „sich an einem bestimmten Ort befinden“ = Ortskopula |

Lemma-IDs: `be/VERB` = `b56c71ceb73b44f873826674dd1c9e1e` (bleibt durch `been/be#besucht` in Gebrauch), `be/AUX` = `729ab2845a0434b10a158d68d718faa3` (vorhanden).

**Vorhandener Ziel-Sense:** `be/AUX|be#sein_vollverb` existiert bereits durch `is` (Glosse „sein (als Vollverb oder Kopula zur Angabe von Zustand, Identität oder Eigenschaft)“). are und was haben denselben `sense_key` und bezeichnen dieselbe kopulare Bedeutung; sie werden dort zusammengeführt. Glossen werden nicht überschrieben: `pack.py` übernimmt für einen Sense die Glosse der ersten Karte, wie bereits bei `be#hilfsverb`.

**Neue IDs:** alle vier Karten-IDs nach der Korrektur sowie die Sense-IDs von `be#sein_existieren` und `be#befinden` unter `be/AUX` sind neue Identitäten. Alte IDs werden nicht wiederverwendet; alte Packs werden nicht umgeschrieben.

**Vorkommen alter IDs:** `out/pilot_pack.json` (3d) enthält `are|be/VERB|be#sein_vollverb`, `was|be/VERB|be#sein_vollverb`, `be|be/VERB|be#sein_existieren` und `be|be/VERB|be#befinden`; `out/pilot_60_v1.json` enthält `be|be/VERB|be#befinden`. Ob diese IDs in einer Datenbank veröffentlicht wurden, ist unbekannt.

**Vor einer Veröffentlichung:** Betroffene alte Zeilen (Karten, ggf. Senses, `deck_cards`, `card_sentences`) müssen gegebenenfalls nach dem bestehenden Tombstone-Vertrag (`docs/content-schema.md`) tombstoniert werden. Lernstände werden nicht automatisch auf neue IDs übertragen. In diesem Schritt keine Datenbankänderung.

**Status-Übersicht:**
- Bereits vorhandener Ziel-Sense: `be/AUX|be#sein_vollverb` (Sense-ID `f47c06ceb40b579b5f6c10d8df2ed7c9`, durch `is` im Pilot-60-Pack). are und was werden diesem Sense zugeordnet.
- Neu: alle vier Karten-IDs (fett) und die Sense-IDs `5af96bfad492464f10419c58c90ef7fd` (`be#sein_existieren`), `179de4c158262a33f87e98b089c16d0d` (`be#befinden`).
- Veröffentlichungsstatus der alten IDs: **ungeklärt**. Keine Tombstones, keine Lernstandsübertragung ausgeführt.

## Definitionspräzisierung `be#sein_vollverb` (04.10.2026)

Redaktionelle Entscheidung: `be#sein_vollverb` bezeichnet kopulares „sein“ (Zustand, Eigenschaft oder Identität). Existentielles „existieren / es gibt“ gehört nicht zu diesem Sense; eine existenzielle Karte wird nicht hinzugefügt.

- `are`, `gloss_de` vorher: „Vollverb / Kopula: existieren oder eine Eigenschaft/Zustand haben“
- `are`, `gloss_de` nachher: „sein (als Kopula zur Angabe von Zustand, Identität oder Eigenschaft)“
- Vergleich: `is` „sein (als Vollverb oder Kopula zur Angabe von Zustand, Identität oder Eigenschaft)“, `was` „sein (Zustand, Eigenschaft oder Identität in der Vergangenheit)“. Alle drei bezeichnen dieselbe kopulare Bedeutung; der Zusatz „in der Vergangenheit“ bei `was` ist formabhängig.
- Unverändert: `sense_key`, `pos` (`AUX`), `translation_de` und `form_label_de` je Form, alle IDs. Die Glosse ist nicht ID-relevant.
- Hinweis: `form_label_de` von `is` lautet „3. Person Singular Präsens“, von `are`/`was` „Verb, …“; das sind Lernanzeigen, keine POS, und bleiben erhalten.

Offline-Absicherung: `pipeline/tests/test_inventory.py` hält die vier alten/neuen Karten-IDs sowie fünf unbetroffene Pilot-Karten-IDs als feste Werte fest (`is|be/AUX|be#sein_vollverb` `b325798ce493fd8ad1968460d3a038ab`, `been|be/VERB|be#besucht` `9571634153cd34d44b188319e007d49b`, `be|be/AUX|be#hilfsverb` `bdac6410e29b305386120132d1a7c724`, `not|not/PART|not#nicht` `05f5c519ff76c3267775f5e763e81c0a`, `which|which/DET|which#determiner_auswahl` `724b9485f87a31b2f761596f955bb2c4`) und leitet sie aus dem aktuellen Inventar mit `stable_id` ab; kein `out/` nötig.

## Gemeldete Konflikte (nicht geändert)

- `are/be#sein_vollverb`: erledigt durch die Definitionspräzisierung oben.
- `been/be#besucht` bleibt `VERB`: „an einem Ort gewesen (besucht, hingereist)“ beschreibt „have been to“ im Sinn von besuchen/reisen, keine reine Ortsangabe. Ob UD dies als Kopula behandelt, ist hier nicht eindeutig entschieden; keine pauschale Umklassifizierung.
- `be#gewesen` („Hilfsverb oder Kopulaverb“) ist bereits `AUX`, keine Änderung.
