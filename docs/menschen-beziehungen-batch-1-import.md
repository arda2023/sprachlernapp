# Menschen & Beziehungen – Batch 1 importiert

Stand: 10.10.2026. `menschen_beziehungen_batch_1_v1` offline exportiert und intern gestagt. Genau 82 neue Lernziele mit je einem festen Satz, 1024 Tokenpositionen und vier satzbezogenen Schreibalternativen. Insgesamt 1217 primäre Lernziele: 160 Allgemeine Sprache, 489 Reisen, 241 Alltag & Zuhause, 245 Arbeit & Bildung, 82 Menschen & Beziehungen.

## Redaktion und begrenzte Codeänderung

Alle 82 englisch/deutschen Satzpaare und die vollständigen Wortbindungen wurden gegengelesen; Formglossen wurden aus dem tatsächlichen zusammengeführten Wörterbuch geprüft. Zielidentitäten, Definitionen, Lernmetadaten und Originalpositionen stimmen mit der reservierten Auswahl überein. Genau ein aktiver Link auf Position 1 je neuer Karte; beide Stapelpositionen lückenlos 1–82 gemäß dem gelieferten Mapping. Kein separater Display-Patch für Batch 1, keine der 163 zukünftigen Karten angelegt. Begleitwörter erzeugen keine zusätzlichen Lernkarten.

`tokenize` unterstützt jetzt die optionalen expliziten `lexical_spans` des geprüften Lieferpatches. Nur vollständig begrenzte Zielspannen werden vereinigt; ungültige Grenzen und überlappende Spannen werden abgewiesen. `create_content` übergibt seine Kartenlücken, anschließend gelten weiterhin die vollständigen Packprüfungen. Default-Tokenisierung und alle historischen Token bleiben unverändert. Keine globale Bindestrichregel oder Validatorlockerung. Der Helper wurde nur zum Lesen seiner überprüften Ersetzungsblöcke verwendet; die beiden Änderungen wurden gegen den tatsächlichen Quelltext einzeln abgesichert, bestehende Zeilenenden außerhalb der Änderung erhalten. Referenzquellen wurden nicht über Projektdateien kopiert.

Drei Ziele benötigen jeweils einen vollständigen Token: sister-in-law, son-in-law, open-minded. Alle Zieloffsets und stabilen IDs sind geprüft. Die Lieferung blieb byteidentisch; keine Reviewhashes mussten geändert werden.

Vier Alternativen wurden wörtlich im vollständigen Satz geprüft:

- Could you do me a favor and feed my cat tonight?
- Regular contact with friends is important for my well-being.
- After the break-up, they returned each other's things and stopped living together.
- People in our neighborhood often stop to talk in the street.

`accepted` enthält jeweils ausschließlich favour, wellbeing, breakup beziehungsweise neighbourhood. Die Alternativen bleiben nach bestehender App-Regel neutral; keine Änderung der Antwort-/SRS-Logik. company ist Gesellschaft, lives das Nomen Leben, visit das Verb besuchen, hug die Umarmung, shared ein gemeinsam genutzter Gegenstand; standing up for und die beiden mean-Bedeutungen sind kontextuell getrennt.

Linter für die 82 neuen Sätze: 0 Fehler, genau eine bekannte Frequenzwarnung bei empathy: grieve/grieving, Zipf 3,45 < 3,5. Keine Umformulierung allein dafür. Das ist eine redaktionelle Modellprüfung, keine unabhängige menschliche Sprachfreigabe.

## Bestandsschutz und offene Altbefunde

Alle bisherigen 1250 Karten und sämtliche historischen JSON-Inhaltszeilen sind unverändert. Der gesonderte Exportabgleich vergleicht jede alte Tabellenliste als unveränderten Präfix, alle neuen Identitäten und Definitionen sowie alle Zeilen und Spalten der 18 SQLite-Tabellen gegen `build_rows` (Release-Zeitstempel wie im vorhandenen Prüfer ausgenommen). Die frühere front/NOUN|front#vor_publikum-Korrektur bleibt erhalten.

