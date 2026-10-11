# Alltagssprache & Redewendungen – Spezifikation und Vertragsprüfung

Stand: 11.10.2026. **442 neue normale Lernziele ausgewählt und vollständig als Metadaten geprüft; Batch-1-Authoring-ZIP geschlossen und erneut verifiziert.** Mix: 124 Einzelwörter, 211 Gesprächsformeln, 107 Redewendungen. Batches 89/89/88/88/88; Partition 0 importiert / 89 aktuell / 353 später. Keine neuen Übungssätze, keine Import-/Stagingänderung. Die folgende frühere Spezifikation und die historischen technischen Befunde bleiben nachvollziehbar; der finale Auswahl-/Prüfnachweis steht unten.

## Genehmigte Auswahlspezifikation

Nützlicher Mix aus allgemeinsprachlichen Einzelwörtern, festen Gesprächsausdrücken und gebräuchlichen Redewendungen. Keine starre Typquote; weder reine Einzelwortliste noch fast ausschließlich Idiome. Richtwert etwa 450 eigenständige Lernbedeutungen nach vollständigem Bestands-/Dublettenabgleich, keine Auffüllpflicht.

Acht Themen:

1. Gesprächseinstieg und Smalltalk.
2. Bitten und Höflichkeit.
3. Meinung und Zustimmung/Widerspruch.
4. Gefühle und Reaktionen.
5. Absichten und Entscheidungen.
6. Probleme und Lösungen.
7. Zwischenmenschlicher Umgang.
8. Erzählen und Gesprächsverknüpfung.

Jedes spätere Ziel benötigt eindeutige englische Oberfläche, POS nach bestehendem Vertrag, deutsche Glosse, genaue Bedeutungsdefinition und Thema. Vorschläge sind vor Satzredaktion noch nicht satzvalidiert. Register-/Regionhinweise im bestehenden Vertrag oder Bericht dokumentieren; keine unbelegten Häufigkeitszahlen.

Abgleich gegen alle elf bestehenden Stapel, sämtliche Verbenformen, normalisierte Formen, Besitzer, Aliase, Lern-/Sense-Gruppen, Lexikalanker und feste Kontexte. Ein geeigneter Wörterbuchsense ohne Lernkarte kann wiederverwendet werden. Bestehende abgedeckte Bedeutungen und bestätigte gleichbedeutende Varianten erhalten keine konkurrierende neue Lernkarte. Gleiche deutsche Übersetzung ist kein Synonymiebeweis. Keine Besitzer-/ID-/Lernstandsverschiebung.

Mehrwortziele als vollständige zusammenhängende Oberflächen mit natürlicher Lücke behandeln. Ihre Einzelwörter können schon vorhanden sein; nur der vollständige Ausdruck erhält Besitz, keine Reservierungen seiner Einzelbestandteile. Getrennte Konstruktionen, variable Pronomenstellen und stark variable Ausdrücke zurückstellen. Verb-plus-Partikel überwiegend dem späteren Verbalphrasenstapel, Business-/E-Mail-Spezialwortschatz dem letzten Stapel überlassen. Kein weiterer Grammatik-/Formstapel.

Wenn der Werkzeugvertrag unterstützt ist: möglichst fünf ausgewogene Batches mit 80–100 neuen Satzaufträgen, bei 450 Zielen 90/90/90/90/90; Themen und ähnliche Bedeutungen verteilen. Bei kleinerer belastbarer Auswahl Batchzahl/-größe anpassen. Original-/Besitzpositionen und lückenlose Anzeigepositionen bleiben getrennt. Keine Sätze in diesem Auftrag erzeugen.

## Historische Gegenprüfung vor Auswahländerungen

Die inhaltliche Spezifikation passt zur bestehenden Roadmap und den Besitz-/Mehrwortregeln. Der technische Übergang vom normalen Schema-3-Authoring zur aktuellen Schema-4-Basis ist dagegen noch nicht umgesetzt:

- `pipeline/src/sprachpipe/authoring_context.py`, `validate_context`: verlangt ausschließlich Schema 3, Fehlermeldung `authoring: schema 3 required`.
- Derselbe Validator begrenzt den gesamten Auswahlkatalog auf 300 Ziele (`0 < len(entries) <= 300`), obwohl einzelne Batches bereits auf höchstens 100 beschränkt sind.
- `pipeline/scripts/export_authoring_context.py`: normaler Kontext/README/Importvertrag geben Schema 3 und V2 aus; nur der besondere Form-Auswahlweg transportiert Schema 4.
- `pipeline/scripts/import_editorial_patch.py`, `create_content`: V2 akzeptiert Basis-Schema 2/3; V3 verlangt die besondere Formauswahl mit exakt deren Metadatendeltas. Ein normaler Themenstapel auf Schema 4 hat keinen passenden aktuellen Weg.
- Normale Fortsetzung bindet ebenfalls fest `schema_version: 3` in `authoring_context.prepare_continuation`.

Den Verben-Formauswahlweg für diesen Themenstapel zu kopieren oder die aktuelle Basis auf Schema 3 umzuschreiben wäre eine Vertragsumgehung. Die geplanten Ablagen bleiben reservierte Dateinamen im Auftrag; keine leeren/irreführenden Auswahl-, Registry- oder Gruppensnapshots wurden erzeugt.

## Ursprünglicher kleinster Änderungsplan

1. Bestehenden normalen `validate_context` und `prepare_continuation` additiv für Schema 4 öffnen. Alle vorhandenen Form-/Lexikalzeilen, Karten-/Gruppenentscheidungen und Wortbesitzer unverändert transportieren; keine neue Formauswahl für den Themenstapel.
2. Gesamtkataloggrenze für die genehmigte Auswahl von ungefähr 450 Zielen ausdrücklich anpassen; die vorhandene Grenze von höchstens 100 Zielen je gemischtem Batch erhalten. Nicht mehrere unabhängige Auswahlen als Umgehung erzeugen.
3. Als kleinste Lösung den vorhandenen normalen V2-Create-Weg additiv für eine Schema-4-Quelle öffnen und alle bestehenden Formtabellen unverändert erhalten. Keine neue V3-Formauswahlstruktur für den Themenstapel. Das ist eine tatsächliche Importvertragsentscheidung; keine stille Umstellung in diesem Auswahlauftrag.
4. Normalen Exporter/Verifier und Kontext-/README-Schemaangaben aus der tatsächlichen Quelle ableiten; vollständigen 22-Tabellen-Abgleich beibehalten. Keine App-/SRS-/Antwortänderung und kein Schema-Downgrade.
5. Gezielt einen normalen Themenstapel auf einer Schema-4-Basis mit vorhandenen Formtabellen und >300 Metadatenzielen testen: Erstexport, vollständiger Kontext, kleine Satzimport-Fixture und Fortsetzung. Bestehende Schema-3-Regressionen erhalten. Danach die genehmigte Auswahl durchführen und erst nach erfolgreicher Prüfung die ZIP liefern.

Dieser Plan wurde im separaten technischen Inkrement additiv implementiert und geprüft; die folgenden früheren Fehlermeldungen bleiben historische Nachweise. Keine fremde/stale Basis, Formzielstruktur, Schema-Downgrade oder ungeprüfte finale ZIP.

## Historischer Ausgangsstand und Blocker-Prüfnachweise

Basis `irregular_verbs_batch_4_v1`, Schema 4, elf Stapel; drei Formansichten mit je 134 Übungen. Der bestätigte Abschlussbestand hat 2453 Übungen / 2182 lexikalische Wörter. Die normale Authoring-Gegenprüfung wurde vor Auswahländerungen ausgeführt.

| Datei | SHA256 vorher und nachher |
|---|---|
| `pipeline/out/irregular_verbs_batch_4_v1/pack.json` | `bf13af162d0cd12122665f9f8dc2edfd57daaf38c9e2a6ee58125452c3a267dc` |
| Quell-SQLite und aktuelles Asset | `e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3` |
| Asset-Manifest | `88e460403aeb0733cec65bf7fe74d1e5d5d7062b6d1e27fb0f5db2923f70a9c5` |

Die Basis wurde nicht verändert. Diagnosehilfen verwenden nur In-Memory-Daten und lesen den tatsächlichen Pack; weder Importausgabe noch Ersatzbasis erzeugt.

Befehle auf macOS; unter Windows PowerShell `pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python` verwenden. Dart/Git-Befehle sind plattformgleich. Logs/Bestandsaufnahme: `build/alltagssprache_redewendungen_checks/`. Keine Paketinstallation.

```text
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version irregular_verbs_batch_4_v1, schema 4, 16863232 bytes
  sha256 e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3
  22 table counts match finalization_report.json
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help
CLI unterstützt --selection, --batch, --out und --verify-zip; keine separate normale Schema-4-Option.
Exit 0

pipeline/.venv-macos/bin/python /tmp/probe_everyday_authoring.py authoring
Konkrete Eingabe: tatsächlicher Schema-4-Pack, validate_context als vorgesehener normaler Metadatenprüfer.
ValueError: authoring: schema 3 required
Exit 1

pipeline/.venv-macos/bin/python /tmp/probe_everyday_authoring.py importer
Konkrete Eingabe: bestehende V2-Testlieferung, Quell-/Registryhash an tatsächliche Basis gebunden,
keine Satzgenerierung oder Exportausgabe; Prüfung scheitert vor Anwendung der Inhalte.
sprachpipe.curate.CurationError: create source schema incompatible with format
Exit 1

pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_word_registry.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_selection.py pipeline/tests/test_learning_groups.py -q
........................................................                 [100%]
56 passed in 2.25s
Exit 0
```

Die erfolgreichen bestehenden Tests beweisen keine Unterstützung des neuen Vertragsfalls; die zwei gezielten Negativdiagnosen belegen den konkreten Blocker. Kein wiederholter gleicher Lösungsversuch, keine Schutzprüfung deaktiviert. Kein Export-/ZIP-Verifikationslauf für den geplanten Stapel behauptet: Die erforderliche Auswahl ist wegen des vorherigen Vertragskonflikts noch nicht angelegt.

## Historischer Umfang, Ablagen und Commitstatus vor der Auswahl

Ausgewählte Lernziele: **0**; Typ-/Themenzahlen und Wiederverwendung/neue Bedeutungen daher noch nicht ermittelt. Keine inhaltliche Dublettenprüfung mit einer erfundenen Kandidatenliste behauptet. Die acht Themen und der gewünschte Mix sind spezifiziert, die aktuelle Werkzeugfähigkeit ist gegengeprüft. Keine Mengenfüllung oder falsche sichere Kollisionsbehauptung.

Geplante Original-/Kontext-/Registry-/Gruppenpfade aus dem Auftrag bleiben die vorgesehenen Ablagen, sofern die additive Unterstützung diesen normalen Vertrag beibehält. Sie wurden nicht als leere Scheindateien erzeugt. Batches: noch nicht eingefroren; geplant fünf ausgewogene Gruppen bei entsprechendem tatsächlichem Umfang. Keine gültige Partition ohne Auswahl behauptet.

Noch keine geprüfte ZIP unter `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/alltagssprache_redewendungen_authoring_batch_1.zip`. Diese Datei wurde nicht erzeugt und darf noch nicht zur Satzredaktion hochgeladen werden.

Kein Commit: Das gewünschte Auswahl-/ZIP-Inkrement ist nicht abnahmefähig. Zusätzlich enthält `NEXTSTEPS.md` bereits vor diesem Auftrag uncommittete Änderungen gegenüber HEAD (HEAD dokumentiert noch Arbeit & Bildung Batch 2). Ein vollständiges Staging dieser Datei würde fremden/vorbestehenden Umfang einschließen. Der vorhandene Index ist leer geblieben. Eigener uncommitteter Umfang: dieser neue Spezifikations-/Blockerbericht und die Aktualisierung von NEXTSTEPS. Kein Sammelcommit, kein Push.

Bekannte repositoryweite CRLF-/Whitespace-Altbefunde bleiben unangetastet. Eigene Dokumentpfade werden gezielt und neue Dateien zusätzlich direkt geprüft; keine Flutter-Komplettsuite ohne Appänderung. Produktionspack, Asset/Manifest, user.db, Lernstände, alte Auswahlen/Registrys/Gruppen, historische Lieferungen und App-/Pipelinecode bleiben erhalten.

## Historische Bestandsschutzprüfung vor der Auswahl

```text
pipeline/.venv-macos/bin/python -
(Read-only-Audit mit build_rows und finalize_curation.check_sqlite; SHA256-/Index-/Whitespaceabgleich)
source_full_rows: PASS; sqlite_tables: 22; source_cards: 2567; form_targets: 402
preexisting_files_checked: 2634; changed_preexisting: [NEXTSTEPS.md]
index: empty; nextsteps_lines: 23; protected_source_asset_hashes: unchanged
zip: not created: schema contract blocked
Exit 0

git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-authoring.md
(keine Ausgabe)
Exit 0
```

Alle 22 Quelltabellen wurden vollständig Zeile für Zeile gegen build_rows geprüft. Der Schlussbeleg steht in `build/alltagssprache_redewendungen_checks/final-check.json`; alle ursprünglichen Produktions-/Assethashes stimmen mit `baseline.json` überein. Nur NEXTSTEPS hat sich unter den vorbestehenden Dateien geändert; der neue Bericht ist separat unversioniert. Die zwei eigenen Dokumentdateien wurden außerdem direkt auf nachgestellte Leerzeichen geprüft. Keine Auswahl-/Kontextdatei, Importausgabe oder ZIP entstanden.

## Behobene technische Blockade – noch keine Inhaltsauswahl

Der bestehende normale Weg unterstützt nun Schema-4-Basen und bis zu 450 Auswahlziele. Kontextformat 2 und V2-Lieferformat bleiben erhalten; Content-Schema 4 und sämtliche bestehenden Formtabellen werden unverändert transportiert. 451 Ziele und Einzelbatches über 100 Ziele werden weiterhin abgewiesen. Vollständige synthetische 450er-ZIP mit fünf 90er-Batches, normaler Deltaimport und CLI-Teilfortsetzung geprüft; keine echten Alltagssprache-Ziele angelegt.

