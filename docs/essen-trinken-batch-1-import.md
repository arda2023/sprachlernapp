# Essen & Trinken: Batch 1 offline importiert

Stand: 10.10.2026. Genau 84 Ziele und 84 feste Satzpaare wurden geprüft, importiert und intern gestagt. Ein neuer Stapel essen-trinken mit Anzeigepositionen 1–84; insgesamt 1713 primäre Ziele in sieben Stapeln: 160/489/241/245/245/249/84.

## Redaktionelle Prüfung

Alle 84 englisch-deutschen Satzpaare, 960 Tokenpositionen (871 Worttoken, 89 Satzzeichen), neuen Sense-Definitionen und Formglossen sowie fünf Alternativantworten wurden gegengelesen. Lesedokument und Annotationen wurden vollständig gegen den tatsächlichen Import abgeglichen.

Geprüfte Kontextbindungen: stone Fruchtkern; skin Fruchtschale; rings ringförmige Stücke; bed Speisenunterlage; glasses Trinkgläser; pepper am Spieß Paprika; clove Gewürznelke. scales Küchenwaage, pastry Teig, rare Garstufe. tin unterscheidet Dose bei Keksen/Thunfisch und Backform bei baking tin. still ist beim Speck Zeitadverb, bei Wasser ohne Kohlensäure. cream Sahne, ice gefrorenes Wasser, heat Kochhitze. off nach rolled ist Präposition von einer Oberfläche, nach broke Abtrennpartikel. cut und use sind Verben; each vor bowl ist Determinierer und kein each other. save time bedeutet Zeit sparen; fit beim Verschluss bezeichnet Gegenstandspassform. Ebenso geprüft: in half, roll out, instead of, existentielles There was gegenüber Verlaufsform was sizzling und die präpositionalen/infinitivischen to-Bindungen.

Alle fünf Alternativen wurden wörtlich eingesetzt:

- The lemon gives this cake a fresh flavor.
- David gave his father a bottle of whiskey for his birthday.
- Ben cut the eggplant into thick slices for the grill.
- Ali covered the dish with aluminium foil before putting it in the oven.
- Ali covered the dish with aluminum foil before putting it in the oven.

accepted bleibt ausschließlich flavour, whisky, aubergine beziehungsweise foil. Die Folien-Alternativen passen zur definierten Alufolie in der Ofenszene. Es handelt sich um einzeln geprüfte satzbezogene Antworten; keine automatische Freigabe aus Besitzaliasen, keine Lernstandwirkung durch neutrale Wiederholung.

### Eine belegte Identitätskorrektur

Die Lieferung führte tin/NOUN|tin#dose für die Dose bei Keksen und Thunfisch neu ein. Die Originalauswahl reserviert dieselbe Bedeutung bereits als tin/NOUN|tin#konservendose (Definition: „Verschließbarer Metallbehälter für Lebensmittel.“). Ein zweiter paralleler Sense würde die verbindliche spätere Zielidentität umgehen.

In der separaten Importkopie build/essen_batch_1_checks/reviewed_delivery/ wurde genau diese Sensezeile auf Schlüssel, Glosse und Definition der Originalreservierung gebracht. Eine Wörterbuchform und genau zwei Tokenreferenzen wurden entsprechend aktualisiert, einschließlich zweier Reviewhashes und der Manifesthashes. tin#backform ist eine eigenständige Bedeutung und bleibt erhalten. Keine Änderung an Satztext, Übersetzung, aktuellen Zielkarten oder Lerngruppen; keine zusätzliche tin-Lernkarte. Original-Lieferung bytegleich. Vollständiger Vorher-/Nachher-Nachweis: local_corrections.json in der Importkopie. Kein Display-Patch erforderlich.

Der ursprüngliche und der korrigierte Lieferverifier bestehen. Die mechanische Prüfung allein erkennt die parallele semantische Identität nicht; der Abgleich mit zukünftigen Reservierungen begründet die gezielte Korrektur. Keine pauschale Altglossenbereinigung oder Validatorlockerung.

