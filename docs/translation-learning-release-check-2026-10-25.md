# Abschlussprüfung Übersetzung und Story→Lernkarte · 25.10.2026

Ausgangsstand `0982982` (Function v7). Korrektur `682d92c`, ausgeliefert als `create-learning-card` v8 und iPhone-Profile-Update. Für diese Prüfung freigegeben: höchstens 15 echte Generierungen und 1 USD. Verbraucht: **15 Generierungen, 22 kostenlose Tokenzählungen, 0,0054 USD**. Nur synthetische Sätze, kein Produktionsschreibzugriff.

## Prüfweg

- **Lokal:** vorhandene Flutter-, Backend- und SQL-Regressionen; dazu drei neue Regressionen, die vor der Korrektur fehlschlugen.
- **Anbieter:** Die echten Handler von `lookup-word`, `translate-sentence` und `create-learning-card` liefen lokal in Node.
  - Auth, RPCs und Storage waren simuliert, die Packbytes echt (EN `510c6685…`, pt-BR `4213d487…`).
  - Jeder echte Request ging zuerst kostenlos an `count_tokens`. Damit sind Schema und Request beim Anbieter geprüft. Erst danach wurde generiert, mit Hartgrenze im Ledger, ohne SDK und ohne Retries.
  - Der Schlüssel wurde nur verdeckt im Nutzerterminal eingegeben und nur an den Kindprozess übergeben.
- **Grenzen:** Ein Mock-Anbieter ist kein Kompatibilitätsnachweis. Die simulierten RPCs ersetzen weder die Cloud-Last noch die Mehrgeräte-Nebenläufigkeit.

## Prüfmatrix

| Prüfpunkt | EN | pt-BR | Nachweis |
|---|---|---|---|
| Geprüfte Übersetzung/genauer Cache ohne Modellaufruf | ✓ | ✓ | `offline_translation_flow_test` (Cache vor Wörterbuch/Einwilligung), `runtime_translation_test` (gespeicherter Satz ohne Provider), `translation_cache_test` (exakte Identität inkl. Akzente/Sprache) |
| Eindeutiger Wörterbuchtreffer | ✓ | ✓ | `dictionary_selection_test`, `offline_translation_flow_test`; bewusst konservativ: nur Substantive mit genau einer Glosse |
| Mehrdeutig, gebeugt, Akzent, Apostroph, Bindestrich | ✓ | ✓ | Live T1 *left*, T2 *comprou*, T3 *manga* (→ Ärmel), T4 *didn't*, C6 *guarda-chuva*; Wortgrenzen-Regressionen aus `c8c031a` |
| Satzübersetzung | ✓ | ✓ | Live T4/T5; nur nach ausdrücklicher Aktion (`runtime_translation_test`) |
| Passende bestehende Karte (reuse_id) | ✓/Fix | – | Live C2 (*bought*, richtige Funktion `past`). C1 (*Station*): **Fehler gefunden und behoben**, siehe unten. pt-BR-Pack hat keine passenden Karten. |
| Neue Karte aus geeignetem Original | ✓ | ✓ | Live C3, C5, C6: technisch gültig; Qualitätsmängel behoben, siehe unten |
| Ersatzsatz bei 1–2 Wörtern | Fix | ✓ nach Fix | Live C4/C7: **Fehler**, zwei gezielte Korrekturen, C7 danach gültig |
| Kein Ersatz nur wegen Pronomen | ✓ | – | Live C3 „She folded it and put it away.“ bleibt Original |
| Deutsch gleich geschrieben | ✓ | – | Live C5 *kindergarten*: Hinweise ohne Antwort, Lesecache nicht übernommen und nicht überschrieben (`personal_reading_cache_preservation_test`) |
| Genau ein fester Übungskontext | ✓ | ✓ | `story_collection_test`, `personal_learning_flow_test`; Hamster-Geräteabnahme `0982982` |
| Keine doppelte Karte / getrennte Lernstände | ✓ | ✓ | 8 parallele Adds → 1 Karte; neue Regression „Went“ → Packkarte `went` |
| Speicherung, Sammlung, erneutes Öffnen, Neustart | ✓ | ✓ | echte SQLite schließen/öffnen; Gerät (Hamster) |
| Offline mit Cache/gespeicherten Karten | ✓ | ✓ | `translation_cache_test`, `story_learning_flow_test`, `personal_import_status_test`; Gerät siehe Prüfliste |
| Netzabbruch, Anmeldung, Kontowechsel, Sprachwechsel, Limit, Retry | ✓ | ✓ | `personal_retry_client_test` (verlorene Antwort → eine Karte), `translation_cache_test` (Konto/Token), `word_cloud_consent_test`, `personal_learning_error_test`, SQL-Suiten |
| Keine Erstellung durch Tap/Scrollen/Import | ✓ | ✓ | `offline_translation_flow_test` (Mounten ohne Tap startet nichts); Karte nur über „Zum Lernen hinzufügen“ |

