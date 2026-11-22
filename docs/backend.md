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

`lookup-word` und `translate-sentence` sind jetzt lokal implementiert, noch nicht deployed. Flutter nutzt vorhandene Pack-/Beispielübersetzungen offline. Nur wenn sie fehlen, bietet der Reader bzw. die Textübung „Mit KI übersetzen“ an. Die Runtime-Functions verlangen ein bestätigtes, nicht-anonymes Supabase-Konto und erlauben `en` und `pt-BR`; sie vergeben oder benötigen keine interne `content_readers`-Rolle. Die Functions rufen ausschließlich `https://api.anthropic.com/v1/messages` mit `claude-haiku-5-5` auf; Thinking aus, Effort low. Kein Gemini-/Vertex-Fallback und keine EU-only-Verarbeitungsgarantie. `ANTHROPIC_API_KEY` ausschließlich als serverseitiges Secret; weder Flutter noch Browser erhalten es.

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

Fehler: JSON mit festem `error`, sicherer `message`, `request_id`; `401` Anmeldung, `403` fehlende Sprachfreigabe oder unbestätigtes Konto, `405` Methode, `409` laufende/unklare Anfrage (kein automatischer Retry), `413` Bodylimit, `422` Eingabe, `429` eigenes, Kontingent- oder Anbieterlimit, `502` ungültige/fehlgeschlagene Modellantwort, `503` Konfiguration/Infrastruktur, `504` Deadline. `TRANSLATION_QUOTA_EXHAUSTED` enthält `quota_kind` und beim Premiumkonto `resets_at`; die App zeigt das Datum ohne erneute Kaufaufforderung. Keine rohen Anbieter-/Authfehler im Client. Antworten `Cache-Control: no-store`.

## Begrenzung und Schlüsselhaltung

- Body ≤4096 Byte, Satz ≤600 Zeichen, Wortform ≤80 Zeichen; nur erlaubte Felder und explizite Sprachrichtungen. Die Wortform muss im Kontext stehen. Modellantwort ≤16384 Byte, deutsche Satzantwort ≤1200 Zeichen; Wortantwort genau ein Sinn mit vier Feldern ≤200 Zeichen.
- Höchstens 384 Outputtokens, insgesamt 25 Sekunden Function-Deadline einschließlich Auth/Limitcheck; Flutter maximal 30 Sekunden für HTTP, separat maximal 30 Sekunden für vorhandene Tokenbeschaffung. Null automatische Wiederholungen. Erneutes Öffnen verwendet einen lokalen Treffer ohne Bestätigung. Eine ausdrücklich angefragte identische Serverübersetzung verwendet den privaten Treffer ohne Generierungsbudget.
- Migrationen `20261019000001_runtime_translation_limits.sql` und `20261031000002_translation_subscription_budget.sql`: service-only RPCs, bestätigte nicht-anonyme Auth-Konten, erlaubte Runtime-Sprachen und neue serverseitige Quotenreservierungen. Eine interne `content_readers`-Freigabe ist für die öffentliche Display-Übersetzung nicht nötig und wird nicht vergeben. Verifizierte Konten erhalten lebenslang insgesamt 5 neue KI-Übersetzungen über alle Sprachen. Ein aktives Produktionsentitlement `premium` gewährt 500 neue Übersetzungen je monatlichem Kaufzeitraum; auch Jahresabos erhalten die 500 pro Monat ab Kaufdatum. Aktive Sandbox-Entitlements freigegebener Tester (nur sie erhalten über `billing-sync` überhaupt Sandbox-Zeilen) zählen seit `20261101000001_sandbox_translation_budget.sql` wie Produktion für das Premiumkontingent (Nutzerentscheidung 01.11.2026); bei beiden Zeilen gilt Produktion. Treffer aus Pack/Redaktion oder gültigem Servercache verbrauchen nichts. Eine Übersetzung zählt erst beim erfolgreichen Speichern; erkennbare Fehler und abgelaufene Tickets werden freigegeben. Der Ticketzaun verhindert, dass eine späte Antwort nach Freigabe doppelt belastet wird. Öffentliche Display-Übersetzungen behalten 5 Anfragen je UTC-Minute pro Konto und 1000 je UTC-Tag global; es gibt kein zusätzliches tägliches Premiumkontingent. `reserve_runtime_translation` bleibt für bestehende Personal-Learning-Jobs unverändert (einschließlich seiner bisherigen Grenze von 20/Tag); dieser private Pfad erhält dadurch keine neue KI-Freigabe. Paket 2A ergänzt `20261024000001_private_translation_cache.sql`: private validierte Antworttexte, ansonsten nur Anfragehash und kurzlebige Reservierungsdaten; keine Originalsatzspeicherung auf dem Server und keine Lernstandsänderung. Cache-Treffer benötigen kein Generierungsbudget. Seit `20261101000002_keep_translations.sql` (Nutzerentscheidung 01.11.2026) bleiben fertige Antworten ohne Ablaufdatum gespeichert (vorher 30 Tage), lokal ebenso; Löschen über die Einstellungen oder die Kontolöschung. Lokale Originaltexte gehören weiterhin zum Reader, nicht zum Cache.
- Diese Anfrage-/Ausgabelimits sind keine garantierte Dollar-Rechnungsgrenze. Inputtokens enthalten auch Prompt und Schema; nicht aus Zeichenlimits eine Tokenobergrenze ableiten. Anbieterlimits separat verwalten.
- Erfolgslogs enthalten nur ursprüngliche Anfrage-ID, Cachehit-Flag, Provider, Modell und historische Tokenzahlen (bei `cached=true` kein neuer Verbrauch); keine Texte, Nutzer-IDs, Schlüssel oder Tokens. Die Antwortmodell-ID wird vor Erfolg exakt geprüft.
- Lokale SQL-/Deno-/Flutter-Nachweise und genaue manuelle Einrichtung: [Laufzeitbericht](haiku-runtime-translations.md). Cloud-Gateway, echte Parallelität mehrerer DB-Sitzungen, Abrechnung und iPhone bleiben gesonderte Abnahme.

