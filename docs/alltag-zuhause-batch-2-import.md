# Alltag & Zuhause: Batch 2 importiert, Batch 3 vorbereitet

Stand: 07.10.2026. `alltag_zuhause_batch_2_v1`, Schema 3, ist als internes
Test-Pack gestagt. 927 physische Karten, 812 primäre Lernziele:
160 Allgemeine Sprache / 489 Reisen / 163 Alltag & Zuhause.
1461 Satztexte, 1455 Satzverknüpfungen einschließlich Historie und 823 Wortbesitzzeilen.

| Artefakt | SHA256 (Rohbytes) |
|---|---|
| Basis `pipeline/out/alltag_zuhause_batch_1_v1/pack.json` | `05cc1602efda960f19c19028a5da32d2f2ccc864df90b2b6b255956832a74e70` |
| Neuer Export `pipeline/out/alltag_zuhause_batch_2_v1/pack.json` | `b24f5599646120c62dca163dccb3cd5d2d27c71206be76fb8690a303f8b96d7c` |
| Neuer Export und Asset `content.sqlite` | `736ccd251ff3f84fe2577f48113a76f4b0a750bb64679c58810533c59109bee9` |
| `build/alltag_zuhause_authoring_batch_3.zip` | `228209c1816cf242b6085c1fd9a46eb97d699a83939842a42eed15dc90ad2229` |
| Original-Liefermanifest `alltag_zuhause_batch_2/manifest.json` | `ab3ba39929979a75fde2cbb0b76190329d8ef66179574122ac6ed3cb3d8659fb` |

## Bestandsschutz und Lieferung

Der Lieferordner war bereits vorhanden und wurde unverändert verwendet.
Keine Referenzquellen über Projektcode kopiert, keine vorhandenen Ausgaben
überschrieben. Git-Status und SHA256 von 1093 vorhandenen Dateien wurden vor
Änderungen unter `build/alltag_batch_2_checks/` gesichert. Asset, Manifest,
NEXTSTEPS und bestehender Pack-Lesetest liegen dort zusätzlich als Originalbytes
in `asset_backup/`. Der abschließende Audit bestätigt 1089 bytegleiche Dateien;
genau die vier autorisierten Bestandsdateien unterscheiden sich. Bereits
vorhandene Änderungen bleiben erhalten. Neue Dateien sind separat hinzugekommen.

Der unveränderte Lieferverifier prüfte Liefer- und Referenzmanifest, JSON-Schema,
Fortsetzungsvertrag und Basis-SQLite erfolgreich. Registry und Gruppen wurden
kanonisch als JSON verglichen; Pack und SQLite rohbytegebunden. Keine
Zeilenendennormalisierung und keine Installation oder Aktualisierung von Paketen.

## Redaktionelle Gegenlesung

Alle 80 englisch-deutschen Satzpaare, Zieldefinitionen, Wortbindungen und neuen
Formglossen wurden gelesen. Alle acht Alternativen wurden wörtlich im jeweiligen
vollständigen Satz geprüft. Kein konkret belegter Lieferfehler festgestellt;
keine Korrektur, Neugenerierung oder Neuberechnung der gültigen Review-/Createhashes.
Die Gegenlesung durch Codex ist keine unabhängige menschliche Zertifizierung.
Einzelprotokoll mit 80 Einträgen und den acht tatsächlichen Substitutionen:
`build/alltag_batch_2_checks/editorial-review.json`.

| Ziel / Alternative | Wörtlich eingesetzter Satz |
|---|---|
| sofa → couch | We can all sit on the couch and watch a film. |
| bin → rubbish bin | This wrapper belongs in the rubbish bin, not on the floor. |
| bin → trash can | This wrapper belongs in the trash can, not on the floor. |
| peg → clothes peg | Use another clothes peg to stop the towel falling off the washing line. |
| peg → clothespin | Use another clothespin to stop the towel falling off the washing line. |
| cinema → movie theater | Would you rather watch the film at the movie theater or at home? |
| cinema → movie theatre | Would you rather watch the film at the movie theatre or at home? |
| photo → photograph | This photograph shows my grandparents and their first house. |

