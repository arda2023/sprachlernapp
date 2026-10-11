# Menschen & Beziehungen – Abschluss mit 245 Lernzielen

Stand: 10.10.2026. `menschen_beziehungen_batch_3_v1` offline importiert, exportiert und intern gestagt. Genau 81 neue Ziele, 81 Satzpaare, 1001 Tokenpositionen und zwei satzbezogen geprüfte Alternativen. Der Stapel ist mit 245 importierten / 0 aktuellen / 0 späteren Zielen abgeschlossen. Keine weitere Auswahl und keine Batch-4-ZIP erstellt.

Die fünf Stapel enthalten 1380 primäre Lernziele: 160 Allgemeine Sprache, 489 Reisen, 241 Alltag & Zuhause, 245 Arbeit & Bildung, 245 Menschen & Beziehungen. Physischer Gesamtbestand: 1495 Karten, 2029 Satztexte, 2023 historische Satzverknüpfungen, 1391 Wortbesitzzeilen und 22174 Tokenpositionen.

## Redaktion und zwei gezielte Lieferkorrekturen

Alle 81 englisch/deutschen Satzpaare und 1001 Tokenbindungen wurden gegengelesen, neue Formglossen und wiederverwendete Inhaltswortglossen kontextuell geprüft. company ist Gesellschaft, hand bei cheat das Kartenblatt, calling bezeichnet Benennen, watch das Aufpassen auf Kinder, trust ein Nomen, meeting jeweils Treffen/Besprechung. Vollverb-have, Perfect-Hilfsverb und had to wurden unterschieden, ebenso existenzielles there was, Kopula und Verlauf. father-in-law und daughter-in-law bleiben vollständige Zieltokens mit exakten Offsets; vorhandener Tokenizer unverändert.

Zwei belegte Lieferfehler wurden ausschließlich in einer separaten Importkopie korrigiert:

| Satz | Tokenindex | Vorher | Nachher |
|---|---:|---|---|
| Their commitment to each other helped them through a difficult year. | 4 | other/ADJ, other/ADJ\|other#anderen | other/PRON, other/PRON\|other#einander_teil |
| The children learn to interact with each other through simple games. | 7 | other/ADJ, other/ADJ\|other#anderen | other/PRON, other/PRON\|other#einander_teil |

In beiden Fällen ist other Teil des gegenseitigen Pronomens each other. Die passende Lemma-/Sense-/Formglossenbindung existiert bereits in der Basis; keine neue Wörterbuchzeile oder Lernkarte war erforderlich. each generation bleibt der Determinierer, We each der eigenständige Pronomengebrauch. Zielidentitäten, Satztexte, Übersetzungen, Offsets und Kartenmetadaten bleiben unverändert.

Originalbytes unter `menschen_beziehungen_batch_3/` unverändert erhalten. Geprüfte Importkopie: `build/menschen_batch_3_checks/reviewed_delivery/`. Änderungen: zwei Tokens, ihre beiden Review-Tokenhashes und Reviewbegründungen, Create-Rohbytehash im Display-Patch, die beiden Zeilen in annotation_review.txt sowie ergänzende Redaktionsnotiz. `local_corrections.json` dokumentiert vollständige Vorher-/Nachherwerte und Hashes; das Manifest der Kopie wurde entsprechend aktualisiert. Unveränderte Dateien wurden bytegetreu kopiert. Original-Verifier und anschließend derselbe unveränderte Verifier in der korrigierten Kopie bestanden gegen die aktuellen Projektquellen. Kein Hashcheck oder Validator umgangen; kein Pipeline-Code geändert.

Alternativen wörtlich im vollständigen Satz geprüft:

- We invited our neighbours to a barbeque in the garden on Sunday.
- I can unwind completely in the company of close friends.

accepted enthält ausschließlich barbecue beziehungsweise relax. barbeque ist eine Schreibvariante, unwind passt in genau diesem Entspannungssatz. Beide bleiben nach bestehender App-Regel lernstandsneutral; keine globale Alternativfreigabe oder Änderung der SRS-/Antwortlogik.

