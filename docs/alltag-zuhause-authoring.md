# Alltag & Zuhause — Authoring-Vorbereitung, 06.10.2026

## Aktualisierung 07.10.2026

Batch 1 ist intern als `alltag_zuhause_batch_1_v1` gestagt (847 Karten,
732 primäre Lernziele: 160/489/83). Der geprüfte Fortsetzungskontext für Batch 2
liegt unter `build/alltag_zuhause_authoring_batch_2.zip`: 80 aktuelle Ziele,
83 bereits importiert, 78 später. Alle 241 Originaleinträge bleiben unverändert.
Neue Snapshots heißen `alltag_zuhause_batch_2_context_v1`; alte Auswahlversionen
bleiben erhalten. Die zwei erlaubten CRLF→LF-Normalisierungen ändern keine Daten.
Anzeigezuordnung und Begleitwort-Sense-Reuse sind ausdrücklich geprüft.
Vollständiger aktueller Nachweis: [Fortsetzungsbericht](alltag-zuhause-continuation.md).
Die folgenden Abschnitte dokumentieren die ursprüngliche Vorbereitung vom 06.10.

## Ursprüngliche Vorbereitung

**241 neue eigenständige Lernziele**, verteilt auf **83 / 80 / 78** Wörter.
Alle drei Gruppen enthalten alle acht Themen. 250 Kandidaten wurden geprüft,
neun ausgeschlossen; keine Auffüllung auf 300 durch Varianten oder Randvokabular.
Noch keine Übungssätze, importierten Karten oder Änderungen am App-Pack.
Erste Gruppe zur Satzredaktion: `build/alltag_zuhause_authoring_batch_1.zip`.

## Tatsächliche Grundlage und Lerngruppen

Das Asset-Manifest bestimmt die Quelle, nicht der Name des letzten Reisebatches:
`pipeline/out/learning_groups_v1/pack.json`, **learning_groups_v1, Schema 3**.
Gestagtes SQLite und Quellen-SQLite sind hashgleich:
`a8359628ed273ee81037abcf24cdb494a2d8b2dc29d667100190c4b6a985651e`.
764 Karten, 660 Wortbesitzeinträge, 752 Gruppen über alle Karten, 649 primäre
Einführungsziele. Alle historischen Karten und Satzalternativen einbezogen.

Die Umsetzung ist in `lib/domain/learning_groups.dart`, `new_card_selection.dart`,
`answer_check.dart` und `review_pass.dart` vorhanden: bestehende Gruppenstände
reservieren das Ziel, neue Einführungen verwenden den Kopf, gelernte Zeilen bleiben
erhalten. Themen-/Kontrastabstand zunächst drei, bei Knappheit kontrollierte
Reduktion. Nur für die konkrete Lücke geprüfte Alternativen sind neutral.
Gruppenmitgliedschaft und Schreibalias sind keine automatische Antwortfreigabe.
Keine Flutter-Änderung oder erneute Flutter-Testausführung in diesem Auftrag.

Eine konkrete Vorbereitungslücke wurde behoben: Der Create-Importer akzeptierte
bisher nur Schema 2 und setzte die Ausgabe auf 2. Er akzeptiert jetzt 2/3, erhält
das Quellschema und lässt bei Schema 3 fehlende oder unauflösbare `cards.learning`
durch den bestehenden Gruppenvalidator ablehnen. Das Austauschformat bleibt
Version 2; dessen Schema beschreibt die Gruppenfelder jetzt ausdrücklich.
Kein neuer Importweg, kein bekannter verbleibender Blocker für diese Vorbereitung.

## Auswahl und Entscheidungen

| Thema | Gesamt | Gruppe 1 | Gruppe 2 | Gruppe 3 |
|---|---:|---:|---:|---:|
| Wohnen | 28 | 10 | 9 | 9 |
| Haushalt | 30 | 10 | 10 | 10 |
| Kleidung | 30 | 10 | 10 | 10 |
| Einkaufen | 22 | 8 | 7 | 7 |
| Kochen | 40 | 14 | 13 | 13 |
| Familie | 30 | 10 | 10 | 10 |
| Freizeit | 29 | 10 | 10 | 9 |
| Alltagstätigkeiten | 32 | 11 | 11 | 10 |
| **Gesamt** | **241** | **83** | **80** | **78** |

Maßgeblich: `pipeline/data/selection/alltag_zuhause_v1.json`. Jeder Eintrag enthält
Form, Lemma, POS, genaue Zieldefinition, natürliche deutsche Kartenübersetzung,
bestehende/vorgeschlagene Sense-Identität, Thema, Auswahlgrund, Schreibvarianten,
Synonymprüfung, Kontrastentscheidungen und eigene Gruppenmetadaten.
`stairs`, `scissors`, `trousers`, `jeans`, `pyjamas`, `tights` sind Pluralformen.
Der Kandidat „twins“ wurde auf das einzelne Lernziel „twin“ präzisiert.

