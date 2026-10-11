# Körper & Gesundheit: Abschluss mit Batch 3

Stand: 10.10.2026. Die letzten 83 Ziele wurden offline geprüft, importiert und intern gestagt. Körper & Gesundheit ist mit allen 249 Originalzielen vollständig: Partition 249 importiert / 0 aktuell / 0 später. Insgesamt 1629 primäre Lernziele in sechs Stapeln: 160/489/241/245/245/249. Kein Restbatch und keine Batch-4-ZIP.

## Redaktion und Entscheidungen

Alle 83 Satzpaare sowie 1042 Tokenpositionen (949 Worttoken, 93 Satzzeichen) wurden gegengelesen. Die Lesedokumente und vollständigen Tokenbindungen stimmen exakt mit dem Import überein. Die neuen Senses und Formglossen wurden ebenfalls gelesen. Keine belegte Lieferkorrektur nötig; die Original-Lieferung wurde direkt importiert und bleibt bytegleich.

Besonders geprüft: stool bezeichnet Ausscheidung/Stuhlprobe, cast den Gipsverband, positive ein positives Testergebnis und acute eine akute Erkrankung. back am Schuh ist die Rückseite; tape im Maßband ist Messband; examine beim Schädelmodell bedeutet genau betrachten, am Mund ärztlich untersuchen. old bei dream und scar bezeichnet früher; local beim Anästhetikum einen begrenzten Körperbereich. reflex und nail sind körperbezogen. steady verwendet die reservierte Bedeutung ohne Wackeln; die historische Rhythmusbedeutung bleibt getrennt erhalten. Die Untersuchungsliege ist nicht der Esstisch. switch off, kausatives made, Passiv been, had to und before als Präposition/Konjunktion passen zum jeweiligen Satz. session ist laut vorhandener Definition ein zeitlich begrenzter Tätigkeitstermin und passt zur Hygieneschulung. Keine pauschale Altglossenbereinigung.

Beide Schreibvarianten wurden wörtlich eingesetzt:

- Emma compared the amount of fiber in two packets of breakfast cereal.
- The dentist explained the local anesthetic before beginning the procedure.

accepted enthält ausschließlich fibre beziehungsweise anaesthetic. Die Alternativen sind satzbezogen und lernstandsneutral. Keine weitere Lernkarte durch Begleitwort-Senses.

## Verträge und Bestandsschutz

Die Basisrohbytes stimmen mit den beauftragten SHA256-Werten überein. Liefer- und Referenzmanifest, Registry/Gruppen kanonisch, Review- und Displayhashes wurden mit aktuellen Projektquellen geprüft. Keine Referenzquellen zurückkopiert oder Validatoren gelockert.

83 Mitgliedschaften wurden an 167–249 angehängt; anschließend ordnet ausschließlich der gelieferte hashgebundene Display-Patch deck_cards.position und deck_words.position von Körper & Gesundheit auf 1–249. Originalauswahl, Registrypositionen und alte Kontexte bleiben bytegleich.

Alle 249 Originalidentitäten, Definitionen, Lerngruppen, Besitzer und genau ein aktiver fester Satz pro Ziel wurden abgeglichen. Alle 1661 bisherigen Karten und historischen Inhalte bleiben erhalten, außer den autorisierten Körper-Anzeigepositionen. Auch die drei Batch-1-Bindungskorrekturen und die physikalische blood-pressure-Bindung aus Batch 2 bestehen unverändert fort. Keine zusätzlichen Ziele oder Stapel.

Alle 18 SQLite-Tabellen wurden vollständig gegen build_rows abgeglichen: 1744 Karten, 2278 Satztexte, 2272 historische Satzverknüpfungen, 1640 Wortbesitzzeilen. Interner Testpack, keine Veröffentlichung, keine Modellaufrufe oder Kosten.

## Häufigkeitshinweise

Linter: 0 Fehler, sechs Hinweise; keine Umformulierung allein wegen der Schwelle 3,5.

| Ziel | Begleitwort | Zipf |
|---|---|---:|
| itch | woollen | 2,74 |
| painkiller | pharmacist | 3,34 |
| drowsy | sleepless | 3,18 |
| heart | stethoscope | 2,66 |
| wrist | fastened / fasten | 3,02 |
| stamina | uphill | 3,38 |

## Staging und Abweichung beim Sicherungsablauf

Vorab wurde der Ausgangsstand von 2128 Dateien samt Hashes erfasst. Beim Vorbereitungsskript war eine Assertion zu breit: Sie suchte allgemein nach batch_3_v1, das schon bei anderen Stapeln vorkam. Die Assertion schlug vor Änderung des Tests und vor der separaten Asset-Kopie fehl. Das anschließend gestartete Staging lief bereits durch. Dies wich von der vorgesehenen Reihenfolge „erst sichern, dann stagen“ ab.

