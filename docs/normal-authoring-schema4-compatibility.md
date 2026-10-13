# Normaler Authoring-/Importweg auf Schema 4

Stand: 11.10.2026. Technisches Inkrement; noch keine redaktionelle Alltagssprache-Auswahl. Die folgende Dateiliste und Gegenprüfung wurden vor Implementierungsänderungen festgehalten.

## Ursachen und freigegebener Plan

Zwei reproduzierte Blockaden: `authoring: schema 3 required` in `validate_context` und `create source schema incompatible with format` im normalen V2-Create. Zusätzlich: normaler Gesamtkatalog höchstens 300 Ziele, Fortsetzung und ZIP-Vertrag/README/Verifier fest Schema 3.

Genau betroffene Implementierungsdateien und Schnittstellen:

- `pipeline/src/sprachpipe/authoring_context.py`: `validate_context(pack, selection, registry, groups, *, source_bytes)` unterstützt normal Schema 3/4 und 1..450 Ziele; `prepare_continuation(...)` bindet die tatsächliche Content-Schemaversion. Die Prüfung von höchstens 100 Zielen je gemischtem Batch bleibt unverändert.
- `pipeline/scripts/import_editorial_patch.py`: `create_content(source, entry, registry, *, source_hash)` akzeptiert normale V2-Lieferungen auf Schema 2/3/4, erhält Schema 4 und die vier Formtabellen aus der Quellkopie. Der V3-Formweg bleibt unverändert.
- `pipeline/scripts/export_authoring_context.py`: normaler `export(...)` und `verify_zip(..., historical=False)` verwenden die tatsächliche Content-Schemaversion für Kontext, README und Prüfung. Normales Kontextformat 2 und V2-Lieferformat bleiben bestehen; Form-Kontextformat 3 bleibt unverändert.
- `pipeline/data/curation/editorial_content_v2.schema.json`: nur die Beschreibung der Lernmetadatenpflicht auf Quell-Schema 3/4 präzisieren. Keine Änderung von Formatversion, Feldern oder V3-Schema.
- Neue Regressionen: `pipeline/tests/test_normal_schema4_authoring.py`. Bestehende Tests werden nur bei konkret nötiger Anpassung geändert.

Aufrufstellen geprüft: `selection.partition_selection` nutzt bereits `build_rows` und benötigt keine Änderung; `validate_display_plan` nutzt den vorhandenen reinen Display-Patch; normaler Export/Verifier rufen denselben `validate_context` auf. Die Form-Exporter-/Continuation-Funktionen und `form_targets` bleiben getrennt und unverändert.

Gegenprüfung: Eine Schema-4-Quelle darf nicht als Schema 3 ausgegeben werden. V2 transportiert weiterhin ausschließlich normale neue Deltas; bestehende Schema-4-Form-/Lexikalzeilen bleiben vollständig erhalten. Keine Verben-Neuzuordnung, keine neuen Formidentitäten, kein SRS-Merge. Die 450-Grenze gilt nur für den normalen Authoring-Gesamtkatalog; keine Budget-, Generierungs-, Cloud- oder Einzelbatchgrenze wird geändert. Unbekannte Schemata, manipulierte Hashes, fehlende Referenzen, Besitzerkonflikte und falsche Teilimportpartitionen bleiben Fehler.

Tests verwenden ausschließlich synthetische Daten in temporären Verzeichnissen: nichtleere Schema-4-Formbasis, normale V2-Deltas mit SQLite-Readback, 300/301/450/451 Ziele, 450er-ZIP mit fünf 90er-Batches, Teilimport/Fortsetzung und negative Bindungsfälle. Der reale Pack und historische ZIPs werden ausschließlich lesend geprüft. Kein Produktionsimport, Staging oder echte Auswahl in diesem Inkrement.

## Endgültige Implementierung und Vertragsentscheidung

Die vorab genannten vier Implementierungs-/Vertragsdateien wurden genau in diesem Umfang geändert. Keine weitere Auswahlfunktion, Appdatei oder V3-Schemadatei musste geändert werden. `validate_context` akzeptiert Schema 3/4 und 1..450 Ziele, prüft eine vorhandene deklarierte Quell-Schemaversion gegen die tatsächliche Basis und erhält die Einzelbatchgrenze 100. `prepare_continuation` übernimmt die reale Content-Schemaversion. Normale V2-Deltas erhalten auf einer Schema-4-Basis Schema 4; die zusätzlichen Quelltabellen werden durch die vorhandene tiefe Kopie und den unveränderten Builder/Exporter transportiert. Es werden keine neuen Formtabellen oder Formidentitäten für normale Ziele angelegt.