Nachweis: [normal-authoring-schema4-compatibility.md](normal-authoring-schema4-compatibility.md). 73 gezielte Tests; gesamte Pipeline 447 Tests + 19 Subtests; aktuelles Asset und realer historischer Natur-Authoring-ZIP-Verifier bestanden. Produktions-/Asset-/Manifesthashes unverändert. Der frühere Blockerstatus und seine damaligen 56 Tests bleiben oben als historische Diagnose erhalten.

Die genehmigte Spezifikation kann jetzt umgesetzt werden. Tatsächliche Auswahlzahlen, Batches und Dublettenentscheidungen sind weiterhin offen; keine redaktionelle Abnahme oder fertige Upload-ZIP behauptet. Eigene technische Änderungen bleiben uncommittet, weil gemischte Vorarbeiten den eigenständigen getesteten Indexstand verhindern; konkrete Hunk-Diagnose im Kompatibilitätsbericht.

## Gegenprüfung vor der konkreten Auswahl (11.10.2026)

Die freigegebene Spezifikation mit acht Themen und drei Ausdruckstypen wird jetzt ausgeführt. Der abgeschlossene normale Schema-4-/V2-Weg wird unverändert verwendet; keine erneute Implementierung. Die vorgesehenen sechs JSON-/ZIP-Ablagen aus dem Auswahlauftrag bleiben verbindlich. Aktuelle Quelle: irregular_verbs_batch_4_v1; vollständiger Bestandsabgleich umfasst alle elf Ansichten, sämtliche Karten-/Wörterbuchsenses, Oberflächenbesitzer, Aliase, Satzalternativen, Gruppen und Lexikalzuordnungen. Vorheraufnahme unter build/alltagssprache_redewendungen_checks/selection_run_20261011/.

Routineentscheidungen: Eigenständige neue Lernbedeutungen auswählen, reine syntaktische Satzschablonen und variable Pronomenplätze zurückstellen. Gesprächstypische feste Formeln können konventionell Ich-/Du-Bezug haben; das sind keine offenen Slots. Mehrwortbesitz gilt nur für die vollständige Oberfläche. Verbalphrasen und Fachsprache nicht als Mengenfüller aufnehmen. Keine Wiederverwendung bestehender Lernkarten als zusätzliche neue Ziele; geeignete reine Wörterbuchsenses können übernommen werden. Batch-1-Sätze fehlen planmäßig und werden nicht fingiert. Die Menge folgt der Dubletten-/Abgrenzungsprüfung, nicht einer Pflicht auf exakt 450.

## Finale Auswahl: Plan-Gegenprüfung und Ergebnis

Die genehmigte Spezifikation wurde vor Auswahländerungen erneut gegengeprüft und mit dem inzwischen vorhandenen normalen Schema-4-/V2-Weg ausgeführt. Keine erneute Kompatibilitätsimplementierung und keine neuen Tests. Alle elf Bestandsstapel einschließlich sämtlicher 402 Verbenfunktionen, 2567 Karten und aller Wörterbuchsenses, 2356 Besitzer, 37 Aliase, 2555 vorhandenen Gruppen und 134 Verben-Lexikalanker wurden in die Identitäts-/Dublettenprüfung einbezogen. Alle vorhandenen Satzalternativen wurden als zusätzliche Kollisionsmenge behandelt.

Aus 522 konkret redaktionell betrachteten Kandidaten wurden **442** ausgewählt und **80** ausgeschlossen/zurückgestellt. Die Menge ist nach Abgrenzung entstanden, keine Auffüllung auf 450. Alle ausgewählten Ziele haben Oberfläche, vorhandene POS-Klassifikation, eindeutige Lemma-/Sense-/Kartenidentität, idiomatische deutsche Glosse, vollständige `target_meaning_de`, Thema, eigenen geplanten Gruppen-Kopf und genaue Besitzbindung. Neue Definitionen sind ausdrücklich Vorschläge, noch nicht durch neue Sätze/Tokenreviews bestätigt.

| Ausdruckstyp | Anzahl |
|---|---:|
| Einzelwörter | 124 |
| Feste Gesprächsformeln / Gesprächsverknüpfungen | 211 |
| Redewendungen | 107 |
| Gesamt | 442 |

| Thema | Anzahl |
|---|---:|
| Absichten und Entscheidungen | 56 |
| Bitten und Höflichkeit | 49 |
| Erzählen und Gesprächsverknüpfung | 72 |
| Gefühle und Reaktionen | 52 |
| Gesprächseinstieg und Smalltalk | 55 |
| Meinung und Zustimmung/Widerspruch | 52 |
| Probleme und Lösungen | 58 |
| Zwischenmenschlicher Umgang | 48 |

| Batch | Neue Satzaufträge | Wörter | Formeln | Redewendungen |
|---|---:|---:|---:|---:|
| 1 | 89 | 25 | 43 | 21 |
| 2 | 89 | 25 | 42 | 22 |
| 3 | 88 | 25 | 42 | 21 |
| 4 | 88 | 25 | 42 | 21 |
| 5 | 88 | 24 | 42 | 22 |

Alle acht Themen sind in jedem Batch vertreten. Die Reihenfolge mischt Themen und Ausdruckstypen; innerhalb jedes Batches stehen keine zwei Ziele desselben Themas unmittelbar nebeneinander. Die Grenze zwischen Batch 1/2 enthält zwei verschiedene Verknüpfungsfunktionen (Themenabgrenzung und Vermutung), keine benachbarte Synonymwiederholung. Anzeige- und Besitzerpositionen können wegen der zusammenhängenden Batchblöcke numerisch übereinstimmen, bleiben aber getrennte Vertragsfelder: immutable Original-/editorial_position, Registry-Besitzposition, vom Exporter abgeleitete display_position. Kein Laufzeitsortier- oder SRS-Verhalten verändert.

## Bestand, Bedeutungen und Wiederverwendung

Alle **442 Lernkarten sind neue geplante ordinary-Ziele**. Bestehende Lernkarten wurden nicht kopiert, verschoben oder als zusätzliche neue Ziele gezählt. Drei ausschließlich im Wörterbuch vorhandene Senses werden exakt übernommen:

| Ziel | Unverändert wiederverwendeter Sense | Begründung |
|---|---|---|
| willing | willing/ADJ\|willing#bereit | Bereitschaft aus eigenem Willen; keine bestehende Lernkarte. |
| setback | setback/NOUN\|setback#rueckschlaege | Rückschlag; vorhandener pluralischer Glossentext bleibt erhalten, Zielübersetzung ist singularisch. |
| instead | instead/ADV\|instead#anstatt | Ersatz für eine andere Möglichkeit; vorhandene Glosse bleibt erhalten, Zielübersetzung ist stattdessen. |

439 neue Sense-Definitionen sind explizite redaktionelle Vorschläge. Die beiden geerbten fehlenden Langdefinitionen (`setback`, `instead`) bleiben NULL; jedes Auswahlziel hat unabhängig davon eine vollständige verbindliche `target_meaning_de`. Keine Altsensezeile oder alte Formglosse wurde angepasst. Wiederverwendung heißt hier Wörterbuch-Sense, nicht bereits gelerntes Ziel und nicht neue Satzvalidierung.

Mehrwortbesitz wird ausschließlich für die vollständige Oberfläche reserviert; alle neuen Besitzaliaslisten sind leer. Bekannte Einzelbestandteile erzeugen keine zweite Reservierung. 442 neue Oberflächenreservierungen ergeben 2798 Registry-Wörter; die 2356 alten Reservierungen bleiben exakt als unverändertes Präfix erhalten. Gruppensnapshot: 2567 alte Kartenentscheidungen unverändert und 442 separat geplante Singleton-Köpfe. Normale Ziele erhalten keine Verben-Formidentität oder Formtabellen-Neuzuordnung.

Kollisionsentscheidungen vergleichen englische Form, Lemma/POS, Sinn, aktuelle Lernkarte/Owner/Alias und vorhandene Definition/Kontexte. Deutsche Übersetzungen sind lediglich ein Kandidatensignal. Beispiele: `favor` ist bereits Besitzalias des gelernten `favour#gefallen`; `consensus` überschneidet sich in der vorgeschlagenen Einigkeitsbedeutung mit `agreement#einigkeit`. `thoughtful` als aufmerksam/rücksichtsvoll wurde wegen der bereits besessenen Oberfläche nicht neu reserviert, ohne die bestehende Nachdenklichkeitsbedeutung fälschlich gleichzusetzen. Synonyme innerhalb der Vorschläge werden nur einmal als Ziel eingeführt, etwa for example/for instance, what a pity/what a shame und nevertheless/nonetheless.

Routineabgrenzungen: konventionelle feste Ich-/Du-Formeln sind vollständige Gesprächsmarker, keine offenen Slots. Idiome mit variabler Objekt-/Possessivstelle wie make up one's mind, take for granted oder give someone the benefit of the doubt werden nicht als künstlich verkürzte feste Oberflächen gerettet. Phrasal Verbs wie hit it off und hang in there sowie fachlich/korrespondenzlastige Kandidaten werden überwiegend späteren Stapeln überlassen. Kein Business-/E-Mail-Spezialstapel, keine zusätzliche Grammatik-/Formauswahl.

Register: Gesprächsformeln sind teilweise informell; `no offence`, `fancy seeing you here`, `touch wood`, `take a rain check` und einzelne Idiome haben regionale/konventionelle Prägung. `skeptical` verwendet US-Schreibung; die britische Form ist keine zusätzliche Auswahl. Die Mehrheit ist allgemeinsprachlich. Die verbindliche Registerbeurteilung einzelner Satzverwendungen folgt bei Redaktion, besonders bei scharfen Formeln wie mind your own business oder good riddance. Keine Häufigkeitszahlen oder unabhängige menschliche Freigabe behauptet. Besitz-/Typdaten erlauben keine automatischen Synonymantworten.

## Finale Dateien und Hashbindungen

Verbindliche tatsächliche Ablage:

- `pipeline/data/selection/alltagssprache_redewendungen_v1.json`: unveränderlich zu liefernder Gesamtkatalog, Definitionen und Ausschlussentscheidungen.
- `pipeline/data/selection/alltagssprache_redewendungen_batch_1_context_v1.json`: gleiche Identitäten/Definitionen im Batch-1-Kontext.
- `pipeline/data/words/en.alltagssprache_redewendungen_batch_1_context_v1.json`: neue Reservierungsrevision.
- `pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_1_context_v1.json`: aktuelle alte Gruppen plus geplante neue Köpfe.
- `build/alltagssprache_redewendungen_authoring_batch_1.zip`: geprüfte erste Übergabe.
- Prüfprotokolle: `build/alltagssprache_redewendungen_checks/selection_run_20261011/`.

Der tatsächliche bestehende Gruppenkontext der Verben lag unter `pipeline/data/selection/irregular_verbs_batch_4_context_v1/learning_groups.json`; aktuelle Gruppendaten werden aus dem finalen Pack und seinen stabilen IDs abgeleitet, nicht aus einem alten Snapshot als vermeintlich aktuellem Stand. Die Basis ist `pipeline/out/irregular_verbs_batch_4_v1/pack.json` samt SQLite, Schema 4. Alle elf Ansichten und 402 bestehenden Formziele bleiben vollständig im ZIP enthalten.

| Basisdatei | SHA256 vorher/nachher |
|---|---|
| Pack-JSON | bf13af162d0cd12122665f9f8dc2edfd57daaf38c9e2a6ee58125452c3a267dc |
| Quell-SQLite und Asset | e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3 |
| Asset-Manifest | 88e460403aeb0733cec65bf7fe74d1e5d5d7062b6d1e27fb0f5db2923f70a9c5 |

| Neue Datei | Rohbyte-SHA256 |
|---|---|
| pipeline/data/selection/alltagssprache_redewendungen_v1.json | fef6e572248adff37e2ec6996f84244212fb078a22933526ad5a694ca91be349 |
| pipeline/data/selection/alltagssprache_redewendungen_batch_1_context_v1.json | 12779941a0cd3aad7954652f75d293a315a7ca69c71d56839730790413c4b416 |
| pipeline/data/words/en.alltagssprache_redewendungen_batch_1_context_v1.json | 51d19fc324afed93c74dc8a4918797977bc35da797f78b8816a7da0d6da6cc1b |
| pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_1_context_v1.json | bf2cf6ac5e6403615043fe5f84dc0e418f367c06d9e733feac3e1a4e81156f25 |
| build/alltagssprache_redewendungen_authoring_batch_1.zip | 03a20081eaaf4926a571d38edf830b68eba3a5c588ad05d275ce0c6cc560e752 |

Kanonische Hashes und rohe Dateihashes sind getrennt. Source-JSON ist nicht der SQLite-Hash. Kontextauswahl kanonisch `6d4664e012e28506118fb9513560264f7a6e4fe77cc11740c570e72a578a4a8d`; Registry `555b95a300d0aadd8245cdac8f8cd50b2f650905f5dbd037ed51549d91b0b2d2`; Gruppen `332551919729f4b0f0615d8f119480aec0e5b0307a191c1d638b6f5bf6c67054`.

## Tatsächliche Prüfungen

Befehle auf macOS; Windows verwendet den vorhandenen `pipeline\.venv\Scripts\python.exe` statt `pipeline/.venv-macos/bin/python`. Dart-/Git-Befehle sind identisch. Keine Paketupdates, Produktionsimporte, Staging, Geräte-/Flutter-Komplettsuite oder Cloud-/Modellaufrufe.

