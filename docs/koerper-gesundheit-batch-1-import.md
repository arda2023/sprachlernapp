# Körper & Gesundheit – Batch 1 importiert, Batch 2 vorbereitet

Stand: 10.10.2026. Genau **83 Ziele, 83 Satzpaare und 1037 Tokenpositionen** offline geprüft, importiert, exportiert und intern gestagt als `koerper_gesundheit_batch_1_v1`. Eine satzbezogen geprüfte Schreibalternative. Alle 1495 bisherigen Karten und sämtliche historischen Inhalte einschließlich aller Stapelpositionen unverändert.

Die sechs Stapel enthalten **1463 primäre Lernziele: 160 / 489 / 241 / 245 / 245 / 83**. Physischer Gesamtbestand: 1578 Karten, 2112 Satztexte, 2106 historische Satzverknüpfungen, 1474 Wortbesitzzeilen, 23211 Tokenpositionen.

Geprüfte Batch-2-ZIP: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/koerper_gesundheit_authoring_batch_2.zip`. Partition **83 importiert / 83 aktuell / 83 später**. Alle 249 ursprünglichen Identitäten und deutschen/englischen Zieldefinitionen enthalten, keine Batch-2-Sätze erstellt.

## Eingang, Redaktion und gezielte Korrekturen

Die Lieferung lag bereits als `koerper_gesundheit_batch_1/` entpackt vor. Nichts erneut entpackt oder überschrieben. 92 Dateihashes im Liefermanifest sowie das Referenzmanifest geprüft. Ausgangsbasis und SQLite entsprechen exakt den beauftragten Hashes. Referenzquellen wurden nie über Projektquellen kopiert; beide Lieferprüfungen nutzten `--repo .` und damit die aktuellen Quellen.

Alle 83 Satzpaare und sämtliche Wortbindungen gegengelesen; der Audit gleicht die gelesenen reading.json-/annotation_review.txt-Inhalte exakt mit den tatsächlich importierten Zeilen ab. 946 Worttokens und 91 Interpunktionspositionen, zusammen 1037 vollständig abgedeckte Positionen. Keine unabhängige menschliche Sprachfreigabe behauptet.

Geprüfte Schwerpunkte: minutes sind Zeitminuten; left bei lung/sling ist linke, bei numb verließ; used bei tweezers benutzte, nicht used to; lower untere, office Arztpraxis. shape/rest/change/serving sind Nomen. sweat als Handlung beziehungsweise Schweiß-Nomen, wake transitives Wecken versus woke intransitives Aufwachen. have to, Perfect-have und Vollverb-have bleiben getrennt. shake hat ein direktes Objekt und erfüllt die transitive Zieldefinition.

Drei Bindungsfehler nur in `build/koerper_batch_1_checks/reviewed_delivery/` korrigiert:

| Fundstelle | Vorher | Nachher / Grund |
|---|---|---|
| kidney: as well as the other | other/ADJ\|other#anderen | other/PRON\|other#anderen; selbstständiger Verweis auf die andere Niere, vorhandener passender Pronomen-Sense. |
| isolation: visiting the ward | ward/NOUN\|ward#krankenhausstation | ward/NOUN\|ward#krankenstation; bereits reservierter Batch-2-Key samt exakter Glosse und Definition. |
| carbohydrate: carbohydrate and protein | protein/NOUN\|protein#eiweiss | protein/NOUN\|protein#eiwei; bereits reservierter Batch-2-Key samt exakter Definition. Der historische Slug wird nicht normalisiert. |

ward und protein bezeichneten bereits genau die reservierten Lernbedeutungen. Ihre abweichenden neuen Keys hätten beim späteren Import doppelte Senses verursacht. Korrigiert wurden zwei neue Sensezeilen, zwei neue Wörterbuchreferenzen, drei Tokenbindungen und die drei betroffenen Review-Tokenhashes. annotation_review.txt und redaktionelle Notiz der Kopie aktualisiert; Manifest der Kopie vollständig neu abgeglichen. local_corrections.json enthält die vollständigen Vorher-/Nachherwerte und Rohbytehashes. Originaldateien einschließlich mitgelieferter Prüfberichte und Referenzen unverändert erhalten.

Alle 83 Kartenidentitäten, Zieldefinitionen, cards.learning, Satztexte, Übersetzungen, Lücken und Besitz-/Displaybindungen unverändert. Keine alten Glossen bereinigt, keine bestehende Sensezeile verändert. Der Originalprüfer bestand vor der Korrektur; derselbe unveränderte Prüfer bestand anschließend für die Importkopie. Die redaktionellen Fehler waren semantische Befunde, keine umgangenen Validatorfehler.

Wörtlich geprüfte Alternative: **He stayed home with diarrhea and called to cancel his appointment.** accepted bleibt ausschließlich diarrhoea; diarrhea ist nur in diesem Satz valid_alternatives. Keine globale Freigabe oder SRS-/Synonymlogikänderung.

## Linter: 0 Fehler, 14 neue Häufigkeitshinweise

Keine Umformulierung allein wegen niedriger Häufigkeit. Die Wörter sind im jeweiligen Satzkontext sinnvoll.

| Ziel | Hinweis |
|---|---|
| dose | 'pharmacist'/'pharmacist' Zipf 3.34 below 3.5 |
| ointment | 'pharmacist'/'pharmacist' Zipf 3.34 below 3.5 |
| drown | 'lifeguard'/'lifeguard' Zipf 3.07 below 3.5 |
| drown | 'swimmer'/'swimmer' Zipf 3.49 below 3.5 |
| unconscious | 'paramedic'/'paramedic' Zipf 3.19 below 3.5 |
| unconscious | 'knelt'/'knelt' Zipf 2.80 below 3.5 |
| yawn | 'sleepless'/'sleepless' Zipf 3.18 below 3.5 |
| squeeze | 'physiotherapist'/'physiotherapist' Zipf 2.67 below 3.5 |
| paramedic | 'stretcher'/'stretcher' Zipf 3.23 below 3.5 |
| posture | 'physiotherapist'/'physiotherapist' Zipf 2.67 below 3.5 |
| carbohydrate | 'dietitian'/'dietitian' Zipf 2.69 below 3.5 |
| dental | 'checkup'/'checkup' Zipf 2.88 below 3.5 |
| scalp | 'hairdresser'/'hairdresser' Zipf 3.17 below 3.5 |
| scalp | 'itchy'/'itchy' Zipf 3.34 below 3.5 |

## Identitäten, Bestandsschutz und interner Pack

Der Export stimmt exakt mit create_content aus der korrigierten Lieferung überein. Alle alten Listen sind unveränderte Präfixe, einschließlich deck_cards und deck_words. Die 83 neuen Displaypositionen entsprechen der gelieferten Zuordnung 1–83; kein Display-Patch in Batch 1. Originalpositionen in Auswahl und Registry bleiben erhalten. Alle 83 Karten besitzen genau einen aktiven festen Satz; Begleitwörter erzeugen keine zusätzlichen Lernkarten.

Alle Zeilen und Spalten aller 18 SQLite-Tabellen wurden gegen build_rows zurückgelesen; der automatisch erzeugte Release-Zeitstempel ist wie im bestehenden Prüfer ausgenommen. front/NOUN|front#vor_publikum und die beiden korrigierten each-other-Bindungen aus Menschen Batch 3 bleiben unverändert.

Asset und Manifest vor Staging bytegetreu unter `build/koerper_batch_1_checks/backup/assets/content/en/` gesichert. Staging und --verify bestanden; Sechsstapel-Lesetest liest ausschließlich eine temporäre Testinstallation. flutter analyze meldet keine Probleme. Keine echte user.db, review_log oder App-Einstiegsdatei geöffnet/geändert; keine Geräteprüfung durchgeführt.

## Fortsetzung für Batch 2

- Neue separate Dateien `pipeline/data/selection/koerper_gesundheit_batch_2_context_v1.json`, `pipeline/data/words/en.koerper_gesundheit_batch_2_context_v1.json` und `pipeline/data/learning_groups/en.koerper_gesundheit_batch_2_context_v1.json` gegen den tatsächlich gestagten neuen Pack erzeugt.
- Alle 249 Originalidentitäten und Definitionen exakt erhalten; 83 importierte Satzbindungen eingefroren, 83 aktuelle und 83 spätere Ziele. Je Batch weiterhin alle acht Themen.
- Neun ursprünglich vorgeschlagene spätere Senses liegen nun als Begleitwörter vor und werden wiederverwendet; ward/protein nutzen jetzt ebenfalls exakt ihre Reservierung. Keine Definitionsequivalenz-Ausnahme nötig.
- Späterer Folgeimport: nur aktuelle 83 Ziele; Mitgliedschaften auf 84–166 anhängen, dann mit bestehendem hashgebundenem Display-Patch auf gemeinsame Positionen 1–166 ordnen. Die jetzigen Packpositionen bleiben davon unberührt.
- ZIP enthält vollständige Basis-SQLite, Wörterbuch, Registry, Gruppen, Quellen, Schemas, Offline-Tokenizer-Modell und sämtliche Identitäten. 83 Dateien inklusive Manifest, 82 Nutzdateihashes. CRCs, alle Hashes, Referenzen, Partitionen und vollständige 18-Tabellen-SQLite nach Schließen erneut geprüft; nach Verschieben an den endgültigen Pfad nochmals bestanden.

## Tatsächliche Prüfoutputs

`PYTHON` steht unter macOS Terminal für `pipeline/.venv-macos/bin/python`, unter Windows PowerShell für `.\pipeline\.venv\Scripts\python.exe`. Repository-Root als Arbeitsverzeichnis. Dart-/Flutter-Befehle sind auf beiden Systemen identisch.

```text
PYTHON koerper_gesundheit_batch_1/verify_koerper_gesundheit_batch_1.py --repo .
PYTHON build/koerper_batch_1_checks/reviewed_delivery/verify_koerper_gesundheit_batch_1.py --repo .
Observed in this task for BOTH original and corrected delivery verifier, each Exit 0:
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS create_content/build_rows: 1578 cards; 1463 primary goals (160/489/241/245/245/83); 18 tables
PASS 83 reserved identities, display 1..83; 1495 old IDs and all historical rows preserved
PASS 1037 token positions; one reviewed spelling alternative; linter 0 errors, 14 warnings
```

```text
PYTHON pipeline/scripts/import_editorial_patch.py --source pipeline/out/menschen_beziehungen_batch_3_v1/pack.json --create build/koerper_batch_1_checks/reviewed_delivery/koerper_gesundheit_batch_1.editorial.json --registry pipeline/data/words/en.koerper_gesundheit_v1.json --out pipeline/out/koerper_gesundheit_batch_1_v1
{
  "status": "ok",
  "internal_test_pack": true,
  "ai_calls": 0,
  "ai_cost_usd": 0,
  "sqlite_counts": {
    "languages": 1,
    "lemmas": 2679,
    "senses": 4022,
    "cards": 1578,
    "dictionary_forms": 4666,
    "decks": 6,
    "deck_cards": 1578,
    "deck_words": 1474,
    "word_aliases": 23,
    "sentences": 2112,
    "sentence_tokens": 23211,
    "card_sentences": 2106,
    "stories": 1,
    "story_sentences": 6,
    "exercises": 0,
    "grammar_rules": 0,
    "audio_assets": 0,
    "content_releases": 1
  },
  "sha256": "42dc059df3425b80eda702339de079aacd0fbc5c543c52626a547c74c05f7182"
}

