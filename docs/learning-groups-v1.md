# Lerngruppen v1 — Offline-Abschluss vom 06.10.2026

Umgesetzt und intern gestagt: `learning_groups_v1`, Content-Schema 3. Neue Nutzer erhalten **649 Lernziele: 160 Allgemeine Sprache + 489 Reisen**. Die 660 bisherigen Wortbesitz-Zuordnungen, alle 764 Karten-IDs und alle 1298 Satztexte bleiben erhalten. Kein Batch 6, keine Ersatzwörter.

## Quelle und Eingriff

- Quelle: `pipeline/out/reisen_batch_5_v1/pack.json`; Wortbesitz-Snapshot: `pipeline/data/words/en.reisen_batch_5_v1.json` unverändert.
- Quellen-SHA-256: `e93bbf7991b00e54bb60e3f0d3a3832509e5d6a83faad1352d38cb91518c7d39`.
- Versionierte Entscheidungen: `pipeline/data/learning_groups/en.v1.json`, 764 Einträge mit alter Kartenreferenz/-ID, Gruppe, Hauptlernwortreferenz/-ID, Thema, Kontrasttags und Begründung. 660 primäre Wörter und 104 historische Nebenbedeutungen wurden auf Überschneidungen geprüft. Deutsche Glossen dienten nur als Kandidatensignal; auch POS, Form, Funktion und feste Sätze wurden berücksichtigt.
- Die nicht gruppierten Einträge bleiben explizite Einzelziele; keine Ableitung einer Bedeutungsidentität aus deutscher Übersetzung. 752 Gruppen über alle 764 Karten, davon 649 für automatische Primäreinführung.
- `fasten|fasten/VERB|fasten#schliessen`: Kartenglosse jetzt **anschnallen**. ID, Sense-Schlüssel, Satztext und alle historischen Übersetzungen bleiben erhalten. Weitere Bedeutungsunterschiede sind in den Entscheidungsnotizen präzisiert.
- Vorhandene uncommittete Batch-Änderungen und die Formatierung von `docs/content-schema.md` erhalten. Baseline: 736 Dateien; 142 geschützte Zulieferungs-/Registry-/App-Einstiegsdateien hashgleich.

## Redaktionelle Gruppen

| Hauptlernwort | Weitere Mitglieder (nur genannte Kartenbedeutungen) | Begründung |
|---|---|---|
| trip | travel, journey | Beschlossene gemeinsame Einführung der ausgewählten Reise-Nomen; Reise allgemein, einzelne Reise und Reiseweg bleiben im Wörterbuch unterscheidbar. |
| luggage | baggage | Gepäck als Sammelbegriff. |
| backpack | rucksack | Rucksack; lexikalische Varianten, keine Schreibaliasse. |
| excursion | outing | Beschlossener gemeinsamer Ausflugsbegriff. |
| rent | hire | Beschlossene Einführung des Mietens; hire nur Fahrzeugmiete, rent ist breiter. Keine gegenseitige Satzfreigabe. |
| booking | reservation | Vorab gebuchte Leistung im ausgewählten Kontext. |
| book | reserve | Eine Leistung vorab buchen/reservieren. |
| landscape | scenery | Beschlossene gemeinsame Einführung von Landschaft. |
| timetable | schedule | Beide ausgewählten Nomen bezeichnen den Verkehrsfahrplan. |
| help | assist | Beide ausgewählten Verben bezeichnen praktische Hilfe; assist ist formeller. |
| understand | get | Verstehen; historisches get#verstehen ist umgangssprachliche Variante, nicht get#bekommen. |

`rent` hat im vorhandenen festen Satz eine Wohnung als Objekt; der breitere Mietbegriff ist gemäß Auftrag Kopf, `hire` wird ausschließlich in seiner Fahrzeug-Mietbedeutung zugeordnet. Der Satz wurde nicht auf ein Auto umgeschrieben. `get` wird nur als historisches `get#verstehen` mit `understand` gebündelt; bekommen/gelangen/werden bleiben getrennt. Reisen-Nomen erzeugen genau ein neues Ziel `trip`; die unterschiedlichen Nuancen und Originalkarten bleiben nachschlagbar.

