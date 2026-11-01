# Tägliche Nachrichten

**Stand 01.11.2026: vorbereitet, nicht aktiv.** Auf Nutzerwunsch ist der Bereich „Nachrichten“ in der App vorerst ausgeblendet, auch die Beispieltexte; die Funktion kommt später. Nichts davon ist auf dem Server: Die Migrationen und die Function liegen in `supabase/drafts/daily-news/`, damit `db push` und `functions deploy` sie nicht mitnehmen. Zum Einschalten die beiden Migrationen nach `supabase/migrations/` (mit neuem Zeitstempel) und `refresh-news/` nach `supabase/functions/` zurücklegen (Importpfad wieder `../_shared/daily_news.ts`), in `supabase/config.toml` `[functions.refresh-news] verify_jwt = false` ergänzen und in `app_shell.dart` die Artikel aus `newsProvider` wieder an den Stories-Tab geben. Danach die Einrichtung unten ausführen.

Geplant: Der Bereich „Nachrichten“ im Stories-Tab zeigt echte, täglich erzeugte Nachrichten.

## Ablauf

1. `pg_cron` ruft um 04:00, 04:06, 04:12, 04:18 und 04:24 UTC je ein Ressort auf: Politik, Wirtschaft, Technologie, Medizin, Unterhaltung (Entwurf `supabase/drafts/daily-news/20261101000005_daily_news_schedule.sql`).
2. Die Edge Function `refresh-news` (`supabase/functions/_shared/daily_news.ts`) prüft das gemeinsame Geheimnis `x-news-secret`. Dann sucht Claude Haiku 5.5 mit dem Websuche-Tool (`web_search_20250305`, höchstens 5 Suchen) die 3 bis 6 wichtigsten Meldungen der letzten 48 Stunden. Es meldet sie über das Werkzeug `report_stories`: englische Fakten in eigenen Worten plus 1 bis 3 Quellen. Nur Links, die die Suche tatsächlich geliefert hat, werden angenommen.
3. Für jede Lernsprache (en, pt-BR, es, it, nb) schreibt Haiku 5.5 parallel kurze B1-Artikel: Titel, 2 bis 3 Abschnitte mit Zwischenüberschrift, je 2 bis 4 Sätze, jeder Satz mit deutscher Übersetzung. Das Format ist per JSON-Schema festgelegt, ohne Denkmodus.
4. `store_news` ersetzt die Ausgabe dieses Ressorts und dieser Sprache. Ausgaben älter als 14 Tage werden gelöscht. Scheitert eine Sprache, bleibt ihre vorige Ausgabe stehen.
5. Die App liest über `latest_news(p_lang)` je Ressort die neueste Ausgabe der letzten 7 Tage, mit dem öffentlichen Schlüssel und ohne Konto. Die letzte gute Antwort liegt für die Offline-Nutzung unter `Application Support/news/<lang>.json`.

## Einrichtung (einmalig, mit Zustimmung)

- Secret der Function: `supabase secrets set NEWS_CRON_SECRET=<zufälliger Wert>`. `ANTHROPIC_API_KEY` ist bereits als Server-Secret gesetzt.
- Vault: `select vault.create_secret('<https://<ref>.supabase.co>', 'project_url');` und `select vault.create_secret('<gleicher Wert>', 'news_cron_secret');`
- Veröffentlichen: `supabase db push --linked` (Migrationen `…04_daily_news.sql`, `…05_daily_news_schedule.sql`) und `supabase functions deploy refresh-news`.
- Erster Lauf ohne Warten: dieselbe `net.http_post`-Anfrage wie im Cron-Job einmal per SQL ausführen, oder `cron.schedule` abwarten.

Die Schlüssel stehen nie im Repository oder in der App. Ohne das Geheimnis antwortet die Function mit 401 und startet keine kostenpflichtige Anfrage.

## Kosten (Schätzung, Preise Stand 01.11.2026)

- Websuche: 10 $ je 1.000 Suchen, höchstens 5 je Ressort und Tag, also bis 25 Suchen ≈ 0,25 $ pro Tag.
- Tokens Haiku 5.5 (0,10 $ / 0,50 $ je Million Ein-/Ausgabe): Suchergebnisse etwa 5 × 50.000 Eingabetokens, Artikel etwa 25 × 4.000 Ausgabetokens, zusammen deutlich unter 0,10 $ pro Tag.
- Gesamt grob 0,30 $ pro Tag, unter 10 $ pro Monat. Die Rechnung im Anthropic-Konto ist maßgeblich.

## Inhaltliche Regeln

- Eigene Worte, keine Zitate, keine drastischen Details. Namen, Zahlen und Fakten werden aus der Recherche übernommen und nicht ergänzt.
- Quellenangaben stehen unter jedem Artikel im Reader („Quellen“, öffnet die Seite im Browser), wie es die Zitierregel der Websuche verlangt.
- Suchergebnisse gelten als Information, nie als Anweisung.

## Prüfungen

- `node --experimental-transform-types --test supabase/functions/_shared/daily_news_test.ts`: simulierte API mit Suche, pausierter Suche, erfundenen Quellen, Teilausfall einer Sprache, Ablehnung und falschem Geheimnis.
- `node tool/test_daily_news_sql.mjs <pglite>/dist/index.js`: Rechte, neueste Ausgabe je Ressort, Ersetzen, Prüfregeln, Löschen alter Ausgaben.
