ARBEIT & BILDUNG – BATCH 1

82 Lernziele mit je einem festen englisch/deutschen Satz, 900 Tokenpositionen und sechs geprüften Alternativen.

1. ZIP im Projektstamm als arbeit_bildung_batch_1/ entpacken.
2. PROMPT_CODEX.txt vollständig in eine neue lokale Codex-Session kopieren.
3. Der Auftrag prüft/importiert/stagt die 82 Ziele und erstellt die nächste Kontext-ZIP für 82 weitere Ziele.

reference/content.sqlite ist ausschließlich die alte Quelle alltag_zuhause_batch_3_v1. Nicht direkt als neues App-Asset kopieren!

Dateien:
- arbeit_bildung_batch_1.editorial.json: Create-Vertrag v2 für Content-Schema 3.
- arbeit_bildung_batch_1.html und reading.json: lesbare Satzübersicht.
- annotation_review.txt: alle Wortbindungen.
- editorial_notes.txt: Bedeutungsentscheidungen, Alternativen und Grenzen.
- verify_arbeit_bildung_batch_1.py: unverändernde Prüfung; optional --export-check NEUER_ORDNER.
- reference/: vollständiger unveränderter Authoring-Kontext.
- local_export_report.json und validation.txt: tatsächlich ausgeführte lokale Prüfung.
- manifest.json: SHA256 sämtlicher Lieferdateien.

Prüfung ab Repository-Root:
Windows PowerShell:
.\pipeline\.venv\Scripts\python.exe arbeit_bildung_batch_1\verify_arbeit_bildung_batch_1.py --repo .
macOS Terminal:
pipeline/.venv/bin/python arbeit_bildung_batch_1/verify_arbeit_bildung_batch_1.py --repo .
Ohne --repo verwendet der Verifier die enthaltenen Quellen. Er benötigt die vorhandenen Pipeline-Pakete einschließlich jsonschema; spaCy-Modellgewichte sind enthalten. Keine Cloud-Aufrufe.

Erwarteter Endstand nach lokalem Import: 1087 Karten; 972 primäre Lernziele (160 / 489 / 241 / 82).
Noch kein echtes App-Staging durch diese Lieferung. Echte Lernstände werden nicht geöffnet.