## Bewusst getrennte Kandidaten

| Kandidaten | Entscheidung |
|---|---|
| wallet/purse | Brieftasche für Karten/Scheine gegenüber kleinem Münzportemonnaie im britischen Kontext. |
| port/harbour | Hafen als Verkehrs-/Umschlagplatz gegenüber geschütztem Hafenbecken. |
| layover/stopover | Kurzer Umstieg gegenüber geplantem mehrtägigem Zwischenaufenthalt. |
| citizenship/nationality | Rechtlicher Bürgerstatus gegenüber Staatszugehörigkeit als Formularangabe; Reichweite nicht identisch. |
| junction/intersection/crossroads | Verkehrsknoten umfasst auch Einmündungen; intersection Straßenkreuzung, crossroads kreuzende Straßen. Ober-/Unterbegriffe bleiben getrennt. |
| find/locate | Allgemeines Finden gegenüber gezieltem Ermitteln des Orts. |
| necessary/essential | Notwendig gegenüber unverzichtbar/wesentlich; Intensitätsunterschied bleibt. |
| quiet/peaceful | Geräuscharm gegenüber friedlich/ungestört. |
| shade/shadow | Schattiger, vor Sonne geschützter Bereich gegenüber geworfenem Schattenumriss. |
| close/fasten | Öffnung schließen gegenüber Gurt befestigen/anschnallen. |
| a/an | Kontextabhängige Artikelformen vor Konsonanten-/Vokallaut; Formen getrennt üben. |
| was/had/has/are/have/been/were/is/be | Person, Tempus, Partizip und Hilfs-/Vollverbfunktionen sind eigenständige Formen/Bedeutungen. |
| aircraft/aeroplane | Luftfahrzeug umfasst mehr als Flugzeuge. |
| boat/ship/yacht/ferry | Boot/Schiff und spezialisierte Schiffstypen bleiben getrennt. |
| rain/drizzle/downpour | Regen gegenüber Niesel- und Starkregen. |
| mist/fog | Leichter Dunst gegenüber dichtem Nebel. |
| path/trail | Allgemeiner Fußweg gegenüber Wanderpfad. |
| waiter/waitress | Geschlechtsformen bleiben getrennt. |
| fee/charge/surcharge/cost/fare/price | Gebühr, Entgelt, Aufpreis, Kosten, Fahrpreis und Preis haben unterschiedliche Reichweite. |
| need/require | Subjekt braucht etwas gegenüber Anforderung durch Vorschrift/Umstand. |
| recommend/suggest | Empfehlen bewertet positiv, vorschlagen eröffnet eine Möglichkeit. |
| sunshine/sunlight | Sonniges Wetter gegenüber Lichtstrahlung. |
| safe/secure | Sicherheit vor Gefahr gegenüber gesichertem Verschluss. |
| available/vacant | Verfügbar gegenüber unbesetzt. |
| cheap/affordable | Geringer Preis gegenüber finanziell tragbar. |
| injury/wound/burn/blister/bruise | Verletzung als Oberbegriff und konkrete Verletzungsarten. |
| thief/pickpocket | Dieb als Oberbegriff, Taschendieb als Spezialisierung. |
| boarding/board/landing/land/rental/rent/booking/book/assistance/help | Wortarten und Nominalisierungen bleiben eigenständige Lernziele. |
| will/get | Zukunfts-Hilfsverb will und Zustandswechsel get (werden) sind verschiedene Funktionen. |
| her/they | Objektpronomen Singular her und Subjektpronomen Plural they bleiben getrennt. |
| by/with | by bezeichnet Transportmittel/Verfahrensweise; with Begleitung, Werkzeug oder Eigenschaft. Unterschiedliche Konstruktionen und Bedeutungen. |
| in | Zeitbezug gegenüber räumlichem Bezug. |
| more | Pronomen, Steigerungsadverb und Mengendeterminierer unterscheiden sich grammatisch. |
| they/you | Unbestimmte fremde Handelnde they gegenüber verallgemeinerndem you. |
| on | Zeitliche Präposition gegenüber eingeschaltetem Zustand. |
| which | Begleitender Determinierer gegenüber stellvertretendem Fragepronomen. |
| from/by | Unterscheidung von etwas gegenüber Urheber eines Passivs. |
| parking/park | Nominalisiertes Parken gegenüber Verb parken. |

