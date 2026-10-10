REISEN – BATCH 3
100 neue Lernwörter, je ein englischer Übungssatz und eine deutsche Übersetzung.
Geschrieben und redaktionell geprüft von ChatGPT. Keine unabhängige menschliche Freigabe.

VERWENDUNG
1. ZIP im Projekt entpacken. Ergebnis: sprachapp/reisen_batch_3/PROMPT_CODEX.txt.
2. Optional reisen_batch_3.html zum Lesen öffnen.
3. PROMPT_CODEX.txt vollständig in eine neue Codex-Sitzung im Projekt kopieren.
Der Auftrag umfasst Prüfung, vorhandenen Importpfad, Export, internes Staging und
Batch-4-Vorbereitung. Kein manuelles Bearbeiten der SQLite-Datei nötig.

LIEFERUNG
reisen_batch_3.editorial.json: Create-v2, 100 Karten, 100 Sätze, 978 Tokens,
152 ergänzende Wörterbuchform-Zeilen und sieben kontextuell geprüfte Alternativen.
deck_display_patch.json: vollständiges hashgebundenes Anzeigemapping für 300 Reisewörter.
verify_reisen_batch_3.py: read-only Prüfprogramm; mit --repo zusätzlich reale Projektfunktionen.
annotation_review.txt: vollständige Token-/Bedeutungszuordnung für alle 100 Sätze.
reference/: unveränderter Authoring-Kontext, Basis-Pack, Schema und Originalquellkopien.
authoring_audit.json, linter_findings.json, validation.txt und manifest.json: Befunde und Bindungen.

POSITIONEN
Create fügt zunächst Anzeigen 201–300 an. Der bereits vorhandene --display-patch-Pfad
sortiert anschließend alle 300 Reisen-Mitgliedschaften nach combined_display_mapping.json.
190 alte Anzeigen verschieben sich. Nur die position-Spalten ändern sich, keine alten
Texte, IDs, Registry-Originalpositionen oder Lernstände. Die Referenz deck_display.py
NICHT als neue Implementierung ins Projekt kopieren. Kein Zwischenexport.

TATSÄCHLICH HIER GEPRÜFT
100 Satzpaare und sämtliche Wortbindungen redaktionell gelesen; sieben Alternativen
wörtlich eingesetzt, einschließlich Artikel und Satzanschluss.
Mitgelieferte echte Tokenize-/Linterfunktionen mit spaCy 3.8.16 und en_core_web_sm 3.8.0:
0 Linterfehler, 23 Häufigkeitswarnungen; 6–11 Wörter je Satz. JSON-Schema, Hashes,
100 Zielidentitäten, Wortabdeckung, Lücken, Tokens und Review-Hashes geprüft.
Positionen unabhängig im Speicher simuliert, Abgleich gegen alle 300 Registrypositionen.
Die aktuelle Projekt-Implementierung samt create_content/build_rows/stable_id und
Registryvalidator wird erst durch --repo geprüft. Hier kein App-/SQLite-/Gerätetest.

ERWARTET NACH IMPORT
reisen_batch_3_v1, intern, Schema 2; 564 Karten, 1098 Satztexte einschließlich 6 Story-Sätzen,
1092 Karten-Satz-Verknüpfungen einschließlich Historie; 460 Primärwörter:
160 Allgemeine Sprache und 300 Reisen. Weiterhin zwei Stapel.

INHALTLICHE HINWEISE
32 bestehende Ziel-Senses werden wiederverwendet; 68 neue Ziel-Senses kommen aus der
vorgegebenen Auswahl. confirmation#buchungsbestaetigung überschneidet sich mit dem
vorhandenen Begleitwort confirmation#bestaetigung; die festgelegte Zielidentität bleibt
unverändert. Keine heimliche Zusammenlegung oder Neuvergabe von Karten-IDs.
Bestehende Wörterbuchglossen werden nicht pauschal korrigiert; neue Formübersetzungen
sind ausdrücklich formbezogen. Leere Alternativlisten behaupten keine Eindeutigkeit.
Kein Gemini-/Vertex-Aufruf. Das Pack bleibt intern; keine öffentliche Inhaltsfreigabe.

QUELLEN
Basis: pipeline/out/reisen_batch_2_v1/pack.json
Raw SHA256: 4871da0f7e94c0401de2a4dd1b11d0229a6c610723ad3823acfef29cb1d06d1c
Registry: pipeline/data/words/en.reisen_batch_3_v1.json
Canonical SHA256: f0b92c6b7952ab7a4f782c9a0ccd81192f41150f1d16dcb3719055c2842666f1
Historische source_sqlite_sha256-Metadaten der Registry bleiben erhalten.
