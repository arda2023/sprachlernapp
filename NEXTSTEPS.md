# NEXTSTEPS
## Stand Pipeline
- Inventar, display_form, Ausschlüsse, Parallelität, Stapelreihenfolge, gebündelte Annotation unverändert.
- Alternativantworten (Commit a208cba): blindtest-v3 liefert Kandidaten, Alternativprüfung je Satzversuch ein Aufruf; valid_alternatives in Pack, schema.py, SQLite-Export; accepted bleibt [Zielform].
- Migration 20261004000001 erstellt, nicht angewendet.
## Smoke v6 (laut Arda)
- 15 Karten, 45 Sätze, 20 gespeicherte Alternativen, 0,1120 USD; Datenfluss funktioniert.
- Befunde: „sun is too light“ + bright bestätigt; „sun light“ getrennt; about → nearly/almost bestätigt; up the mountain road → along bestätigt.
## QA-Lücken geschlossen (offline, 04.10.2026)
- meaning-check-v3: Pflichtfeld language_ok im selben Aufruf; false → failed, Grund „Sprache“, vor der Alternativprüfung.
- Fehlendes oder falsch typisiertes language_ok → ungültige Prüfantwort. Retry- und Kandidatenlimits unverändert.
- alternative-check-v2: gleiche Aussage und Übersetzung (Mengen, Richtung, Negation, Zeit, Modalität, Handelnde); im Zweifel false.
- sentences-v6: natürliche Sprache, keine Wortzerlegung; keine Wortlisten.
- language_ok in meaning_check_result, qa_report, review.csv („Sprachprüfung“), Bericht; alte Packs lesbar.
- Prüfsammlung tests/fixtures/qa_language_cases.json und scripts/check_qa_cases.py vorbereitet, nicht live ausgeführt.
- Live-Qualität der neuen Prompts ungeprüft.
## Nächster Schritt
- Arda: `scripts/check_qa_cases.py --out out/qa_language_v1 --max-usd 0.25`, results.json auswerten.
- Bei Abweichungen Ergebnisse auswerten, Prompts nicht auf die bekannten Beispiele zuschneiden.
- Danach Smoke v7, dann Migration (nach Freigabe), dann App (valid_alternatives, Hinweis, hint_used, Box-1-Regel).
## Offen
- Empfehlungen (nicht angewendet): their/they#ihr_singular, like#fuellwort, will#testament redaktionell entscheiden.
- Alternativensuche ist Heuristik, keine Vollständigkeitsgarantie.
- 60er-Pilot erst nach ausgewertetem QA-Vergleich und Smoke v7.
