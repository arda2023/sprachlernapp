ALLTAG & ZUHAUSE – BATCH 3 / ABSCHLUSS

78 Lernziele, 78 feste englisch/deutsche Satzpaare, 937 Tokens, 7 geprüfte Alternativen.
Grundlage: alltag_zuhause_batch_2_v1. Vorhandenen Stapel abschließen, keinen neuen anlegen.

1. ZIP im Projektstamm als alltag_zuhause_batch_3/ entpacken.
2. PROMPT_CODEX.txt vollständig in eine frische lokale Codex-Session kopieren.
3. Der Auftrag prüft, importiert und stagt den abschließenden Batch.
reference/content.sqlite ist ausschließlich der unveränderte QUELLPACK von Batch 2. Nicht direkt als neuen App-Pack kopieren!

.editorial.json: Create-Vertrag v2, Content-Schema 3.
.display.json: separat hashgebundene Anzeigepositionen 1–241.
.html / reading.json: lesbare Satzübersicht.
annotation_review.txt: sämtliche Wortbindungen.
editorial_notes.txt: Entscheidungen, Altglossen und Grenzen.
verify_alltag_zuhause_batch_3.py: unverändernde Prüfung, optional --export-check NEUER_ORDNER.
reference/: unveränderter übergebener Authoring-Kontext.
local_export_report.json / validation.txt: tatsächliche lokale Prüfungen.
manifest.json: Dateihashes.

Prüfung ab Projektstamm, Windows PowerShell:
.\pipeline\.venv\Scripts\python.exe alltag_zuhause_batch_3\verify_alltag_zuhause_batch_3.py --repo .
macOS Terminal:
pipeline/.venv/bin/python alltag_zuhause_batch_3/verify_alltag_zuhause_batch_3.py --repo .
Ohne --repo werden die enthaltenen Quellen verwendet. Benötigt die Pipeline-Abhängigkeiten einschließlich jsonschema; spaCy-Modell ist enthalten. Keine Providerzugriffe.

Erwarteter Endstand: 1005 Karten; 890 primäre Lernziele (160 / 489 / 241).
Noch keine App-Installation, keine Flutter-/Geräteprüfung durch diese Lieferung. user.db bleibt unberührt.