Der normale ZIP-Kontext bleibt Format 2, die Redaktion bleibt Lieferformat V2, während die Contentbasis 3 oder 4 sein kann. Der normale Verifier prüft Lieferformat und tatsächliche Content-Schemaversion getrennt; eine manipulierte Schema-3-Angabe für Schema-4-Inhalte wird auch nach Neuhashung des ZIP-Manifests abgewiesen. Form-Kontextformat 3 und V3-Create bleiben unverändert. Schema-2/3-V2-Importe bleiben unterstützt; normale Authoring-Kontexte wie zuvor ab Schema 3. Schema 5 bleibt klar abgelehnt.

Die neue Testdatei umfasst 14 Regressionen. Sie baut eine nichtleere unabhängige synthetische Formbasis über den bestehenden V3-Weg auf: neun Formkarten mit Lexikalzuordnungen, drei Funktionen, mehrfacher Ansicht und Wiederverwendung von cut. Der normale V2-Deltaimport ergänzt zwei ordinary-Karten. Alle alten JSON-Zeilen und sämtliche alten SQL-Zeilenwerte/IDs werden verglichen, die vier nichtleeren Formtabellen bleiben exakt gleich. SQLite-Export und vollständiger 22-Tabellen-Readback werden tatsächlich ausgeführt.

Die 300/301/450-Grenzfälle laufen über vollständige gültige Metadatenkataloge. 451 Ziele und 102 Ziele in einem Einzelbatch werden abgewiesen. Der 450er-Kontext wird tatsächlich geschlossen, erneut geöffnet und verifiziert (0 importiert / 90 aktuell / 360 später, fünf 90er-Batches). Quelle, Register und sämtliche geplanten Gruppen bleiben enthalten; keine echten redaktionellen Ziele. Ein zweiter Fall führt normalen Teilimport, neue Sourcebindung, tatsächliche normale CLI-Fortsetzung und Folge-ZIP-Verifikation aus (2 importiert / 2 aktuell / 2 später). Veraltete Sourcebytes, duplizierte Ziele, fehlende Gruppenreferenzen, Besitzerkonflikte, falsche Quell-Schemaangaben und unbekannte Schemata scheitern weiterhin.

## Tatsächliche Prüfungen, Ausgaben und Exitcodes

Ausführung auf macOS. Unter Windows PowerShell den vorhandenen `pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python` einsetzen; Dart-/Git-Befehle sind plattformgleich. Logs und Vorheraufnahme: `build/normal_authoring_schema4_checks/`. Keine Paketupdates und keine Flutter-Komplettsuite oder Geräteprüfung, da keine Dart-/Appänderung.

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_normal_schema4_authoring.py -q
.............                                                            [100%]
13 passed in 5.35s
Exit 0
```

Dieser erste Lauf prüfte 13 Fälle. Anschließend wurde der zusätzlich erforderliche reale CLI-/ZIP-Fortsetzungsfall ergänzt; der endgültige Testumfang enthält 14 Fälle in der neuen Datei.

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_normal_schema4_authoring.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_editorial_import.py pipeline/tests/test_form_authoring_details.py -q
........................................................................ [ 98%]
.                                                                        [100%]
73 passed in 8.16s
Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
447 passed, 19 subtests passed in 24.26s
Exit 0

dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version irregular_verbs_batch_4_v1, schema 4, 16863232 bytes
  sha256 e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3
  22 table counts match finalization_report.json
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/natur_umwelt_authoring_batch_1.zip --historical
zip_verification: PASS
hashed_files: 80; sqlite_tables: 18; sqlite_cards: 1994; selected: 242
zip_sha256: 3ba7db8d373b402aca01437b3a301c8b19b39a57d0bee5a06013b69afec949a6
Exit 0
```

Der vorhandene reale historische Normal-ZIP-Verifier prüfte CRCs, Archiv-Dateihashes, Kontext, Referenzen und alle Zeilen der 18 historischen Quelltabellen mit aktuellen Validatoren. `--historical` ist erforderlich, weil historische Quelle/Skripte bewusst nicht dem heutigen Produktionsstand entsprechen; archivierter Code wurde nicht ausgeführt. Aktuelle Schema-3-Normaltests und Schema-4-V3-Formtests sind im Gesamt-/gezielten Lauf grün.

