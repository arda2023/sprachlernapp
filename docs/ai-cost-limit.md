# Gemeinsame KI-Kostengrenze

Stand: 01.11.2026. Auf Nutzerwunsch eingerichtet und im verknüpften Supabase-Projekt veröffentlicht. Die Grenze gilt für neue, über die veröffentlichten Endpunkte gestartete KI-Aufrufe ab dieser Umstellung. Frühere Rechnungsbeträge werden nicht nachträglich rekonstruiert.

## Was begrenzt wird

Ein bestätigtes, nicht anonymes Supabase-Konto erhält höchstens **5.000.000 Mikro-Euro = 5 € Sicherheitsbudget pro UTC-Kalendermonat**. Gemeinsam begrenzt werden:

- `lookup-word` und `translate-sentence`;
- `create-learning-card`;
- die vorgeschaltete Themenprüfung und die eigentliche Erstellung in `generate-vocabulary`.

Die Grenze gilt auch bei Premium, Test-Premium und kostenloser Freischaltung. Die bisherigen kostenlosen Übersetzungs-, Premium-, Minuten-, Tages-, Wort- und globalen Limits gelten zusätzlich. Vorhandene Offline-Inhalte, native Apple-/Android-Sprachausgabe, Cachetreffer und Statusabfragen erzeugen keine neue KI-Reservierung.

Das ist **kein Limit für sämtliche Betriebsausgaben**: Supabase-Hosting, Datenübertragung, Storage, SMTP, Adapty/Storegebühren und administrative Redaktion sind nicht individuell mit diesem Zähler abgerechnet. Mehrere Konten einer Person bleiben mehrere Konten; es gibt keine behauptete Identitätsprüfung natürlicher Personen. Der vorbereitete Nachrichtenjob ist weiterhin nicht veröffentlicht.

## Geldrechnung und Sicherheitsreserve

