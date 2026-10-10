# Alltag & Zuhause: internes Staging und Fortsetzung, 07.10.2026

Batch 1 ist als `alltag_zuhause_batch_1_v1` intern gestagt. Der unveränderte
Lieferverifier, SQLite-Prüfung und Dreistapel-Lesetest bestehen: 847 physische
Karten, 732 primäre Lernziele (160 Allgemeine Sprache / 489 Reisen / 83 Alltag).
Der bereits vorhandene Export wurde weder neu erzeugt noch überschrieben.
SQLite-SHA256: `f2439e023c2f835477c0a806b9a72fc495313bfefb7ef32fe0272f0b8b63c9ca`.

Die separat geprüfte ZIP `build/alltag_zuhause_authoring_batch_2.zip` enthält
80 aktuelle Ziele und den vollständigen Kontext auf dieser Basis. SHA256:
`30b215513af2729d9e6881f2f3dd637e97f51c52ab887dd3a9e6c9ae38fdd87a`.
83 Dateien, davon 82 im Hashmanifest; keine neuen Batch-2-Übungssätze.

## Abhängigkeiten und erlaubte Normalisierung

`pipeline/.venv/Scripts/python.exe -m pip install jsonschema` endete mit Exit 0.
Neu installiert wurden jsonschema 4.26.0, attrs 26.1.0,
jsonschema-specifications 2025.9.1, referencing 0.37.0 und rpds-py 2026.9.1.
typing-extensions 4.16.0 war bereits vorhanden. Keine bestehenden Pakete aktualisiert.
jsonschema ist in pyproject.toml exakt gepinnt, alle fünf Pakete in requirements.lock.

Nach der Installation meldete der unveränderte Lieferverifier einen Bytekonflikt:
Die ursprüngliche Wort- und Gruppenregistry hatten CRLF statt LF. Arda erlaubte
ausdrücklich ausschließlich die Normalisierung der Zeilenenden nach Sicherung.
Betroffen: `pipeline/data/words/en.alltag_zuhause_v1.json` und
`pipeline/data/learning_groups/en.alltag_zuhause_v1.json`. Die Originalbytes liegen
unter `build/alltag_continuation_checks/registry_original_bytes/`.
JSON-Werte, Versionen, IDs und kanonische Hashes sind unverändert. Original-Lieferung,
alte Packs und ursprüngliche Auswahl bleiben bytegleich. Der abschließende Audit
bestätigt 336 bytegleiche Dateien und genau diese zwei erlaubten Normalisierungen.

Vor Staging wurden das bisherige learning_groups_v1-Asset und Manifest bytegleich
unter `build/alltag_continuation_checks/asset_backup/` gesichert.

## Fortsetzungsvertrag

Der bestehende Exporter und `authoring_context.validate_context` unterstützen einen
ausdrücklichen Fortsetzungsmodus. Erstimport-Prüfungen bleiben erhalten. Die
ursprünglichen 241 Einträge werden vollständig und unverändert eingebettet und
verglichen: 83 importiert, 80 aktuell, 78 später; disjunkte vollständige Partition.
Vorhandene Karten werden einschließlich Besitzer, Gruppe, IDs und festem Satz
mit Tokenhash geprüft. Aktuelle/spätere Karten dürfen noch nicht vorhanden sein.
Wortbesitz-, Alias- und Gruppenprüfungen verwenden die bestehenden Validatoren.

Neue Snapshots:

- `pipeline/data/selection/alltag_zuhause_batch_2_context_v1.json`
- `pipeline/data/words/en.alltag_zuhause_batch_2_context_v1.json`
- `pipeline/data/learning_groups/en.alltag_zuhause_batch_2_context_v1.json`

Sie binden an das tatsächlich gestagte Batch-1-Pack und dessen SQLite-Hash.
Registry-Parent ist der eingebettete Registry-Snapshot. Alle 901 Wortzeilen bleiben
identisch; keine Reservierungen erneut angehängt. Gruppen decken alle 847 Karten
(835 Gruppen) ab, weitere 158 Köpfe bleiben reserviert. Die ursprünglichen
Gruppenentscheidungen sind separat mit Hash erhalten.

Acht ursprünglich vorgeschlagene Senses sind inzwischen Begleitwort-Senses:
sofa, toy, wipe, fit, jeans, flour, fry, lid. Sie werden wiederverwendet, nicht als
bereits eingeführte Lernkarten gezählt. Diese acht betreffen beide verbleibenden
Gruppen. Die ursprüngliche Klassifikation 122 vorhandene / 119 vorgeschlagene
Senses bleibt historische Auswahlinformation; `sense_availability` bezeichnet
die tatsächliche Wiederverwendung je aktuellem Ziel.