Der tatsächliche aktuelle Pack wurde ausschließlich read-only mit `build_rows` und `finalize_curation.check_sqlite` vollständig über alle 22 Tabellen abgeglichen: 2567 Karten, 402 Formziele, bestehende Verbenansichten je 134. Gegen Vorheraufnahme alle Produktionshashes unverändert:

| Datei | SHA256 vorher/nachher |
|---|---|
| aktuelles Pack-JSON | `bf13af162d0cd12122665f9f8dc2edfd57daaf38c9e2a6ee58125452c3a267dc` |
| Quell-SQLite und Asset | `e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3` |
| Asset-Manifest | `88e460403aeb0733cec65bf7fe74d1e5d5d7062b6d1e27fb0f5db2923f70a9c5` |

Read-only-Audit und Hashes: `build/normal_authoring_schema4_checks/real-pack.json`, Exit 0. Ein erster Audit-Aufruf mit System-`python3` fand dort kein `yaml` (Exit 1); anschließend wurde die vorhandene Pipeline-venv verwendet, ohne Installation. Alle endgültigen Prüfungen sind oben erfolgreich ausgewiesen.

## Bestandsschutz, eigene Änderungen und Commitgrenze

Eigene Implementierungsänderungen: `pipeline/src/sprachpipe/authoring_context.py`, `pipeline/scripts/export_authoring_context.py`, `pipeline/scripts/import_editorial_patch.py`, Beschreibung in `pipeline/data/curation/editorial_content_v2.schema.json`. Neue Datei: `pipeline/tests/test_normal_schema4_authoring.py`; Dokumentation: dieser Bericht, Ergänzung in `docs/alltagssprache-redewendungen-authoring.md` und `NEXTSTEPS.md`. Keine alten Fixtures/Tests, V3-Schemata oder sonstigen Sicherheitslimits geändert.

Kein Commit, weil der getestete Änderungsumfang nicht sicher als eigenständiger Indexstand von den Vorarbeiten trennbar ist. Die drei Implementierungsdateien enthalten bereits vor diesem Auftrag uncommittete Änderungen. Insbesondere enthält HEAD noch keinen V3-Zweig in `create_content`, der aktuelle eigene Schema-4-Hunk setzt genau auf diesem uncommitteten Zweig auf. Auch `pipeline/tests/form_fixture.py`, die benötigte bestehende Formfixture, ist noch untracked. NEXTSTEPS enthält ebenfalls den bisherigen uncommitteten Arbeitsstand. Ein vollständiges Datei-Staging würde diese Vorarbeiten mit aufnehmen.

Die rein prüfende Hunk-Anwendung bestätigt die konkrete Grenze, ohne den Index zu verändern:

```text
git apply -p0 --cached --check build/normal_authoring_schema4_checks/import_editorial_patch.py.own.patch
error: patch failed: pipeline/scripts/import_editorial_patch.py:537
error: pipeline/scripts/import_editorial_patch.py: patch does not apply
Exit 1

git diff --cached --name-only
(keine Ausgabe)
Exit 0
```

Eigene Vorher-/Nachher-Patches und Ausgangskopien liegen im Prüfverzeichnis. Kein Sammelcommit, kein git add -A, kein Push. Die technische Abnahme gilt dem getesteten vorhandenen Arbeitsbaum; fremde Vorarbeiten bleiben erhalten.

Eigene Whitespaceprüfung: `git -c core.whitespace=cr-at-eol diff --check --` mit der oben genannten genauen Implementierungs-/Schema-/Test-/Dokumentliste, keine Ausgabe, Exit 0; neue unversionierte Dateien zusätzlich direkt prüfen. Bekannte globale CRLF-/Whitespace-Altbefunde bleiben unangetastet; keine pauschale Bereinigung.

## Ergebnis und nächster Schritt

Die zwei dokumentierten technischen Blockaden sind behoben; normaler Schema-4-V2-Import, Export und Teilfortsetzung sowie bis zu 450 Ziele mit begrenzten Einzelbatches sind tatsächlich geprüft. Es ist ausschließlich technische Kompatibilität freigegeben. Keine echte Alltagssprache-Auswahl, Reservierung, neue Produktionssätze, finale Authoring-ZIP, Produktionsimporte oder Staging durchgeführt. Quellen, Assets, user.db, Lernstände, historische Lieferungen/Auswahlen/Registrys, App-/SRS-/Synonymlogik und Remote-Datenbanken bleiben unverändert.

