# Content-Pipeline (`pipeline/`)

Offline-Werkzeug in Python, läuft nie in der App (siehe `PRODUCT.md`, Abschnitt Runtime AI Boundary).

## 3a Stand

Gerüst ohne KI-Aufrufe: stabile IDs, Lemma-Auswahl, Satz-Linter, DB-Schreiber, Export nach `content.sqlite`, Kosten-Protokoll.

Ordner: `pipeline/src/sprachpipe/` (Code), `pipeline/tests/` (pytest, Fixture `tests/fixtures/mini_pack.json`), `pipeline/config.yaml`, `pipeline/out/` und `pipeline/.venv/` (beide nicht im Repo). Verbindung nur über `SUPABASE_DB_URL` in `pipeline/.env` (Vorlage: `pipeline/.env.example`).

Windows (PowerShell), im Ordner `pipeline`:
```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -e ".[test]"
.\.venv\Scripts\python.exe -m pytest
.\.venv\Scripts\python.exe -m sprachpipe.cli lemmas
.\.venv\Scripts\python.exe -m sprachpipe.cli lint tests\fixtures\mini_pack.json
.\.venv\Scripts\python.exe -m sprachpipe.cli upsert tests\fixtures\mini_pack.json            # Dry-Run
.\.venv\Scripts\python.exe -m sprachpipe.cli upsert tests\fixtures\mini_pack.json --publish  # schreibt
.\.venv\Scripts\python.exe -m sprachpipe.cli export tests\fixtures\mini_pack.json out\content.sqlite
.\.venv\Scripts\python.exe -m sprachpipe.cli check-db                                         # nur lesen
```

macOS (Terminal), im Ordner `pipeline`:
```bash
python3.11 -m venv .venv
.venv/bin/python -m pip install -e ".[test]"
.venv/bin/python -m pytest
.venv/bin/python -m sprachpipe.cli lemmas
.venv/bin/python -m sprachpipe.cli upsert tests/fixtures/mini_pack.json --publish
.venv/bin/python -m sprachpipe.cli export tests/fixtures/mini_pack.json out/content.sqlite
```