Exit 0
PYTHON build/koerper_batch_1_checks/audit_export.py
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2679, 'senses': 4022, 'cards': 1578, 'dictionary_forms': 4666, 'decks': 6, 'deck_cards': 1578, 'deck_words': 1474, 'word_aliases': 23, 'sentences': 2112, 'sentence_tokens': 23211, 'card_sentences': 2106, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PASS 83 original identities, definitions, learning groups, owners and fixed sentences; partition 83/83/83
PASS 1495 historical cards and all old content preserved, including all display positions; front and both each-other corrections retained
ALTERNATIVE He stayed home with diarrhea and called to cancel his appointment.
PASS reviewed reading/annotation documents exactly match all 83 sentences and 1037 imported token positions
DECK allgemeine-sprache 160
DECK reisen 489
DECK alltag-zuhause 241
DECK arbeit-bildung 245
DECK menschen-beziehungen 245
DECK koerper-gesundheit 83
PACK_SHA256 da7a6890241f4ae6db2ca225d7eb8c2a3fe4cbfbdd40ef17a697dce47dd7d9b3
SQLITE_SHA256 42dc059df3425b80eda702339de079aacd0fbc5c543c52626a547c74c05f7182
PASS future identities not introduced; ward/protein exact reserved senses ready for reuse; old reciprocal bindings unchanged