```text
dart run tool/stage_content_pack.dart --verify
verified assets/content/en/content.sqlite
  version irregular_verbs_batch_4_v1, schema 4, 16863232 bytes
  sha256 e99074c535015c7875a5c8ac5e4c68e318ab4d569825db488e01dd4947bdcde3
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help
CLI: --selection, --batch, --out, --verify-zip; normale Kontextstruktur unverändert.
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-selection/build.py
bind_new_pack, stable_id, validate_context und bestehende Gruppen-/Registry-/Partitionvalidatoren
status PASS; selected=442; existing_senses=3; new_senses=439; existing_cards=2567; new_groups=442
batches 89/89/88/88/88; registry_words=2798; partition_selection PASS: 0 present
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/alltagssprache_redewendungen_batch_1_context_v1.json --batch 1 --out build/alltagssprache_redewendungen_authoring_batch_1.zip
export PASS; selected=442; nur 89 aktuelle Satzaufträge
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/alltagssprache_redewendungen_authoring_batch_1.zip
{
  "zip_verification": "PASS",
  "zip_sha256": "03a20081eaaf4926a571d38edf830b68eba3a5c588ad05d275ce0c6cc560e752",
  "hashed_files": 81,
  "sqlite_tables": 22,
  "sqlite_cards": 2567,
  "selected": 442,
  "batches": {
    "1": 89,
    "2": 89,
    "3": 88,
    "4": 88,
    "5": 88
  },
  "new_groups": 442
}
Exit 0

pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_word_registry.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_normal_schema4_authoring.py pipeline/tests/test_learning_groups.py pipeline/tests/test_blindtest.py::test_candidates_case_duplicates_multiword_and_main_answer -q
...............................................................          [100%]
63 passed in 5.68s
Exit 0

pipeline/.venv-macos/bin/python /tmp/everyday-selection/final_audit.py
BATCH 1 89 all eight themes; types {'WORD': 25, 'FORMULA': 43, 'IDIOM': 21}
BATCH 2 89 all eight themes; types {'WORD': 25, 'FORMULA': 42, 'IDIOM': 22}
BATCH 3 88 all eight themes; types {'WORD': 25, 'FORMULA': 42, 'IDIOM': 21}
BATCH 4 88 all eight themes; types {'WORD': 25, 'FORMULA': 42, 'IDIOM': 21}
BATCH 5 88 all eight themes; types {'WORD': 24, 'FORMULA': 42, 'IDIOM': 22}
ZIP exact whole catalogue / source / registry / groups / partitions PASS; CRC PASS
PROTECTED baseline 2637 files; changed only ['docs/alltagssprache-redewendungen-authoring.md'] ; source/asset/manifest and all compatibility/V3/App/SRS code unchanged PASS
SENSES 3 dictionary-only reused / 439 new proposals; 0 existing learning cards reused; no new sentence or token rows
PARTITION 0 imported / 89 current / 353 later PASS; original/owner/display positions distinct fields
Exit 0
```

Die ZIP wurde geschlossen, erneut geöffnet und vollständig geprüft: CRCs, alle 81 manifestierten Dateihashes, exakte JSON-/SQLite-Basis, alle Zeilen aller 22 Tabellen, Identitäten, Referenzen, Reservierungen, alte/geplante Gruppen und disjunkte Partition. `all_selection_identities.json` entspricht exakt den 442 Originalzielen; `authoring_context.entries` enthält nur 89 aktuelle Ziele. Schema-4-Basis, normaler Kontextformat-2-/V2-Importvertrag und unveränderte Verbenformen sind nachgewiesen. Metadatenfähigkeit ist geprüft, fehlende neue Sätze sind ausdrücklich nicht als geprüft/erstellt behandelt.

## Arbeitslaufabweichungen und Commitgrenze

Zwei frühe Aufbauversuche betrafen nur die neue lokale Metadatenerzeugung: zunächst Rückgabewert von `bind_new_pack` statt dessen mutiertem Objekt verwendet (TypeError, Exit 1), anschließend die separat im Authoring-Vertrag erforderlichen Besitzpositionen fehlten (KeyError position, Exit 1). Nach Prüfung des vorhandenen Funktionskörpers wurden die verlangten Kontextfelder aus den Originalpositionen ergänzt, ohne Pipelinecode zu ändern. Kein wiederholter gleicher Lösungsversuch und keine Schutzprüfung deaktiviert. Diese Fehlversuche erzeugten keine Auswahldateien.

Ein erster Testaufruf verwendete versehentlich den nicht vorhandenen Pfad `pipeline/tests/test_multiword.py` (Exit 4); nach gezielter Suche wurde der tatsächliche vorhandene Mehrwort-/Duplikatfall in `test_blindtest.py` ausgeführt. Kein neuer Test oder Paketupdate. Die gemeldete Zwischenmenge 441 war ein Rechenfehler: favor war bereits als Besitzalias ausgeschlossen; der zusätzliche Ausschluss consensus reduzierte 443 auf **442**. Vor Veröffentlichung wurden ausschließlich eigene unveröffentlichte Entwurfsdateien konsistent neu erzeugt; alte Snapshotdateien blieben unangetastet. Endgültige Hashes/Partitionen oben sind nach dieser Korrektur geprüft.

Kein Commit: HEAD enthält noch den normalen Schema-3-Vertrag und die 300-Grenze, während die benötigte Schema-4-/450-Kompatibilität und V3-Vorarbeiten ausdrücklich uncommittet bleiben sollen. Ein Datencommit mit dieser Schema-4-/442er-Auswahl wäre auf HEAD nicht eigenständig mit den versionierten Werkzeugen prüfbar. Darüber hinaus sind der Authoring-Bericht und NEXTSTEPS mit vorbestehenden uncommitteten Anteilen gemischt. Der Index bleibt leer; keine Kompatibilitäts-/V3-Datei, kein fremder Dokumentanteil oder build-Artefakt aufgenommen, kein git add -A und kein Push. Eigener Umfang: die vier neuen Auswahl-/Kontext-/Registry-/Gruppendateien und die zwei erlaubten Dokumentaktualisierungen; erzeugte ZIP/Protokolle bleiben build-Artefakte.

Abschließender dokumentbezogener Git-Check (macOS Terminal und Windows PowerShell, identischer Befehl):

```text
git -c core.whitespace=cr-at-eol diff --check -- NEXTSTEPS.md docs/alltagssprache-redewendungen-authoring.md pipeline/data/selection/alltagssprache_redewendungen_v1.json pipeline/data/selection/alltagssprache_redewendungen_batch_1_context_v1.json pipeline/data/words/en.alltagssprache_redewendungen_batch_1_context_v1.json pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_1_context_v1.json
Output: leer
Exit 0
Direkter Scan derselben sechs Dateien: Whitespace PASS: 6 documents/JSON files; NEXTSTEPS: 25 lines
Exit 0
Schlussaudit: PROTECTED baseline 2637 files; changed only ['docs/alltagssprache-redewendungen-authoring.md', 'NEXTSTEPS.md']; source/asset/manifest and all compatibility/V3/App/SRS code unchanged PASS
Exit 0
```

Eigene Whitespaceprüfung mit der genauen sechsfachen Auftragsdateiliste und zusätzlichem direkten Scan unversionierter Dateien bestanden, Exit 0. Bekannte globale CRLF-/Whitespace-Altbefunde bleiben unverändert. Schlussaudit bestätigt ausschließlich erlaubte Dokumentänderungen unter vorbestehenden Dateien; Produktions-/Asset-/Manifesthashes, historische Dateien, App-/SRS-/V3-/Kompatibilitätscode unverändert.

## Vollständiger Auswahlkatalog

Diese Liste enthält Lernziele/Metadaten, keine neuen Übungssätze. Eindeutige IDs, Wortbesitz, Gruppen und vollständige Ausschlussentscheidungen stehen in den JSON-Dateien. Wörterbuch-Sensewiederverwendung ist als solche gekennzeichnet.

