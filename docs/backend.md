# Backend (Supabase)

Die App ruft nie direkt eine KI auf. Online-Funktionen laufen über das Backend.

## Plattform

- Supabase, Region EU (Frankfurt).
- Auth: E-Mail (Google/Apple vor dem Release). Lernen funktioniert offline ohne Konto.
- Schema `content`: öffentlich lesbar (`docs/content-schema.md`), geschrieben nur von der Pipeline.
- Schema `app`: Row Level Security, jeder Nutzer sieht und ändert nur eigene Zeilen.
- Buckets: `audio` (öffentlich lesen), `packs` (öffentlich lesen, `content.sqlite` je Sprache und Version), `imports` (privat, Texte der Nutzer).
- Audio-Basis-URL ist Konfiguration (Remote-Config bzw. Release-Eintrag), nicht im Code.

## Lokale Entwicklung

Voraussetzung: Docker Desktop läuft (`docs/setup.md`). Migrationen: `supabase/migrations/`, Tests: `supabase/tests/database/`, Functions: `supabase/functions/`.

Windows (PowerShell):
```powershell
supabase start                    # erster Start lädt Images
supabase db reset                 # Migrationen neu anwenden
supabase test db                  # pgTAP-Tests
supabase functions serve health   # lokal unter http://127.0.0.1:54321/functions/v1/health
$k = ((supabase status -o env | Select-String '^ANON_KEY=') -split '=',2)[1].Trim('"')
Invoke-RestMethod http://127.0.0.1:54321/functions/v1/health -Headers @{ Authorization = "Bearer $k" }
```

macOS (Terminal):
```bash
supabase start
supabase db reset
supabase test db
supabase functions serve health
K=$(supabase status -o env | grep '^ANON_KEY=' | cut -d= -f2- | tr -d '"')
curl -H "Authorization: Bearer $K" http://127.0.0.1:54321/functions/v1/health
```

Lokale Schlüssel nur im Terminal verwenden, nie in Dateien. Falls `docker` unter Windows nicht gefunden wird: `$env:Path += ";C:\Program Files\Docker\Docker\resources\bin"`.

## Deploy (manuell durch Arda)

Gleich auf Windows (PowerShell) und macOS (Terminal):
```
supabase link --project-ref <project-ref>
supabase db push --dry-run
supabase db push
supabase functions deploy health
```

## KI-Zugang: vorhandene Pipeline und geplanter Laufzeitbetrieb

- Lokal implementierter Python-Textanschluss: `claude-haiku-5-5`, EU-Multiregion `eu`, Projekt `sprachlernapp-510508`, ADC; SDK `anthropic[vertex]==1.15.0`. Kein API-Key und kein Fallback. Siehe [Umsetzung Paket A](haiku-migration-implementation.md).
- Die nachfolgenden KI-Edge-Functions sind weiterhin **nicht implementierte Entwürfe**. Vorhanden sind nur Health und Inhaltsverteilung/-veröffentlichung; Paket A ändert keine Supabase-Funktion oder Cloudkonfiguration.
- Für späteren Laufzeitbetrieb vorgesehen: dasselbe EU-Vertex-Routing, Dienstkonto mit Prediction-Berechtigung; dokumentierter Secretname `GCP_SA_KEY`, niemals Repo/App. Weder tatsächliche Secret-Einrichtung noch Modellfreischaltung wurde hier geprüft.
- Historisch nutzte der Pipelineanschluss `gemini-3.8-flash` auf `global`; sein erfolgreicher Mini-Aufruf vom 03.10.2026 ist kein Haiku-/EU-Zugangsbeleg.

## Thinking und Antworten

Haiku-Konfiguration des vorhandenen Wrappers: Thinking aus, Effort low. Bei gemeldetem Verbrauch enthält `output_tokens` bereits Thinking; nicht doppelt zählen. Vollständiges Originalschema lokal prüfen, reduzierte Schemakopie über `output_config.format`; Refusal, Truncation, ungültiges JSON und ungewisse Nutzung kontrolliert ablehnen. Laufzeitlimits/Caches/Usage-Inkremente unten beschreiben einen zukünftigen Vertrag, keine bereits wirksamen Cloudschutzmaßnahmen.

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

`usage(user_id uuid, day date, kind text, units int, primary key (user_id, day, kind))` (siehe `docs/user-schema.md`). Jede Funktion erhöht `units` atomar und liefert `429`, wenn das Limit der Funktion erreicht ist. Limits stehen in der Konfiguration. Ob kostenlos oder Premium, ist offen (`PRODUCT.md`).
