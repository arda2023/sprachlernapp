# Architecture

Zielarchitektur. Produktregeln: `PRODUCT.md`, Optik: `DESIGN.md`.

> **Stand 20.10.2026:** Das integrierte Redesign in `lib/screens/`, `lib/widgets/` und `lib/theme/` nutzt die bestehenden Provider/Repositories, echte Inhaltspakete und persistente Lernstände. Einzelne Beispielbereiche und simulierte Audiozustände bleiben Platzhalter. Die Schichten unten beschreiben die Zielordnung; dies ist kein Auftrag zum Verschieben vorhandener Screens. `lib/domain/` bleibt reines Dart. Aktuelle visuelle Regeln: `DESIGN.md` und `docs/redesign/design-system.md`; Übernahme: `docs/redesign/uebernahme.md`.

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
- Verbindung nur über **stabile IDs** (Hash des normalisierten Inhalts). Kuratierte Inhalte werden in `user.db` nur referenziert. Vollständige lokale Karten speichern eigene Metadaten und unveränderliche Kontexte mit Quellenreferenzen; sie bleiben ohne Content-Pack übbar.
- Inhaltsimport ist idempotent; entfernte Zeilen bleiben als Tombstone.

### lib/presentation
- Riverpod verwaltet Übungs-Queues je Modus (Gemischt, Lerne mit diesem Stapel, Stapel-Revue), Audiowiedergabe, Navigation.
- Screens lesen nur Provider, nie die Datenbank direkt.

### supabase/
- EU Frankfurt. Schema `content` (öffentlich lesbar), Schema `app` (RLS, nur eigene Zeilen), Buckets `audio`, `packs`, `imports`.
- Übersetzungs-Edge-Functions rufen die direkte Anthropic-API mit `claude-haiku-5-5` auf (`docs/backend.md`). Die App enthält keinen KI-Schlüssel.

### pipeline/
- Python-Textanschluss mit vorhandenem `anthropic[vertex]==1.15.0` hinter synchronem `Llm.generate_json`: explizit `llm.provider: anthropic` (AsyncAnthropic, ANTHROPIC_API_KEY nur im lokalen Prozess) oder `vertex` (AsyncAnthropicVertex, EU/ADC). Kein Fallback. Direkte API ausschließlich für lokale Redaktion, ohne EU-only-Zusage und ohne echte Nutzerdaten; Nutzerentscheidung vom 19.10.2026. TTS behält seine Regeln; die separate Laufzeitübersetzung ist unten beschrieben. `google-genai` bleibt für vorhandene Werkzeuge installiert. [Einrichtung und Grenzen](docs/haiku-direct-api-setup.md).
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
Aktueller Clientvertrag: Wort-Tap → geprüfte Wortstelle/privater Cache/einfache Wörterbuchbedeutung → bei fachlichem Miss und dauerhafter widerrufbarer Einwilligung `RuntimeTranslationClient`; ganze Sätze nach ausdrücklichem „Übersetzen“. Keine Geräteübersetzung/Modelldownloads und kein automatischer Upload bei Speicherfehlern. `word_cloud_consent` speichert Vertragsversion und Entscheidung pro Owner in der getrennten privaten Übersetzungsdatenbank, nicht in user.db. [Änderungsvertrag](docs/offline-translation-revision.md). Vorhandener Backendpfad: `RuntimeTranslationClient` mit bestehendem Supabase-Login → `lookup-word`/`translate-sentence` → Auth-Prüfung und atomare Reservierung in `app.usage` → direkte Anthropic-API (`claude-haiku-5-5`). en/pt-BR → de, nur ein Satz und optional die Wortform. Vorhandene Packübersetzungen bleiben zuerst und offline. Paket 2A ergänzt `TranslationRequest`, `TranslationCache` (separates `private_translations.sqlite`) und `CachedRuntimeTranslationClient`: kontogebundene Offline-Treffer, In-flight-Deduplizierung, vorgemerkte Cloudlöschung. Server: `claim_translation` → Treffer oder atomare Generierungsreservierung → validierte Antwort → `finish_translation`; `clear_translation_cache` löscht nur private Übersetzungen. Vollständiger Vertrag: `docs/story-translation-cache.md`. Kein Fallback, keine EU-only-Zusage; serverseitiges Secret. `sentence-check` bleibt Entwurf. Nachweise und Abnahme: [Haiku-Laufzeitübersetzungen](docs/haiku-runtime-translations.md).

