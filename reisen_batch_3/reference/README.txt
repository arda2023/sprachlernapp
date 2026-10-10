REISEN AUTHORING BATCH 3 – tatsächlicher Stand nach Batch 2 (06.10.2026)
Genau authoring_batch=3, 100 Einträge; nicht IDs 201–300. Keine Sätze erzeugt.
Alle 500 Identitäten und 660 Registry-Wortzeilen unverändert; Auswahlpositionen bleiben original.
32 vorhandene Zielsenses / 68 neue Vorschläge. Bereits vorhandene Begleitwort-Senses wiederverwenden.
Neu erkannte vorhandene Senses: date, refund, square, harbour, snow, ferry, ship, recommend.

Quelle: pipeline/out/reisen_batch_2_v1/pack.json
Packversion: reisen_batch_2_v1, intern, Schema 2
Pack SHA256 Rohbytes: 4871da0f7e94c0401de2a4dd1b11d0229a6c610723ad3823acfef29cb1d06d1c
Pack SHA256 kanonisch: b71ebb869bf9f743e29a8c8152787bbab695ab57a3218c3f3b4a15724652eda9
SQLite SHA256: e6ea7ee8e77b88e6f6ca3f823d1d947bb9156bd30f7b7ef4fc5f2413a7867281
Registry: pipeline/data/words/en.reisen_batch_3_v1.json
Registry SHA256 kanonisch: f0b92c6b7952ab7a4f782c9a0ccd81192f41150f1d16dcb3719055c2842666f1
Registry Parent: e2331264c70e18c2bbb8e92ce8ead4e7d81f14a342da466e7b1c1c990c5a3642
source_sqlite_sha256 in der Registry ist übernommene historische Metadatenangabe;
source_pack_sha256 bindet an den tatsächlichen neuen Pack. Keine Änderung alter Registrydateien.

CREATE UND POSITIONEN
Nur neue Karten/Sätze/benötigte Wörterbuchzeilen; keinen weiteren Reisen-Stapel anlegen.
Create hängt an Positionen 201–300 an. Danach alle 300 Reisen-Mitgliedschaften nach
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

SPÄTERER IMPORT, NICHT AUSGEFÜHRT: neue Batch-3-Lieferung zuerst vollständig prüfen.
PowerShell: $env:PYTHONPATH='pipeline/src'; .\pipeline\.venv\Scripts\python.exe -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_2_v1/pack.json --create <GEPRUEFTES_CREATE> --registry pipeline/data/words/en.reisen_batch_3_v1.json --display-patch <GEPRUEFTER_DISPLAY_PATCH> --out <NEUER_ORDNER>
macOS: PYTHONPATH=pipeline/src pipeline/.venv/bin/python -X utf8 pipeline/scripts/import_editorial_patch.py --source pipeline/out/reisen_batch_2_v1/pack.json --create <GEPRUEFTES_CREATE> --registry pipeline/data/words/en.reisen_batch_3_v1.json --display-patch <GEPRUEFTER_DISPLAY_PATCH> --out <NEUER_ORDNER>
Platzhalter ersetzen; niemals vorhandene out-Ordner überschreiben. Nach SQLite-Abnahme
beide Assets sichern, erst danach stagen und verifizieren. user.db nicht öffnen.
Keine Cloud-Aufrufe, keine öffentliche Inhaltsfreigabe. Redaktion bleibt ChatGPT-Redaktion.