Exit 0
```

```text
PYTHON -m pytest pipeline/tests/test_editorial_import.py pipeline/tests/test_content_contract.py pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
........................................................................ [ 58%]
...................................................   [100%]
123 passed, 19 subtests passed in 1.70s

Exit 0
dart run tool/stage_content_pack.dart --from pipeline/out/koerper_gesundheit_batch_1_v1
Running build hooks...Running build hooks...staged assets/content/en/content.sqlite
  version koerper_gesundheit_batch_1_v1, schema 3, 11255808 bytes
  sha256 42dc059df3425b80eda702339de079aacd0fbc5c543c52626a547c74c05f7182
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
dart run tool/stage_content_pack.dart --verify
Running build hooks...Running build hooks...verified assets/content/en/content.sqlite
  version koerper_gesundheit_batch_1_v1, schema 3, 11255808 bytes
  sha256 42dc059df3425b80eda702339de079aacd0fbc5c543c52626a547c74c05f7182
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release

Exit 0
flutter test test/data/real_pack_test.dart
00:00 +0: loading /Users/ardasayar/Documents/FlutterProjekte/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
deck allgemeine-sprache: 160 learning targets, 160 ownership cards, 160 fixed sentence assignments verified
deck reisen: 489 learning targets, 500 ownership cards, 500 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 241 ownership cards, 241 fixed sentence assignments verified
deck arbeit-bildung: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck menschen-beziehungen: 245 learning targets, 245 ownership cards, 245 fixed sentence assignments verified
deck koerper-gesundheit: 83 learning targets, 83 ownership cards, 83 fixed sentence assignments verified
pack koerper_gesundheit_batch_1_v1 (schema 3, internal: true); 6 decks: 1474 cards, 1578 card sentences, 121 with valid_alternatives, 1578 cards in the pack
00:13 +1: All tests passed!