## Regeln
1. Keine Schlüssel in Repo oder App.
2. Der Client ruft nie einen KI-Anbieter direkt auf.
3. Abgeleitete Zähler nie als Spalte speichern.
4. `review_log` ist append-only.
5. IDs werden nie wiederverwendet.

## Weitere Doku
`docs/srs.md` (Wiederholung), `docs/content-schema.md` (Inhaltsschema), `docs/backend.md`, `docs/pipeline.md`, `docs/setup.md`.

## Inhaltsvertrag Paket A (04.10.2026)
Der vorhandene Offline-Pipeline-/Exportweg liefert Schema 2, die App liest Schema 1 und 2 read-only. `deck_words` trennt Wortbesitz/Primärplatz von der sinnbezogenen Lernkarte. Repositories liefern Primärkarten für direkte Stapel und alle erhaltenen Karten für gelernte Altstände in Gemischt. Ein fester Übungssatz plus gesonderte historische Satzabfrage ersetzt Rotation. Vor Austausch eines installierten Packs werden Version und Schema des Kandidaten geprüft.
Paket A ließ `user.db` auf Schema 3. Paket B migriert additiv auf Schema 4: lokale Kartenmetadaten, unveränderliche `card_contexts`, getrennte explizite Story-Lernentscheidungen und exakte Identitätsbindungen. `PracticeItemResolver` verbindet beide Repositories für Wortliste, Zähler und den bestehenden Übungscontroller. Domain-Typen enthalten keine Flutter-Imports. Kein Cloud-Aufruf und keine Servermigration.

## Ergänzung Lerngruppen v1 (06.10.2026)
Content-Schema 3 ergänzt `cards.learning`; Schema 1/2 bleibt lesbar. `LearningGroups` in der reinen Domain projiziert Einführung und Fortschritt über alle Quellen. `PracticeItemResolver` ordnet lokale Karten nur anhand exakter Identitäten zu; beide Drift-Repositories transportieren die Metadaten beziehungsweise verwenden sie beim atomaren Story-Add. Bestehende gelernte Gruppenmitglieder bleiben eigenständige Reviewziele. Gemeinsame Auswahl verteilt neue Themen, die Session behält ihre einmalige Reihenfolge. Satzbezogene geprüfte Synonyme sind neutrale erneute Versuche; keine user.db-Migration. Verbindliche Regeln und Tests: `docs/learning-groups-v1.md` (im docs-Ordner: `learning-groups-v1.md`).

## Verben-Paket B (10.10.2026)
Content-Schema 4 und user.db v5 bleiben getrennt. `PracticeItemResolver` verbindet typed Deckziele, exakte lokale Formbindungen und bestehende Zustände; Controller, Provider, Wortliste und Story nutzen diesen Pfad. Domain bleibt Flutter-frei. Übungs- und Wortzahlen werden aus demselben berechtigten Inventar abgeleitet; es gibt keine Counterspalten und keinen zweiten Review-Schreibweg. Nullable lokale Form-/Lexikalmetadaten erhalten die Übbarkeit bei Content-Rückfall. Installationsvalidierung bleibt vor Dateiaustausch. Siehe `docs/irregular-verbs-package-b.md`.

## Textanschluss Paket A (historischer Stand 18.10.2026)
Der bestehende Offline-Wrapper nutzt `claude-haiku-5-5`, Projekt `sprachlernapp-510508`, EU-Multiregion `eu`, Thinking aus und Effort low. Kein Fallback. SDK-Retries aus; maximal drei kontrollierte Versuche, feste Request-/Gesamtdeadline, vollständige ursprüngliche JSON-Schema-Prüfung lokal. Keine neue Runtime-KI oder Appänderung. Cloudfreischaltung und Modellqualität bleiben ungeprüft; Offline-Nachweise: [Umsetzung](docs/haiku-migration-implementation.md). Die Stapelphase ist beendet; keine neuen Produktionsläufe aus dieser Änderung.

Paket 2C: ausdrückliches Add → PersonalLearningService → bestehende Karte oder separater privater Erstellungs-Claim (`create-learning-card`) → streng validierter PersonalLearningCandidate → bestehende atomare user.db-Karten-/Kontexttransaktion und „Aus Storys“. Eigene Konto-/Gerätefreigabe in private_learning_consent.sqlite; Übersetzungscache und Kartenspeicher getrennt. Keine Scheduleränderung. Cloud und Geräteabnahme noch offen: docs/story-import-learning-package-2c.md.
