# NEXTSTEPS
## Pipeline 3e / Inkremente 1 und 2
- Inventar, display_form, Ausschlüsse, Parallelität, Stapelreihenfolge und gebündelte Annotation bestehen unverändert.
- Smoke v4 laut Arda: 15 Karten, 45 ok-Sätze, 0,0997 USD; bestehende out-Artefakte unverändert.
- Ardas Klassifikationslauf liegt als lokale Inventaränderung vor; nicht verändert.
- Agent-ADC scheiterte zuvor am Proxy; Arda meldete Python-ADC im normalen Terminal erfolgreich.
- Inkrement 1 erhalten: Bedeutungs-, Satz-POS- und Übersetzungsprüfung; nullable-anyOf und vollständiger ParallelFake.
- Inkrement 2: blindtest-v2 liefert Hauptantwort plus maximal drei begründete Alternativen in einem Aufruf.
- Normalisierung/Deduplizierung; Zielformvarianten zählen nicht. Andere Alternativen verwerfen als Mehrdeutige Lücke.
- Bestehender Blindtest-Retry gemeinsam genutzt; accepted bleibt ausschließlich die Zielform, keine Qualitätsschranke gelockert.
- CSV, Versuchsdaten und qa_report speichern Modellbefunde; Bericht zählt auch ersetzte Versuche und zeigt Pack-Anteil/fehlende Karten.
- Geändert in Inkrement 2: blindtest.py, generate.py, pack.py, review.py, prompts/blindtest.md, test_generate.py, test_blindtest.py, docs/pipeline.md, NEXTSTEPS.md.
- Notwendige Ergänzung zur Dateiliste: test_parallel.py, nur alternatives=[] im Blindtest-Fake; übrige Tests unverändert.
- Offline: 124 passed in 7.79s; concurrency 1 und 8 jeweils 2 erwartete Karten, 6 ok-Sätze, 3 je Karte, identische Packs.
- Simulierter Totalausfall: 11 Kandidaten plus je ein Retry, 22 Mehrdeutigkeitsbefunde, keine Karte im Pack.
- Empfehlungen (nicht angewendet): their/they#ihr_singular neben/active wie they#singular_they; like#fuellwort neben, Ausschluss wegen Lückenmehrdeutigkeit erwägen; will#testament neben/active beibehalten.
- Keine Cloud-Aufrufe, Paketinstallationen, Commits oder Pushes; Modelle, Budgets, stabile IDs und Inventar unverändert.
## Offen
- Empfehlungen redaktionell entscheiden; Bedeutungsfrequenz und Lückeneignung getrennt bewerten.
- Live-Qualität ausdrücklich ungeprüft: Alternativensuche ist eine Heuristik, keine Eindeutigkeitsgarantie.
- Live-Smoke und 60er-Pilot bleiben Arda vorbehalten; in diesem Auftrag nicht gestartet.