**122 passende vorhandene Senses werden wiederverwendet; 119 sind neu definiert.**
Begleitwort-Senses gelten nicht automatisch als vorhandene Karten. Alte Senses
behalten auch flektierte Glossen und gegebenenfalls fehlende historische Definitionen;
die genaue neue Kartenbedeutung steht immer vollständig in `target_meaning_de`.
Historische Wörterbucheinträge werden nicht umgeschrieben.

Mehrere vorhandene Senses zum selben Lemma/POS wurden ausdrücklich unterschieden:
`sheet` Bettlaken statt Blatt; `cream` Sahne statt Speiseeis; `album` Fotoalbum statt
Musikalbum; `paint` Bilder malen statt Wände streichen; `catch` fangen statt den Bus
erwischen; `smell` Geruch wahrnehmen statt Geruch abgeben. Hier entstehen neue Senses.
Bei `taste` wird dagegen aktives Probieren wiederverwendet; bei `battery` der
Batterie-Sense, bei `home` die nominale Ortsbedeutung. Annotierte Bestandsverwendungen
wurden für diese Mehrdeutigkeiten mitgelesen.

Deutsche Ähnlichkeit allein erzeugt keine Gleichsetzung: `wear` Kleidung am Körper
haben gegenüber `carry` transportieren; `recipe` Kochrezept gegenüber `prescription`
ärztlicher Verordnung; `entry` Einreise gegenüber `entrance` Gebäudeeingang.
Neue Unterschiede wie `house/home`, `pan/pot`, `parent/mother/father` und `laugh/smile`
sind in den Einträgen und zusätzlich unter `semantic_decisions` begründet.

| Ausgeschlossen | Grund |
|---|---|
| expensive, bargain | Bereits primäre Lernwörter. |
| remote, lift, water | Wortbesitz vergeben; auch neue Wortart rechtfertigt keine zweite Stapelzuweisung. |
| cushion | Neben pillow konservativ kein weiterer Kissen-Erstkontakt. |
| duvet | Neben blanket konservativ kein weiterer Decken-Erstkontakt. |
| relax | Zu nah an rest; kein zweiter Erstkontakt für Ausruhen/Entspannen. |
| cashback | Regional und für diesen Kernstapel nachrangig; kein Füllwort. |

Synonyme wie `couch`, `refrigerator`, `sweater`, `sneaker`, `movie`, `present`,
`trash/garbage` und `faucet` werden nicht als zusätzliche Lernziele gezählt.
Drei echte Schreibvarianten sind reserviert: `neighbor`, `pajamas`, `yogurt`.
Keine davon wird ohne Satzprüfung zur akzeptierten Lückenantwort.
Die vollständigen 250 Kandidaten und alle Ausschlussgründe stehen in der Auswahl.
Die redaktionelle Prüfung ist eine inhaltliche Entscheidung; technische Validatoren
behaupten keine automatische Synonymerkennung.

## Reservierung, Positionen und Kontext

- `pipeline/data/words/en.alltag_zuhause_v1.json`: 901 Wörter, bestehend aus
  660 unveränderten Bestandszeilen und 241 Reservierungen. Elternhash ist der
  tatsächliche Registry-Snapshot des gestagten Packs. Bestehendes `bind_new_pack`
  verwendet, danach `index_registry`/`validate_selection`.
- `pipeline/data/learning_groups/en.alltag_zuhause_v1.json`: unveränderte alte
  Entscheidungen plus 241 reservierte neue Einzelköpfe. Nach späterer vollständiger
  Aufnahme 993 Gruppen, noch nicht importiert. Der innere historische Quellenhash
  beschreibt die frühere Umstellung; der äußere bindet an das aktuelle Pack.
- Sieben ältere Wortregistrydateien zusätzlich abgeglichen: keine Überschneidung
  mit neuen Formen oder Aliasen. Keine alte Registryversion geändert.
- `position`/`editorial_position` erhalten Originalpositionen 1–250 samt Lücken.
  `authoring_batch` verteilt jedes Thema reihum. Die erste Gruppe verwendet 83
  lückenlose Anzeigepositionen; die ZIP enthält auch spätere Zuordnungen.
  Diese Positionen sind keine feste Lernreihenfolge.
- Das Reisen-Exportlayout wurde in `pipeline/scripts/export_authoring_context.py`
  wiederverwendbar gemacht. `pipeline/src/sprachpipe/authoring_context.py` kombiniert
  vorhandene Auswahl-, Registry-, Pack- und Gruppenvalidatoren.
- ZIP: Basis-JSON und SQLite, Wörterbuch, Staging-Manifest, Registry, Gruppen,
  alle 241 Identitäten/Definitionen, 83 Gruppeneinträge, Anzeigezuordnungen, Schema,
  echter Importer/Tokenizer/Linter samt Quellabhängigkeiten, spaCy-Modell 3.8.0,
  Konfiguration, Paket-Lockdatei, Umgebung und SHA256-Manifest. `artifact_paths`
  bildet Repository-Provenienzpfade auf ZIP-Dateien ab. Python-Interpreter und
  installierte Python-Pakete sind nicht enthalten; Versionen sind dokumentiert.
  Keine Zugangsdaten oder Lernstände.