`upsert` ist ohne `--publish` ein Dry-Run. Lokale DB nach `supabase start`: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`.

**Funktionswörter** (entschieden in 3b): werden Karten wie alle anderen Wörter. Der `lemmas`-Befehl aus 3a filtert weiter nur NOUN, VERB, ADJ, ADV; `generate` nutzt ihn nicht.

**Bekannte Grenze:** spaCy bestimmt Lemma und Wortart am einzelnen Wort ohne Kontext. Dadurch stehen z. B. `about`, `up`, `out` als ADV in der Liste und `best`/`better` bei `well`.

## 3b Stand

KI-Generierung über Vertex AI, Blindtest, Kostenkontrolle, Review-Liste. Kein Schreiben in eine Datenbank.

Windows (PowerShell), im Ordner `pipeline`:
```powershell
gcloud auth application-default login                       # einmalig, ADC
.\.venv\Scripts\python.exe -m pip install -e ".[test]"
.\.venv\Scripts\python.exe -m pytest
.\.venv\Scripts\python.exe -m sprachpipe.cli generate --forms smoke --out out\smoke_pack.json --max-usd 1.0
```

macOS (Terminal), im Ordner `pipeline`:
```bash
gcloud auth application-default login
.venv/bin/python -m pip install -e ".[test]"
.venv/bin/python -m pytest
.venv/bin/python -m sprachpipe.cli generate --forms smoke --out out/smoke_pack.json --max-usd 1.0
```

`--forms`: `smoke` (`smoke_forms` in `config.yaml`), eine Zahl n (die n häufigsten wordfreq-Formen) oder `a,b,c`. `--max-usd` (Standard 1.0) ist die Kostengrenze des Laufs; für `smoke` ist sie im Code auf höchstens 1.0 begrenzt. Ausgaben in `pipeline/out/`: Pack, `ledger.csv` (je Aufruf: Schritt, Modell, Token Eingabe/Ausgabe/Denken, USD; ein vorhandenes Ledger wird zu `ledger-<zeit>.csv` umbenannt), `review.csv` (UTF-8 mit BOM, Trenner `;`, eine Zeile je erzeugtem Satz), `run_report.md`.

Module: `llm.py` (Wrapper: Kostenschätzung → `check_budget` → Aufruf → Ledger mit echten Token aus `usage_metadata`; transiente Fehler höchstens 2× wiederholt; 401/403 nie), `generate.py` (Schritt A Bedeutungen, Schritt B Sätze, Gap-Offsets, QA-Schleife), `annotate.py`, `blindtest.py`, `review.py`; Befehl in `cli.py`, Pack in `pack.py`.

**Prompts** (`pipeline/prompts/`, erste Zeile = Version): `meanings-v1`, `sentences-v1`, `annotate-v1`, `blindtest-v1`.

**Preise** (abgerufen 2026-10-03, https://cloud.google.com/vertex-ai/generative-ai/pricing, leitet weiter auf https://cloud.google.com/gemini-enterprise-agent-platform/generative-ai/pricing; Global, Standard, ≤ 200K Eingabe-Token; Denk-Token = Ausgabepreis):

| Modell | Eingabe / 1 Mio. | Ausgabe inkl. Denken / 1 Mio. |
|---|---|---|
| `gemini-3.8-flash` | 0,75 USD | 3,75 USD (Einführungspreis bis 31.12.2026; ab 1.1.2027: 1,50 / 7,50) |
| `gemini-2.5-flash` | 0,30 USD | 2,50 USD |

**Denk-Parameter** (geprüft 2026-10-03 gegen https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/thinking und …/models/guides/gemini-3-8-flash): Gemini 3 nutzt `thinking_level` (3.8 Flash: `LOW`, `MEDIUM` Standard, `HIGH`; `MINIMAL` ergibt einen Fehler) → gesetzt `LOW`. Gemini 2.5 nutzt `thinking_budget` → Blindtest `0` (aus).

**Blindtest-Modell**: `gemini-2.5-flash` (billiger als die Generierung, Verfügbarkeit im Projekt am 2026-10-03 per Mini-Aufruf geprüft).

**Qualitätsregeln**
- Karten-Kandidaten: wordfreq-Formen mit Rang; Wortart und Bedeutung bestimmt das Modell (höchstens 3 Bedeutungen je Form). Funktionswörter werden Karten wie alle anderen Wörter. Leere Liste (Fragment, Eigenname, Zahl) → Form übersprungen, im Report.
- Gap-Offsets berechnet der Code (ganzes Token, erst case-sensitiv, dann case-insensitiv), nie das Modell.
- Linter-Fehler → Satz höchstens 2× neu (Befund im Prompt), danach `qa_status = failed`.
- Blindtest (Satz mit Lücke, `translation_de`, `gloss_de`, ohne Form): Antwort = Form oder in `accepted[]` → `passed`. Kein Wort oder andere Form desselben Lemmas → nicht bestanden, Satz 1× neu, danach `failed`. Anderes echtes Wort → `review` mit der Antwort in `qa_report`; nie automatisch in `accepted[]`.
- `failed`-Sätze kommen nicht in den Pack; eine Karte kommt nur mit 3 Sätzen ohne `failed` in den Pack.
- Annotation: spaCy-Tokens mit Offsets, ein Modellaufruf je Satz für Lemma + Glosse jedes Wort-Tokens (auch Funktionswörter), geprüft gegen Index und Surface. Daraus `sentence_tokens` und `dictionary_forms` (`rank` = Reihenfolge der Bedeutungen einer Form nach Häufigkeit im Pack).

**Smoke-Test** (2026-10-03, `went, left, about, up, light`): 14 Karten, 42 Sätze (33 passed, 9 review, 0 failed), 104 Aufrufe, 0,0951 USD gesamt, **0,0068 USD je Karte** (davon Annotation 0,072 USD). Blindtest-review-Quote 21 %, Linter-Fehler 1/43 (`subclauses`).

## 3c Stand

Generierung über Vertex AI und ADC wie in 3b. Die folgenden Regeln ersetzen die 3b-Qualitätsregeln; ältere 3b-Zahlen bleiben als historischer Vergleich stehen. Kein Datenbankzugriff beim Generieren.

- Schritt A (`meanings-v2`) gibt bis zu drei Bedeutungen je Form zurück. `gloss_de` grenzt ähnliche Bedeutungen kurz ab. Der Bedeutungs-Check (`meaning-check-v1`, Blindtest-Modell) erhält Satz, Form sowie **alle** `sense_key` und `gloss_de` dieser Form und muss den Karten-`sense_key` wählen. Abweichung verwirft den Satz.
- Schritt B (`sentences-v2`) erzeugt je Karte fünf einzelne Kandidaten. Die ersten drei mit Linter, Blindtest, Bedeutungs-Check und Vielfaltprüfung werden angenommen. Sind es weniger als drei, folgt genau eine Runde mit drei weiteren Kandidaten. Nur Karten mit drei angenommenen Sätzen kommen in den Pack.
- Blindtest (`blindtest-v1`): Nur die exakte Zielform besteht. Bei jeder abweichenden Antwort wird der Satz einmal neu erzeugt; Antwort und Anweisung, den Kontext auf **nur** die Zielform festzulegen, stehen im Prompt. Bei erneuter Abweichung `failed`. `accepted[]` bleibt auf die Zielform beschränkt. Pack-Sätze haben ausschließlich `qa_status = ok`; `review` und `failed` bleiben außerhalb des Packs.
- Vielfalt: Innerhalb einer Karte werden identische Fenster von je zwei Tokens vor und nach der Zielform sowie identische erste vier Tokens verworfen. Jeder Kandidaten-Slot erhält eine deterministisch gewählte, innerhalb der Karte unterschiedliche Alltagssituation und einen erlaubten Vornamen aus `config.yaml` (ohne Tom/Anna). Die 15 bisher im Pack häufigsten Inhaltswort-Lemmata stehen als Vermeidungsliste im Prompt. Übernutzung eines Inhaltsworts in mehr als `max(4, 5 %)` aller Pack-Sätze erscheint nur als Warnung im Bericht.
- i+1 ist bei `generate` standardmäßig aktiv: Top 5000 `wordfreq`-Formen werden wie in `lemmas.py` lemmatisiert; die Warnschwellen nach `cefr_band` sind 1500/3000/5000. Verstöße blockieren den Satz nicht und werden je Karte im Bericht gezählt.
- `review.csv` ist UTF-8 mit BOM und Semikolon für deutsches Excel; sie enthält jeden Versuch sowie `bedeutung_check` und `verworfen_grund`. `run_report.md` zeigt die Verwerfungen nach Linter-Regel, Blindtest, Bedeutung und Duplikat.
- Das Ledger verwendet `prompt_token_count`, `candidates_token_count` und `thoughts_token_count` aus `usage_metadata`. `thinking_tokens` werden mit dem Denk-Preis berechnet. Ein Vertex-Miniaufruf mit `HIGH` am 03.10.2026 lieferte 5 Eingabe-, 1 Ausgabe- und 105 Denk-Token. Preise und Modellparameter bleiben wie in `config.yaml` dokumentiert.
- Einmaliger Smoke-Test 3c (03.10.2026, fünf Formen, Budget 1,00 USD): 14 Karten erzeugt, 13 im Pack mit 39 `ok`-Sätzen; 267 Ledger-Aufrufe, 380 Denk-Token, 0,150474 USD. Eine Karte (`left#links`) erreichte keine drei Sätze. Alle Pack-Gaps und `qa_status` wurden geprüft. Die Artefakte wurden geschrieben; der Prozess beendete sich erst beim anschließenden Konsolen-`print` wegen `UnicodeEncodeError` (Windows cp1252, Zeichen `→`) mit Exit 1. Die Ausgabe wurde auf ASCII umgestellt; der Smoke-Test wurde nicht wiederholt.

