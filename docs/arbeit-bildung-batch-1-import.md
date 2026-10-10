# Arbeit & Bildung – Batch 1: Import und Batch-2-Kontext

Stand: 07.10.2026. Offline importiert und als internes Test-Pack gestagt: `arbeit_bildung_batch_1_v1`.

## Ergebnis

82 neue Karten mit je einem festen Satz, 82 Satzpaare, 900 Tokenpositionen und sechs geprüfte Alternativen. 1087 Karten insgesamt, 1621 Satztexte, 1615 Verknüpfungen einschließlich Historie und 983 Wortbesitzzeilen. 972 primäre Lernziele: Allgemeine Sprache 160, Reisen 489, Alltag & Zuhause 241, Arbeit & Bildung 82. Der neue Stapel hat Anzeige 1–82; alte Inhaltszeilen einschließlich Anzeigepositionen und alle 1005 alten Karten-IDs sind unverändert erhalten. Keine zukünftigen Karten eingefügt.

- Pack: `pipeline/out/arbeit_bildung_batch_1_v1/pack.json`
- Rohbyte-SHA256: `ebe5fd764d290d671682cff10f55f1b06e35026b5a19b1c3216ab6dadd89b3a2`
- SQLite und gestagtes Asset: `4b7a1899e9c0b9247ba3cddd153aaa56fe1a2470eb7e41c2ade31ea01656e9dd`
- Basis-JSON: `bb092533f44af47f168f1b432226f4999585e8b4ad5f789ca544abe04fe32be0`
- Basis-SQLite: `9fd1a5e546ba32e92bdbb519008414dc34225f76552e79d8271a71af50a1cbe3`

## Redaktion und eine konkrete Korrektur

Alle Satzpaare, Wortbindungen und neuen Bedeutungen gegengelesen. `save` bezeichnet Datenspeicherung, `mouse` das Eingabegerät, `manage` Bewältigung, `graduate` den Studienabschluss. Schaltfläche/Kleiderknopf, Behauptung/Versicherungsantrag, Schreibtafel/Brett sowie Vergütung/bezahlen/Aufmerksamkeit schenken bleiben getrennt. `study` umfasst laut Definition die systematische Beschäftigung mit einem Fach; `have#einnehmen` umfasst auch erleben/durchführen. Historische Glossen wurden nicht bereinigt. CV bleibt Form und Lemma `CV`, Besitzform `cv`. Zielübersetzungen, IDs und cards.learning sind unverändert; accepted enthält nur die Zielform.

Belegter Lieferfehler im weakness-Satz: „in front of large groups“ war an `front#vorderseite` gebunden; dessen Definition nennt den vorderen Teil eines Gegenstands oder Fahrzeugs. Die separate korrigierte Importdatei bindet ausschließlich dieses Token an `front#vor_publikum`, mit passender neuer Bedeutung und Wörterbuchform. Kein neuer Lernkartenkopf. Satztext, Übersetzung, Zielkarte und alle anderen Bindungen bleiben unverändert. Original-Lieferung samt Manifest und Referenzen byteidentisch erhalten. Der bestehende Importer wurde unverändert verwendet.

Korrekturdatei: `pipeline/data/curation/arbeit_bildung_batch_1.corrected.editorial.json`.

```json
{
  "original": "arbeit_bildung_batch_1\\arbeit_bildung_batch_1.editorial.json",
  "original_sha256": "602c4420cde9d32328414ba6a815e5076a871f4ffd5231517617e1d29472810d",
  "corrected": "pipeline\\data\\curation\\arbeit_bildung_batch_1.corrected.editorial.json",
  "corrected_sha256": "6ba458bca4f1731d48936e5389f122bade8a78c2071c0dac8ddb986381d23372",
  "sentence": "arbeit-bildung-v1-084-s1",
  "old_sense": "front/NOUN|front#vorderseite",
  "new_sense": "front/NOUN|front#vor_publikum",
  "old_tokens_sha256": "a921b1111d59c09416f7e14e1f898a72c49683c981fd39eba9f22e33afe3e26b",
  "new_tokens_sha256": "b0f4e053fefeef822be865965edd8b674ca36de8468f6eed6dc6593a86ca457b",
  "reason": "ChatGPT redaktionell geprüft: weakness als NOUN in der vorgegebenen Bedeutung „Ein Bereich, in dem die Fähigkeiten einer Person begrenzt sind.“; Gesamtsatz und deutsche Übersetzung gegengelesen; Wortbindungen kontrolliert. Keine Alternativantwort freigegeben; keine Behauptung der Eindeutigkeit. Lokale Korrektur: front in in front of large groups bezeichnet das Sprechen vor Publikum, keine Vorderseite eines Gegenstands."
}
```

