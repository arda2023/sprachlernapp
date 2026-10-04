# NEXTSTEPS
## Stand Pipeline
- Inventar, display_form, Ausschlüsse, Parallelität, Stapelreihenfolge, gebündelte Annotation und Bedeutungs-/POS-/Übersetzungsprüfung unverändert.
- Smoke v5 laut Arda: 13/15 Karten, 39 Sätze, 0,1365 USD; Ursache u. a. Ausschluss echter Synonyme (about=ungefähr).
## Alternativantworten, Content-Seite (04.10.2026)
- Blindtest (blindtest-v3) liefert Kandidaten: abweichende Hauptantwort plus ≤ 3 Alternativen, form_norm-dedupliziert, ohne Zielform, ≤ 4.
- Neu alternative_check.py / alternative-check-v1: Code setzt Kandidaten wörtlich in die Lücke; ein Aufruf je Satzversuch, Ledger-Schritt alternative_check, 512 Ausgabetoken.
- Prüfung erst nach bestandener Originalsatzprüfung; ungültige Prüfantwort lässt den Versuch scheitern; Fehler brechen wie bisher ab.
- Hauptantwort = Zielform oder bestätigte Alternative → Satz besteht; nicht bestätigte Hauptantwort → ein Blindtest-Neuversuch, dann failed.
- valid_alternatives in Pack, build_rows, schema.py und SQLite-Export; accepted bleibt [Zielform]; IDs unverändert; alte Packs → [].
- Migration 20261004000001_card_sentence_alternatives.sql erstellt, nicht angewendet.
- Review-CSV, qa_report (auch ersetzte Versuche) und Bericht zeigen Kandidaten, eingesetzte Sätze, Urteile, Gründe; Kosten je gepackter Karte.
- sentences-v5: Zielform als natürlichste Antwort, echte Synonyme nicht künstlich ausschließen.
- Offline: 162 passed; concurrency 1 und 8 mit identischen Packs, 2 Karten, 6 Sätze.
- Abweichung: test_meaning_check.py nur Versionsassertion sentences-v4 → sentences-v5.
- Keine Cloud-Läufe, DB-Verbindungen, Deploys, Commits oder Pushes.
## Nächster Schritt
- Live-Smoke durch Arda; Bestätigungs- und Ablehnungsquote sowie Stichprobe der valid_alternatives prüfen.
- Migration lokal/remote anwenden (nach Freigabe).
- Danach App: valid_alternatives lesen, Hinweis, hint_used-Migration im review_log, Box-1-Regel.
## Offen
- PRODUCT.md und docs/srs.md nennen Pipeline/Export noch als nicht umgesetzt (in diesem Auftrag nicht geändert).
- Empfehlungen (nicht angewendet): their/they#ihr_singular, like#fuellwort, will#testament redaktionell entscheiden.
- Live-Qualität ungeprüft: Alternativensuche ist Heuristik, keine Vollständigkeitsgarantie.