239 vorher erfasste Dateien unter Assets, App-Code, vorhandenen Packs und alten
Registrys blieben hashgleich. Keine Cloud-Generierung, neuen Sätze, Staging-Aktion,
Commits oder Pushes. Bereits vorliegende uncommittete Änderungen bleiben erhalten.

## Prüfnachweis

Die Befehle wurden mit der Windows-Pipeline-Umgebung aus dem Repository-Stamm
ausgeführt. Auf macOS lautet der Interpreterpfad `pipeline/.venv/bin/python`;
nach Aktivierung der jeweiligen Umgebung sind die Befehle `python …` identisch.
`git`-Befehle sind auf beiden Systemen gleich. Erstellung mit denselben Validatoren:

```text
pipeline/.venv/Scripts/python.exe pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltag_zuhause_v1.json --batch 1 --out build/alltag_zuhause_authoring_batch_1.zip
export: PASS; files: 81; selected: 241; batches: 83/80/78;
partition_selection: PASS, 0 present; validate_selection: PASS;
index_registry: PASS; validate_learning: PASS; build_rows: unchanged.
```

Vollständige Ausgaben der separaten Endprüfungen folgen unten. Negative Tests
decken manipulierte Identitäten, Definitionen, Reservierungen, Aliase, Gruppenköpfe,
Gruppenzuschnitt, ZIP-Hashes, private Dateien und Pfade ab. Ein zusätzlicher Lauf
verwendet die aus der ZIP gelesenen Tokenizer-/Linterquellen und das enthaltene
Modell an drei unveränderten Bestandsätzen. Die Git-Statusausgabe enthält auch
die bereits vor diesem Auftrag vorhandenen Änderungen, nicht nur diese Aufgabe.

<!-- FINAL CHECK OUTPUT -->

```text
$ pipeline/.venv/Scripts/python.exe pipeline/scripts/export_authoring_context.py --verify-zip build/alltag_zuhause_authoring_batch_1.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "afd097fa7044d84c84a20b8e24c010e016ef5497da88337964894aab023a8231",
  "hashed_files": 80,
  "sqlite_tables": 18,
  "sqlite_cards": 764,
  "credentials_and_learning_states": "none; explicit content/source/model whitelist",
  "status": "PASS",
  "selected": 241,
  "excluded": 9,
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
  "existing_cards": 764,
  "existing_groups": 752,
  "new_groups": 241,
  "registry_words": 901,
  "partition_selection": "PASS: 0 present",
  "validate_selection": "PASS: parent and exact reservations",
  "index_registry": "PASS",
  "validate_learning": "PASS: existing and planned",
  "build_rows": "PASS: reservation-only rows unchanged",
  "semantic_review": "explicit editorial decisions, no automatic equivalence inference"
}
Exit: 0
```

```text
$ pipeline/.venv/Scripts/python.exe build/alltag_zuhause_checks/verify_runtime.py
{"archived_tokenizer_and_linter": "PASS", "archived_model_version": "3.8.0", "existing_texts_checked": 3, "token_offsets": "exact", "linter_errors": 0, "new_texts": 0}
Exit: 0
```

```text
$ pipeline/.venv/Scripts/python.exe build/alltag_zuhause_checks/audit.py
{
  "protected_files_unchanged": 239,
  "old_registry_versions_checked": {
    "en.reisen_500_v1.json": 660,
    "en.reisen_batch_2_v1.json": 660,
    "en.reisen_batch_3_v1.json": 660,
    "en.reisen_batch_4_v1.json": 660,
    "en.reisen_batch_5_v1.json": 660,
    "en.story_learning_v1.json": 160,
    "en.v1.json": 160
  },
  "selection_and_alias_overlap": 0,
  "editorial_candidates_hash": "PASS",
  "new_aliases": 3,
  "new_sentences": 0,
  "cloud_calls": 0,
  "flutter_changes_this_task": 0
}
Exit: 0
```

```text
$ pipeline/.venv/Scripts/python.exe -m pytest pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_content_contract.py pipeline/tests/test_editorial_import.py pipeline/tests/test_learning_groups.py pipeline/tests/test_word_registry.py pipeline/tests/test_selection.py pipeline/tests/test_deck_display.py -q
........................................................................ [ 67%]
...................................                   [100%]
107 passed, 19 subtests passed in 2.06s
Exit: 0
```

```text
$ git diff --check
warning: in the working copy of 'NEXTSTEPS.md', LF will be replaced by CRLF the next time Git touches it
warning: in the working copy of 'docs/pipeline.md', LF will be replaced by CRLF the next time Git touches it
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
?? docs/alltag-zuhause-authoring.md
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
?? pipeline/data/selection/alltag_zuhause_v1.json
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