Die sechs Alternativen wurden wörtlich eingesetzt und als passend beurteilt:

- Please send your résumé with a short letter about your experience.
- Please send your resume with a short letter about your experience.
- Please send your curriculum vitae with a short letter about your experience.
- The two teams must collaborate to finish the project on time.
- We have to memorize this poem for the next lesson.
- I need to apologize for sending you the wrong file.

Keine Behauptung sprachlicher Eindeutigkeit; Alternativen bleiben neutral ohne Lernstandsabzug. Linter: null neue Fehler, vier Häufigkeitshinweise bei mittel/Zipf 3.5: unread 2.71 bei inbox, electrician 3.26 bei apprenticeship und qualified, fasten 2.98 bei stapler. Keine Umformulierungen wegen dieser Hinweise.

Bei der lokalen Korrektur wurde zunächst das Pflichtfeld rank vermisst (Importer Exit 2); anschließend beanstandete die zusätzliche JSON-Schemaprüfung rank 0 (Exit 1, Minimum 1). Mit rank 1 sind Schema und vollständige Folgeprüfungen grün. Der nicht gestagte Zwischenexport bleibt unter `build/arbeit_batch_1_checks/rejected_rank_0_export/` erhalten; kein historischer Output wurde überschrieben.

## Fortsetzung

Neue Snapshots `arbeit_bildung_batch_2_context_v1.json` in selection sowie `en.arbeit_bildung_batch_2_context_v1.json` in words und learning_groups. Partition 82 importiert / 82 aktuell / 81 später. Alle 245 ursprünglichen Einträge einschließlich Positionen, Definitionen und IDs sind exakt erhalten; alle 1146 Registry-Wörter bleiben identisch. Elf vorgeschlagene Bedeutungen sind inzwischen durch Begleitwörter vorhanden und werden wiederverwendet. Keine Definitionsäquivalenz-Ausnahme erforderlich. Mitgliedschaften zum Anhängen 83–164; gemeinsamer separater Display-Plan 1–164. Noch keine Batch-2-Sätze verfasst.

ZIP: `build/arbeit_bildung_authoring_batch_2.zip`; SHA256 `201fbaa11ba42262efb64a4b2cfebdc523783c830fcbe13bc6c3f9a59e84f9d4`. 83 Dateien einschließlich Manifest, 82 Nutzdateihashes, CRCs und vollständige SQLite-Zeilen aller 18 Tabellen geprüft. Temporär unter `build/arbeit_batch_1_checks/staging/` geschrieben, geschlossen und erneut geöffnet/geprüft; erst danach auf den endgültigen Pfad verschoben und erneut verifiziert. Kontext ist an den tatsächlich erzeugten Pack und das gestagte Manifest gebunden. Enthalten sind Basis-Pack/SQLite, Wörterbuch, alle Identitäten, ursprüngliche und fortgesetzte Auswahl, Registry/Gruppen, Schema, Quellen und lokale Sprachmodelldateien.

## Prüfungen und tatsächliche Ausgaben

Alle folgenden abgeschlossenen Prüfungen: Exit 0. Die ursprüngliche Lieferprüfung bezieht sich auf die Originaldatei; `audit_corrected.py` wiederholt ihre Identitäts-/Inhalts-/Schema-/Linterprüfungen mit der separaten Korrekturdatei, vergleicht das Export-JSON und alle tatsächlichen SQLite-Zeilen gegen build_rows. Dies ist ein auftragsspezifisches Audit unter build, keine neue generische Testsuite.

Python-Testpfade: `test_editorial_import.py`, `test_word_registry.py`, `test_selection.py`, `test_learning_groups.py`, `test_deck_display.py`, `test_authoring_context.py`, `test_authoring_schema3.py`, `test_authoring_continuation.py`, jeweils unter `pipeline/tests/`.

