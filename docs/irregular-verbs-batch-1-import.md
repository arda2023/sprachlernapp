# Unregelmäßige Verben – Batch 1: Import und interne Bereitstellung

Stand: 10.10.2026. **`irregular_verbs_batch_1_v1` intern gestagt und verifiziert.** 83 neue Satzpaare und 16 unveränderte Wiederverwendungen bilden drei Ansichten mit je 33 Übungen. Die geprüfte Folge-ZIP fordert genau 83 neue Satzpaare für Batch 2 an. Keine Batch-2-Sätze erzeugt, keine öffentliche Inhaltsfreigabe.

## Quelle, Sicherung und Original-Lieferung

Ausgangspack: `pipeline/out/natur_umwelt_batch_3_v1/pack.json` samt `content.sqlite`, Schema 3, acht Stapel und 2121 besitzgebundene Primärziele. Gemeinsame Auswahl: `pipeline/data/selection/irregular_verbs_v1.json`, gebundene Registry `pipeline/data/words/en.irregular_verbs_v1.json` und Gruppensnapshot `pipeline/data/learning_groups/en.irregular_verbs_v1.json`. Paket B erlaubt nach Integrationsabnahme Schema-4-Staging; die tatsächlichen Werkzeuge und der App-Leser wurden in diesem Auftrag erneut ausgeführt.

**Vor den Änderungen** wurden Produktionsasset, Manifest und beide Basispackdateien bytegenau nach `build/irregular_verbs_batch_1_backup/` unter Beibehaltung ihrer relativen Pfade gesichert. `hashes.json` enthält die vier Ausgangshashes; `baseline.json` erfasst weitere 2589 vorbestehende Dateien. Der spätere Audit bestätigt die Sicherung erneut. Bestehende Änderungen wurden erhalten.

| Datei | SHA256 vor Import |
|---|---|
| Quell-JSON | `7d1b7a48fc1ec3799d0216b6a89b012de1e02064e8e84b310c11815dbae77a8e` |
| Quell-SQLite und damaliges Asset | `34b7edc0b66cf66933183d29ad505afd0bb4c67ed8570b7b3bdf0d50ffe4aee7` |
| damaliges Asset-Manifest | `e316e78d1a4bb35347d703a618577d08476c929f8ace1d00f0c3f1ac260adc3b` |
| Original `editorial_content_v3.json` | `63be2ee6cf881973d93d4c8f957a6d4acb49b6811a1dc25b19bec87e631eb9c7` |

Alle sechs in `irregular_verbs_batch_1_lieferung/manifest.json` genannten Dateien wurden SHA256-geprüft und am Ende erneut unverändert bestätigt. Lieferauswahl und lokale Auswahl sind exakt gleich; kanonischer Auswahlhash `a0f2d79e8553b1da9dd606672b3c3b5f6c304d2cc6b762ce78fc761f3ebd8d58`. Basis- oder Auswahlhash wurden nicht passend gerechnet. Die 759 Einträge von `token_review.json` entsprechen exakt den Wortpositionen der Original-Lieferung; die HTML-Übersicht enthält dieselben 83 englischen und deutschen Texte.

## Redaktionelle Prüfung und isolierte Korrektur

Alle 83 englischen Sätze, deutschen Übersetzungen, Formfunktionen und 851 Tokenpositionen einschließlich 92 Satzzeichen wurden gegengelesen. Der echte Importer prüft zusätzlich Tokenisierung, Offsets, vollständige Abdeckung, Wörterbuchbindungen, Reviewhashes und Zieltoken-Funktion. Grundformen, auch bei `bet`, `broadcast`, `cost`, stehen in eindeutigen Modal-/Infinitivkontexten; Präteritum/Partizip werden durch Satzsyntax getrennt.

Die geforderten Begleitwortbindungen passen: `station#rundfunksender`, `interview#mediengespraech`, bestehendes `card#spielkarte`, `post#pfosten`, `on#wetteinsatz` gegenüber `on#sendemedium` und `to#festhalten_an`. Sie erzeugen keine Wortbesitzer oder Lernkarten.

Eine zusätzliche kontextuelle Korrektur betrifft **`irregular-v1-b1-s060`, Token 4, `see`**: „My brother came to see me last weekend.“ bedeutet einen Besuch. Die Originalbindung `see/VERB|see#sehen` wurde ausschließlich in einer separaten Importkopie auf `see/VERB|see#besuchen` geändert. Eine neue Besuchsbedeutung und eine passende Formglosse wurden ergänzt. Kein neuer Lemma-/Karten-/Besitzdatensatz; keine Tempus-Sense; der spätere visuelle `see`-Formkatalog bleibt unverändert. Englischer Text, Übersetzung und Offsets bleiben gleich. Nur der betroffene Token-Reviewhash und die zugehörige Begründung wurden konsistent aktualisiert.