Der vorherige SQLite-Stand wurde danach aus pipeline/out/koerper_gesundheit_batch_2_v1/content.sqlite und das vorherige Manifest aus build/unit_test_assets/assets/content/en/content.manifest.json gesichert. Beide Kopien stimmen exakt mit den VOR Staging erfassten SHA256-Werten überein. Sicherung: build/koerper_batch_3_checks/backup/assets/content/en/. Kein Verlust des vorherigen Stands. Die Assertion wurde auf den konkreten Körper-Packnamen eingeschränkt; der Test erhielt nur den neuen Versionsblock mit konkreten Zählererwartungen.

Flutter-/Dart-Aufrufe benötigten den vorhandenen SDK-Cache außerhalb des Repositorys. Keine App-, Pipeline-, SRS-, Modell-, Budget- oder Plattformänderung. Echte user.db und review_log wurden nicht geöffnet. Keine Cloud, Supabase, Commits oder Pushes. Geräteprüfung nicht ausgeführt.

## Prüfungen mit tatsächlichen Ausgaben

Alle Logs: build/koerper_batch_3_checks/. Python auf macOS: pipeline/.venv-macos/bin/python; unter Windows PowerShell: .\pipeline\.venv\Scripts\python.exe. Die folgenden Argumente gelten mit dem jeweiligen Interpreter; Dart/Flutter/Git sind auf beiden Systemen identisch.

```text
PYTHON koerper_gesundheit_batch_3/verify_koerper_gesundheit_batch_3.py --repo .
PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/koerper_gesundheit_batch_2_v1/pack.json --create koerper_gesundheit_batch_3/koerper_gesundheit_batch_3.editorial.json --registry pipeline/data/words/en.koerper_gesundheit_batch_3_context_v1.json --display-patch koerper_gesundheit_batch_3/koerper_gesundheit_batch_3.display.json --out pipeline/out/koerper_gesundheit_batch_3_v1
PYTHON build/koerper_batch_3_checks/audit_export.py
PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
dart run tool/stage_content_pack.dart --from pipeline/out/koerper_gesundheit_batch_3_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
```

### verifier.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS hash-bound display patch: append 167..249, final display 1..249; original registry positions preserved
PASS create_content/build_rows: 1744 cards; 1629 primary goals (160/489/241/245/245/249); 18 tables
PASS 83 reserved identities, display 1..249; 1661 old IDs and all historical rows preserved
PASS 1042 token positions; two reviewed alternatives; linter 0 errors, 6 warnings
WARNINGS [["itch", "i+1", "'woollen'/'woollen' Zipf 2.74 below 3.5"], ["painkiller", "i+1", "'pharmacist'/'pharmacist' Zipf 3.34 below 3.5"], ["drowsy", "i+1", "'sleepless'/'sleepless' Zipf 3.18 below 3.5"], ["heart", "i+1", "'stethoscope'/'stethoscope' Zipf 2.66 below 3.5"], ["wrist", "i+1", "'fasten'/'fastened' Zipf 3.02 below 3.5"], ["stamina", "i+1", "'uphill'/'uphill' Zipf 3.38 below 3.5"]]
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
    "lemmas": 2873,
    "senses": 4254,
    "cards": 1744,
    "dictionary_forms": 4966,
    "decks": 6,
    "deck_cards": 1744,
    "deck_words": 1640,
    "word_aliases": 28,
    "sentences": 2278,
    "sentence_tokens": 25249,
    "card_sentences": 2272,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04"
}

Exit 0
```

### audit-export.log

```text
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2873, 'senses': 4254, 'cards': 1744, 'dictionary_forms': 4966, 'decks': 6, 'deck_cards': 1744, 'deck_words': 1640, 'word_aliases': 28, 'sentences': 2278, 'sentence_tokens': 25249, 'card_sentences': 2272, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 249 original identities, definitions, learning groups, owners and fixed sentences; partition 249/0/0
PASS 1661 historical cards and all old content preserved, except authorized Körper display positions; all Batch-1 corrections retained
ALTERNATIVE Emma compared the amount of fiber in two packets of breakfast cereal.
ALTERNATIVE The dentist explained the local anesthetic before beginning the procedure.
PASS reviewed reading/annotation documents exactly match all 83 sentences and 1042 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 245
DECK koerper-gesundheit 249
PACK_SHA256 c03047452c197a5bd4985af0faf64fb1e0614765a8a7c3f475f8c088a595f457
SQLITE_SHA256 98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04
NEW_TOKEN_COUNTS 949 word tokens 93 punctuation
PASS blood pressure uses explicit physical sense; social-pressure sense/card preserved; no additional learning card

Exit 0
```

### pytest.log

```text
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 0.91s

Exit 0
```

### stage.log

```text
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version koerper_gesundheit_batch_3_v1, schema 3, 12234752 bytes
  sha256 98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
```

### stage-verify.log

```text
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version koerper_gesundheit_batch_3_v1, schema 3, 12234752 bytes
  sha256 98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04
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
pack koerper_gesundheit_batch_3_v1 (schema 3, internal: true); 6 decks: 1640 cards, 1744 card sentences, 125 with valid_alternatives, 1744 cards in the pack
00:08 +1: All tests passed!