Authentifiziertes `DELETE /functions/v1/translate-sentence` ohne Body löscht private Übersetzungen des verifizierten Kontos. Kein Generierungsbudget und keine Sprachfreigabe nötig, damit Löschung auch nach Entzug einer Leserfreigabe möglich bleibt. Keine andere Function unterstützt DELETE.

## Private Themenvokabeln

`POST /functions/v1/generate-vocabulary` erzeugt auf ausdrückliche Anfrage private Themenvokabeln für `en`, `es`, `it`, `nb` und `pt-BR`. Erforderlich sind ein gültiges Supabase-Bearer-Token eines bestätigten, nicht-anonymen Kontos und die bestehende widerrufbare KI-Einwilligung. Der Client sendet Vertrag 1 mit `request_id` (UUID), `lang`, getrimmtem `prompt` (1–400 UTF-16-Einheiten, höchstens zwei Sätze), `count` (1–50) und `consent: 1`; unbekannte Felder werden abgelehnt. Zusammenhängende Satzendzeichen bilden eine Satzgrenze. Der Themenhinweis ist unvertrauenswürdige Daten, keine Systemanweisung.

Die Function verwendet ausschließlich direkte Anthropic-Aufrufe mit `claude-haiku-5-5`, Thinking aus und Effort low; `ANTHROPIC_API_KEY` bleibt ein serverseitiges Secret. Kein Anbieterzugriff aus Flutter, kein Gemini-/Vertex-Fallback, keine EU-only-Garantie. Der Anbieter erhält Thema, Sprache und Anzahl; keine lokalen Karten oder Lernverläufe. Eine Antwort enthält 1 bis `count` unterschiedliche vollständige Wörter mit Lemma, POS ohne Eigennamen, deutschen Bedeutungs-/Formhinweisen und genau einem festen Beispielsatz je Wort (3–40 Wörter, keine Semikolons oder Striche). Die genaue Wortstelle wird serverseitig aus dem Satz als UTF-16-Offset ermittelt. Satz und ganzes Zielwort müssen exakt passen; deutsche Glosse und Satzübersetzung dürfen die Lösung auch bei anderer Großschreibung nicht verraten. Client und Function validieren dieselben Feld-, Längen- und Referenzregeln. Der Server übernimmt ausschließlich vollständig validierte, untereinander eindeutige Kandidaten, begrenzt auf die angefragte Anzahl. Einzelne ungültige Kandidaten entfallen; ohne gültige Karte wird die Antwort abgelehnt. Es gibt keinen zweiten Modellaufruf zum Auffüllen oder Reparieren.