Es werden Ganzzahlen statt Fließkomma-Euro verwendet. Die vom Anbieter dokumentierten Preise für `claude-haiku-5-5` betragen bei höchstens 100.000 Eingabetokens 0,10 USD/Million Input und 0,50 USD/Million Output; darüber 0,50 und 2,50 USD. Das dokumentierte Kontextfenster umfasst eine Million Tokens. Quelle, am 01.11.2026 geprüft: [Anthropic-Modellübersicht](https://platform.claude.com/docs/en/models/haiku-5-5/overview).

Der interne Tarif setzt vorsichtig **2 Euro einschließlich Wechselkurs-, Steuer- und Gebührenpuffer je Dollar** an. Das ist ein bewusst hoher Rechenfaktor, kein aktueller Wechselkurs und kein Rechnungsbetrag. Damit ergeben sich folgende Obergrenzen:

| Eingabeumfang | Euro pro Million Inputtokens | Euro pro Million Outputtokens |
|---|---:|---:|
| bis einschließlich 100.000 Tokens | 0,20 | 1,00 |
| mehr als 100.000 Tokens | 1,00 | 5,00 |

Die Kostendeckung gilt, solange Anbieterpreise und gesamter Euro-Umrechnungsfaktor innerhalb dieser angenommenen Obergrenzen bleiben. Ein anderes Modell, Zusatztools, Fast Mode, Prompt-Caching oder ein anderer Kontextumfang darf nicht ohne entsprechende Budgetanpassung eingeführt werden. Der gemeinsame Wrapper verweigert solche unerwarteten Requestoptionen.

Vor dem Versand wird das **gesamte dokumentierte maximale Eingabefenster** zum höheren Tarif reserviert, zuzüglich des fest begrenzten Outputs. Dadurch hängt die Obergrenze nicht von einer geschätzten Tokenzahl ab. Der [Tokenzähl-Endpunkt](https://platform.claude.com/docs/en/build-with-claude/token-counting) liefert eine Schätzung; er wird hier nicht als exakte Abrechnungsgrenze behandelt.

| Funktion | maximaler Output | vorläufig reserviert |
|---|---:|---:|
| Wort- oder Satzübersetzung | 384 Tokens | 1,001920 € |
| Persönliche Lernkarte | 1.500 Tokens | 1,007500 € |
| Themenprüfung | 128 Tokens | 1,000640 € |
| Vokabelliste | 16.000 Tokens | 1,080000 € |

Diese hohen Beträge sind **vorläufige Sicherheiten**, keine Behauptung entsprechender tatsächlicher Kosten. Sobald eine vollständig gelesene, plausible Anbieterantwort die Tokenzahlen bestätigt, wird die Reservierung einmalig auf den kleineren Verbrauch reduziert. Beispiel: 1.000 Input- und 4.000 Outputtokens verbrauchen beim kurzen Tarif 0,0042 € Sicherheitsbudget. Die Erzeugung einer Liste enthält zusätzlich die separate Themenprüfung.

Praktische Folge: Neue Anfragen können schon vor einem endgültig verbrauchten Betrag von 5 € gesperrt werden, weil der nächste Höchstbetrag nicht mehr hineinpasst. Bei vollständig bekannten bisherigen Kosten endet nutzbares Budget dadurch etwa einen Euro früher. Auch mehrere gleichzeitig laufende Anfragen können vorübergehend sperren. Das ist die beabsichtigte konservative Auslegung von „nicht mehr als 5 €“.

## Atomarität, Fehler und Wiederholungen

`reserve_ai_spend` sperrt pro Konto transaktionsweit, legt den UTC-Monat an und erhöht den Zähler nur, wenn die neue Reservierung vollständig passt. Erst eine ausdrücklich bestätigte `reserved`-Antwort erlaubt den Anbieteraufruf. Bei Datenbankproblemen, unbekannter Antwort, wiederverwendeter Attempt-ID oder gesperrtem Tarif erfolgt kein Aufruf.

Jeder echte Versuch erhält serverseitig eine neue UUID. Die bestehenden fachlichen Anfragekennungen verhindern weiterhin doppelte Generierung. Der Geldzähler ersetzt deren Wiederholungs- und Antwortspeicherung nicht.

`settle_ai_spend` ist genau einmal wirksam. Es akzeptiert nur plausible Input-/Outputzahlen innerhalb des reservierten Modellfensters. Es verändert den Monat der ursprünglichen Reservierung, auch wenn die Antwort erst im Folgemonat ankommt. Der Client kann weder Konto, Tarif, Ausgaben, Rückerstattungen noch Resetdatum bestimmen.

Bei Timeout, Netzwerkabbruch, Anbieterfehler, unbekanntem Verbrauch oder verlorenem Abrechnungs-Acknowledgement bleibt die volle Reservierung bestehen. Auch eine Antwort, die später an der Vokabelvalidierung scheitert, hat Geld gekostet; plausible Verbrauchsdaten werden vorher abgerechnet. Ein fachlicher Quoten-Refund bei fehlgeschlagener Übersetzung erstattet **nicht** das Geldbudget. Cachelöschung, Abmeldung, Kaufänderung und abgelaufene Anfragelocks setzen es ebenfalls nicht zurück.

Es gibt keinen clientseitigen Override und keinen öffentlichen „Guthaben zurücksetzen“-RPC. Die Tabellen sind RLS-geschützt; die beiden Geld-RPCs dürfen ausschließlich mit `service_role` aufgerufen werden. Konto-IDs stammen vorher aus Supabase Auth. Kontolöschung entfernt zugehörige Zähler und Versuche per Fremdschlüssel.

## Wichtiger Betriebsbedarf: Tarifprüfung vor Dezember

**Einordnung auf Rückfrage des Betreibers:** Diese Befristung wurde bei der Umsetzung als zusätzliche Vorsichtsmaßnahme eingeführt. Sie ist weder eine Vorgabe von Anthropic noch eine App-Store-Anforderung und war vom Betreiber nicht ausdrücklich bestellt. „Tarif-Freigabe“ bezeichnet hier ausschließlich die interne Datenbankkonfiguration, keinen Anbieter-Vertrag oder Genehmigungsprozess. Die jetzige Rückfrage ändert die bereits veröffentlichte Frist nicht.

**Die anfängliche Tarif-Freigabe läuft am 01.12.2026 um 00:00 UTC ab.** Danach blockiert der Server neue kostenpflichtige Anfragen, bis der Betreiber Preise, Kontextfenster und Euro-Puffer erneut geprüft und die Freigabe verlängert hat. Vorhandene Antworten und Offline-Lernen bleiben verfügbar. Es wurde keine automatische Preisfreigabe und keine Erinnerungsautomation eingerichtet.

Die Prüfung betrifft konkret die Input-/Outputpreise und ihre Kontextstaffel, das erlaubte Modell und maximale Kontextfenster sowie Wechselkurs, Steuern und Gebühren innerhalb des angesetzten Faktors von 2 EUR je USD. Sie verlangt keine erneute Prüfung der ganzen App. Das persönliche Monatsbudget beginnt unabhängig davon automatisch jeden UTC-Kalendermonat neu; die zusätzliche Befristung ist eine globale Sperre für neue KI-Reservierungen.

Die Konfiguration liegt in `app.ai_spend_policy`. Nur ein administrativer Datenbankzugang darf sie ändern. `enabled=false` ist eine sofortige Sperre für neue Reservierungen; bereits gestartete Anbieteraufrufe werden dadurch nicht rückwirkend abgebrochen. `monthly_limit_micros` darf per Datenbankconstraint nicht über 5.000.000 steigen. Bei einer Tarifänderung müssen Reservierungs- und Abrechnungsformeln gemeinsam angepasst werden; bestehende Reservierungen dürfen nicht nachträglich günstiger gerechnet werden, ohne ihren ursprünglichen Tarif nachzuweisen.

Alte Kostenzeilen werden nach Ende des zweiten Folgemonats stündlich entfernt. Der aktuelle Monat bleibt unangetastet, auch bei lange ungeklärten Versuchen. Es werden keine Themen, Sätze oder Modellantworten im Geldledger gespeichert.

## Nachweis und Reproduktion

- PostgreSQL/PGlite: elf Assertionsgruppen zu Rollenrechten, gemeinsamem Budget, Rundung, wiederholter Abrechnung, falschem Besitzer, deaktivierter/abgelaufener Policy, unbestätigten Konten, altem Monat, Kontolöschung und Datenaufbewahrung.
- Live-Supabase: zwölf tatsächlich gleichzeitig gesendete Reservierungs-RPCs erlaubten vier Listenreservierungen und stoppten acht. Gesamt: 4.320.000 Mikro-Euro. Cachelöschung änderte den Betrag nicht.
- Veröffentlichte Wort-, Satz- und Themenendpunkte verweigerten anschließend neue kostenpflichtige Anfragen mit `AI_MONTHLY_LIMIT`; keine weitere Reservierung entstand.
- Die erfolgreiche Live-Themenprüfung und Generierung wurden anhand realer Anbieter-Verbrauchsangaben abgerechnet; reine Statusabfragen erzeugten keinen zusätzlichen Versuch.

Für Windows PowerShell und macOS Terminal identisch, mit einem extern installierten PGlite-Modul:

```text
node tool/test_ai_spend_sql.mjs <absoluter-Pfad-zu-pglite/dist/index.js>
node --experimental-transform-types --test supabase/functions/_shared/ai_budget_test.ts
```

Die lokalen SQL-Tests simulieren Auth-Rollen und führen die tatsächlichen Migrationen/Funktionskörper aus. PGlite selbst bietet hier keinen Beweis für unabhängige parallele Datenbanksessions; dafür dient der separate Live-Test. Die Cron-Registrierung wurde auf Supabase geprüft. Einzelheiten und Restbefunde: [Sicherheitsnachprüfung](security-fixes-2026-11-01.md).