Vorhandene Wörterbuchglossen sind teilweise flektiert oder auf einen alten Kontext zugeschnitten: hurt → „verletzte“, proud → „stolzen“, asked → „bat“, with#umstand → „hier: weil alle anderen weg sind (With everyone else away)“. Diese Zeilen wurden ausdrücklich gegen die alte Basis geprüft und bleiben gemäß Bestandsschutz unverändert. Sie sind offene Altbefunde; die neuen vollständigen Satzübersetzungen sind davon getrennt. Keine globale Glossenbereinigung oder künstlichen Ersatzsenses.

App-Asset und Manifest wurden vor dem Staging unter `build/menschen_batch_1_checks/backup/assets/content/en/` gesichert. Echter Lernstand, user.db und review_log wurden nicht geöffnet. Der Flutter-Test installiert das Asset ausschließlich in ein temporäres Testverzeichnis. Keine Geräte-/Emulatorprüfung in diesem Auftrag.

## Batch 2

Mit dem bestehenden Fortsetzungs-Exporter wurden drei separate Snapshots `menschen_beziehungen_batch_2_context_v1` in `pipeline/data/selection/`, `pipeline/data/words/` und `pipeline/data/learning_groups/` erzeugt (die letzten beiden mit `en.`-Präfix). Quelle ist der tatsächlich gestagte neue Pack. Die ursprünglichen 245 Identitäten, Definitionen, Ausschlüsse und Auswahlpositionen sind unverändert enthalten. Partition 82 importiert / 82 aktuell / 81 später, alle acht Themen im aktuellen Batch.

Der Kontext enthält 1391 Wortreservierungen, 1332 bestehende Karten, 1320 bestehende Gruppen und 163 noch reservierte Gruppen. Sieben ursprünglich geplante Senses sind inzwischen als Begleitwörter vorhanden und werden anhand exakter Definitionen wiederverwendet; keine zusätzliche Definitionsequivalenz nötig. Der Folgeimport hängt neue Mitgliedschaften auf 83–164 an und verwendet anschließend den bestehenden hashgebundenen Display-Patch für beide Anzeigepositionen 1–164. Der reine Mitgliedschaftstest dieses Vertrags bestand. Keine Batch-2-Sätze erzeugt.

Die ZIP wurde unter einem temporären Verzeichnis mit endgültigem Basisnamen vollständig geschlossen, erneut geöffnet und geprüft. Erst nach bestandener CRC-/Manifest-/Referenz-/SQLite-Prüfung wurde sie an den endgültigen Pfad verschoben und nochmals verifiziert:

`/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/menschen_beziehungen_authoring_batch_2.zip`

## Hashes

- `pipeline/out/arbeit_bildung_batch_3_v1/pack.json`: `d170e0ca41784fae6e888043b53e53af6ba0e5288b79ad1f91fd3e9f0983b3ba`
- `pipeline/out/arbeit_bildung_batch_3_v1/content.sqlite`: `4239a32d45354539ce5aee74a61ec8ed7ac20d39902ff060f2a0bc94e1fcaa91`
- `menschen_beziehungen_batch_1/menschen_beziehungen_batch_1.editorial.json`: `ebad42ffd289be5d5597aae732245bc72783ceb1d382fcf2ece4363fc34a2461`
- `pipeline/out/menschen_beziehungen_batch_1_v1/pack.json`: `a9ce4790d50d4acd1024a81452987b17013e26f30fda15a71b3daa029414f6d4`
- `pipeline/out/menschen_beziehungen_batch_1_v1/content.sqlite`: `1b0d9ef74cba9baf11b045f7fdb40cc7b2b06030dc15820cd66e6396add6b70e`
- `assets/content/en/content.sqlite`: `1b0d9ef74cba9baf11b045f7fdb40cc7b2b06030dc15820cd66e6396add6b70e`
- `assets/content/en/content.manifest.json`: `48097bb83465d0cab91c30b355555d383edcd883c8decfc7dcdb3ebe5b3815f9`
- `build/menschen_beziehungen_authoring_batch_2.zip`: `aaa542d7a4e60d416b942ec3d73715f532273440ab367b694142978728d07397`

