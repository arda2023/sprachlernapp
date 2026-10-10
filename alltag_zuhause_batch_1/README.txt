ALLTAG & ZUHAUSE — BATCH 1
83 Wörter · 83 Satzpaare · 9 geprüfte Alternativen · Schema 3

Verwendung
1. alltag_zuhause_batch_1.zip ins Projektverzeichnis sprachapp entpacken.
   Danach liegt dort alltag_zuhause_batch_1/PROMPT_CODEX.txt.
2. Den vollständigen Prompt aus PROMPT_CODEX.txt in Codex einfügen.
   Er übernimmt Prüfung, Import, internes Staging und den nächsten ZIP-Kontext.
3. Nicht von Hand JSON oder SQLite ins App-Asset kopieren.

Lieferung
- alltag_zuhause_batch_1.editorial.json: hashgebundene Create-v2-Datei für Content-Schema 3.
- alltag_zuhause_batch_1.html und reading.json: alle Satzpaare, Bedeutung und Alternativen.
- annotation_review.txt: vollständige Wortzuordnung pro Satz.
- verify_alltag_zuhause_batch_1.py: Offline-Prüfung; optional --repo PFAD und --export-check NEUER_ORDNER.
- validation.txt/local_export_report.json: tatsächlich ausgeführte Prüfung mit den mitgelieferten Projektquellen.
- reference/: unveränderte Authoring-Referenzen einschließlich Quellkopien und Modellgewichten.
- manifest.json: SHA256 der Lieferdateien; nicht der ZIP-Datei selbst.

Geprüft hier
Quellhashes, JSON Schema, Tokenizer, Linter, tatsächlicher mitgelieferter create_content,
build_rows, Stable IDs, 83 Lerngruppenmetadaten, Bestandserhalt, SQLite-Export und
vollständiger Tabellenabgleich bestanden. 931 Tokens, 0 Linterfehler, 26 neue
Häufigkeitswarnungen. Kein Gemini-/Vertex-Aufruf, keine zusätzlichen Pipeline-Kosten.

Nicht durchgeführt
Kein Staging in deinem Projekt, keine Flutter-Suite, kein Zugriff auf user.db,
keine Geräteprüfung und keine öffentliche Freigabe. Die Importprüfung vor Ort bleibt nötig.
Die Redaktion und Gegenprüfung stammen von ChatGPT, nicht von einem unabhängigen Menschen.
Die neun Alternativen sind eine gezielte Auswahl, keine vollständige Synonymliste.

Bestand nach Import
847 physische Karten; 732 neue primäre Lernziele (160 Allgemeine Sprache,
489 Reisen, 83 Alltag & Zuhause). Historische Nebenbedeutungen werden nicht gelöscht.
Originalpositionen bleiben erhalten, neue Anzeigepositionen sind 1–83.
Die weiteren 158 reservierten Ziele gehören in Batch 2 (80) und Batch 3 (78).

Altwörterbuch
Wiederverwendete Sense-/Formzeilen bleiben unverändert, auch alte flektierte oder
verkürzte Glossentexte. Neue Karten verwenden die vollständige translation_de aus
der Auswahl. Diese Lieferung ist keine Bereinigung des gesamten Altwörterbuchs.