Bei be/have wurden auch alle historischen Hilfs-, Vollverb-, Modal-, Partizip- und Vergangenheitsbedeutungen erfasst. Beispielsweise are als Hilfsverb bleibt von are als Kopula getrennt; has/have/had werden nicht ineinander überführt. Ebenso bleiben historische Präpositions-, Pronomen- und Funktionsunterschiede erhalten. Die maschinenlesbare Registry enthält die exakten Referenzen, auch wenn Tabellen dieselbe Oberfläche nur einmal nennen.

## Inhaltsschema und gemeinsame App-Regel

- Minimal additive Spalte `cards.learning` (`jsonb`, in SQLite JSON-Text). Felder: `group_id`, `primary_card_id`, `topic`, `related`, `note`. Eindeutige Mitgliedschaft durch Karten-ID. Export und App prüfen vollständige Metadaten, lebenden Kopf derselben Sprache/Gruppe, einheitlichen Kopf und eindeutige Kontrasttags. Schema 1/2 bleibt lesbar und ohne Metadaten bei Einzelzielen.
- Lokale Spiegelmigration `supabase/migrations/20261006000001_learning_groups.sql` ausschließlich angelegt, nicht remote ausgeführt. user.db bleibt Schema 4, ohne Migration oder Rücksetzung.
- `LearningGroups.project` bildet die gemeinsame neue Lernmenge: vorhandene gelernte Mitglieder alle behalten; sonst ältesten vorhandenen Box-0-Stand wiederverwenden (Zeitpunkt, danach ID), sonst redaktionellen Kopf. Jeder vorhandene Stand reserviert seine Gruppe auch bei Deaktivierung; kein Synonym umgeht diese Entscheidung.
- `PracticeItemResolver`, beide Queue-Modi, Zähler, Stapelfortschritt und Wortliste verwenden diese Projektion. Ein gelerntes Nebenmitglied verhindert einen zusätzlichen Erstkontakt des Hauptworts. Mehrere bereits gelernte Mitglieder behalten getrennte fällige Reviews, Revueplätze, Favoriten, Notizen, Playlist und Reviewzeilen. Darum können Bestandsnutzer mehr aktive gelernte Karten als neue Nutzer haben.
- Die vier Kategorien bleiben disjunkt und aus Zustand/Fälligkeit abgeleitet. Ungesehene Gruppen zählen einmal; gelernte Bestandskarten zählen einzeln. Deaktivierte/retirierte Karten zählen nicht. Die Wortliste erhält bedienbare deaktivierte und alle gelernten Zeilen; redundant gewordene unbewertete Zeilen werden nur ausgeblendet, nicht gelöscht.
- `deckCardIds` behält rohe Besitz-IDs für Bestandsschutz; Repository-Summaries zählen redaktionelle Ziele, lernstandsabhängige Anzeigen verwenden die Projektion. Kein gespeicherter Zähler.

## Story-Hinzufügen und neutrale Antworten

