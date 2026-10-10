# Alltag & Zuhause: Abschluss mit Batch 3

Stand 07.10.2026: `alltag_zuhause_batch_3_v1`, Schema 3, ist intern gestagt.
Alle 241 ursprünglich ausgewählten Alltag-Lernziele sind vollständig und genau
einmal enthalten: 83 + 80 + 78. Kein Restbatch, kein Batch 4, kein neuer Stapel.

| Kennzahl | Ergebnis |
|---|---:|
| Physische Karten | 1005 |
| Primäre Lernziele | 890 |
| Allgemeine Sprache / Reisen / Alltag & Zuhause | 160 / 489 / 241 |
| Wortbesitzzeilen | 901 |
| Satztexte | 1539 |
| Satzverknüpfungen inklusive Historie | 1533 |
| Erhaltene alte Karten-IDs | 927 |
| Neue Satzpaare / Tokenpositionen / Alternativen | 78 / 937 / 7 |

## Hashbindung und Bestandsschutz

- Basis-JSON: `b24f5599646120c62dca163dccb3cd5d2d27c71206be76fb8690a303f8b96d7c`.
- Neues Pack-JSON: `bb092533f44af47f168f1b432226f4999585e8b4ad5f789ca544abe04fe32be0`.
- Neues SQLite und gestagtes Asset: `9fd1a5e546ba32e92bdbb519008414dc34225f76552e79d8271a71af50a1cbe3`.
- Vorheriges Asset: `736ccd251ff3f84fe2577f48113a76f4b0a750bb64679c58810533c59109bee9`.

Die Lieferung lag bereits als `alltag_zuhause_batch_3/` vor. Unverändert verwendet;
kein Entpacken über vorhandene Dateien und keine Referenzquelle über Projektcode
kopiert. Liefer- und Referenzmanifest sowie Vertragsbindung wurden mit dem
unveränderten Verifier geprüft. Registry/Gruppen kanonisch verglichen,
Pack/SQLite rohbytegebunden. Keine Hashprüfung umgangen, keine Paketupdates.

Vor Änderungen: Git-Status und Hashes von 1198 Dateien unter
`build/alltag_batch_3_checks/baseline.json` und `git-status-before.txt` erfasst.
Asset/Manifest und die zwei zu bearbeitenden Bestandsdateien sind unter
`asset_backup/` gesichert. Abschluss: 1194 Dateien bytegleich; nur Asset, Manifest,
Pack-Lesetest und NEXTSTEPS verändert. Alte Packs, Registrys, Auswahlen,
Original-Lieferung, App-Einstieg und vorherige Änderungen bleiben erhalten.

## Sprachliche Gegenlesung und bekannte Altbestände

Alle 78 Satzpaare gegen die Zieldefinitionen gegengelesen, alle Wortbindungen,
neuen Senses und neuen Formglossen geprüft. Die 937 Tokenpositionen sind durch
den Tokenizer vollständig einschließlich Satzzeichen gebunden; Worttokens haben
Sense-/Lemma- und Formglossenreferenzen. Keine konkret belegten Lieferfehler
festgestellt. Originale, Reviewhashes und Create-Bindung bleiben unverändert;
keine automatische Neugenerierung. Einzelprotokoll mit den 78 Paaren:
`build/alltag_batch_3_checks/editorial-review.json`.
Dies ist eine Codex-Gegenlesung, keine unabhängige menschliche Zertifizierung.

Wörtlich eingesetzte und gegengelesene Alternativen:

| Alternative | Vollständiger Satz |
|---|---|
| trash | Please take the trash out before the bin starts to smell. |
| garbage | Please take the garbage out before the bin starts to smell. |
| vacuum cleaner | The vacuum cleaner is full; empty it before you clean the carpet. |
| refrigerator | Keep the milk in the refrigerator so it stays fresh. |
| sneaker | There is a small stone inside my sneaker; I need to remove it. |
| yogurt | I mix plain yogurt with fresh fruit for breakfast. |
| tv | The tv is too large for this small living room. |

