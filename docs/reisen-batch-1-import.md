# Reisen Batch 1 – offline exportiert und intern gestagt

Stand: 04.10.2026. Pack `reisen_batch_1_v1`, Schema 2, internes Testpack.
100 Reisen-Karten mit je einem festen Satz erfolgreich importiert. Beide freigegebenen
Ersatzsätze bestehen den unveränderten Projekt-Linter. Kein Cloud-/Modellaufruf,
Kosten 0 USD. Keine Veröffentlichung, Commits, Pushes oder Zugriffe auf Original-user.db.

## Genau zwei Satzänderungen

| Referenz | Englisch | Deutsch |
|---|---|---|
| reisen-v1-030-s1 | We show our passports at immigration. | Wir zeigen unsere Reisepässe bei der Einreisekontrolle vor. |
| reisen-v1-401-s1 | Please ask the driver about the next stop. | Bitte frag den Fahrer nach der nächsten Haltestelle. |

Vorher blockierten „We wait at immigration to have our passports checked.“ und
„Let us ask the driver where to get off.“ mit jeweils zwei gezählten Nebensätzen
(Grenze 1). Die beiden Ersatztexte liefern jeweils keine Linterbefunde.
Tokenisierung mit echter Projektfunktion; stop an `stop/NOUN|stop#haltestelle`
gebunden. Vorhandene passende Senses und Formglossen wiederverwendet, nichts ergänzt.
Review-Texte und Token-/Link-Hashes ausschließlich für diese zwei Ersetzungen erneuert.
Stabile Satz-/Link-IDs aus dem neuen Inhalt durch Importer abgeleitet; Satzrefs erhalten.
accepted jeweils nur Zielform; beide Alternativenlisten leer.

Die anderen 98 Satzpaare, Annotationen, Reviews und alle 15 Alternativen sind gegenüber
`build/reisen_batch_1_checks/sentence_fix_backup/` unverändert. Karten, Ziel-Sense-IDs,
Besitz, Auswahl und Registry-Originalpositionen unverändert. Lesbare Lieferung HTML
und `build/reisen_batch_1_checks/editorial_readback.json` bilden den neuen Stand ab.

Nach Referenzprüfung nur nicht mehr benötigte NEUE Lieferzeilen entfernt:
Senses `have/VERB|have#veranlassen`, `let/VERB|let#aufforderung_let_us` sowie deren
Formglossen have/let und die neue Form get am bestehenden get#stieg-Sense.
Keine Bestandszeile entfernt. Ergebnis: 134 neue Lemmas, 147 neue Senses,
182 neue Formglossen, 1040 Tokens. Manifestrevision 3 bewahrt Quellenbindungen.
Nachweise: `reisen_batch_1/local_corrections.json` und
`build/reisen_batch_1_checks/local_corrections.json`.

Frühere Korrekturen bleiben nachvollziehbar: rain an bestehenden rain#regnet-Sense,
get/off ursprünglich an vorhandene Aussteigen-Senses gebunden, kausative have-Glosse
von haben zu lassen korrigiert. Die letzten drei Stellen entfallen nun mit den alten
Satzfassungen; die rain-Korrektur bleibt. Alte Bestandsglossen Reise-, Flughafen-,
Eisenbahn- und Geschichts- unverändert.

## Positionen und Bestand

Auswahl-/Registry-Positionen bleiben original, nur Reisen-Anzeigen im Pack dicht
1–100: Original 26 wird Anzeige 6. `card_sentences.position` bleibt 1.
Mapping: `build/reisen_batch_1_checks/position_mapping.json`.
Übergabe-Validator prüft zusätzlich Batch 1+2: 200 eindeutige Anzeigen, Original 26
wird Anzeige 11. Keine Batch-2-Sätze erzeugt. Keine Pipeline-/App-Codeänderung.

## Tatsächliche Prüfungen

Windows PowerShell, ausgeführt ab Repository-Root, jeweils Exit 0:

```powershell
.\pipeline\.venv\Scripts\python.exe -X utf8 reisen_batch_1/verify_reisen_batch_1.py --repo .
$env:PYTHONPATH = 'pipeline/src'
.\pipeline\.venv\Scripts\python.exe -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/story_learning_v1/pack.json --create reisen_batch_1/reisen_batch_1.editorial.json --registry pipeline/data/words/en.reisen_500_v1.json --out pipeline/out/reisen_batch_1_v1
```