- Importkopie: `pipeline/data/curation/irregular_verbs_batch_1_import_v1.json`.
- Einzelbeleg mit Vorher/Nachher und vollständigem aktualisiertem Review: `pipeline/data/curation/irregular_verbs_batch_1_corrections_v1.json`.
- Importkopie SHA256: `7881572df443885a07a13e227b0693dccbd1442669031d51bde87d9924c28b66`.
- Tatsächlich hinzugefügt: 43 Senses = 11 ausgewählte Zielbedeutungen + 32 Begleitbedeutungen; 82 Wörterbuchformzeilen. Die Original-Lieferung enthielt 31 Begleitbedeutungen/81 Formzeilen.

Alte gemeinsam genutzte Glossen bleiben erhalten, auch flektierte/kompositumsbezogene Einträge wie `bent → beugte`, `brought → brachte`, `caught → fing`, `cost → kostete`, `software → Software-`, `concert → Konzert-`, `bedroom → Schlafzimmer-`. Sie wurden weder still korrigiert noch als kontextübergreifend neu freigegeben.

Vier Alternativen wurden wörtlich eingesetzt und geprüft; `accepted` enthält weiterhin nur die jeweilige Zielform:

```text
s045: We burned the last of our wood yesterday evening.
s046: We have burned all the wood in the fireplace.
s078: Last night, I dreamed about a house beside the sea.
s079: I have dreamed about my school several times.
```

Diese Varianten sind jeweils im konkreten Satz neutral; daraus folgt keine Freigabe anderer Tempora oder verbverwandter Antworten. Die 16 alten Übungen dieses Batches behalten exakt ihre festen Sätze und Tokens. 71 Wiederverwendungen beziehen sich weiterhin auf den vollständigen Vier-Batch-Katalog.

## Tatsächlicher Import und Zählung

Der vorhandene V3-Create-Weg exportierte nach `pipeline/out/irregular_verbs_batch_1_v1/`; keine bestehende Ausgabe wurde überschrieben. Alle alten JSON-Zeilen und sämtliche alten SQL-IDs/Spaltenwerte wurden gegen die Basis verglichen und erhalten. `release` und Registry-Bindung wechseln planmäßig zur neuen Version; Schema-4-Zusatzspalten kommen additiv hinzu. Echte Nutzerdatenbanken oder Lernstände wurden nicht geöffnet.

| Größe | Tatsächlicher Wert |
|---|---:|
| Karten im gesamten Pack | 2319 = 2236 + 83 |
| aktive feste Karten-Satzbindungen | 2319 |
| historische Satzbindungen insgesamt | 2847 |
| Satztexte insgesamt | 2853 = 2770 + 83 |
| aktive Formziele | 99 |
| Übungen pro neuer Formansicht | 33 |
| Lexikalanker dieses Batches | 33 |
| davon zuvor als Lernbedeutung vorhanden / neu | 14 / 19 |
| neue aktive Oberflächenbesitzer | 54 |
| Oberflächenbesitzer insgesamt | 2186 |
| gemischtes Übungsinventar, dedupliziert | 2204 |
| gemischte lexikalische Wörter | 2136 |

Die acht normalen Stapel bleiben bei **160 / 489 / 241 / 245 / 245 / 249 / 250 / 242 Übungen**. Neue Formkarten können Besitzer in diesen Stapeln haben, werden dort wegen `form_only` nicht als gewöhnliche Übungen eingeführt. Besitzpositionen und Form-Praxispositionen sind getrennt. Die drei Formansichten enthalten jeweils fortlaufende 33 Praxispositionen.

Die globale Wortzahl lautet **2121 − 4 + 19 = 2136**: Fünf bisher getrennt gezählte Kopula-Gruppen von `be` werden lexikalisch ein Konzept, ohne IDs, Übungsgruppen oder Zustände zusammenzulegen. Die 99 Formmitgliedschaften sind 33 Konzepte, davon nur 19 neu. Die Übungszahl ergibt sich dagegen aus **2121 + 83 = 2204**. Die Rohmitgliedschaften aller Ansichten (2231) sind wegen wiederverwendeter Karten und Lerngruppen kein globaler Zähler. Das vorhandene Dart-Diagnosewerkzeug und der Pack-Lesetest bestätigen diese Projektion unabhängig von der redaktionellen Vorausrechnung.

## Gefundener Leserfehler und begrenzte Korrektur