`tv` ist vertragsgemäß normalisiert gespeichert. Sieben Alternativen betreffen
sechs Satzbindungen; aktive Sätze mit Alternativen steigen von 94 auf 100.
`accepted` enthält ausschließlich die Zielform. Alternative Antworten bleiben
neutral nach bestehenden Regeln; keine App-/Synonymregel verändert.

Die Lernkarte `wrapper|wrapper/NOUN|wrapper#verpackungshulle` verwendet exakt
die reservierte Identität. `wrapper/NOUN|wrapper#verpackung` bleibt als älterer
gleichbedeutender Begleitwort-Sense unverändert erhalten. Nachweis: genau eine
wrapper-Lernkarte. Keine historischen Tokens umgehängt und keine Senses vereinigt.
Diese Wörterbuchredundanz bleibt ein möglicher separater Bereinigungspunkt.

Bestehende knappe/gebeugte Glossen bleiben unangetastet, etwa scissors
„einer Schere“, shelf „Regal“, glove „Handschuhe“, pet „Haustiere“ und magazine
„Zeitschriften“ in historischen Sense-Schlüsseln/Glossen. Die reservierten
Zielübersetzungen und neuen Formglossen bleiben davon getrennt erhalten.
Auch jeans-Gleichwertigkeitsentscheidung und die dokumentierte aisle-Reichweite
aus früheren Batches gelten unverändert. Keine globale Altglossenbereinigung.

Kontextuell getrennt geprüft: iron als Bügeleisen; television als Lernziel das
Gerät, als Begleitwort bei sport das Medium; smell als Lernziel Wahrnehmung,
bei rubbish Geruchsabgabe; fit beim Deckel Gegenstandspassung, als Lernziel
Kleidungsgröße. Die vorhandenen Wiederverwendungsentscheidungen bleiben erhalten.

Linter: 0 Fehler, 28 neue Häufigkeitswarnungen (`i+1`). Keine Umformulierungen
allein aufgrund dieser Hinweise. Der Finalisierungsbericht enthält zusätzlich
die Häufigkeitshinweise der alten Sätze.

## Import, vollständiger Auswahlabgleich und Anzeige

Bestehender Importer, neue Ausgabe `pipeline/out/alltag_zuhause_batch_3_v1/`.
Genau 78 neue Lernkarten mit unveränderten Identitäten, Zielübersetzungen und
`cards.learning`, jeweils ein fester Satz; keine Begleitwort-Lernkarten.
Alle alten Zeilen bleiben wertgleich außer den ausdrücklich erlaubten
Alltag-Anzeigepositionen. 927 alte Karten-IDs und historische Links erhalten.

Neue Mitgliedschaften zunächst 164–241, danach unveränderter hashgebundener
Display-Patch für 1–241. Von 163 alten Alltag-Mitgliedschaften verschieben sich
161 Positionen je Tabelle `deck_cards`/`deck_words`; die ersten zwei bleiben
stehen. Alle Änderungen exakt gegen den Patch verglichen. Andere Stapel und
Registry-Originalpositionen bleiben unverändert.

`build/alltag_batch_3_checks/audit.py` prüft zusätzlich am tatsächlichen Export:

- Alle 18 SQLite-Tabellen, sämtliche Zeilen gegen `build_rows`.
- Exakte Multimenge aller 241 ursprünglichen Karten-IDs gegen Wortbesitz.
- Je Ziel Lemma-ID, Sense-ID, Form, Zielübersetzung und vollständige Lernmetadaten.
- 241 verschiedene Lerngruppen und je genau einen aktiven festen Satz, Position 1.
- Anzeige lückenlos 1–241 und identische Reihenfolge zur sortierten Originalauswahl.
- Registry-Snapshot, vollständige Besitzer-/Alias-/Gruppenvalidierung durch `build_rows`.
- Keine fehlenden Ziele, keine zusätzliche wrapper-Lernkarte.