Linter für die neuen Sätze: 0 Fehler; genau ein neuer Frequenzhinweis zu housework (Zipf 3,08 < 3,5) im stress-Satz. Keine Umformulierung allein dafür. Redaktionelle Modellprüfung, keine unabhängige menschliche Sprachfreigabe. Historische flektierte/kontextgebundene Glossen (etwa offered → anbot, welcomed → nahm auf; nahmen auf, important → wichtige) bleiben als Altbefunde erhalten; keine globale Bereinigung.

## Identitäten, Display und Bestandsschutz

Die 81 neuen Mitgliedschaften wurden auf 165–245 angehängt. Danach ordnete der gelieferte Display-Patch mit aktualisiertem Create-Hash beide Menschen-Positionsspalten gemäß der Originalauswahl auf 1–245. Originalpositionen in Auswahl und Registry sind unverändert. Kein neuer Stapel; Begleitwörter erzeugen keine zusätzlichen Lernkarten.

Alle 245 Menschen-Identitäten, Definitionen, Lerngruppen, Besitzer, Kartenglossen und jeweils genau ein aktiver fester Satz auf Position 1 wurden gegen die Originalauswahl geprüft. Alle 1414 bisherigen Karten und historischen Inhalte einschließlich front/NOUN|front#vor_publikum bleiben erhalten. An alten Zeilen änderten sich ausschließlich die genehmigten Menschen-Positionen in deck_cards und deck_words. Alle anderen Werte wurden als unveränderte historische Präfixe verglichen.

Der tatsächliche Export entspricht exakt create_content plus dem hashgebundenen Display-Patch. Alle Zeilen und Spalten der 18 SQLite-Tabellen wurden gegen build_rows zurückgelesen; der automatisch erzeugte Release-Zeitstempel ist wie im vorhandenen Prüfer ausgenommen. Beide korrigierten Pronomenpaare und beide Compound-Ziele wurden zusätzlich im tatsächlichen Export geprüft.

Asset und Manifest sind vor Staging unter `build/menschen_batch_3_checks/backup/assets/content/en/` gesichert. Staging, --verify, Fünfstapel-Lesetest und Flutter-Analyse bestanden. Der Lesetest installiert ausschließlich in ein temporäres Testverzeichnis. Echte user.db, review_log und Lernstände wurden nicht geöffnet oder verändert.

## Änderungen, Altbefunde und Grenzen

Geändert: konkrete Batch-3-Erwartungen in `test/data/real_pack_test.dart`, internes Asset/Manifest und `NEXTSTEPS.md`. Neu: `pipeline/out/menschen_beziehungen_batch_3_v1/`, dieser Bericht und `build/menschen_batch_3_checks/` mit korrigierter Importkopie, Ausgangshashes, Sicherungen und vollständigen Logs. Ursprüngliche Lieferungen, alte Packs, Registrys und Auswahlen erhalten. Pipeline, App-Einstieg, SRS und Plattformdateien unverändert. Keine Cloud-/Modellaufrufe, Veröffentlichung, Commits oder Pushes; Supabase blieb unangetastet.

`git diff --check`: Exit 2 wegen alter CRLF-/Whitespace-Befunde. Mit `core.whitespace=cr-at-eol` verbleiben sieben bekannte Stellen: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127 und docs/arbeit-bildung-batch-2-import.md:121. Vollständige Logs sind komprimiert gesichert. Eigene Änderungen werden separat gegen Sicherung oder /dev/null geprüft; --no-index --check darf Exit 1 für Unterschiede ohne Diagnostik liefern. Endnachweis mit Wrapper Exit 0: `final-checks.log`. Keine fehlgeschlagenen fachlichen Prüfläufe; die beiden redaktionellen Bindungsfehler wurden beim Gegenlesen erkannt.

## Noch ausstehende Geräteprüfung

