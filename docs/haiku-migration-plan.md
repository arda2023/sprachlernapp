# Haiku-Migrationsplan zur Abnahme

Stand und Quellenabruf: **18.10.2026**. Basis: `6deba380042578a5cee96af24988db9d713e02ba`, Branch `codex/portuguese-package-2`.

## Entscheidung und Umfang

Die **Stapelphase ist beendet**. Nächste Produktphase: UI, Lernalgorithmus und Funktionen. Keine neuen Stapel, Reservierungen, Sätze oder Produktionsläufe für diesen Wechsel.

Empfehlung: Google Cloud/Vertex weiterverwenden, Modell **`claude-haiku-5-5`**, für einen späteren genehmigten Umbau ausdrücklich **EU-Multiregion `eu`** wählen. Die API ist unterstützt und preislich plausibel; Projektfreischaltung, eigene Quoten, Qualität und tatsächlicher Verbrauch sind noch nicht nachgewiesen. Dieser Bericht autorisiert keine Einrichtung oder Modellanfrage.

Der zentrale Textzugriff existiert in der **Offline-Pipeline**, nicht im Laufzeitbackend. Die drei in `docs/backend.md` beschriebenen KI-Edge-Functions sind Entwürfe. Es gibt deshalb keinen vorhandenen App-Gemini-Aufruf, den man durch Austausch eines Modellnamens migrieren könnte. Kleinster technischer Auftrag ist der lokale Umbau des vorhandenen Pythonwrappers samt Vertragstests. Weil die Stapelproduktion abgeschlossen ist, ist selbst dieser Umbau für die nächste UI-/SRS-Arbeit nicht Voraussetzung. Laufzeit-KI bleibt ein eigenes späteres Funktionspaket.

Vor Beginn: Index leer, keine Änderungen versionierter Dateien; einzig fremd/unversioniert: `published-baseline-transfer/`. Dieses Verzeichnis blieb unangetastet. Gelesen wurden die vorgegebenen sieben Projekt-/Detaildokumente sowie `CLAUDE.md`, gezielte Quellstellen und öffentliche Konfigurationsvorlagen. Keine `.env`, ADC-Datei, Dienstkontodatei oder echte `user.db` geöffnet; keine Secretwerte abgerufen. Historischer NEXTSTEPS-Ausgangstext bleibt über obigen Gitstand vollständig rekonstruierbar; relevante offene Punkte sind unten und im gekürzten Status erhalten.

## 1. Tatsächliche Verwendung im Repository

### Einziger zentraler generativer Transport

`pipeline/src/sprachpipe/llm.py:114–210`: `Llm.generate_json(prompt, schema, *, model, thinking, step, max_output_tokens)` reserviert Kosten, ruft `_call` auf und liefert ein geparstes JSON-Objekt. `_call` baut `GenerateContentConfig(response_mime_type="application/json", response_json_schema=schema, thinking_config=ThinkingConfig(**thinking), max_output_tokens=…)`; `client.models.generate_content` führt den kostenpflichtigen Aufruf aus. `genai.Client(vertexai=True, project=…, location=…)` verwendet ADC. Kein expliziter URL-String im Code; logisch Vertex REST `POST https://aiplatform.googleapis.com/v1/projects/sprachlernapp-510508/locations/global/publishers/google/models/{model}:generateContent` (SDK-Transport kann seine API-Version setzen; kein mitgeschnittener Netzwerkbeleg).

Öffentlich konfigurierte Werte in `pipeline/config.yaml:prices,llm`:

| Schlüssel | Tatsächlicher Wert / Verwendung |
|---|---|
| `project`, `location` | `sprachlernapp-510508`, `global` |
| `generate_model`, `generate_thinking` | `gemini-3.8-flash`, `{thinking_level: LOW}` |
| `meaning_check_model`, `meaning_check_thinking` | `gemini-3.8-flash`, `{thinking_level: LOW}` |
| `alternative_check_model`, `alternative_check_thinking` | `gemini-3.8-flash`, `{thinking_level: LOW}` |
| `blindtest_model`, `blindtest_thinking` | `gemini-2.5-flash`, `{thinking_budget: 0}`; auch Klassifikation |
| `timeout_s` | 90 Sekunden je SDK-Anfrage |
| `max_output_tokens` | meanings 2048; sentences 2048; annotate 4096; blindtest 256; meaning_check 4096; classify_usage 1024; alternative_check 1024 |

`pipeline/pyproject.toml` und `pipeline/requirements.lock`: `google-genai==2.28.0`, Lock außerdem `google-auth==2.59.1`; kein Anthropic-SDK. `jsonschema==4.26.0` bereits vorhanden. `config.py:load_config` liest YAML, `load_env` lädt optional `pipeline/.env`. Vorlage `pipeline/.env.example`: nur `SUPABASE_DB_URL`, kein KI-API-Key. Root-`.env.example`: `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` für Backendzugang, keine Modellkonfiguration. Keine Werte aus realen Umgebungen geprüft.

### Funktionen, die wirklich den Wrapper aufrufen

