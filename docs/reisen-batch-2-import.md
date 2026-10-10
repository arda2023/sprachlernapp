# Reisen Batch 2 – offline importiert, geprüft und intern gestagt

Stand: 06.10.2026. Pack `reisen_batch_2_v1`, Schema 2, internes Testpack.
100 zusätzliche Satzpaare/Karten; Reisen enthält jetzt 200 von 500 Primärwörtern.
Keine öffentliche Inhaltsfreigabe. Herkunft und Gegenlesen: ChatGPT/Codex,
keine unabhängige menschliche Freigabe, keine Gemini-/Vertex-Prüfung.
Modell-/Cloud-Aufrufe: 0; Kosten: 0 USD.

## Ausgangszustand und Sicherung

Arbeitsbaum zu Beginn: ausschließlich `?? reisen_batch_2/`; kein zusätzlicher
Unterordner. Die vorhandene Lieferung wurde vollständig nach
`build/reisen_batch_2_checks/delivery_original/` kopiert. Baseline der vorhandenen
versionierten Dateien und beiden Assets: `build/reisen_batch_2_checks/baseline.json`.
Quelldateien und alle reference/-Dateien blieben bytegleich. Kein bestehender
out/-Lauf überschrieben; neues Exportverzeichnis war vor dem Import nicht vorhanden.

Basis pack.json Rohbyte-SHA256:
`874b4a95d0a060fc9a77d7dc0dc426018942fa35ad7b2119731fb5281ceb6540`.
Registry `en.reisen_batch_2_v1.json`, kanonisch:
`e2331264c70e18c2bbb8e92ce8ead4e7d81f14a342da466e7b1c1c990c5a3642`.
Beide Bindungen am tatsächlichen Bestand geprüft, nicht angepasst.

## Vollständige redaktionelle Abnahme und zwei konkrete Korrekturen

Alle 100 englischen Sätze, deutschen Übersetzungen, Zielbindungen und 984 Tokenzeilen
gelesen; alle 14 gelieferten Alternativen wörtlich in den Satz eingesetzt.
Die ursprüngliche technische Validierung bestand, erkannte aber diese zwei
inhaltlichen Alternativfehler nicht:

| Satz / Kartenreferenz | Originale Einsetzung | Lokale Korrektur und Grund |
|---|---|---|
| reisen-v1-056-s1; aeroplane\|aeroplane/NOUN\|aeroplane#flugzeug | We watch an plane land at the small airport. | Alternative plane entfernt: an passt nicht vor /p/. airplane bleibt korrekt: We watch an airplane land at the small airport. |
| reisen-v1-135-s1; reception\|reception/NOUN\|reception#rezeption | Please leave your room key at front desk. | Alternative the front desk: Please leave your room key at the front desk. Der zählbare Ausdruck braucht hier einen Artikel. |

Ergebnis: 13 gültige Alternativen. Alle 100 Satzpaare, sämtliche Tokens, Ziel-IDs,
Wörterbuchzeilen und accepted unverändert. Nur zwei Alternativenlisten, ihre
Review-Einsetzungen/Link-Hashes und Begründungen geändert. Token-Hashes unverändert.
Create-Rohbytebindung im Display-Patch neu berechnet; dessen Positionsdaten unverändert.
Leseliste reading.json/HTML, README und Liefermanifest nachvollziehbar aktualisiert.
Originalaudit und validation.txt bleiben historische Liefernachweise; die README
kennzeichnet den lokalen Folgestand. Protokoll: `reisen_batch_2/local_corrections.json`.
Versionierte Create-/Display-Kopien sind bytegleich zur korrigierten Lieferung.
Vollständige Leseliste mit Zielreferenz, Text, Übersetzung, Tokenbindungen und
Alternativsätzen: `build/reisen_batch_2_checks/editorial_readback.json`.

Alle anderen 98 Alternativ-/Review-Datensätze unverändert. Keine Stilrunde:
„in the road“, „at reception“, „to hospital“ und „bank note“ bleiben erhalten;
diese britischen bzw. orthografischen Varianten sind hier keine Fehler.
„doctor“ → „Ärztin“ und „nurse“ → „Pflegekraft“ widersprechen keinem Satzkontext.

