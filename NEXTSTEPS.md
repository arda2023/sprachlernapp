# NEXTSTEPS

## Erledigt (Stand 2026-10-03)
- KI-Zugang: Vertex AI (`sprachlernapp-510508`, `global`, `gemini-3.8-flash`); TTS über Cloud Text-to-Speech.
- `PRODUCT.md` umgestellt (Karten, Erstkontakt, Modi, falsche Form, Story-Wörter, Übersetzungsschichten, Import, Konten); keine "Zero Runtime AI"-Stellen.
- Neu: `ARCHITECTURE.md`, `docs/srs.md`, `docs/content-schema.md`. Gemerged: `docs/backend.md`, `docs/pipeline.md`.
- `CLAUDE.md` und `AGENTS.md`: dieselben 8 Pflichtregeln. `DESIGN.md`: nur Meldung bei falscher Form.

## Abweichungen (Doku gewinnt, Code nicht angepasst)
- `lib/domain/leitner.dart`: kein Box 0, keine Erstkontakt-Regel (richtig → Box 3).
- `DESIGN.md` nennt "Einsteiger/Mittelstufe" für die Bolts, `PRODUCT.md` "Anfänger/Mittleres Niveau".
- `DESIGN.md` Memory Level Legend: "richtig = +1" gilt nicht beim Erstkontakt.
- Code zeigt wöchentliche Nachrichten; v1 liefert zeitlose Kurztexte.
- Pipeline-Ordner heißt `pipeline/` (früher `tools/content_pipeline/`).

## Annahmen (bitte bestätigen)
- Karte mit Box 0 (aus Story, nie beantwortet) zählt als "Noch nicht angezeigt".
- Tagesziel = verschiedene Karten mit `review_log`-Zeile heute; `mode = early` für Vorab-Üben.
- Eine `review_log`-Zeile je Karte und Session; die Wiederholung wird nicht geloggt.

## Offen
- Denk-Budget-Parameter von Gemini 3.8 Flash prüfen; TTS-Pilot `gemini-3.8-flash-lite-tts`.
- Dienstkonto "Vertex AI User" anlegen, Secret `GCP_SA_KEY` setzen.
- EN-Hauptlauf und Audio vor ca. 22.11.2026; weitere Punkte: `PRODUCT.md` → Open Decisions.