| Datei / Symbol / Aufrufstelle | Aufgabe und fachlicher Vertrag | Auslöser / Status |
|---|---|---|
| `pipeline/src/sprachpipe/generate.py:100,113` `meanings` | Bedeutungen, Form-/Lemma-/Sense-Metadaten, deutsche Glossen | CLI-Generierung; vorhandenes `MeaningInventory.get(form)` wird ohne `refresh` wiederverwendet |
| `pipeline/src/sprachpipe/generate.py:141,159` `sentences` | Kandidatensätze plus `translation_de`; Anzahl wird geprüft | CLI-Generierung, kein eigenständiger App-Übersetzungsdienst |
| `pipeline/src/sprachpipe/annotate.py:61,78` `annotate_card` | Lemma und Glosse je Worttoken; `sentences[].sentence_idx`, `tokens[]` | Nach akzeptiertem Satz; prüft Zahl, Index, Oberfläche, Ziellücke und vollständige Abdeckung |
| `pipeline/src/sprachpipe/blindtest.py:21,28` `ask` | `answer`, bis drei Alternativvorschläge | Offline-Lückentest, eigene Normalisierung; Kandidaten sind keine akzeptierten Antworten |
| `pipeline/src/sprachpipe/meaning_check.py:48,63` `check` | `sense_key`, `observed_pos`, `translation_ok`, `language_ok`, `reason` | Offline-Sinn-/Sprach-/Übersetzungsprüfung; explizite Diagnose-Overrides möglich |
| `pipeline/src/sprachpipe/alternative_check.py:51,65` `check` | Verdict je vollständig eingesetztem Kandidaten | Kein Aufruf bei leerer Kandidatenliste; höchstens vier Kandidaten pro regulärem Aufruf |
| `pipeline/src/sprachpipe/classify.py:8,18` `classify_form` | `usages` mit exakt vorhandenen Sense-Keys und Enum `haupt/neben/selten` | CLI `classify-usage`, nur Pipelinewerkzeug |

CLI-Einstiege: `pipeline/src/sprachpipe/cli.py:cmd_generate` (Wrapperinstanz Zeile 278), `cmd_generate_selection` (316), `cmd_classify_usage` (344). `_process_card:108` verbindet Satzkandidaten → Linter → Blindtest → Bedeutungs-/Alternativenprüfung → Annotation. Kandidatenrunden **5/3/3**, nur ein aktiver Satz angenommen; zusätzlich Linter-Neuerzeugungen maximal 2, gemeinsamer Blindtest-Neuversuch maximal 1 (`generate.py:176–…`). Diese fachlichen Aufrufe vervielfachen Transportkosten. Alte 3-Satz-Läufe in `docs/pipeline.md` sind historische Stände, kein aktueller Produktionsauftrag.

### App-Aktionen und Backend

| Aktion | Belegter Pfad | Kostenpflichtiger Modellaufruf heute |
|---|---|---|
| Wort im annotierten Reader antippen | `lib/screens/stories/story_reader_screen.dart:_addAnnotated` (140–174), `_lookUp` (ab 299); `story_learning_providers.dart:StoryLearningController` lädt Kandidaten aus Content-/Nutzerrepository | **Keiner**; Token trägt Kontextglosse, sonst „Übersetzung nicht verfügbar“ |
| Satzübersetzung antippen | Reader `_translate` (253–261) → `SentenceTranslationSheet.show`; `document.sentences[index].translation` | **Keiner**; gespeicherte deutsche Übersetzung |
| Platzhalter-/Newsreader | Reader-Konstruktor `sampleLookup` / `sampleTranslateSentence` aus `lib/models/sample_content.dart` | **Keiner**; synchrone lokale Beispieldaten |
| Story-Wort zum Lernen hinzufügen | `lib/presentation/providers/story_learning_providers.dart:add`, `PracticeItemResolver`, lokale Speicherung | **Keiner**; exakte Identität, feste bereits geprüfte Kontexte |
| Vorlesen im Storyreader | `PlaybackClock.forText`, `lib/models/playback_clock.dart:play` mit `Timer.periodic` | **Keiner**; simulierte Zeitsteuerung, kein TTS-Modell |
| Importtext: Wörterbuchmiss, Satzübersetzung, Satzprüfung | In `PRODUCT.md` / `docs/backend.md` vorgesehen | **Noch nicht implementiert**; kein entsprechender Client-Aufrufer oder Edge-Handler gefunden |

`supabase/functions/` enthält nur `health/index.ts` (GET/Status), `content-publish/index.ts`, `content-release/index.ts` und gemeinsame Distributions-/Verifikationsdateien. Diese publizieren/liefern Inhalte, rufen kein Textmodell auf. Kein vorhandener zentraler KI-Edge-Wrapper, kein ausgeführter `GCP_SA_KEY`-Authentifizierungspfad. Backenddokumentation nennt dieses Secret erst als Zielarchitektur. `usage`/Tageslimits und `{cached:…}` der drei KI-Endpunkte sind damit keine belegten laufenden Schutzmechanismen.

Keine Treffer für `lookup-word`, `translate-sentence`, `sentence-check`, `functions.invoke`, Gemini-/Vertex-Transport in `lib/`; Transport-Literalsuche in `pipeline/src/` und Functions bestätigt obigen einzigen Textzugriff. Aussage gilt für den untersuchten Repositorystand, nicht für unbekannte Clouddeployments. Editor/Offline-Create bleiben modellfreie Import-/Validierungswege. Audio/TTS und Embeddings sind kein Teil dieses Textwechsels; kein generativer Embedding-Aufruf in den untersuchten Pfaden gefunden.

### Caches, Fehler und bestehende Grenzen

