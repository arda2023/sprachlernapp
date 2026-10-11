Alltagssprache & Redewendungen – Batch 1
89 neue Satzpaare für genau die 89 aktuellen Auswahlziele.
Format: sprachapp.editorial-content v2 auf Content-Schema 4.
Vorgesehene Ausgabe: alltagssprache_redewendungen_batch_1_v1.

Einstieg: IMPORT_PROMPT.txt. Lieferung vollständig entpacken; Original behalten.
editorial_content_v2.json ist die Importdatei, reference/registry.json die hashgebundene Registry.
Basis ist irregular_verbs_batch_4_v1; unveränderte Basisdateien liegen im Projekt.
Die authoring-context-Identitäten und cards.learning sind exakt übernommen.
accepted enthält nur die genaue Zielform einschließlich des großen I in I'm.
Mehrwortziele werden über ihren gesamten zusammenhängenden Gap als ein Token annotiert.
89 Eigentümerpositionen: ausschließlich 1–89 aus combined_display_mapping.json.
Keine Phrase reserviert ihre einzelnen Bestandteile als neue Lernwörter.

Nachweis in validation_report.json: Schema, Identitäten, alle 870 Tokenpositionen
(719 Wort-/Ausdruckstokens), Wörterbuchschlüssel, Reviewhashes, acht Alternativen,
Registry, build_rows am In-Memory-Merge und unveränderte Formtabellen bestanden.
81 Eingangsdateihashes geprüft. Die 22 Tabellen der Quell-SQLite wurden mit build_rows
abgeglichen; der exportgenerierte created_at-Wert ist nur auf Vorhandensein geprüft.
Linter: 0 Fehler; 1 Frequenzhinweis: reopen, Zipf 3,42 unter 3,5.
117 Sense-Zeilen und 127 Formübersetzungen werden additiv geliefert; keine Altzeile geändert.
Acht konkrete geerbte Formglossen-Befunde stehen in inherited_gloss_comparison.json.
Sie sind keine neu angelegten Übersetzungen; globale Korrekturen sind nicht Teil der Lieferung.

Technische Korrekturen während der Eigenprüfung: accepted für "correct me if I'm wrong"
nicht vollständig kleinschreiben; der Packvertrag fordert die exakte Kartenform.
Der lokale Vergleichsprüfer berücksichtigt Tabellen ohne id-Spalte, nullable Exportspalten
und den beim Export erzeugten Releasezeitpunkt. Die Inhaltsverträge wurden nicht gelockert.
Vier Satzentwürfe wurden vor der Lieferung wegen zu vieler Teilsätze vereinfacht.

Keine Modell-API-Aufrufe, kein Produktionsimport, kein SQLite-Neuexport, kein Staging,
keine Flutter- oder Geräteprüfung in dieser Chat-Umgebung. ChatGPT-Redaktion und Eigenprüfung
sind keine unabhängige menschliche Sprachfreigabe. Alle 353 späteren Ziele bleiben unberührt.