Ein konkreter Definitionsvergleich benötigt eine redaktionelle Entscheidung:
jeans reserviert „Eine robuste Hose aus Denimstoff.“, bestehend „Eine Hose aus
festem Denimstoff.“. Beide beschreiben dieselbe Zielbedeutung; beide Texte bleiben
unverändert. `alltag_zuhause_definition_equivalences_v1.json` dokumentiert diese
einzelne Entscheidung mit beiden exakten Texten, Sense-Hash und Begründung.
Ohne passende Entscheidung scheitert der Konflikt; unbenutzte Entscheidungen
werden abgelehnt. Es gibt keine allgemeine Freigabe abweichender Definitionen.

Originalpositionen bleiben erhalten. Der Kontext trennt Bestandsanzeige 1–83,
Anhängepositionen 84–163 und gemeinsame endgültige Zuordnung 1–163 nach
Originalposition. Diese wird mit dem bestehenden `apply_deck_display_patch`
auf einer temporären Mitgliedschaftskopie geprüft. Beim späteren echten Import
müssen Create-Dateihash und Vorher-Zeilenhashes für `--display-patch` gebunden werden.
Die ZIP enthält eine vorbereitete Zuordnung, keinen vorgetäuschten ausführbaren
Patch. Das gestagte Pack wurde nicht umsortiert; Lernreihenfolge bestimmt die App.

ZIP-Inhalt: Basis-JSON/SQLite, Wörterbuch, alle Identitäten und Zieldefinitionen,
Originalauswahl, Registry, Gruppen, Anzeigezuordnungen, Importschema, echte
Importer-/Tokenizer-/Linterquellen, Modell, Konfiguration, Paket-Lock und Umgebung.
Hashes und Referenzen werden nach erneutem Öffnen geprüft, SQLite gegen alle
18 build_rows-Tabellen. Keine Zugangsdaten oder Lernstände; Python-Venv nicht enthalten.

Synthetische Tests prüfen Erstimport, Fortsetzung und Batch 3 nach simuliertem
Batch-2-Import, Begleitwort-Reuse, Quellen-/Parenthash, IDs, Definitionen,
doppelte Reservierungen, fremden Besitzer, Gruppenköpfe, Satzbindung,
Partitionen und lückenlose Anzeigezuordnung. Keine out/-abhängigen Fixtures.
Keine App-/SRS-/Synonymregeländerung in diesem Auftrag, keine echte user.db,
Gerätetests, Modell-/Supabase-Aufrufe, Veröffentlichung, Commits oder Pushes.

## Ausgeführte Befehle

Windows PowerShell ab Repository-Stamm verwendet `pipeline/.venv/Scripts/python.exe`.
macOS Terminal verwendet stattdessen `pipeline/.venv/bin/python` mit gleichen
Argumenten. Dart-, Flutter- und Git-Befehle sind identisch auf beiden Systemen.
Die folgenden Erstellungsbefehle überschreiben bestehende Snapshots/ZIPs absichtlich
nicht; ihre bereits erzeugten Ergebnisse werden anschließend separat geprüft.

```text
pipeline/.venv/Scripts/python.exe pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltag_zuhause_v1.json --batch 2 --prepare-continuation alltag_zuhause_batch_2_context_v1 --definition-equivalences pipeline/data/selection/alltag_zuhause_definition_equivalences_v1.json
snapshots: PASS; partition_counts: imported 83, current 80, future 78
Exit: 0

pipeline/.venv/Scripts/python.exe pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltag_zuhause_batch_2_context_v1.json --batch 2 --out build/alltag_zuhause_authoring_batch_2.zip
export: PASS; files: 83; selected: 241; partition_counts: 83/80/78
Exit: 0

dart run tool/stage_content_pack.dart --from pipeline/out/alltag_zuhause_batch_1_v1
version alltag_zuhause_batch_1_v1, schema 3, 7122944 bytes
sha256 f2439e023c2f835477c0a806b9a72fc495313bfefb7ef32fe0272f0b8b63c9ca
18 table counts match finalization_report.json
INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit: 0

dart run tool/stage_content_pack.dart --verify
version alltag_zuhause_batch_1_v1, schema 3, 7122944 bytes
sha256 f2439e023c2f835477c0a806b9a72fc495313bfefb7ef32fe0272f0b8b63c9ca
18 table counts match finalization_report.json
Exit: 0

flutter test test/data/real_pack_test.dart
deck allgemeine-sprache: 160 learning targets, 160 ownership cards, 160 fixed sentence assignments verified
deck reisen: 489 learning targets, 500 ownership cards, 500 fixed sentence assignments verified
deck alltag-zuhause: 83 learning targets, 83 ownership cards, 83 fixed sentence assignments verified
pack alltag_zuhause_batch_1_v1 (schema 3, internal: true); 3 decks: 743 cards, 847 card sentences, 89 with valid_alternatives, 847 cards in the pack
00:04 +1: All tests passed!
Exit: 0

flutter analyze
No issues found! (ran in 2.1s)
Exit: 0
```

