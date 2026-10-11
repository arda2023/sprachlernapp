# Menschen & Beziehungen – Batch 2 importiert

Stand: 10.10.2026. `menschen_beziehungen_batch_2_v1` ist vollständig offline exportiert und intern gestagt. Genau 82 neue Ziele mit je einem festen Satz und insgesamt 1028 Tokenpositionen. Menschen & Beziehungen umfasst jetzt 164 Ziele; alle fünf Stapel zusammen 1299 primäre Lernziele (160/489/241/245/164).

## Redaktion, Identität und Anzeige

Alle 82 englisch/deutschen Satzpaare, sämtliche Tokenbindungen, neue Formglossen und wiederverwendete Inhaltswortglossen wurden gegengelesen. Zieldefinitionen, IDs und `cards.learning` stimmen exakt mit der Originalauswahl überein. Begleitwörter erzeugen keine zusätzlichen Lernkarten; die 81 späteren Karten bleiben reserviert. Kein neuer Stapel und keine Änderung am Pipeline-Code. Der bestehende `lexical_spans`-Vertrag bindet mother-in-law, brother-in-law und self-esteem jeweils als genau einen Token mit korrekten Offsets, Sense und Kartenreferenz.

Besonders geprüft: meeting ist das Verb sich treffen, respect das Nomen Respekt, plans sind Vorhaben, married bei stepmother das Verb heiraten und bei brother-in-law das Adjektiv verheiratet. used to bezeichnet die frühere Gewohnheit, nicht benutzen. thoughtful bedeutet nachdenklich, sympathy Mitgefühl, heavy bei burden eine Belastung. having a party nutzt die bereits vorhandene breite have-Bedeutung „zu sich nehmen … oder erleben/durchführen“ mit neuer passender Formglosse; keine künstliche zusätzliche Sense. Die front-Bindungen bei brave und ashamed verwenden `front/NOUN|front#vor_publikum`.

Die zwei regionalen Schreibvarianten wurden wörtlich eingesetzt:

- Would you recognize your old school friends after twenty years?
- A rumor about their separation spread before either of them said anything.

`accepted` enthält ausschließlich recognise beziehungsweise rumour. Die Alternativen bleiben satzbezogen und lernstandsneutral; keine Änderung der App-/SRS-/Antwortlogik. Die Lieferdateien sind unverändert; keine neuen Reviewhashes oder Create-Hashes erforderlich.

Neue Mitgliedschaften wurden auf 83–164 angehängt, danach beide Menschen-Anzeigepositionen mit dem gelieferten hashgebundenen Display-Patch auf 1–164 abgebildet. Originalpositionen in Auswahl und Registry bleiben unverändert. Alle 1332 alten Karten-IDs, Texte, Tokens, Lerngruppen und die front-Korrektur sind erhalten. An alten Zeilen dürfen und konnten ausschließlich `position` in Menschen-`deck_cards` und `deck_words` abweichen. Alle anderen Inhaltswerte wurden vollständig verglichen.

## Prüfungen und Grenzen

Der Lieferverifier prüfte Rohbyte-/kanonische Hashes, Schema, Kontext, exakte Reservierungen, Reviews und Displayvertrag. Der tatsächliche Export und ein zusätzlicher unabhängiger Vergleich gegen `create_content` plus `apply_deck_display_patch` bestanden. Alle Zeilen und Spalten aller 18 SQLite-Tabellen wurden gegen `build_rows` zurückgelesen; wie im vorhandenen Prüfer ausgenommen ist der Exportzeitstempel. Ergebnis: 1414 Karten, 1948 Satztexte, 1942 historische Satzlinks, 1310 Wortbesitzzeilen, 21173 Tokens.

Linter der neuen Sätze: 0 Fehler, zwei bekannte Warnungen: newcomer im outsider-Satz, Zipf 3,40 < 3,5; hurtful im regret-Satz, 3,30 < 3,5. Keine Umformulierung allein wegen dieser Frequenzhinweise. Redaktionelle Modellprüfung, keine unabhängige menschliche Sprachfreigabe.