- Story-Hinzufügen verwendet ein vorhandenes Gruppenziel oder den Kopf atomar und idempotent. Tooltip und Quellenfingerprint beziehen sich weiterhin auf das tatsächlich angetippte Wort. Geübt wird der vorhandene geprüfte Satz des ausgewählten Ziels; kein Storysatz wird umgeschrieben.
- Lokale Karten werden ausschließlich über Sprache + normalisierte Form + stabile Sense-ID zugeordnet. Ihre Kontexte und Zustände bleiben erhalten. Gruppenweiterleitungen erzeugen keine falschen Schreib-/Sense-Bindungen; Quellen und explizite Storyentscheidung dürfen auf das wiederverwendete Ziel zeigen.
- Nur bestehende satzbezogene `valid_alternatives` sind neutral. Gruppenmitglieder sind nicht pauschal gültige Antworten. Keine neue Alternative ergänzt, keine Laufzeit-KI.
- Exakte Meldung: „Das passt auch. Gesucht ist hier ein anderes Wort. Versuch es noch einmal.“ Editierbar, neutrale Textfarbe, keine Fehlervibration, kein Lösungspräfix, kein Aufdecken.
- Synonym → exakt und wiederholte Synonyme → exakt: Erstkontakt Box 3, `error_count=0`, `hint_used=false`, `first_attempt_correct=true`, kein Extra-Review und keine Wiederholung allein deswegen. Reguläre Reviews steigen normal; Revue/Vorab-Üben behalten Box/Termin.
- Falsch → Synonym → exakt bleibt Box 1 mit dem echten Fehler. Synonym → Aufdecken bleibt Box 1 mit `revealed=true`. Neutrale Versuche verbrauchen den bewerteten Erstversuch nicht. Tippfehler verhalten sich unverändert: `first_attempt_correct=false`, trotzdem keine Box-Strafe. Historische `hint_used`-Werte bleiben unverändert, der Scheduler unterstützt den alten Flag weiterhin.

## Reihenfolge und Nachweis erster 30 Ziele

Beide Modi verwenden `selectNewCards`. Verwandt bedeutet gleiches redaktionelles Thema oder gemeinsames Kontrasttag. Wenn passende Kandidaten verfügbar sind, liegen mindestens drei andere neue Lernziele dazwischen. Bei Knappheit werden nur die vier Stufen 3 → 2 → 1 → 0 geprüft. Jeder Durchlauf wählt eine noch nicht verwendete Gruppe/Form/ein Lemma; keine Endlosschleife. Innerhalb der Stufe bleiben Storyvorrang, neue Lemmas und Inhalts-/Funktionswortregel erhalten. Verbleibende Ziele rücken in folgenden Sessions nach. Fällige Reviews und notwendige Wiederholungen sind davon unabhängig. Der Controller friert die einmal gebildete Session ein.

Read-only-Ausgabe der tatsächlichen produktiven Auswahl, ohne Lernstand, Größe 30: `tool/report_learning_groups.dart`; vollständige IDs und Gründe in `build/learning_groups_checks/selection.json`. Vorher ist jedes Ziel ein Einzelziel seiner alten Karten-ID; Grund jeweils alte Eingangsfolge, neues Lemma und Inhalts-/Funktionsquote. Danach bezeichnet `en:card:…` ein Einzelziel, `en:learning:…:v1` eine redaktionelle Gruppe. Der ausgewiesene Mindestabstand ist die tatsächlich verwendete Auswahlstufe; am Anfang gibt es entsprechend weniger Vorgänger.

### Reisen