Die Erstellungs- und Staging-Ausgaben oben sind auf ihre Ergebniszeilen gekürzt.
Die vollständigen abschließenden Validatorausgaben folgen. Das NOT RUN des
Lieferverifiers beschreibt ausschließlich dessen Umfang; Staging und Flutter
wurden separat wie oben ausgeführt. 26 Linterwarnungen sind Häufigkeitshinweise,
keine Fehler. Git-Status umfasst auch schon vorher vorhandene Änderungen.

```text
$ pipeline/.venv/Scripts/python.exe -m pip show jsonschema
Name: jsonschema
Version: 4.26.0
Summary: An implementation of JSON Schema validation for Python
Home-page: https://github.com/python-jsonschema/jsonschema
Author: 
Author-email: Julian Berman <Julian+jsonschema@GrayVines.com>
License-Expression: MIT
Location: C:\Users\ardas\Music\sprachapp\pipeline\.venv\Lib\site-packages
Requires: attrs, jsonschema-specifications, referencing, rpds-py
Required-by: 
Exit: 0
```

```text
$ pipeline/.venv/Scripts/python.exe -m pip check
No broken requirements found.
Exit: 0
```

```text
$ pipeline/.venv/Scripts/python.exe alltag_zuhause_batch_1/verify_alltag_zuhause_batch_1.py --repo .
PASS source/delivery hashes and JSON Schema
PASS create_content/build_rows: 847 cards, 732 primary learning goals, 18 tables
PASS 83 reserved identities; 83 sentence reviews; all historical rows preserved
PASS tokenizer and linter: 931 tokens, 0 errors, 26 warnings
PASS 9 sentence-specific alternative substitutions; no automatic group synonyms
Export omitted (use --export-check NEW_DIRECTORY for SQLite readback)
NOT RUN: asset staging, Flutter tests, device tests or user database access
Exit: 0
```

```text
$ pipeline/.venv/Scripts/python.exe -m pytest pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_word_registry.py pipeline/tests/test_selection.py pipeline/tests/test_learning_groups.py pipeline/tests/test_deck_display.py -q
...................................................................                                                           [100%]
67 passed, 19 subtests passed in 1.60s
Exit: 0
```

```text
$ pipeline/.venv/Scripts/python.exe pipeline/scripts/export_authoring_context.py --verify-zip build/alltag_zuhause_authoring_batch_2.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "30b215513af2729d9e6881f2f3dd637e97f51c52ab887dd3a9e6c9ae38fdd87a",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 847,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 241,
  "excluded": 9,
  "partition_counts": {
    "imported": 83,
    "current": 80,
    "future": 78
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
      "Alltagstätigkeiten": 11
    },
    "2": {
      "Wohnen": 9,
      "Haushalt": 10,
      "Kleidung": 10,
      "Einkaufen": 7,
      "Kochen": 13,
      "Familie": 10,
      "Freizeit": 10,
      "Alltagstätigkeiten": 11
    },
    "3": {
      "Wohnen": 9,
      "Haushalt": 10,
      "Kleidung": 10,
      "Einkaufen": 7,
      "Kochen": 13,
      "Familie": 10,
      "Freizeit": 9,
      "Alltagstätigkeiten": 10
    }
  },
  "existing_senses": 122,
  "new_senses": 119,
  "existing_cards": 847,
  "existing_groups": 835,
  "new_groups": 158,
  "registry_words": 901,
  "partition_selection": "PASS: 83 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}
Exit: 0
```

```text
$ pipeline/.venv/Scripts/python.exe build/alltag_continuation_checks/audit.py
{
  "protected_files_byte_identical": 336,
  "authorized_CRLF_to_LF_only": 2,
  "original_selection_entries_unchanged": 241,
  "registry_words_unchanged": 901,
  "positions": {
    "existing": "1..83",
    "append": "84..163",
    "combined": "1..163"
  },
  "new_practice_sentences": 0,
  "app_entry_unchanged": true,
  "status": "PASS"
}
Exit: 0
```

```text
$ git diff --check
warning: in the working copy of 'docs/pipeline.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'pipeline/pyproject.toml', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'pipeline/scripts/import_editorial_patch.py', LF will be replaced by CRLF the next time Git touches it
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
?? docs/alltag-zuhause-authoring.md
?? docs/alltag-zuhause-batch-1-import.md
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
?? pipeline/data/selection/alltag_zuhause_definition_equivalences_v1.json
?? pipeline/data/selection/alltag_zuhause_v1.json
?? pipeline/data/words/en.alltag_zuhause_batch_2_context_v1.json
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