- Lokales Wörterbuch, Tokenannotation und Satzübersetzungen verhindern bereits Modellbedarf. Riverpod hält geladene Daten; die einschlägigen Storyprovider deaktivieren automatische Provider-Retries (`retry: (_, _) => null`). Das ist kein kostenpflichtiger KI-Cache.
- Pipeline: persistentes Bedeutungsinventar als Wiederverwendung; keine allgemeine Antwortcache-Schicht, keine expliziten Vertex-Promptcacheparameter im Wrapper. Ein Datenbank-/Releasecache ist kein Provider-Tokenrabatt.
- Wrapper: `range(5)` = **bis fünf Versuche insgesamt** für 429/500/502/503/504 bzw. RESOURCE_EXHAUSTED; exponentieller Jitter. 401/403 setzen laufweiten Auth-Abbruch, keine Wiederholung. Netzwerk-/Timeoutfehler werden derzeit `LlmError`, ohne eigenen Retry. JSON-Parsefehler: kein Repair/Retry; Diagnose nennt Modell, Limits, Token und Finishgrund. Raw-Providerfehlermeldung kann heute über `e.message` weitergereicht werden: für künftige Nutzung persönlicher Texte zu bereinigen.
- `cost.py`: CSV mit Zeit, Schritt, Modell, Eingabe-/Ausgabe-/Denktokens, USD; keine Prompt-/Antwortspalten. `llm.py` reserviert nebenläufig unter Lock vor Aufruf (`prompt_chars // 2 + 1`, volles Ausgabelimit), gleicht zurückgemeldete Nutzung ab. Zeichenheuristik ist keine nachgewiesene obere Tokenschranke. Nicht beantwortete, möglicherweise abgerechnete Versuche sind nicht verlässlich erfasst; SDK-interne Wiederholungen wurden nicht gemessen. Fehlende `usage_metadata` wird im Zählerpfad zu null, obwohl Parse-Diagnose „unbekannt“ kennt. Dies darf bei Haiku nicht als kostenlose Nutzung fortgeschrieben werden.

## 2. Offiziell unterstützter Haiku-Zugang

### Modell, Region und Daten

Google führt `claude-haiku-5-5` als GA. Modellverfügbarkeit: **US-Multiregion, Europa-Multiregion, global**; separat genannte ML-Verarbeitung in Asien ist keine Freigabe eines dortigen Anfrageendpunkts. Keine Zusage für `europe-west3`/Frankfurt aus der Modellkarte ableiten. [Google-Modellkarte](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/haiku-5-5), Abruf 18.10.2026.

Ist: Supabase laut Architektur EU Frankfurt, Pipeline und Backend-KI-Entwurf `global`. Das ist **keine belegte EU-Bindung des heutigen Modellwegs**. Vorschlag für neue Textnutzung: `eu` mit EU-Routing, nicht stillschweigend `global`. Falls ausschließlich Frankfurt verlangt wird, ist Haiku 5.5 anhand der vorliegenden Regionsliste dafür nicht freizugeben; Region bleibt dann ein Blocker für die spätere Inbetriebnahme.