Neue Begleitwort-Senses gegen Bestand verglichen, insbesondere alle 16 neuen Senses
mit bereits vorhandenem Lemma. Keine bloßen Flexionsduplikate bestätigt. Beispiele:
registration/Anmeldung ist keine Fahrzeugzulassung; light/schwacher Regen ist kein
leichtes Material; strong/Strömung ist nicht die alte Definition körperlicher Kraft;
thick/Steinmauern unterscheidet sich vom Bestandsbeleg dichter Wolken.
enter/eintragen, board/Bord, right/rechts, come/serviert werden, keep/fernhalten,
from/verhinderte Handlung, walking/nominale Tätigkeit, put/on/Sonnenschutz auftragen,
into/Zielsprache und handle/Flüge abfertigen haben nachvollziehbare Kontextabgrenzungen.
Vorhandene rain#regnet, book#bucht, offer#anbot werden korrekt wiederverwendet.
Alte flektierte/verkürzte Glossen wie Reise-, Flughafen-, Wein-, Englisch-,
show/zeigt oder follow/folgen Sie wurden nicht als neue Lieferzeilen kaschiert oder
im Bestand überschrieben. Keine pauschale sprachliche Freigabe des Altbestands.

## Umsetzung und Schutzbedingungen

Neue reine Funktion `pipeline/src/sprachpipe/deck_display.py`, aus gelieferter
Referenz integriert. Sie kopiert den Pack und ändert nur position in Reisen-
deck_cards/deck_words. Strikte Schlüssel-/Typprüfung, drei Quellbindungen,
Vorzeilenhashes, vollständige Karten-/Wortmengen und 1..n-Endreihenfolge bleiben Pflicht.
Zusätzlich werden Form, Eigentümer, Kartenreferenz und ursprüngliche Position gegen
den tatsächlich hashgeprüften Registry-Snapshot geprüft. Eine bloß umgeschriebene
original_position im Patch reicht damit nicht aus.

`pipeline/scripts/import_editorial_patch.py` unterstützt optional --display-patch
nur zusammen mit --create; andernfalls argparse-Fehler vor jedem Dateizugriff/Schreiben.
CLI berechnet tatsächliche Rohbytehashes von Quelle/Create und kanonischen Registryhash.
Reihenfolge: bestehendes create_content im Speicher (Append 101–200), Display-Patch
im Speicher, build_rows/Linter, sicherer Export. Kein Zwischenpack exportiert.
Standard-Create, Schema, Exporter und bisherige Importpfade unverändert.
95 alte Reisen-Anzeigen pro Mitgliedschaftstabelle wechseln; keine Doppelzeilen.
Originalpositionen in Auswahl/Registry und alle anderen Stapel bleiben erhalten.

Tests: Referenzfälle plus synthetische 200er-Sortierung, gefälschte Originalposition,
falsche Quell-/Create-/Registryhashes, fehlende/zusätzliche/doppelte Karten,
Positionslücken/-typen/Vorzustände, falsche Wörter, unbekannte Felder, Wiederanwendung,
Eingabe-Unveränderlichkeit sowie echte CLI-Anbindung/Export mit kleiner Fixture.
Bestehendes Ausgabeziel wird samt Sentinel erhalten; fehlerhafte neue Importe erzeugen
keinen Ausgabeordner. Alte Importpfade werden durch die bestehende Suite geprüft.

## Tatsächliche Befehle und Outputs

Windows PowerShell, Repository-Root; jeder Prozess mit expliziter Exitcode-Prüfung.
Alle folgenden ausgeführten Befehle Exit 0:

```powershell
.\pipeline\.venv\Scripts\python.exe -X utf8 reisen_batch_2/verify_reisen_batch_2.py
.\pipeline\.venv\Scripts\python.exe -X utf8 reisen_batch_2/test_deck_display_patch.py
$env:PYTHONPATH='pipeline/src'
.\pipeline\.venv\Scripts\python.exe -X utf8 -m pytest pipeline/tests -q
.\pipeline\.venv\Scripts\python.exe -X utf8 reisen_batch_2/verify_reisen_batch_2.py --repo .
.\pipeline\.venv\Scripts\python.exe -X utf8 pipeline/scripts/import_editorial_patch.py --help
.\pipeline\.venv\Scripts\python.exe -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_1_v1/pack.json --create pipeline/data/curation/reisen_batch_2.editorial.json --registry pipeline/data/words/en.reisen_batch_2_v1.json --display-patch pipeline/data/curation/reisen_batch_2_display_v1.json --out pipeline/out/reisen_batch_2_v1
```