macOS-Entsprechung, hier nicht ausgeführt; Export nicht erneut in bestehenden Ordner starten:

```sh
pipeline/.venv/bin/python reisen_batch_1/verify_reisen_batch_1.py --repo .
PYTHONPATH=pipeline/src pipeline/.venv/bin/python pipeline/scripts/import_editorial_patch.py --source pipeline/out/story_learning_v1/pack.json --create reisen_batch_1/reisen_batch_1.editorial.json --registry pipeline/data/words/en.reisen_500_v1.json --out pipeline/out/reisen_batch_1_v1
```

Aus tatsächlichem Abschlussoutput (`build/reisen_batch_1_checks/final-validator.txt`):

```text
PASS deterministic display mapping: batch 1=1..100; batches 1+2=1..200; original order retained
PASS supplied schema constraints (strict local adapter; jsonschema package unavailable)
PASS 100 authoritative batch-1 identities, positions and reservations; 1 ownership alias
PASS 100 sentences and gaps; 1040 complete tokens; words/sentence 6–12
PASS sense references, dictionary coverage, immutable existing rows, 100 review hashes
PASS literal alternative substitutions: 15
PASS delivery file hashes
PASS actual project tokenizer and all recomputed stable IDs
PASS actual tokenizer, recomputed IDs, create_content, build_rows: 364 cards / 898 sentence texts / 260 primary words
```

jsonschema ist lokal nicht installiert. Der strenge lokale Adapter prüft alle tatsächlich
verwendeten Schema-Schlüssel und bricht bei unbekannten ab; keine Installation oder
Abschwächung des Produktionsvalidators. Exportbericht: status ok, internal_test_pack true,
ai_calls 0, ai_cost_usd 0. Vollständiger Satzlinter: 892 Satzverknüpfungen, 0 Fehler,
163 Warnbefunde; Warnungen wurden nicht als fehlerfreie Stilprüfung ausgegeben.

SQLite ausschließlich lesend geprüft: integrity_check = ok, foreign_key_check = [].
Vollständiger Abgleich aller 18 Tabellen/Spalten mit build_rows. Einzige gesondert
geprüfte Exportmetadatei-Spalte: content_releases.created_at ist ein gültiger ISO-Zeitstempel
mit Zeitzone (2026-10-04T19:50:17.674775+00:00). Alle alten Inhaltszeilen erhalten;
der Release-Deskriptor beschreibt den neuen Export.
Nachweis: `build/reisen_batch_1_checks/sqlite_verification.json`.

| Größe | Soll | SQLite-Ist |
|---|---:|---:|
| Karten | 364 | 364 |
| Satztexte inklusive Story | 898 | 898 |
| Karten-Satz-Verknüpfungen inklusive Historie | 892 | 892 |
| Primärwörter | 260 | 260 |
| Reisen-Karten / feste aktive Satzzuordnungen | 100 / 100 | 100 / 100 |
| Reisen-Anzeigepositionen | 1–100 | 1–100 |

Eine zunächst gebündelte Shell-Ausführung lief nach einem zu strengen Zeitstempelvergleich
irrtümlich bis zum Staging weiter, bevor die Assetsicherung entstand. Korrigiert:
Readback vollständig abgeschlossen, alten Assetstand aus unveränderter Basis wiederhergestellt,
SQLite UND Manifest gegen ursprüngliche Baseline bytegleich bestätigt, reversibel nach
`build/reisen_batch_1_checks/asset_rollback/` gesichert, anschließend getrennt erneut gestagt.

Beide Systeme, tatsächlich unter Windows jeweils Exit 0:

```text
dart run tool/stage_content_pack.dart --from pipeline/out/reisen_batch_1_v1
dart run tool/stage_content_pack.dart --verify
flutter test test/data/real_pack_test.dart
```

Staging und verify bestätigen Pack/SHA und Tabellenzahlen. Echter Lesetest:

```text
deck allgemeine-sprache: 160 primary cards, 160 fixed sentence assignments verified
deck reisen: 100 primary cards, 100 fixed sentence assignments verified
pack reisen_batch_1_v1 (schema 2, internal: true); 2 decks: 260 cards, 364 card sentences, 48 with valid_alternatives, 364 cards in the pack
00:01 +1: All tests passed!
```

Die 364 Satzzuordnungen im App-Test sind die gelesene aktive Auswahl; SQLite enthält
892 Verknüpfungen einschließlich Historie. Gezielte Testdatei-Analyse zuvor ohne Befund.
Keine vollständige Testsuite, kein Emulator-/iOS-Lauf, keine Lernaktionen.

## Artefakte und SHA256

| Artefakt | SHA256 |
|---|---|
| Neues SQLite, 4.665.344 Bytes | `fd0962fe5b4958338fe46f1101db520f69b5e5c7f101762b1bdade1cef847678` |
| Neues pack.json, Rohbytes | `874b4a95d0a060fc9a77d7dc0dc426018942fa35ad7b2119731fb5281ceb6540` |
| Neues pack.json, kanonisch | `f26c698420824d9028c6654678fbf1816a10a743080dbd7e2271593ea0649223` |
| Unveränderte Basis pack.json, Rohbytes | `3f35432275a8033804f04857240b67999a419a5e6017d47a78d17d968fd95bd1` |
| Ursprüngliche Registry, kanonisch | `888632469bbf306e85bbe42de93082362af24a37be84f6a3c82e2258581d3a90` |
| Gesichertes altes SQLite | `b8231bbc7d1fe834b13ee81b901ad2d96dc06ac3dfbcdf72422718a68bb5e59b` |
| Neue Batch-2-Registry, kanonisch | `e2331264c70e18c2bbb8e92ce8ead4e7d81f14a342da466e7b1c1c990c5a3642` |
| Batch-2-ZIP | `1bdcd19f4220a1d7391f130d5a0b85a48f973412cc3e9aade9484d33a3123b25` |

Originale Lieferung: `build/reisen_batch_1_checks/delivery_original/`.
Vor Positionskorrektur: `build/reisen_batch_1_checks/position_fix_backup/`.
Vor diesen Satzänderungen: `build/reisen_batch_1_checks/sentence_fix_backup/`.
Auswahl, ursprüngliche Registry, Basis-Pack, reference-Dateien und Produktionscode unverändert.

## Nächste Übergabe

`build/reisen_authoring_batch_2.zip`: 13 Dateien; CRC und alle 12 Manifest-Dateihashes
geprüft. Enthält bytegleiches tatsächliches pack.json, geprüfte Registryrevision
`pipeline/data/words/en.reisen_batch_2_v1.json`, exakt 100 Batch-2-Ziele,
alle 500 Originalidentitäten, aktuelle Wörterbuchdaten, Create-Schema, Anzeige-Mapping,
README mit Hashes/Voraussetzungen sowie tatsächliche annotate.py/linter.py.
Registry nach bestehendem Vertrag vom exportierten Snapshot abgeleitet; alle 660 Wortzeilen
identisch, Parent korrekt, source_pack_sha256 an tatsächliche Packbytes gebunden.

Batch 2: 35 bereits vorhandene Senses, 65 vorgeschlagene neue. Sieben inzwischen
vorhandene Begleitwort-Senses wiederverwendet: campsite, tax, castle, ambulance,
reserve, cancel, miss. Kein Batch-2-Satz erzeugt.
Runtime dokumentiert: spaCy 3.8.16, en_core_web_sm 3.8.0, NER deaktiviert;
Linter max_words 14, max_subclauses 1 sowie tatsächliche Namenliste und Zipf-Grenzen.
Modellbinaries nicht mitgeliefert; Nutzung in vorhandener Projektumgebung.

Nächster gebündelter Schritt: Batch 2 auf dieser Übergabe redigieren und seinen Import
mit gezielter, geprüfter Neupositionierung vorhandener Reisen-Anzeigen vorbereiten.
Der aktuelle Create-Importer hängt nur an; er kann bestehende Reisen-Zeilen noch nicht
für die verzahnte 200er-Reihenfolge umordnen. Diese Voraussetzung ist im ZIP-README
explizit vermerkt. Keine doppelten Zeilen oder abgeschwächten Verträge als Ersatz.