## Bestandsschutz und Export

Basis-Pack koerper_gesundheit_batch_3_v1 und SQLite stimmen rohbytegenau mit den beauftragten Hashes überein. Liefer-/Referenzmanifest, Registry/Gruppen kanonisch und Reviewhashes geprüft. Aktueller Projektcode verwendet, keine mitgelieferten Referenzquellen zurückkopiert.

Alle 84 aktuellen Originalidentitäten, Definitionen, cards.learning, Besitzer, Aliase und genau ein aktiver fester Satz sind erhalten. Keine vorgezogenen Karten aus den 166 späteren Zielen. Begleitwort-Senses bleiben reine Wörterbucheinträge und passen gegebenenfalls exakt zu den reservierten Definitionen.

Alle bisherigen 1744 Karten und historischen Zeilen bleiben unverändert, einschließlich früherer Tokenkorrekturen, Lerngruppen und sämtlicher alter Anzeigepositionen. Die neuen Mitgliedschaften verwenden direkt die gelieferten Positionen 1–84. Originalpositionen in Auswahl und Registry bleiben unverändert.

Alle 18 SQLite-Tabellen wurden vollständig gegen build_rows verglichen: 1828 Karten, 2362 Satztexte, 2356 historische Satzverknüpfungen, 1724 Wortbesitzzeilen. Exportstatus ok, internal_test_pack true, ai_calls 0, Kosten 0.

## Sicherung vor Staging

Asset und Manifest wurden in einem separaten erfolgreichen Vorbereitungsschritt nach build/essen_batch_1_checks/backup/assets/content/en/ kopiert. Beide Sicherungshashes stimmen mit der vorab erfassten Baseline überein. Erst nach dessen Exit 0 wurde das Staging gestartet. Zeit-/Hashnachweis: backup-proof.json; tatsächliche Ausgabe unten in prepare-stage.log. Kein fehlgeschlagener Vorbereitungsschritt wurde übersprungen.

Im bestehenden real_pack_test wurde ausschließlich ein konkreter Versionsblock für die sieben erwarteten Stapel und Zähler ergänzt. Asset-Verifikation, Siebenstapel-Lesetest und Flutter-Analyse bestehen. Der vorhandene Flutter-SDK-Cache erforderte Zugriff außerhalb des Repositorys; keine SDK-/Plattformdateien im Projekt verändert.

## Vierzehn Häufigkeitshinweise

Linter: 0 Fehler, 14 Hinweise. Keine Umformulierung allein wegen der Zipf-Schwelle 3,5. Sie betreffen grated, yoghurt, sprinkled, cucumber, spoonful bei bran und pesto, lentils, sizzling, teaspoon, napkin, fishmonger, stalks, pickled und yolk. Exakte Zielzuordnung und Werte stehen im Lieferverifier-Output unten.

## Batch 2

Neue separate Kontextdateien essen_trinken_batch_2_context_v1 in selection/, words/ und learning_groups/ wurden mit dem vorhandenen Fortsetzungs-Exporter aus dem tatsächlich geprüften Pack erzeugt. Die Originalauswahl und alten Snapshots bleiben unverändert. Alle 250 Originalidentitäten und Definitionen sind exakt enthalten; Partition 84 importiert / 83 aktuell / 83 später.

Der nächste Import hängt 85–167 an und ordnet anschließend ausschließlich Essen-Anzeigen hashgebunden auf 1–167 um. Keine Batch-2-Sätze erzeugt. Bereits eingeführte Wörterbuchbedeutungen werden nach den exakten Reservierungen wiederverwendet; keine Definition-Equivalence-Ausnahme nötig.

ZIP: 83 Dateien, 82 Manifesthashes. Geschlossen, neu geöffnet und vollständig geprüft: CRCs, Manifesthashes, Quellen/Referenzen, Identitäten, Partition, Besitz/Gruppen und alle 18 SQLite-Tabellen. Danach ohne Überschreiben an den endgültigen Ort verschoben und dort nochmals vollständig geprüft. README mit relativen Importpfaden, keine Zugangsdaten oder Lernstände.