## Liveproben

| Fall | Zweck | Ergebnis |
|---|---|---|
| T1–T3 | Wortübersetzung EN/pt-BR | 200; *leave*: „verlassen, zurücklassen“ (Kontext eher „liegen lassen“), *comprar*: „kaufen“, *manga*: „Ärmel“ |
| T4–T5 | Satzübersetzung | 200; natürlich und korrekt |
| C1 | Reuse *Station* (Pack *station*) | 502 `CACHE_CONFLICT`: `cache_use=true` ohne mitgeschickte Hinweise |
| C2 | Reuse *bought* (past/past_participle) | 200, richtige Packkarte |
| C3 | Neue Karte mit Pronomen | 200; Lemma deutsch „falten“, Funktion falsch `past_participle` |
| C4 | „Cheers!“ | 502 `RULE_15` (2×): `too_short`, aber Original zurückgegeben |
| C5 | *kindergarten* mit Lesecache „Kindergarten“ | 200; Cache korrekt verworfen, Hinweis umständlich, aber lösungsfrei |
| C6 | *guarda-chuva* | 200; Hinweis „das Ding zum Schutz vor Regen“ statt „Regenschirm“ |
| C7 | „Obrigada!“ | 1. Fix: 502 `RULE_13` mit **deutschem** Ersatzsatz; 2. Fix: 200, „Obrigada pela ajuda que você me deu hoje cedo.“, Hinweis „danke“ |
| S1 | gesperrte Bedeutung (nur Zählung) | Schema angenommen |

Kostenlose Zählungen nach der Korrektur: C1, C4, C5, S1 → 200. Technische Gültigkeit und sprachliche Eignung sind getrennt bewertet. Fünf der neun ersten Kartenantworten waren gültig; inhaltlich gut waren C2 und C5 (mit Einschränkung). Die Stichprobe ist sehr klein und keine statistische Qualitätsaussage.

## Behobene Fehler (`682d92c`)