Der erste echte Dart-Leseversuch lehnte den exportierten Pack mit `ContentUnavailable(incompatible): Schema 4: Bedeutung/Definition fehlt` ab, Exit 255. Konkrete frühe Belege: `omar#omar`, `notice#bemerkt`, `that#dass`, `the#die` und `classroom#klassenzimmer`; insgesamt 2228 geerbte Senses mit NULL-Langdefinition. Die gemeinsame Pipeline-Schema-/Build-Implementierung behandelt `definition_de` als nullable; die Migration soll geerbte Senses erhalten. Der neue Schema-4-Appvalidator verlangte dagegen unbeabsichtigt eine Langdefinition für jedes alte Token.

Die minimale Korrektur in `lib/data/content/form_content_validation.dart` lässt NULL-Langdefinitionen gemäß bestehendem Feldvertrag zu, prüft weiterhin eine nichtleere Glosse und eine nichtleere Langdefinition, sofern vorhanden. Alle Referenz-, Wörterbuch-, Funktions-, Satz- und Besitzprüfungen bleiben aktiv. Keine Sperre übersprungen, keine Altdaten mit erfundenen Definitionen aufgefüllt, keine SRS-/Synonymlogik geändert. Der Regressionstest akzeptiert nullable Definitionen, verwirft aber weiterhin fehlende Glossen. Erst nach bestandenem App-Leser und Formtests wurde gestagt.

`test/data/real_pack_test.dart` prüft zusätzlich die drei Formansichten, 16 Wiederverwendungen, getrennte `cut/cut/cut`-IDs und feste Sätze sowie die tatsächlichen Wort-/Übungszahlen. Die vorhandenen normalen Stapelprüfungen bleiben aktiv. Besitzinventar und Praxisinventar werden auch im Test getrennt.

## Tatsächliche Befehle und Ausgaben

Ausführung auf macOS. Flutter-/Dart-Befehle sind unter Windows PowerShell identisch. Für Python unter Windows den vorhandenen aktivierten Projektinterpreter `python` statt `pipeline/.venv-macos/bin/python` verwenden. `/tmp/irregular-verbs-b1/` enthält die lokalen macOS-Arbeitslogs; Sicherung und Korrekturbelege liegen zusätzlich im Repository. Keine Paketinstallation, Modell-/Cloud-Aufrufe, Remote-Migrationen, Commits oder Pushes.

```text
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/natur_umwelt_batch_3_v1/pack.json --create pipeline/data/curation/irregular_verbs_batch_1_import_v1.json --registry pipeline/data/words/en.irregular_verbs_v1.json --out pipeline/out/irregular_verbs_batch_1_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 3497,
    "senses": 4989,
    "cards": 2319,
    "dictionary_forms": 5889,
    "decks": 11,
    "deck_cards": 2290,
    "deck_words": 2186,
    "word_aliases": 37,
    "sentences": 2853,
    "sentence_tokens": 31715,
    "card_sentences": 2847,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1,
    "lexical_targets": 33,
    "card_lexical_targets": 101,
    "form_targets": 99,
    "deck_practice_targets": 99
  },
  "sha256": "cb719374dbd760809ab261333d7a3fbbda1373c565dec64134ac2db219298c60"
}
Exit 0

pipeline/.venv-macos/bin/python /tmp/irregular-verbs-b1/verify_pack.py
PRESERVATION all old metadata, cards, sentences, tokens, links, owners and dictionary rows exact PASS
OLD SQL IDs and columns unchanged PASS
SQLITE_ALL_ROWS {"audio_assets": 0, "card_lexical_targets": 101, "card_sentences": 2847, "cards": 2319, "content_releases": 1, "deck_cards": 2290, "deck_practice_targets": 99, "deck_words": 2186, "decks": 11, "dictionary_forms": 5889, "exercises": 0, "form_targets": 99, "grammar_rules": 0, "languages": 1, "lemmas": 3497, "lexical_targets": 33, "senses": 4989, "sentence_tokens": 31715, "sentences": 2853, "stories": 1, "story_sentences": 6, "word_aliases": 37}
LINTER 2847 links; 448 findings; 0 errors
NEW FINDINGS [{'card': 'irregular:blow:past_participle', 'level': 'warn', 'rule': 'i+1', 'message': "'spoonful'/'spoonful' Zipf 2.87 below 3.5"}]
PRACTICE irregular_verbs_base 33
PRACTICE irregular_verbs_past 33
PRACTICE irregular_verbs_participle 33
REUSE 16
PRE-STAGE BACKUP and production hashes still match PASS
Exit 0
```

