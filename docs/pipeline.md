# Content-Pipeline (`pipeline/`)

Offline-Werkzeug in Python, läuft nie in der App (siehe `PRODUCT.md`, Abschnitt Runtime AI Boundary).

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
Der Parameter-Name für Gemini 3.8 Flash ist vor der Nutzung gegen die offizielle Dokumentation zu prüfen, nicht zu raten.

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

- **Linter** (automatisch, jeder Satz): Länge im Rahmen des Stapel-Niveaus; höchstens 1 Nebensatz; Lücken-Offsets stimmen (`gap_start`/`gap_end` treffen genau die Form); i+1 (alle anderen Wörter liegen im bekannten Wortschatz des Niveaus, höchstens das Zielwort ist neu).
- **Blindtest**: Ein zweites Modell bekommt den Satz mit Lücke ohne Lösung und muss die Form liefern. Weicht die Antwort von `accepted[]` ab, geht der Satz zurück.
- **Stichprobe**: 5 % der Sätze je Lauf werden von Hand geprüft.

## Kosten

- Jeder Lauf protokolliert Modell, Token (Eingabe, Ausgabe, Denken) und Kosten je Schritt in einer Lauf-Datei.
- **Kostenobergrenze pro Lauf ist ein Pflicht-Parameter** (`--max-cost-usd`). Der Lauf bricht ab, bevor die Grenze überschritten wird.
- **Batch-Modus** nur nach Prüfung gegen die offizielle Doku und Eintrag hier. Bis dahin: normale Anfragen.
- Testguthaben endet ca. 22.11.2026: EN-Hauptlauf und Audio vorher.

## TTS

- Cloud Text-to-Speech API, Modell Gemini 2.5 Flash TTS, Login per ADC.
- TTS-Pilot: zusätzlich `gemini-3.8-flash-lite-tts` vergleichen (Preis und Qualität noch ungeprüft).

## Hinweise zu Frequenzlisten

- Einträge in BNC/COCA sind Wortfamilien, je 1.000er-Liste alphabetisch sortiert, nicht nach Rang. Kopfwort-Zuordnung erhalten.
- Die Werte `"null"`, `"true"`, `"false"` kommen als Wörter vor. Beim Einlesen (CSV, YAML, JSON, Excel) explizit als Text behandeln.
