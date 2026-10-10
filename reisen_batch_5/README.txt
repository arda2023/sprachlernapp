REISEN – BATCH 5 (LETZTE 100 VON 500)
100 neue Lernwörter, je ein englischer Übungssatz und eine deutsche Übersetzung.
Geschrieben und redaktionell geprüft von ChatGPT. Keine unabhängige menschliche Freigabe.

VERWENDUNG
1. ZIP im Projekt entpacken. Ergebnis: sprachapp/reisen_batch_5/PROMPT_CODEX.txt.
2. Optional reisen_batch_5.html zum Lesen öffnen.
3. PROMPT_CODEX.txt vollständig in eine neue Codex-Sitzung im Projekt kopieren.
Der Auftrag umfasst Inhaltsprüfung, vorhandenen Importpfad, Export, internes Staging
und den Gesamt-Abgleich aller 500 Reisewörter. Kein Batch 6; keine neue Generierung.

LIEFERUNG
reisen_batch_5.editorial.json: Create-v2, 100 Karten, 100 Sätze, 1021 Tokens,
142 ergänzende Wörterbuchform-Zeilen und sieben kontextuell geprüfte Alternativen.
deck_display_patch.json: vollständiges hashgebundenes Anzeigemapping für 500 Reisewörter.
verify_reisen_batch_5.py: read-only Prüfprogramm, mit --repo zusätzlich echte Projektfunktionen.
annotation_review.txt: sämtliche Token-/Bedeutungszuordnungen.
reference/: unveränderter Authoring-Kontext, Basis-Pack, Schema und Quellkopien.
authoring_audit.json, linter_findings.json, validation.txt und manifest.json: Befunde und Bindungen.

POSITIONEN
Create fügt Anzeigen 401–500 an. Der vorhandene --display-patch-Pfad sortiert vor
Export alle 500 Reisen-Mitgliedschaften nach combined_display_mapping.json.
380 alte Anzeigen verschieben sich. Nur position in deck_cards/deck_words ändert sich,
keine alten Texte, IDs, Originalpositionen oder Lernstände. Kein Zwischenexport.
Die Referenz deck_display.py nicht als neue Implementierung ins Projekt kopieren.

TATSÄCHLICH HIER GEPRÜFT
100 Satzpaare und alle Wortbindungen gelesen; sieben Alternativen wörtlich eingesetzt.
Echte mitgelieferte Tokenize-/Linterfunktionen, spaCy 3.8.16, en_core_web_sm 3.8.0:
0 Linterfehler, 38 Häufigkeitswarnungen; 7–11 Wörter je Satz.
JSON-Schema, Hashbindungen, Zielidentitäten, Lücken, Tokens, Wörterbuchabdeckung
und Review-Hashes geprüft. Vollständige 500er-Anzeige im Speicher abgeglichen.
Aktuelle Projektfunktionen create_content/build_rows/stable_id/deck_display werden
erst mit --repo im Projekt ausgeführt. Hier kein SQLite-Export, App- oder Gerätetest.

ERWARTET NACH IMPORT
reisen_batch_5_v1, intern, Schema 2; 764 Karten, 1298 Satztexte einschließlich 6 Story-Sätzen,
1292 Karten-Satz-Verknüpfungen einschließlich Historie; 660 Primärwörter:
160 Allgemeine Sprache und 500 Reisen. Zwei Stapel, keine neue Lernstandmigration.

INHALTLICHE HINWEISE
31 bestehende und 69 vorgeschlagene Ziel-Senses, alle Bindungen wie im Kontext.
Neue Formübersetzungen sind formbezogen. Die schon vorhandenen kurzen/flektierten
Sense-Glossen werden nicht pauschal korrigiert und IDs nicht zusammengelegt.
ride als Mitfahren/Fahrradfahren, cold als Kälte, entry als Einreise und station in
petrol station sind bewusst getrennt zugeordnet. Ausführliche Entscheidungen im Audit.
Geprüfte Alternativen: traveler, luggage, license, seat belt, theater, rent, buckle.
Leere Alternativlisten behaupten keine Eindeutigkeit. Kein Gemini-/Vertex-Aufruf.
Technische Vollständigkeit von 500 Wörtern ist keine öffentliche Inhaltsfreigabe.

QUELLEN
Basis: pipeline/out/reisen_batch_4_v1/pack.json
Raw SHA256: 97015c3c12b9f5e2fb2d900ee9544029189e1f51a3741c1a9100f206dcf5b4d3
Registry: pipeline/data/words/en.reisen_batch_5_v1.json
Canonical SHA256: 4148c720b983fe66c01683db760208c7b85cb0a59f98bb5a40ae7d049198f2b4
Historische source_sqlite_sha256-Metadaten bleiben erhalten.