`accepted` enthält jeweils nur die Zielform. Die acht Alternativen betreffen fünf
Satzbindungen; deshalb steigt die Zahl aktiver Sätze mit Alternativen von 89 auf
94. Sie bleiben neutrale satzbezogene Wiederholungsversuche nach den bestehenden
App-Regeln; keine Gruppen-Synonyme pauschal ergänzt.

`jeans` verwendet dieselbe bestehende Sense und die ausdrückliche hashgebundene
Entscheidung zwischen „Eine robuste Hose aus Denimstoff.“ und „Eine Hose aus
festem Denimstoff.“. Beide Texte bleiben erhalten. `aisle` verwendet gemäß
freigegebener Zieldefinition den Gang zwischen Warenregalen; die engere
historische Fahrzeugdefinition bleibt unverändert. Keine zweite Reise-/Alltag-Sense.
Historische Formglossen etwa bei home, bin, battery und tennis bleiben erhalten;
die Lieferung ist keine globale Wörterbuchbereinigung.

967 Tokenpositionen vollständig geprüft, keine Linterfehler. Die 34 neuen
Warnungen sind ausschließlich Häufigkeitshinweise (`i+1`), kein Anlass für
wiederholtes Umformulieren. Der Exportbericht enthält auch die bestehenden
Häufigkeitshinweise des gesamten Packs.

## Import und Anzeige

Genau 80 neue Lernkarten mit unveränderten `cards.learning`-Objekten und je einem
festen Satz. Keine Lernkarten für Begleitwörter. Bestehender Stapel weiterverwendet:
zuerst Anhängepositionen 84–163, anschließend der unveränderte hashgebundene
Display-Patch auf Anzeige 1–163 in Originalreihenfolge.

Von 83 bisherigen Alltag-Zeilen ändern sich tatsächlich 82 Positionen je Tabelle
`deck_cards`/`deck_words`; die erste bleibt 1. Alle Änderungen entsprechen dem
Patch. Andere alte Felder und Stapel bleiben wertgleich, Registry-Originalpositionen
unverändert. Alle 847 alten Karten-IDs und historischen Zeilen sind erhalten.
Der Exporter und ein zusätzlicher Readback vergleichen sämtliche Zeilen aller
18 SQLite-Tabellen mit `build_rows`; die erwarteten Zahlen wurden ohne Weglassen
von Daten erreicht. Audit: `build/alltag_batch_2_checks/export-audit.json`.

Nach grünen Prüfungen und Sicherung wurden Asset und Manifest intern gestagt.
`--verify` und der produktive Pack-Lesetest bestätigen 160/489/163 Lernziele,
160/500/163 Wortbesitzkarten und jeweils feste Satzzuordnungen.
Der bestehende Test erhielt ausschließlich zusätzliche Erwartungswerte für
Batch 2; seine Batch-1-Prüfung bleibt erhalten.

## Batch 3

Der vorhandene Fortsetzungsmodus erzeugte getrennte Snapshots:

- `pipeline/data/selection/alltag_zuhause_batch_3_context_v1.json`
- `pipeline/data/words/en.alltag_zuhause_batch_3_context_v1.json`
- `pipeline/data/learning_groups/en.alltag_zuhause_batch_3_context_v1.json`

Bindung an den tatsächlich neuen Pack-JSON- und SQLite-Hash. Alle 241
Originaleinträge und 901 Registry-Wortzeilen bleiben unverändert; Partition
163 importiert / 78 aktuell / 0 später. 927 Bestandskarten sind durch 915
Gruppen abgedeckt, 78 weitere Köpfe reserviert. Keine doppelten Reservierungen,
Besitzer-/Gruppen-/Identitätskonflikte oder ungenutzten Definitionsentscheidungen.

Bei den verbleibenden Zielen werden die vorgeschlagenen Senses für skirt,
blouse, lid, fry, toy, sew, catch und fit aus dem vorhandenen Wörterbuch
wiederverwendet. Keine neuen Definitionskonflikte; die einzelne jeans-Entscheidung
bleibt für die unveränderte Originalauswahl erforderlich und gültig.

