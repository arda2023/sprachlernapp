# Natur & Umwelt: Batch 1 offline importiert

Stand: 10.10.2026. Genau 81 Ziele mit je einem aktiven festen Satz offline importiert und intern gestagt. Ein neuer Stapel natur-umwelt mit Anzeigepositionen 1–81; insgesamt 1960 primäre Lernziele in acht Stapeln: 160/489/241/245/245/249/250/81. Der verbindliche Abschlussplan mit genau 14 Stapeln bleibt maßgeblich; keine weiteren Kategorien oder Verbenstapel vorbereitet.

## Redaktionelle Prüfung

Alle 81 englisch-deutschen Satzpaare, 915 Tokenpositionen (829 Worttoken, 86 Satzzeichen einschließlich des Genitivapostrophs in animals'), neuen Sense-Definitionen und Formglossen vollständig gegengelesen. reading.json und das korrigierte annotation_review.txt stimmen vollständig mit dem tatsächlichen Import überein. Satzzeichen sind ohne Wortbedeutung, Lemma und Karte. Die vorhandenen festen Wendungen picked up, looking for, rather than, turn off und blow out sind als Ganzes verständlich; ihre vorhandenen Glossen/POS werden nicht pauschal umgeschrieben.

Besonders geprüft: Frosch/bank Ufer, rust/iron Metall, overflow/bath Badewanne. gas/heat Gebäude beheizen gegenüber solar/heat Wasser erhitzen. petal/branch fell physisches Fallen gegenüber sleet/fell Temperatur sinkt. root/growing wachsen gegenüber fertile/growing und greenhouse/grows anbauen. nest/pollution/poaching has Hilfsverb gegenüber mainland/steel has Besitz. extinction/save retten gegenüber hibernate/save Ressourcen sparen. hire Personal einstellen; bills Rechnungen; panels Solarmodule; nutrients Pflanzennährstoffe; ground feste Bodenoberfläche gegenüber soil Pflanzenschicht. most überwiegende Menge, enough Mengenangabe, just before kurz vor. mosquito/me mich und by Mittel gegenüber stem/by Anfassstelle. guards Wächter/Wildhüter; plastic in brittle ein Nomen; drinking bei water eine nominale Zweckangabe. Kopula, Hilfsverb und existenzielles be wurden kontextbezogen geprüft.

Einzige Alternative wörtlich eingesetzt:

> This fertilizer gives the plants the nutrients they need.

Die amerikanische Schreibweise bewahrt Satz und Bedeutung. accepted bleibt ausschließlich fertiliser. Alternative satzbezogen und lernstandsneutral; Besitzalias allein ist keine Antwortfreigabe. Keine weitere Alternative ergänzt.

## Zwei belegte Fehlergruppen, fünf Tokenkorrekturen

Die Original-Lieferung bleibt bytegleich. Separate Importkopie: build/natur_batch_1_checks/reviewed_delivery/. Der Originalverifier bestand mechanisch; die vollständige Bedeutungsprüfung begründet folgende lokale Korrekturen:

| Satz/Ziel | Vorher | Nachher | Begründung |
|---|---|---|---|
| butterfly: landed on the flowers | on#gegenstand-verbot | vorhandenes on#auf | Räumlicher Kontakt mit einer Oberfläche |
| rust: rust on the gate | on#gegenstand-verbot | vorhandenes on#auf | Rost befindet sich auf dem Tor |
| float: on the surface | on#gegenstand-verbot | vorhandenes on#auf | Auf der Wasseroberfläche bleiben |
| horizon: on the horizon | on#gegenstand-verbot | vorhandenes on#am | Räumliche Lage am Horizont |
| solar: solar energy | energy#energie | neu energy#physikalische-energie | Alte Definition bezeichnet ausdrücklich körperliche/geistige Leistungsfähigkeit; Sonnenenergie ist physikalische Energie |

Die neue on#gegenstand-verbot-Definition gilt ausschließlich für die Handlung nach ban. Sie bleibt genau dort verwendet und wird nicht zu einem allgemeinen räumlichen Sense umdefiniert. Der neue physikalische Energie-Sense ist ausdrücklich definiert und erhält eine Wörterbuchform ohne Karte. energy#energie bleibt unverändert und weiterhin beim Winterschlaf-Satz verwendet. Kein neuer Besitzer oder zusätzliches Lernziel.

Fünf tokens_sha256-Reviewbindungen und das Manifest der Importkopie wurden erneuert. Annotationstext der Kopie und lokale Notizen angepasst; local_corrections.json enthält vollständige Token-/Review-Vorher-Nachher-Werte und Hashes. Satztexte, Satzübersetzungen, Karten, Lerngruppen, akzeptierte Formen, Alternative, Lücken und Positionen unverändert. Keine allgemeine Altglossenbereinigung. Lieferinterne ursprüngliche Auditdateien bleiben als Zulieferungsnachweise erhalten; der aktuelle Projekt-Audit unten dokumentiert das korrigierte Ergebnis.

## Bestandsschutz und tatsächlicher Export

Basis-JSON und SQLite rohbytegenau gegen die beauftragten Hashes geprüft; App-Asset entspricht der Basis. Liefer-/Referenzmanifest und Registry-/Gruppenbindungen bestanden. Aktueller Projektcode verwendet, keine Referenzquellen zurückkopiert und kein Validator gelockert.

Genau 81 aktuelle reservierte Identitäten, Definitionen, cards.learning, Besitzer/Aliase und je ein aktiver Satz wurden gegen die Originalauswahl geprüft. 161 spätere Karten bleiben abwesend. Als Begleitwörter eingeführte spätere Senses entsprechen exakt ihren Reservierungen und erzeugen keine vorgezogenen Karten. Der erste Batch verwendet direkt die gelieferten Anzeigepositionen 1–81; kein Display-Patch. Auswahl-/Registry-Originalpositionen unverändert.

Alle 1994 alten Karten-IDs und sämtlichen historischen Zeilen sind vollständig als unveränderter Präfix des neuen Packs nachgewiesen, einschließlich früherer Blutdruck- und tin-Tokenkorrekturen sowie aller alten Mitgliedschaftspositionen. Alle 18 SQLite-Tabellen vollständig gegen build_rows des tatsächlichen JSON-Exports verglichen: 2075 Karten, 2609 Satztexte, 2603 historische Satzverknüpfungen und 1971 Wortbesitzzeilen. Durch die gezielte Energieergänzung enthält der tatsächliche Export 4713 Senses und 5509 Wörterbuchformen. Exportstatus ok, internal_test_pack true, ai_calls 0 und Kosten 0.

Linter 0 Fehler, vier Hinweise: steel/walkway 3.16, oak/acorns 3.08, slope/grassy 3.24, exhaust/lorry 3.21. Keine Umformulierung allein wegen dieser Hinweise.

## Sicherung vor Staging

Asset und Manifest wurden in einem neuen Sicherungsordner build/natur_batch_1_checks/backup/assets/content/en/ kopiert. Beide Sicherungshashes stimmen mit der Ausgangsbaseline überein; backup-proof.json enthält den UTC-Zeitstempel und Hashes. Erst nach erfolgreichem SQLite-Audit und grünen Pipeline-Tests wurde dieser separate Vorbereitungsschritt ausgeführt; erst nach dessen Exit 0 das Staging gestartet.

Im vorhandenen real_pack_test wurde ausschließlich ein konkreter Versionsblock für natur_umwelt_batch_1_v1 mit acht Stapeln und den erwarteten Zählern ergänzt. Asset-Verifikation, Achtstapel-Lesetest und Flutter-Analyse bestehen. Flutter/Dart verwendeten den vorhandenen SDK-Cache außerhalb des Repositorys. Kein App-Einstieg, keine echte user.db/review_log geöffnet.

Ein zusätzlicher einmaliger Auditskriptfehler betraf die vom vorherigen Batch übernommene Zeichenlänge des Genitivapostrophs: neighbours' wurde zu animals' geändert, zunächst aber die alte Slice-Länge übernommen. Die Länge wurde auf das tatsächliche Wort angepasst; erneuter Audit bestand. Keine Änderung an Inhalt, Tokenizer oder Validator. Staging erfolgte erst nach diesem erfolgreichen Lauf. Erstversuch in audit-first-attempt.log erhalten.

## Geprüfte Batch-2-Übergabe

Mit dem vorhandenen Fortsetzungs-Exporter aus dem tatsächlich geprüften Pack erzeugt:

- pipeline/data/selection/natur_umwelt_batch_2_context_v1.json
- pipeline/data/words/en.natur_umwelt_batch_2_context_v1.json
- pipeline/data/learning_groups/en.natur_umwelt_batch_2_context_v1.json

Alte Auswahl-/Registry-/Gruppendateien bleiben unverändert. Alle 242 Originalidentitäten exakt enthalten; Partition 81 importiert / 81 aktuell / 80 später. Der nächste Import hängt 82–162 an und ordnet ausschließlich Natur-Anzeigen anhand des vorhandenen hashgebundenen Display-Vertrags auf 1–162 um. Keine Batch-2-Sätze erzeugt.

ZIP mit 83 Dateien und 82 Manifesthashes geschlossen und erneut geöffnet: CRCs, sämtliche Hashes, Referenzen, vollständige Identitäten/Partition, Besitzer/Aliase/Gruppen und alle 18 SQLite-Tabellen geprüft. Enthaltenes JSON und SQLite bytegleich zum tatsächlich geprüften neuen Pack. Danach ohne Überschreiben an den endgültigen Ort verschoben und dort nochmals vollständig geprüft.

Absoluter ZIP-Pfad: /Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/natur_umwelt_authoring_batch_2.zip

## Befehle und tatsächliche Prüfoutputs

Ab Repository-Root. PYTHON bedeutet auf macOS Terminal pipeline/.venv-macos/bin/python, unter Windows PowerShell .\pipeline\.venv\Scripts\python.exe. Dart-/Flutter-/Git-Befehle sind auf beiden Systemen identisch. Logs und lokale Hilfsskripte unter build/natur_batch_1_checks/.

```text
PYTHON natur_umwelt_batch_1/verify_natur_umwelt_batch_1.py --repo .
PYTHON build/natur_batch_1_checks/correct_delivery.py
PYTHON build/natur_batch_1_checks/reviewed_delivery/verify_natur_umwelt_batch_1.py --repo .
PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/essen_trinken_batch_3_v1/pack.json --create build/natur_batch_1_checks/reviewed_delivery/natur_umwelt_batch_1.editorial.json --registry pipeline/data/words/en.natur_umwelt_batch_1_context_v1.json --out pipeline/out/natur_umwelt_batch_1_v1
PYTHON build/natur_batch_1_checks/audit_export.py
PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
PYTHON build/natur_batch_1_checks/prepare_stage.py
dart run tool/stage_content_pack.dart --from pipeline/out/natur_umwelt_batch_1_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
PYTHON pipeline/scripts/export_authoring_context.py --help
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/natur_umwelt_v1.json --batch 2 --prepare-continuation natur_umwelt_batch_2_context_v1
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/natur_umwelt_batch_2_context_v1.json --batch 2 --out build/natur_batch_1_checks/staging/natur_umwelt_authoring_batch_2.zip
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/natur_batch_1_checks/staging/natur_umwelt_authoring_batch_2.zip
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/natur_umwelt_authoring_batch_2.zip
```

### verifier-corrected.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS new deck display 1..81; original registry positions preserved
PASS create_content/build_rows: 2075 cards; 1960 primary goals (160/489/241/245/245/249/250/81); 18 tables
PASS 81 reserved identities, display 1..81; 1994 old IDs and all historical rows preserved
PASS 915 token positions; one reviewed alternative; linter 0 errors, 4 warnings
WARNINGS [["steel", "i+1", "'walkway'/'walkway' Zipf 3.16 below 3.5"], ["oak", "i+1", "'acorn'/'acorns' Zipf 3.08 below 3.5"], ["slope", "i+1", "'grassy'/'grassy' Zipf 3.24 below 3.5"], ["exhaust", "i+1", "'lorry'/'lorry' Zipf 3.21 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access

Exit 0
```

### correction.log

```text
PASS five token corrections; one physical-energy dictionary sense/form; five review hashes and copy manifest renewed; all sentences/cards/learning/positions unchanged

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
    "lemmas": 3276,
    "senses": 4713,
    "cards": 2075,
    "dictionary_forms": 5509,
    "decks": 8,
    "deck_cards": 2075,
    "deck_words": 1971,
    "word_aliases": 36,
    "sentences": 2609,
    "sentence_tokens": 29043,
    "card_sentences": 2603,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "3136cdbbcf5c9b71d2afd36b3614caf25e6cf29f3dbd8903bff0347ff194d84f"
}

Exit 0
```

### audit.log

```text
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 3276, 'senses': 4713, 'cards': 2075, 'dictionary_forms': 5509, 'decks': 8, 'deck_cards': 2075, 'deck_words': 1971, 'word_aliases': 36, 'sentences': 2609, 'sentence_tokens': 29043, 'card_sentences': 2603, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 81 original identities, definitions, learning groups, owners and fixed sentences; partition 81/81/80
PASS 1994 historical cards and all old content preserved, including all previous corrections and display positions
ALTERNATIVE This fertilizer gives the plants the nutrients they need.
PASS reviewed reading/annotation documents exactly match all 81 sentences and 915 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 245
DECK koerper-gesundheit 249
DECK essen-trinken 250
DECK natur-umwelt 81
PACK_SHA256 0238ba53db979fb9c54483ee6c9ba7e0794bec30f7a506c1d0b237e2383a0767
SQLITE_SHA256 3136cdbbcf5c9b71d2afd36b3614caf25e6cf29f3dbd8903bff0347ff194d84f
NEW_TOKEN_COUNTS 829 word tokens 86 punctuation
PASS blood pressure uses explicit physical sense; social-pressure sense/card preserved; no additional learning card
PASS ownership aliases exact; 161 future cards absent; promoted reserved senses exact; local on/energy corrections exact; old tin and blood-pressure corrections preserved

Exit 0
```

### pytest.log

```text
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 1.01s

Exit 0
```

### prepare-stage.log

```text
PASS backup BEFORE staging: {"verified_before_staging_utc": "2026-10-10T13:08:48.109665+00:00", "files": {"assets/content/en/content.sqlite": "cffc9e4529ada7f61e0bbf7e2e1e7d7d0926f68957b616f2497e38234405d2ce", "assets/content/en/content.manifest.json": "3edb2db9a0a549521956ebf2f8ff9014574b46b95f04e5be39a48e9091436248"}}
PASS exact eight-deck test expectations added; existing bytes preserved

Exit 0
```

### stage.log

```text
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version natur_umwelt_batch_1_v1, schema 3, 14131200 bytes
  sha256 3136cdbbcf5c9b71d2afd36b3614caf25e6cf29f3dbd8903bff0347ff194d84f
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
```

### stage-verify.log

```text
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version natur_umwelt_batch_1_v1, schema 3, 14131200 bytes
  sha256 3136cdbbcf5c9b71d2afd36b3614caf25e6cf29f3dbd8903bff0347ff194d84f
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
deck essen-trinken: 250 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
deck natur-umwelt: 81 learning targets, 81 ownership cards, 81 fixed sentence assignments verified
pack natur_umwelt_batch_1_v1 (schema 3, internal: true); 8 decks: 1971 cards, 2075 card sentences, 136 with valid_alternatives, 2075 cards in the pack
00:11 +1: All tests passed!

Exit 0
```

### flutter-analyze.log

```text
Analyzing sprachapp...
No issues found! (ran in 2.1s)

Exit 0
```

### continuation.log

```text
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/natur_umwelt_batch_2_context_v1.json",
    "registry": "pipeline/data/words/en.natur_umwelt_batch_2_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.natur_umwelt_batch_2_context_v1.json"
  },
  "partition_counts": {
    "imported": 81,
    "current": 81,
    "future": 80
  }
}