Absoluter ZIP-Pfad: /Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/essen_trinken_authoring_batch_2.zip

## Befehle und tatsächliche Prüfoutputs

Alle Logs unter build/essen_batch_1_checks/. PYTHON bedeutet auf macOS Terminal pipeline/.venv-macos/bin/python, unter Windows PowerShell .\pipeline\.venv\Scripts\python.exe. Dart/Flutter/Git sind auf beiden Systemen identisch. Ausführung ab Repository-Root.

```text
PYTHON essen_trinken_batch_1/verify_essen_trinken_batch_1.py --repo .
PYTHON build/essen_batch_1_checks/correct_delivery.py
PYTHON build/essen_batch_1_checks/reviewed_delivery/verify_essen_trinken_batch_1.py --repo .
PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/koerper_gesundheit_batch_3_v1/pack.json --create build/essen_batch_1_checks/reviewed_delivery/essen_trinken_batch_1.editorial.json --registry pipeline/data/words/en.essen_trinken_batch_1_context_v1.json --out pipeline/out/essen_trinken_batch_1_v1
PYTHON build/essen_batch_1_checks/audit_export.py
PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
PYTHON build/essen_batch_1_checks/prepare_stage.py
dart run tool/stage_content_pack.dart --from pipeline/out/essen_trinken_batch_1_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
PYTHON pipeline/scripts/export_authoring_context.py --help
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/essen_trinken_v1.json --batch 2 --prepare-continuation essen_trinken_batch_2_context_v1
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/essen_trinken_batch_2_context_v1.json --batch 2 --out build/essen_batch_1_checks/staging/essen_trinken_authoring_batch_2.zip
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/essen_batch_1_checks/staging/essen_trinken_authoring_batch_2.zip
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/essen_trinken_authoring_batch_2.zip
```

### verifier-corrected.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS new deck display 1..84; original registry positions preserved
PASS create_content/build_rows: 1828 cards; 1713 primary goals (160/489/241/245/245/249/84); 18 tables
PASS 84 reserved identities, display 1..84; 1744 old IDs and all historical rows preserved
PASS 960 token positions; five reviewed alternatives; linter 0 errors, 14 warnings
WARNINGS [["cheddar", "i+1", "'grate'/'grated' Zipf 3.17 below 3.5"], ["blend", "i+1", "'yoghurt'/'yoghurt' Zipf 3.01 below 3.5"], ["dill", "i+1", "'sprinkle'/'sprinkled' Zipf 3.39 below 3.5"], ["dill", "i+1", "'cucumber'/'cucumber' Zipf 3.41 below 3.5"], ["bran", "i+1", "'spoonful'/'spoonful' Zipf 2.87 below 3.5"], ["cumin", "i+1", "'lentil'/'lentils' Zipf 3.00 below 3.5"], ["bacon", "i+1", "'sizzle'/'sizzling' Zipf 3.13 below 3.5"], ["paprika", "i+1", "'teaspoon'/'teaspoon' Zipf 3.30 below 3.5"], ["juicy", "i+1", "'napkin'/'napkin' Zipf 3.16 below 3.5"], ["fillet", "i+1", "'fishmonger'/'fishmonger' Zipf 2.29 below 3.5"], ["celery", "i+1", "'stalk'/'stalks' Zipf 3.46 below 3.5"], ["pesto", "i+1", "'spoonful'/'spoonful' Zipf 2.87 below 3.5"], ["herring", "i+1", "'pickle'/'pickled' Zipf 3.39 below 3.5"], ["crack", "i+1", "'yolk'/'yolk' Zipf 3.04 below 3.5"]]
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
    "lemmas": 2978,
    "senses": 4378,
    "cards": 1828,
    "dictionary_forms": 5117,
    "decks": 7,
    "deck_cards": 1828,
    "deck_words": 1724,
    "word_aliases": 30,
    "sentences": 2362,
    "sentence_tokens": 26209,
    "card_sentences": 2356,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "1c6a0e1d5ca182a0cc30405f541b25120d8bb887d317f627aabc324c56733e92"
}

