# Essen & Trinken: Batch 2 offline importiert

Stand: 10.10.2026. Genau 83 neue Ziele mit je einem festen Satz intern gestagt. Jetzt 167 Essen-Ziele und 1796 primäre Lernziele insgesamt: 160/489/241/245/245/249/167.

## Redaktionelle Entscheidungen

Alle 83 Satzpaare, 971 Tokenpositionen (886 Worttoken, 85 Satzzeichen), neue Sense-Definitionen und Wörterbuchformen gegengelesen und gegen den Import abgeglichen. Kein belegter Lieferfehler: Original unverändert importiert, keine Korrekturkopie nötig.

Geprüft: sardine/tin Konservendose gegenüber pit/tin Backform; beide früheren tin-Korrekturen erhalten. rosemary/parchment tray Backblech gegenüber Ziel tray Tablett. curd Käsebruch, whey Molke; still ohne Kohlensäure gegenüber undercooked/still noch. stone Fruchtkern, flesh Fruchtfleisch, stalks Pflanzenstiele, centre/middle Inneres/Mitte. chips Pommes, bland/pepper Pfeffer, stuff/peppers Paprika. serving servieren; crumb/brush wegwischen; finish beenden; parchment/stop verhindern; sticking anhaften. blender/after nachdem; inside innen/darin; spatula/over Wendepartikel; drain/back zurück. chewy/has und waffle/had Vollverben; wheat/is und wholemeal/was Hilfsverben. crushed zerdrückt/zerstoßen, filled füllte/gefüllt, squares quadratische Waffelvertiefungen.

Vier Alternativen wörtlich geprüft:

- Emma folded the omelet around the mushrooms before serving it.
- Lina chopped a red chili and added it to the sauce.
- Let the sugar caramelize in the pan before adding the cream.
- Omar cut a zucchini into thin slices for the pan.

accepted bleibt ausschließlich die jeweilige Zielform. Alternativen bleiben lernstandsneutral, Aliasreservierungen geben keine Antworten automatisch frei. Keine pauschalen Altglossenänderungen.

## Import und Bestandsschutz

Basisdateien rohbytegebunden, Registry/Gruppen kanonisch, Liefermanifest und Review-/Displayhashes geprüft. Aktuelle Projektquellen verwendet; keine Referenzquellen zurückkopiert. Neue Mitgliedschaften 85–167, danach ausschließlich gelieferter hashgebundener Display-Patch auf Essen-Positionen 1–167. Originalpositionen unverändert.

Alle 1828 bisherigen Karten, Satztexte, Annotationen, Lerngruppen und historischen Zeilen erhalten; nur autorisierte Essen-Anzeigepositionen verändert. Reservierte Identitäten, Definitionen, cards.learning, Besitzer und Aliase geprüft. Keine Batch-3-Karten vorgezogen; Begleitwort-Senses bleiben Wörterbucheinträge.

Vollständiger Abgleich aller 18 SQLite-Tabellen gegen build_rows: 1911 Karten, 2445 Satztexte, 2439 historische Verknüpfungen, 1807 Wortbesitzzeilen. Linter 0 Fehler und zehn Häufigkeitshinweise: curd/cheesemaker 1.67, oat/flakes 3.38, rosemary/sprig 2.43, mint/jug 3.30, cappuccino/croissant 2.78, cinnamon/sprinkled 3.39, spatula/pancake 3.35, kale/stalks 3.46, blender/rinsed 3.48, refill/jug 3.30. Keine Umformulierung nur wegen dieser Hinweise.

## Sicherung und Staging

Assets und Manifest wurden vor Staging nach build/essen_batch_2_checks/backup/assets/content/en/ kopiert und gegen die Ausgangsbaseline geprüft. Erst nach erfolgreichem separatem Vorbereitungsschritt wurde gestagt. backup-proof.json dokumentiert Zeit und Hashes. Konkrete Versionsprüfung im real_pack_test ergänzt; keine App- oder Pipelineänderung.