Migration `20261031000004_generated_vocabulary.sql` ergänzt die private, RLS-geschützte Tabelle `app.generated_vocabulary_requests` und die ausschließlich für `service_role` ausführbaren RPCs `claim_generated_vocabulary`, `finish_generated_vocabulary` und `fail_generated_vocabulary`. `anon` und `authenticated` haben weder Tabellenzugriff noch RPC-Ausführungsrechte. Der eindeutige Schlüssel ist (`user_id`, `request_id`); gespeichert werden Sprache, Eingabehash, angefragte Anzahl, Zustand, Worker-Ticket, Zeitpunkte und gegebenenfalls die validierte Antwort. Der eingegebene Themenklartext wird dort nicht gespeichert. Das fremdschlüsselgebundene Konto löscht bei Kontolöschung auch diese Zeilen.

Claim serialisiert die Reservierung atomar über ein globales Advisory Lock: höchstens 5 neue Anfragen und 250 reservierte Wörter je Konto sowie 20.000 reservierte Wörter global in rollierenden 24 Stunden. Die angefragte Anzahl wird vor dem Anbieteraufruf reserviert und bleibt auch bei Fehlversuch, kürzerer Antwort oder abgebrochener Verbindung belastet. Migration `20261116000001_unstarted_generation_quota.sql`: Endet ein Auftrag nachweislich vor dem Generierungsaufruf (Themenprüfung abgelehnt/fehlgeschlagen, KI-Budget nicht verfügbar), setzt `release_unstarted_generated_vocabulary` ihn auf `failed` mit `quota_released` und gibt ein Gratisrecht frei; solche Zeilen zählen nicht zu 5 Anfragen/250 Wörtern/20.000 global, aber zu höchstens 30 Versuchen je Konto in 24 Stunden. Bereits gebuchte KI-Kosten bleiben bestehen. Während einer aktiven dreiminütigen Lease darf das Konto keinen weiteren neuen Auftrag beginnen. Finish ist durch Konto, UUID, Ticket, Zustand und aktive Lease gegen veraltete Worker geschützt. Diese Grenzen gehören ausschließlich zur Topic-Generierung; die bestehenden kostenlosen/Premium-Übersetzungsbudgets und Personal-Learning-Grenzen werden dadurch nicht geändert.

Migration `20261115000001_free_vocabulary_generation.sql` gewährt einem bestätigten Konto über alle Lernsprachen eine kostenlose Generierung mit bis zu 50 Wörtern. Der Claim verwendet dieselbe atomare Reservierung und einen eindeutigen Teilindex pro Konto. Ein nachweislich vor dem Generierungsaufruf abgewiesener Auftrag gibt nur die Gratisreservierung frei. Sein UUID-Tombstone, die Tagesgrenzen und die bereits reservierten KI-Kosten bleiben bestehen. Sobald der Generierungsaufruf begonnen hat, bleibt die Gratisreservierung bei Fehlern oder unklarem Ausgang erhalten. Verifiziertes Premium eröffnet die regulären neuen Anfragen. Die authentifizierte Abfrage `free_vocabulary_generation_available()` zeigt den Kontostatus ohne Generierung.

`POST /functions/v1/generate-vocabulary?status=1` mit demselben vollständigen Request ist eine reine Status-/Ergebnisabfrage: Treffer liefern die gespeicherte Antwort, fehlende UUIDs bleiben ohne Reservierung und ohne Anbieteraufruf. Für dieselbe UUID ergeben geänderte Sprache, Thema oder Anzahl einen Konflikt. Aktive Aufträge sind `busy`, abgelaufene unbeendete Aufträge `uncertain`; `failed` und `expired` sind ebenfalls keine neue Generierungsfreigabe. Keine automatischen Wiederholungen im Client oder Backend. Eine neue Generierung braucht eine bewusst neu angelegte UUID und das normale Reservierungsbudget.

Nach 30 Tagen seit Reservierung entfernt ein späterer Claim gespeicherte Antworttexte und setzt den Zustand auf `expired`; das gilt auch für eine spätere Statusabfrage. Die Bereinigung erfolgt bei Zugriff und ist keine garantierte zeitgesteuerte Löschung exakt am 30. Tag. Replay-Tombstones bleiben bis zur Kontolöschung erhalten. Der Client zeigt zunächst eine Vorschau. Erst die Auswahl speichert lokale Karten in `user.db`. Schema v9 vermerkt die vom Server bestätigte Gratisherkunft in einer separaten lokalen Tabelle ohne Änderung des bestehenden Sync-Formats, damit diese Karten offline im Stapel und in Gemischt übbar bleiben. Ein Premium-Ergebnis wird ohne diesen Marker ausgeliefert. Der Client verwendet ausschließlich HTTPS, folgt keinen Redirects und begrenzt Antworten beim Lesen auf 300.000 Byte; die Function hat eine 110-Sekunden-Deadline, der Client 120 Sekunden. Kontowechsel, Sprachwechsel oder Widerruf der Einwilligung verwerfen veraltete Ergebnisse vor Übernahme. Keine Themen, Anbieterantworten, Nutzer-IDs oder Zugangsdaten in Logs.