| Nr. | Ziel | POS | Typ | Batch | Deutsche Glosse | Präzise Zieldefinition |
|---:|---|---|---|---:|---|---|
| 1 | nevertheless | ADV | WORD | 1 | dennoch | Trotz des zuvor genannten Umstands. |
| 2 | no harm done | INTJ | FORMULA | 1 | es ist nichts passiert | Aussage, dass ein Versehen keinen nennenswerten Schaden verursacht hat. |
| 3 | put two and two together | VERB | IDIOM | 1 | eins und eins zusammenzählen | Aus mehreren Hinweisen eine naheliegende Schlussfolgerung ziehen. |
| 4 | chitchat | NOUN | WORD | 1 | Geplauder | Ungezwungenes Gespräch über wenig gewichtige Alltagsthemen. |
| 5 | by the way | ADV | FORMULA | 1 | übrigens | Einleitung einer ergänzenden Bemerkung oder eines Themenwechsels. |
| 6 | see eye to eye | VERB | IDIOM | 1 | einer Meinung sein | In einer bestimmten Frage miteinander übereinstimmen. |
| 7 | incidentally | ADV | WORD | 1 | nebenbei bemerkt | Einleitung einer beiläufigen zusätzlichen Bemerkung. |
| 8 | suit yourself | INTJ | FORMULA | 1 | wie du willst | Akzeptanz einer fremden Entscheidung, oft mit leichter Distanz oder Missbilligung. |
| 9 | a piece of cake | NOUN | IDIOM | 1 | ein Kinderspiel | Eine sehr leicht zu erledigende Aufgabe. |
| 10 | ultimately | ADV | WORD | 1 | letztlich | Bezogen auf den letztlich ausschlaggebenden Grund oder die abschließende Bewertung. |
| 11 | long time no see | INTJ | FORMULA | 1 | lange nicht gesehen | Gruß an jemanden, den man lange nicht getroffen hat. |
| 12 | stand on ceremony | VERB | IDIOM | 1 | förmlich sein | Stark auf formelle Umgangsregeln und Abläufe bestehen. |
| 13 | bias | NOUN | WORD | 1 | Voreingenommenheit | Einseitige Neigung, die eine unvoreingenommene Beurteilung beeinflusst. |
| 14 | you must be joking | INTJ | FORMULA | 1 | das kann nicht dein Ernst sein | Reaktion, die eine Aussage für kaum glaubhaft oder absurd hält. |
| 15 | take a rain check | VERB | IDIOM | 1 | auf später verschieben | Eine Einladung höflich ablehnen und eine spätere Gelegenheit wünschen. |
| 16 | obstacle | NOUN | WORD | 1 | Hindernis | Etwas, das eine Handlung oder einen Fortschritt blockiert. |
| 17 | in other words | ADV | FORMULA | 1 | mit anderen Worten | Einleitung einer anders formulierten Erklärung derselben Aussage. |
| 18 | out of the blue | ADV | IDIOM | 1 | völlig unerwartet | Ohne vorherige Anzeichen oder Ankündigung eintretend. |
| 19 | courtesy | NOUN | WORD | 1 | Höflichkeit | Rücksichtsvoller höflicher Umgang mit anderen Menschen. |
| 20 | to my mind | ADV | FORMULA | 1 | nach meinem Dafürhalten | Kennzeichnung einer Aussage als eigenes Urteil. |
| 21 | under the weather | ADJ | IDIOM | 1 | nicht ganz auf dem Damm | Sich leicht krank oder gesundheitlich angeschlagen fühlend. |
| 22 | impulse | NOUN | WORD | 1 | spontaner Drang | Plötzliches Bedürfnis, etwas ohne längeres Überlegen zu tun. |
| 23 | there must be a way | INTJ | FORMULA | 1 | es muss einen Weg geben | Ausdruck der Zuversicht, dass eine Lösung gefunden werden kann. |
| 24 | rub salt in the wound | VERB | IDIOM | 1 | Salz in die Wunde streuen | Eine bereits schmerzhafte Erfahrung durch weitere Bemerkungen verschlimmern. |
| 25 | literally | ADV | WORD | 1 | buchstäblich | Im tatsächlichen Wortsinn und nicht bildlich gemeint. |
| 26 | how have you been | INTJ | FORMULA | 1 | wie ist es dir ergangen | Frage nach dem Befinden seit der letzten Begegnung. |
| 27 | would you mind | INTJ | FORMULA | 1 | würde es dir etwas ausmachen | Höfliche Einleitung einer Bitte, gefolgt von der gewünschten Handlung. |
| 28 | convincing | ADJ | WORD | 1 | überzeugend | Geeignet, jemanden von einer Behauptung zu überzeugen. |
| 29 | good riddance | INTJ | FORMULA | 1 | endlich weg | Erleichterung über das Weggehen einer lästigen Person oder Sache. |
| 30 | take a back seat | VERB | IDIOM | 1 | in den Hintergrund treten | Anderen die führende Rolle überlassen und selbst weniger Einfluss ausüben. |
| 31 | hassle | NOUN | WORD | 1 | lästiger Aufwand | Unangenehme Mühe oder Schwierigkeiten bei einer alltäglichen Aufgabe. |
| 32 | mind your own business | INTJ | FORMULA | 1 | kümmere dich um deine eigenen Angelegenheiten | Aufforderung, sich nicht in fremde private Dinge einzumischen. |
| 33 | give the game away | VERB | IDIOM | 1 | sich verraten | Durch einen Hinweis eine verborgene Absicht erkennbar machen. |
| 34 | reserved | ADJ | WORD | 1 | zurückhaltend | Persönliche Gedanken und Gefühle nicht leicht nach außen zeigend. |
| 35 | could you repeat that | INTJ | FORMULA | 1 | könntest du das wiederholen | Höfliche Bitte um erneutes Aussprechen einer Äußerung. |
| 36 | call a spade a spade | VERB | IDIOM | 1 | Klartext reden | Eine unangenehme Tatsache ohne beschönigende Worte benennen. |
| 37 | dismay | NOUN | WORD | 1 | Bestürzung | Erschrecken und Enttäuschung über eine unangenehme Entwicklung. |
| 38 | on second thoughts | INTJ | FORMULA | 1 | bei genauerem Überlegen | Einleitung einer geänderten Einschätzung oder Entscheidung. |
| 39 | the tip of the iceberg | NOUN | IDIOM | 1 | die Spitze des Eisbergs | Der sichtbare kleine Teil eines viel größeren Problems. |
| 40 | sincere | ADJ | WORD | 1 | aufrichtig | Wirkliche Gefühle oder Überzeugungen ausdrückend, nicht nur vortäuschend. |
| 41 | as a rule | ADV | FORMULA | 1 | in der Regel | Kennzeichnung eines gewöhnlichen, aber nicht ausnahmslosen Ablaufs. |
| 42 | from time to time | ADV | IDIOM | 1 | von Zeit zu Zeit | Gelegentlich, ohne festen regelmäßigen Rhythmus. |
| 43 | tactful | ADJ | WORD | 1 | taktvoll | Heikle Dinge so ansprechend, dass andere möglichst nicht verletzt werden. |
| 44 | not necessarily | INTJ | FORMULA | 1 | nicht unbedingt | Einschränkung, dass eine Behauptung nicht in jedem Fall zutrifft. |
| 45 | jump for joy | VERB | IDIOM | 1 | vor Freude springen | Große Freude lebhaft ausdrücken. |
| 46 | spontaneous | ADJ | WORD | 1 | spontan | Ohne vorherige Planung aus einem unmittelbaren Impuls entstehend. |
| 47 | so far, so good | INTJ | FORMULA | 1 | bis jetzt läuft alles gut | Zwischenbilanz, dass bisher keine wesentlichen Schwierigkeiten aufgetreten sind. |
| 48 | meet halfway | VERB | IDIOM | 1 | einen Kompromiss eingehen | Beiderseitig Zugeständnisse machen, um eine Einigung zu ermöglichen. |
| 49 | to begin with | ADV | FORMULA | 1 | zunächst einmal | Einleitung des ersten Gesichtspunkts oder der ursprünglichen Situation. |
| 50 | help yourself | INTJ | FORMULA | 1 | bedien dich | Einladung, sich selbst etwas zu nehmen, etwa angebotene Speisen. |
| 51 | never mind | INTJ | FORMULA | 1 | macht nichts | Aufforderung, eine belanglose Sache nicht weiter zu beachten oder zu verfolgen. |
| 52 | subjective | ADJ | WORD | 1 | subjektiv | Von persönlichen Erfahrungen oder Vorlieben geprägt. |
| 53 | that's the spirit | INTJ | FORMULA | 1 | genau diese Einstellung ist richtig | Ermutigende Anerkennung von Entschlossenheit oder Zuversicht. |
| 54 | follow suit | VERB | IDIOM | 1 | es ebenso machen | Sich dem Beispiel oder der Handlung einer anderen Person anschließen. |
| 55 | manageable | ADJ | WORD | 1 | bewältigbar | Nicht so schwierig oder groß, dass man es nicht handhaben kann. |
| 56 | it's not your fault | INTJ | FORMULA | 1 | du bist nicht schuld | Entlastung einer Person von Verantwortung für ein Ereignis. |
| 57 | word for word | ADV | IDIOM | 1 | Wort für Wort | Genau mit denselben Worten, ohne Umformulierung. |
| 58 | anecdote | NOUN | WORD | 1 | Anekdote | Kurze unterhaltsame Erzählung über ein konkretes Erlebnis. |
| 59 | allow me | INTJ | FORMULA | 1 | darf ich helfen | Höfliches Angebot, eine Aufgabe für jemanden zu übernehmen. |
| 60 | miss the point | VERB | IDIOM | 1 | den Kern verfehlen | Die entscheidende Bedeutung einer Aussage nicht verstehen. |
| 61 | uneasy | ADJ | WORD | 1 | unbehaglich | Leichte Sorge oder Unruhe wegen einer unsicheren Situation empfindend. |
| 62 | for now | INTJ | FORMULA | 1 | vorerst | Kennzeichnung einer Entscheidung als derzeitige vorläufige Lösung. |
| 63 | up in the air | ADJ | IDIOM | 1 | noch ungewiss | Noch nicht entschieden oder sicher festgelegt. |
| 64 | clingy | ADJ | WORD | 1 | anhänglich | Übermäßig viel Nähe oder Bestätigung von einer anderen Person verlangend. |
| 65 | on the other hand | ADV | FORMULA | 1 | andererseits | Einleitung der gegenüberstehenden Seite einer Abwägung. |
| 66 | not too bad | INTJ | FORMULA | 1 | ganz ordentlich | Zurückhaltend positive Antwort auf eine Frage nach dem Befinden oder Zustand. |
| 67 | appreciative | ADJ | WORD | 1 | anerkennend | Wertschätzung für eine Leistung oder Freundlichkeit zeigend. |
| 68 | it depends on the circumstances | INTJ | FORMULA | 1 | es hängt von den Umständen ab | Ausdruck, dass situative Bedingungen für eine Entscheidung maßgeblich sind. |
| 69 | cry over spilt milk | VERB | IDIOM | 1 | vergeblich Vergangenem nachtrauern | Sich über einen nicht mehr rückgängig zu machenden Schaden grämen. |
| 70 | worthwhile | ADJ | WORD | 1 | lohnend | Den eingesetzten Aufwand oder die Zeit wert. |
| 71 | you'll manage | INTJ | FORMULA | 1 | du schaffst das | Ermutigung, dass jemand eine Aufgabe bewältigen kann. |
| 72 | that's between us | INTJ | FORMULA | 1 | das bleibt unter uns | Bitte oder Zusicherung, eine Information vertraulich zu behandeln. |
| 73 | to be honest | ADV | FORMULA | 1 | ehrlich gesagt | Angekündigt offene persönliche Einschätzung ohne Beschönigung. |
| 74 | see you around | INTJ | FORMULA | 1 | man sieht sich | Unverbindliche informelle Verabschiedung ohne festen nächsten Termin. |
| 75 | you shouldn't have | INTJ | FORMULA | 1 | das wäre nicht nötig gewesen | Freundliche Reaktion auf ein Geschenk oder unerwarteten Aufwand. |
| 76 | for the sake of argument | INTJ | FORMULA | 1 | nehmen wir es für die Diskussion an | Eine Annahme vorläufig zulassen, ohne sie selbst zu vertreten. |
| 77 | easy does it | INTJ | FORMULA | 1 | ganz vorsichtig | Aufforderung, langsam und behutsam vorzugehen. |
| 78 | better late than never | INTJ | FORMULA | 1 | besser spät als nie | Anerkennung, dass verspätetes Handeln besser als völliges Unterlassen ist. |
| 79 | oops | INTJ | WORD | 1 | hoppla | Informeller Ausruf bei einem kleinen unbeabsichtigten Fehler. |
| 80 | keep in touch | INTJ | FORMULA | 1 | bleiben wir in Kontakt | Abschiedsformel mit dem Wunsch nach weiterem gegenseitigem Kontakt. |
| 81 | correct me if I'm wrong | ADV | FORMULA | 1 | korrigiere mich, wenn ich mich irre | Einleitung einer unsicheren Aussage mit Offenheit für Berichtigung. |
| 82 | sweet dreams | INTJ | FORMULA | 1 | träum schön | Freundlicher Wunsch vor dem Schlafengehen. |
| 83 | thanks for the heads-up | INTJ | FORMULA | 1 | danke für den Hinweis | Dank für eine rechtzeitige Vorwarnung oder wichtige Information. |
| 84 | in principle | ADV | FORMULA | 1 | grundsätzlich | Bezogen auf die Grundidee, unabhängig von einzelnen praktischen Umständen. |
| 85 | mortified | ADJ | WORD | 1 | peinlich berührt | Wegen eines eigenen Fehlers oder einer Blamage stark beschämt. |
| 86 | there's no time like the present | INTJ | FORMULA | 1 | warum nicht gleich | Ermutigung, eine beabsichtigte Handlung sofort zu beginnen. |
| 87 | go back to the drawing board | VERB | IDIOM | 1 | noch einmal neu planen | Nach dem Scheitern eines Versuchs eine andere Lösung entwickeln. |
| 88 | you have my word | INTJ | FORMULA | 1 | darauf gebe ich dir mein Wort | Persönliche feste Zusicherung der Wahrheit oder eines Versprechens. |
| 89 | now that you mention it | INTJ | FORMULA | 1 | wo du es gerade erwähnst | Reaktion, dass eine Bemerkung einen weiteren Gedanken ausgelöst hat. |
| 90 | apparently | ADV | WORD | 2 | offenbar | Nach verfügbaren Informationen oder dem äußeren Eindruck zu urteilen. |
| 91 | my mistake | INTJ | FORMULA | 2 | mein Fehler | Übernahme der Verantwortung für einen konkreten Irrtum. |
| 92 | get straight to the point | VERB | IDIOM | 2 | direkt zur Sache kommen | Ohne längere Einleitung den wesentlichen Punkt ansprechen. |
| 93 | disbelief | NOUN | WORD | 2 | Unglaube | Gefühl, dass man eine überraschende Behauptung kaum glauben kann. |
| 94 | that is to say | ADV | FORMULA | 2 | das heißt | Einleitung einer Präzisierung oder Erklärung. |
| 95 | go with the flow | VERB | IDIOM | 2 | sich dem Verlauf anpassen | Eine Entwicklung geschehen lassen, statt sie stark steuern zu wollen. |
| 96 | furthermore | ADV | WORD | 2 | außerdem | Einleitung eines zusätzlichen Arguments oder Gesichtspunkts. |
| 97 | I'll see what I can do | INTJ | FORMULA | 2 | ich schaue, was sich machen lässt | Hilfszusage ohne Garantie eines bestimmten Ergebnisses. |
| 98 | paint a picture | VERB | IDIOM | 2 | ein Bild vermitteln | Eine Situation so beschreiben, dass andere sie sich vorstellen können. |
| 99 | banter | NOUN | WORD | 2 | Scherzgeplänkel | Freundschaftlicher Austausch spielerischer neckender Bemerkungen. |
| 100 | may I ask | INTJ | FORMULA | 2 | darf ich fragen | Höfliche Einleitung einer möglicherweise persönlichen Frage. |
| 101 | sit on the fence | VERB | IDIOM | 2 | sich nicht festlegen | Bei einer Streitfrage keine der Seiten eindeutig unterstützen. |
| 102 | thrilled | ADJ | WORD | 2 | begeistert | Außerordentlich erfreut oder aufgeregt über etwas Gutes. |
| 103 | count me in | INTJ | FORMULA | 2 | ich bin dabei | Zusage, an einer vorgeschlagenen Aktivität teilzunehmen. |
| 104 | a blessing in disguise | NOUN | IDIOM | 2 | ein Glück im Unglück | Etwas zunächst Negatives, das sich später als vorteilhaft erweist. |
| 105 | arguably | ADV | WORD | 2 | vertretbarerweise | Kennzeichnung einer Behauptung, für die sich gute Gründe nennen lassen. |
| 106 | nice to meet you | INTJ | FORMULA | 2 | freut mich, dich kennenzulernen | Höfliche Formel bei der ersten persönlichen Begegnung. |
| 107 | go the extra mile | VERB | IDIOM | 2 | sich besonders viel Mühe geben | Mehr Einsatz leisten, als normalerweise erwartet wird. |
| 108 | biased | ADJ | WORD | 2 | voreingenommen | In einer Beurteilung einseitig zugunsten oder gegen etwas eingestellt. |
| 109 | what a relief | INTJ | FORMULA | 2 | was für eine Erleichterung | Reaktion darauf, dass eine Sorge oder Gefahr vorüber ist. |
| 110 | go for broke | VERB | IDIOM | 2 | alles riskieren | Mit vollem Einsatz ein Ziel verfolgen und dabei ein großes Risiko eingehen. |
| 111 | drawback | NOUN | WORD | 2 | Nachteil | Eine ungünstige Eigenschaft einer ansonsten möglichen Lösung. |
| 112 | don't take it personally | INTJ | FORMULA | 2 | nimm es nicht persönlich | Bitte, eine Äußerung nicht als persönliche Abwertung zu verstehen. |
| 113 | talk a mile a minute | VERB | IDIOM | 2 | reden wie ein Wasserfall | Sehr schnell und ausdauernd sprechen. |
| 114 | familiar | ADJ | WORD | 2 | vertraut | Durch wiederholte Begegnung oder Erfahrung bereits bekannt. |
| 115 | thanks anyway | INTJ | FORMULA | 2 | trotzdem danke | Dank für eine Bemühung, obwohl sie nicht das gewünschte Ergebnis brachte. |
| 116 | in a nutshell | ADV | IDIOM | 2 | kurz gesagt | Eine Sache in sehr knapper Form zusammenfassen. |
| 117 | speechless | ADJ | WORD | 2 | sprachlos | Vor Überraschung oder starken Gefühlen keine Worte findend. |
| 118 | come to think of it | INTJ | FORMULA | 2 | wenn ich genauer darüber nachdenke | Einleitung eines Gedankens, der einem gerade ergänzend einfällt. |
| 119 | the last straw | NOUN | IDIOM | 2 | der Tropfen, der das Fass zum Überlaufen bringt | Der letzte zusätzliche Ärger, der eine bereits belastete Person zum Reagieren bringt. |
| 120 | supportive | ADJ | WORD | 2 | unterstützend | Anderen mit Verständnis oder praktischer Hilfe beistehend. |
| 121 | above all | ADV | FORMULA | 2 | vor allem | Hervorhebung des wichtigsten Gesichtspunkts. |
| 122 | go way back | VERB | IDIOM | 2 | sich schon sehr lange kennen | Bereits seit vielen Jahren miteinander bekannt sein. |
| 123 | etiquette | NOUN | WORD | 2 | Umgangsregeln | Anerkannte Regeln für angemessenes höfliches Verhalten. |
| 124 | as far as I'm concerned | ADV | FORMULA | 2 | was mich betrifft | Einleitung der eigenen persönlichen Position zu einer Sache. |
| 125 | on edge | ADJ | IDIOM | 2 | angespannt | Nervös und leicht gereizt wegen Anspannung. |
| 126 | indecisive | ADJ | WORD | 2 | unentschlossen | Sich nur schwer für eine Möglichkeit entscheiden könnend. |
| 127 | what went wrong | INTJ | FORMULA | 2 | was ist schiefgegangen | Frage nach der Ursache eines Misserfolgs oder Fehlers. |
| 128 | add insult to injury | VERB | IDIOM | 2 | die Sache noch schlimmer machen | Zu einem erlittenen Nachteil noch eine weitere Kränkung hinzufügen. |
| 129 | initially | ADV | WORD | 2 | anfangs | Zu Beginn eines Ablaufs, bevor sich etwas möglicherweise änderte. |
| 130 | fancy seeing you here | INTJ | FORMULA | 2 | dich hier zu treffen ist eine Überraschung | Informelle Reaktion auf eine unerwartete Begegnung. |
| 131 | eat humble pie | VERB | IDIOM | 2 | kleinlaut einen Fehler eingestehen | Die eigene Überheblichkeit überwinden und einräumen, im Unrecht gewesen zu sein. |
| 132 | unanimous | ADJ | WORD | 2 | einstimmig | Von allen Beteiligten ohne Gegenstimme getragen. |
| 133 | are you serious | INTJ | FORMULA | 2 | meinst du das ernst | Frage, ob eine überraschende Aussage wirklich ernst gemeint ist. |
| 134 | at the last minute | ADV | IDIOM | 2 | in letzter Minute | Sehr kurz vor einer Frist oder einem Ereignis. |
| 135 | predicament | NOUN | WORD | 2 | missliche Lage | Schwierige Situation, aus der man nur schwer herauskommt. |
| 136 | I'm here for you | INTJ | FORMULA | 2 | ich bin für dich da | Zusicherung persönlicher Unterstützung in einer schwierigen Lage. |
| 137 | in plain English | ADV | IDIOM | 2 | klar und verständlich | Ohne Fachjargon oder unnötig komplizierte Sprache ausgedrückt. |
| 138 | nosy | ADJ | WORD | 2 | neugierig auf Privates | Unangemessen stark an persönlichen Angelegenheiten anderer interessiert. |
| 139 | by all means | INTJ | FORMULA | 2 | selbstverständlich | Nachdrückliche freundliche Erlaubnis oder Zustimmung zu einer Bitte. |
| 140 | fair enough | INTJ | FORMULA | 2 | das ist nachvollziehbar | Anerkennung einer Erklärung oder Entscheidung als akzeptabel. |
| 141 | thank goodness | INTJ | FORMULA | 2 | zum Glück | Ausdruck von Erleichterung oder Dankbarkeit über einen guten Ausgang. |
| 142 | just in case | INTJ | FORMULA | 2 | für alle Fälle | Hinweis, dass etwas vorsorglich für einen möglichen Bedarf getan wird. |
| 143 | on thin ice | ADJ | IDIOM | 2 | auf dünnem Eis | In einer unsicheren Lage, in der ein kleiner Fehler schwere Folgen haben kann. |
| 144 | pushy | ADJ | WORD | 2 | aufdringlich | Wünsche durch übermäßigen Druck auf andere durchsetzen wollend. |
| 145 | in the first place | ADV | FORMULA | 2 | von vornherein | Bezug auf den ursprünglichen Grund oder Anfang einer Sache. |
| 146 | a breath of fresh air | NOUN | IDIOM | 2 | eine wohltuende Abwechslung | Eine Person oder Sache, die eine Situation angenehm erneuert. |
| 147 | inconsiderate | ADJ | WORD | 2 | rücksichtslos | Bedürfnisse und Gefühle anderer nicht ausreichend beachtend. |
| 148 | I wouldn't say that | INTJ | FORMULA | 2 | so würde ich das nicht sagen | Zurückhaltender Widerspruch gegen eine Formulierung oder Schlussfolgerung. |
| 149 | see red | VERB | IDIOM | 2 | rotsehen | Plötzlich sehr wütend werden. |
| 150 | deliberate | ADJ | WORD | 2 | absichtlich | Bewusst gewählt und nicht zufällig geschehen. |
| 151 | give me a moment | INTJ | FORMULA | 2 | gib mir einen Augenblick | Bitte um kurze Zeit, um etwas zu überlegen oder zu erledigen. |
| 152 | thick as thieves | ADJ | IDIOM | 2 | eng vertraut | Eine besonders enge und vertrauliche Verbindung habend. |
| 153 | tangent | NOUN | WORD | 2 | Abschweifung | Ein Gedankengang, der vom eigentlichen Gesprächsthema wegführt. |
| 154 | good for you | INTJ | FORMULA | 2 | das freut mich für dich | Zustimmende Anerkennung eines erfreulichen Erfolgs oder Entschlusses. |
| 155 | make way | INTJ | FORMULA | 2 | Platz machen | Aufforderung, Durchgang oder Raum für jemanden freizugeben. |
| 156 | credible | ADJ | WORD | 2 | glaubwürdig | So beschaffen, dass man einer Aussage oder Person Vertrauen schenken kann. |
| 157 | fingers crossed | INTJ | FORMULA | 2 | hoffentlich geht es gut | Ausdruck der Hoffnung auf einen günstigen Ausgang. |
| 158 | now or never | INTJ | FORMULA | 2 | jetzt oder nie | Betonung, dass eine Gelegenheit nur jetzt genutzt werden kann. |
| 159 | tricky | ADJ | WORD | 2 | knifflig | Schwierig und mit besonderer Aufmerksamkeit zu behandeln. |
| 160 | no offence | INTJ | FORMULA | 2 | nicht böse gemeint | Vorsichtiger Zusatz vor einer möglicherweise kränkenden Bemerkung. |
| 161 | as it turns out | ADV | FORMULA | 2 | wie sich herausstellt | Einleitung einer erst später bekannt gewordenen Tatsache. |
| 162 | can't complain | INTJ | FORMULA | 2 | ich kann mich nicht beklagen | Informelle Aussage, dass es einem insgesamt gut genug geht. |
| 163 | it's the least I can do | INTJ | FORMULA | 2 | das ist das Mindeste, was ich tun kann | Bescheidene Erklärung, warum man jemandem eine Hilfe erweist. |
| 164 | I see your point | INTJ | FORMULA | 2 | ich verstehe deinen Standpunkt | Anerkennung, dass man das Argument der anderen Person verstanden hat. |
| 165 | chin up | INTJ | FORMULA | 2 | Kopf hoch | Kurze Ermutigung in einer enttäuschenden Situation. |
| 166 | easier said than done | INTJ | FORMULA | 2 | leichter gesagt als getan | Hinweis, dass ein Vorschlag praktisch schwieriger als in Worten ist. |
| 167 | keep the ball rolling | VERB | IDIOM | 2 | die Sache in Gang halten | Dafür sorgen, dass eine begonnene Aktivität weiterläuft. |
| 168 | take care | INTJ | FORMULA | 2 | pass auf dich auf | Freundlicher Abschiedsgruß mit einem Wunsch nach Wohlergehen. |
| 169 | if memory serves | ADV | FORMULA | 2 | wenn ich mich recht erinnere | Einschränkung einer Aussage auf die eigene Erinnerung. |
| 170 | have a good one | INTJ | FORMULA | 2 | mach's gut | Informeller guter Wunsch beim Abschied. |
| 171 | obliging | ADJ | WORD | 2 | hilfsbereit | Gern bereit, auf die Wünsche anderer einzugehen. |
| 172 | generally speaking | ADV | FORMULA | 2 | im Allgemeinen | Kennzeichnung einer Aussage als grobe allgemeine Beobachtung. |
| 173 | get cold feet | VERB | IDIOM | 2 | kalte Füße bekommen | Vor einer geplanten Handlung plötzlich ängstlich werden. |
| 174 | feasible | ADJ | WORD | 2 | machbar | Mit verfügbaren Mitteln und Bedingungen durchführbar. |
| 175 | what a bother | INTJ | FORMULA | 2 | wie lästig | Reaktion auf einen unangenehmen zusätzlichen Aufwand. |
| 176 | let's keep it that way | INTJ | FORMULA | 2 | belassen wir es dabei | Vorschlag, einen bestehenden Zustand nicht zu verändern. |
| 177 | where was I | INTJ | FORMULA | 2 | wo war ich stehen geblieben | Frage zur Wiederaufnahme eines unterbrochenen Gedankengangs. |
| 178 | welcome back | INTJ | FORMULA | 2 | willkommen zurück | Gruß an jemanden, der nach einer Abwesenheit zurückkehrt. |
| 179 | meanwhile | ADV | WORD | 3 | währenddessen | Zur gleichen Zeit wie ein anderes beschriebenes Ereignis. |
| 180 | I can't believe it | INTJ | FORMULA | 3 | ich kann es kaum glauben | Ausdruck großer Überraschung oder Unglaubens. |
| 181 | get the wrong end of the stick | VERB | IDIOM | 3 | etwas falsch verstehen | Eine Äußerung grundlegend anders verstehen als gemeint. |
| 182 | reluctant | ADJ | WORD | 3 | widerwillig | Nicht gern bereit, eine bestimmte Handlung auszuführen. |
| 183 | speaking of which | ADV | FORMULA | 3 | wo wir davon sprechen | Übergang zu einem Gedanken, der an das vorige Thema anknüpft. |
| 184 | a stumbling block | NOUN | IDIOM | 3 | ein Stolperstein | Ein konkretes Hindernis, das den Fortschritt erschwert. |
| 185 | admittedly | ADV | WORD | 3 | zugegebenermaßen | Einräumend, dass ein möglicherweise ungünstiger Umstand zutrifft. |
| 186 | good to see you | INTJ | FORMULA | 3 | schön, dich zu sehen | Freundliche Begrüßung einer bereits bekannten Person. |
| 187 | play devil's advocate | VERB | IDIOM | 3 | die Gegenposition vertreten | Absichtlich Gegenargumente vorbringen, um eine Ansicht zu prüfen. |
| 188 | frustration | NOUN | WORD | 3 | Frustration | Unzufriedenheit darüber, dass ein Ziel oder Wunsch nicht erreicht wird. |
| 189 | count me out | INTJ | FORMULA | 3 | ohne mich | Aussage, dass man an einer Aktivität nicht teilnehmen will. |
| 190 | in hot water | ADJ | IDIOM | 3 | in Schwierigkeiten | Wegen eigenen Verhaltens mit Ärger oder drohenden Folgen konfrontiert. |
| 191 | rapport | NOUN | WORD | 3 | guter Draht | Gegenseitiges Verständnis und angenehmer Kontakt zwischen Menschen. |
| 192 | for instance | ADV | FORMULA | 3 | zum Beispiel | Einleitung eines konkreten Beispiels für eine allgemeine Aussage. |
| 193 | off the beaten track | ADV | IDIOM | 3 | abseits der üblichen Wege | Außerhalb häufig besuchter oder gewöhnlich gewählter Orte und Wege. |
| 194 | considerate | ADJ | WORD | 3 | rücksichtsvoll | Die Bedürfnisse und Gefühle anderer bei eigenem Verhalten berücksichtigend. |
| 195 | I couldn't agree more | INTJ | FORMULA | 3 | ich stimme voll und ganz zu | Nachdrückliche vollständige Zustimmung zu einer Äußerung. |
| 196 | at ease | ADJ | IDIOM | 3 | entspannt | Ohne Befangenheit, Sorge oder Unruhe. |
| 197 | tentative | ADJ | WORD | 3 | vorläufig | Noch nicht endgültig festgelegt und möglicherweise änderbar. |
| 198 | it can't be helped | INTJ | FORMULA | 3 | da kann man nichts machen | Feststellung, dass eine unangenehme Lage unvermeidbar ist. |
| 199 | bury the hatchet | VERB | IDIOM | 3 | sich versöhnen | Einen persönlichen Streit beenden und wieder Frieden schließen. |
| 200 | previously | ADV | WORD | 3 | zuvor | Vor dem beschriebenen Zeitpunkt oder Ereignis. |
| 201 | make yourself at home | INTJ | FORMULA | 3 | fühl dich wie zu Hause | Einladung an einen Gast, sich entspannt und ungezwungen zu verhalten. |
| 202 | bend over backwards | VERB | IDIOM | 3 | sich alle Mühe geben | Außergewöhnlich große Anstrengungen unternehmen, um jemandem zu helfen. |
| 203 | stance | NOUN | WORD | 3 | Haltung | Bewusst eingenommene Position zu einer Frage. |
| 204 | that's more like it | INTJ | FORMULA | 3 | so ist es besser | Zustimmende Reaktion auf eine Verbesserung. |
| 205 | leave no stone unturned | VERB | IDIOM | 3 | alle Möglichkeiten ausschöpfen | Gründlich jede Möglichkeit prüfen, um etwas zu erreichen. |
| 206 | oversight | NOUN | WORD | 3 | Versehen | Ein Fehler, weil man etwas Wichtiges nicht bemerkt oder beachtet hat. |
| 207 | I meant well | INTJ | FORMULA | 3 | ich habe es gut gemeint | Erklärung, mit einer Handlung eine gute Absicht verfolgt zu haben. |
| 208 | ring a bell | VERB | IDIOM | 3 | bekannt vorkommen | Eine vage Erinnerung oder ein Gefühl des Wiedererkennens auslösen. |
| 209 | chatty | ADJ | WORD | 3 | gesprächig | Gern und viel in ungezwungener Weise sprechend. |
| 210 | if it's not too much trouble | INTJ | FORMULA | 3 | wenn es keine Umstände macht | Höfliche Einschränkung einer Bitte, um den Aufwand anzuerkennen. |
| 211 | read between the lines | VERB | IDIOM | 3 | zwischen den Zeilen lesen | Eine nicht ausdrücklich genannte Bedeutung aus einer Äußerung erschließen. |
| 212 | resentment | NOUN | WORD | 3 | Verbitterung | Anhaltender Ärger über als ungerecht empfundenes Verhalten. |
| 213 | I'd rather not | INTJ | FORMULA | 3 | lieber nicht | Höfliche Ablehnung einer vorgeschlagenen Handlung. |
| 214 | cut corners | VERB | IDIOM | 3 | es sich zu leicht machen | Arbeit schneller oder billiger erledigen, indem nötige Sorgfalt ausgelassen wird. |
| 215 | genuine | ADJ | WORD | 3 | echt und aufrichtig | Nicht bloß vorgetäuscht oder künstlich dargestellt. |
| 216 | after all | ADV | FORMULA | 3 | schließlich | Verweis auf einen Umstand, der eine Aussage begründet oder korrigiert. |
| 217 | a change of scenery | NOUN | IDIOM | 3 | ein Tapetenwechsel | Ein Aufenthalt in einer anderen Umgebung zur Abwechslung. |
| 218 | generosity | NOUN | WORD | 3 | Großzügigkeit | Bereitschaft, anderen freiwillig Zeit, Hilfe oder Mittel zu geben. |
| 219 | I suppose so | INTJ | FORMULA | 3 | ich nehme an, ja | Zögerliche oder eingeschränkt sichere Zustimmung. |
| 220 | lose heart | VERB | IDIOM | 3 | den Mut verlieren | Zuversicht aufgeben, weil etwas schwierig erscheint. |
| 221 | eventually | ADV | WORD | 3 | letztendlich | Nach einiger Zeit oder Entwicklung schließlich eintretend. |
| 222 | let's give it a try | INTJ | FORMULA | 3 | versuchen wir es | Vorschlag, eine unsichere Möglichkeit praktisch auszuprobieren. |
| 223 | get along like a house on fire | VERB | IDIOM | 3 | sich auf Anhieb bestens verstehen | Sehr schnell eine besonders gute persönliche Beziehung entwickeln. |
| 224 | figuratively | ADV | WORD | 3 | bildlich | Mit übertragener und nicht wörtlicher Bedeutung. |
| 225 | it's been a while | INTJ | FORMULA | 3 | das ist schon eine Weile her | Feststellung, dass seit einer Begegnung oder Tätigkeit längere Zeit vergangen ist. |
| 226 | in good faith | ADV | IDIOM | 3 | in gutem Glauben | Mit ehrlicher Absicht und ohne Täuschungswillen handeln. |
| 227 | plausible | ADJ | WORD | 3 | einleuchtend | Auf den ersten Blick vernünftig und möglicherweise wahr wirkend. |
| 228 | touch wood | INTJ | FORMULA | 3 | hoffentlich bleibt es so | Formel, um nach einer positiven Aussage drohendes Pech abzuwehren. |
| 229 | throw caution to the wind | VERB | IDIOM | 3 | alle Vorsicht vergessen | Bewusst handeln, ohne übliche Risiken oder Bedenken zu berücksichtigen. |
| 230 | glitch | NOUN | WORD | 3 | kleine Störung | Eine meist vorübergehende technische oder organisatorische Fehlfunktion. |
| 231 | let's call it a day | INTJ | FORMULA | 3 | machen wir für heute Schluss | Vorschlag, die gemeinsame Arbeit für den Tag zu beenden. |
| 232 | a running joke | NOUN | IDIOM | 3 | ein wiederkehrender Witz | Ein scherzhafter Bezug, der in einer Gruppe immer wieder aufgegriffen wird. |
| 233 | catchphrase | NOUN | WORD | 3 | Schlagwort | Einprägsamer Ausdruck, der wiederholt verwendet wird. |
| 234 | I beg your pardon | INTJ | FORMULA | 3 | wie bitte | Höfliche Bitte, etwas wegen fehlenden Verständnisses zu wiederholen. |
| 235 | let's agree to disagree | INTJ | FORMULA | 3 | belassen wir es bei unterschiedlichen Meinungen | Vorschlag, einen Meinungsstreit ohne Einigung zu beenden. |
| 236 | contented | ADJ | WORD | 3 | zufrieden | Mit der eigenen Situation ruhig zufrieden. |
| 237 | in the meantime | INTJ | FORMULA | 3 | in der Zwischenzeit | Verweis auf den Zeitraum bis zu einem erwarteten Ereignis. |
| 238 | all is not lost | INTJ | FORMULA | 3 | noch ist nicht alles verloren | Hinweis, dass trotz Problemen noch Hoffnung besteht. |
| 239 | aloof | ADJ | WORD | 3 | distanziert | Wenig persönliche Nähe oder Interesse am Kontakt mit anderen zeigend. |
| 240 | last but not least | ADV | FORMULA | 3 | zu guter Letzt | Einleitung eines letzten, aber ebenfalls wichtigen Punkts. |
| 241 | just wondering | INTJ | FORMULA | 3 | ich frage mich nur | Einleitung einer beiläufigen Frage ohne dringliche Forderung. |
| 242 | no worries | INTJ | FORMULA | 3 | schon gut | Informelle beruhigende Antwort auf eine Entschuldigung oder ein kleines Versehen. |
| 243 | as a matter of fact | ADV | FORMULA | 3 | tatsächlich | Einleitung einer ergänzenden oder korrigierenden Tatsache. |
| 244 | in the same boat | ADJ | IDIOM | 3 | im selben Boot | In derselben schwierigen Lage wie andere. |
| 245 | so be it | INTJ | FORMULA | 3 | dann sei es so | Akzeptanz eines Ergebnisses, das man nicht mehr ändern will oder kann. |
| 246 | that should do it | INTJ | FORMULA | 3 | das dürfte genügen | Einschätzung, dass eine Maßnahme eine Aufgabe ausreichend erledigt. |
| 247 | on good terms | ADJ | IDIOM | 3 | in gutem Verhältnis | Eine freundliche oder konfliktfreie Beziehung zueinander habend. |
| 248 | as luck would have it | ADV | FORMULA | 3 | wie es der Zufall wollte | Einleitung eines zufälligen Umstands, der einen Verlauf beeinflusste. |
| 249 | enjoy yourself | INTJ | FORMULA | 3 | viel Spaß | Wunsch, eine bevorstehende Aktivität angenehm zu erleben. |
| 250 | excuse me | INTJ | FORMULA | 3 | entschuldigen Sie bitte | Höfliche Formel, um Aufmerksamkeit zu erhalten oder vorbeigehen zu können. |
| 251 | reasoning | NOUN | WORD | 3 | Argumentation | Gedanklicher Weg, mit dem man zu einer Schlussfolgerung kommt. |
| 252 | no hard feelings | INTJ | FORMULA | 3 | kein böses Blut | Signal, dass nach einem Konflikt kein persönlicher Groll bleibt. |
| 253 | in the long run | ADV | IDIOM | 3 | auf lange Sicht | Betrachtet über einen längeren Zeitraum statt nur unmittelbar. |
| 254 | straightforward | ADJ | WORD | 3 | unkompliziert | Leicht zu verstehen oder ohne besondere Schwierigkeiten durchzuführen. |
| 255 | let bygones be bygones | INTJ | FORMULA | 3 | lassen wir die Vergangenheit ruhen | Vorschlag, vergangene Konflikte nicht weiter nachzutragen. |
| 256 | from what I gather | ADV | FORMULA | 3 | soweit ich es verstanden habe | Einschränkung auf aus verfügbaren Informationen erschlossenes Wissen. |
| 257 | lively | ADJ | WORD | 3 | lebhaft | Voller Energie, Bewegung oder angeregtem Austausch. |
| 258 | that would be great | INTJ | FORMULA | 3 | das wäre sehr nett | Freundliche Zustimmung zu einem Hilfsangebot. |
| 259 | in practice | ADV | FORMULA | 3 | in der Praxis | Bezogen auf tatsächliche Anwendung statt bloßer Theorie. |
| 260 | anticipation | NOUN | WORD | 3 | gespannte Erwartung | Freudiges oder sorgendes Vorausdenken an etwas Bevorstehendes. |
| 261 | nothing ventured, nothing gained | INTJ | FORMULA | 3 | wer nicht wagt, der nicht gewinnt | Hinweis, dass ein Erfolg oft ein gewisses Risiko voraussetzt. |
| 262 | it's no big deal | INTJ | FORMULA | 3 | das ist keine große Sache | Einschätzung, dass ein Problem oder Ereignis wenig Gewicht hat. |
| 263 | I'll be in touch | INTJ | FORMULA | 3 | ich melde mich | Ankündigung, später wieder Kontakt aufzunehmen. |
| 264 | let me put it this way | INTJ | FORMULA | 3 | ich drücke es einmal so aus | Einleitung einer alternativen Erklärung. |
| 265 | thanks for having me | INTJ | FORMULA | 3 | danke für die Einladung | Dank für Gastfreundschaft oder die Möglichkeit, als Gast teilzunehmen. |
| 266 | I owe you one | INTJ | FORMULA | 3 | ich schulde dir einen Gefallen | Informelle Zusage, erhaltene Hilfe später zu erwidern. |
| 267 | otherwise | ADV | WORD | 4 | andernfalls | Wenn die genannte Bedingung nicht erfüllt wird. |
| 268 | why not | INTJ | FORMULA | 4 | warum eigentlich nicht | Ungezwungene Zustimmung zu einem Vorschlag. |
| 269 | let the cat out of the bag | VERB | IDIOM | 4 | ein Geheimnis ausplaudern | Eine bis dahin geheim gehaltene Information unbeabsichtigt verraten. |
| 270 | resolve | NOUN | WORD | 4 | Entschlossenheit | Fester Wille, eine schwierige Handlung durchzuführen. |
| 271 | as I was saying | ADV | FORMULA | 4 | wie ich gerade sagte | Rückkehr zu einem unterbrochenen Gedankengang. |
| 272 | a can of worms | NOUN | IDIOM | 4 | ein Wespennest | Eine Angelegenheit, deren Behandlung zahlreiche neue Probleme auslöst. |
| 273 | undoubtedly | ADV | WORD | 4 | zweifellos | Mit großer Sicherheit und ohne vernünftigen Zweifel. |
| 274 | how's it going | INTJ | FORMULA | 4 | wie läuft's | Informelle Frage nach dem allgemeinen Befinden oder Verlauf. |
| 275 | over the moon | ADJ | IDIOM | 4 | überglücklich | Außerordentlich glücklich über ein Ereignis. |
| 276 | willing | ADJ | WORD | 4 | bereit | Eine Handlung freiwillig und ohne grundsätzlichen Widerstand tun wollend. |
| 277 | leave it to me | INTJ | FORMULA | 4 | überlass das mir | Angebot, die Verantwortung für eine Aufgabe zu übernehmen. |
| 278 | cross the line | VERB | IDIOM | 4 | zu weit gehen | Durch Verhalten eine Grenze des Akzeptablen überschreiten. |
| 279 | subsequently | ADV | WORD | 4 | anschließend | Nach dem genannten Ereignis zu einem späteren Zeitpunkt. |
| 280 | be my guest | INTJ | FORMULA | 4 | nur zu | Freundliche Erlaubnis, etwas Gewünschtes zu tun oder zu benutzen. |
| 281 | return the favor | VERB | IDIOM | 4 | sich revanchieren | Eine erhaltene freundliche Hilfe durch eigene Hilfe erwidern. |
| 282 | dissent | NOUN | WORD | 4 | Widerspruch | Ausdrücklich abweichende Meinung gegenüber einer gemeinsamen Position. |
| 283 | what a shame | INTJ | FORMULA | 4 | wie schade | Ausdruck von Bedauern über etwas Unerfreuliches. |
| 284 | leave well alone | VERB | IDIOM | 4 | etwas so lassen, wie es ist | Auf unnötige Eingriffe verzichten, die eine gute Situation verschlechtern könnten. |
| 285 | hurdle | NOUN | WORD | 4 | Hürde | Eine Schwierigkeit, die vor dem Erreichen eines Ziels überwunden werden muss. |
| 286 | I didn't mean it that way | INTJ | FORMULA | 4 | so habe ich das nicht gemeint | Klarstellung, dass eine Äußerung anders verstanden wurde als beabsichtigt. |
| 287 | go in one ear and out the other | VERB | IDIOM | 4 | nicht hängen bleiben | Gehörtes sofort wieder vergessen, statt es zu behalten. |
| 288 | sociable | ADJ | WORD | 4 | kontaktfreudig | Gern mit anderen Menschen zusammenkommend und sprechend. |
| 289 | please do | INTJ | FORMULA | 4 | gern, nur zu | Freundliche Zustimmung zu einer angekündigten oder erbetenen Handlung. |
| 290 | take sides | VERB | IDIOM | 4 | Partei ergreifen | In einem Konflikt eine beteiligte Seite unterstützen. |
| 291 | excitement | NOUN | WORD | 4 | Aufregung | Freudig gespannte Erwartung oder lebhafte Begeisterung. |
| 292 | I'll think about it | INTJ | FORMULA | 4 | ich werde darüber nachdenken | Antwort, die eine Entscheidung bis nach weiterer Überlegung offenlässt. |
| 293 | between a rock and a hard place | ADJ | IDIOM | 4 | in einer Zwickmühle | Zwischen zwei gleichermaßen ungünstigen Möglichkeiten stehend. |
| 294 | loyalty | NOUN | WORD | 4 | Treue | Beständige Unterstützung einer Person oder Verbindung. |
| 295 | in any case | ADV | FORMULA | 4 | jedenfalls | Rückkehr zu einer Aussage, die unabhängig von Einzelheiten gilt. |
| 296 | break the ice | VERB | IDIOM | 4 | das Eis brechen | Anfängliche Befangenheit zwischen Menschen durch Kontakt oder Gespräch lösen. |
| 297 | gracious | ADJ | WORD | 4 | liebenswürdig | Freundlich und großzügig im Umgang, auch in schwierigen Situationen. |
| 298 | if you ask me | ADV | FORMULA | 4 | wenn du mich fragst | Informelle Einleitung einer persönlichen Meinung. |
| 299 | in high spirits | ADJ | IDIOM | 4 | gut gelaunt | In fröhlicher und zuversichtlicher Stimmung. |
| 300 | dilemma | NOUN | WORD | 4 | Zwickmühle | Situation, in der man zwischen schwierigen Möglichkeiten wählen muss. |
| 301 | what's the catch | INTJ | FORMULA | 4 | wo ist der Haken | Frage nach einem versteckten Nachteil eines verlockenden Angebots. |
| 302 | a shoulder to cry on | NOUN | IDIOM | 4 | ein verständnisvoller Zuhörer | Eine Person, bei der man Trost und Mitgefühl finden kann. |
| 303 | gist | NOUN | WORD | 4 | Kernaussage | Die grundlegende Bedeutung einer Äußerung ohne alle Einzelheiten. |
| 304 | small world | INTJ | FORMULA | 4 | die Welt ist klein | Reaktion auf eine unerwartete Verbindung zwischen Menschen oder Orten. |
| 305 | with open arms | ADV | IDIOM | 4 | mit offenen Armen | Jemanden besonders herzlich und vorbehaltlos empfangen. |
| 306 | debatable | ADJ | WORD | 4 | diskutabel | Nicht eindeutig richtig, sondern mit guten Gründen bestreitbar. |
| 307 | just my luck | INTJ | FORMULA | 4 | typisch mein Pech | Ironische Reaktion auf eine erneut ungünstige Entwicklung. |
| 308 | burn bridges | VERB | IDIOM | 4 | Brücken abbrechen | Durch eigenes Handeln eine spätere Rückkehr oder Versöhnung erschweren. |
| 309 | nuisance | NOUN | WORD | 4 | Ärgernis | Eine Person oder Sache, die lästige Störungen verursacht. |
| 310 | you can count on me | INTJ | FORMULA | 4 | du kannst dich auf mich verlassen | Persönliche Zusicherung verlässlicher Hilfe. |
| 311 | the bottom line | NOUN | IDIOM | 4 | der entscheidende Punkt | Die wichtigste abschließende Aussage einer Betrachtung. |
| 312 | nickname | NOUN | WORD | 4 | Spitzname | Informeller Name, der anstelle des eigentlichen Namens verwendet wird. |
| 313 | sorry to bother you | INTJ | FORMULA | 4 | entschuldige die Störung | Entschuldigung vor einer Unterbrechung oder Bitte um Aufmerksamkeit. |
| 314 | go against the grain | VERB | IDIOM | 4 | widerstreben | Den eigenen Überzeugungen oder natürlichen Neigungen widersprechen. |
| 315 | delight | NOUN | WORD | 4 | große Freude | Starkes freudiges Vergnügen an etwas. |
| 316 | if all goes well | INTJ | FORMULA | 4 | wenn alles gut läuft | Einschränkung einer Planung auf einen günstigen Verlauf. |
| 317 | make ends meet | VERB | IDIOM | 4 | über die Runden kommen | Mit dem vorhandenen Geld die notwendigen Ausgaben decken können. |
| 318 | selfless | ADJ | WORD | 4 | uneigennützig | Das Wohl anderer über den eigenen Vorteil stellend. |
| 319 | then again | ADV | FORMULA | 4 | andererseits | Einleitung eines Gegenarguments zur eigenen vorherigen Aussage. |
| 320 | the life of the party | NOUN | IDIOM | 4 | der Mittelpunkt der Feier | Eine Person, die eine gesellige Runde besonders unterhält und belebt. |
| 321 | modest | ADJ | WORD | 4 | bescheiden | Eigene Leistungen oder Ansprüche nicht übermäßig hervorhebend. |
| 322 | exactly right | INTJ | FORMULA | 4 | genau richtig | Betonte Bestätigung, dass eine Aussage zutrifft. |
| 323 | keep a straight face | VERB | IDIOM | 4 | ernst bleiben | Nicht lachen, obwohl eine Situation komisch wirkt. |
| 324 | one step at a time | INTJ | FORMULA | 4 | eins nach dem anderen | Empfehlung, eine größere Aufgabe in kleinen Schritten anzugehen. |
| 325 | here goes nothing | INTJ | FORMULA | 4 | jetzt probiere ich es einfach | Ausruf vor einem Versuch mit unsicherem Ausgang. |
| 326 | nothing personal | INTJ | FORMULA | 4 | das ist nicht persönlich gemeint | Klarstellung, dass eine Entscheidung nicht gegen die Person gerichtet ist. |
| 327 | to sum up | ADV | FORMULA | 4 | zusammenfassend | Einleitung einer knappen Zusammenfassung des bisher Gesagten. |
| 328 | what brings you here | INTJ | FORMULA | 4 | was führt dich hierher | Freundliche Frage nach dem Anlass eines Besuchs oder Aufenthalts. |
| 329 | much appreciated | INTJ | FORMULA | 4 | vielen Dank dafür | Knapp ausgedrückte große Wertschätzung für eine Hilfe oder Leistung. |
| 330 | objective | ADJ | WORD | 4 | objektiv | Bei einer Beurteilung möglichst unabhängig von persönlichen Vorlieben. |
| 331 | it serves you right | INTJ | FORMULA | 4 | das geschieht dir recht | Wertende Reaktion, dass jemand die Folgen eigenen Fehlverhaltens verdient. |
| 332 | sooner or later | ADV | IDIOM | 4 | früher oder später | Zu einem noch unbestimmten Zeitpunkt, aber voraussichtlich unvermeidlich. |
| 333 | shortcut | NOUN | WORD | 4 | Abkürzung | Eine Vorgehensweise, mit der man weniger Zeit oder Aufwand benötigt. |
| 334 | all the best | INTJ | FORMULA | 4 | alles Gute | Allgemeiner guter Wunsch beim Abschied oder für ein Vorhaben. |
| 335 | believe it or not | ADV | FORMULA | 4 | ob du es glaubst oder nicht | Vorbereitung auf eine überraschende, aber als wahr behauptete Mitteilung. |
| 336 | likewise | ADV | WORD | 4 | ebenso | In gleicher Weise, auch als Erwiderung eines freundlichen Wunsches. |
| 337 | not at all | INTJ | FORMULA | 4 | überhaupt nicht | Betonte Verneinung, dass eine erfragte Sache zutrifft oder stört. |
| 338 | that makes sense | INTJ | FORMULA | 4 | das leuchtet ein | Bestätigung, dass eine Erklärung logisch oder verständlich ist. |
| 339 | irritable | ADJ | WORD | 4 | reizbar | Leicht ärgerlich werdend oder gereizt reagierend. |
| 340 | whatever happens | INTJ | FORMULA | 4 | was auch geschieht | Kennzeichnung einer Zusage oder Haltung als unabhängig vom Verlauf. |
| 341 | messy | ADJ | WORD | 4 | unordentlich | Nicht ordentlich angeordnet oder mit Schmutz verbunden. |
| 342 | frank | ADJ | WORD | 4 | offen | Eigene Meinung ehrlich und ohne Beschönigung aussprechend. |
| 343 | as far as I know | ADV | FORMULA | 4 | soweit ich weiß | Einschränkung auf den eigenen Wissensstand. |
| 344 | for old times' sake | ADV | IDIOM | 4 | der alten Zeiten wegen | Um gemeinsame frühere Erlebnisse oder eine frühere Verbindung zu würdigen. |
| 345 | take your time | INTJ | FORMULA | 4 | lass dir Zeit | Hinweis, dass kein Zeitdruck besteht und man ruhig vorgehen kann. |
| 346 | that's beside the point | INTJ | FORMULA | 4 | das tut nichts zur Sache | Hinweis, dass ein Argument für die aktuelle Frage nicht relevant ist. |
| 347 | bless you | INTJ | FORMULA | 4 | Gesundheit | Freundliche Reaktion auf das Niesen einer Person. |
| 348 | better safe than sorry | INTJ | FORMULA | 4 | lieber vorsichtig als später bereuen | Empfehlung, eine Vorsichtsmaßnahme einem vermeidbaren Schaden vorzuziehen. |
| 349 | let's start again | INTJ | FORMULA | 4 | fangen wir noch einmal an | Vorschlag, einen misslungenen Ablauf neu zu beginnen. |
| 350 | don't be a stranger | INTJ | FORMULA | 4 | lass dich mal wieder sehen | Informeller Abschied mit dem Wunsch nach künftigem Kontakt. |
| 351 | that's another story | INTJ | FORMULA | 4 | das ist eine andere Geschichte | Hinweis, dass ein Thema eine gesonderte Erklärung erfordert. |
| 352 | safe travels | INTJ | FORMULA | 4 | gute Reise | Abschiedsgruß mit dem Wunsch nach einer sicheren Reise. |
| 353 | forgive me | INTJ | FORMULA | 4 | verzeih mir | Bitte um Vergebung für eigenes Fehlverhalten. |
| 354 | to some extent | ADV | FORMULA | 4 | in gewissem Maße | Ausdruck einer begrenzten, nicht vollständigen Geltung. |
| 355 | presumably | ADV | WORD | 5 | vermutlich | Aufgrund einer naheliegenden Annahme, ohne vollständige Sicherheit. |
| 356 | these things happen | INTJ | FORMULA | 5 | so etwas kommt vor | Beruhigende Reaktion auf einen gewöhnlichen Fehler oder Missgeschick. |
| 357 | spill the beans | VERB | IDIOM | 5 | auspacken | Eine vertrauliche Information preisgeben. |
| 358 | hesitation | NOUN | WORD | 5 | Zögern | Kurzes Innehalten vor einer Handlung wegen Unsicherheit. |
| 359 | to cut a long story short | ADV | FORMULA | 5 | kurz gesagt | Einleitung einer stark verkürzten Zusammenfassung längerer Ereignisse. |
| 360 | a vicious circle | NOUN | IDIOM | 5 | ein Teufelskreis | Ein Ablauf, bei dem ein Problem sich durch seine Folgen immer weiter verstärkt. |
| 361 | instead | ADV | WORD | 5 | stattdessen | Als Ersatz für eine zuvor genannte Möglichkeit. |
| 362 | what's new | INTJ | FORMULA | 5 | was gibt's Neues | Gesprächseinstieg mit einer Frage nach Neuigkeiten. |
| 363 | on the same page | ADJ | IDIOM | 5 | auf demselben Stand | In Verständnis oder Zielsetzung mit anderen übereinstimmend. |
| 364 | adamant | ADJ | WORD | 5 | unbeirrbar | Fest auf einer Meinung oder Entscheidung bestehend. |
| 365 | it's worth a try | INTJ | FORMULA | 5 | ein Versuch lohnt sich | Einschätzung, dass ein Versuch trotz unsicherem Erfolg sinnvoll ist. |
| 366 | hold a grudge | VERB | IDIOM | 5 | Groll hegen | Eine Kränkung über längere Zeit nicht verzeihen. |
| 367 | essentially | ADV | WORD | 5 | im Wesentlichen | Auf die entscheidenden Merkmale beschränkt betrachtet. |
| 368 | after you | INTJ | FORMULA | 5 | nach dir | Höfliche Aufforderung, zuerst zu gehen oder etwas zu tun. |
| 369 | beat around the bush | VERB | IDIOM | 5 | um den heißen Brei herumreden | Das eigentliche Thema indirekt ansprechen oder vermeiden. |
| 370 | relief | NOUN | WORD | 5 | Erleichterung | Angenehmes Gefühl, wenn eine Belastung oder Sorge nachlässt. |
| 371 | it's up to you | INTJ | FORMULA | 5 | du entscheidest | Hinweis, dass die andere Person die Entscheidung treffen darf. |
| 372 | out of the woods | ADJ | IDIOM | 5 | über den Berg | Die gefährlichste oder schwierigste Phase einer Lage überwunden habend. |
| 373 | trustworthiness | NOUN | WORD | 5 | Vertrauenswürdigkeit | Eigenschaft, auf die man sich ehrlich und zuverlässig verlassen kann. |
| 374 | all things considered | ADV | FORMULA | 5 | alles in allem | Einleitung einer abschließenden Beurteilung nach umfassender Abwägung. |
| 375 | a familiar face | NOUN | IDIOM | 5 | ein bekanntes Gesicht | Eine Person, die man in einer Umgebung wiedererkennt. |
| 376 | gratitude | NOUN | WORD | 5 | Dankbarkeit | Gefühl der Anerkennung für erhaltene Hilfe oder Freundlichkeit. |
| 377 | in my opinion | ADV | FORMULA | 5 | meiner Meinung nach | Kennzeichnung einer folgenden Aussage als persönliche Einschätzung. |
| 378 | down in the dumps | ADJ | IDIOM | 5 | niedergeschlagen | In gedrückter, trauriger Stimmung. |
| 379 | alternative | NOUN | WORD | 5 | Alternative | Eine andere Möglichkeit, die anstelle einer gewählten Option infrage kommt. |
| 380 | back to square one | INTJ | FORMULA | 5 | wieder ganz am Anfang | Feststellung, nach einem Rückschlag von vorn beginnen zu müssen. |
| 381 | clear the air | VERB | IDIOM | 5 | Spannungen ausräumen | Durch offene Aussprache Missverständnisse oder Konflikte beseitigen. |
| 382 | briefly | ADV | WORD | 5 | kurz | In wenigen Worten oder während kurzer Zeit. |
| 383 | same as usual | INTJ | FORMULA | 5 | wie immer | Antwort, dass sich am üblichen Zustand nichts Wesentliches geändert hat. |
| 384 | on the house | ADV | IDIOM | 5 | aufs Haus | Ohne Berechnung vom Anbieter spendiert. |
| 385 | viewpoint | NOUN | WORD | 5 | Standpunkt | Perspektive, aus der jemand eine Sache beurteilt. |
| 386 | no kidding | INTJ | FORMULA | 5 | das ist ja unglaublich | Informelle Reaktion von Überraschung auf eine Mitteilung. |
| 387 | take the plunge | VERB | IDIOM | 5 | den entscheidenden Schritt wagen | Nach Zögern eine riskante oder wichtige Handlung beginnen. |
| 388 | setback | NOUN | WORD | 5 | Rückschlag | Ein Ereignis, das Fortschritte verzögert oder erschwert. |
| 389 | that's none of your business | INTJ | FORMULA | 5 | das geht dich nichts an | Deutliche Abwehr einer als zu persönlich empfundenen Frage. |
| 390 | keep a low profile | VERB | IDIOM | 5 | sich bedeckt halten | Möglichst wenig Aufmerksamkeit auf die eigene Person lenken. |
| 391 | approachable | ADJ | WORD | 5 | zugänglich | Auf andere freundlich wirkend, sodass man leicht Kontakt aufnehmen kann. |
| 392 | if you don't mind | INTJ | FORMULA | 5 | wenn es dir nichts ausmacht | Höflicher Zusatz zu einer Bitte, der Rücksicht auf die andere Person ausdrückt. |
| 393 | strike a chord | VERB | IDIOM | 5 | Anklang finden | Eine starke zustimmende oder persönliche Reaktion auslösen. |
| 394 | amazement | NOUN | WORD | 5 | Verblüffung | Großes Staunen über etwas Unerwartetes. |
| 395 | let me sleep on it | INTJ | FORMULA | 5 | lass mich eine Nacht darüber schlafen | Bitte um Bedenkzeit bis zum nächsten Tag. |
| 396 | weather the storm | VERB | IDIOM | 5 | eine Krise überstehen | Eine schwierige Phase aushalten, ohne dauerhaft daran zu scheitern. |
| 397 | bossy | ADJ | WORD | 5 | herrisch | Anderen häufig auf unangenehme Weise Vorschriften machend. |
| 398 | what's more | ADV | FORMULA | 5 | darüber hinaus | Einleitung einer zusätzlichen, oft verstärkenden Information. |
| 399 | once in a blue moon | ADV | IDIOM | 5 | alle Jubeljahre | Sehr selten und in großen zeitlichen Abständen. |
| 400 | discretion | NOUN | WORD | 5 | Diskretion | Vorsichtiger vertraulicher Umgang mit persönlichen Informationen. |
| 401 | you have a point | INTJ | FORMULA | 5 | da ist etwas dran | Anerkennung, dass ein vorgebrachtes Argument berechtigt ist. |
| 402 | a bundle of nerves | NOUN | IDIOM | 5 | ein Nervenbündel | Eine sehr nervöse oder besorgte Person. |
| 403 | when in doubt | INTJ | FORMULA | 5 | im Zweifelsfall | Einleitung einer Empfehlung für eine unsichere Situation. |
| 404 | there you go | INTJ | FORMULA | 5 | so, bitte schön | Ausspruch beim Überreichen von etwas oder nach erledigter Hilfe. |
| 405 | a fair-weather friend | NOUN | IDIOM | 5 | ein Schönwetterfreund | Eine Person, die nur in guten Zeiten Freundschaft zeigt. |
| 406 | on the one hand | ADV | FORMULA | 5 | einerseits | Einleitung der ersten Seite einer Abwägung. |
| 407 | how do you know each other | INTJ | FORMULA | 5 | woher kennt ihr euch | Frage nach dem Ursprung der Bekanntschaft zwischen anderen Personen. |
| 408 | sorry to interrupt | INTJ | FORMULA | 5 | entschuldige die Unterbrechung | Höfliche Entschuldigung, wenn man in ein laufendes Gespräch eingreift. |
| 409 | skeptical | ADJ | WORD | 5 | skeptisch | Nicht ohne Weiteres von der Wahrheit oder Güte einer Sache überzeugt. |
| 410 | lucky you | INTJ | FORMULA | 5 | du hast es gut | Reaktion auf einen glücklichen Umstand bei der anderen Person. |
| 411 | draw the line | VERB | IDIOM | 5 | eine Grenze ziehen | Festlegen, welches Verhalten oder welcher Aufwand nicht mehr akzeptabel ist. |
| 412 | mix-up | NOUN | WORD | 5 | Verwechslung | Durcheinander durch falsche Zuordnung von Personen oder Dingen. |
| 413 | that's not fair | INTJ | FORMULA | 5 | das ist nicht gerecht | Widerspruch gegen eine als ungerecht empfundene Behandlung. |
| 414 | in black and white | ADV | IDIOM | 5 | schwarz auf weiß | In schriftlicher, eindeutig nachlesbarer Form. |
| 415 | icebreaker | NOUN | WORD | 5 | Gesprächsöffner | Bemerkung oder Aktivität, die anfängliche Befangenheit zwischen Menschen löst. |
| 416 | you're welcome | INTJ | FORMULA | 5 | gern geschehen | Freundliche Antwort auf einen Dank. |
| 417 | I doubt it | INTJ | FORMULA | 5 | das bezweifle ich | Ausdruck, dass man eine Behauptung für wahrscheinlich falsch hält. |
| 418 | touchy | ADJ | WORD | 5 | empfindlich | Bei bestimmten Bemerkungen leicht beleidigt oder verärgert. |
| 419 | first things first | INTJ | FORMULA | 5 | das Wichtigste zuerst | Hinweis, zuerst eine grundlegende oder dringliche Aufgabe zu erledigen. |
| 420 | remedy | NOUN | WORD | 5 | Abhilfe | Eine Maßnahme, die einen Fehler oder Missstand beseitigen soll. |
| 421 | let's call it even | INTJ | FORMULA | 5 | jetzt sind wir quitt | Vorschlag, gegenseitige Ansprüche als ausgeglichen zu betrachten. |
| 422 | to be fair | ADV | FORMULA | 5 | fairerweise | Einleitung eines Gesichtspunkts, der eine einseitige Beurteilung ausgleicht. |
| 423 | at the crack of dawn | ADV | IDIOM | 5 | in aller Frühe | Sehr früh am Morgen, etwa bei Tagesanbruch. |
| 424 | with pleasure | INTJ | FORMULA | 5 | sehr gern | Bereitschaft, eine erbetene Handlung gern auszuführen. |
| 425 | to each their own | INTJ | FORMULA | 5 | jedem das Seine | Anerkennung, dass Menschen unterschiedliche Vorlieben haben dürfen. |
| 426 | burst into tears | VERB | IDIOM | 5 | in Tränen ausbrechen | Plötzlich zu weinen beginnen. |
| 427 | all in good time | INTJ | FORMULA | 5 | alles zu seiner Zeit | Beruhigender Hinweis, dass etwas zum passenden Zeitpunkt erfolgen wird. |
| 428 | don't make a fuss | INTJ | FORMULA | 5 | mach kein Aufhebens | Aufforderung, nicht übermäßig auf eine kleine Sache zu reagieren. |
| 429 | don't get me wrong | INTJ | FORMULA | 5 | versteh mich nicht falsch | Einleitung einer Klarstellung, um eine Fehlinterpretation zu vermeiden. |
| 430 | as far as I can tell | ADV | FORMULA | 5 | soweit ich erkennen kann | Einschränkung auf die eigene Beobachtung oder Beurteilung. |
| 431 | sleep tight | INTJ | FORMULA | 5 | schlaf gut | Vertrauter Wunsch nach gutem ruhigem Schlaf. |
| 432 | whenever you're ready | INTJ | FORMULA | 5 | sobald du bereit bist | Signal, dass die andere Person den Beginn selbst bestimmen kann. |
| 433 | assumption | NOUN | WORD | 5 | Annahme | Etwas, das ohne vollständigen Beweis als wahr vorausgesetzt wird. |
| 434 | what a mess | INTJ | FORMULA | 5 | was für ein Durcheinander | Reaktion auf eine ungeordnete oder misslungene Situation. |
| 435 | turn over a new leaf | VERB | IDIOM | 5 | einen Neuanfang machen | Sich entschließen, künftig anders und besser zu handeln. |
| 436 | fussy | ADJ | WORD | 5 | wählerisch | Bei kleinen Einzelheiten sehr anspruchsvoll oder schwer zufriedenzustellen. |
| 437 | just between you and me | INTJ | FORMULA | 5 | unter uns gesagt | Hinweis, dass eine Mitteilung vertraulich bleiben soll. |
| 438 | that's a different matter | INTJ | FORMULA | 5 | das ist eine andere Sache | Abgrenzung eines neuen Punkts vom bisher besprochenen Thema. |
| 439 | gossip | NOUN | WORD | 5 | Klatsch | Informelle Gespräche über persönliche Angelegenheiten anderer. |
| 440 | my apologies | INTJ | FORMULA | 5 | meine Entschuldigung | Formelle knappe Entschuldigung für einen Fehler oder ein Versäumnis. |
| 441 | strictly speaking | ADV | FORMULA | 5 | streng genommen | Kennzeichnung einer Aussage, die besonders genaue Begriffsverwendung voraussetzt. |
| 442 | better luck next time | INTJ | FORMULA | 5 | beim nächsten Mal mehr Glück | Tröstender Wunsch nach einem Misserfolg. |

