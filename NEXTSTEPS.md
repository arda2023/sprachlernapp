# NEXTSTEPS

## Erledigt (2026-10-03, Pipeline 3c)

- Pack nur mit drei `ok`-Sätzen je Karte; keine automatische Erweiterung von `accepted[]`.
- Fünf Kandidaten, bei Bedarf eine Zusatzrunde mit drei; Blindtest mit genau einem Neuversuch, Bedeutungs-Check gegen alle Bedeutungen der Form, Duplikatprüfung.
- Deterministische Alltagssituationen und Namen je Slot, Vermeidungsliste, i+1-Warnungen, Review/Report und Denk-Token-Ledger.
- Prompt-Versionen: meanings-v2, sentences-v2, annotate-v1, blindtest-v1, meaning-check-v1.

## Testergebnis und Kosten

- Offline: `pytest -q` → 55 passed.
- Vertex-Miniaufruf mit hoher Denkstufe: `thoughts_token_count=105` (5 Eingabe-, 1 Ausgabe-Token); das Ledger verwendet dieses Feld.
- Einmaliger Smoke-Test: 5 Formen, 14 Karten erzeugt, 13 im Pack, 39 `ok`-Sätze; alle Gaps treffen exakt die Form.
- Ledger: 267 Aufrufe, 380 Denk-Token, 0,150474 USD bei 1,00 USD Grenze.

## Abweichungen

- Der Smoke-Test schrieb Pack, Review, Ledger und Bericht, endete danach beim Konsolen-`print` mit `UnicodeEncodeError` (Windows cp1252, `→`); ASCII-Ausgabe ist korrigiert. Kein zweiter Smoke-Test.
- `left#links` blieb ohne drei gültige Sätze außerhalb des Packs.
- Vorbestehende Änderungen an `.agent/`, `.agents/`, `.claude/` und `.gemini/` bleiben unberührt; deshalb zeigt `git status` mehr als die angefragten Pipeline- und Dokumentationsdateien.

## Offen

- Die 3c-Smoke-Ausgabe fachlich prüfen, insbesondere die Bedeutungen und deutschen Übersetzungen von `left` und `light`.
