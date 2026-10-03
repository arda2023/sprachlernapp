# Wiederholungssystem (SRS)

Quelle der Regeln: `PRODUCT.md`. Code: `lib/domain/` (Interface `SpacedRepetitionEngine`).

## Karte und Zustand

Eine Karte ist eine exakte Wortform in einer Bedeutung. Zustand je Karte in `user.db`: `box` (0 = noch nie beantwortet, 1–5), `due_at`, `origin` (deck / story), `disabled`, `created_at`.

## Intervalle

| Box | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|
| Tage | 1 | 4 | 14 | 40 | 90 |

Standardwerte, einstellbar. `due_at` = Antwortzeitpunkt + Intervall der neuen Box. Box 5 heißt "gemeistert".

## Erstkontakt

Eine Karte entsteht bei der ersten Anzeige in einem Stapel oder per "Zum Lernen hinzufügen" (Box 0). Der erste Versuch entscheidet:

- richtig (ohne falschen Versuch, ohne "Wort erfahren") → Box 3
- sonst → Box 1

## Danach

- **Antwort sauber** (erster Versuch exakt) → Box + 1 (höchstens 5).
- **Fehler** (falscher Versuch, falsche Form, "Wort erfahren") → Box 1.
- "Fast richtig" ist kein Fehler.
- **Vorab-Üben** und **Stapel-Revue** (Karte nicht fällig): richtig → Box bleibt, `due_at` bleibt; Fehler → Box 1.

## In-Session-Wiederholung

Eine Karte mit Fehler kommt einmal wieder, etwa 3 Karten später. Die Box entscheidet allein der erste Versuch; die Wiederholung ändert Box und `due_at` nicht und erzeugt keine eigene Zeile im `review_log`.

## Queue je Modus

Deaktivierte Karten sind nie in einer Queue.

**Gemischt**
1. Fällige Karten aller Herkunft (`due_at ≤ jetzt`, älteste zuerst).
2. Neue Wörter aktiver Stapel (und Story-Karten in Box 0), bis das Tagesziel erreicht ist.
3. Weitere neue Wörter.
4. Vorab-Üben der als Nächstes fälligen Karten.

Der Stapelschalter steuert nur Schritt 2 und 3 (neue Wörter); gesehene Karten werden immer wiederholt.

**Lerne mit diesem Stapel**: nur Formen und Sätze dieses Stapels, nie reine Story-Karten, auch bei inaktivem Stapel. Reihenfolge: fällige Karten des Stapels, dann neue Wörter des Stapels.

**Stapel-Revue**: nur gesehene Karten des Stapels (Box ≥ 1), als Vorab-Üben (Box bleibt, Fehler → Box 1).

## Abgeleitete Zähler

Nie gespeichert. Mit `A` = aktive Stapel, `C` = nicht deaktivierte Karten, `now` = Abfragezeit:

| Zähler | Definition |
|---|---|
| Noch nicht angezeigt | Formen aus `deck_cards` von `A` ohne Karte in `user.db` **plus** Karten in `C` mit `box = 0` |
| Verfügbare Wiederholungen | Karten in `C` mit `box ≥ 1` und `due_at ≤ now` |
| Wörter gemeistert | Karten in `C` mit `box = 5` und `due_at > now` |
| Wörter im Aufbau | Karten in `C` mit `box` 1–4 und `due_at > now` |

Zuordnung in dieser Reihenfolge, damit die Zähler disjunkt sind. **Invariante:** Summe der vier = |`C`| + Formen aus `A` ohne Karte. Tagesziel-Fortschritt und Streak entstehen aus `review_log` (lokale Kalendertage).

## review_log (nur anhängen)

Eine Zeile je Karte und Session, geschrieben nach dem ersten Durchgang der Karte. Keine Updates, keine Löschungen.

| Spalte | Typ | Bedeutung |
|---|---|---|
| id | uuid | Zeilen-ID |
| card_id | text | stabile Karten-ID |
| created_at | timestamp | Zeitpunkt (UTC) |
| mode | text | `mixed`, `deck`, `revue`, `early` |
| sentence_id | text | gezeigter Satz |
| first_attempt_correct | bool | erster Versuch exakt |
| error_count | int | falsche Versuche im ersten Durchgang |
| revealed | bool | "Wort erfahren" benutzt |
| device_id | text | Gerät |

## Offene Annahmen

- Tagesziel zählt verschiedene Karten, die heute eine Zeile im `review_log` haben.
- `early` kennzeichnet Vorab-Üben innerhalb von Gemischt (Box-Regel wie Revue).