## 3d Stand

- Schritt A verwendet das versionierte Inventar `pipeline/data/meanings/en.json`. Ein vorhandener Formeintrag wird ohne Modellaufruf übernommen. `--refresh-meanings <form>` fordert Bedeutungen neu an und hängt nur neue `sense_key` an; bestehende Schlüssel und ihre Inhalte bleiben erhalten. Für wordfreq-Rang ≤ 1000 gelten höchstens vier Bedeutungen, sonst drei. `meanings-v3` trennt Wortarten mit verschiedenen deutschen Übersetzungen, z. B. `left#links` (Adjektiv) und `left#nach_links` (Adverb). Die fünf Smoke-Formen sind aus dem bisherigen Pack vorbefüllt; beide `left`-Schlüssel sind ergänzt.
- Schritt B (`sentences-v3`) erzeugt fünf Kandidaten in **einem** Aufruf mit je einer vorgegebenen Alltagssituation und einem erlaubten Namen. Er bittet um verschiedene Satzanfänge und Satzmuster. Bis zu zwei zusätzliche Runden mit je drei Kandidaten sind möglich. Nach drei angenommenen Sätzen werden übrige Kandidaten nicht mehr kostenpflichtig geprüft. Blindtest-Neuversuche bleiben Einzelaufrufe. Innerhalb einer Karte ist höchstens ein Satz mit demselben ersten Wort erlaubt.
- i+1 ist eine reine Warnung: Für jedes Inhaltswort außer Zielform, Namenspool und Zahlen gilt der höhere Wert aus `wordfreq.zipf_frequency(lemma, "en")` und `wordfreq.zipf_frequency(Form, "en")`. Mindestwerte nach `cefr_band`: Anfänger 4,0; Mittel 3,5; Fortgeschritten 3,0.
- `review.csv` verwendet UTF-8 mit BOM und Komma. Der Bericht nennt für jede nicht gepackte Karte alle protokollierten Verwerfungsgründe und Blindtest-Antworten. Die Konsolenausgabe bleibt ASCII.
- `--forms 60` wählt die ersten 60 zulässigen wordfreq-Formen nach Ausschluss von Fragmenten, Zahlen und Eigennamen. Funktionswörter bleiben enthalten. `--forms smoke` bleibt die Liste aus `config.yaml`.
- Einmaliger Smoke-Test 3d: alle fünf Formen und `left#links` im Pack, 15 Karten mit je drei `ok`-Sätzen, alle Gap-Spannen korrekt; 169 Aufrufe, 0,121110 USD, 0 Denk-Token.
- Einmaliger Pilot 3d mit 60 Formen: 177 Karten erzeugt, 169 im Pack (95,48 %), 507 `ok`-Sätze; 2.443 Aufrufe, 1,674511 USD, 6.431 Denk-Token. Alle Pack-Gaps und Satzanzahlen sind geprüft. Acht Karten blieben unvollständig; der Bericht nennt je Karte alle Verwerfungsgründe und Blindtest-Antworten. Häufige Verwerfungen betreffen `what` (61), `there` (38), `like` (34), `this` (29), `i` und `your` (je 22). Die Wortform `i` aus wordfreq ist kleingeschrieben und scheitert im Blindtest an `I`; die Inventar- und Formnormalisierung dafür ist noch offen.

