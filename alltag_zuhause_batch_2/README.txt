ALLTAG & ZUHAUSE – BATCH 2

80 Lernziele, 80 feste englisch/deutsche Satzpaare, 967 Tokens, 8 geprüfte Alternativen.
Grundlage: alltag_zuhause_batch_1_v1; kein neuer Stapel.

1. ZIP im Projektstamm als alltag_zuhause_batch_2/ entpacken.
2. PROMPT_CODEX.txt vollständig in eine frische lokale Codex-Session kopieren.
3. Der Auftrag prüft/importiert/stagt Batch 2 und erstellt den Kontext für die letzten 78 Wörter.
Die SQLite-Datei unter reference/ ist ausschließlich der unveränderte QUELLPACK von Batch 1. Nicht direkt als neuen App-Pack kopieren!

Lieferung:
- alltag_zuhause_batch_2.editorial.json: Create-Vertrag v2 für Content-Schema 3.
- alltag_zuhause_batch_2.display.json: separat hashgebundene Anzeigepositionen 1–163.
- alltag_zuhause_batch_2.html: lesbare, durchsuchbare Satzübersicht.
- annotation_review.txt: alle Wortbindungen.
- editorial_notes.txt: Entscheidungen, Altglossen und Grenzen.
- verify_alltag_zuhause_batch_2.py: unverändernde Prüfung, optional eigener Exportcheck.
- reference/: unveränderter Kontext aus der übergebenen Authoring-ZIP.
- local_export_report.json / validation.txt: tatsächlich ausgeführte lokale Prüfungen.
- manifest.json: Dateihashes der Lieferung.

Prüfung ab Projektstamm, Windows PowerShell:
.\pipeline\.venv\Scripts\python.exe alltag_zuhause_batch_2\verify_alltag_zuhause_batch_2.py --repo .
macOS Terminal:
pipeline/.venv/bin/python alltag_zuhause_batch_2/verify_alltag_zuhause_batch_2.py --repo .
Ohne --repo nutzt der Verifier die Referenzquellen. Benötigt die Pipeline-Abhängigkeiten einschließlich jsonschema; spaCy-Modell ist enthalten. Alle Aufrufe offline, keine Providerzugriffe.

Erwarteter Endstand: 927 Karten; 812 primäre Lernziele (160 / 489 / 163).
Keine aktuelle App-Installation, keine Flutter- oder Geräteprüfung durch diese Lieferung. Keine Änderungen an user.db.