1. **Schreibvarianten erzeugten Doppelkarten.**
   - Fehler: Kandidaten wurden mit exakter Schreibweise gesucht, gesperrte Karten normalisiert. „Station“ am Satzanfang fand die Packkarte *station* nicht und legte eine zweite private Karte mit eigenem Lernstand an. Eine deaktivierte *station* führte serverseitig zu 422.
   - Korrektur: Client (`personal_learning_service.dart`) und Server (`formNorm`) vergleichen jetzt wie bei Sperren über `contentFormNorm` (NFC, Kleinschreibung, ’→'). Die Lücke behält die exakte Oberfläche.
   - Nachweis: Regressionen „Went“ (Flutter, echte SQLite) und „Station“ (Server).
2. **Ein-/Zwei-Wort-Originale konnten keine Karte bekommen.**
   - Fehler: Prompt und Schema verlangten zugleich „Original byte-genau“ und „ersetzen“. Ergebnis war RULE_15; nach dem ersten Fix kam ein deutscher Ersatzsatz mit falschem Offset (RULE_13).
   - Korrektur: Das Schema nennt die bestehenden RULE_15/19/20 jetzt pro Anfrage: `reason` nur `too_short`, ein neuer Satz in `input.lang`, nie Deutsch, eine großgeschriebene Form am Satzanfang (`start` 0).
   - Validator unverändert. Bewusst kein serverseitiges Nachrechnen von `start`: RULE_13 hat hier eine falschsprachige Karte verhindert.
3. **Behauptete Cacheübernahme ohne Hinweise.** Ohne mitgeschickten Wort- bzw. Satzhinweis ist das jeweilige `cache_use`-Flag im Schema `enum:[false]`.
4. **Sprachliche Mängel aus dem Vertrag.** Neu vorgegeben:
   - Das Lemma steht in der Ausgangssprache.
   - `past` und `past_participle` werden unterschieden.
   - Die schlichte deutsche Entsprechung ist der gewünschte Hinweis; umschreiben nur bei identischer Schreibweise.
   - `form_detail` steht auf Deutsch.

GitNexus: `_add`, `personalInput`, `perform` LOW; `personalResponseSchema` vor Neuindizierung CRITICAL (Namenskanten), danach LOW. `detect_changes(staged)`: 4 Dateien, mittel, ausschließlich `personalHandler`/`personalInput`-Abläufe, vollständig.

## Nicht live bestätigt

- **C1 und C4 mit dem geänderten Vertrag:** nicht erneut generiert, weil das Budget erschöpft war. Belegt sind die Annahme der Schemas durch Tokenzählung, die erzwungenen `false`-Flags per Constrained Decoding und die pt-BR-Entsprechung C7.
- **Verbesserte Lemma- und Funktionsangaben bei EN-Neukarten** (C3): nicht erneut generiert.
- **Wiederverwendung mit Großschreibung auf dem Gerät:** braucht eine weitere Generierung, siehe Prüfliste.
- **Kompatibilität alter Clients:** Ein alter Client würde bei „Station“ jetzt eine angebotene Wiederverwendung als „Unbekannte Kartenreferenz“ ablehnen. Das betrifft nur Geräte ohne das heutige Update.

## Bekannte Grenzen (dokumentiert, nicht geändert)

- Übersetzungen: Ein unklarer oder gescheiterter Versuch sperrt dieselbe Wort- bzw. Satzstelle 24 Stunden (`docs/story-translation-cache.md`). Für Lernkarten gibt es dagegen den ausdrücklichen Retry. Die Angleichung wäre eine Produktentscheidung.
- Laufzeit-Wortübersetzungen liefern freie Wortartlabels („verb“, „Substantiv“). Deshalb ist ihre Wortübernahme in Karten praktisch nie zulässig. Das ist richtig, aber ineffizient.
- Ob eine Antwort in der falschen Sprache steht, kann der Validator nicht deterministisch prüfen.
- KI-Funktionen erfordern eine interne Leserfreigabe (`content_readers`, `internal`).

## Kosten und Limits

Gemessen (Haiku 5.5, 0,10/0,50 USD je Mio. Input/Output, Prompts bis 100k):

| Anfrage | Input / Output Tokens | Dauer (Generierung) | Kosten |
|---|---|---|---|
| Wortübersetzung (n=3) | 528–536 / 57–72 | 1,3–2,6 s | ≈ 0,00009 USD |
| Satzübersetzung (n=2) | 350 / 30–39 | 1,2–1,4 s | ≈ 0,00005 USD |
| Kartenerstellung (n=10) | 3369–3788 / 265–386 | 1,9–4,8 s | ≈ 0,0005 USD |

Die Karte kostet etwa das Zehnfache einer Wortübersetzung, vor allem wegen des festen Vertragstexts. Gerät und Cloud brauchen zusätzlich etwa 1 s für Auth und Pack.

Aktive Limits, lesend geprüft (`migration list --linked`: alle 16 Migrationen lokal = remote; spätere Migrationen rufen die Limitfunktion nur auf):

- **Je Nutzer:** 5 Anfragen pro UTC-Minute, 20 pro UTC-Tag.
- **Global:** 1000 pro Tag.
- **Geltungsbereich:** gemeinsam für Wort, Satz und Karte. Cachetreffer zählen nicht, Fehlversuche zählen.

Auswirkung:
- **Normale Nutzung**, etwa 10–15 neue Wörter, 2–3 Sätze und 2–3 Karten am Tag: passt, Kosten unter 0,003 USD/Tag.
- **Intensives Lesen eines importierten Texts:** Nach 20 nicht gecachten Tipps ist der Tag aufgebraucht. Schnelles Tippen löst nach 5 Anfragen pro Minute 429 aus („Übersetzungslimit erreicht“).
- **Rechnerische Obergrenzen:** 20 Karten ≈ 0,01 USD je Nutzer und Tag; global ≈ 0,50 USD/Tag.
- Abo- oder Preismodell: offen (`PRODUCT.md`), hier nicht festgelegt.

## Urteil

**Bereit für eine begrenzte Beta** (interne Leser, wenige Tester), **nicht für den öffentlichen Release.**

Gründe:
- Übersetzungen sind live korrekt und günstig.
- Die Kartenerstellung funktioniert für Wiederverwendung, Originale und jetzt auch Ein-Wort-Originale (pt-BR live).
- Die Kernpfade sind durch Regressionen abgesichert.

Gegen einen öffentlichen Release sprechen:
- Die sprachliche Qualität neuer Karten schwankt; bei 9 Kartenantworten war rund ein Drittel zunächst ungültig.
- Die heutigen Vertragsänderungen sind nur teilweise live bestätigt.
- Das Tageslimit von 20 bremst intensives Lesen.
- Die 24-h-Sperre bei Übersetzungen besteht weiter.
- Ein Preis- und Freikontingentsmodell fehlt.
- Es gibt keine Qualitätsmessung über eine größere Stichprobe.

## Verifikation

- Flutter: 619 PASS, 6 bestehende Skips.
- Backend: 57 PASS.
- SQL: 4 Suiten plus Produktionshandler-Probe PASS.
- Original-Pack: 1 PASS.
- Stage: verifiziert (22 Tabellen, `b8579…`).
- Analyse: nur bestehendes `avoid_print` (`test/data/baseline_adoption_pack_test.dart:43`).
- Die drei `content_*`-Testdateien sind Deno-Tests und gehören nicht zum Node-Befehl (Altbefund).

Auslieferung:
- Vorher v7 = `0bfa641` lesend bestätigt, danach v8 = `682d92c` byte-gleich, `verify_jwt=true`.
- Andere Functions, Migrationen und Secrets unverändert.
- iPhone-Profile-Build aus einem **sauberen Export von `682d92c`** (ohne nicht committete fremde Onboarding-Arbeit) mit den unveränderten Supabase-Defines; als Update installiert und gestartet.

## iPhone-Prüfliste

1. App öffnen → „Aus Storys“: Hamster-Karte vorhanden; Übung öffnen: genau ein Kontext, nichts absenden.
2. Story „The hamster sleeps in the cage“ öffnen, *hamster* antippen: Übersetzung sofort aus dem Cache, Status „Hinzugefügt“.
3. Flugmodus an, App ganz schließen und neu öffnen. Schritt 1 und 2 wiederholen: beides funktioniert offline. Flugmodus aus.
4. Ein beliebiges Wort mit Packübersetzung in einer Pack-Story antippen und das Blatt schließen: keine neue Karte in Wortliste oder „Aus Storys“.
5. Optional, **nur mit zusätzlicher Freigabe für eine Generierung** (≈ 0,0005 USD): „Computer games are fun.“ importieren, *Computer* antippen, einmal „Zum Lernen hinzufügen“. Erwartet: Verknüpfung mit der bestehenden Packkarte *computer*, keine zweite Karte. Bei einem Fehler: Code notieren, nicht wiederholen.

## Nutzerbeobachtung iPhone · 25.10.2026

Der Nutzer hat die Prüfliste auf „iPhone von Claus“ selbst durchgeführt und meldet: „Die von mir durchgeführte iPhone-Prüfung funktioniert.“ Das gilt für die Schritte 1–4 (Hamster-Karte mit genau einem Kontext, Cache-Übersetzung mit „Hinzugefügt“, Offlinebetrieb nach Neustart, keine Karte durch bloßes Antippen). Schritt 5 (*Computer*-Wiederverwendung, optional, zusätzliche Generierung) wurde nicht ausdrücklich bestätigt und gilt **nicht** als bestanden. Die Wiederverwendung mit Großschreibung auf dem Gerät bleibt damit unbestätigt.