Ein zusätzlicher lokaler Dokumentvergleich scheiterte zunächst mit Exit 1: Seine aus einem früheren Batch übernommene Satzzeichenliste enthielt keinen alleinstehenden Apostroph. Der konkrete Token nach grandparents in „grandparents' garden“ ist korrekt ohne Lemma/Sense/Karte annotiert. Ausschließlich diese exakt gebundene Stelle wurde im lokalen Prüfhelfer zugelassen; danach Exit 0. Importer, Packvalidator und Lieferung blieben unverändert. Erstversuch erhalten in `build/menschen_batch_2_checks/audit-export-attempt-1.log`.

Alte Wörterbuchglossen bleiben teilweise flektiert oder auf einen anderen Kontext zugeschnitten, etwa guest → „Gäste-“, closest → „stärkste; nächste (Konkurrenz)“, met → „trafen“, brave → „mutige“. Die korrekten Bedeutungsreferenzen und neuen vollständigen Satzübersetzungen sind davon getrennt. Diese vorhandenen Glossen wurden gemäß Bestandsschutz nicht global bereinigt; sie bleiben als Altbefunde offen.

Assets wurden vor dem Staging unter `build/menschen_batch_2_checks/backup/assets/content/en/` gesichert. Staging-Verifikation, Fünfstapel-Lesetest und Flutter-Analyse bestanden. Der Lesetest verwendet ein temporäres Installationsverzeichnis. Echte user.db, review_log und Lernstände wurden nicht geöffnet. Keine Geräte-/Emulatorprüfung.

## Letzter Authoring-Batch

Der vorhandene Fortsetzungs-Exporter erzeugte separate `menschen_beziehungen_batch_3_context_v1`-Dateien in `pipeline/data/selection/`, `pipeline/data/words/` und `pipeline/data/learning_groups/` (die letzten beiden mit `en.`-Präfix). Quelle ist der tatsächlich gestagte Batch-2-Pack. Voller Kontext aller 245 Originalidentitäten und Definitionen, 1391 Reservierungen, 1414 bestehende Karten, 1402 bestehende Gruppen und 81 reservierte Gruppen. Partition: 164 importiert / 81 aktuell / 0 später. Sechs ursprünglich geplante Senses sind als Begleitwörter bereits vorhanden und werden wiederverwendet; keine zusätzliche Definitionsequivalenz nötig.

Der reine Display-Vertragstest bestätigt: beim Folgeimport 165–245 anhängen, danach beide Anzeigen hashgebunden auf 1–245 ordnen. Alle ursprünglichen Identitäten, Definitionen und Positionen bleiben erhalten. Keine Batch-3-Sätze erzeugt.

Die ZIP wurde im temporären Verzeichnis vollständig geschlossen, erneut geöffnet und auf CRCs, sämtliche Manifesthashes, Referenzen und alle 18 SQLite-Tabellen geprüft. Erst danach wurde sie an den endgültigen Pfad verschoben und nochmals verifiziert:

`/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/menschen_beziehungen_authoring_batch_3.zip`

## Dateien und Bestandsschutz

Geändert: konkrete Batch-2-Erwartungen in `test/data/real_pack_test.dart`, internes Asset/Manifest und `NEXTSTEPS.md`. Neu: Packexport, drei Batch-3-Kontextsnapshots, geprüfte ZIP, dieser Bericht und `build/menschen_batch_2_checks/` mit Baseline, Sicherungen und Prüfprotokollen. Kein Pipeline-/App-Einstiegs-/SRS-/Plattformcode geändert; ursprüngliche Lieferungen, historische Packs und Registrys erhalten. Keine Cloud-/Modellaufrufe, öffentliche Veröffentlichung, Commits oder Pushes.

`git diff --check` meldet Exit 2 wegen bestehender CRLF-/Whitespace-Altbefunde. Mit `core.whitespace=cr-at-eol` bleiben die bekannten sieben Stellen: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127 und docs/arbeit-bildung-batch-2-import.md:121. Vollständige Logs sind komprimiert gesichert. Eigene Änderungen werden gegen ihre Sicherung bzw. /dev/null getrennt geprüft, ohne Altbereinigung. `--no-index --check` darf bei Unterschieden Exit 1 ohne Diagnostik liefern; prüfender Wrapper Exit 0. Endnachweis: `final-checks.log`.

