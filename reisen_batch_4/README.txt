REISEN – BATCH 4
100 neue Lernwörter, je ein englischer Übungssatz und eine deutsche Übersetzung.
Geschrieben und redaktionell geprüft von ChatGPT. Keine unabhängige menschliche Freigabe.

VERWENDUNG
1. ZIP im Projekt entpacken. Ergebnis: sprachapp/reisen_batch_4/PROMPT_CODEX.txt.
2. Optional reisen_batch_4.html zum Lesen öffnen.
3. PROMPT_CODEX.txt vollständig in eine neue Codex-Sitzung im Projekt kopieren.
Der Auftrag umfasst Prüfung, vorhandenen Importpfad, Export, internes Staging und
Batch-5-Vorbereitung. Kein manuelles Bearbeiten der SQLite-Datei nötig.

LIEFERUNG
reisen_batch_4.editorial.json: Create-v2, 100 Karten, 100 Sätze, 982 Tokens,
150 ergänzende Wörterbuchform-Zeilen und fünf kontextuell geprüfte Alternativen.
deck_display_patch.json: vollständiges hashgebundenes Anzeigemapping für 400 Reisewörter.
verify_reisen_batch_4.py: read-only Prüfprogramm; mit --repo zusätzlich reale Projektfunktionen.
annotation_review.txt: vollständige Token-/Bedeutungszuordnung für alle 100 Sätze.
reference/: unveränderter Authoring-Kontext, Basis-Pack, Schema und Originalquellkopien.
authoring_audit.json, linter_findings.json, validation.txt und manifest.json: Befunde und Bindungen.

POSITIONEN
Create fügt zunächst Anzeigen 301–400 an. Der bereits vorhandene --display-patch-Pfad
sortiert anschließend alle 400 Reisen-Mitgliedschaften nach combined_display_mapping.json.
285 alte Anzeigen verschieben sich. Nur die position-Spalten ändern sich, keine alten
Texte, IDs, Registry-Originalpositionen oder Lernstände. Die Referenz deck_display.py
NICHT als neue Implementierung ins Projekt kopieren. Kein Zwischenexport.

TATSÄCHLICH HIER GEPRÜFT
100 Satzpaare und sämtliche Wortbindungen redaktionell gelesen; fünf Alternativen
wörtlich eingesetzt, einschließlich Artikel und Satzanschluss.
Mitgelieferte echte Tokenize-/Linterfunktionen mit spaCy 3.8.16 und en_core_web_sm 3.8.0:
0 Linterfehler, 26 Häufigkeitswarnungen; 6–12 Wörter je Satz. JSON-Schema, Hashes,
100 Zielidentitäten, Wortabdeckung, Lücken, Tokens und Review-Hashes geprüft.
Positionen unabhängig im Speicher simuliert, Abgleich gegen alle 400 Registrypositionen.
Die aktuelle Projekt-Implementierung samt create_content/build_rows/stable_id und
Registryvalidator wird erst durch --repo geprüft. Hier kein App-/SQLite-/Gerätetest.

ERWARTET NACH IMPORT
reisen_batch_4_v1, intern, Schema 2; 664 Karten, 1198 Satztexte einschließlich 6 Story-Sätzen,
1192 Karten-Satz-Verknüpfungen einschließlich Historie; 560 Primärwörter:
160 Allgemeine Sprache und 400 Reisen. Weiterhin zwei Stapel.

INHALTLICHE HINWEISE
34 bestehende Ziel-Senses werden wiederverwendet; 66 neue Ziel-Senses kommen aus der
vorgegebenen Auswahl. nearby#nahe-gelegen überschneidet sich mit dem
vorhandenen Begleitwort nearby#nahe_gelegen; die festgelegte Zielidentität bleibt
unverändert. Keine heimliche Zusammenlegung oder Neuvergabe von Karten-IDs.
Bestehende Wörterbuchglossen werden nicht pauschal korrigiert; neue Formübersetzungen
sind ausdrücklich formbezogen. Leere Alternativlisten behaupten keine Eindeutigkeit.
Kein Gemini-/Vertex-Aufruf. Das Pack bleibt intern; keine öffentliche Inhaltsfreigabe.

QUELLEN
Basis: pipeline/out/reisen_batch_3_v1/pack.json
Raw SHA256: 27d2ef97c9a188e7313cdb7e12b84336f37266f0cca865d1a5c836a4dc17251f
Registry: pipeline/data/words/en.reisen_batch_4_v1.json
Canonical SHA256: 8f1e9307f30639616ba4e1ac757b7e1f5eeeeb72aa1c2c75ec13d791ba3edb33
Historische source_sqlite_sha256-Metadaten der Registry bleiben erhalten.