Exit 0
```

### verify-batch-2-final.log

```text
{
  "zip_verification": "PASS",
  "zip_sha256": "1590e17c73622dae07f17bb366cb9461b7703abf6f557b3bc021220fb0bc512f",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 2075,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 242,
  "excluded": 452,
  "partition_counts": {
    "imported": 81,
    "current": 81,
    "future": 80
  },
  "reused_proposed_senses": 9,
  "batches": {
    "1": 81,
    "2": 81,
    "3": 80
  },
  "topics_per_batch": {
    "1": {
      "Tiere und ihre Lebensräume": 15,
      "Pflanzen, Bäume und Pflanzenteile": 12,
      "Klima, Energie und Naturschutz": 11,
      "Materialien und natürliche Ressourcen": 11,
      "Umwelt, Abfall und Recycling": 9,
      "Landschaften und Gewässer": 9,
      "Naturvorgänge und Jahreszeiten": 8,
      "Wetter und Temperatur": 6
    },
    "2": {
      "Tiere und ihre Lebensräume": 15,
      "Pflanzen, Bäume und Pflanzenteile": 12,
      "Materialien und natürliche Ressourcen": 12,
      "Klima, Energie und Naturschutz": 11,
      "Umwelt, Abfall und Recycling": 9,
      "Naturvorgänge und Jahreszeiten": 8,
      "Landschaften und Gewässer": 8,
      "Wetter und Temperatur": 6
    },
    "3": {
      "Tiere und ihre Lebensräume": 15,
      "Pflanzen, Bäume und Pflanzenteile": 12,
      "Materialien und natürliche Ressourcen": 11,
      "Klima, Energie und Naturschutz": 10,
      "Umwelt, Abfall und Recycling": 10,
      "Naturvorgänge und Jahreszeiten": 8,
      "Landschaften und Gewässer": 8,
      "Wetter und Temperatur": 6
    }
  },
  "existing_senses": 30,
  "new_senses": 212,
  "existing_cards": 2075,
  "existing_groups": 2063,
  "new_groups": 161,
  "registry_words": 2132,
  "partition_selection": "PASS: 81 present",
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
| pipeline/out/essen_trinken_batch_3_v1/pack.json | `0a7a73b424f1625f71a2af892ff2a610f6103aef263d210bdcc3fc528d0ce521` |
| pipeline/out/essen_trinken_batch_3_v1/content.sqlite | `cffc9e4529ada7f61e0bbf7e2e1e7d7d0926f68957b616f2497e38234405d2ce` |
| natur_umwelt_batch_1/natur_umwelt_batch_1.editorial.json | `d6b60477297b34794e8eff51e29a164b14384aac143264717e3445455fac1842` |
| natur_umwelt_batch_1/manifest.json | `ce93248397dcba3697f0042fa16e18059d6dae52a1ce60c4b544941569b44faa` |
| build/natur_batch_1_checks/reviewed_delivery/natur_umwelt_batch_1.editorial.json | `084e9df28f5a7fd258b21e418a6a85c81ac3d593549a555e20936eb81105fef2` |
| build/natur_batch_1_checks/reviewed_delivery/manifest.json | `d9d279e8c3786e49a709e43f48bbc8eb65fd9c3c26fea7a0fad7a19db0a048a1` |
| pipeline/out/natur_umwelt_batch_1_v1/pack.json | `0238ba53db979fb9c54483ee6c9ba7e0794bec30f7a506c1d0b237e2383a0767` |
| pipeline/out/natur_umwelt_batch_1_v1/content.sqlite | `3136cdbbcf5c9b71d2afd36b3614caf25e6cf29f3dbd8903bff0347ff194d84f` |
| assets/content/en/content.sqlite | `3136cdbbcf5c9b71d2afd36b3614caf25e6cf29f3dbd8903bff0347ff194d84f` |
| assets/content/en/content.manifest.json | `b299d46849b39a998f07a7188263de239f04631ab16c93b6a76a70cc27443dc8` |
| pipeline/data/selection/natur_umwelt_v1.json | `344f4b562855584acf8c3290ff2c8b5c7f4a6b400b937cd7f166cd0671ee0c21` |
| pipeline/data/selection/natur_umwelt_batch_2_context_v1.json | `cb9782d28427bd1d9c08181aef61be8c5dd1b9d13f69b8520d4e015e275158b9` |
| pipeline/data/words/en.natur_umwelt_batch_2_context_v1.json | `442db94805d4372691b37fdaf00315ee2dd84ac3bb2fe637a9ea00e87bbac23c` |
| pipeline/data/learning_groups/en.natur_umwelt_batch_2_context_v1.json | `5ec62c854bf141416d233e0888d592dd6a3c97fbe1bc660fc0c6303abfac27c3` |
| build/natur_umwelt_authoring_batch_2.zip | `1590e17c73622dae07f17bb366cb9461b7703abf6f557b3bc021220fb0bc512f` |

## Arbeitsbaum und Grenzen

Baseline mit 2541 erfassten Dateien. Ausschließlich vier vorhandene Dateien dürfen geändert sein: Assets/Manifest, test/data/real_pack_test.dart und NEXTSTEPS.md. Neu: geprüfter Pack, drei Batch-2-Kontextsnapshots, dieser Bericht und ZIP. Original-Lieferung, historische Packs, Originalauswahl, alte Registrys/Gruppen, alte ZIP und die Roadmap bleiben bytegleich. Schlussnachweis unter final-protection.json, final-checks.log und Git-Status vor/nachher.

Gezielte git diff --check-Prüfung und zusätzlicher CRLF-toleranter Check für die konkreten bearbeiteten Dateien; neue unversionierte Textdateien separat gegen /dev/null, test/NEXTSTEPS gegen Ausgangskopien. Keine riesige repositoryweite Diff-Ausgabe. Bekannte sieben Altstellen separat erhalten: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127 und docs/arbeit-bildung-batch-2-import.md:121. Keine globale Bereinigung.

Keine echte user.db/review_log oder Lernstände verändert; keine App-/SRS-/Synonym-/Modell-/Budget-/Supabase-/Plattformänderung, Cloud-/Modellaufrufe, Veröffentlichung, Commits oder Pushes. Keine Geräteprüfung oder unabhängige menschliche Sprachfreigabe behauptet. Offen: Satzredaktion der nächsten 81 Ziele; Geräteprüfung und bekannte Altbefunde bleiben eigene Aufgaben. Keine ungeklärte Inhaltsbindung des aktuellen Imports.

## Abschließender Nachweis

```text
BASELINE 2541 UNCHANGED 2537 CHANGED ['NEXTSTEPS.md', 'assets/content/en/content.manifest.json', 'assets/content/en/content.sqlite', 'test/data/real_pack_test.dart']
git-diff-check-targeted Exit 2 output bytes 20336
git-diff-check-targeted-crlf Exit 0 output bytes 0
PASS new untracked files, NEXTSTEPS and exact test change separately checked; own whitespace Exit 0
git status --short Exit 0; saved to git-status-after.txt
PASS all historical selections/registries/groups, historical packs/deliveries and app/pipeline code unchanged; only authorized assets/manifest/test/NEXTSTEPS changed; no repository-wide diff generated

Exit 0
```

2537 von 2541 erfassten Ausgangsdateien bleiben bytegleich; genau die vier beauftragten Bestandsdateien sind geändert. Der normale gezielte Diff-Check meldet erhaltene CRLF-Zeilen in NEXTSTEPS/Test (Exit 2); CRLF-tolerant und für eigene Änderungen gegen Ausgangskopien keine Befunde. Neue unversionierte Dateien separat geprüft. Der erste lokale Abschlusscheck hatte eine zu niedrige reine Loggrößengrenze von 15 KB; die gezielte CRLF-Diagnose betrug 20336 Bytes. Speicherung bis 64 KB zugelassen, ohne Diagnoseunterdrückung oder Lockerung einer Inhaltsprüfung; erneuter vollständiger Abschlusscheck Exit 0. Kein repositoryweiter Diff erzeugt. NEXTSTEPS: 25 Zeilen.