## Ausgeführte Prüfungen

macOS-Interpreter: `pipeline/.venv-macos/bin/python` (Python 3.13.15). Windows-PowerShell-Entsprechung: `.\pipeline\.venv\Scripts\python.exe`. In den folgenden Befehlen steht `PYTHON` für den jeweiligen Interpreter. Flutter-/Dart-Befehle sind auf beiden Systemen gleich; Arbeitsverzeichnis Repository-Root. Alle unten aufgeführten fachlichen Prüfungen: Exit 0.

```text
PYTHON menschen_beziehungen_batch_1/compatibility/check_compound_target_spans.py --source . --model menschen_beziehungen_batch_1/reference/runtime/en_core_web_sm
PASS 14 tokenizer checks: compounds, offsets, default compatibility, malformed spans
Exit 0
```

```text
PYTHON menschen_beziehungen_batch_1/verify_menschen_beziehungen_batch_1.py --repo .
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS create_content/build_rows: 1332 cards; 1217 primary goals (160/489/241/245/82); 18 tables
PASS 82 reserved identities, display 1..82; 1250 old IDs and all historical rows preserved
PASS 1024 token positions; four reviewed alternatives; linter 0 errors, 1 warnings
WARNINGS [["empathy", "i+1", "'grieve'/'grieving' Zipf 3.45 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access
Exit 0
```

```text
PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 1.76s
Exit 0
```

```text
PYTHON -m pytest pipeline/tests/test_generate.py -q
..................                                                       [100%]
18 passed in 1.29s
Exit 0
```

```text
PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/arbeit_bildung_batch_3_v1/pack.json --create menschen_beziehungen_batch_1/menschen_beziehungen_batch_1.editorial.json --registry pipeline/data/words/en.menschen_beziehungen_v1.json --out pipeline/out/menschen_beziehungen_batch_1_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 2379,
    "senses": 3660,
    "cards": 1332,
    "dictionary_forms": 4192,
    "decks": 5,
    "deck_cards": 1332,
    "deck_words": 1228,
    "word_aliases": 19,
    "sentences": 1866,
    "sentence_tokens": 20145,
    "card_sentences": 1860,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "1b0d9ef74cba9baf11b045f7fdb40cc7b2b06030dc15820cd66e6396add6b70e"
}
Exit 0
```

```text
PYTHON build/menschen_batch_1_checks/audit_export.py
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2379, 'senses': 3660, 'cards': 1332, 'dictionary_forms': 4192, 'decks': 5, 'deck_cards': 1332, 'deck_words': 1228, 'word_aliases': 19, 'sentences': 1866, 'sentence_tokens': 20145, 'card_sentences': 1860, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 82 original identities, definitions, learning groups, owners and fixed sentences; 163 future targets excluded
PASS 1250 historical cards and all old content preserved; front correction retained
ALTERNATIVE Could you do me a favor and feed my cat tonight?
ALTERNATIVE Regular contact with friends is important for my well-being.
ALTERNATIVE After the break-up, they returned each other's things and stopped living together.
ALTERNATIVE People in our neighborhood often stop to talk in the street.
PASS reviewed reading/annotation documents exactly match all 82 sentences and 1024 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 82
PACK_SHA256 a9ce4790d50d4acd1024a81452987b17013e26f30fda15a71b3daa029414f6d4
SQLITE_SHA256 1b0d9ef74cba9baf11b045f7fdb40cc7b2b06030dc15820cd66e6396add6b70e
Exit 0
```

```text
dart run tool/stage_content_pack.dart --from pipeline/out/menschen_beziehungen_batch_1_v1
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version menschen_beziehungen_batch_1_v1, schema 3, 9846784 bytes
  sha256 1b0d9ef74cba9baf11b045f7fdb40cc7b2b06030dc15820cd66e6396add6b70e
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
```