Die erste Lieferprüfung lief vor den lokalen Korrekturen (14 Alternativen), die
--repo-Prüfung danach (13). Beide verwenden tatsächlichen Tokenizer/Linter.
Strenger Standardbibliotheks-Schemaadapter der Lieferung, kein jsonschema benötigt.
CLI --help zeigte --display-patch vor dem Import tatsächlich an.

```text
Ran 6 tests in 0.002s
OK
360 passed, 19 subtests passed in 10.74s
PASS 100 sentences, 984 tokens, 5-12 words; 100 review hashes
PASS actual tokenizer and linter: 0 errors, 14 frequency warnings
PASS literal reviewed alternatives: 13
PASS in-memory 200-word display mapping; all other data unchanged
PASS current project create_content, stable IDs, display patch and build_rows: 464 cards / 998 texts / 992 links / 360 primary words
PASS delivery file hashes
```

macOS-Entsprechungen (hier nicht ausgeführt; vorhandenen Export nicht wiederholen):

```sh
pipeline/.venv/bin/python -X utf8 reisen_batch_2/verify_reisen_batch_2.py
pipeline/.venv/bin/python -X utf8 reisen_batch_2/test_deck_display_patch.py
PYTHONPATH=pipeline/src pipeline/.venv/bin/python -X utf8 -m pytest pipeline/tests -q
pipeline/.venv/bin/python -X utf8 reisen_batch_2/verify_reisen_batch_2.py --repo .
PYTHONPATH=pipeline/src pipeline/.venv/bin/python -X utf8 pipeline/scripts/import_editorial_patch.py --help
PYTHONPATH=pipeline/src pipeline/.venv/bin/python -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_1_v1/pack.json --create pipeline/data/curation/reisen_batch_2.editorial.json --registry pipeline/data/words/en.reisen_batch_2_v1.json --display-patch pipeline/data/curation/reisen_batch_2_display_v1.json --out pipeline/out/reisen_batch_2_v1
```

Gesamter Exportlinter: 992 Satzverknüpfungen einschließlich Historie, 0 Fehler,
177 Häufigkeitswarnungen (163 aus Basis + 14 neu). Keine Grammatikfehler daraus abgeleitet.
Exportbericht: status ok, internal_test_pack true, ai_calls 0, ai_cost_usd 0.

## SQLite-Abnahme, Assetbackup und App-Lesetest

Neues SQLite ausschließlich read-only geöffnet. integrity_check ok,
foreign_key_check leer. Alle 18 Tabellen und alle Spalten vollständig gegen build_rows
abgeglichen; exportgeneriertes created_at separat als ISO-Zeitstempel mit Zeitzone
geprüft. Alle alten Zeilen/IDs erhalten, außer freigegebenen Reisen-position-Feldern
und neuem Release-Deskriptor. Wortbesitz, Satztexte, Story und alte Reviewdaten erhalten.
Alle 200 Reisen-Zuordnungen exakt gegen reference/combined_display_mapping.json geprüft,
je eine aktive Satzzuordnung an Position 1.
Nachweis: `build/reisen_batch_2_checks/sqlite_verification.json`.

VOR dem ersten Stage-Aufruf beide tatsächlich vorhandenen Assets kopiert und
SHA256 abgeglichen: `build/reisen_batch_2_checks/asset_backup/` einschließlich hashes.json.
Altes SQLite: fd0962fe5b4958338fe46f1101db520f69b5e5c7f101762b1bdade1cef847678.
Altes Manifest: 4bd7749d63a864cd995e8bebc3be7b6288e378a0a9da965d6424e5e4a2293ebf.
Kein Weiterlaufen nach einem Fehler; Abnahme und Backup gingen Stage voraus.

Beide Systeme identisch, unter Windows ausgeführt, jeweils Exit 0:

```text
dart run tool/stage_content_pack.dart --from pipeline/out/reisen_batch_2_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
flutter analyze
git diff --check
git status --short
```

```text
version reisen_batch_2_v1, schema 2, 5132288 bytes
sha256 e6ea7ee8e77b88e6f6ca3f823d1d947bb9156bd30f7b7ef4fc5f2413a7867281
18 table counts match finalization_report.json
deck allgemeine-sprache: 160 primary cards, 160 fixed sentence assignments verified
deck reisen: 200 primary cards, 200 fixed sentence assignments verified
pack reisen_batch_2_v1 (schema 2, internal: true); 2 decks: 360 cards, 464 card sentences, 61 with valid_alternatives, 464 cards in the pack
00:01 +1: All tests passed!
No issues found! (ran in 26.6s)
```

