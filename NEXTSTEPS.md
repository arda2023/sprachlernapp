# NEXTSTEPS
## Stand Pipeline
- Inventar, display_form, Ausschlüsse, Parallelität, Stapelreihenfolge, gebündelte Annotation und Bedeutungs-/POS-/Übersetzungsprüfung unverändert.
- Smoke v5 laut Arda: 13/15 Karten, 39 Sätze, 0,1365 USD; Ursache u. a. Ausschluss echter Synonyme (about=ungefähr).
## Alternativantworten, Content-Seite (Commit a208cba)
- blindtest-v3 liefert Kandidaten (abweichende Hauptantwort + ≤ 3 Alternativen, ≤ 4); alternative-check-v1 prüft wörtlich eingesetzte Sätze, ein Aufruf je Satzversuch.
- Hauptantwort = Zielform oder genau diese Hauptantwort bestätigt → Satz besteht; sonst ein Blindtest-Neuversuch, dann failed.
- valid_alternatives in Pack, build_rows, schema.py und SQLite-Export; accepted bleibt [Zielform]; IDs unverändert; alte Packs → [].
- Status: umgesetzt und offline getestet; Migration 20261004000001 erstellt, nicht angewendet; Live-Qualität ungeprüft.
## Review 04.10.2026 (Code, kein funktionaler Befund)
- confirmed_alternative besteht in QA, Pack-Aufnahme und Bericht; nur `passed` kennzeichnet den exakten Zielform-Treffer.
- Eine andere bestätigte Alternative rettet keine abgelehnte Hauptantwort (Ad-hoc-Probe: replaced → failed, valid_alternatives []).
- Einsetzen per Code in die Originalspanne; Prüfantwort ohne Satz-/Kandidatenfelder; ungültig → failed; Auth/Budget/Transport → Abbruch.
- Statusangaben in PRODUCT.md und docs/srs.md berichtigt; Produktregeln unverändert.
- Offline: 162 passed. Keine Code-/Teständerung, keine Cloud-Läufe, DB-Verbindungen, Commits oder Pushes.
## Nächster Schritt
- Smoke v6 durch Arda im normalen Terminal (Befehle im Review-Bericht): Backup, eindeutiger Pack-Pfad, ein Lauf, Exitcode.
- Auswertung braucht smoke_pack_v6*.json, run_report.md, review.csv und Konsolenausgabe.
- Danach: Migration anwenden (nach Freigabe), dann App (valid_alternatives lesen, Hinweis, hint_used-Migration, Box-1-Regel).
## Offen
- Empfehlungen (nicht angewendet): their/they#ihr_singular, like#fuellwort, will#testament redaktionell entscheiden.
- Alternativensuche ist Heuristik, keine Vollständigkeitsgarantie.
- 60er-Pilot erst nach ausgewertetem Smoke v6.