| Nr. | Vorher (Einzelziel) | Nachher | Gruppe danach | Thema | Auswahlgrund danach |
|---:|---|---|---|---|---|
| 1 | travel | trip | `en:learning:trip:v1` | planning | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 2 | trip | tour | `en:card:ee59863a251654468ca533509290ee65` | culture | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 3 | journey | budget | `en:card:42be5e3a38dc1ee4f1d97674d6908551` | money | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 4 | tour | airport | `en:card:f8a2410991af88a4bdfa12f90ee7b9a9` | air | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 5 | holiday | holiday | `en:card:defe33d34b5f3b11a8649169bbb5bae8` | planning | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 6 | destination | luggage | `en:learning:luggage:v1` | luggage | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 7 | itinerary | railway | `en:card:4c15c23edf25b9ffe06b8a23d5359bd6` | rail | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 8 | excursion | airline | `en:card:cfd9ce0970a21dd5d8452b57d39bd84a` | air | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 9 | outing | destination | `en:card:19d6062feeff8189f006b38978394e65` | planning | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 10 | booking | suitcase | `en:card:f32a1760c273368d6377d7dcbae3521c` | luggage | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 11 | reservation | rail | `en:card:a294fc559111a8e25a9f72780aa5bb57` | rail | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 12 | confirmation | terminal | `en:card:4520f3d30abca71b4a24f30f84569f10` | air | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 13 | cancellation | itinerary | `en:card:df8e336c1fc6a048750f14810b9e3192` | planning | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 14 | availability | carousel | `en:card:cb73f7b9db3a003c7913c05cd9c5958e` | luggage | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 15 | date | platform | `en:card:50319e70ff0290edc98958a74c2c38d9` | rail | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 16 | duration | flight | `en:card:b9c98f0eee4f2c3fd074d8a9920fef13` | air | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 17 | budget | excursion | `en:learning:excursion:v1` | planning | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 18 | package | trolley | `en:card:b4e706ccc3fd02e32d5351d910376bdc` | luggage | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 19 | agency | timetable | `en:learning:timetable:v1` | rail | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 20 | agent | aircraft | `en:card:cf031b9da16c66d29dcd920db35f1969` | air | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 21 | traveller | booking | `en:learning:booking:v1` | planning | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 22 | companion | junction | `en:card:66d734bd51c25ca3b7f9192c46fa9ab6` | road | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 23 | group | carriage | `en:card:67cef1e9c2902f09b892907ba3804bc2` | rail | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 24 | recommendation | aeroplane | `en:card:4f2f9334e980a449c14641b2b10b6b86` | air | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 25 | preference | confirmation | `en:card:ba51a1435e8114b2f0d25949a3dd4575` | planning | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 26 | passport | coach | `en:card:2d316543c4386efb1700782e9fe30c12` | road | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 27 | visa | compartment | `en:card:4b89423a689b5e347bdc7e80369cd496` | rail | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 28 | border | pilot | `en:card:8daaaacf3afd336177259e0c10ced78d` | air | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 29 | customs | cancellation | `en:card:89e5a081575dc742f8cc9c946b27a8eb` | planning | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 30 | immigration | taxi | `en:card:12480fb421e836c827e201747fd697c0` | road | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |

### Allgemeine Sprache