Exit 0
```

### audit-export.log

```text
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2978, 'senses': 4378, 'cards': 1828, 'dictionary_forms': 5117, 'decks': 7, 'deck_cards': 1828, 'deck_words': 1724, 'word_aliases': 30, 'sentences': 2362, 'sentence_tokens': 26209, 'card_sentences': 2356, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 84 original identities, definitions, learning groups, owners and fixed sentences; partition 84/83/83
PASS 1744 historical cards and all old content preserved, including all previous corrections and display positions
ALTERNATIVE The lemon gives this cake a fresh flavor.
ALTERNATIVE David gave his father a bottle of whiskey for his birthday.
ALTERNATIVE Ben cut the eggplant into thick slices for the grill.
ALTERNATIVE Ali covered the dish with aluminium foil before putting it in the oven.
ALTERNATIVE Ali covered the dish with aluminum foil before putting it in the oven.
PASS reviewed reading/annotation documents exactly match all 84 sentences and 960 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 245
DECK koerper-gesundheit 249
DECK essen-trinken 84
PACK_SHA256 30aedf52b01a6cb755ac7845569a306d3cdeb9df03ebe2e0c539cdbf57e2e755
SQLITE_SHA256 1c6a0e1d5ca182a0cc30405f541b25120d8bb887d317f627aabc324c56733e92
NEW_TOKEN_COUNTS 871 word tokens 89 punctuation
PASS blood pressure uses explicit physical sense; social-pressure sense/card preserved; no additional learning card
PASS future identities not introduced; all promoted reserved senses exact; tin container/backform distinct

Exit 0
```

### pytest.log

```text
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 0.89s

Exit 0
```

### prepare-stage.log

```text
PASS backup BEFORE staging: {"verified_before_staging_utc": "2026-10-10T11:47:45.390372+00:00", "files": {"assets/content/en/content.sqlite": "98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04", "assets/content/en/content.manifest.json": "a3c692f8662ef680e14f6285f405cb68cb74c1fa1861ac463caf458c585df3c0"}}
PASS exact seven-deck test expectations added; existing bytes preserved

Exit 0
```

### stage.log

```text
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version essen_trinken_batch_1_v1, schema 3, 12738560 bytes
  sha256 1c6a0e1d5ca182a0cc30405f541b25120d8bb887d317f627aabc324c56733e92
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
```

### stage-verify.log

```text
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version essen_trinken_batch_1_v1, schema 3, 12738560 bytes
  sha256 1c6a0e1d5ca182a0cc30405f541b25120d8bb887d317f627aabc324c56733e92
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
deck essen-trinken: 84 learning targets, 84 ownership cards, 84 fixed sentence assignments verified
pack essen_trinken_batch_1_v1 (schema 3, internal: true); 7 decks: 1724 cards, 1828 card sentences, 129 with valid_alternatives, 1828 cards in the pack
00:09 +1: All tests passed!

Exit 0
```

### flutter-analyze.log

```text
Analyzing sprachapp...
No issues found! (ran in 1.9s)

Exit 0
```

### continuation.log

```text
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/essen_trinken_batch_2_context_v1.json",
    "registry": "pipeline/data/words/en.essen_trinken_batch_2_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.essen_trinken_batch_2_context_v1.json"
  },
  "partition_counts": {
    "imported": 84,
    "current": 83,
    "future": 83
  }
}