| Thema | Lernziele |
|---|---:|
| Wohnen | 28 |
| Haushalt | 30 |
| Kleidung | 30 |
| Einkaufen | 22 |
| Kochen | 40 |
| Familie | 30 |
| Freizeit | 29 |
| Alltagstätigkeiten | 32 |

## Staging, Änderungen und Grenzen

Nach Sicherung und grünen Prüfungen intern gestagt. `--verify` bestätigt
7979008 Bytes und 18 Tabellen. Der bestehende Pack-Lesetest erhielt gezielte
Batch-3-Erwartungen; ältere Prüfzweige bleiben erhalten. Produktiver Installer
und Repository lesen 160/489/241 Lernziele und 160/500/241 Wortbesitzkarten.

Neu: Export, dieser Bericht und lokale Prüfprotokolle. Geändert: Asset/Manifest,
`test/data/real_pack_test.dart`, `NEXTSTEPS.md` (25 Zeilen). Keine Änderungen an
App-Logik, SRS, Synonymregeln, Modellen, Budgets, Supabase oder Plattformdateien.
Keine echte user.db geöffnet oder verändert; Tests verwenden temporäre Daten.
Keine Cloud-/Modellaufrufe, Veröffentlichung, Commits oder Pushes.
Keine Geräte-/Emulatorprüfung durchgeführt. Keine offenen Import-/Prüffehler.

## iPhone nach Mac-Sync

1. Sync vollständig abschließen, einschließlich neuer Assets/Manifest und
   `pipeline/out/alltag_zuhause_batch_3_v1/` (gitignorierte Dateien mit übertragen).
2. Im Repository auf dem Mac `dart run tool/stage_content_pack.dart --verify`
   ausführen; Version und SQLite-Hash müssen den obigen Werten entsprechen.
3. App mit den neuen gebündelten Assets neu bauen und auf dem angeschlossenen
   iPhone starten, etwa mit `flutter run -d <iPhone-Geräte-ID>`.
4. Bestehende App aktualisieren, nicht deinstallieren; weder user.db noch
   App-Daten löschen. Der Content-Installer ersetzt nur die Inhaltsdatenbank
   unter dem Content-Verzeichnis und lässt Lernstände erhalten.

## Tatsächliche Prüfoutputs

Ausgeführt unter Windows PowerShell ab Repository-Root. `PYTHON` bezeichnet
hier `.\pipeline\.venv\Scripts\python.exe`; unter macOS Terminal ist es
`pipeline/.venv/bin/python` mit denselben Argumenten. Dart-/Flutter-/Git-Befehle
sind auf beiden Systemen identisch. Erzeugungsbefehle dokumentieren den erfolgten
Lauf; bestehende Ausgaben nicht überschreiben. Verifier-NOT-RUN betrifft nur
dessen eigenen Umfang, Staging und Flutter wurden separat ausgeführt.


```text
$ PYTHON alltag_zuhause_batch_3/verify_alltag_zuhause_batch_3.py --repo .
PASS source/delivery hashes, JSON Schema, continuation 163/78/0 and base SQLite
PASS display patch: append 164..241, final 1..241, original registry positions preserved
PASS all 241 original identities and learning metadata; no remaining batch
PASS create_content/build_rows: 1005 cards, 890 primary learning goals, 18 tables
PASS 78 reserved identities; 78 sentence reviews; all historical rows preserved
PASS tokenizer and linter: 937 tokens, 0 errors, 28 warnings
PASS 7 sentence-specific alternative substitutions; no automatic group synonyms
Export omitted (use --export-check NEW_DIRECTORY for SQLite readback)
NOT RUN: asset staging, Flutter tests, device tests or user database access
Exit: 0
```