| Nr. | Vorher (Einzelziel) | Nachher | Gruppe danach | Thema | Auswahlgrund danach |
|---:|---|---|---|---|---|
| 1 | is | is | `en:card:b325798ce493fd8ad1968460d3a038ab` | grammar | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 2 | have | like | `en:card:7a4f6baef68966c837f421dd2fe7f7c1` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 3 | just | time | `en:card:ddb15383296fd24e973ea11e4e5eb00f` | planning | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 4 | like | old | `en:card:0b22b7e132d111536d3516884f74ab19` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 5 | the | the | `en:card:d0980b611fd3e292e0dcdedf7c3d58b1` | grammar | Gruppenkopf; neues Lemma; Funktionswort; Mindestabstand 3 |
| 6 | up | do | `en:card:fcfbb872406704d91f8cf88e4f60da63` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 7 | out | money | `en:card:3c71a38fcd6ec62bb32d220c75ff93f3` | money | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 8 | do | full | `en:card:61ec48794256dc40ace9d3afda5f4eb4` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 9 | time | have | `en:card:60b73f88916bf4e77a016fc0217b3546` | grammar | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 10 | to | get | `en:card:31a9cf838af1e911d0b8ba3ce67bd87a` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 11 | get | head | `en:card:bdf9a1aa29a3ccd1959fbc96871c0761` | health | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 12 | old | hard | `en:card:678c782d556383c3a35e851b93a548c0` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 13 | money | just | `en:card:43ac1032025839d42212f6418e51d054` | grammar | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 14 | full | read | `en:card:fa82bc4e41ba46a0a1187a6b519c2235` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 15 | and | car | `en:card:66a5bca32470bdc87ddd6e16532db817` | road | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 16 | read | young | `en:card:692abd8adb6a6c591b20e32a6b3e3e53` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 17 | hard | up | `en:card:26f0624cbe450fb6632f6a5c0a7ef923` | grammar | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 18 | head | open | `en:card:9a1a28a337cefdbf11bceb185b271668` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 19 | open | hand | `en:card:cd767d1d713076842de381082551c9c8` | health | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 20 | of | office | `en:card:f9dcf6497687431647832b5f7e04247b` | objects | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 21 | car | out | `en:card:afbfe3a49f3493c1d30311e4718c872b` | grammar | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 22 | young | pay | `en:card:3a4febb432d220f62c6f1d4891e0a3ea` | money | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 23 | hand | close | `en:card:205f0f1f0f700fc4677f3d5a118d63b1` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 24 | office | phone | `en:card:12c292f705a3be680124ab5662656a77` | objects | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 25 | a | ready | `en:card:8bc52012a2d0ee4eaf469e64b0cd3fcc` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 26 | pay | to | `en:card:9cbf63e6494fa806cd7c5d6a8c1ad60c` | grammar | Gruppenkopf; neues Lemma; Funktionswort; Mindestabstand 3 |
| 27 | close | wait | `en:card:47eed138e4bf09bff6135f5b3993dd1a` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 28 | wait | buy | `en:card:211695c38c0a5270b39247c2486e0cfe` | money | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 29 | buy | road | `en:card:4a30a152f12d45bcfbf798afcb11101c` | nature | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 30 | in | strong | `en:card:067512cff1d073634236792dd096a597` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |

### Gemischt

| Nr. | Vorher (Einzelziel) | Nachher | Gruppe danach | Thema | Auswahlgrund danach |
|---:|---|---|---|---|---|
| 1 | is | is | `en:card:b325798ce493fd8ad1968460d3a038ab` | grammar | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 2 | have | like | `en:card:7a4f6baef68966c837f421dd2fe7f7c1` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 3 | just | time | `en:card:ddb15383296fd24e973ea11e4e5eb00f` | planning | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 4 | like | old | `en:card:0b22b7e132d111536d3516884f74ab19` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 5 | the | the | `en:card:d0980b611fd3e292e0dcdedf7c3d58b1` | grammar | Gruppenkopf; neues Lemma; Funktionswort; Mindestabstand 3 |
| 6 | up | do | `en:card:fcfbb872406704d91f8cf88e4f60da63` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 7 | out | money | `en:card:3c71a38fcd6ec62bb32d220c75ff93f3` | money | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 8 | do | full | `en:card:61ec48794256dc40ace9d3afda5f4eb4` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 9 | time | have | `en:card:60b73f88916bf4e77a016fc0217b3546` | grammar | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 10 | to | get | `en:card:31a9cf838af1e911d0b8ba3ce67bd87a` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 11 | get | head | `en:card:bdf9a1aa29a3ccd1959fbc96871c0761` | health | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 12 | old | hard | `en:card:678c782d556383c3a35e851b93a548c0` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 13 | money | just | `en:card:43ac1032025839d42212f6418e51d054` | grammar | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 14 | full | read | `en:card:fa82bc4e41ba46a0a1187a6b519c2235` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 15 | and | car | `en:card:66a5bca32470bdc87ddd6e16532db817` | road | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 16 | read | young | `en:card:692abd8adb6a6c591b20e32a6b3e3e53` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 17 | hard | up | `en:card:26f0624cbe450fb6632f6a5c0a7ef923` | grammar | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 18 | head | open | `en:card:9a1a28a337cefdbf11bceb185b271668` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 19 | open | hand | `en:card:cd767d1d713076842de381082551c9c8` | health | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 20 | of | office | `en:card:f9dcf6497687431647832b5f7e04247b` | objects | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 21 | car | out | `en:card:afbfe3a49f3493c1d30311e4718c872b` | grammar | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 22 | young | pay | `en:card:3a4febb432d220f62c6f1d4891e0a3ea` | money | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 23 | hand | close | `en:card:205f0f1f0f700fc4677f3d5a118d63b1` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 24 | office | phone | `en:card:12c292f705a3be680124ab5662656a77` | objects | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 25 | a | ready | `en:card:8bc52012a2d0ee4eaf469e64b0cd3fcc` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 26 | pay | to | `en:card:9cbf63e6494fa806cd7c5d6a8c1ad60c` | grammar | Gruppenkopf; neues Lemma; Funktionswort; Mindestabstand 3 |
| 27 | close | wait | `en:card:47eed138e4bf09bff6135f5b3993dd1a` | actions | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 28 | wait | buy | `en:card:211695c38c0a5270b39247c2486e0cfe` | money | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 29 | buy | road | `en:card:4a30a152f12d45bcfbf798afcb11101c` | nature | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |
| 30 | in | strong | `en:card:067512cff1d073634236792dd096a597` | qualities | Gruppenkopf; neues Lemma; Inhaltswort; Mindestabstand 3 |