Stand 31.10.2026: Die Migration ist remote angewandt und die Function `generate-vocabulary` ist deployed. Synthetische Liveproben aller fünf Sprachen mit je bis zu 50 Karten und identischem Status-Replay waren erfolgreich; Details und akzeptierte Anzahlen stehen im Arbeitsbericht. Deployment, lokale Regressionstests, sprachliche Qualität und Geräteabnahme sind getrennte Nachweise.

Stand 15.11.2026: Die aktualisierte Function `generate-vocabulary` (Version 12) wurde vor Migration `20261115000001` ausgerollt; beide sind aktiv. Remote geprüft: eindeutiger Gratisindex, Verfügbarkeit nur für authentifizierte Konten, Reservierungsfreigabe nur für `service_role`; anonyme Function-Aufrufe liefern HTTP 401. Diese Prüfung hat keine echten Nutzerkontingente verbraucht. Lokale PostgreSQL- und Deno-Tests prüfen parallele Vergabe, Wiederaufnahme und Kostenlimits.

## Tägliche Nachrichten (vorbereitet, nicht veröffentlicht)

Auf Nutzerwunsch vom 01.11.2026 vorerst ausgeblendet. Migrationen und Function liegen in `supabase/drafts/daily-news/` und sind weder angewandt noch deployt. Geplant: `refresh-news` (ohne Nutzer-JWT, mit gemeinsamem Geheimnis `NEWS_CRON_SECRET` aus Vault) wird täglich je Ressort von `pg_cron` aufgerufen. Claude Haiku 5.5 sucht mit dem Websuche-Tool und schreibt B1-Artikel mit deutschen Satzübersetzungen für alle Lernsprachen. Die Artikel liegen in `app.news_articles`, schreibbar nur über `store_news` (service_role). Lesbar sind sie öffentlich über `latest_news(p_lang)`. Einrichtung, Kosten und Prüfungen: [daily-news.md](daily-news.md).

## Weiterhin Entwurf: `sentence-check`

Story-Satzprüfung/Umschreiben ist nicht implementiert und wird durch diesen Auftrag nicht aktiviert. SRS, Antwortbewertung, Produktionspacks, redaktionelle Übersetzungen und bestehende Lernstände bleiben unverändert.

## AI-Tutor (22.11.2026, implementiert, noch nicht veröffentlicht)

`POST /functions/v1/tutor-generate` und `POST /functions/v1/tutor-grade` benötigen
`Authorization: Bearer <Supabase-Access-Token>`, ein bestätigtes, nicht-anonymes
Konto und die widerrufbare KI-Einwilligung. **Beide Requests enthalten zusätzlich
zum Planvertrag `consent: 1`** (bestätigte Vertragsergänzung vom 22.11.2026, wie
bei den bestehenden KI-Functions). Fehlt der Wert oder wurde die Einwilligung
widerrufen, darf der Client nicht senden; der Server verweigert Requests ohne
`consent: 1` mit `CONSENT_REQUIRED` (403). Es gibt keine zentrale Consent-Tabelle;
dies ist der ausdrückliche Nachweis pro Request, kein dauerhaft gespeicherter
Server-Consent. Nutzer-ID, Premiumstatus, Prompt und Fehlerkontext zur Bewertung
kommen ausschließlich aus Auth bzw. der Datenbank.

Generierung, exakter Beispielrequest:

```json
{
  "request_id": "12345678-1234-4234-8234-123456789abc",
  "lang": "en",
  "items": [{ "skills": ["past_simple"], "kind": "translate" }],
  "avoid_topics": ["alltag"],
  "consent": 1
}
```

Antwort 200:

```json
{
  "items": [{
    "id": "22345678-1234-4234-8234-123456789abc",
    "kind": "translate",
    "prompt_de": "Ich ging gestern ins Kino.",
    "reference_answer": "I went to the cinema yesterday.",
    "skills": ["past_simple"],
    "topic": "kultur"
  }]
}
```

