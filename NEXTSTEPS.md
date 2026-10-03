# NEXTSTEPS

## Erledigt (2026-10-03, Pipeline 3d)

- Persistentes Bedeutungs-Inventar `pipeline/data/meanings/en.json`; vorhandene `sense_key` bleiben stabil, Refresh hängt nur an.
- meanings-v3 trennt Wortarten und begrenzt Bedeutungen nach Wortfrequenz auf vier bzw. drei.
- sentences-v3 erzeugt fünf Kandidaten in einem Aufruf; bei Bedarf zwei Dreier-Runden. Satzanfänge je Karte sind verschieden.
- i+1 verwendet den höheren Zipf-Wert aus Lemma und Form; Namenspool und Zahlen sind ausgenommen. review.csv nutzt Komma und UTF-8 mit BOM.

## Testergebnis und Kosten

- Offline: `pytest -q` → 64 passed.
- Smoke einmal: 5/5 Formen, `left#links` im Pack, 15 Karten und 45 gültige Sätze; 169 Aufrufe, 0,121110 USD, 0 Denk-Token.
- Pilot einmal: 60 Formen, 169/177 Karten im Pack (95,48 %), 507 gültige Sätze; 2.443 Aufrufe, 1,674511 USD, 6.431 Denk-Token.
- Beide Packs: jede Lücke trifft die Form, alle Pack-Sätze `ok`, jede Pack-Karte genau drei Sätze; Satzanfänge je Karte verschieden.

## Abweichungen

- Acht Pilotkarten erreichten keine drei Sätze; Gründe und Blindtest-Antworten stehen vollständig in `pipeline/out/run_report.md`.
- Häufigste Verwerfungen: `what` 61, `there` 38, `like` 34, `this` 29, `i` und `your` je 22.

## Offen

- Kleingeschriebenes `i` aus wordfreq wird vom Blindtest als `I` beantwortet; Kanonisierung der Form vor einem Folgelauf klären.
- Schwierige Funktionswort-Bedeutungen wie `what#ausruf`, `there#beruhigung` und `like#als_ob` fachlich prüfen.