## Bestands- und Exportprüfung

Alle 18 SQLite-Tabellen wurden zeilen- und spaltenweise gegen `build_rows` des tatsächlichen JSON-Exports geprüft, ausgenommen der neu erzeugte Release-Zeitstempel. `PRAGMA integrity_check = ok`, keine Foreign-Key-Verstöße. Besitz, Aliaslisten, vollständige Wörterbuch-/Sense-/Lemma-Daten, Satztexte, Tokens und historische Links stimmen mit der Quelle überein. Bei Karten sind nur Metadaten und die angekündigte fasten-Glosse neu.

| Größe | Ergebnis |
|---|---:|
| Karten | 764 |
| Gruppen über alle Karten | 752 |
| Alte Primär-Wortbesitzpositionen | 660 |
| Neue primäre Lernziele | 649 |
| Allgemeine Sprache | 160 |
| Reisen | 489 |
| Satztexte (davon Story) | 1298 (6) |
| Satzverknüpfungen inklusive Historie | 1292 |
| Schreib-/Besitzaliase | 8 |

Export-/Asset-SHA-256: `a8359628ed273ee81037abcf24cdb494a2d8b2dc29d667100190c4b6a985651e`. 6.684.672 Bytes. Vor erstem Staging gesichert unter `build/learning_groups_checks/asset_backup/`: altes SQLite `5921e5f481d6a1ee78ee20041405803d2610b539ecf781a0c160ead7baafd1dd` samt Manifest. Ursprüngliche Packs und Registryversionen nicht überschrieben. `lib/main.dart` unverändert: `c7e54ec1834b4dd18c592d32a310fae25394b6e2a48307fb3162de16e9eb4edd`.

## Tatsächlich gelaufene Prüfungen

```text
python -m pytest -q pipeline/tests
371 passed, 19 subtests passed in 13.49s
flutter analyze
No issues found! (ran in 2.9s)
flutter test
00:19 +248: All tests passed!
dart run tool/stage_content_pack.dart --verify
verified assets\content\en\content.sqlite
version learning_groups_v1, schema 3, 6684672 bytes
18 table counts match finalization_report.json
git diff --check
(keine Ausgabe, Exit 0)
```