Asset-Verifikation, Siebenstapel-Lesetest, Flutter-Analyse sowie 123 Pipeline-Tests und 19 Untertests bestanden. Der zusätzliche einmalige Auditskript-Fehler war ein KeyError bei einem historischen Sense ohne definition_de; der Vergleich nutzt jetzt get und prüft exakt gegen den reservierten Nullwert. Keine Inhaltsänderung oder Validatorlockerung. Erst der erfolgreiche Audit ging der Sicherung und dem Staging voraus. Erstversuch in audit-first-attempt.log erhalten.

## Batch 3

Vorhandener Fortsetzungs-Exporter erzeugte separate Auswahl-/Registry-/Gruppen-Snapshots essen_trinken_batch_3_context_v1 aus dem tatsächlich geprüften Pack. Alle 250 Originalidentitäten exakt enthalten; Partition 167 importiert / 83 aktuell / 0 später. Nächster Import hängt 168–250 an und ordnet anhand der Originalauswahl hashgebunden auf 1–250 um. Keine neuen Batch-3-Sätze erzeugt.

ZIP geschlossen und neu geöffnet: CRCs, 82 Manifesthashes für 83 Dateien, Referenzen, Identitäten und alle 18 SQLite-Tabellen geprüft. Ohne Überschreiben an endgültigen Ort verschoben und dort nochmals vollständig geprüft.

Absoluter ZIP-Pfad: /Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/essen_trinken_authoring_batch_3.zip

## Tatsächliche Prüfoutputs

Logs und Hilfsskripte: build/essen_batch_2_checks/. Python auf macOS Terminal: pipeline/.venv-macos/bin/python; Windows PowerShell: .\pipeline\.venv\Scripts\python.exe. Dart-, Flutter- und Git-Befehle sind identisch. Verifier mit --repo ., Import mit Originaleditorial und Display-Patch; Fortsetzung mit --selection pipeline/data/selection/essen_trinken_v1.json --batch 3 --prepare-continuation essen_trinken_batch_3_context_v1. ZIP-Verifikation jeweils mit --verify-zip. Konkrete Importpfade stehen im Benutzerauftrag; keine Importkopie verwendet.