## Hashes

- `pipeline/out/menschen_beziehungen_batch_1_v1/pack.json`: `a9ce4790d50d4acd1024a81452987b17013e26f30fda15a71b3daa029414f6d4`
- `pipeline/out/menschen_beziehungen_batch_1_v1/content.sqlite`: `1b0d9ef74cba9baf11b045f7fdb40cc7b2b06030dc15820cd66e6396add6b70e`
- `menschen_beziehungen_batch_2/menschen_beziehungen_batch_2.editorial.json`: `78f08c73f8f228dda8bc32d426b9c456fefd28ad680eadbe57f214b3640ab5b2`
- `menschen_beziehungen_batch_2/menschen_beziehungen_batch_2.display.json`: `1deddee878ae38ab4a864a5db66ba2da4fa72e12141d3d9b0a5677dd8124e231`
- `pipeline/out/menschen_beziehungen_batch_2_v1/pack.json`: `7d3b2a2f0d716df0f12e69b097ff72e1a1b430ca5bac9c858503ead557028bbb`
- `pipeline/out/menschen_beziehungen_batch_2_v1/content.sqlite`: `96f6fab1d2b151f1c57f9645d90acf1a39fd7deb1d43df13615268c21b1c360c`
- `assets/content/en/content.sqlite`: `96f6fab1d2b151f1c57f9645d90acf1a39fd7deb1d43df13615268c21b1c360c`
- `assets/content/en/content.manifest.json`: `96ed675ad09e10b5c9fb47de14b6438b0105d6614d95b7d40e48b5d2c36edd94`
- `build/menschen_beziehungen_authoring_batch_3.zip`: `7ab656738488edba349a5b285cb75b311bedf9e32221d6be33690df8d270d7fd`

## Tatsächliche Befehle und Outputs

macOS: `PYTHON` steht für `pipeline/.venv-macos/bin/python`. Windows PowerShell: `.\pipeline\.venv\Scripts\python.exe`. Repository-Root als Arbeitsverzeichnis; Dart-/Flutter-Befehle auf beiden Systemen gleich.

```text
PYTHON menschen_beziehungen_batch_2/verify_menschen_beziehungen_batch_2.py --repo .
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 83..164, final display 1..164; original registry positions preserved
PASS create_content/build_rows: 1414 cards; 1299 primary goals (160/489/241/245/164); 18 tables
PASS 82 reserved identities, display 1..164; 1332 old IDs and all historical rows preserved
PASS 1028 token positions; two reviewed alternatives; linter 0 errors, 2 warnings
WARNINGS [["outsider", "i+1", "'newcomer'/'newcomer' Zipf 3.40 below 3.5"], ["regret", "i+1", "'hurtful'/'hurtful' Zipf 3.30 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access
Exit 0
```

```text
PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 1.82s
Exit 0
```

```text
PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/menschen_beziehungen_batch_1_v1/pack.json --create menschen_beziehungen_batch_2/menschen_beziehungen_batch_2.editorial.json --registry pipeline/data/words/en.menschen_beziehungen_batch_2_context_v1.json --display-patch menschen_beziehungen_batch_2/menschen_beziehungen_batch_2.display.json --out pipeline/out/menschen_beziehungen_batch_2_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 2473,
    "senses": 3782,
    "cards": 1414,
    "dictionary_forms": 4357,
    "decks": 5,
    "deck_cards": 1414,
    "deck_words": 1310,
    "word_aliases": 21,
    "sentences": 1948,
    "sentence_tokens": 21173,
    "card_sentences": 1942,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "96f6fab1d2b151f1c57f9645d90acf1a39fd7deb1d43df13615268c21b1c360c"
}
Exit 0
```