## Vollständige Ausschluss-/Zurückstellungsliste

Kollidierende Ref oder redaktioneller Vergleich werden ausdrücklich genannt; reine Textähnlichkeit ist kein sicherer semantischer Konflikt. Keine Aussage, alle zurückgestellten Wörter seien selten oder ungebräuchlich. `overwhelmed` wurde wegen des breiten gemischten Gefühls-/Überforderungsumfangs zugunsten klarer abgegrenzter Ziele zurückgestellt; kein offener Konflikt in der Auswahl.

| Kandidat | Grund | Bestands-/Vergleichsreferenz |
|---|---|---|
| outgoing | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | outgoing\|outgoing/ADJ\|outgoing#kontaktfreudig |
| what a coincidence | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | small world\|small world/INTJ\|small-world#die-welt-ist-klein |
| say hello to everyone | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| every now and then | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | from time to time\|from time to time/ADV\|from-time-to-time#von-zeit-zu-zeit |
| bright and early | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| thoughtful | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | thoughtful\|thoughtful/ADJ\|thoughtful#nachdenklich |
| grateful | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | grateful\|grateful/ADJ\|grateful#dankbar |
| gesture | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | gesture\|gesture/NOUN\|gesture#geste |
| favor | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | favour\|favour/NOUN\|favour#gefallen |
| thanks in advance | Verbalphrasen bzw. formeller Fach-/Korrespondenzgebrauch überwiegend späterem Stapel überlassen. | Redaktionelle Abgrenzung |
| ladies first | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| no rush | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | take your time\|take your time/INTJ\|take-your-time#lass-dir-zeit |
| don't mention it | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | you're welcome\|you're welcome/INTJ\|you-re-welcome#gern-geschehen |
| out of courtesy | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| swallow pride | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| consensus | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | agreement\|agreement/NOUN\|agreement#einigkeit |
| debatably | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| evidence | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | evidence\|evidence/NOUN\|evidence#belegmaterial |
| that's debatable | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | debatable\|debatable/ADJ\|debatable#diskutabel |
| that depends | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | it depends on the circumstances\|it depends on the circumstances/INTJ\|it-depends-on-the-circumstances#es-hangt-von-den-umstanden-ab |
| on balance | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | all things considered\|all things considered/ADV\|all-things-considered#alles-in-allem |
| by and large | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | generally speaking\|generally speaking/ADV\|generally-speaking#im-allgemeinen |
| overwhelmed | Breiter Gefühls-/Überforderungsumfang zurückgestellt; enger abgegrenzte Reaktionen priorisiert. | overwhelmed\|overwhelmed/ADJ\|overwhelmed#uberfordert |
| astonished | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | amazement\|amazement/NOUN\|amazement#verbluffung |
| what a pity | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | what a shame\|what a shame/INTJ\|what-a-shame#wie-schade |
| that's a shame | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | what a shame\|what a shame/INTJ\|what-a-shame#wie-schade |
| that's a relief | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | what a relief\|what a relief/INTJ\|what-a-relief#was-fur-eine-erleichterung |
| hang in there | Verbalphrasen bzw. formeller Fach-/Korrespondenzgebrauch überwiegend späterem Stapel überlassen. | Redaktionelle Abgrenzung |
| on cloud nine | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | over the moon\|over the moon/ADJ\|over-the-moon#uberglucklich |
| beside oneself | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| a weight off the mind | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| intention | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | intention\|intention/NOUN\|intention#absicht |
| priority | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | priority\|priority/NOUN\|priority#vorrang |
| preference | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | preference\|preference/NOUN\|preference#vorliebe |
| the choice is yours | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | it's up to you\|it's up to you/INTJ\|it-s-up-to-you#du-entscheidest |
| make up one's mind | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| cross that bridge when we come to it | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| stick to the plan | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| loophole | Verbalphrasen bzw. formeller Fach-/Korrespondenzgebrauch überwiegend späterem Stapel überlassen. | Redaktionelle Abgrenzung |
| misunderstanding | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | misunderstanding\|misunderstanding/NOUN\|misunderstanding#missverstandnis |
| workaround | Verbalphrasen bzw. formeller Fach-/Korrespondenzgebrauch überwiegend späterem Stapel überlassen. | Redaktionelle Abgrenzung |
| my fault | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| hold on a second | Verbalphrasen bzw. formeller Fach-/Korrespondenzgebrauch überwiegend späterem Stapel überlassen. | Redaktionelle Abgrenzung |
| one thing at a time | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | one step at a time\|one step at a time/INTJ\|one-step-at-a-time#eins-nach-dem-anderen |
| by the skin of one's teeth | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| get to the bottom of it | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| nip it in the bud | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| sweep it under the carpet | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| empathy | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | empathy\|empathy/NOUN\|empathy#einfuhlungsvermogen |
| sympathy | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | sympathy\|sympathy/NOUN\|sympathy#mitgefuhl |
| grudge | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | grudge\|grudge/NOUN\|grudge#groll |
| courteousness | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | courtesy\|courtesy/NOUN\|courtesy#hoflichkeit |
| reliable | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | reliable\|reliable/ADJ\|reliable#zuverlaessige |
| dependable | Bereits bestätigte satzgebundene Bestandsalternative; nicht zusätzlich reservieren. | Redaktionelle Abgrenzung |
| selfish | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | selfish\|selfish/ADJ\|selfish#egoistisch |
| stubborn | Vorhandene besessene Oberfläche oder Besitzalias; kein zweiter normaler Lernkopf. | stubborn\|stubborn/ADJ\|stubborn#stur |
| I can relate | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| I know how you feel | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| put yourself in my shoes | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| give my regards | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| give the benefit of the doubt | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| give the cold shoulder | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| hit it off | Verbalphrasen bzw. formeller Fach-/Korrespondenzgebrauch überwiegend späterem Stapel überlassen. | Redaktionelle Abgrenzung |
| break a promise | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| keep a promise | Zusätzliche wörtliche Schablone, nahe Wiederholung oder engere Variante nicht als eigenständigen Kopf priorisieren. | Redaktionelle Abgrenzung |
| take for granted | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| wear out one's welcome | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| be there for someone | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| nonetheless | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | nevertheless\|nevertheless/ADV\|nevertheless#dennoch |
| likewise | Doppelte Kandidatenoberfläche. | Redaktionelle Abgrenzung |
| roughly | Bereits bestätigte satzgebundene Bestandsalternative; nicht zusätzlich reservieren. | Redaktionelle Abgrenzung |
| long story short | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | to cut a long story short\|to cut a long story short/ADV\|to-cut-a-long-story-short#kurz-gesagt |
| for example | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | for instance\|for instance/ADV\|for-instance#zum-beispiel |
| at any rate | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | in any case\|in any case/ADV\|in-any-case#jedenfalls |
| on the whole | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | all things considered\|all things considered/ADV\|all-things-considered#alles-in-allem |
| to tell the truth | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | to be honest\|to be honest/ADV\|to-be-honest#ehrlich-gesagt |
| what was I saying | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | where was I\|where was I/INTJ\|where-was-i#wo-war-ich-stehen-geblieben |
| hear it through the grapevine | Variable/offene Stelle, unnatürliche verkürzte Oberfläche oder ungeeigneter Kandidat; nicht durch feste Schreibweise retten. | Redaktionelle Abgrenzung |
| talk nineteen to the dozen | Expliziter redaktioneller Varianten-/Überschneidungsentscheid; kein zweites Ziel für dieselbe Lernabsicht. | talk a mile a minute\|talk a mile a minute/VERB\|talk-a-mile-a-minute#reden-wie-ein-wasserfall |
| off the record | Verbalphrasen bzw. formeller Fach-/Korrespondenzgebrauch überwiegend späterem Stapel überlassen. | Redaktionelle Abgrenzung |

Nächste Aktion: **die geprüfte Batch-1-ZIP im Chat hochladen und 89 aktuelle Lernziele redigieren**. 353 spätere Ziele bleiben im eingefrorenen Kontext, sind noch kein Satzauftrag. Keine öffentliche Inhaltsfreigabe, keine bereits erfolgte Satzvalidierung behauptet.

Vollständiger ZIP-Pfad: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/alltagssprache_redewendungen_authoring_batch_1.zip`.