### verifier.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS create_content/build_rows: 1087 cards; 972 primary goals (160/489/241/82); 18 tables
PASS 82 reserved identities, display 1..82; 1005 old IDs and all historical rows preserved
PASS 900 token positions; six reviewed alternatives; linter 0 errors, 4 warnings
WARNINGS [["inbox", "i+1", "'unread'/'unread' Zipf 2.71 below 3.5"], ["apprenticeship", "i+1", "'electrician'/'electrician' Zipf 3.26 below 3.5"], ["stapler", "i+1", "'fasten'/'fasten' Zipf 2.98 below 3.5"], ["qualified", "i+1", "'electrician'/'electrician' Zipf 3.26 below 3.5"]]
NOT RUN: App staging, Flutter/device tests, user database access
Exit: 0
```

### audit-final.log

```text
PASS source/registry/groups/manifest hashes, Schema 3, context and base SQLite
PASS create_content/build_rows: 1087 cards; 972 primary goals (160/489/241/82); 18 tables
PASS 82 reserved identities, display 1..82; 1005 old IDs and all historical rows preserved
PASS 900 token positions; six reviewed alternatives; linter 0 errors, 4 warnings
WARNINGS [["inbox", "i+1", "'unread'/'unread' Zipf 2.71 below 3.5"], ["apprenticeship", "i+1", "'electrician'/'electrician' Zipf 3.26 below 3.5"], ["stapler", "i+1", "'fasten'/'fasten' Zipf 2.98 below 3.5"], ["qualified", "i+1", "'electrician'/'electrician' Zipf 3.26 below 3.5"]]
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2070, 'senses': 3273, 'cards': 1087, 'dictionary_forms': 3668, 'decks': 4, 'deck_cards': 1087, 'deck_words': 983, 'word_aliases': 13, 'sentences': 1621, 'sentence_tokens': 17272, 'card_sentences': 1615, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
PACK_SHA256 ebe5fd764d290d671682cff10f55f1b06e35026b5a19b1c3216ab6dadd89b3a2
SQLITE_SHA256 4b7a1899e9c0b9247ba3cddd153aaa56fe1a2470eb7e41c2ade31ea01656e9dd
Exit: 0
```

### pytest.log

```text
.......................................................... [ 59%]
.......................................                             [100%]
97 passed, 19 subtests passed in 2.21s
Exit: 0
```

### stage-verify.log

```text
verified assets\content\en\content.sqlite
  version arbeit_bildung_batch_1_v1, schema 3, 8441856 bytes
  sha256 4b7a1899e9c0b9247ba3cddd153aaa56fe1a2470eb7e41c2ade31ea01656e9dd
  18 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Running build hooks...Running build hooks...
Exit: 0
```

### flutter-test.log

```text
00:00 +0: loading C:/Users/ardas/Music/sprachapp/test/data/real_pack_test.dart
00:00 +0: staged pack: all cards and sentence links readable, read-only
deck allgemeine-sprache: 160 learning targets, 160 ownership cards, 160 fixed sentence assignments verified
deck reisen: 489 learning targets, 500 ownership cards, 500 fixed sentence assignments verified
deck alltag-zuhause: 241 learning targets, 241 ownership cards, 241 fixed sentence assignments verified
deck arbeit-bildung: 82 learning targets, 82 ownership cards, 82 fixed sentence assignments verified
pack arbeit_bildung_batch_1_v1 (schema 3, internal: true); 4 decks: 983 cards, 1087 card sentences, 104 with valid_alternatives, 1087 cards in the pack
00:06 +1: All tests passed!
Exit: 0
```

### flutter-analyze.log

```text
Analyzing sprachapp...                                          
No issues found! (ran in 2.3s)
Exit: 0
```

### continuation-audit.log

```text
PASS 245 original entries unchanged, registry reservations unchanged, CV/CV/cv preserved
PASS display append 83..164; combined 1..164; 82 sentence pairs and six literal alternatives reviewed
PACK_SHA256 ebe5fd764d290d671682cff10f55f1b06e35026b5a19b1c3216ab6dadd89b3a2
Exit: 0
```

## Schutzumfang und offene Punkte

Ausgangsstatus und 1300 Dateihashes liegen in `build/arbeit_batch_1_checks/`; Asset/Manifest, alter Lesetest und NEXTSTEPS wurden vor Änderungen gesichert. Geänderte Bestandsdateien: ausschließlich content.sqlite, content.manifest.json, real_pack_test.dart und NEXTSTEPS.md. Neue Dateien: korrigierte Importdatei, neuer Pack, drei Fortsetzungssnapshots, dieser Bericht und Prüf-/ZIP-Artefakte. App-Einstieg, App-Logik, historische Packs/Registrys/Auswahlen und Original-Lieferung bleiben unverändert. Keine echte user.db geöffnet; Lesetest verwendet ein temporäres Testverzeichnis. Keine Cloud-/Modellaufrufe, Veröffentlichung, Commits oder Pushes. Keine Geräteprüfung ausgeführt. Nächster fachlicher Schritt: die 82 Batch-2-Ziele anhand der ZIP redigieren. Keine offenen Import- oder ZIP-Vertragsfehler.

Abschließender Rohbytevergleich: 1296 von 1300 Ausgangsdateien byteidentisch; exakt die vier oben genannten autorisierten Bestandsdateien verändert. `preservation.json` dokumentiert das Ergebnis.
