# NEXTSTEPS

## Pipeline 3e (2026-10-03)

- `display_form` ist je Form gespeichert; `i` wird in Prompts als `I` gezeigt. Lücke und Blindtest vergleichen ohne Groß-/Kleinschreibung.
- Der Linter akzeptiert nach `.?!` schließende Anführungszeichen und Klammern.
- Das Inventar enthält `usage`, `status` und `exclude_reason`; vier Lücken-untaugliche Bedeutungen sind ausgeschlossen. Seltene Bedeutungen werden durch `classify-usage` ausgeschlossen, sobald die Klassifikation erfolgreich lief.
- Der Pack erhält den Stapel `allgemeine-sprache` mit gewichteter Rangfolge. Karten laufen mit konfigurierbarer Parallelität (Standard 8), Annotation in einem Aufruf je Karte.
- Das Budget wird vor Aufrufen reserviert; 429 und 5xx werden höchstens fünfmal mit Rückzug versucht. `out/progress.txt` zeigt Laufdaten.
- Offline: `pytest -q` → 75 passed in 7.23s.

## Ausstehend

- Der einmal gestartete Klassifikationslauf brach vor dem ersten Vertex-Aufruf mit `AuthError: ADC TransportError` ab. Keine Kosten und keine Klassifikationstabelle. Zugangsdaten wurden nicht geprüft.
- Der 3e-Smoke-Test wurde deshalb nicht gestartet. Der 60er-Pilot wurde wie angewiesen nicht gestartet.
- Nach Behebung der ADC-Verbindung: `classify-usage --max-usd 0.50`, dann `generate --forms smoke --out out/smoke_pack_v4.json --max-usd 1.0`. Den 60er-Pilot führt Arda selbst aus.