Die 464 aktiven Satzzuordnungen im App-Test sind nicht die 992 SQLite-Verknüpfungen
inklusive Historie. Testdatei nur Reisen-Sollzahl 100 → 200 geändert; alle bisherigen
Assertions bleiben erhalten. Kein Emulator-/iOS-Test, keine user.db geöffnet,
keine Lernaktionen oder App-Deinstallation. Keine Paketinstallation/Updates.

| Tabelle | SQLite-Ist |
|---|---:|
| languages | 1 |
| lemmas | 1437 |
| senses | 2534 |
| cards | 464 |
| dictionary_forms | 2684 |
| decks | 2 |
| deck_cards | 464 |
| deck_words | 360 |
| word_aliases | 3 |
| sentences | 998 |
| sentence_tokens | 10556 |
| card_sentences | 992 |
| stories | 1 |
| story_sentences | 6 |
| exercises | 0 |
| grammar_rules | 0 |
| audio_assets | 0 |
| content_releases | 1 |

## Neue Authoring-Übergabe

`build/reisen_authoring_batch_3.zip`, 14 Dateien mit CRC-/Manifestprüfung.
Kein versionierter allgemeiner Authoring-Exporter war vorhanden. Das bestehende
Batch-2-Kontextformat wurde wiederverwendet; neuer lokaler Hilfsskriptpfad:
`build/reisen_batch_2_checks/prepare_batch_3.py`. Er verwendet vorhandene
Registry-/Auswahl-/Packvalidatoren und schreibt keinen Satz.

Enthalten: tatsächlicher neuer pack.json, Wörterbuch, geprüfte Registryrevision,
exakt authoring_batch=3 (100 Ziele, nicht IDs 201–300), alle 500 unveränderten
Identitäten, finale Zuordnung für 300 Reisen-Wörter, Create-Schema, unveränderte
annotate.py/linter.py, integrierte deck_display.py, Umgebungsdaten, README und Manifest.
Registryrevision `pipeline/data/words/en.reisen_batch_3_v1.json`: alle 660 Wortzeilen
unverändert; Parent entspricht exportiertem Snapshot, source_pack_sha256 echten Bytes.
Historische source_sqlite_sha256-Metadaten sind im README ausdrücklich gekennzeichnet.
Mit neuer Registry gebundene In-Memory-Packzeilen bleiben identisch.

32 vorhandene / 68 vorgeschlagene neue Zielsenses. Acht ursprünglich vorgeschlagene
inzwischen vorhanden: date, refund, square, harbour, snow, ferry, ship, recommend.
Vorhandene Senses werden wiederverwendet, keine Batch-3-Karten/Sätze erzeugt.
Runtime: spaCy 3.8.16, en_core_web_sm 3.8.0; NER deaktiviert; max_words 14,
max_subclauses 1, tatsächliche Namenliste/Zipf-Grenzen beiliegend. Keine Modellbinaries.
README erläutert Append 201–300 plus separate hashgebundene Neusortierung 1–300.

| Neues Artefakt | SHA256 |
|---|---|
| SQLite | `e6ea7ee8e77b88e6f6ca3f823d1d947bb9156bd30f7b7ef4fc5f2413a7867281` |
| pack.json Rohbytes | `4871da0f7e94c0401de2a4dd1b11d0229a6c610723ad3823acfef29cb1d06d1c` |
| Versioniertes Create | `35200f1002e3b384f7668a31e2915816c4f2bddfbebb037b4d4b5871b1788807` |
| Versionierter Display-Patch | `e901c2869b41af6acbcc6c4d667306a542d261216d371ba1f13469a6c74634ef` |
| Batch-3-ZIP | `1c4cbfb19efe1ddff1bf12ab24d6f6fc1066e567ae21660cd3c5410dd202a28d` |
| Batch-3-Registry kanonisch | `f0b92c6b7952ab7a4f782c9a0ccd81192f41150f1d16dcb3719055c2842666f1` |

Nächster gebündelter Schritt: 100 Satzpaare für authoring_batch=3 anhand der neuen
ZIP redigieren, anschließend Create und 300er-Display-Patch gemeinsam prüfen/importieren.
Keine Cloud-Aufrufe, Remote-Migrationen, Commits, Pushes oder öffentliche Veröffentlichung.