```text
$ PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/alltag_zuhause_batch_2_v1/pack.json --create alltag_zuhause_batch_3/alltag_zuhause_batch_3.editorial.json --registry pipeline/data/words/en.alltag_zuhause_batch_3_context_v1.json --display-patch alltag_zuhause_batch_3/alltag_zuhause_batch_3.display.json --out pipeline/out/alltag_zuhause_batch_3_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 1958,
    "senses": 3143,
    "cards": 1005,
    "dictionary_forms": 3492,
    "decks": 3,
    "deck_cards": 1005,
    "deck_words": 901,
    "word_aliases": 11,
    "sentences": 1539,
    "sentence_tokens": 16372,
    "card_sentences": 1533,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "9fd1a5e546ba32e92bdbb519008414dc34225f76552e79d8271a71af50a1cbe3"
}
Exit: 0
```


```text
$ PYTHON build/alltag_batch_3_checks/audit.py
{
  "status": "PASS",
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 1958,
    "senses": 3143,
    "cards": 1005,
    "dictionary_forms": 3492,
    "decks": 3,
    "deck_cards": 1005,
    "deck_words": 901,
    "word_aliases": 11,
    "sentences": 1539,
    "sentence_tokens": 16372,
    "card_sentences": 1533,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "old_card_ids_preserved": 927,
  "exact_original_targets": 241,
  "batches": {
    "1": 83,
    "2": 80,
    "3": 78
  },
  "topics": {
    "Wohnen": 28,
    "Haushalt": 30,
    "Kleidung": 30,
    "Einkaufen": 22,
    "Kochen": 40,
    "Familie": 30,
    "Freizeit": 29,
    "Alltagst�tigkeiten": 32
  },
  "remaining_targets": 0,
  "primary_learning_targets": {
    "allgemeine-sprache": 160,
    "reisen": 489,
    "alltag-zuhause": 241
  },
  "old_display_positions_changed": {
    "deck_cards": 161,
    "deck_words": 161
  },
  "wrapper_learning_cards": 1,
  "pack_sha256": "bb092533f44af47f168f1b432226f4999585e8b4ad5f789ca544abe04fe32be0"
}
Exit: 0
```


```text
$ PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_deck_display.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_selection.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py -q
..................................................... [ 55%]
...........................................                              [100%]
96 passed, 19 subtests passed in 2.17s
Exit: 0
```


```text
$ dart run tool/stage_content_pack.dart --from pipeline/out/alltag_zuhause_batch_3_v1
staged assets\content\en\content.sqlite
  version alltag_zuhause_batch_3_v1, schema 3, 7979008 bytes
  sha256 9fd1a5e546ba32e92bdbb519008414dc34225f76552e79d8271a71af50a1cbe3
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
Exit: 0
```


```text
$ dart run tool/stage_content_pack.dart --verify
verified assets\content\en\content.sqlite
  version alltag_zuhause_batch_3_v1, schema 3, 7979008 bytes
  sha256 9fd1a5e546ba32e92bdbb519008414dc34225f76552e79d8271a71af50a1cbe3
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
deck alltag-zuhause: 241 learning targets, 241 ownership cards, 241 fixed sentence assignments verified
pack alltag_zuhause_batch_3_v1 (schema 3, internal: true); 3 decks: 901 cards, 1005 card sentences, 100 with valid_alternatives, 1005 cards in the pack
00:05 +1: All tests passed!
Exit: 0
```


```text
$ flutter analyze
Analyzing sprachapp...                                          
No issues found! (ran in 2.5s)
Exit: 0
```


```text
$ Python-Abgleich der Baseline-Hashes und Asset-Sicherungen
{
  "status": "PASS",
  "baseline_files": 1198,
  "protected_files_byte_identical": 1194,
  "authorized_changed_files": [
    "NEXTSTEPS.md",
    "assets/content/en/content.manifest.json",
    "assets/content/en/content.sqlite",
    "test/data/real_pack_test.dart"
  ],
  "asset_backups_byte_identical": true,
  "original_delivery_and_old_sources_unchanged": true,
  "app_entry_unchanged": true,
  "nextsteps_lines": 25
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
?? alltag_zuhause_batch_3/
?? docs/alltag-zuhause-authoring.md
?? docs/alltag-zuhause-batch-1-import.md
?? docs/alltag-zuhause-batch-2-import.md
?? docs/alltag-zuhause-batch-3-import.md
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
