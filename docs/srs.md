# Wiederholungssystem (SRS)

Quelle der Regeln: `PRODUCT.md`. Code: `lib/domain/` (Interface `SpacedRepetitionEngine`). Tabellen: `docs/user-schema.md`.

## Karte und Zustand

Eine Karte ist eine exakte Wortform in einer Bedeutung. Zustand je Karte in `user_cards`: `box` (0 = noch nie beantwortet, 1–5), `due_at`, `origin` (deck / story), `disabled`, `retired`, `created_at`.

Der Kartenzustand (`box`, `due_at`) ist ein **Cache**: Er lässt sich aus der Kartenerstellung und dem `review_log` rekonstruieren (letzte Zeile je Karte: `box_after`, `due_at_after`). Das ist die Grundlage für Sync.

## Intervalle

| Box | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Tage | 1 | 4 | 14 | 40 | 90 |

Standardwerte, einstellbar. Box 5 heißt "gemeistert".

**Fälligkeit nach Kalendertag:** `due_at` = Beginn des lokalen Tages (Antwortdatum + Intervall in Tagen), nicht Uhrzeit + Intervall. Beispiel: Antwort am 3.10. um 22:40 in Box 2 → fällig ab 7.10., 00:00 Ortszeit.

Jede Box-Änderung setzt `due_at` nach der neuen Box neu.

## Erstkontakt

Eine Karte entsteht bei der ersten Anzeige in einem Stapel oder per "Zum Lernen hinzufügen" (Box 0). Der erste Versuch entscheidet:

- richtig (ohne falschen Versuch, ohne "Wort erfahren") → Box 3
- sonst → Box 1

## Danach

- **Antwort sauber** (erster Versuch exakt) → Box + 1 (höchstens 5), `due_at` nach neuer Box.
- **Fehler** (falscher Versuch, falsche Form, "Wort erfahren") → Box 1, `due_at` nach Box 1.
- "Fast richtig" ist kein Fehler.
- **Vorab-Üben** und **Stapel-Revue** (Karte nicht fällig): richtig → Box und `due_at` unverändert; Fehler → Box 1, `due_at` nach Box 1.

## In-Session-Wiederholung

Eine Karte mit Fehler kommt einmal wieder, etwa 3 Karten später. Die Box entscheidet allein der erste Versuch; die Wiederholung ändert Box und `due_at` nicht und erzeugt keine eigene Zeile im `review_log`.

## Queue je Modus

Deaktivierte und retired Karten sind nie in einer Queue.

**Gemischt**
1. Fällige Karten aller Herkunft (`due_at ≤ jetzt`, älteste zuerst).
2. Neue Wörter bis zum Tagesziel: zuerst Story-Karten in Box 0 (älteste zuerst), danach neue Stapelwörter aktiver Stapel.
3. Weitere neue Wörter.
4. Vorab-Üben der als Nächstes fälligen Karten (`mode = early`).

Der Stapelschalter steuert nur neue Stapelwörter (Schritt 2 und 3); gesehene Karten werden immer wiederholt.

**Lerne mit diesem Stapel**: nur Formen und Sätze dieses Stapels, nie reine Story-Karten, auch bei inaktivem Stapel. Reihenfolge: fällige Karten des Stapels, dann neue Wörter des Stapels.

**Stapel-Revue**: nur gesehene Karten des Stapels (Box ≥ 1), als Vorab-Üben (richtig → unverändert, Fehler → Box 1).

## Abgeleitete Zähler

Nie gespeichert. Mit `A` = aktive Stapel, `C` = Karten mit `disabled = false` und `retired = false`, `now` = Abfragezeit. Formen werden **distinct über `card_id`** gezählt (eine Form in zwei aktiven Stapeln zählt einmal).

| Zähler | Definition |
|---|---|
| Noch nicht angezeigt | distinct `card_id` aus `deck_cards` von `A` ohne Zeile in `user_cards` **plus** Karten in `C` mit `box = 0` |
| Verfügbare Wiederholungen | Karten in `C` mit `box ≥ 1` und `due_at ≤ now` |
| Wörter gemeistert | Karten in `C` mit `box = 5` und `due_at > now` |
| Wörter im Aufbau | Karten in `C` mit `box` 1–4 und `due_at > now` |

Zuordnung in dieser Reihenfolge, damit die Zähler disjunkt sind. **Invariante:** Summe der vier = |`C`| + distinct `card_id` aus `A` ohne Karte. Retired Karten zählen wie deaktivierte nirgends mit.

**Tagesziel** = Anzahl verschiedener `card_id` mit einer `review_log`-Zeile am heutigen lokalen Kalendertag. Der Streak entsteht ebenfalls aus `review_log`.

## review_log (nur anhängen)

Eine Zeile je Karte und Session, geschrieben nach dem ersten Durchgang der Karte. Keine Updates, keine Löschungen.

| Spalte | Typ | Bedeutung |
|---|---|---|
| id | uuid | Zeilen-ID |
| card_id | text | stabile Karten-ID (Content-ID oder `u:`-ID) |
| created_at | timestamp | Zeitpunkt (UTC) |
| mode | text | `mixed`, `deck`, `revue`, `early` |
| sentence_id | text | gezeigter Satz (`sentences.id` oder `card_contexts.id`) |
| first_attempt_correct | bool | erster Versuch exakt |
| error_count | int | falsche Versuche im ersten Durchgang |
| revealed | bool | "Wort erfahren" benutzt |
| box_before | int | Box vor der Antwort (0–5) |
| box_after | int | Box nach der Antwort (1–5) |
| due_at_after | timestamp | neue Fälligkeit |
| response_ms | int | Millisekunden bis zur ersten Antwort |
| app_version | text | App-Version |
| device_id | text | Gerät |

## Bestätigte Regeln (früher Annahmen)

- Karte in Box 0 (aus Story, noch nie beantwortet) zählt als "Noch nicht angezeigt". ✔
- Tagesziel = verschiedene Karten mit `review_log`-Zeile heute. ✔
- `mode = early` kennzeichnet Vorab-Üben innerhalb von Gemischt (Box-Regel wie Revue). ✔
- Eine `review_log`-Zeile je Karte und Session; die In-Session-Wiederholung wird nicht geloggt. ✔