```text
dart run tool/stage_content_pack.dart --verify
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version menschen_beziehungen_batch_1_v1, schema 3, 9846784 bytes
  sha256 1b0d9ef74cba9baf11b045f7fdb40cc7b2b06030dc15820cd66e6396add6b70e
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
```

```text
flutter test test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
deck allgemeine-sprache: 160 learning targets, 160 ownership cards, 160 fixed sentence assignments verified
deck reisen: 489 learning targets, 500 ownership cards, 500 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 241 ownership cards, 241 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck menschen-beziehungen: 82 learning targets, 82 ownership cards, 82 fixed sentence assignments verified
pack menschen_beziehungen_batch_1_v1 (schema 3, internal: true); 5 decks: 1228 cards, 1332 card sentences, 116 with valid_alternatives, 1332 cards in the pack
00:10 +1: All tests passed!
Exit 0
```

```text
flutter analyze
Analyzing sprachapp...
No issues found! (ran in 2.8s)
Exit 0
```

```text
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/menschen_beziehungen_v1.json --batch 2 --prepare-continuation menschen_beziehungen_batch_2_context_v1
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/menschen_beziehungen_batch_2_context_v1.json",
    "registry": "pipeline/data/words/en.menschen_beziehungen_batch_2_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.menschen_beziehungen_batch_2_context_v1.json"
  },
  "partition_counts": {
    "imported": 82,
    "current": 82,
    "future": 81
  }
}
Exit 0
```

```text
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/menschen_beziehungen_batch_2_context_v1.json --batch 2 --out build/menschen_batch_1_checks/staging/menschen_beziehungen_authoring_batch_2.zip
{
  "export": "PASS",
  "files": 83,
  "partition_counts": {
    "imported": 82,
    "current": 82,
    "future": 81
  }
}
Exit 0
```

```text
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/menschen_batch_1_checks/staging/menschen_beziehungen_authoring_batch_2.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "aaa542d7a4e60d416b942ec3d73715f532273440ab367b694142978728d07397",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 1332,
  "partition_counts": {
    "imported": 82,
    "current": 82,
    "future": 81
  }
}
Exit 0
```

```text
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/menschen_beziehungen_authoring_batch_2.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "aaa542d7a4e60d416b942ec3d73715f532273440ab367b694142978728d07397",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 1332,
  "partition_counts": {
    "imported": 82,
    "current": 82,
    "future": 81
  }
}
Exit 0
```

## Änderungen und Whitespace

Geändert: `pipeline/src/sprachpipe/annotate.py`, `pipeline/scripts/import_editorial_patch.py`, konkrete Pack-Erwartungen in `test/data/real_pack_test.dart`, internes Asset/Manifest und `NEXTSTEPS.md`. Neu: Packexport, drei Fortsetzungssnapshots, Batch-2-ZIP, dieser Bericht und `build/menschen_batch_1_checks/` mit Baseline, Backups und vollständigen Logs.

`git diff --check`: Exit 2, vorhandene CRLF-/Whitespace-Befunde (komprimiertes vollständiges Log). `git -c core.whitespace=cr-at-eol diff --check`: Exit 2, sieben unveränderte Altbefunde in DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127 und docs/arbeit-bildung-batch-2-import.md:121. Keine pauschale Bereinigung. Eigene Änderungen werden separat gegen ihre Sicherungen bzw. /dev/null geprüft; `--no-index --check` darf bei unterschiedlichen Dateien Exit 1 ohne Diagnostik liefern. Nachweis in `final-checks.log`.

Keine Cloud-/Modellaufrufe, Veröffentlichungen, Commits oder Pushes; App-Einstieg, SRS, Plattformdateien, historische Packs, ursprüngliche Registrys/Auswahl und Lieferung erhalten. Keine fehlgeschlagenen fachlichen Prüfläufe oder umgangenen Hashprüfungen. Offen: bekannte Wörterbuch-/Whitespace-Altbefunde und Geräteprüfung. Nächster Schritt: Satzredaktion ausschließlich für die 82 aktuellen Batch-2-Ziele anhand der geprüften ZIP.