Neue Tests: Domain-Gruppen/Abstand/Knappheit/kein Verhungern/exakte lokale Zuordnung; Pipeline-Identitäten/Hashbindung/Schemafehler/SQLite; separate temporäre Datei-Datenbank für Erstnutzer, gelerntes Nebenmitglied, mehrere gelernte Mitglieder, atomare Story-Doppelbetätigung, lokale Altkarte, neutrale Antworten, Fehler und Aufdecken sowie Neustart/idempotente Reviewbuchung. Provider-Neuberechnung erhält den aktuellen Pass. Widgettests prüfen neutrale Farbe, unveränderten Eingabetext/Hint, keine Haptik, korrekte Box, Summary und fehlende unnötige Wiederholung. Der echte Asset-Lesetest liest alle 764 Karten mit ihren aktiven festen Sätzen; der vollständige SQLite-Abgleich erfasst zusätzlich sämtliche historischen Satzverknüpfungen.

Zwischenbefunde behoben: Storyvorrang wurde bei der gemeinsamen Auswahl zunächst verdrängt; nun bleibt er innerhalb der Abstandsstufe erhalten. Alte Synonym- und 660-Anzeigeerwartungen in Tests wurden auf den neuen Produktvertrag geändert. Der Neuberechnungstest benötigt aktive Provider-Listener wie die Oberfläche; sein anfängliches Warten auf einen ungehörten, invalidierten Future wurde im Test korrigiert. Anschließend vollständiger grüner Lauf, keine offenen Testfehler.

Reproduzieren im Repository-Root:

Windows PowerShell:
```powershell
.\pipeline\.venv\Scripts\python.exe -m pytest -q pipeline/tests
```
macOS Terminal:
```sh
pipeline/.venv/bin/python -m pytest -q pipeline/tests
```
Beide Systeme:
```text
flutter analyze
flutter test
dart run tool/stage_content_pack.dart --verify
dart run tool/report_learning_groups.dart
git diff --check
git status --short
```

## Geänderte Pfade und Grenzen

- Content: `pipeline/data/learning_groups/en.v1.json`, `pipeline/src/sprachpipe/{learning_groups,pack,schema,content_contract}.py`, `pipeline/scripts/export_learning_groups.py`, lokale Spiegelmigration; neuer Export `pipeline/out/learning_groups_v1/`.
- App: `lib/domain/{learning_groups,content,new_card_selection,srs_state,review_pass,answer_check,story_learning,repositories,leitner}.dart`; `lib/data/content/{content_database,drift_content_repository}.dart`; `lib/data/learning/practice_item_resolver.dart`; `lib/data/user/drift_user_repository.dart`; `lib/presentation/providers/{deck_providers,learning_providers}.dart`.
- Tests: `pipeline/tests/test_learning_groups.py`, `test/domain/learning_groups_test.dart`, `test/data/learning_groups_test.dart`, bestehende Antwort-/Review-/Widget-/Assettests. Diagnose: `tool/report_learning_groups.dart`.
- Dokumentation: PRODUCT, DESIGN, ARCHITECTURE, SRS, Content-/User-Schema, Deck-/Story-Plan, dieser Bericht, NEXTSTEPS.
- Keine echte user.db geöffnet oder verändert; Testdatenbanken ausschließlich unter temporären Testpfaden. Keine neuen Geschichten, Cloud-/KI-Aufrufe, Veröffentlichung, Commits oder Pushes. Keine Codegenerierung nötig (keine typisierten Drift-Tabellen oder Providerdeklarationen geändert).
- Kein physischer Geräte-/Emulatortest dieses Auftrags. Die redaktionelle Entscheidung ist keine unabhängige menschliche Sprachfreigabe. Bekannte sonstige Altglossen/POS-Befunde außerhalb dieser Gruppierung bleiben eigene Aufgaben. Auf macOS/iPhone kann nach Übertragung des internen Assets lokal geprüft werden.