### verifier.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 85..167, final display 1..167; original registry positions preserved
PASS create_content/build_rows: 1911 cards; 1796 primary goals (160/489/241/245/245/249/167); 18 tables
PASS 83 reserved identities, display 1..167; 1828 old IDs and all historical rows preserved
PASS 971 token positions; four reviewed alternatives; linter 0 errors, 10 warnings
WARNINGS [["curd", "i+1", "'cheesemaker'/'cheesemaker' Zipf 1.67 below 3.5"], ["oat", "i+1", "'flake'/'flakes' Zipf 3.38 below 3.5"], ["rosemary", "i+1", "'sprig'/'sprig' Zipf 2.43 below 3.5"], ["mint", "i+1", "'jug'/'jug' Zipf 3.30 below 3.5"], ["cappuccino", "i+1", "'croissant'/'croissant' Zipf 2.78 below 3.5"], ["cinnamon", "i+1", "'sprinkle'/'sprinkled' Zipf 3.39 below 3.5"], ["spatula", "i+1", "'pancake'/'pancake' Zipf 3.35 below 3.5"], ["kale", "i+1", "'stalk'/'stalks' Zipf 3.46 below 3.5"], ["blender", "i+1", "'rinse'/'rinsed' Zipf 3.48 below 3.5"], ["refill", "i+1", "'jug'/'jug' Zipf 3.30 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access

Exit 0
```

### import.log

```text
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 3075,
    "senses": 4483,
    "cards": 1911,
    "dictionary_forms": 5238,
    "decks": 7,
    "deck_cards": 1911,
    "deck_words": 1807,
    "word_aliases": 33,
    "sentences": 2445,
    "sentence_tokens": 27180,
    "card_sentences": 2439,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "d785cfb50faed8fe66227efad8b4c0a7e6e9ba41d486988f18aae0531a96684e"
}

Exit 0
```

### audit.log

```text
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 3075, 'senses': 4483, 'cards': 1911, 'dictionary_forms': 5238, 'decks': 7, 'deck_cards': 1911, 'deck_words': 1807, 'word_aliases': 33, 'sentences': 2445, 'sentence_tokens': 27180, 'card_sentences': 2439, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 167 original identities, definitions, learning groups, owners and fixed sentences; partition 167/83/0
PASS 1828 historical cards and all old content preserved, except authorized Essen display positions; all Batch-1 corrections retained
ALTERNATIVE Emma folded the omelet around the mushrooms before serving it.
ALTERNATIVE Lina chopped a red chili and added it to the sauce.
ALTERNATIVE Let the sugar caramelize in the pan before adding the cream.
ALTERNATIVE Omar cut a zucchini into thin slices for the pan.
PASS reviewed reading/annotation documents exactly match all 83 sentences and 971 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 245
DECK koerper-gesundheit 249
DECK essen-trinken 167
PACK_SHA256 ea3e5521b179a5b412ceefdbc80a71a739becf513b1c3edb04c565715d006adc
SQLITE_SHA256 d785cfb50faed8fe66227efad8b4c0a7e6e9ba41d486988f18aae0531a96684e
PASS future cards absent; reserved future senses exact; both old tin corrections preserved
NEW_TOKEN_COUNTS 886 word tokens 85 punctuation

Exit 0
```

### pytest.log

```text
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 0.95s

Exit 0
```

### prepare-stage.log

```text
PASS backup BEFORE staging: {"verified_before_staging_utc": "2026-10-10T12:01:02.560057+00:00", "files": {"assets/content/en/content.sqlite": "1c6a0e1d5ca182a0cc30405f541b25120d8bb887d317f627aabc324c56733e92", "assets/content/en/content.manifest.json": "00067ac8f58cbf64d407a02975aed42e15f7ecb6291dc4dc1299f69bcc2689ef"}}
PASS exact seven-deck test expectations added; existing bytes preserved

Exit 0
```

### stage.log

```text
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version essen_trinken_batch_2_v1, schema 3, 13234176 bytes
  sha256 d785cfb50faed8fe66227efad8b4c0a7e6e9ba41d486988f18aae0531a96684e
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
```

### stage-verify.log

```text
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version essen_trinken_batch_2_v1, schema 3, 13234176 bytes
  sha256 d785cfb50faed8fe66227efad8b4c0a7e6e9ba41d486988f18aae0531a96684e
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
```

### flutter-test.log

```text
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
deck allgemeine-sprache: 160 learning targets, 160 ownership cards, 160 fixed sentence assignments verified
deck reisen: 489 learning targets, 500 ownership cards, 500 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 241 ownership cards, 241 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck menschen-beziehungen: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck koerper-gesundheit: 249 learning targets, 249 ownership cards, 249 fixed sentence assignments verified
deck essen-trinken: 167 learning targets, 167 ownership cards, 167 fixed sentence assignments verified
pack essen_trinken_batch_2_v1 (schema 3, internal: true); 7 decks: 1807 cards, 1911 card sentences, 133 with valid_alternatives, 1911 cards in the pack
00:09 +1: All tests passed!

Exit 0
```

### flutter-analyze.log

```text
Analyzing sprachapp...
No issues found! (ran in 1.8s)

Exit 0
```

### continuation.log

```text
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/essen_trinken_batch_3_context_v1.json",
    "registry": "pipeline/data/words/en.essen_trinken_batch_3_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.essen_trinken_batch_3_context_v1.json"
  },
  "partition_counts": {
    "imported": 167,
    "current": 83,
    "future": 0
  }
}

