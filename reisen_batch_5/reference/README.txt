REISEN AUTHORING BATCH 5 – tatsächlicher Stand nach Batch 4 (06.10.2026)
Genau authoring_batch=5, 100 Einträge; nicht IDs 401–500. Keine Sätze erzeugt.
Alle 500 Identitäten und 660 Registry-Wortzeilen unverändert; Auswahlpositionen bleiben original.
31 vorhandene Zielsenses / 69 neue Vorschläge. Bereits vorhandene Begleitwort-Senses wiederverwenden.
Zieldefinitionen und Glossen bleiben aus der Auswahl unverändert; die aktuellen
Bestandsdefinitionen stehen separat im dictionary_context.json.
Neu erkannte vorhandene Senses: traveller, trolley, junction, payment, souvenir, hike, sunset, rent.

Quelle: pipeline/out/reisen_batch_4_v1/pack.json
Packversion: reisen_batch_4_v1, intern, Schema 2
Pack SHA256 Rohbytes: 97015c3c12b9f5e2fb2d900ee9544029189e1f51a3741c1a9100f206dcf5b4d3
Pack SHA256 kanonisch: 4eaba9f14deba0ba136052be7a07ae1cbc55ebfa1a49f72535d60e456b4aeaed
SQLite SHA256: fc04b23eed0150e34690fc06eec7c8518bbfc85739b505d18c0d1792083040f4
Registry: pipeline/data/words/en.reisen_batch_5_v1.json
Registry SHA256 kanonisch: 4148c720b983fe66c01683db760208c7b85cb0a59f98bb5a40ae7d049198f2b4
Registry Parent: 8f1e9307f30639616ba4e1ac757b7e1f5eeeeb72aa1c2c75ec13d791ba3edb33
source_sqlite_sha256 in der Registry ist übernommene historische Metadatenangabe;
source_pack_sha256 bindet an den tatsächlichen neuen Pack. Keine Änderung alter Registrydateien.

CREATE UND POSITIONEN
Nur neue Karten/Sätze/benötigte Wörterbuchzeilen; keinen weiteren Reisen-Stapel anlegen.
Create hängt an Positionen 401–500 an. Danach alle 500 Reisen-Mitgliedschaften nach
combined_display_mapping.json umordnen, ausschließlich deren position-Felder.
Die optionale --display-patch-Unterstützung ist im Projekt jetzt integriert und getestet.
Ein neuer Display-Patch muss an Rohbytehash von Quelle UND konkretem Create sowie
kanonischen Registryhash und vollständige vorherige Deckzeilen gebunden sein.
Das Schema/Validierungen von deck_display.py beachten; Originalpositionen werden gegen
Registry-Snapshot geprüft. Kein Zwischenexport der Append-Reihenfolge.

Genau ein fester Satz je Ziel, accepted nur [form]; Alternativen wörtlich einsetzen.
Artikel außerhalb der Lücke beachten: an plane und at front desk waren Lieferfehler in Batch 2.
Hashgebundene Reviews für Satz, Tokens, Links und konkrete Alternativsätze erforderlich.
Wörterbuchergänzungen erzeugen keine zusätzlichen Lernkarten/Besitzpositionen.

LOKALE UMGEBUNG
spaCy 3.8.16; en_core_web_sm 3.8.0; NER deaktiviert.
Linter max_words=14, max_subclauses=1.
Namenliste, Frequenzgrenzen und weitere reale Parameter: tokenizer_linter_environment.json.
annotate.py/linter.py sind unveränderte Projektkopien; nur tokenize verwenden, keine Cloud-Funktionen.
Modellbinaries nicht enthalten; bestehende Pipelineumgebung nutzen, keine Installation nötig.

SPÄTERER IMPORT, NICHT AUSGEFÜHRT: neue Batch-5-Lieferung zuerst vollständig prüfen.
PowerShell: $env:PYTHONPATH='pipeline/src'; .\pipeline\.venv\Scripts\python.exe -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_4_v1/pack.json --create <GEPRUEFTES_CREATE> --registry pipeline/data/words/en.reisen_batch_5_v1.json --display-patch <GEPRUEFTER_DISPLAY_PATCH> --out <NEUER_ORDNER>
macOS: PYTHONPATH=pipeline/src pipeline/.venv/bin/python -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_4_v1/pack.json --create <GEPRUEFTES_CREATE> --registry pipeline/data/words/en.reisen_batch_5_v1.json --display-patch <GEPRUEFTER_DISPLAY_PATCH> --out <NEUER_ORDNER>
Platzhalter ersetzen; niemals vorhandene out-Ordner überschreiben. Nach SQLite-Abnahme
beide Assets sichern, erst danach stagen und verifizieren. user.db nicht öffnen.
Keine Cloud-Aufrufe, keine öffentliche Inhaltsfreigabe. Redaktion bleibt ChatGPT-Redaktion.
