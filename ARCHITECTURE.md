# Architecture

Zielarchitektur. Produktregeln: `PRODUCT.md`, Optik: `DESIGN.md`.

> **Stand:** `lib/models/` und `lib/screens/` sind der aktuelle Stand (In-Memory-Stores, Platzhalterinhalte). Sie werden später auf die Schichten unten migriert. `lib/domain/` ist bereits reines Dart.

## Schichten

```
lib/
├── domain/         Pure Dart, keine Flutter-Imports (kein dart:ui, kein package:flutter)
├── data/           Drift user.db + schreibgeschützte content.sqlite, Repositories
└── presentation/   Riverpod-Provider, Screens, Widgets, Theme
supabase/           migrations/, functions/ (Edge Functions), config.toml
pipeline/           Python, offline, nie in der App
docs/               Detaildokus (siehe unten)
```

### lib/domain
- Karten, Wortformen, Antwortprüfung (exakt / "fast richtig" / falsche Form / falsch), Satzgrenzen, `*Betonung*`-Markup.
- `SpacedRepetitionEngine` (Interface): Leitner mit fünf Boxen in v1, später FSRS vergleichbar. Regeln: `docs/srs.md`.
- Alle Entitäten tragen explizite Sprachkennzeichen (`lang`, `glossLang`).
- Die vier Zähler werden hier aus Kartenzustand und Fälligkeit berechnet, nie gespeichert.

### lib/data
- **`user.db`** (Drift): Karten des Lernenden (`card_id`, Box, `due_at`, Herkunft, deaktiviert, Favorit, Notiz), Einstellungen, Importe, **`review_log`** (nur anhängen).
- **`content.sqlite`** (schreibgeschützt, eine Datei je Sprache): Wörterbuch, Karten, Sätze, Token-Annotation, Stapel, Stories, Übungen, Audio-Verweise. Schema: `docs/content-schema.md`.
- Verbindung nur über **stabile IDs** (Hash des normalisierten Inhalts). `user.db` enthält nie Inhaltstexte, nur IDs und Zustand.
- Inhaltsimport ist idempotent; entfernte Zeilen bleiben als Tombstone.

### lib/presentation
- Riverpod verwaltet Übungs-Queues je Modus (Gemischt, Lerne mit diesem Stapel, Stapel-Revue), Audiowiedergabe, Navigation.
- Screens lesen nur Provider, nie die Datenbank direkt.

### supabase/
- EU Frankfurt. Schema `content` (öffentlich lesbar), Schema `app` (RLS, nur eigene Zeilen), Buckets `audio`, `packs`, `imports`.
- Edge Functions rufen Vertex AI auf (`docs/backend.md`). Die App enthält keinen KI-Schlüssel.

### pipeline/
- Python mit `google-genai` (Vertex AI), Login per ADC. Erzeugt Karten, Sätze, Annotation, Wörterbuch, Audio (`docs/pipeline.md`).
- Läuft nur auf dem Entwicklungsrechner, nie in der App und nie in einer Edge Function.

## Datenfluss

```
wordfreq → pipeline/ (Karten, Sätze, Annotation, Wörterbuch, QA)
        → Supabase Schema content
        → Export content.sqlite je Sprache
        → Storage (Bucket packs)  → App-Download
Audio:  pipeline/ → Cloud Text-to-Speech → Bucket audio → App streamt/cached
```

Der Client lädt `content.sqlite` einer Sprache (versioniert über `content_releases`) und spielt Updates ohne Änderung an `user.db` ein. Audio-Basis-URL kommt aus der Konfiguration, nicht aus dem Code.

## Laufzeit-KI
Nur für nutzergenerierte Inhalte, nur über Edge Functions: `lookup-word`, `translate-sentence`, `sentence-check`. Tageslimits in Tabelle `usage`. Kuratierte Inhalte sind vor dem Release fertig.

## Regeln
1. Keine Schlüssel in Repo oder App.
2. Der Client ruft nie einen KI-Anbieter direkt auf.
3. Abgeleitete Zähler nie als Spalte speichern.
4. `review_log` ist append-only.
5. IDs werden nie wiederverwendet.

## Weitere Doku
`docs/srs.md` (Wiederholung), `docs/content-schema.md` (Inhaltsschema), `docs/backend.md`, `docs/pipeline.md`, `docs/setup.md`.