Nächste Aktion: den bereits genehmigten Auswahlauftrag für Alltagssprache & Redewendungen fortsetzen, mit dem dokumentierten Mix und den acht Themen, vollständiger Dublettenprüfung und einer anschließend tatsächlich geprüften ersten ZIP.

## Abschließender Audit

```text
git -c core.whitespace=cr-at-eol diff --check -- pipeline/src/sprachpipe/authoring_context.py pipeline/scripts/import_editorial_patch.py pipeline/scripts/export_authoring_context.py pipeline/data/curation/editorial_content_v2.schema.json pipeline/tests/test_normal_schema4_authoring.py docs/normal-authoring-schema4-compatibility.md docs/alltagssprache-redewendungen-authoring.md NEXTSTEPS.md
(keine Ausgabe)
Exit 0

pipeline/.venv-macos/bin/python -
(Read-only-Hash-/Index-/Whitespaceaudit gegen Vorheraufnahme)
baseline_files: 2651
changed_preexisting: nur die vier genannten Implementierungs-/Schema-Dateien und zwei aktualisierten Dokumente
own_new_files: test_normal_schema4_authoring.py, normal-authoring-schema4-compatibility.md
production_assets_and_historical_files: unchanged
whitespace: PASS; nextsteps_lines: 24; index: empty
real_selection_or_final_zip: none
Exit 0
```

Vollständiges Ergebnis: `build/normal_authoring_schema4_checks/final-check.json`. Alle sonstigen vorbestehenden Dateien, insbesondere Produktions-/Asset-/Manifestdateien, historische Packs, ZIPs, Auswahlen/Registrys und App-/Dartdateien, sind hashgleich. Der Index bleibt unverändert leer; ausschließlich der dokumentierte eigene Arbeitsbaumumfang ist uncommittet.


## Additive Vertragsergänzung 13.10.2026: Business-Pakete A+B

Die historischen 300-/450er-Befunde oben bleiben historische Prüfergebnisse. Der normale Gesamtkatalog unterstützt jetzt **1..1500 Ziele**; `validate_context` ändert ausschließlich Grenze und Fehlermeldung. Gemischte Batches bleiben bei höchstens 100. Quellen-/Schema-/ID-/Besitz-/Alias-/Bedeutungs-/Gruppen-/Alternativ-/Fortsetzungsprüfungen unverändert; kein Force-, V3- oder Importer-Sonderweg.

Bestehende Tests erweitert: 450 erhalten, 451/1500 gültig, 1501 ungültig; gemischte Batchgröße 100 gültig/101 ungültig. Ungerade Kataloge werden ausgewogen verteilt. Auf nichtleerer Formbasis: 1500er-ZIP geschlossen/erneut geprüft, 22 Tabellen und Partition 0/100/1400; kleiner tatsächlicher V2-Fixtureimport mit großem Zukunftskatalog und normaler CLI-Fortsetzung 2/100/1398. Alte JSON-/SQL-Werte und vier Formtabellen exakt erhalten. Kleine 6er-Fortsetzung weiterhin geprüft.

Technisches Gate: vier beauftragte Module, **77 passed in 5.36s, Exit 0**. Synthetische ZIP 1500: 909162 komprimierte /9216847 unkomprimierte Bytes, 0.359s innerhalb des Tests; 450: 374083/2872635 Bytes, 0.230s. Diese Fixtures enthalten kleine Modellplatzhalter, keine realistische Prognose der produktiven Modellgröße. Bestehende Negativparametrisierung zusätzlich für aktive und retirierte bestätigte Alternativen erweitert: final **8 passed, 14 deselected in 1.78s, Exit 0**. Zwei anfängliche Fehler betrafen ausschließlich die neue historische Fixture (fehlender aktiver Satz; doppelte textbasierte Satz-ID), keine Produktionsänderung erforderlich.

Nach vollständiger Auswahl 28 Auswahl-/Registry-/Gruppentests bestanden. Aktuelle Übergabe: 579 vorbereitete Ziele, davon 43 E-Mail, Batches 97/97/97/96/96/96. Ausschließlich die korrigierte Batch-1-Version `build/business_email_authoring_batch_1_v2.zip` verwenden; die erste unveröffentlichte v1 bleibt als Zwischenbeleg erhalten. [Vollständige Auswahl, Versionskorrektur und tatsächliche Befehle](business-email-authoring.md). Keine Produktionsimporte oder öffentliche Sprachfreigabe.