Der vollständige vorhandene Satzlinter lief im Export. Kein Fehler; 448 Hinweise insgesamt, davon genau einer zu neuen Karten: `irregular:blow:past_participle`, `spoonful`, Zipf 2,87 unter 3,5. Die bekannte Warnung führte zu keiner Umformulierung. Die übrigen Hinweise betreffen den mitgeprüften Bestand.

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_form_targets.py pipeline/tests/test_form_authoring_details.py pipeline/tests/test_word_registry.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_editorial_import.py -q
........................................................................ [ 75%]
........................                                                 [100%]
96 passed in 17.49s
Exit 0

flutter test --no-pub test/data/form_content_test.dart test/data/form_learning_test.dart test/domain/form_projection_test.dart test/form_learning_flow_test.dart test/form_counts_widget_test.dart
00:01 +27: All tests passed!
Exit 0

flutter test --no-pub test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
SCHEMA4 mixed exercises=2204 lexical=2136; 99 forms / 16 reuse / cut 3 identities PASS
deck allgemeine-sprache: 160 learning targets, 170 ownership cards, 170 fixed sentence assignments verified
deck reisen: 489 learning targets, 501 ownership cards, 501 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 246 ownership cards, 246 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck menschen-beziehungen: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck koerper-gesundheit: 249 learning targets, 254 ownership cards, 254 fixed sentence assignments verified
deck essen-trinken: 250 learning targets, 250 ownership cards, 250 fixed sentence assignments verified
deck natur-umwelt: 242 learning targets, 242 ownership cards, 242 fixed sentence assignments verified
deck irregular_verbs_base: 33 learning targets, 33 ownership cards, 33 fixed sentence assignments verified
deck irregular_verbs_past: 33 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
deck irregular_verbs_participle: 33 learning targets, 0 ownership cards, 0 fixed sentence assignments verified
pack irregular_verbs_batch_1_v1 (schema 4, internal: true); 11 decks: 2186 cards, 2319 card sentences, 142 with valid_alternatives, 2319 cards in the pack
00:55 +1: All tests passed!
Exit 0

flutter analyze --no-pub
Analyzing sprachapp...
No issues found! (ran in 3.2s)
Exit 0
```

Frühe Diagnoseausgaben getrennt: System-`python3` hatte für die Audit-Hilfe kein `yaml` (Exit 1); anschließend vorhandene Pipeline-venv verwendet, keine Installation. Dart/Flutter benötigten freigegebenen SDK-Cachezugriff. Der erste Analyse-Lauf meldete zwei Hinweise im erweiterten Test (`avoid_print`, fehlende Blockklammern, Exit 1); beide behoben, final ohne Befund. Die Formtests meldeten zusätzlich eine Drift-Debugwarnung zu mehreren Testdatenbanken, bestanden aber vollständig. Keine vollständige Flutter-Suite ausgeführt.

```text
dart run tool/report_learning_groups.dart pipeline/out/irregular_verbs_batch_1_v1/content.sqlite
mixed: raw_words=2231, learning_targets=2204, lexical_words=2136, form_memberships=99
Exit 0

dart run tool/stage_content_pack.dart --from pipeline/out/irregular_verbs_batch_1_v1
staged assets/content/en/content.sqlite
  version irregular_verbs_batch_1_v1, schema 4, 15548416 bytes
  sha256 cb719374dbd760809ab261333d7a3fbbda1373c565dec64134ac2db219298c60
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version irregular_verbs_batch_1_v1, schema 4, 15548416 bytes
  sha256 cb719374dbd760809ab261333d7a3fbbda1373c565dec64134ac2db219298c60
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0
```

Simulatorprüfung: `xcrun simctl list devices available` scheiterte zunächst im eingeschränkten Prozess, danach mit lokalem Dienstzugriff Exit 0. Die Liste enthielt reguläre iOS-26.5-/27.0-Simulatoren, keinen als isolierten Testsimulator gekennzeichneten Bestand. Keine bestehende Appinstallation/Nutzerdatenbank verwendet, kein Gerätenachweis behauptet. Die synthetischen Flutter-Tests prüfen getrennte Formzustände und Neustart; sie ersetzen keinen Geräteversuch. `lib/main.dart` ist bytegleich, es wurde kein temporärer App-Einstieg angelegt.

## Fortsetzung und geprüfte Batch-2-ZIP

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/irregular_verbs_v1.json --prepare-continuation irregular_verbs_batch_2_context_v1 --batch 2 --source-pack pipeline/out/irregular_verbs_batch_1_v1/pack.json --source-sqlite pipeline/out/irregular_verbs_batch_1_v1/content.sqlite --out pipeline/data/selection/irregular_verbs_batch_2_context_v1
{
  "snapshots": "PASS",
  "selection": "pipeline/data/selection/irregular_verbs_batch_2_context_v1/selection.json",
  "registry": "pipeline/data/selection/irregular_verbs_batch_2_context_v1/registry.json",
  "partition_counts": {
    "imported": 99,
    "current": 105,
    "future": 198
  }
}
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/irregular_verbs_batch_2_context_v1/selection.json --batch 2 --out build/irregular_verbs_authoring_batch_2.zip
Exit 0
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/irregular_verbs_authoring_batch_2.zip
Exit 0
```