Exit 0
```

### verify-batch-2-final.log

```text
{
  "zip_verification": "PASS",
  "zip_sha256": "90d96e06b5b7bd3848f2922b79d9712fd5691543fc19c6b183a59f26131a2077",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 1828,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 250,
  "excluded": 83,
  "partition_counts": {
    "imported": 84,
    "current": 83,
    "future": 83
  },
  "reused_proposed_senses": 8,
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
  "existing_cards": 1828,
  "existing_groups": 1816,
  "new_groups": 166,
  "registry_words": 1890,
  "partition_selection": "PASS: 84 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}

Exit 0
```

## SHA256

| Datei | Rohbyte-SHA256 |
|---|---|
| pipeline/out/koerper_gesundheit_batch_3_v1/pack.json | `c03047452c197a5bd4985af0faf64fb1e0614765a8a7c3f475f8c088a595f457` |
| pipeline/out/koerper_gesundheit_batch_3_v1/content.sqlite | `98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04` |
| essen_trinken_batch_1/essen_trinken_batch_1.editorial.json | `e19c89c6f49eaf71d40bff1226399d618f94cb9ba52c3d17bd1a491ad260d793` |
| build/essen_batch_1_checks/reviewed_delivery/essen_trinken_batch_1.editorial.json | `aac2d2d9e229d5d1c2498ed1a845381db1dadb8eada683e40dcd32dccbe93903` |
| build/essen_batch_1_checks/reviewed_delivery/manifest.json | `1905892c3df105a7070c1516d96bfc0af796e7d22038f9d0e9e9abcfe7c12398` |
| pipeline/out/essen_trinken_batch_1_v1/pack.json | `30aedf52b01a6cb755ac7845569a306d3cdeb9df03ebe2e0c539cdbf57e2e755` |
| pipeline/out/essen_trinken_batch_1_v1/content.sqlite | `1c6a0e1d5ca182a0cc30405f541b25120d8bb887d317f627aabc324c56733e92` |
| assets/content/en/content.sqlite | `1c6a0e1d5ca182a0cc30405f541b25120d8bb887d317f627aabc324c56733e92` |
| assets/content/en/content.manifest.json | `00067ac8f58cbf64d407a02975aed42e15f7ecb6291dc4dc1299f69bcc2689ef` |
| pipeline/data/selection/essen_trinken_batch_2_context_v1.json | `6a69e2c2c58a108d48a17a650735fcd6dfe5df2f4158f9676110332129a2f98d` |
| pipeline/data/words/en.essen_trinken_batch_2_context_v1.json | `dd0a68f6652ae423e8ae95c438e25ccf9ab9e3d8db65703ec1cd97f8625c9fbd` |
| pipeline/data/learning_groups/en.essen_trinken_batch_2_context_v1.json | `d4439deb7a654750f04cf7ebeabb726f55727bc75ee0731e4bf397e0685b842d` |
| build/essen_trinken_authoring_batch_2.zip | `90d96e06b5b7bd3848f2922b79d9712fd5691543fc19c6b183a59f26131a2077` |

## Arbeitsbaum und Grenzen

2226 von 2230 Ausgangsdateien bleiben bytegleich. Nur Asset/Manifest, test/data/real_pack_test.dart und NEXTSTEPS.md wurden verändert. Neu: Pack-Ausgabe, Batch-2-Kontextsnapshots, dieser Bericht und die ZIP. Original-Lieferung, historische Packs und alte Auswahlen/Registrys/Gruppen unverändert. Nachweise: baseline.json, git-status-before.txt, git-status-after.txt und final-protection.json unter build/essen_batch_1_checks/.

git diff --check: Exit 2 wegen vorhandener CRLF-/Whitespace-Befunde. Der CRLF-tolerante Check meldet sieben Altstellen: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127, docs/arbeit-bildung-batch-2-import.md:121. Keine globale Bereinigung. Eigene Änderungen gesondert ohne Whitespace-Diagnostik geprüft (Wrapper Exit 0); git status --short: Exit 0. Umfangreiche Rohlogs gzip-komprimiert gespeichert.

Keine echte user.db oder review_log geöffnet; keine App-/Pipeline-/SRS-/Modell-/Budget-/Supabase-/Plattformänderung, Cloud-Aufrufe, Veröffentlichung, Commits oder Pushes. Geräteprüfung nicht durchgeführt. Offen bleiben die Satzredaktion der nächsten 83 Ziele, die bekannten sieben Whitespace-Altbefunde und eine Geräteprüfung; keine ungeklärte Inhaltsbindung dieses Imports.
