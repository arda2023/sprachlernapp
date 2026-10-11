ARBEIT & BILDUNG – BATCH 3

81 Lernziele, 81 feste englisch/deutsche Satzpaare, 915 Tokenpositionen und vier geprüfte Alternativen.

1. ZIP im Projektstamm als arbeit_bildung_batch_3/ entpacken.
2. PROMPT_CODEX.txt vollständig in eine neue Codex-Session kopieren.
3. Der Auftrag prüft, importiert und stagt Batch 3 und schließt den Stapel mit 245 Lernzielen ab.

Dateien:
- arbeit_bildung_batch_3.editorial.json: Create-Vertrag v2 für Content-Schema 3.
- arbeit_bildung_batch_3.display.json: separater hashgebundener Display-Patch.
- arbeit_bildung_batch_3.html / reading.json: lesbare Satzübersicht.
- annotation_review.txt / editorial_notes.txt: vollständige Bindungen und redaktionelle Entscheidungen.
- verify_arbeit_bildung_batch_3.py: unverändernde Prüfung; optional --export-check NEUER_ORDNER.
- reference/: unveränderter Originalkontext.
- local_export_report.json / validation.txt: tatsächlicher Prüfoutput.
- authoring_audit.json / manifest.json: Umfang und SHA256 aller Lieferdateien.

reference/content.sqlite ist die ALTE Quelle arbeit_bildung_batch_2_v1, nicht das neue App-Asset!

Prüfung ab Repository-Root:
Windows PowerShell:
.\pipeline\.venv\Scripts\python.exe arbeit_bildung_batch_3\verify_arbeit_bildung_batch_3.py --repo .
macOS Terminal:
pipeline/.venv/bin/python arbeit_bildung_batch_3/verify_arbeit_bildung_batch_3.py --repo .
Ohne --repo verwendet der Verifier die enthaltenen Quellen. Vorhandene Pipeline-Umgebung mit jsonschema, spaCy und den übrigen Pipeline-Abhängigkeiten nutzen; die Modellgewichte sind enthalten. Keine Cloud-Aufrufe.

Nach Import: 1250 Karten; 1135 primäre Lernziele (160 / 489 / 241 / 245). Ursprüngliche Auswahlpositionen bleiben erhalten; nur die Stapelanzeige von Arbeit & Bildung wird auf 1–245 zusammengeführt.
Hier noch kein App-Staging oder Gerätetest. Keine echten Lernstände geöffnet.