`lang`: `en`, `pt-BR`, `es`, `it`, `nb`. `items`: 1–5, je 1–2 eindeutige IDs aus
`supabase/functions/_shared/tutor_skills.json` für diese Sprache. `kind` ist
optional (`translate` oder `situation`); `parent_item_id` ist eine optionale UUID
für eine eigene noch gespeicherte Elternaufgabe. `avoid_topics` ist erforderlich,
höchstens acht verschiedene Katalogthemen, leere Liste erlaubt. Jede Ausgabe
entspricht der Position ihrer Anfrage. Die Hauptfähigkeit bleibt erhalten;
bei einer Neugenerierung müssen beide Fähigkeiten samt Reihenfolge der
Elternaufgabe entsprechen. Elternaufgabe und Fehler aus deren letzten acht
gespeicherten Versuchen lädt der Server selbst. Die neue Aufgabe muss ein
anderes Thema und einen anderen Prompt als die Elternaufgabe haben.

`prompt_de` enthält ausschließlich den deutschen Satz oder die Situationsfrage,
8–160 UTF-16-Einheiten, höchstens zwei Sätze, Schlusspunkt/Frage-/Ausrufezeichen;
Situationen enden mit `?`. Instruktionspräfixe (`Übersetze`, `Übersetzen Sie`,
`Translate`, `Bitte`), führende Labels mit Doppelpunkt, umschließende Anführungszeichen
und Kontrollzeichen werden verworfen, nicht still entfernt. Referenz: 2–200
Einheiten, ungleich dem Prompt. Katalog-IDs, Themenausschlüsse, Reihenfolge,
Feldschema und Grenzen werden im Code geprüft. Sprache, Alltagstauglichkeit und
inhaltliche Angemessenheit werden im Systemprompt vorgegeben; diese semantischen
Eigenschaften sind durch die formale Validierung allein nicht bewiesen.

Bewertung, exakter Beispielrequest:

```json
{
  "attempt_id": "32345678-1234-4234-8234-123456789abc",
  "item_id": "22345678-1234-4234-8234-123456789abc",
  "answer": "I goed to the cinema yesterday.",
  "consent": 1
}
```

Antwort 200:

```json
{
  "scores": { "meaning": 2, "grammar": 0, "naturalness": 1 },
  "outcome": "incorrect",
  "errors": [{ "skill": "past_simple", "severity": "major", "quote": "goed", "fix": "went" }],
  "feedback_de": "Die Vergangenheitsform von go ist went.",
  "ideal_answer": "I went to the cinema yesterday.",
  "quota": { "used": 1, "limit": 3 }
}
```

`answer`: nach Trimmen 1–300 UTF-16-Einheiten, keine Kontroll-/Formatzeichen.
Weitere Requestfelder werden abgewiesen, insbesondere clientseitige Prompts,
Zielfähigkeiten oder Scores. Die Antwort steht im Modellinput als untrusted
JSON-Daten. Scores sind ganze Zahlen 0–2, höchstens vier Fehler mit Katalog-ID
der Lernsprache oder `other`; `quote` ist ein echter Ausschnitt der Nutzerantwort,
`quote`/`fix` je höchstens 60 Einheiten. Feedback: 1–2 deutsche Sätze, maximal 220;
Idealsatz: maximal 200, gültige Nutzerentscheidungen mit minimalen Änderungen
erhalten. Die gesamte Rubrik einschließlich der „Nie Fehler“-Liste steht im
Systemprompt. `tutorOutcome(scores: TutorScores, errors: readonly TutorError[],
targetSkills: readonly string[]): TutorOutcome` in `_shared/tutor_contract.ts`
(auch aus `_shared/tutor.ts` exportiert) berechnet in dieser Reihenfolge:
`correct` bei Bedeutung=2, Grammatik=2, Natürlichkeit≥1; sonst `acceptable` bei
allen Scores≥1 und keinem major-Fehler in einer Zielfähigkeit; sonst `incorrect`.
Ein tabellengetriebener Test prüft alle 27 Scorekombinationen und Fehlerpositionen.

Free: 3 Bewertungen und 6 generierte Aufgaben pro **Europe/Berlin-Kalendertag**;
Premium: 150 und 60. Grenzen gelten gemeinsam über alle Sprachen. Premium wird
aus aktiven serververifizierten Production-/zulässigen Sandbox-/Complimentary-
Entitlements mit gültigen Zeiträumen bestimmt. `claim_tutor` reserviert die ganze
Anfrage atomar unter Kontosperre, bevor das Modell läuft. `quota` ist der bei
Reservierung gespeicherte Stand (einschließlich dieser Anfrage); ein Replay
liefert denselben Stand, keinen aktuellen Tageszähler. Bereits gestartete,
fehlgeschlagene oder unklare Provideraufrufe zählen weiter. Nur nachweislich
vor Providerdispatch beendete Versuche geben die Tagesreservierung frei.

