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

## KI-Zugang und Laufzeitübersetzungen (19.10.2026)

Die Python-Pipeline unterstützt explizit direkte Anthropic-API oder Vertex EU/ADC; siehe [Direktzugang](haiku-direct-api-setup.md). Historischer Gemini-Code ist kein aktueller App-Modellpfad. TTS bleibt unverändert.

`lookup-word` und `translate-sentence` sind jetzt lokal implementiert, noch nicht deployed. Flutter nutzt vorhandene Pack-/Beispielübersetzungen offline. Nur wenn sie fehlen, bietet der Reader bzw. die Textübung „Mit KI übersetzen“ an. Bestehender Supabase-Login und Sprachfreigabe in `content_readers` sind erforderlich. Die Functions rufen ausschließlich `https://api.anthropic.com/v1/messages` mit `claude-haiku-5-5` auf; Thinking aus, Effort low. Kein Gemini-/Vertex-Fallback und keine EU-only-Verarbeitungsgarantie. `ANTHROPIC_API_KEY` ausschließlich als serverseitiges Secret; weder Flutter noch Browser erhalten es.

## Übersetzungsverträge

Beide: `POST`, JSON, `Authorization: Bearer <Nutzer-JWT>`; Flutter sendet zusätzlich den vorhandenen öffentlichen `apikey`. `verify_jwt=true` bleibt aktiv, zusätzlich prüft die Function den Nutzer bei Auth. Anonyme Nutzer sind ausgeschlossen. `lang` ist `en` oder `pt-BR`, `target_lang` ist zwingend `de`. Die bisherigen Antwortfelder bleiben erhalten; Metadaten `provider`, `model`, `request_id`, `usage` kommen hinzu. Paket 2A: privater persistenter Cache, `cached=true` bei Serverwiederverwendung. Vertrag 2 ergänzt `contract`, `prompt`, `created_at`; die ursprüngliche Erfolgs-`request_id` bleibt bei Wiederverwendung erhalten. Details: [Cachevertrag und Deployment](story-translation-cache.md).

**`lookup-word`**:
```json
{"contract":2,"lang":"pt-BR","target_lang":"de","form":"banco","sentence":"Ela sentou no banco.","start":14,"end":19,"sense_ref":null,"form_ref":null}
```
Antwortvertrag (Illustration, kein Liveergebnis):
```json
{"form":"banco","senses":[{"pos":"substantivo","form_label":"Substantiv","gloss_de":"Bank zum Sitzen","lemma":"banco"}],"cached":false}
```
Genau eine kontextbezogene Bedeutung; alle vier Sinnfelder werden serverseitig validiert. UTF-16-Start/Ende identifizieren genau das ausgewählte Vorkommen; Sense-/Formreferenzen sind optional. Alte Clients ohne Vertrag/Offsets werden nur bei genau einem exakten Vorkommen akzeptiert. Optionales altes `sentence_id` wird weiterhin ignoriert.

**`translate-sentence`**:
```json
{"lang":"en","target_lang":"de","text":"She knelt down."}
```
Antwortkern: `{"translation_de":"Sie kniete sich hin.","cached":false}`. Optionales altes `import_id` wird ignoriert. Keine Profile, Lernstände oder ganzen Packs im Modellrequest.

Fehler: JSON mit festem `error`, sicherer `message`, `request_id`; `401` Anmeldung, `403` fehlende Sprachfreigabe, `405` Methode, `409` laufende/unklare Anfrage (kein automatischer Retry), `413` Bodylimit, `422` Eingabe, `429` eigenes oder Anbieterlimit, `502` ungültige/fehlgeschlagene Modellantwort, `503` Konfiguration/Infrastruktur, `504` Deadline. Keine rohen Anbieter-/Authfehler im Client. Antworten `Cache-Control: no-store`.

## Begrenzung und Schlüsselhaltung

- Body ≤4096 Byte, Satz ≤600 Zeichen, Wortform ≤80 Zeichen; nur erlaubte Felder und explizite Sprachrichtungen. Die Wortform muss im Kontext stehen. Modellantwort ≤16384 Byte, deutsche Satzantwort ≤1200 Zeichen; Wortantwort genau ein Sinn mit vier Feldern ≤200 Zeichen.
- Höchstens 384 Outputtokens, insgesamt 25 Sekunden Function-Deadline einschließlich Auth/Limitcheck; Flutter maximal 30 Sekunden für HTTP, separat maximal 30 Sekunden für vorhandene Tokenbeschaffung. Null automatische Wiederholungen. Erneutes Öffnen verwendet einen lokalen Treffer ohne Bestätigung. Eine ausdrücklich angefragte identische Serverübersetzung verwendet den privaten Treffer ohne Generierungsbudget.
- Migration `20261019000001_runtime_translation_limits.sql`: service-only `reserve_runtime_translation`, bestehende `content_readers` und `app.usage`. Gemeinsame Limits beider Functions und Sprachen: 5 Anfragen je UTC-Minute/Nutzer, 20 je UTC-Tag/Nutzer, 1000 je UTC-Tag insgesamt. Transaktions-Advisory-Lock schützt die Reservierung; Fehler nach Reservierung zählen mit. Paket 2A ergänzt `20261024000001_private_translation_cache.sql`: private validierte Antworttexte, ansonsten nur Anfragehash und kurzlebige Reservierungsdaten; keine Originalsatzspeicherung auf dem Server und keine Lernstandsänderung. Fehler nach Claim bleiben konservativ 24 Stunden gesperrt. Lokale Originaltexte gehören weiterhin zum Reader, nicht zum Cache.
- Diese Anfrage-/Ausgabelimits sind keine garantierte Dollar-Rechnungsgrenze. Inputtokens enthalten auch Prompt und Schema; nicht aus Zeichenlimits eine Tokenobergrenze ableiten. Anbieterlimits separat verwalten.
- Erfolgslogs enthalten nur ursprüngliche Anfrage-ID, Cachehit-Flag, Provider, Modell und historische Tokenzahlen (bei `cached=true` kein neuer Verbrauch); keine Texte, Nutzer-IDs, Schlüssel oder Tokens. Die Antwortmodell-ID wird vor Erfolg exakt geprüft.
- Lokale SQL-/Deno-/Flutter-Nachweise und genaue manuelle Einrichtung: [Laufzeitbericht](haiku-runtime-translations.md). Cloud-Gateway, echte Parallelität mehrerer DB-Sitzungen, Abrechnung und iPhone bleiben gesonderte Abnahme.

Authentifiziertes `DELETE /functions/v1/translate-sentence` ohne Body löscht private Übersetzungen des verifizierten Kontos. Kein Generierungsbudget und keine Sprachfreigabe nötig, damit Löschung auch nach Entzug einer Leserfreigabe möglich bleibt. Keine andere Function unterstützt DELETE.

## Weiterhin Entwurf: `sentence-check`

Story-Satzprüfung/Umschreiben ist nicht implementiert und wird durch diesen Auftrag nicht aktiviert. SRS, Antwortbewertung, Produktionspacks, redaktionelle Übersetzungen und bestehende Lernstände bleiben unverändert.