Exit 0
```

### verify-batch-3-final.log

```text
{
  "zip_verification": "PASS",
  "zip_sha256": "265f3907bf08843b0d9008c9682feb770c9018c4fc211bd09fe9245ec8f1008b",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 1911,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 250,
  "excluded": 83,
  "partition_counts": {
    "imported": 167,
    "current": 83,
    "future": 0
  },
  "reused_proposed_senses": 5,
  "batches": {
    "1": 84,
    "2": 83,
    "3": 83
  },
  "topics_per_batch": {
    "1": {
      "Obst, Gemüse und Hülsenfrüchte": 14,
      "Kochen, Backen und Küchenhandlungen": 12,
      "Gewürze, Zutaten und Würzmittel": 11,
      "Milchprodukte, Eier, Fleisch und Fisch": 11,
      "Getreide, Brot und Backwaren": 11,
      "Mahlzeiten, Geschmack und Essenssituationen": 10,
      "Getränke und Getränkezubereitung": 8,
      "Küchenutensilien, Geschirr und Aufbewahrung": 7
    },
    "2": {
      "Obst, Gemüse und Hülsenfrüchte": 13,
      "Milchprodukte, Eier, Fleisch und Fisch": 12,
      "Getreide, Brot und Backwaren": 11,
      "Kochen, Backen und Küchenhandlungen": 11,
      "Gewürze, Zutaten und Würzmittel": 11,
      "Mahlzeiten, Geschmack und Essenssituationen": 9,
      "Getränke und Getränkezubereitung": 8,
      "Küchenutensilien, Geschirr und Aufbewahrung": 8
    },
    "3": {
      "Obst, Gemüse und Hülsenfrüchte": 13,
      "Gewürze, Zutaten und Würzmittel": 12,
      "Milchprodukte, Eier, Fleisch und Fisch": 11,
      "Getreide, Brot und Backwaren": 11,
      "Kochen, Backen und Küchenhandlungen": 11,
      "Mahlzeiten, Geschmack und Essenssituationen": 9,
      "Getränke und Getränkezubereitung": 8,
      "Küchenutensilien, Geschirr und Aufbewahrung": 8
    }
  },
  "existing_senses": 19,
  "new_senses": 231,
  "existing_cards": 1911,
  "existing_groups": 1899,
  "new_groups": 83,
  "registry_words": 1890,
  "partition_selection": "PASS: 167 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}

Exit 0
```

## SHA256 (Rohbytes)

| Datei | SHA256 |
|---|---|
| pipeline/out/essen_trinken_batch_1_v1/pack.json | `30aedf52b01a6cb755ac7845569a306d3cdeb9df03ebe2e0c539cdbf57e2e755` |
| pipeline/out/essen_trinken_batch_1_v1/content.sqlite | `1c6a0e1d5ca182a0cc30405f541b25120d8bb887d317f627aabc324c56733e92` |
| essen_trinken_batch_2/essen_trinken_batch_2.editorial.json | `a150f9d224e2e27ebddd8f6bb9e76ed092c4b9f76c3e649c196a64b3acd2f9df` |
| essen_trinken_batch_2/essen_trinken_batch_2.display.json | `04b589f7fd655c36b31c991febc980625bfe7cdc5a24ece57bf08e2e1f6f5348` |
| essen_trinken_batch_2/manifest.json | `5666aba442a7cd7eef1759e8576c8c2c1be85905ba7ebdd301b935e86f274ed5` |
| pipeline/out/essen_trinken_batch_2_v1/pack.json | `ea3e5521b179a5b412ceefdbc80a71a739becf513b1c3edb04c565715d006adc` |
| pipeline/out/essen_trinken_batch_2_v1/content.sqlite | `d785cfb50faed8fe66227efad8b4c0a7e6e9ba41d486988f18aae0531a96684e` |
| assets/content/en/content.sqlite | `d785cfb50faed8fe66227efad8b4c0a7e6e9ba41d486988f18aae0531a96684e` |
| assets/content/en/content.manifest.json | `90b28e6d45d2737635d9f7f1ab0952b36136bd8e5e5bd0179693e370266aa2d4` |
| build/essen_trinken_authoring_batch_3.zip | `265f3907bf08843b0d9008c9682feb770c9018c4fc211bd09fe9245ec8f1008b` |
| pipeline/data/selection/essen_trinken_batch_3_context_v1.json | `5542ba3b73d533938cde2c52cebe84c8eaa787f7005ee897e49709ee35a2db53` |
| pipeline/data/words/en.essen_trinken_batch_3_context_v1.json | `3066fa03d197135855ed1d7aa2a61e6dcd3991ebd626f3a3cfd698c6ec8bb07f` |
| pipeline/data/learning_groups/en.essen_trinken_batch_3_context_v1.json | `a36ff7d622afcc428fbc36cd4877aff680cf9cb7ebc3e8413c40231147d73dbe` |

## Arbeitsbaum und Grenzen

Baseline mit 2333 Dateien; ausschließlich vier vorhandene Dateien dürfen sich ändern: Asset, Manifest, test/data/real_pack_test.dart und NEXTSTEPS.md. Neu: Pack, drei Kontextsnapshots, ZIP und Bericht. Abschließender Nachweis: final-protection.json und final-checks.log; Git-Status davor/danach gespeichert.

Bekannte CRLF-/Whitespace-Altbefunde separat: git diff --check Exit 2; CRLF-tolerant sieben Stellen in DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127 und docs/arbeit-bildung-batch-2-import.md:121. Eigene Änderungen separat geprüft; keine globale Bereinigung. Große Rohlogs gzip-komprimiert.

Keine echte user.db/review_log geöffnet oder verändert; keine Cloud-/Modellaufrufe, Veröffentlichung, Commits oder Pushes. Keine App-/SRS-/Synonym-/Modell-/Budget-/Supabase-/Plattformänderung. Offen: Redaktion der letzten 83 Ziele und Geräteprüfung. Keine ungeklärte Inhaltsbindung dieses Imports.

## Abschließender Nachweis

```text
BASELINE 2333 UNCHANGED 2329 CHANGED ['NEXTSTEPS.md', 'assets/content/en/content.manifest.json', 'assets/content/en/content.sqlite', 'test/data/real_pack_test.dart']
git-diff-check Exit 2 bytes 322643551 lines 6399218
git-diff-check-crlf Exit 2 bytes 717 lines 14
DESIGN.md:162: trailing whitespace.
+**Display/Headline Font:** Source Serif 4 (serif fallback)
DESIGN.md:163: trailing whitespace.
+**Body Font (stories/sentences):** Source Serif 4
DESIGN.md:164: trailing whitespace.
+**UI/Label Font (chrome/navigation/stats):** Figtree (sans-serif fallback)
docs/alltag-zuhause-continuation.md:148: trailing whitespace.
+Author:
docs/alltag-zuhause-continuation.md:153: trailing whitespace.
+Required-by:
docs/arbeit-bildung-batch-1-import.md:127: trailing whitespace.
+Analyzing sprachapp...
docs/arbeit-bildung-batch-2-import.md:121: trailing whitespace.
+Analyzing sprachapp...
git status --short Exit 0
PASS own whitespace checks (wrapper Exit 0)
PASS original delivery, historical packs, original selections/registries/groups and app/pipeline code unchanged

Exit 0
```

Zusätzliche ZIP-Prüfung: append_position exakt 168–250, 250 kombinierte Zeilen. Der Hilfsbericht prüfte zunächst fälschlich den Feldnamen position; nach Abgleich mit dem tatsächlichen Schema erfolgreich erneut geprüft. ZIP und Produktdaten waren unverändert. NEXTSTEPS: 24 Zeilen.