Keine Geräte-/Emulatorprüfung durchgeführt. Für macOS Terminal und Windows PowerShell sind die folgenden Flutter-Befehle gleich; iOS benötigt macOS und die vorhandene Signierung:

```text
flutter devices
flutter run -d DEVICE_ID
```

DEVICE_ID durch das gewünschte verbundene Testgerät ersetzen. Die bestehende App regulär aktualisieren und neu starten, dabei Installation und Appdaten erhalten. Menschen & Beziehungen öffnen und 245 Ziele sowie vollständige Wortliste prüfen. Auf einem frischen Testprofil sind die Stapelgrößen 160/489/241/245/245; bestehender Lernfortschritt kann die gruppenbezogene Anzeige beeinflussen. Einige neue feste Sätze, beide Schwieger-Zielwörter und die neutralen Alternativen barbeque/unwind durchspielen; App neu starten und Lernfortschritt prüfen. Dies ist eine Anleitung, kein bereits ausgeführter Test. Der Offlinebetrieb benötigt kein aktives Supabase-Projekt.

## SHA256

- `pipeline/out/menschen_beziehungen_batch_2_v1/pack.json`: `7d3b2a2f0d716df0f12e69b097ff72e1a1b430ca5bac9c858503ead557028bbb`
- `pipeline/out/menschen_beziehungen_batch_2_v1/content.sqlite`: `96f6fab1d2b151f1c57f9645d90acf1a39fd7deb1d43df13615268c21b1c360c`
- `menschen_beziehungen_batch_3/menschen_beziehungen_batch_3.editorial.json`: `528f5db8ae4f49293e94c4fd28f9daac37f96781093af6eeb428230cd7b640e4`
- `menschen_beziehungen_batch_3/menschen_beziehungen_batch_3.display.json`: `e1a5244dfdccce6f1b4e717e35573e220d2e1bac807dcf1b9956d2698a150a70`
- `build/menschen_batch_3_checks/reviewed_delivery/menschen_beziehungen_batch_3.editorial.json`: `1039d6c086a96a4dcdd7a6f036b30379eb4fef72a008abef45b9e1566a512469`
- `build/menschen_batch_3_checks/reviewed_delivery/menschen_beziehungen_batch_3.display.json`: `8a9a3179f79f793fb11330d424092c1294931e90f8d0022c23112b6680743c61`
- `build/menschen_batch_3_checks/reviewed_delivery/manifest.json`: `44b64fb030c66fabe680f9750e9e132c6b4046b638d1340076fe553214196023`
- `pipeline/out/menschen_beziehungen_batch_3_v1/pack.json`: `080e7948e77552d3055b7569032f164c2d6c92640287a8622ced5a29a8cc2855`
- `pipeline/out/menschen_beziehungen_batch_3_v1/content.sqlite`: `9811bf3e0aa71b44d01e66a872b9a0981fd82e990f47571cd1e56ba2cd79a388`
- `assets/content/en/content.sqlite`: `9811bf3e0aa71b44d01e66a872b9a0981fd82e990f47571cd1e56ba2cd79a388`
- `assets/content/en/content.manifest.json`: `f4481fd2550ca1f3bbf3aec3c5ba913fc0bbc4166d49a0a8cf6126e7c9601ec1`

## Tatsächliche Befehle und Outputs

macOS: `PYTHON` steht für `pipeline/.venv-macos/bin/python`. Windows PowerShell: `.\pipeline\.venv\Scripts\python.exe`. Arbeitsverzeichnis Repository-Root. Flutter-/Dart-Befehle auf beiden Systemen gleich.

```text
PYTHON menschen_beziehungen_batch_3/verify_menschen_beziehungen_batch_3.py --repo .
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 165..245, final display 1..245; original registry positions preserved
PASS create_content/build_rows: 1495 cards; 1380 primary goals (160/489/241/245/245); 18 tables
PASS 81 reserved identities, display 1..245; 1414 old IDs and all historical rows preserved
PASS 1001 token positions; two reviewed alternatives; linter 0 errors, 1 warnings
WARNINGS [["stress", "i+1", "'housework'/'housework' Zipf 3.08 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access
Exit 0
```