Anhängepositionen 164–241 und die gemeinsame Anzeigezuordnung 1–241 sind separat
vorbereitet. Das gestagte Batch-2-Pack wird dadurch nicht verändert.
Keine Batch-3-Lernkarten oder -Sätze erzeugt.

Die ZIP enthält 83 Dateien: vollständige Basis als JSON und SQLite, Wörterbuch,
Identitäten, ursprüngliche Auswahl, Registry, Lerngruppen, Schema, tatsächliche
Projektquellen, Modellgewichte, Konfiguration, Paket-Lock und Hashmanifest.
Erneutes Öffnen mit dem bestehenden ZIP-Verifier bestätigt alle 82
Nutzdateihashes, Provenienz, Partitionen und den vollständigen SQLite-Abgleich.

## Umfang und offene Punkte

Neu: Exportverzeichnis, drei Batch-3-Snapshots, ZIP, dieser Bericht und lokale
Prüfprotokolle. Geändert: Asset/Manifest, `test/data/real_pack_test.dart`,
`NEXTSTEPS.md` (25 Zeilen). App-Einstieg, App-Logik, SRS, Synonymregeln,
Produktionsmodelle, Budgets, Supabase und Plattformdateien bleiben unberührt.
Keine echte user.db geöffnet, keine Lernstände/Reviews verändert; der Flutter-Test
verwendet ein temporäres Testverzeichnis. Keine Cloud-/Modellaufrufe,
Veröffentlichung, Commits oder Pushes. Kein Geräte-/Emulatortest durchgeführt.
Keine offenen Importfehler. Offen bleibt die Redaktion der 78 Batch-3-Ziele.

## Tatsächliche Prüfungen und Exitcodes

Ausgeführt im Repository-Root unter Windows PowerShell. Für die folgenden
Python-Befehle steht `PYTHON` auf Windows für
`.\pipeline\.venv\Scripts\python.exe`, auf macOS Terminal für
`pipeline/.venv/bin/python`; alle folgenden Argumente sind identisch.
Dart-, Flutter- und Git-Befehle sind auf beiden Systemen identisch.
Erstellungs-/Stagingbefehle dokumentieren den erfolgten Lauf; vorhandene Ausgaben
dürfen nicht erneut überschrieben werden. Vollständige Logs liegen unter
`build/alltag_batch_2_checks/`. Das NOT RUN des Lieferverifiers beschreibt nur
dessen eigenen Umfang; Staging und Flutter wurden separat ausgeführt.


```text
$ PYTHON alltag_zuhause_batch_2/verify_alltag_zuhause_batch_2.py --repo .
PASS source/delivery hashes, JSON Schema, continuation 83/80/78 and base SQLite
PASS display patch: append 84..163, final 1..163, original registry positions preserved
PASS create_content/build_rows: 927 cards, 812 primary learning goals, 18 tables
PASS 80 reserved identities; 80 sentence reviews; all historical rows preserved
PASS tokenizer and linter: 967 tokens, 0 errors, 34 warnings
PASS 8 sentence-specific alternative substitutions; no automatic group synonyms
Export omitted (use --export-check NEW_DIRECTORY for SQLite readback)
NOT RUN: asset staging, Flutter tests, device tests or user database access
Exit: 0
```


```text
$ PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/alltag_zuhause_batch_1_v1/pack.json --create alltag_zuhause_batch_2/alltag_zuhause_batch_2.editorial.json --registry pipeline/data/words/en.alltag_zuhause_batch_2_context_v1.json --display-patch alltag_zuhause_batch_2/alltag_zuhause_batch_2.display.json --out pipeline/out/alltag_zuhause_batch_2_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 1908,
    "senses": 3080,
    "cards": 927,
    "dictionary_forms": 3398,
    "decks": 3,
    "deck_cards": 927,
    "deck_words": 823,
    "word_aliases": 10,
    "sentences": 1461,
    "sentence_tokens": 15435,
    "card_sentences": 1455,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "736ccd251ff3f84fe2577f48113a76f4b0a750bb64679c58810533c59109bee9"
}
Exit: 0
```