```text
PYTHON build/menschen_batch_2_checks/audit_export.py
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2473, 'senses': 3782, 'cards': 1414, 'dictionary_forms': 4357, 'decks': 5, 'deck_cards': 1414, 'deck_words': 1310, 'word_aliases': 21, 'sentences': 1948, 'sentence_tokens': 21173, 'card_sentences': 1942, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 164 original identities, definitions, learning groups, owners and fixed sentences; 81 future targets excluded
PASS 1332 historical cards and all old content preserved, except authorized display positions; front correction retained
ALTERNATIVE Would you recognize your old school friends after twenty years?
ALTERNATIVE A rumor about their separation spread before either of them said anything.
PASS reviewed reading/annotation documents exactly match all 82 sentences and 1028 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 164
PACK_SHA256 7d3b2a2f0d716df0f12e69b097ff72e1a1b430ca5bac9c858503ead557028bbb
SQLITE_SHA256 96f6fab1d2b151f1c57f9645d90acf1a39fd7deb1d43df13615268c21b1c360c
Exit 0
```

```text
dart run tool/stage_content_pack.dart --from pipeline/out/menschen_beziehungen_batch_2_v1
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version menschen_beziehungen_batch_2_v1, schema 3, 10297344 bytes
  sha256 96f6fab1d2b151f1c57f9645d90acf1a39fd7deb1d43df13615268c21b1c360c
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
```

```text
dart run tool/stage_content_pack.dart --verify
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version menschen_beziehungen_batch_2_v1, schema 3, 10297344 bytes
  sha256 96f6fab1d2b151f1c57f9645d90acf1a39fd7deb1d43df13615268c21b1c360c
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
deck menschen-beziehungen: 164 learning targets, 164 ownership cards, 164 fixed sentence assignments verified
pack menschen_beziehungen_batch_2_v1 (schema 3, internal: true); 5 decks: 1310 cards, 1414 card sentences, 118 with valid_alternatives, 1414 cards in the pack
00:11 +1: All tests passed!
Exit 0
```

```text
flutter analyze
Analyzing sprachapp...
No issues found! (ran in 2.9s)
Exit 0
```

```text
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/menschen_beziehungen_v1.json --batch 3 --prepare-continuation menschen_beziehungen_batch_3_context_v1
{
  "snapshots": "PASS",
  "paths": {
    "selection": "pipeline/data/selection/menschen_beziehungen_batch_3_context_v1.json",
    "registry": "pipeline/data/words/en.menschen_beziehungen_batch_3_context_v1.json",
    "groups": "pipeline/data/learning_groups/en.menschen_beziehungen_batch_3_context_v1.json"
  },
  "partition_counts": {
    "imported": 164,
    "current": 81,
    "future": 0
  }
}
Exit 0
```

```text
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/menschen_beziehungen_batch_3_context_v1.json --batch 3 --out build/menschen_batch_2_checks/staging/menschen_beziehungen_authoring_batch_3.zip
{
  "export": "PASS",
  "files": 83,
  "partition_counts": {
    "imported": 164,
    "current": 81,
    "future": 0
  }
}
Exit 0
```

```text
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/menschen_batch_2_checks/staging/menschen_beziehungen_authoring_batch_3.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "7ab656738488edba349a5b285cb75b311bedf9e32221d6be33690df8d270d7fd",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 1414,
  "partition_counts": {
    "imported": 164,
    "current": 81,
    "future": 0
  }
}
Exit 0
```

```text
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/menschen_beziehungen_authoring_batch_3.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "7ab656738488edba349a5b285cb75b311bedf9e32221d6be33690df8d270d7fd",
  "hashed_files": 82,
  "sqlite_tables": 18,
  "sqlite_cards": 1414,
  "partition_counts": {
    "imported": 164,
    "current": 81,
    "future": 0
  }
}
Exit 0
```

Zusätzliche Prüfungen (Exit 0): drei vollständige Compound-Zieltokens samt Offsets/Kartenbindung; 245 unveränderte Originalidentitäten/Definitionen/Positionen; reiner Display-Vertragstest append 165–245, final 1–245. Git-Status vorher/nachher und vollständige Ausgangshashes liegen im Prüfordner.
