# Backend (Supabase)

Die App ruft nie direkt eine KI auf. Online-Funktionen laufen über das Backend.

## Plattform

- Supabase, Region EU (Frankfurt).
- Auth: E-Mail (Google/Apple vor dem Release). Lernen funktioniert offline ohne Konto.
- Schema `content`: öffentlich lesbar (`docs/content-schema.md`), geschrieben nur von der Pipeline.
- Schema `app`: Row Level Security, jeder Nutzer sieht und ändert nur eigene Zeilen.
- Buckets: `audio` (öffentlich lesen), `packs` (öffentlich lesen, `content.sqlite` je Sprache und Version), `imports` (privat, Texte der Nutzer).
- Audio-Basis-URL ist Konfiguration (Remote-Config bzw. Release-Eintrag), nicht im Code.

## KI-Zugang: Vertex AI

- Projekt `sprachlernapp-510508`, Region `global`.
- Modell `gemini-3.8-flash` (getestet am 2026-10-03, Antwort erfolgreich).
- Kein API-Key-Zugang.
- Edge Functions nutzen ein Dienstkonto mit der Rolle "Vertex AI User".
- Der Dienstkonto-Schlüssel liegt als Supabase-Secret `GCP_SA_KEY`, nie im Repo und nie in der App.

## Denk-Token

Denk-Token zählen als Ausgabe. Jede Anfrage bekommt ein Denk-Budget.
Der Parameter-Name für Gemini 3.8 Flash ist vor der Nutzung gegen die offizielle Dokumentation zu prüfen, nicht zu raten.

## Laufzeit-KI (nur über Edge Functions)

Der Client ruft nie einen KI-Anbieter direkt auf. Edge Functions rufen Vertex AI nur für nutzergenerierte Inhalte auf:

- Wörterbuch-Nachschlagen bei Treffer-Fehlschlag (dictionary miss lookup)
- Satzübersetzung per Tipp in importierten Texten
- Satzprüfung bzw. Umschreiben für Story-Wörter

Kuratierte Inhalte werden vor dem Release erzeugt (`docs/pipeline.md`). Jede Funktion verlangt ein gültiges Nutzer-Token und zählt in `usage`.

## Edge Functions (Entwurf)

Alle: `POST`, JSON, Header `Authorization: Bearer <Nutzer-JWT>`. Fehler: `{ "error": "<code>", "message": "..." }` mit `401` (kein Token), `429` (Tageslimit), `422` (ungültige Eingabe), `502` (KI-Fehler).

**`lookup-word`** (Wörterbuch-Treffer fehlt)
```json
// Request
{ "lang": "en", "form": "knelt", "sentence": "She knelt down.", "sentence_id": null }
// Response
{ "form": "knelt", "senses": [ { "pos": "verb", "form_label": "Vergangenheit", "gloss_de": "kniete", "lemma": "kneel" } ], "cached": false }
```

**`translate-sentence`** (Satz in importiertem Text)
```json
// Request
{ "lang": "en", "text": "She knelt down.", "import_id": "7f3a..." }
// Response
{ "translation_de": "Sie kniete sich hin.", "cached": false }
```

**`sentence-check`** (Story-Wort: verständlich ohne Kontext?)
```json
// Request
{ "lang": "en", "sentence": "He knelt.", "form": "knelt", "sense_gloss_de": "kniete" }
// Response
{ "understandable": false, "rewrite": { "text": "The child knelt to tie her shoe.", "gap_start": 10, "gap_end": 15, "translation_de": "Das Kind kniete sich hin, um den Schuh zu binden." } }
```
`rewrite` fehlt, wenn `understandable` wahr ist. Neuer Satz enthält dieselbe Form und Bedeutung.

## Tageslimits: Tabelle `usage`

`usage(user_id uuid, day date, fn text, count int, primary key (user_id, day, fn))`. Jede Funktion erhöht `count` atomar und liefert `429`, wenn das Limit der Funktion erreicht ist. Limits stehen in der Konfiguration. Ob kostenlos oder Premium, ist offen (`PRODUCT.md`).
