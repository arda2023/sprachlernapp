# Unregelmäßige Verben – Batch 2

## Lieferung
83 neue Satzpaare, 826 Tokenpositionen (738 Wörter/Genitivmarker, 88 Satzzeichen), neun satzgebundene regionale Varianten. Die 22 Wiederverwendungen erhalten keine neuen Sätze. Metadaten: exakt 105 aktuelle Formziele und 35 neue lexikalische Zuordnungen; 83 neue Karten, kein Eingriff in vorhandene Identitäten.

Dateien: `editorial_content_v3.json` für den bestehenden V3-Importer; `satzuebersicht.html` zum Lesen; `token_review.json` für sämtliche Wortbindungen; `validation_report.json` für tatsächlich ausgeführte Lieferprüfungen; `IMPORT_PROMPT.txt` für Codex im Repository. `manifest.json` bindet die Lieferdateien per SHA256.

## Redaktion
Alle 83 englischen Sätze und deutschen Übersetzungen sowie alle 738 Wortbindungen wurden im Chat gegengelesen. Die Zielbedeutung und Formfunktion stammen unverändert aus der Auswahl. Die automatische spaCy-Lemma/POS-Vorhersage wurde bei Bedarf redaktionell korrigiert, ohne Tokenoffsets zu verändern: unter anderem missing, glasses, clothes, has vor leant und die beiden verschiedenen to in s068. Ein bereits vorhandener Sense wird nicht allein wegen einer anderen Verbform neu angelegt.

17 zusätzliche Begleitwortbedeutungen werden ausschließlich fürs Wörterbuch ergänzt, ohne neue Lernkarten oder Wortbesitzer: Benutzerkonto, digitaler Zugriff, Entschuldigung, Verbiegen eines Gegenstands, Gemeinderat, Reitparcours, jemals, Hammer, Metallnagel, Antwort, Schulzeugnis, Boxring, Waschbecken, unfreundlich, Dorfbewohner, Suchgegenstand nach look for und Sportnetz. Bestehende gleiche Bedeutungen werden wiederverwendet, darunter die Brillen-Sense und Partikel-/Präpositionsbindungen.

Neun Varianten wurden wörtlich im jeweiligen Satz geprüft: s028 gotten; s056/s057 kneeled; s067/s068 leaned; s070/s071 leaped; s072/s073 learned. Sie erhalten die vorgegebene Formfunktion und Aussage. `accepted` enthält ausschließlich die Zielform; `valid_alternatives` ist satzgebunden und lernstandsneutral. Keine Vollständigkeitsgarantie für alle denkbaren Alternativen.

Bei lay/lie trennt das Objekt die Bedeutung: lay the towels / laid the baby gegenüber the dog lay / has lain. Hit und let werden durch Modal-/Aufforderungs-, Vergangenheits- bzw. Perfect-Kontext getrennt. Got in s028 beschreibt den Erhalt einer Hotelantwort; gotten ist die amerikanische Partizipvariante für genau diesen Kontext.

## Tatsächliche Prüfungen
- Eingabe-ZIP: CRCs und alle 77 Manifestdateihashes bestanden.
- V3-JSON-Schema, Basis-/Auswahl-/Registryhash, exakte aktuelle Metadaten bestanden.
- Referenzen, eindeutige neue Wörterbuchschlüssel, vollständige Tokenabdeckung, Offsets, Zielbindung, Review-/Linkhashes bestanden.
- Nachgebildete Regeln des gelieferten Linters: Zielstelle, nur ein Zielvorkommen, höchstens 14 Wörter und ein untergeordneter Teilsatz, Satzende: null Fehler. Zwei Frequenzhinweise: unkind 2,99 und gardener 3,49.
- Quell-SQLite ausschließlich read-only geöffnet: integrity_check ok, 22 Tabellen gezählt. Hier kein vollständiger Zeilenvergleich gegen build_rows.
- Kein archivierter Repository-Code ausgeführt. Kein echter Import, Export, Staging, Flutter-/Gerätetest oder Lernstandzugriff. Keine API-/Modellaufrufe.

Diese Lieferung ist Chat-Redaktion, keine unabhängige menschliche Sprachfreigabe. Der Repository-Import muss seine regulären Validatoren noch ausführen.

## Geerbte Wörterbuchglossen – separat offen
20 konkrete bestehende Wörterbuchschlüssel sind in `inherited_gloss_findings.json` mit Satzreferenzen dokumentiert. Beispielsweise zeigt heard noch „hörten“, hit nur „schlug; schlugen“ und kept „hielt bereit“. Diese Anzeige ist für manche neuen Kontexte unvollständig oder unpassend. Die vollständigen Satzübersetzungen und Zieldefinitionen dieser Lieferung sind davon getrennt und passend.

Das bestehende Wörterbuch hat genau eine Formglosse pro (Oberfläche, Sense), nicht pro Tempusfunktion. Alte Glossen wurden weder überschrieben noch durch künstliche neue Senses umgangen. Die Vorschläge in der Befunddatei sind nicht angewendet und müssen, falls gewünscht, in einer eigenen versionierten Kurationsoperation über alle betroffenen Bestandskontexte geprüft werden. Dies gilt auch für alte gebundene Glossen wie „Konzert-“ und „Sommer-“. Es wird keine umfassende Glossenbereinigung behauptet.

## Übergabe
ZIP im Projekt entpacken und `IMPORT_PROMPT.txt` an Codex geben. Der Prompt umfasst Prüfung, Import, gesichertes internes Staging und Batch-3-ZIP. Basis ist der in der Eingabe gebundene Pack `irregular_verbs_batch_1_v1`, nicht eine ältere Natur-Version. Nach Import: erwartete Formansichten 68/68/68; Batch-3-Partition 204 importiert / 99 aktuell / 99 später, davon 84 neue Satzaufträge und 15 Wiederverwendungen im aktuellen Batch.
