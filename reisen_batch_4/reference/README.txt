REISEN AUTHORING BATCH 4 – tatsächlicher Stand nach Batch 3 (06.10.2026)
Genau authoring_batch=4, 100 Einträge; nicht IDs 301–400. Keine Sätze erzeugt.
Alle 500 Identitäten und 660 Registry-Wortzeilen unverändert; Auswahlpositionen bleiben original.
34 vorhandene Zielsenses / 66 neue Vorschläge. Bereits vorhandene Begleitwort-Senses wiederverwenden.
Zieldefinitionen und Glossen bleiben aus der Auswahl unverändert; die aktuellen
Bestandsdefinitionen stehen separat im dictionary_context.json.
Neu erkannte vorhandene Senses: route, petrol, shower, toilet, fish, fee, path, sail, board, land, replace.

Quelle: pipeline/out/reisen_batch_3_v1/pack.json
Packversion: reisen_batch_3_v1, intern, Schema 2
Pack SHA256 Rohbytes: 27d2ef97c9a188e7313cdb7e12b84336f37266f0cca865d1a5c836a4dc17251f
Pack SHA256 kanonisch: c24e2c2401f0e17b4cf80b9e9d55cb4f0ddcf89123de4b8810266894d6a853b3
SQLite SHA256: 621f2d849074c9d8f1408fbccf42cf6558e13adb0ddcd4ee66cfe7390bd0baf9
Registry: pipeline/data/words/en.reisen_batch_4_v1.json
Registry SHA256 kanonisch: 8f1e9307f30639616ba4e1ac757b7e1f5eeeeb72aa1c2c75ec13d791ba3edb33
Registry Parent: f0b92c6b7952ab7a4f782c9a0ccd81192f41150f1d16dcb3719055c2842666f1
source_sqlite_sha256 in der Registry ist übernommene historische Metadatenangabe;
source_pack_sha256 bindet an den tatsächlichen neuen Pack. Keine Änderung alter Registrydateien.

CREATE UND POSITIONEN
Nur neue Karten/Sätze/benötigte Wörterbuchzeilen; keinen weiteren Reisen-Stapel anlegen.
Create hängt an Positionen 301–400 an. Danach alle 400 Reisen-Mitgliedschaften nach
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

SPÄTERER IMPORT, NICHT AUSGEFÜHRT: neue Batch-4-Lieferung zuerst vollständig prüfen.
PowerShell: $env:PYTHONPATH='pipeline/src'; .\pipeline\.venv\Scripts\python.exe -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_3_v1/pack.json --create <GEPRUEFTES_CREATE> --registry pipeline/data/words/en.reisen_batch_4_v1.json --display-patch <GEPRUEFTER_DISPLAY_PATCH> --out <NEUER_ORDNER>
macOS: PYTHONPATH=pipeline/src pipeline/.venv/bin/python -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_3_v1/pack.json --create <GEPRUEFTES_CREATE> --registry pipeline/data/words/en.reisen_batch_4_v1.json --display-patch <GEPRUEFTER_DISPLAY_PATCH> --out <NEUER_ORDNER>
Platzhalter ersetzen; niemals vorhandene out-Ordner überschreiben. Nach SQLite-Abnahme
beide Assets sichern, erst danach stagen und verifizieren. user.db nicht öffnen.
Keine Cloud-Aufrufe, keine öffentliche Inhaltsfreigabe. Redaktion bleibt ChatGPT-Redaktion.