Exit 0
flutter analyze
Analyzing sprachapp...
No issues found! (ran in 3.0s)

Exit 0
```

```text
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/koerper_gesundheit_v1.json --batch 2 --prepare-continuation koerper_gesundheit_batch_2_context_v1
snapshots: PASS; partition_counts: imported 83, current 83, future 83
Exit 0
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/koerper_gesundheit_batch_2_context_v1.json --batch 2 --out build/koerper_batch_1_checks/staging/koerper_gesundheit_authoring_batch_2.zip
export: PASS; files: 83
Exit 0
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/koerper_batch_1_checks/staging/koerper_gesundheit_authoring_batch_2.zip
zip_verification: PASS; hashed_files: 82; sqlite_tables: 18; sqlite_cards: 1578
Exit 0
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/koerper_gesundheit_authoring_batch_2.zip
zip_verification: PASS; partition 83/83/83
zip_sha256: ccef9bc9f35a534a005a1fcb2edf93e7634bfcd99f1ae2997f1379b0aadbcb25
Exit 0
```

Die ZIP wurde erst nach erfolgreicher erster Readback-Prüfung geschlossen auf den endgültigen Pfad verschoben, ohne vorhandene Lieferung zu überschreiben. Vollständige Outputs und Exitcodes in `build/koerper_batch_1_checks/`.

## Änderungen, Abweichungen und Altbefunde

1922 Ausgangsdateien gehasht; nach Abschluss 1918 byteidentisch, genau vier autorisierte Änderungen: internes Asset und Manifest, konkrete neue Testerwartungen in test/data/real_pack_test.dart sowie NEXTSTEPS.md. Neue Ausgabe, drei Fortsetzungssnapshots, dieser Bericht und build-Prüfdateien zusätzlich angelegt. Historische Packs, Original-Lieferung und ursprüngliche Registrys/Auswahlen/Gruppen unverändert. Keine Pipeline-/App-/SRS-/Plattformänderung, keine Cloud-/Modellaufrufe, Supabase-Aktionen, Veröffentlichung, Commits oder Pushes.

Der erste Staging-Versuch endete mit Exit 1, weil die Sandbox das Schreiben von engine.stamp.tmp und engine.realm im externen Flutter-SDK-Cache verweigerte. Nach zugelassenem erweitertem Cache-Zugriff bestand derselbe Staging-Befehl mit Exit 0; keine Produktdatei als Umgehung geändert. Sonst keine fehlgeschlagenen fachlichen Prüfläufe.

`git diff --check`: Exit 2 wegen bestehender CRLF-/Whitespace-Befunde; vollständiger großer Rohoutput komprimiert gesichert. `git -c core.whitespace=cr-at-eol diff --check`: Exit 2 mit denselben sieben alten Stellen: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127 und docs/arbeit-bildung-batch-2-import.md:121. Eigene Änderungen separat gegen Sicherung beziehungsweise /dev/null ohne Whitespace-Diagnostik geprüft; Wrapper Exit 0. `git status --short`: Exit 0, kompletter Zustand in git-status-after.txt. Keine globale Bereinigung.

## SHA256

- `pipeline/out/menschen_beziehungen_batch_3_v1/pack.json`: `080e7948e77552d3055b7569032f164c2d6c92640287a8622ced5a29a8cc2855`.
- `pipeline/out/menschen_beziehungen_batch_3_v1/content.sqlite`: `9811bf3e0aa71b44d01e66a872b9a0981fd82e990f47571cd1e56ba2cd79a388`.
- `koerper_gesundheit_batch_1/koerper_gesundheit_batch_1.editorial.json`: `2fb06213932d67477fd1bd059947d6876d87f026b77b2786ea0532879e7eef3f`.
- `build/koerper_batch_1_checks/reviewed_delivery/koerper_gesundheit_batch_1.editorial.json`: `0b1ff722fddf3a8503d62e5c20b06bbb03e2597f93678a5b7a3dec8083406a51`.
- `pipeline/out/koerper_gesundheit_batch_1_v1/pack.json`: `da7a6890241f4ae6db2ca225d7eb8c2a3fe4cbfbdd40ef17a697dce47dd7d9b3`.
- `pipeline/out/koerper_gesundheit_batch_1_v1/content.sqlite`: `42dc059df3425b80eda702339de079aacd0fbc5c543c52626a547c74c05f7182`.
- `assets/content/en/content.sqlite`: `42dc059df3425b80eda702339de079aacd0fbc5c543c52626a547c74c05f7182`.
- `assets/content/en/content.manifest.json`: `d2e78cbebe424cb87734ce391e429cc664308153399cdcce9d16b5a90674d771`.
- `pipeline/data/selection/koerper_gesundheit_batch_2_context_v1.json`: `1f23b2deab29d56713d4637bda5b8d7798fa40882ce16df27530a35c3de490c1`.
- `pipeline/data/words/en.koerper_gesundheit_batch_2_context_v1.json`: `a78816c793bd1918623da63158c718df01b6d3434737b4766057b65828d1d214`.
- `pipeline/data/learning_groups/en.koerper_gesundheit_batch_2_context_v1.json`: `fd57ef16507241cccf9cf5d1eb10dea6e4ba3c4b85dac6ba15b2a5e64e1afdc8`.
- `build/koerper_gesundheit_authoring_batch_2.zip`: `ccef9bc9f35a534a005a1fcb2edf93e7634bfcd99f1ae2997f1379b0aadbcb25`.

## Nächster Schritt

Die 83 aktuellen Batch-2-Ziele anhand der geprüften ZIP im Chat redigieren. Noch keine Batch-2-Sätze oder Folgeimporte erzeugt. Geräteprüfung bleibt optional separat auszuführen; automatisierter Lesetest und Analyse sind bestanden. Keine ungeklärten Besitz-/Alias-/Gruppenbindungen.
