# NEXTSTEPS
## Erledigt (offline, 04.10.2026)
- pipeline/scripts/complete_curation.py: gezielter Kurationslauf; führt nur die 13 ausstehenden Schritte aus curate() je einmal aus (keine Neugenerierung, lint/blind retries = 0). Bestehende Llm-Klasse, Ledger, Budgetreservierung, qa_sentence, meaning_check, alternative_check, annotate_card wiederverwendet.
- Ergebnisse an geprüften Text/Übersetzung gebunden (`checked`); alter qa_report als `history`. Ablehnungen bleiben offen mit Befund; Annotation nur nach bestandener Satz-QA. Token-Änderungen an Schwestersätzen im Bericht.
- dictionary_forms aus vollständigem Tokenbestand: Quellwerte mit Herkunft + Werte aus neuer Annotation; keine Bedeutungsglossen als Ersatz; fehlende/mehrfache Werte bleiben offen.
- Artefakte nur im neuen --out-Ordner: working_state.json, report.json, ledger.csv. Exit 0/1/2/3 (fertig / offen / Vorbedingung / Abbruch).
- tests/test_complete_curation.py: 14 Tests, simulierte Modellantworten. pytest -q: 266 passed.
- Dry-Run (lokal): 13 Schritte, 7 Karten; Reservierungsobergrenze 0,197 USD ≤ 0,50 USD.
## Geplante Cloud-Arbeiten (nicht gestartet)
- Übersetzungsprüfung s99, s331; Satz-QA s30, s126 (Recheck inside/indoors), s153, s171, s413; annotate_card the#umso, in#herein_drinnen, about#im_begriff, just#genau, all#vollstaendig_adv.
## Manueller Start (Windows PowerShell, ab pipeline)
- `.\.venv\Scripts\python.exe scripts\complete_curation.py --pack pilot_60_v1=out/pilot_60_v1.json --pack pos_check_v1=out/pos_check_v1.json --out out/curation_run_v1 --max-usd 0.50`
- macOS: `.venv/bin/python scripts/complete_curation.py --pack pilot_60_v1=out/pilot_60_v1.json --pack pos_check_v1=out/pos_check_v1.json --out out/curation_run_v1 --max-usd 0.50`
## Offene Konflikte
- 12 Formübersetzungs-Konflikte (Plan Abschnitt 9) bleiben offen; dictionary_forms-Schritt bleibt daher auch nach erfolgreichem Lauf offen (erwartet Exit 1).
- 9 Bedeutungsglossen-Konflikte: Pilotwert behalten, redaktionell offen.
## Offen (sonst)
- Abschnitt-4-Entscheidungen (your, singular they, like#fuellwort, will#testament, s64/s292/s294/s390/s466, pos s9, 6 Alternativen); technisch abgeschlossene QA ist keine redaktionelle Freigabe.
- Alte IDs: Veröffentlichungsstatus ungeklärt; keine Tombstones, keine Lernstandsübertragung.
- Später: Migration 20261004000001 anwenden, App-Anbindung (Hinweis, hint_used, Box-1-Regel). Kein DB-Upload/SQLite-Release durch den Lauf.