Der vorhandene Fortsetzungsweg erzeugt im neuen Verzeichnis `pipeline/data/selection/irregular_verbs_batch_2_context_v1/` die Dateien `selection.json`, `registry.json` und `learning_groups.json`. Pfade/Hashes wurden aus dem tatsächlichen Export gebunden, keine alten Snapshots überschrieben. Verifier-Ausgabe (Referenzlisten hier als Längen zusammengefasst):

```json
{
  "zip_verification": "PASS",
  "zip_sha256": "ae8cee83cb95e20cbecf23ab6e4f7f09424a5a07c55eae50ce65c25ac427d1f0",
  "content_schema_version": 4,
  "sqlite_tables": 22,
  "counts": {
    "imported": 99,
    "current": 105,
    "future": 198,
    "reused_cards": 71,
    "new_form_targets": 303,
    "new_lexical_targets": 101,
    "new_surface_reservations": 0,
    "new_cards": 248
  },
  "partition_counts": {
    "imported": 99,
    "current": 105,
    "future": 198
  }
}
```

ZIP geschlossen und erneut vollständig geöffnet: CRCs, alle manifestierten Dateihashes, Referenzen, Reuse-Belege, vollständige Metadatenpartition und **alle Zeilen aller 22 Quelltabellen** PASS. `current_authoring_tasks.json` enthält exakt **83 neue Satzaufträge und 22 unveränderte Wiederverwendungen**. Die 71 Reuse-Belege im Gesamtzähler umfassen alle vier Batches. `new_surface_reservations: 0` bedeutet keine zusätzliche Reservierung gegenüber dem schon in Batch 1 gebundenen Gesamtkatalog; weitere Karten/Sätze fehlen weiterhin planmäßig.

| Abschlusshash | SHA256 |
|---|---|
| Export-JSON | `23e6731e358f7e9f59a4dfa0f304ac850ef4a7abf5786649a7ca384f1c5f2a46` |
| Export-SQLite und gestagtes Asset | `cb719374dbd760809ab261333d7a3fbbda1373c565dec64134ac2db219298c60` |
| neues Asset-Manifest | `707971486442f1a4b1513f332bdaeba39349adca86f80d1b516797d0e479494e` |
| Batch-2-ZIP | `ae8cee83cb95e20cbecf23ab6e4f7f09424a5a07c55eae50ce65c25ac427d1f0` |

## Dateiabgleich und offener Schritt

Der Baseline-Abgleich weist als geänderte vorbestehende Dateien nur den Formleser, die zwei genannten Tests und `NEXTSTEPS.md` aus. Hinzu kommen neuer Bericht, Importkopie/Korrekturbeleg, Export-/Fortsetzungsdateien, Sicherung und ZIP. Produktionsasset und Manifest wurden ausschließlich durch das Staging-Werkzeug aktualisiert. Alte Quelle, Original-Lieferung, Auswahlen, Registrys und historische Lieferungen blieben unverändert.

Eigene Diffprüfung: `git -c core.whitespace=cr-at-eol diff --check --` mit den geänderten Leser-/Test-/Dokumentpfaden und neuen Import-/Snapshotdateien: keine Ausgabe, Exit 0. CRLF wird dabei ausdrücklich als Zeilenende behandelt. Die früher dokumentierten repositoryweiten CRLF-/Whitespace-Altbefunde bleiben bestehen; keine pauschale Bereinigung oder erneute riesige Gesamtausgabe. Neue ungetrackte JSON-/Markdown-Dateien werden zusätzlich direkt auf nachgestellte Leerzeichen geprüft.

Nächste Aktion: **83 neue Batch-2-Satzpaare anhand der geprüften ZIP im Chat redigieren.** Die 22 Wiederverwendungen bleiben unverändert. Öffentliche Freigabe und ein tatsächlicher isolierter Gerätenachweis sind nicht Bestandteil des behaupteten Prüfergebnisses.

Vollständiger ZIP-Pfad: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/irregular_verbs_authoring_batch_2.zip`.