```text
$ Zusätzlicher Python-Readback: check_sqlite(content.sqlite, build_rows(pack)); Altzeilen-/ID-/Baseline-Abgleich
display row example: {'card_ref': 'house|house/NOUN|house#haus', 'form_norm': 'house', 'original_position': 1, 'expected_position': 1, 'position': 1}
{
  "status": "PASS",
  "sqlite_tables": {
    "languages": 1,
    "lemmas": 1908,
    "senses": 3080,
    "cards": 927,
    "dictionary_forms": 3398,
    "decks": 3,
    "deck_cards": 927,
    "deck_words": 823,
    "word_aliases": 10,
    "sentences": 1461,
    "sentence_tokens": 15435,
    "card_sentences": 1455,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "old_card_ids_preserved": 847,
  "primary_learning_goals": {
    "allgemeine-sprache": 160,
    "reisen": 489,
    "alltag-zuhause": 163
  },
  "protected_files_byte_identical_before_staging": 1093,
  "pack_sha256": "b24f5599646120c62dca163dccb3cd5d2d27c71206be76fb8690a303f8b96d7c"
}
Exit: 0
```


```text
$ PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_word_registry.py pipeline/tests/test_selection.py pipeline/tests/test_learning_groups.py pipeline/tests/test_deck_display.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py -q
.......................................................... [ 60%]
......................................                              [100%]
96 passed, 19 subtests passed in 1.93s
Exit: 0
```


```text
$ dart run tool/stage_content_pack.dart --from pipeline/out/alltag_zuhause_batch_2_v1
staged assets\content\en\content.sqlite
  version alltag_zuhause_batch_2_v1, schema 3, 7561216 bytes
  sha256 736ccd251ff3f84fe2577f48113a76f4b0a750bb64679c58810533c59109bee9
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
Exit: 0
```


```text
$ dart run tool/stage_content_pack.dart --verify
verified assets\content\en\content.sqlite
  version alltag_zuhause_batch_2_v1, schema 3, 7561216 bytes
  sha256 736ccd251ff3f84fe2577f48113a76f4b0a750bb64679c58810533c59109bee9
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
Exit: 0
```


```text
$ flutter test test/data/real_pack_test.dart
00:00 +0: loading C:/Users/ardas/Music/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
deck allgemeine-sprache: 160 learning targets, 160 ownership cards, 160 fixed sentence assignments verified
deck reisen: 489 learning targets, 500 ownership cards, 500 fixed sentence assignments verified
deck alltag-zuhause: 163 learning targets, 163 ownership cards, 163 fixed sentence assignments verified
pack alltag_zuhause_batch_2_v1 (schema 3, internal: true); 3 decks: 823 cards, 927 card sentences, 94 with valid_alternatives, 927 cards in the pack
00:05 +1: All tests passed!
Exit: 0
```


```text
$ flutter analyze
Analyzing sprachapp...                                          
No issues found! (ran in 2.1s)
Exit: 0
```


```text
$ PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltag_zuhause_v1.json --batch 3 --prepare-continuation alltag_zuhause_batch_3_context_v1 --definition-equivalences pipeline/data/selection/alltag_zuhause_definition_equivalences_v1.json
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/alltag_zuhause_batch_3_context_v1.json",
    "registry": "pipeline/data/words/en.alltag_zuhause_batch_3_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.alltag_zuhause_batch_3_context_v1.json"
  },
  "partition_counts": {
    "imported": 163,
    "current": 78,
    "future": 0
  }
}
Exit: 0
```