Geplanter SDK-Zugang: `AnthropicVertex(project_id="sprachlernapp-510508", region="eu", max_retries=0, timeout=30.0)`. EU-Routing und 10 % Aufpreis sind dokumentiert. [Anthropic: Google Cloud](https://platform.claude.com/docs/en/build-with-claude/claude-on-vertex-ai), Abruf 18.10.2026.

Konkreter REST-Vertrag für späteren Nonstreaming-Aufruf:

```text
POST https://aiplatform.eu.rep.googleapis.com/v1/projects/sprachlernapp-510508/locations/eu/publishers/anthropic/models/claude-haiku-5-5:rawPredict
Authorization: Bearer <OAuth-Zugriffstoken aus ADC/Dienstkonto>
Content-Type: application/json
```

Body enthält `anthropic_version: "vertex-2023-10-16"`, `messages`, `max_tokens`, `thinking`, `output_config`; `model` steht bei REST im URL-Pfad. Das SDK setzt diesen Vertrag aus `messages.create(model=…)` um. Host- und Pfadbildung zusätzlich im [offiziellen Anthropic-Pythonclient](https://github.com/anthropics/anthropic-sdk-python/blob/main/src/anthropic/lib/vertex/_client.py) geprüft (Abruf 18.10.2026; beweglicher main-Stand, später installierte Version dagegen testen). Nicht den Gemini-`generateContent`-Vertrag wiederverwenden.

EU-Routing allein belegt weder individuelle Vertragsfreigabe noch vollständige Aufbewahrungs-/Loggingkonformität. Vor persönlichem Textbetrieb Google-Verarbeitung, Modellbedingungen und vorhandene Loggingeinstellungen prüfen; keine Prompt-/Completionprotokollierung aktivieren. Bestehende EU-Datenhaltung in Supabase erhalten. Projekt-IAM, Billing, Modellfreischaltung und Cloud-Logging wurden hier nicht abgefragt.

### Authentifizierung und Freischaltung

Vorhandener ADC-Zugang bleibt für das lokale Werkzeug nutzbar. Später muss ein berechtigter Administrator die Haiku-5.5-Modellkarte im Projekt freischalten und Bedingungen akzeptieren; Freischaltrolle `roles/consumerprocurement.entitlementManager`, Inferenzberechtigung `aiplatform.endpoints.predict` (z. B. `roles/aiplatform.user`). Organisationsrichtlinien, Beschaffung/Billing und EU-Quote gesondert prüfen. Kein eigener Modellserver nötig. [Google: Partnermodelle/IAM](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/use-partner-models), Abruf 18.10.2026.

Für den lokalen Wrapper **kein neues Secret** und kein `ANTHROPIC_API_KEY`. Explizite YAML-Werte sind den optionalen SDK-Umgebungsnamen `ANTHROPIC_VERTEX_PROJECT_ID`, `CLOUD_ML_REGION`, `ANTHROPIC_VERTEX_BASE_URL` vorzuziehen; Base-URL-Override darf EU-Routing nicht umgehen. Beim späteren Edge-Betrieb ist `GCP_SA_KEY` der bereits dokumentierte Secretname; noch kein implementierter Tokenaustausch und kein Beleg, dass dieses Secret remote eingerichtet ist.

Direkte Anthropic-API als konkrete Reserveoption: `POST https://api.anthropic.com/v1/messages`, Modell `claude-haiku-5-5`, `x-api-key` aus neuem serverseitigen Secret `ANTHROPIC_API_KEY`, Header `anthropic-version: 2023-06-01`. Sie wäre bei gescheiterter Google-Freischaltung technisch möglich, erfordert aber eigene Vertrags-/Datenregionsprüfung und Änderung der verbindlichen Vertex-only-Produktregel. Globaler Listenpreis spart gegenüber EU-Vertex nur den Regionsaufschlag; das begründet hier keinen Providerwechsel. Nicht als Fallback implementieren. [Messages-Referenz](https://platform.claude.com/docs/en/api/overview), [Haiku-Preise](https://platform.claude.com/docs/en/models/haiku-5-5/overview), Abruf jeweils 18.10.2026.

### Parameter und strukturierte Ausgabe

- Feste Modell-ID ohne Datumszusatz. `temperature`, `top_p`, `top_k` weglassen; keine Gemini-Samplingwerte übertragen. Kein Assistant-Prefill. [Haiku-Migrationsvertrag](https://platform.claude.com/docs/en/models/haiku-5-5/migration-guide), Abruf 18.10.2026.
- Günstigste erste Kandidatenkonfiguration für kurze Aufgaben: `thinking={"type":"disabled"}`, `output_config.effort="low"`. Haiku unterstützt ausgeschaltetes Denken bei low/medium/high; alternativ adaptive + low, wenn der Qualitätstest dies erfordert. Kein `thinking_budget`, `thinking_level` oder `budget_tokens`. Nicht still auf medium/high erhöhen. Denken ist sonst standardmäßig adaptiv und verbraucht Ausgabe-/`max_tokens`-Budget. [Effort-Vertrag](https://platform.claude.com/docs/en/build-with-claude/effort), Abruf 18.10.2026.
- JSON via `output_config.format={"type":"json_schema","schema":…}` auf Google Cloud unterstützt. Alle Objekte müssen `additionalProperties:false` tragen. Vorhandene Schemas enthalten `maxItems`, teils `minItems>1`; diese dürfen nicht direkt gesendet werden. Eine Kopie für den Transport passend reduzieren, Originalschema lokal vollständig mit `jsonschema` prüfen; fachliche Mengen/Enums/Offsets unverändert. Schema-Zusatzprompt kostet Eingabetokens. `stop_reason=refusal` und `max_tokens` sind Fehlerfälle trotz JSON-Ausgabemodus. [Structured Outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs), Abruf 18.10.2026.
- Antworttext anhand `content[].type == "text"` auswählen, nicht den ersten Block blind parsen. Nur vollständig beendete, validierte Antwort als Erfolg behandeln. Providerusage abbilden: Anthropic-Ausgabetokens enthalten Denken bereits; nicht nochmals einen fiktiven Denktokenwert addieren. Bei späterem Promptcaching `input_tokens`, `cache_creation_input_tokens` und `cache_read_input_tokens` getrennt zum jeweiligen Tarif abrechnen; nicht als dieselbe Eingabemenge doppelt zählen.

## 3. Kostenvergleich mit denselben Aufgaben

USD, Listenpreise ohne Steuern, Credits oder verhandelte Rabatte; Standard-On-Demand, kurze Prompts. [Google-Preisliste](https://cloud.google.com/gemini-enterprise-agent-platform/generative-ai/pricing) und [Anthropic-Haiku-Preise](https://platform.claude.com/docs/en/models/haiku-5-5/overview), Abruf 18.10.2026:

| Modell / Ort | Input / 1 Mio. | Output inkl. Denken / 1 Mio. |
|---|---:|---:|
| Gemini 3.8 Flash, tatsächlich global, bis 31.12.2026 | 0,75 | 3,75 |
| Gemini 3.8 Flash, global ab 01.01.2027 | 1,50 | 7,50 |
| Gemini 2.5 Flash, global | 0,30 | 2,50 |
| Haiku 5.5, global / direkte API, kurzer Kontext | 0,10 | 0,50 |
| Haiku 5.5, vorgeschlagen EU | 0,11 | 0,55 |

**Rechenannahmen, keine Messung:** je Modell 1.000 Requests mit denselben fachlichen Prompts/Antworten, zunächst gleiche Tokenzahlen als Vergleichsnorm; kompletter Prompt inkl. Instruktionen/Schema. Null Thinking, keine Retries, kein Cache. Für Haiku `rI/rO` als unbekanntes Verhältnis seiner Tokenisierung zur Gemini-Tokenisierung einsetzen:

`Kosten_1000 = (I * rI * Inputpreis + (O * rO + T) * Outputpreis) / 1000`.

| Aufgabe | angenommene Tokens I/O je Request | Gemini 3.8 global | Gemini 2.5 global | Haiku EU, rI=rO=1 | Haiku EU, rI=rO=1,3 |
|---|---:|---:|---:|---:|---:|
| Kontextbedeutung / Klassifikation | 600 / 120 | 0,9000 | 0,4800 | 0,1320 | 0,1716 |
| Kurze Satzübersetzung (heute nur als Teil der Satzgenerierung) | 400 / 100 | 0,6750 | 0,3700 | 0,0990 | 0,1287 |
| Satz-/Sinn-/Alternativenprüfung | 900 / 250 | 1,6125 | 0,8950 | 0,2365 | 0,30745 |
| Annotation / ausführlichere strukturierte Antwort | 1500 / 600 | 3,3750 | 1,9500 | 0,4950 | 0,6435 |

Die Gemini-2.5-Spalte ist besonders für Blindtest/Klassifikation relevant; sie behauptet keine Umkonfiguration anderer Schritte. Gemini-3.8-Preise verdoppeln sich laut aktueller Liste ab 2027. Die 1,3-Spalte ist eine Sensitivitätsannahme gegenüber Gemini: Anthropic nennt ca. 30 % mehr Tokens **gegenüber Haiku 4.5**, nicht gegenüber Gemini. Eigene Tokenzählung beider Modelle ist erforderlich; Zahlen nicht als Einsparungsprozente ausgeben.

Bei je 100 zusätzlichen Denktokens/Request erhöhen sich 1.000 Requests um 0,375 USD (3.8), 0,250 USD (2.5), 0,055 USD (Haiku EU). Durchschnittlich 10 % vollständige Wiederholungen bedeuten ungefähr Faktor 1,10; fünf vollständige Versuche Faktor 5 vor fachlichen Neugenerierungen. Fehlerabrechnung hängt vom tatsächlichen Versuchsverlauf ab, deshalb keine pauschale Gebührenfreiheit unterstellen.

Cachepreise pro Mio. Tokens bei Haiku kurz/global: 5-Minuten-Schreiben 0,125, 1-Stunde-Schreiben 0,20, Lesen 0,01 USD; EU jeweils ×1,10. Mindestcachelänge 512 Tokens. Oberhalb der kurzen Haiku-Kontextstufe gelten höhere Preise (global 0,50/2,50; EU 0,55/2,75); für diesen Plan bewusst deutlich unter 100.000 Inputtokens bleiben. Grenzfall exakt 100.000 konservativ als höhere Stufe behandeln, da Googles Tabellenfußnote und Spaltenbezeichnung nicht identisch sind. [Haiku-Spezifikation](https://platform.claude.com/docs/en/models/haiku-5-5/overview), [Google-Preisliste](https://cloud.google.com/gemini-enterprise-agent-platform/generative-ai/pricing), Abruf 18.10.2026.

Gemini-Cache-Hitpreise derzeit 0,075 (3.8 global) bzw. 0,03 (2.5); explizite Caches können zusätzlich Speicher kosten. Es wird heute im Wrapper kein solcher Cache angelegt. Haiku-Prefixcache lohnt nur bei ausreichend langen wiederholten Präfixen; seine Schreibkosten in den ersten Request einrechnen. Lokaler exakter Antworttreffer kostet **null Modellrequests**, ganz unabhängig davon. Batchrabatte bleiben außerhalb dieses synchronen Funktionsplans.

Es fehlen repräsentative en-/pt-BR-Verbrauchsdaten mit gleichen Aufgaben, Haiku-Tokenzahlen, Fehlerraten, Latenzen und Qualitätsabnahme. Historische Pipeline-Smokes in `docs/pipeline.md` sind kein Laufzeitprofil. Kein persönliches Ledger oder Cloudbilling ausgewertet. Daher: belegter **Listenpreis-/Szenarienvergleich**, keine Behauptung tatsächlicher Einsparungen; aktueller belegter App-Modellverbrauch aus diesen Aufrufwegen: null Requests, kein monetäres Einsparpotenzial durch bloßen Clientwechsel.

## 4. Kleinster späterer Umsetzungsauftrag

**Paket A, lokal und modellfrei testbar; separat zu beauftragen.** Keine neue Providerplattform, kein neues Appfeature. Bestehendes `Llm.generate_json`-Interface und alle fachlichen Caller behalten. Vor jedem Symboledit erneut Impact prüfen.

| Exakte Datei | Begrenzte Änderung / Schnittstelle |
|---|---|
| `pipeline/src/sprachpipe/llm.py` | `client` auf gepinntes `AnthropicVertex`; `_call` auf Messages umstellen. Gleiches Rückgabe-Tupel für interne Nutzung; gesamtes Anthropic-`output_tokens` als abrechenbare Ausgabe, `thinking_tokens=0` für diese Abrechnungskonvention dokumentieren (kein Beweis für null internes Denken). Nutzungsdaten dürfen nicht doppelt zählen. Originalschema lokal validieren; transportspezifische Schemakopie kapseln. Fehler nach Code statt Rawtext klassifizieren. Kein teureres Ersatzmodell und kein Gemini-Fallback. |
| `pipeline/config.yaml` | Vier `*_model`-Slots auf `claude-haiku-5-5`; zugehörige `*_thinking` auf `{type: disabled}`, neuer gemeinsamer `effort: low`; Projekt beibehalten, `location: eu` ausdrücklich dokumentieren. EU-Preiszeile mit Datum und Kontextgrenze. `timeout_s: 30`, `max_attempts: 3`; Ausgabelimits vorerst maximal bestehende Schrittwerte, kein automatisches Aufweiten. |
| `pipeline/src/sprachpipe/cost.py` | Vorhandenes Ledger um sichere Versuchs-/Statusmetadaten nur soweit nötig ergänzen, historische CSVs weiter lesen. Fehlende usage = unbekannt, nicht null. Jede mögliche Wiederholung vorher budgetieren; ungewisse Timeoutkosten konservativ blockieren/reservieren. Kosten und parallel offene Reservierungen müssen unter Limit bleiben. |
| `pipeline/pyproject.toml`, `pipeline/requirements.lock` | Später kompatibles `anthropic[vertex]` exakt pinnen und Lock aktualisieren; Version gegen EU-Endpunkt/Schema-Unterstützung testen. `google-genai` erst entfernen, wenn separat verifizierte Skript-/Werkzeugabhängigkeiten dies erlauben. Hier keine Installation oder Lockänderung. |
| `pipeline/tests/test_generate.py`, `pipeline/tests/test_parallel.py`, `pipeline/tests/test_cost_schema.py` | Transport-/Usage-/Budget-Fixtures an neuen Vertrag anpassen; historische Rechenfälle erhalten. Authfehler ohne Retry, 429/5xx begrenzt, Timeoutbudget, unbekannte Nutzung, parallele Reservierung, Refusal, abgeschnittene Antwort und Fehlerredaktion gezielt prüfen. |
| neu `pipeline/tests/test_haiku_contract.py` | Netzfreier Fakeclient: Modell/Projekt/EU-Host, kein Sampling/Gemini-Parameter, Textblockauswahl, Schemakopie ohne Mutation, lokale Mengenprüfung und kein Fallback. |
| `docs/pipeline.md`, `docs/setup.md`, `docs/backend.md`, `ARCHITECTURE.md` | In Paket A nur aktuelle Transport-/Einrichtungsangaben zielgenau ergänzen; historische Laufbelege stehen lassen. Backendabschnitt weiterhin als nicht implementiert kennzeichnen. Keine Produktregel an Regression anpassen. |

Timeout-/Retryvertrag: SDK-`max_retries=0`, maximal drei äußere Versuche bei den bereits klassifizierten 429/5xx, je höchstens 30 s und zusätzlich 95 s Gesamtlaufzeit pro logischem Request inkl. Backoff; keine automatische Wiederholung bei 400/401/403/404/422, Refusal, Schemafehlern oder Truncation. Timeout zunächst als ungewiss abrechenbar behandeln und abbrechen. Begrenzung tatsächlich mit Deadline im Transport umsetzen, nicht nur Timeout zwischen empfangenen Bytes. Keine Promptreparaturschleife. `--max-usd` beibehalten; die bisherige Zeichenheuristik durch konservative, getestete Tokenreservierung ersetzen, im späteren Livevergleich per Modellzählung nachprüfen.

Sichere Diagnose: Provider, Modell, Region, Schritt, Versuch, Dauer, HTTP-/Fehlercode, Stopgrund, bekannte Tokenzahlen, Budgetreservierung, geschätzte USD; keine Schlüssel, OAuth-Tokens, Usertexte, Modellantworten oder Provider-Rawfehlermeldungen. Fehlende Messwerte explizit unbekannt. Telemetrieinhaltserfassung deaktiviert halten.

Vorhandene Callerdateien `generate.py`, `annotate.py`, `blindtest.py`, `meaning_check.py`, `alternative_check.py`, `classify.py` benötigen bei stabiler Schnittstelle keine fachlichen Änderungen. Lokale Originalschemavalidierung ergänzt ihre Prüfungen. Wenn beide QA-Rollen Haiku nutzen, ist der Blindtest weiterhin ein separater verdeckter Prompt, **kein unabhängiges zweites Modell**. Entsprechende aktuelle Beschreibung präzisieren; Qualität nicht aus Modellübereinstimmung ableiten.

**Paket B, erst später als eigene Funktion:** `supabase/functions/_shared/vertex_text.ts` als ein kleiner gemeinsamer Transport; neue `lookup-word/index.ts`, `translate-sentence/index.ts`, `sentence-check/index.ts` erst mit Auth-, atomarem Nutzungs-/Kostenlimit und Cachevertrag implementieren. Fachliche Requests/Responses aus `docs/backend.md` erhalten, Sprachkennung exakt `en`/`pt-BR`, Glosssprache `de`; fehlende runtimebezogene Cache-/Usage-Speicherung braucht dann einen gesonderten Migrationsentwurf. Keine universelle Providerabstraktion. Clientanbindung, Import-UX und persönliche Persistenz gehören ausdrücklich nicht zu Paket A. Bestehende `content-publish`-/`content-release`-Deployments brauchen für A keinerlei Änderung.

Für B lokale Wörterbuch-/Satztreffer vor Netz prüfen; Antwortcache nur privat und kontextgebunden (Sprache, Form/Sense bzw. Text, Vertrag-/Modellversion), keine nackte form→Glosse bei Mehrdeutigkeit. Modellcall nur bei der ausdrücklich angeforderten importierten Funktion. Deterministische Antwortprüfung, SRS, abgeleitete Zähler und vorhandene Übersetzungen bleiben lokal ohne KI.

## 5. Kleine Qualitätsabnahme en und pt-BR

Vor Livebetrieb **24 synthetische, vorab redigierte Fälle**, je Sprache zwölf. Goldenwerte inklusive Bedeutungsidentität, zulässiger Übersetzungsvarianten und exakter Form/Offsets vor dem Vergleich einfrieren; keine Produktionspacks oder Nutzertexte. en-only Pipelinefähigkeit beachten: `generate.py:16` enthält `LANG_NAMES={"en":"English"}`; pt-BR-Profil ist redaktionell/modellfrei. pt-BR-Prüfprompts deshalb als isolierte Vertragsfixtures auswerten, nicht den Produktionsgenerator dafür erweitern oder eine Sprachfreigabe behaupten.

| Je Sprache | Fälle / Annahme |
|---|---|
| 3 Kontextbedeutungen | en `left` links/verließ, `light` leicht/Licht, `bank` Ufer/Bank; pt-BR `manga` Mango/Ärmel, `banco` Bank/Sitz, `ficar` kontextgebunden; keine andere Sense akzeptieren |
| 2 Satzübersetzungen | Eine einfache, eine mit Negation/Zeit-/Pronomenbezug; pt-BR-Akzente und brasilianischer Gebrauch; kein erfundener Zusatz |
| 2 Storykontexte | Geeignetes Original ab drei Wörtern erhalten, auch mit Pronomen; Original aus 1–2 Wörtern verlangt redigierten vollständig annotierten Ersatz. Genau ein Satz, dieselbe Zielform/Bedeutung, keine Nachbarsatzverkettung |
| 2 QA-Fälle | Blindlücke und vollständige Einsetzung einer Alternative; Vorschlag allein erweitert niemals accepted/valid_alternatives |
| 2 Struktur-/Annotationfälle | Wort-/Satzindizes, Unicode/Mehrwortziel, vollständige Tokenabdeckung; fehlende/zusätzliche Elemente müssen scheitern |
| 1 Gebrauchsklassifikation | Exakt vorhandene Sense-Keys und erlaubte Enumwerte; keine neuen Senses |

Storyregeln folgen `docs/story-single-sentence-v1.md`: Original bevorzugen; Ersatz ab drei Wörtern nur mit konkreter Bedeutungs-/Übungsbegründung, niemals allein wegen „it“, unbekannter Person oder fehlender Handlung. Bereits fest gebundene Karten-/Gruppensätze werden durch Modelloutput nicht automatisch ersetzt. pt-BR weiterhin manuelle BR-Prüfung, technische Prüfung ersetzt keine Sprachfreigabe.

Abnahme: 100 % strukturell gültige erfolgreiche Antworten oder klarer kontrollierter Fehler; alle erwarteten Sense-/Form-/Negationsbindungen korrekt; keine unberechtigten Ersatzsätze; keine ungeprüften Alternativen; bilinguale redaktionelle Sichtung aller 24 Fälle, BR durch geeignete Prüfung. Refusals/Timeouts/Fehler als eigene Ergebnisse zählen, nicht aus der Quote entfernen. Qualität, Erstversuchserfolg, Gesamtkosten inkl. Wiederholungen und Latenz je Aufgabe vergleichen. Bei Fehlern lokale Hypothese nach 2–3 Versuchen ändern, nach fünf erfolglosen Prüfversuchen stoppen und Blocker benennen.

## 6. Konkrete nächste Einrichtung und spätere Messung

1. Plan abnehmen; UI-/Algorithmusarbeit kann ohne Modellumbau weitergehen. Falls der optionale Wrapperwechsel gewünscht ist: nur Paket A lokal implementieren und mit gemockten Requests gezielt prüfen. Dazu gehören später Installation/Lockupdate; im vorliegenden Plan nichts installiert.
2. Danach Administrator: bestehenden Projektzugang, Haiku-5.5-Freischaltung/Bedingungen, Prediction-IAM, EU-Routing und Budget/Quoten prüfen. Kein API-Key nötig; ADC weiterverwenden. Keine neue Stapelproduktion. Striktes Frankfurt wäre ein gesonderter ungelöster Regionskonflikt.
3. Erst mit eigenem Auftrag kostenbegrenzter Livevergleich: dieselben 24 synthetischen Fälle, je einmal Haiku und passendes bisheriges Gemini-Modell, höchstens **48 Modellversuche insgesamt**, Parallelität 1, keine automatischen Wiederholungen, **maximal 0,50 USD insgesamt** konservativ vor jedem Versuch reservieren. Ausgabe je Fall höchstens bisheriges Schrittlimit (max. 4096); Haiku EU, Gemini bestehendes global nur für diese synthetischen Vergleichsdaten ausdrücklich benennen. Tokenzählung und Schemaoverhead in Budget einbeziehen; bei unbekannter Abrechnung Lauf stoppen. Keine echten Nutzerdaten, kein Packexport. Erst messen, dann Modellentscheidung bestätigen.
4. Paket A braucht **keinen Supabase-Deploy, kein DB-Push und kein Apprelease**. Paket B benötigt später den implementierten gemeinsamen Edge-Transport, serverseitiges `GCP_SA_KEY`, explizite nicht geheime Projekt-/Regions-/Modellkonfiguration, getestete Nutzungs-/Cachemigration und nur die drei neuen KI-Function-Deployments. Diese Voraussetzungen existieren heute nicht; kein Deploymentbefehl für imaginäre fertige Funktionen ausführen.

## 7. Ausgeführte Prüfungen und Grenzen

Quell-/Konfigurationsprüfung per gezielten `rg`, `cat`, `sed`: oben genannte Modellslots, sieben Wrapper-Aufrufstellen, drei CLI-Instanzen, Reader-Lokalpfade und tatsächlich vorhandene Edge-Einstiege bestätigt; erfolgreiche Befehle Exit 0. Ein Suchbefehl hatte einen nicht existierenden Shellglob für `lib/data/repositories/*story*`; gezielte Wiederholung mit den belegten Dateien erfolgreich. Keine Flutter-/Pipeline-Suite gestartet; keine Modellanfrage, Installation, Cloudmutation, Veröffentlichung oder Push.

GitNexus zuerst abgefragt (`query`, `context`, `impact`), Repository `sprachlernapp`; Index anfangs einen Commit zurück. Erster CLI-Reindex Exit 1: `EPERM … ~/.gitnexus/registry-lock/analyze.lock.guard`. Zweiter gezielter Lauf `node .gitnexus/run.cjs analyze --index-only --pdg` mit erforderlichem lokalen Registry-Schreibrecht **Exit 0**: `Repository indexed successfully (15.6s)`, `31,780 nodes | 76,285 edges | 285 clusters | 408 flows`. Beibehaltung des vorhandenen PDG-Modus; keine Repository-Instruktionsdatei verändert.

MCP zeigte nach Reindex noch alten Verbindungsstand; maßgeblich anschließend frische CLI-Abfragen. `context generate_json --file pipeline/src/sprachpipe/llm.py --repo .`: bestehende Tests als Caller, `check_budget`, `append_entry`, `_call` als Callees; keine ausgewiesenen Prozesse, `lower-bound` wegen Receiverauflösung. `impact generate_json … --direction upstream` und `impact NEXTSTEPS.md …` jeweils Exit 0, **risk UNKNOWN**, keine aufgelösten vorgelagerten Prozesse. Keine Entwarnung daraus: sieben echte Caller textlich bestätigt; Statusdateireferenzen in AGENTS/CLAUDE bestätigt. Neuer Plan war noch kein Graphknoten. Es wird ausschließlich Dokumentation geändert; vor späterer Implementation Symbolimpact wiederholen. Der Gesamtindex meldet begrenzte Flowabdeckung; ungenannte Pfade gelten nicht als unbenutzt.

Abschließende tatsächlich ausgeführte Prüfungen (macOS Terminal; Git-/Node-/Pythonaufrufe sind unter Windows PowerShell inhaltlich identisch, lediglich ausführbaren Pythonnamen ggf. `py` wählen):

```text
Python: Dateireferenzen / Statuszeilen / Szenarien / Änderungsumfang
600/120: Gemini3.8=0.90000 Gemini2.5=0.48000 HaikuEU=0.13200 HaikuEUx1.3=0.17160
400/100: Gemini3.8=0.67500 Gemini2.5=0.37000 HaikuEU=0.09900 HaikuEUx1.3=0.12870
900/250: Gemini3.8=1.61250 Gemini2.5=0.89500 HaikuEU=0.23650 HaikuEUx1.3=0.30745
1500/600: Gemini3.8=3.37500 Gemini2.5=1.95000 HaikuEU=0.49500 HaikuEUx1.3=0.64350
PASS: Dateireferenzen, 24 Statuszeilen, Rechenwerte, nur erwartete Bestandsänderung; Index leer
Exit 0 (vor dem gezielten Staging)

git -c core.whitespace=cr-at-eol diff --cached --check -- docs/haiku-migration-plan.md NEXTSTEPS.md
Output leer, Exit 0

node .gitnexus/run.cjs detect-changes --scope all --repo .
Changes: 2 files, 6 symbols
Affected processes: 0
Risk level: low
Exit 0
```

MCP-Änderungsprüfung zusätzlich: `changed_files:2`, `changed_count:6`, `affected_count:0`, `risk_level:low`, kein `partial:true` oder `truncated:true`. Neue Dokumentabschnitte sind noch nicht indexiert; deshalb die explizite Referenz-/Diffprüfung zusätzlich. CRLF der bestehenden Statusdatei erhalten. Der frühere `diff --no-index --check /dev/null …` endete ohne Whitespacebefund mit Exit 1 wegen neuer Datei; dieser wird nicht als Exit-0-PASS ausgegeben. Erster Stagingversuch Exit 128 wegen `.git/index.lock`-Schreibrecht, gezieltes Staging mit erforderlichem Recht anschließend Exit 0. Ausschließlich zwei Dokumente gestagt; fremdes `published-baseline-transfer/` unversioniert erhalten. Lokaler isolierter Commit folgt nach erneutem finalem Diffcheck, kein Push.

Kein Qualitäts-PASS für Haiku, kein Cloudfreischaltungsbeleg und kein Geräte-PASS aus dieser Planung ableiten.

## Erhaltene relevante Altinformationen

- Portugiesisch Paket 2 lokal abgeschlossen: UI 2+13, Sprach-/Installationstests 14, Gesamtsuite 380 PASS/5 bestehende Skips, Realpack 1/12s, Stage Exit 0; Analyse Exit 1 nur bekannter `avoid_print`. Das sind **übernommene Vorbefunde**, hier nicht erneut ausgeführt. Details und historische Zwischenstände: `docs/portuguese-package-2.md`.
- Paket 1: pt-BR-editorial-v1, modellfreier Tokenizer, eigene Sprachkennung/Releasekette; echter Seed und leere 20-Ziel-Vorlage bereits vorhanden. Manuelle BR-Prüfung, Geräte-/Cloudabnahme und regulärer Release offen. Kein neuer Authoring-Auftrag durch diesen Plan: `docs/portuguese-package-1.md`, `docs/portuguese-language-rollout-plan.md` und Authoring-Vertrag.
- Aktive Inhaltskontexte: chitchat-Ursache lokal korrigiert; historische Reviews/SRS erhalten. Geräteanleitung, technischer Nachweis und unabhängige Lease-Meldung: `docs/content-update-active-context-fix.md`.
- Publizierte Basis/Editor-Verifikation: frühere Finalize-/Reupload-Anweisungen nicht blind wiederholen. Neueste Vertrags-/Streamingentscheidungen stehen in `docs/content-editor-initial-release.md`, `docs/content-published-base-adoption.md`; bestehende Entwürfe und Uploadanker erhalten. Cloud/Windows-/Geräteabnahmen bleiben gesondert.
- Story-Einzelsätze, exakte aktive Kontextbindung, 530 historische Readerlinks, 402 Formmitgliedschaften, Tombstones und bekannte 137 Provenienzlücken bleiben erhalten. Frühere Zahlen wie 3768 Karten/3767 aktiv und 3654 Übungen/3383 Wörter sind historische Statuswerte, keine neue Bestandsmessung. Referenzen: `docs/story-single-sentence-v1.md`, `docs/story-practice-context-completion.md`, `docs/context-quality-applied-v1.md`.
- UI-Nutzerwerte 40/30 px und Padding 16/6, Fehlerfeedback, Signierung und frühere isolierte Commits bleiben unberührt; damalige Commitblockaden nicht als aktuellen Arbeitsbaumzustand übernehmen. `docs/practice-error-feedback.md` bewahrt Details. Passwortlogin funktioniert laut vorherigem Nutzerbericht; keine neue Auth-/Rollenänderung, siehe `docs/content-password-login.md`.