Dieselbe normalisierte UUID und derselbe Inhalt liefern das gespeicherte Ergebnis
ohne erneute Kosten oder Zählung; geänderter Inhalt → `CONFLICT` 409. Laufende,
fehlgeschlagene, unklare und abgelaufene IDs werden niemals erneut an das Modell
gesendet. Für Ergebniswiederaufnahme denselben POST senden, kein separater
Statusparameter. Neue Versuche brauchen eine neue UUID. Beide Functions haben
55 Sekunden Deadline, Requests sind auf 8.192 Byte begrenzt. Kein automatischer
Retry, kein Fallback, keine Logs mit Prompts, Antworten oder Zugangsdaten.

Fehlerantwort: `{ "error": "CODE" }`, zusätzlich bei Tageslimit z. B.
`{ "error": "TUTOR_DAILY_LIMIT", "premium_required": true, "quota": { "used": 3, "limit": 3 } }`.

| HTTP | Codes |
|---|---|
| 401 | `AUTH_REQUIRED` |
| 403 | `CONSENT_REQUIRED`, `ACCOUNT_UNVERIFIED` |
| 404 / 410 | `ITEM_NOT_FOUND` / `ITEM_EXPIRED`, `REQUEST_EXPIRED` |
| 405 / 413 / 422 | `METHOD_NOT_ALLOWED` / `BODY_LIMIT` / `INPUT_INVALID`, `JSON_INVALID` |
| 409 | `CONFLICT`, `REQUEST_PENDING`, `REQUEST_UNCERTAIN`, `REQUEST_FAILED` |
| 429 | `TUTOR_DAILY_LIMIT` (`premium_required: true` nur für Free), `AI_MONTHLY_LIMIT` |
| 502 | `MODEL_INVALID`, `MODEL_UNAVAILABLE` |
| 503 / 504 | `NOT_CONFIGURED`, `AI_BUDGET_UNAVAILABLE`, `STORAGE_UNAVAILABLE`, `SERVICE_UNAVAILABLE` / `TIMEOUT` |

`app.tutor_items` und `app.tutor_attempts` sind RLS-geschützt, eigene noch nicht
abgelaufene Zeilen lesbar, ausschließlich durch Service-Rolle schreibbar.
`app.tutor_requests` hält die privaten Reservierungen und Replay-Ergebnisse und
ist auch beim Lesen ausschließlich für die Service-Rolle zugänglich. Nach
30 Tagen werden Prompts, Referenzen, Fähigkeiten/Themen, Antworten, Bewertungen
und Ergebnis-JSONs durch den bestehenden stündlichen `purge-private-ai`-Job
gelöscht; Hash-/ID-Tombstones verhindern Replay bis zur Kontolöschung. Abgelaufene
Inhalte werden bereits vor dem nächsten Cronlauf nicht mehr ausgeliefert. Alle
Tutorzeilen werden bei Kontolöschung kaskadierend entfernt. Lokale Lernstände
und deterministisches Scheduling werden hier nicht gespeichert.

Reproduktion ohne Anbieteraufruf, Windows PowerShell und macOS Terminal identisch:

```text
deno test --allow-all supabase/functions/_shared/tutor_contract_test.ts supabase/functions/_shared/tutor_test.ts
deno check supabase/functions/tutor-generate/index.ts supabase/functions/tutor-grade/index.ts
supabase test db supabase/tests/database/tutor_test.sql
node supabase/tests/run_tutor_sql.mjs
```

Der letzte Befehl ist die Alternative bei belegten lokalen Supabase-Ports: Er
verwendet einen temporären Docker-PostgreSQL-Container ohne Host-Port/Netzwerk,
synthetische Auth-/Entitlement-Voraussetzungen und unveränderte Migration und
pgTAP-Datei. Zusätzlich laufen parallele echte PostgreSQL-Sessions gegen die
Quoten und dieselbe Anfrage-ID. Der Container wird anschließend entfernt.

Noch kein Deployment, keine echten Anthropic-Aufrufe und keine sprachliche
Live-Abnahme. Budgetdetails: [AI-Tutor-Kostengrenze](ai-cost-limit.md#ai-tutor).