```text
$ PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltag_zuhause_batch_3_context_v1.json --batch 3 --out build/alltag_zuhause_authoring_batch_3.zip
{
  "export": "PASS",
  "zip": "C:\\Users\\ardas\\Music\\sprachapp\\build\\alltag_zuhause_authoring_batch_3.zip",
  "files": 83,
  "status": "PASS",
  "selected": 241,
  "excluded": 9,
  "partition_counts": {
    "imported": 163,
    "current": 78,
    "future": 0
  },
  "reused_proposed_senses": 8,
  "batches": {
    "1": 83,
    "2": 80,
    "3": 78
  },
  "topics_per_batch": {
    "1": {
      "Wohnen": 10,
      "Haushalt": 10,
      "Kleidung": 10,
      "Einkaufen": 8,
      "Kochen": 14,
      "Familie": 10,
      "Freizeit": 10,
      "Alltagst�tigkeiten": 11
    },
    "2": {
      "Wohnen": 9,
      "Haushalt": 10,
      "Kleidung": 10,
      "Einkaufen": 7,
      "Kochen": 13,
      "Familie": 10,
      "Freizeit": 10,
      "Alltagst�tigkeiten": 11
    },
    "3": {
      "Wohnen": 9,
      "Haushalt": 10,
      "Kleidung": 10,
      "Einkaufen": 7,
      "Kochen": 13,
      "Familie": 10,
      "Freizeit": 9,
      "Alltagst�tigkeiten": 10
    }
  },
  "existing_senses": 122,
  "new_senses": 119,
  "existing_cards": 927,
  "existing_groups": 915,
  "new_groups": 78,
  "registry_words": 901,
  "partition_selection": "PASS: 163 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}
Exit: 0
```


```text
$ PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/alltag_zuhause_authoring_batch_3.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "228209c1816cf242b6085c1fd9a46eb97d699a83939842a42eed15dc90ad2229",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 927,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 241,
  "excluded": 9,
  "partition_counts": {
    "imported": 163,
    "current": 78,
    "future": 0
  },
  "reused_proposed_senses": 8,
  "batches": {
    "1": 83,
    "2": 80,
    "3": 78
  },
  "topics_per_batch": {
    "1": {
      "Wohnen": 10,
      "Haushalt": 10,
      "Kleidung": 10,
      "Einkaufen": 8,
      "Kochen": 14,
      "Familie": 10,
      "Freizeit": 10,
      "Alltagst�tigkeiten": 11
    },
    "2": {
      "Wohnen": 9,
      "Haushalt": 10,
      "Kleidung": 10,
      "Einkaufen": 7,
      "Kochen": 13,
      "Familie": 10,
      "Freizeit": 10,
      "Alltagst�tigkeiten": 11
    },
    "3": {
      "Wohnen": 9,
      "Haushalt": 10,
      "Kleidung": 10,
      "Einkaufen": 7,
      "Kochen": 13,
      "Familie": 10,
      "Freizeit": 9,
      "Alltagst�tigkeiten": 10
    }
  },
  "existing_senses": 122,
  "new_senses": 119,
  "existing_cards": 927,
  "existing_groups": 915,
  "new_groups": 78,
  "registry_words": 901,
  "partition_selection": "PASS: 163 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}
Exit: 0
```


```text
$ PYTHON build/alltag_batch_2_checks/final_audit.py
{
  "status": "PASS",
  "baseline_files": 1093,
  "protected_files_byte_identical": 1089,
  "authorized_changed_files": [
    "NEXTSTEPS.md",
    "assets/content/en/content.manifest.json",
    "assets/content/en/content.sqlite",
    "test/data/real_pack_test.dart"
  ],
  "original_selection_entries_unchanged": 241,
  "registry_words_unchanged": 901,
  "positions": {
    "append": "164..241",
    "combined": "1..241"
  },
  "new_batch_3_practice_sentences": 0,
  "asset_backups_byte_identical": true,
  "app_entry_unchanged": true
}
Exit: 0
```


```text
$ git diff --check
warning: in the working copy of 'docs/pipeline.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'pipeline/pyproject.toml', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'pipeline/scripts/import_editorial_patch.py', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'test/data/real_pack_test.dart', LF will be replaced by CRLF the next time Git touches it
Exit: 0
```