```text
PYTHON build/menschen_batch_3_checks/reviewed_delivery/verify_menschen_beziehungen_batch_3.py --repo .
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 165..245, final display 1..245; original registry positions preserved
PASS create_content/build_rows: 1495 cards; 1380 primary goals (160/489/241/245/245); 18 tables
PASS 81 reserved identities, display 1..245; 1414 old IDs and all historical rows preserved
PASS 1001 token positions; two reviewed alternatives; linter 0 errors, 1 warnings
WARNINGS [["stress", "i+1", "'housework'/'housework' Zipf 3.08 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access
Exit 0
```

```text
PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 1.81s
Exit 0
```

```text
PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/menschen_beziehungen_batch_2_v1/pack.json --create build/menschen_batch_3_checks/reviewed_delivery/menschen_beziehungen_batch_3.editorial.json --registry pipeline/data/words/en.menschen_beziehungen_batch_3_context_v1.json --display-patch build/menschen_batch_3_checks/reviewed_delivery/menschen_beziehungen_batch_3.display.json --out pipeline/out/menschen_beziehungen_batch_3_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 2570,
    "senses": 3898,
    "cards": 1495,
    "dictionary_forms": 4502,
    "decks": 5,
    "deck_cards": 1495,
    "deck_words": 1391,
    "word_aliases": 22,
    "sentences": 2029,
    "sentence_tokens": 22174,
    "card_sentences": 2023,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "9811bf3e0aa71b44d01e66a872b9a0981fd82e990f47571cd1e56ba2cd79a388"
}
Exit 0
```

```text
PYTHON build/menschen_batch_3_checks/audit_export.py
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2570, 'senses': 3898, 'cards': 1495, 'dictionary_forms': 4502, 'decks': 5, 'deck_cards': 1495, 'deck_words': 1391, 'word_aliases': 22, 'sentences': 2029, 'sentence_tokens': 22174, 'card_sentences': 2023, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 245 original identities, definitions, learning groups, owners and fixed sentences; partition 245/0/0
PASS 1414 historical cards and all old content preserved, except authorized display positions; front correction retained
ALTERNATIVE We invited our neighbours to a barbeque in the garden on Sunday.
ALTERNATIVE I can unwind completely in the company of close friends.
PASS reviewed reading/annotation documents exactly match all 81 sentences and 1001 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 245
PACK_SHA256 080e7948e77552d3055b7569032f164c2d6c92640287a8622ced5a29a8cc2855
SQLITE_SHA256 9811bf3e0aa71b44d01e66a872b9a0981fd82e990f47571cd1e56ba2cd79a388
Exit 0
```

```text
Zusätzliche gezielte Bindungsprüfung im tatsächlichen Export
PASS two compound targets: exact single tokens, offsets, card/sense bindings
PASS both corrected each-other pronoun pairs in actual export; existing dictionary reused
Exit 0
```

```text
dart run tool/stage_content_pack.dart --from pipeline/out/menschen_beziehungen_batch_3_v1
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version menschen_beziehungen_batch_3_v1, schema 3, 10768384 bytes
  sha256 9811bf3e0aa71b44d01e66a872b9a0981fd82e990f47571cd1e56ba2cd79a388
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
```

```text
dart run tool/stage_content_pack.dart --verify
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version menschen_beziehungen_batch_3_v1, schema 3, 10768384 bytes
  sha256 9811bf3e0aa71b44d01e66a872b9a0981fd82e990f47571cd1e56ba2cd79a388
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
deck menschen-beziehungen: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
pack menschen_beziehungen_batch_3_v1 (schema 3, internal: true); 5 decks: 1391 cards, 1495 card sentences, 120 with valid_alternatives, 1495 cards in the pack
00:12 +1: All tests passed!
Exit 0
```

```text
flutter analyze
Analyzing sprachapp...
No issues found! (ran in 3.0s)
Exit 0
```