Windows (PowerShell), im Ordner `pipeline`:
```powershell
.\.venv\Scripts\python.exe -m pytest
.\.venv\Scripts\python.exe -m sprachpipe.cli generate --forms smoke --out out\smoke_pack_v3.json --max-usd 1.0
.\.venv\Scripts\python.exe -m sprachpipe.cli generate --forms 60 --out out\pilot_pack.json --max-usd 5.0
```

macOS (Terminal), im Ordner `pipeline`:
```bash
.venv/bin/python -m pytest
.venv/bin/python -m sprachpipe.cli generate --forms smoke --out out/smoke_pack_v3.json --max-usd 1.0
.venv/bin/python -m sprachpipe.cli generate --forms 60 --out out/pilot_pack.json --max-usd 5.0
```

Der Pilot folgt nur auf einen Smoke-Test, bei dem alle fünf Formen mindestens eine Karte im Pack haben und `left#links` im Pack ist. Die Ergebnisse des aktuellen Laufs stehen in `NEXTSTEPS.md`.

## KI-Zugang: Vertex AI

- Projekt `sprachlernapp-510508`, Region `global`.
- Modell `gemini-3.8-flash` (getestet am 2026-10-03, Antwort erfolgreich).
- Kein API-Key-Zugang. Es gibt keinen Key, der in `.env` oder Repo liegt.
- Python mit `google-genai`:

```python
from google import genai
client = genai.Client(vertexai=True, project="sprachlernapp-510508", location="global")
```

- Login über Application Default Credentials: `gcloud auth application-default login`.

## Denk-Token

Denk-Token zählen als Ausgabe. Jede Anfrage bekommt ein Denk-Budget.
Gemini 3.8 Flash: `thinking_level` (geprüft 2026-10-03, siehe „3b Stand“).

## Schritte

1. **wordfreq**: Wortformen mit Rang je Sprache. BNC/COCA nur als Gegenprobe für Englisch.
2. **Karten**: Form + Bedeutung, Lemma-Verknüpfung, Stapelzuordnung.
3. **Sätze**: je Karte 3 Sätze, die genau diese Form enthalten.
4. **Annotation**: Token → Bedeutung im Satz (`sentence_tokens`).
5. **Wörterbuch**: Form → Bedeutungen mit deutscher Glosse (`dictionary_forms`), Satzübersetzungen.
6. **QA** (siehe unten). Nur bestandene Zeilen gehen weiter.
7. **Supabase**: Schreiben ins Schema `content` (idempotent, stabile IDs, Tombstones).
8. **Export**: `content.sqlite` je Sprache, Upload in Bucket `packs`, Eintrag in `content_releases`.
9. **Audio**: Cloud Text-to-Speech, Upload in Bucket `audio`, Eintrag in `audio_assets`.

Jeder Schritt ist wiederholbar und schreibt nur über stabile IDs (`docs/content-schema.md`).

## QA-Regeln

- **Linter** (automatisch, jeder Satz): höchstens 14 Wörter und 1 Nebensatz; Lücken-Offsets treffen genau die Form. i+1 wird nach den Zipf-Mindestwerten aus 3d nur als Warnung ausgegeben.
- **Blindtest**: Ein zweites Modell bekommt den Satz mit Lücke ohne Lösung und muss die exakte Form liefern. Bei Abweichung wird der Satz einmal neu erzeugt; danach gilt er als `failed`.
- **Stichprobe**: 5 % der Sätze je Lauf werden von Hand geprüft.

## Kosten

- Jeder Lauf protokolliert Modell, Token (Eingabe, Ausgabe, Denken) und Kosten je Schritt in einer Lauf-Datei.
- **Kostenobergrenze pro Lauf ist ein Pflicht-Parameter** (`--max-usd`). Der Lauf bricht ab, bevor die Grenze überschritten wird.
- **Batch-Modus** nur nach Prüfung gegen die offizielle Doku und Eintrag hier. Bis dahin: normale Anfragen.
- Testguthaben endet ca. 22.11.2026: EN-Hauptlauf und Audio vorher.

## TTS

- Cloud Text-to-Speech API, Modell Gemini 2.5 Flash TTS, Login per ADC.
- TTS-Pilot: zusätzlich `gemini-3.8-flash-lite-tts` vergleichen (Preis und Qualität noch ungeprüft).

## Hinweise zu Frequenzlisten

- Einträge in BNC/COCA sind Wortfamilien, je 1.000er-Liste alphabetisch sortiert, nicht nach Rang. Kopfwort-Zuordnung erhalten.
- Die Werte `"null"`, `"true"`, `"false"` kommen als Wörter vor. Beim Einlesen (CSV, YAML, JSON, Excel) explizit als Text behandeln.