Exit 0
```

### flutter-analyze.log

```text
Analyzing sprachapp...
No issues found! (ran in 1.8s)

Exit 0
```

## SHA256

| Datei | SHA256 |
|---|---|
| pipeline/out/koerper_gesundheit_batch_2_v1/pack.json | `2d14e22abb6c3e89b5a6a3ac1fdec11312ec78bae5b9bce497b9e4061110f49c` |
| pipeline/out/koerper_gesundheit_batch_2_v1/content.sqlite | `ed4c3b6896d02f20ab1dadaab5ebe478aee2fb95fc01ad16f92776185c308b7f` |
| koerper_gesundheit_batch_3/koerper_gesundheit_batch_3.editorial.json | `0f9f601d4582fc4c588ec7446f79d25cb267752f06366f3ebc95b1a84ed71de1` |
| koerper_gesundheit_batch_3/koerper_gesundheit_batch_3.display.json | `3c3d660afd6ce45986f03530e089ddaa02f39d04c4779bd5a06e7053583772b0` |
| koerper_gesundheit_batch_3/manifest.json | `0ceb6c8ac2344f75a422173bbae402f1ba0afaf718a38c3ab4cbd38bb4767596` |
| pipeline/data/selection/koerper_gesundheit_v1.json | `0d0c2ab1b60f5606a35d0e2f1b4843871aa32cda975a4651440df7869d01fd64` |
| pipeline/data/selection/koerper_gesundheit_batch_3_context_v1.json | `cdf74b497e41b3e47f3bf4f6649492d55f0563968fb24d39ba76fd4ce81a81c9` |
| pipeline/data/words/en.koerper_gesundheit_batch_3_context_v1.json | `dfea18cd93a72a484f0d7ebca3d501f7880e99e4ddddf1cbc32931bab4f9493b` |
| pipeline/data/learning_groups/en.koerper_gesundheit_batch_3_context_v1.json | `fd6cf73f4dcf1bed8ad22f5c09b7c4ae11451d80faa98f5182dd50ecbd33fdd9` |
| pipeline/out/koerper_gesundheit_batch_3_v1/pack.json | `c03047452c197a5bd4985af0faf64fb1e0614765a8a7c3f475f8c088a595f457` |
| pipeline/out/koerper_gesundheit_batch_3_v1/content.sqlite | `98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04` |
| assets/content/en/content.sqlite | `98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04` |
| assets/content/en/content.manifest.json | `a3c692f8662ef680e14f6285f405cb68cb74c1fa1861ac463caf458c585df3c0` |

## Arbeitsbaumprüfung

2124 von 2128 Ausgangsdateien bleiben bytegleich. Nur Asset/Manifest, test/data/real_pack_test.dart und NEXTSTEPS.md wurden geändert. Neu sind der Batch-3-Ausgabeordner und dieser Bericht. Baseline, Vorher-/Nachher-Status und final-protection.json dokumentieren den Bestandsschutz.

git diff --check: Exit 2 wegen vorhandener CRLF-/Whitespace-Befunde. Mit core.whitespace=cr-at-eol verbleiben sieben Altbefunde: DESIGN.md:162–164; docs/alltag-zuhause-continuation.md:148,153; docs/arbeit-bildung-batch-1-import.md:127; docs/arbeit-bildung-batch-2-import.md:121. Keine globale Bereinigung. Eigene Änderungen separat ohne Whitespace-Diagnostik geprüft (Wrapper Exit 0); git status --short: Exit 0. Umfangreiche Rohlogs komprimiert unter build/koerper_batch_3_checks/.

## macOS / iPhone aktualisieren

1. Syncthing auf beiden Rechnern vollständig synchronisieren lassen; Konflikte ausschließen. Danach im synchronisierten Repository auf dem Mac arbeiten.
2. Im macOS-Terminal `dart run tool/stage_content_pack.dart --verify` ausführen. Erwartet werden koerper_gesundheit_batch_3_v1 und SQLite-SHA256 98aaf290c04d7f5305b607ebe9a4c5233f0a1a0eb88271acd90af37af9ffac04.
3. Das vorhandene iPhone verbinden und entsperren. Mit `flutter devices` die Geräte-ID ermitteln und `flutter run -d DEVICE_ID` mit dieser ID ausführen. Dieselbe bestehende App-Konfiguration und Bundle-ID verwenden; die vorhandene Installation aktualisieren, nicht deinstallieren und keinen Lernstand zurücksetzen. Ein vollständiger Neubau bindet das neue Asset ein.
4. Auf dem Gerät den Stapel öffnen und die Inhalte prüfen. Der redaktionelle Sollbestand ist 249 Ziele; bestehende Lerngruppenzustände können die individuelle Anzeige beeinflussen. Diese Geräteprüfung wurde hier nicht durchgeführt.

Inhaltlich ist der Stapel vollständig. Offen bleiben die Geräteprüfung und die sieben unveränderten Whitespace-Altbefunde.