```text
$ git status --short
M ARCHITECTURE.md
 M DESIGN.md
 M NEXTSTEPS.md
 M PRODUCT.md
 M docs/content-schema.md
 M docs/decks-and-story-learning-plan.md
 M docs/pipeline.md
 M docs/reisen-500-authoring.md
 M docs/srs.md
 M docs/user-schema.md
 M lib/data/content/content_database.dart
 M lib/data/content/drift_content_repository.dart
 M lib/data/learning/practice_item_resolver.dart
 M lib/data/user/drift_user_repository.dart
 M lib/domain/answer_check.dart
 M lib/domain/content.dart
 M lib/domain/leitner.dart
 M lib/domain/new_card_selection.dart
 M lib/domain/repositories.dart
 M lib/domain/review_pass.dart
 M lib/domain/srs_state.dart
 M lib/domain/story_learning.dart
 M lib/presentation/providers/deck_providers.dart
 M lib/presentation/providers/learning_providers.dart
 M pipeline/data/curation/editorial_content_v2.schema.json
 M pipeline/pyproject.toml
 M pipeline/requirements.lock
 M pipeline/scripts/import_editorial_patch.py
 M pipeline/src/sprachpipe/content_contract.py
 M pipeline/src/sprachpipe/pack.py
 M pipeline/src/sprachpipe/schema.py
 M pipeline/tests/test_editorial_import.py
 M test/data/real_pack_test.dart
 M test/data/review_flow_test.dart
 M test/deck_flow_test.dart
 M test/domain/answer_check_test.dart
 M test/domain/review_pass_test.dart
?? alltag_zuhause_batch_1/
?? alltag_zuhause_batch_2/
?? docs/alltag-zuhause-authoring.md
?? docs/alltag-zuhause-batch-1-import.md
?? docs/alltag-zuhause-batch-2-import.md
?? docs/alltag-zuhause-continuation.md
?? docs/learning-groups-v1.md
?? docs/reisen-batch-2-import.md
?? docs/reisen-batch-3-import.md
?? docs/reisen-batch-4-import.md
?? docs/reisen-batch-5-import.md
?? lib/domain/learning_groups.dart
?? pipeline/data/curation/reisen_batch_2.editorial.json
?? pipeline/data/curation/reisen_batch_2_display_v1.json
?? pipeline/data/curation/reisen_batch_3.editorial.json
?? pipeline/data/curation/reisen_batch_3_display_v1.json
?? pipeline/data/curation/reisen_batch_4.editorial.json
?? pipeline/data/curation/reisen_batch_4_display_v1.json
?? pipeline/data/curation/reisen_batch_5.editorial.json
?? pipeline/data/curation/reisen_batch_5_display_v1.json
?? pipeline/data/learning_groups/
?? pipeline/data/selection/alltag_zuhause_batch_2_context_v1.json
?? pipeline/data/selection/alltag_zuhause_batch_3_context_v1.json
?? pipeline/data/selection/alltag_zuhause_definition_equivalences_v1.json
?? pipeline/data/selection/alltag_zuhause_v1.json
?? pipeline/data/words/en.alltag_zuhause_batch_2_context_v1.json
?? pipeline/data/words/en.alltag_zuhause_batch_3_context_v1.json
?? pipeline/data/words/en.alltag_zuhause_v1.json
?? pipeline/data/words/en.reisen_batch_3_v1.json
?? pipeline/data/words/en.reisen_batch_4_v1.json
?? pipeline/data/words/en.reisen_batch_5_v1.json
?? pipeline/scripts/export_authoring_context.py
?? pipeline/scripts/export_learning_groups.py
?? pipeline/src/sprachpipe/authoring_context.py
?? pipeline/src/sprachpipe/deck_display.py
?? pipeline/src/sprachpipe/learning_groups.py
?? pipeline/tests/test_authoring_context.py
?? pipeline/tests/test_authoring_continuation.py
?? pipeline/tests/test_authoring_schema3.py
?? pipeline/tests/test_deck_display.py
?? pipeline/tests/test_learning_groups.py
?? reisen_batch_2/
?? reisen_batch_3/
?? reisen_batch_4/
?? reisen_batch_5/
?? supabase/migrations/20261006000001_learning_groups.sql
?? test/data/learning_groups_test.dart
?? test/domain/learning_groups_test.dart
?? tool/report_learning_groups.dart
Exit: 0
```
