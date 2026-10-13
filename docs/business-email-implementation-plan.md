# Business & E-Mail: Inhalts- und Umsetzungsplan

Stand: 13.10.2026. **Paket A+B durch den Ausführungsauftrag genehmigt und umgesetzt; Paket C weiterhin außerhalb.** Ergebnis: 579 vorbereitete Ziele einschließlich 43 E-Mail-Zielen; Batches 97/97/97/96/96/96. Normale Grenze 1500, gemischte Batchgrenze 100. Erste nutzbare Übergabe: [verifizierte Batch-1-ZIP v2 und vollständiger Bericht](business-email-authoring.md), Partition 0/97/482. Produktiv bleiben 13 Stapel und 3075 Übungen /2804 Wörter unverändert. Keine Satzimporte, kein Staging, keine öffentliche Inhaltsfreigabe.

Die folgenden Plan- und ursprünglichen Prüfabschnitte dokumentieren die beschlossene Ausgangslage und historische Messungen. Ihre Mengen waren Richtwerte, keine Mindestmengen. Der ursprüngliche Abschnitt 9 zur Planabnahme ist durch diesen Auftrag erfüllt. 857 konkrete Kandidaten wurden vollständig behandelt: 579 angenommen, 278 ausgeschlossen; 113 mit Strukturtreffern, weitere 165 aus einzelnen redaktionellen Entscheidungen. Der Umfang liegt bewusst unter 1500/70: vorhandene Bedeutungen, Registervarianten, freie Verbindungen, isolierte Anreden und unnötige Fachbegriffe wurden nicht aufgefüllt. Alle elf Themen bleiben abgedeckt.

Abweichung im Wiederanlauf: Der erste noch unveröffentlichte v1-Export wurde nach einem unzutreffenden Ausschlussverweis und drei verbliebenen Prüfformulierungen durch eindeutige neue v2-Dateien ergänzt. v1 unverändert erhalten, nur v2 hochladen. Anzahl, IDs, Originalpositionen und Batches identisch; keine historische Lieferung oder Produktionsdatei umgehasht. Aktuelle Pfade: `pipeline/data/selection/business_email_v2.json`, `pipeline/data/selection/business_email_batch_1_context_v2.json`, `pipeline/data/words/en.business_email_batch_1_context_v2.json`, `pipeline/data/learning_groups/en.business_email_batch_1_context_v2.json`. Die ursprünglich vorgesehenen v1-Dateien bleiben ausschließlich Nachweis des unveröffentlichten Zwischenstands.

## 1. Ausgangsstand und verbindlicher Umfang

Die [Roadmap](content-roadmap-v1.md) bleibt maßgeblich. Die 13 vorhandenen Ansichten sind Allgemeine Sprache (160 Übungen), Reisen (489), Alltag & Zuhause (241), Arbeit & Bildung (245), Menschen & Beziehungen (245), Körper & Gesundheit (249), Essen & Trinken (250), Natur & Umwelt (242), drei Verbenansichten (je 134), Alltagssprache & Redewendungen (441) und Verbalphrasen (181). Business & E-Mail wird die vierzehnte und letzte Ansicht; keine weitere Kategorie, keine sichtbaren Themen- oder Batchstapel.

Am tatsächlichen Bestand erneut geprüft: `pipeline/out/verbalphrasen_batch_2_v1/pack.json`, Quell-SQLite sowie `assets/content/en/content.sqlite` und Manifest. Schema **4**, **13 Stapel**, **3189 Karten**, **2978 aktive Wortbesitzer**, **2979 Registryeinträge** einschließlich einer obsoleten, unverändert erhaltenen Reservierung. Die tatsächliche App-Projektion ergibt **3075 Übungen / 2804 lexikalische Wörter**; rohe Übungsmitgliedschaften 3156 sind ebenfalls keine Karten- oder Wortzahl. Die SQL-Tabelle `exercises` enthält 0 Zeilen und beschreibt andere Inhaltsübungen. Ihre Zeilenzahl ist nicht die Zahl der Satzübungen. Keine Addition der lexikalischen Zahlen einzelner Formansichten zum globalen Wortbestand.

Vier erhaltene Formtabellen: `lexical_targets` 134, `card_lexical_targets` 406, `form_targets` 402, `deck_practice_targets` 402. Die drei Verbenansichten bleiben bei 134 Übungen. Der spätere Zuwachs wird aus der wirklichen Auswahl und produktiven Projektion ermittelt; 1500 ist keine Zusage von 1500 neuen Einzelwörtern. Begleitwort-Senses, Schreibvarianten und Satzalternativen zählen nicht als zusätzliche Ziele.

**Aktuelle Registryquelle:** `pack.word_registry.snapshot`, kanonischer Digest `bf311a26def8442871fbafa688b230af0456a9d462cf8c843997785e537b3ff8`. Exakt identisch mit `pipeline/data/words/en.verbalphrasen_batch_2_context_v1.json`, im neuen Audit bestätigt. **Aktuelle Gruppenquelle:** sämtliche `cards.learning` des finalen Packs, 3189 Entscheidungen / 3177 Gruppen; IDs aus `build_rows`. Die vorhandene `pipeline/data/learning_groups/en.verbalphrasen_batch_2_context_v1.json` ist lediglich der historische Kontext mit 3099 bestehenden und 90 damals reservierten Karten. Sie ist keine aktuelle vollständige Gruppenregistry und darf nicht als solche kopiert werden.

Technische interne Abnahme und öffentliche Sprach-/Inhaltsfreigabe bleiben getrennt. Altglossen, 476 bestehende Linterhinweise (darunter unfairly), beide offenen Auswahlglossenlabels und ältere Vergleichslisten aus dem [letzten Importbericht](verbalphrasen-batch-2-import.md) werden nicht nebenbei korrigiert. Keine Aussage über eine Geräteabnahme oder echte Lernstände.

## 2. Themen und redaktionelle Grenzen

Allgemeiner Berufsalltag hat Vorrang: Verständigung im Team, Termine, Aufgaben, Bewerbungen, Kundenanliegen und einfache betriebliche Abläufe. Verständlich für Erwachsene ohne Management-, Rechts- oder Finanzwissen. Keine seltenen Branchenbegriffe, Finanzprodukte, Juristensprache, Akronymlisten oder künstlich verlängerten Phrasen zur Mengenerfüllung. Nützlicher Mix aus Einzelwörtern, festen Wendungen und vollständigen Formeln; keine starre Typquote.

Die folgenden **elf Themen sind Planbereiche, keine Kandidatenlisten**. Die obere Spalte ist der rechnerische 1500er-Plan; die Spanne zeigt vorläufigen Spielraum durch Dubletten. Auch ihre Untergrenze ist keine Mindestlieferung. Abweichungen werden begründet; keine Auffüllpflicht.

| Hauptthema | Vorläufiger Bereich | 1500er-Plan | Praktischer Schwerpunkt und Abgrenzung |
|---|---:|---:|---|
| Zusammenarbeit und Aufgabenverteilung | 160–180 | 180 | Verantwortung, Unterstützung, Rückmeldungen, Übergaben; keine Wiederholung allgemeiner Beziehungsziele. |
| Berufliche Kommunikation | 160–180 | 180 | Anliegen klären, verständlich erklären, nachfragen, sachlich widersprechen; allgemeine Höflichkeitsziele bleiben im Altbestand. |
| Termine und Besprechungen | 140–160 | 160 | Verfügbarkeit, Abstimmung, Teilnahme, Ergebnisse; Grundwörter wie meeting/deadline nicht neu anbieten. |
| Projekte und Arbeitsabläufe | 150–170 | 170 | Aufgabenstand, Prioritäten, Qualität und Änderungen; keine spezielle Projektmanagementmethode. |
| Personal, Bewerbung und Arbeitsbedingungen | 120–140 | 140 | Bewerbung, Einstieg, Arbeitszeiten, Urlaub und Entwicklung; Arbeit & Bildung besonders prüfen. |
| Kundenservice und Problemlösung | 120–140 | 140 | Anliegen verstehen, Fehler klären, Lösungen vereinbaren; kein zweiter Satz allgemeiner Problemlöseformeln. |
| Vertrieb, Einkauf und Bestellungen | 110–130 | 130 | Angebote, Mengen, Lieferungen und Rückfragen aus Käufer-/Verkäufersicht; keine seltenen Handelsinstrumente. |
| Geld, Rechnungen und Zahlungen | 100–120 | 120 | Rechnungsangaben, Fälligkeit, Erstattung und Zahlung; keine Finanzanlage- oder Buchhaltungsspezialisierung. |
| Verträge und Organisation | 90–110 | 110 | Verständliche Vereinbarungen, Zuständigkeiten, Unterlagen und betriebliche Regeln; keine Rechtsberatung. |
| IT und digitale Zusammenarbeit | 80–100 | 100 | Dateien, Zugänge, Besprechungstechnik und alltägliche Störungen; keine Programmier-/Netzwerkfachsprache. |
| E-Mail-Verkehr | 60–70 | 70 | Betreff/Bezug, Anhänge, Bitte, Bestätigung, Rückfrage, Nachfassen und Abschluss; kurze, idiomatische Ausdrücke. |
| **Gesamt** | **1290–1500** | **1500** | **1430 übrige + 70 E-Mail; E-Mail ist enthalten.** |

Jedes Ziel hat genau **eine Hauptzuordnung** im vorhandenen `topic`. Zusätzliche Kontrast-/Verwandtschaftstags in `learning.related` dürfen sich überschneiden, erhöhen aber keine Themenzahl. Ein E-Mail-Ausdruck zu einer Rechnung wird entweder unter E-Mail oder Zahlungen gezählt, niemals unter beiden. Allgemein verwendbare Rechnungsvokabeln zählen nicht zusätzlich zu den 70 E-Mail-Zielen, nur weil ihr Satz eine E-Mail erwähnt. Vor Freeze die tatsächlichen Themen-/Typzahlen und alle Abweichungen ausgeben.

## 3. Verbindlicher globaler Dublettenabgleich

Nicht nur Arbeit & Bildung, Alltagssprache und Verbalphrasen prüfen, sondern **alle 13 Ansichten, historische Karten/Links, das vollständige Wörterbuch, alle globalen Reservierungen und die komplette neue Vorauswahl**. Folgende Reihenfolge ist verbindlich; Ausschlussprotokoll je verworfenem Kandidaten mit konkretem Treffer, Karten-/Sense-/Satzreferenz oder Registryindex und inhaltlichem Grund:

1. Exakte vollständige Form mittels `ids.form_norm`: NFC, Kleinschreibung, typografischer Apostroph → gerader Apostroph. Keine zusätzliche Lemmatisierung, Akzent- oder Bindestrichentfernung. Führende/nachgestellte Leerzeichen sind unzulässig. Gegen alle vorhandenen Kartenformen und die vollständige neue Auswahl prüfen.
2. Lemma, POS, Sense, Definition und tatsächlichen festen Satz vergleichen. Bestehende gelehrte Bedeutung nicht mit neuer Phrase/Formvariante wiederholen. Ein vorhandener Wörterbuchsense **ohne Lernkarte** kann nach bestehendem Vertrag mit unveränderter Identität/Definition wiederverwendet werden. Neue Bedeutung nur explizit begründen, nicht zum Umgehen eines Treffers konstruieren. Gleiche deutsche Übersetzung allein beweist keine Synonymie.
3. Wortbesitz über `word_registry.index_registry/validate_selection` prüfen: Sprache und gesamte normalisierte Form haben einen Besitzer. Auch eine andere Bedeutung der bereits besessenen Oberfläche ist im normalen neuen Business-Stapel ausgeschlossen. Historische Zusatzsenses beim gleichen Besitzer sind keine Erlaubnis für einen zweiten Business-Primärplatz. Besitzer/IDs/Lernstände nicht verschieben, zusammenlegen oder neu berechnen.
4. Besitzaliase und Schreib-/Regionalvarianten gegen alle Registryeinträge prüfen; Aliasziel und Primärziel dürfen nicht konkurrieren. Neue vollständige Phrase darf bekannte Einzelbestandteile enthalten, wenn ihre eigene Lernabsicht eigenständig ist. Kein zusätzlicher Besitz ihrer Bestandteile und kein beliebiges Verb-plus-Objekt als Mengenfüller.
5. Bestehende und geplante Lerngruppen, Hauptkarten, `related` sowie vollständige Form-/Lexikalbindungen prüfen. Keine neue Singleton-Gruppe für eine bereits entschiedene gleichbedeutende Variante. Gleiche Oberfläche in verschiedenen Formfunktionen bleibt ausschließlich der bestehende Formvertrag; Business ist normaler V2-Inhalt, keine neue Formausnahme.
6. Alle bestätigten `card_sentences.valid_alternatives` prüfen, **einschließlich historischer retirierter Links**, wie es `validate_context` tut. Zusätzlich geplante `ownership_aliases` und `synonym_candidates_not_separate_targets` gegen Gesamtziele/Bestand/Alternativen abgleichen. Kandidaten sind keine Antwortfreigabe. Später jede neue Alternative nochmals gegen alle noch offenen Gesamtziele prüfen.

Automatische Treffer sind strukturelle Sperren oder Reviewhinweise; Bedeutungsentscheidungen bleiben explizite Redaktion. `validate_context` prüft unter anderem `already offered word`, `sense already taught`, `alias/synonym target conflict`, `old ownership changed` und `new independent head`. Ein fachlicher Wunsch hebt diese Prüfungen nicht auf.

Wenige **reale Bestandsbeispiele**, keine Business-Auswahl; nachgelesen im aktuellen Pack und in `build/business_email_plan_checks/read-only-audit.json`:

| Bestand / Referenz | Befund und Konsequenz |
|---|---|
| `meeting\|meeting/NOUN\|meeting#besprechung`, Allgemeine Sprache, Satz `source/everyday/s94` | Beruflicher Nutzen macht die bereits gelehrte Besprechung nicht zu einem neuen Ziel. |
| `deadline\|deadline/NOUN\|deadline#abgabefrist`, Arbeit & Bildung, `arbeit-bildung-v1-106-s1` | Nicht unter Termine oder Projekte erneut reservieren. |
| `to sum up\|to sum up/ADV\|to-sum-up#zusammenfassend`, Alltagssprache, `alltagssprache-v1-0327-s1` | Besprechungszusammenfassung ist kein zweiter eigener Ausdruck. |
| `get back to\|get back to/VERB\|get-back-to#sich-zuruckmelden-bei`, Verbalphrasen, `verbalphrasen-v1-0106-s1` | Beruflicher Kontext ändert die bestehende Lernabsicht nicht. |
| `schedule\|schedule/NOUN\|schedule#fahrplan`, Reisen, `reisen-v1-080-s1` | Andere gewünschte Bedeutung erlaubt keinen neuen Besitzer der Oberfläche schedule. |
| Alias `airplane` → Besitzerform `aeroplane` in `word_aliases` | Schreib-/Regionalvariante bleibt eine Besitzidentität, kein neues Business-Reiseziel. |
| `in my opinion` an `to my mind\|to my mind/ADV\|to-my-mind#nach-meinem-dafurhalten`, `alltagssprache-v1-0020-s1` | Bestätigte Alternative und obsolete Reservierung bleiben erhalten; kein neues Lernziel. |
| `carry out` an `do\|do/VERB\|do#tun`, `source/pilot/pilot_60_v1/s478`, Link `removed_in: single_sentence_v1` | Auch historischer Alternativtreffer sperrt die normale Auswahl. |
| `cut\|cut/VERB\|cut#schneidet`, `irregular:cut:past`, `irregular:cut:past_participle` | Bestehende funktionsgetrennte Übungen erhalten; nicht als drei neue Wörter oder Business-Ausnahme behandeln. |

## 4. Satz-, Mehrwort- und E-Mail-Vertrag

Genau ein natürlicher fester englischer Übungssatz pro primärem Ziel, idiomatische bedeutungstreue deutsche Übersetzung. Keine Ersatzsätze im Auswahlauftrag. `accepted` bleibt exakt `[card.form]`; `valid_alternatives` werden einzeln wörtlich in die Lücke eingesetzt, als vollständiger Satz geprüft, gehasht und bleiben lernstandsneutral. Weder Besitzalias noch Gruppenmitgliedschaft gibt automatisch eine Antwort frei.

Mehrwortziele sind vollständige Ausdrücke mit einer zusammenhängenden Zeichenspanne. Keine getrennten Lücken, kein variables Zwischenobjekt, keine Platzhalter und keine willkürlichen Ausschnitte. `annotate.tokenize(..., lexical_spans=[...])` vereinigt die komplette Ziellücke als ein Token; die Spanne muss ganze Tokens umfassen. Sämtliche übrigen Wort- und Satzzeichenpositionen, Wörterbuchglossen, Bedeutungsbindungen und Reviewhashes bleiben vollständig erforderlich. Grammatik/Register/Objektstellung/Bedeutungsgrenzen stehen im bestehenden `review.reason`, keine neue Importschnittstelle.

**Vollständige Formeln:** Der gegenwärtige Vertrag erlaubt auch eine Lücke über den ganzen lexikalischen Satzinhalt; Satzschlusszeichen kann außerhalb bleiben. Tatsächlich vorhanden: `nothing ventured, nothing gained|nothing ventured, nothing gained/INTJ|nothing-ventured-nothing-gained#wer-nicht-wagt-der-nicht-gewinnt`, Satz `alltagssprache-v1-0261-s1`, „Nothing ventured, nothing gained!“; aktueller Linterlauf ohne Befunde. Das ist ein Bestandsbeleg, keine neue Satzlieferung oder generelle Freigabe jeder Grußformel.

`lint_sentence` in `pipeline/src/sprachpipe/linter.py:32` prüft Zielform/Offsets, Wiederholung, Länge, Nebensätze, Satzschluss und Frequenzhinweise. Aktuell `pipeline/config.yaml:13–14`: **maximal 14 Wörter / ein Nebensatz**, Satzende `.`, `?` oder `!`. Er prüft **keine grammatische Vollständigkeit und kein Mindestmaß an Kontext**. Die Wortgrenze zählt Leerraumwörter des Satzes, nicht die zusammengeführten lexikalischen Tokens. Die 20-Wörter-Sonderregel für explizite Story-Lernkontexte im Importer ist keine E-Mail-Ausnahme.

Daher redaktionell verbindlich: kurze konventionelle vollständige Äußerungen oder natürlich in einen vollständigen Satz eingebettete Ausdrücke. Keine isolierte Anrede/Signatur durch bloßes Anhängen eines Punktes zulassen; keine künstliche Zitierkonstruktion nur zum Bestehen des Linters. Wenn ein sinnvoller Ausdruck keinen natürlichen festen Satz mit zusammenhängender Zielstelle trägt, zurückstellen und unter dem Mengenrichtwert bleiben. Fast identische Höflichkeits-, Personalpronomen- oder Tempusvarianten derselben Absicht nicht zu mehreren Zielen aufblasen. Geeignete vollständige Formeln benötigen keine Linter-/Appänderung.

Redaktion ausschließlich anhand tatsächlich geprüfter Authoring-ZIPs im Chat; keine automatische Modellgenerierung. Die frühen Drei-Satz-Angaben in `docs/content-schema.md:83` betreffen den Altvertrag; die nachfolgende Schema-2-Regel ab Zeile 95 und der aktuelle V2-/Schema-4-Weg verlangen einen aktiven Satz. Keine Rückkehr zu drei Sätzen oder öffentlicher Freigabe durch Techniktests.

## 5. Technische Entscheidung und geprüfte Quellstellen

**Empfehlung: einen normalen Gesamtkatalog bis 1500 Ziele erlauben, Einzelbatches weiterhin höchstens 100 und thematisch gemischt.** Die Grenze ist eine explizite, getestete Authoring-Vertrags-/Schutzregel, keine SQLite-, App-, Schema-4- oder V2-Speichergrenze. Sie darf nur durch die hier geplante kleine Vertragsänderung samt Grenztests angehoben werden. Kein `--force`, kein V3-Umweg, keine Deaktivierung von Prüfungen.

| Vorhandene Stelle | Tatsächliches Verhalten und Folgerung |
|---|---|
| `pipeline/src/sprachpipe/authoring_context.py:22`, `validate_context`, Zeile 53 | `0 < len(entries) <= 450`; Fehlermeldung `authoring: normal authoring selection size must be 1..450`. Genau hier auf 1500 erhöhen und Fehlermeldung anpassen. |
| Dieselbe Funktion, Zeile 151 | Alle Batches `len(t) <= 100` und `len(set(t)) > 1`; Fehler `authoring: unmixed/oversize batch`. Unverändert lassen. |
| `authoring_context.py:221`, `prepare_continuation` | Nimmt unveränderliche Initialauswahl, tatsächliches Basis-Pack und ursprünglichen Gruppensnapshot; bindet neue Source-/Registry-/Gruppenhashes, alle ursprünglichen Identitäten und bereits importierten Satzbindungen. Ruft denselben Validator auf. |
| `pipeline/scripts/export_authoring_context.py:40`, `export` | Initial nur Batch 1 und `new_deck`; später nur passender Fortsetzungssnapshot mit `existing_deck`. Quelle muss dem gestagten Manifest/Asset entsprechen. Enthält gesamte Auswahl, sämtliche Reservierungen/Gruppen, Wörterbuch, Pack, SQLite, Quell-/Modellkontext. Nur aktuelle `entries` sind Satzaufträge. |
| Exporter Zeilen 179–251, `verify_zip` | Geschlossene ZIP erneut öffnen; CRCs, Hashmanifest, Referenzen, Quellstand, Schema, gesamte Auswahl, Partition, alle 22 Tabellen via `check_sqlite`. `--historical` dient Archivprüfung, niemals neuer Übergabe auf fremder Basis. |
| Exporter `main`, Zeilen 415–455 | Normaler `--prepare-continuation VERSION` liest **gestagtes** Manifest. `--source-pack`/`--source-sqlite` sind ausdrücklich Optionen des Formwegs, kein alternativer normaler Business-Aufruf. |
| `pipeline/scripts/import_editorial_patch.py:508`, `create_content` | Normal V2 auf Schema 2/3/4, `copy.deepcopy(source)` und additive Tabellen; keine 450er-Auswahl- oder 100er-Auftragsgrenze hier. Der Gesamtauswahlvertrag muss vor Import extra gegen Lieferumfang geprüft werden. CLI-Hilfetext „schema-2/3“ ist veraltet, kein echter Schema-4-Blocker. |
| Importer Zeilen 633/661, `export_offline` / `main` | Vorhandener Output wird abgelehnt: `output directory already exists`; Create-CLI gibt Exit 2 bei abgefangener Ablehnung. Hashfehler: `create source hash mismatch`, `create registry hash mismatch`; neue Version und Review-/Token-/Linkbindung verpflichtend. |
| `pipeline/data/curation/editorial_content_v2.schema.json` | Formatversion 2, normale additive Tabellen, eine akzeptierte Zielform, Lernmetadaten Schema 3/4. Keine 450er-/100er-Kataloggrenze im JSON-Schema. Für die Erhöhung **keine Schemaänderung** nötig. |
| `pipeline/src/sprachpipe/deck_display.py:18`, `apply_deck_display_patch` | Bestehender Displayvertrag bindet Source-/Create-Rohhash, Registry-Digest und vollständige Vorherhashes von `deck_cards`/`deck_words`. Nur Anzeige dieses Stapels ändern. |
| `pipeline/scripts/finalize_curation.py:165`, `check_sqlite` | Read-only, Tabellen- und Spaltenmenge sowie sämtliche Werte gegen `build_rows`; exportgeneriertes `created_at` aus Wertvergleich ausgenommen. Bestehenden Abgleich beibehalten. |

**Vergleich:** Eine additive Erhöhung braucht im Kern eine Validatoränderung, gezielte Erweiterung der bestehenden Testdatei und aktuelle Vertragsdokumentation. Mehrere versionierte Teil-Auswahlen unter einem Besitzer wären als eigener Vertrag möglich, sind aber heute kein gleichwertiger Standardweg: Initialexport deklariert einen neuen Stapel, Fortsetzung verlangt dieselbe komplette Initialauswahl und bestehende importierte Präfixbatches; neue Reservierungen dürfen in einer Fortsetzung nicht angehängt werden. Mehrere Auswahlen bräuchten zusätzliche Gesamtplanung, Positions-/Besitzregeln und neue Regressionen. Daher verwerfen wir diesen aufwendigeren Weg für v1. Versionen für echte Auswahlkorrekturen bleiben erlaubt; sie sind keine Mengenaufteilung.

**Skalierbarkeit und vollständiger Kontext:** Keine Quelle oder globale Reservierung aus Größenmotiven abschneiden. Der bestehende normale Exporter hält das ZIP-Payload im Speicher, erstellt die ZIP exklusiv mit Modus `x` und verifiziert erst beim separaten `--verify-zip`; keine atomare Veröffentlichung wie im besonderen Formexport behaupten. Die vorhandene Verbalphrasen-Batch-2-ZIP misst 24 549 514 komprimierte / 68 631 459 unkomprimierte Bytes bei 84 Einträgen. Das ist nur ein realer Größenanker, **keine Messung eines 1500er-Business-Kontexts**. Packwachstum, mehrfache Gesamtauswahldarstellung, alle Batchmappings und eingefrorene Sätze vergrößern Folgekontexte. Paket A muss die 1500er-Größe synthetisch messen; Paket B und jeder Folgeexport messen reale Größe und Verifikationszeit. Keine unbelegte Uploadgrenze oder feste Größenprognose erfinden. Bei tatsächlichem Ressourcen-/Uploadblocker Befund melden, keine Kontexte weglassen.

Wiederholbarkeit bedeutet gleiche Identitäten, Partitionen, Quellen und Nutzdaten bei gleichen Eingaben. ZIP-Zeitstempel und SQLite-Releasezeit können neue Rohhashes verursachen; daher veröffentlichte Dateien unverändert wiederverwenden und ihre tatsächlichen Hashes dokumentieren, keine byteidentische Neuerzeugung versprechen.

## 6. Auswahl, Batches, Positionen und Fortsetzung

Zuerst vollständige globale Prüfung und reservierte **Gesamtauswahl**. Bei tatsächlich 1500 Zielen **15 gemischte Batches à 100**; sonst `ceil(N/100)` möglichst ausgewogene Gruppen. Kein winziger homogener Restbatch; Themen/ähnliche Bedeutungen/Grundverben über Batches und Originalreihenfolge verteilen. E-Mail-Ziele in diese Batches mischen, keinen separaten E-Mail-Batchstapel erzeugen. Alle globalen Reservierungen im ersten Kontext festhalten, auch noch nicht importierte; Folgekontexte enthalten sie weiterhin unverändert.

Vier verschiedene Reihenfolgen:

- `authoring_batch` bestimmt nur die jeweils zu redigierenden höchstens 100 Ziele.
- `selection_id`, `position == editorial_position`, Karten-/Sense-IDs und Registrypositionen bleiben nach Freeze stabil; ausgeschlossene Positionen nicht wiederverwenden.
- Packanzeigen sind lückenlose Positionen 1..importierter Umfang. Erster Batch nach `combined_display_mapping.json`; später aktuelle Ziele anhängen und über `continuation_display_mapping.json` plus hashgebundenen Display-Patch die gemeinsame Reihenfolge kompakt abbilden. Keine Änderung von Originalidentitäten oder fremden Stapeln.
- Tatsächliche Sessions nutzen unverändert `lib/domain/new_card_selection.dart:43`, `selectNewCards`, Lerngruppen und Formauflösung. Themen-/Kontrastabstand 3→2→1→0 bei Knappheit, unterschiedliche Gruppe/Oberfläche/Lemma und bestehende Inhalts-/Funktionsquote; eingefrorene Session, Reviews und SRS bleiben unverändert. POS nicht zum Erzwingen einer Quote fälschen. Batchmix garantiert nicht die Laufzeitfolge; **keine Appänderung für Redaktion**.

Nach jedem real geprüften und intern gestagten Import die nächste Fortsetzung aus genau diesem Pack erzeugen. `prepare_continuation` prüft die importierte Präfixpartition und festen Sätze; keine halb importierten Batches oder Batchsprünge als gültige Fortsetzung behandeln. Wenn ein früherer Begleitsense eine spätere vorgeschlagene Bedeutung bereits bereitstellt, exakte Identität wiederverwenden; abweichende gleichbedeutende Definitionsformulierung nur über vorhandene hashgebundene `--definition-equivalences` mit `same_meaning` und Begründung, niemals eine tatsächliche Bedeutungsabweichung wegdeklarieren.

Nachträglicher Zielkonflikt: vorhandenen versionierten Korrekturweg aus [Alltagssprache-Auswahl v2](alltagssprache-redewendungen-selection-v2.md) nutzen. Nur noch nicht importiertes Konfliktziel in einer neuen Gesamtauswahlversion begründet ausschließen; Vorgängerpfad/hash, konkrete Identität, Originalposition/Batch und erhaltenen Treffer dokumentieren. Alle übrigen Eintragsidentitäten und Positionen erhalten. Historische Auswahl-/Registrydateien nie überschreiben; obsolete Reservierung bleibt nachvollziehbar, aber kein offener Satzauftrag. Neue Kontextversion auf echter Basis erzeugen und vollständig prüfen. Konflikt mit bereits importiertem Ziel ist **kein** Fall für stilles Löschen/Mergen: Befund stoppen und separat beschließen. Kein Ersatz zum Auffüllen.

## 7. Drei ausführbare Umsetzungspakete

Alle unten genannten neuen Business-Pfade sind **geplante Ablagen, jetzt nicht erzeugt**. Vor Ausführung aktuellen Stand/Hashschutz und GitNexus-Impact erneut prüfen. Dieser Plan erlaubt noch keine Produktionsänderung.

### Paket A: normale Authoring-Kompatibilität bis 1500

**Erlaubte Änderungen:**

- `pipeline/src/sprachpipe/authoring_context.py`: ausschließlich Obergrenze und zugehörige Meldung in `validate_context`; keine Änderung der Batch-, Hash-, Bedeutungs-, Gruppen-, Besitzer- oder Fortsetzungsprüfungen.
- `pipeline/tests/test_normal_schema4_authoring.py`: vorhandene Fixtures `normal_context/form_base`, Grenztest `test_normal_catalogue_boundaries_use_real_metadata_validator`, ZIP-Test `test_450_goal_normal_zip_carries_22_tables_and_only_90_current_tasks` und CLI-Fortsetzungstest gezielt erweitern/parametrisieren. Bestehende 450er-Abdeckung behalten, 451 künftig positiv, 1500 positiv, 1501 negativ, 100 positiv/101 negativ; keine parallele neue Testsammlung.
- `docs/normal-authoring-schema4-compatibility.md`: datierte additive Vertragsergänzung zur neuen Grenze und tatsächlicher Testnachweis; historische Ergebnisse unverändert lassen. Dieser Plan/NEXTSTEPS nur auf tatsächliche Ergebnisse fortschreiben.

Importer, Exporter, V2-Schema, Display-Patch, App, Formdaten und Produktionsdateien benötigen nach heutigem Befund keine Änderung. Wenn die Tests eine weitere konkrete Ursache zeigen, Befund und kleinste zusätzliche Änderungsfläche zuerst dokumentieren, keine vorsorgliche neue Pipeline.

**Abnahme:** synthetische nichtleere Formbasis; 1500 vollständige Metadaten mit allen globalen Reservierungen; geschlossene ZIP tatsächlich wieder öffnen (22 Tabellen, 100 aktuell/1400 später); kleiner echter V2-Fixtureimport, danach reale normale CLI-Fortsetzung auf synthetisch gestagter Basis mit vielen zukünftigen Zielen. Vorhandene 2/2/2-Fortsetzung bleibt Regression, Großkatalog muss ebenfalls durch `prepare_continuation/verify_zip` laufen. Vollständige alte Werte und vier Formtabellen erhalten. Negativfälle Quellenhash, Registrybesitz, Alias-/Alternativtreffer, Gruppenreferenz, falsches Schema, Teilpartition und bestehende Ausgabe weiterhin abweisen. ZIP-Größe und Laufzeit messen. Keine echten Business-Sätze oder Produktionsreservierungen im Technikteil.

Bei der Fixture-Erweiterung `normal_context` ungerade Größen ausgewogen verteilen: Ein naives 451/90 erzeugt einen Ein-Ziel-Restbatch und scheitert zu Recht an der Themenmischung. Der positive 451er-Test muss einen gültigen gemischten Katalog verwenden; die 100er-Grenze nicht lockern. Kleine Import-Fixtures dürfen wenige aktuelle Ziele, aber den vollständigen großen Zukunftskatalog enthalten.

Passende Befehle für die künftige Ausführung, **hier nicht als ausgeführt behauptet**:

```text
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_normal_schema4_authoring.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_editorial_import.py -q
```

Nur bei zusätzlichem konkretem Befund weitere betroffene Tests. Keine Flutter-Suite für die reine Python-Grenzänderung. Technische Abnahme ist das interne Gate vor Paket B.

### Paket B: gesamte Auswahl, Reservierungen und erste geprüfte ZIP

**Neue Dateien:**

- `pipeline/data/selection/business_email_v1.json`: unveränderliche vollständige Auswahl mit begründeten Ausschlüssen, bestehenden Eintragsfeldern und IDs.
- `pipeline/data/selection/business_email_batch_1_context_v1.json`: gleicher Gesamtbestand, gebunden an die tatsächliche aktuelle Quelle.
- `pipeline/data/words/en.business_email_batch_1_context_v1.json`: exakter bestehender Registrypräfix plus ausschließlich neue Vollformen; vollständige globale Reservierungen.
- `pipeline/data/learning_groups/en.business_email_batch_1_context_v1.json`: vollständige Altgruppen aus aktuellem Pack mit tatsächlichen IDs plus geplante neue Köpfe, keine Kopie des historischen 3099er-Kontexts.
- `docs/business-email-authoring.md`: Einzelnachweise, Themen-/Typ-/Sensezahlen, Ausschlüsse, Batchverteilung, Quellen und reale ZIP-Prüfung.
- `build/business_email_authoring_checks/` und ausschließlich `build/business_email_authoring_batch_1.zip`.

`docs/content-roadmap-v1.md` und `NEXTSTEPS.md` dann nur auf **vorbereitet**, nicht importiert, aktualisieren. Keine Änderung von App-Assets, Basis-Pack, bestehenden Auswahlen, Registrydateien oder Instruktionsdateien.

**Schnittstellen:** `ids.form_norm/stable_id`, `word_registry.index_registry/validate_selection`, `selection.partition_selection`, `learning_groups.validate_learning`, `pack.build_rows`, `authoring_context.validate_context`; tatsächlicher normaler Export/Verifier. Neue Metadaten mit vorhandenen Strukturen aufbauen, kein generierender Pipelinepfad.

**Abnahme:** jede geplante Identität samt Definition, Gruppe/Besitzer und Ausschluss einzeln geprüft; Istzahlen stimmen rechnerisch; stabile Originalpositionen; global konfliktfrei nach bestehendem Vertrag; bei N=1500 Partition 0/100/1400, sonst wirkliche Zahlen. Alle 22 Basistabellen und Formzeilen unverändert. Erste ZIP geschlossen, CRCs, alle Hashes und vollständiger Kontext erfolgreich geprüft; Quellen-/Assethashschutz erneut bestanden. Metadatenreservierung erzeugt noch keine neue produktive Lernkarte. Noch keine zweite ZIP und keine Sätze.

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_batch_1_context_v1.json --batch 1 --out build/business_email_authoring_batch_1.zip
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --verify-zip build/business_email_authoring_batch_1.zip
pipeline/.venv-macos/bin/python -m pytest pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_normal_schema4_authoring.py pipeline/tests/test_learning_groups.py -q
```

### Paket C: redaktionelle Batchimporte und Abschluss

Wiederholbares Arbeitspaket pro tatsächlich gelieferter Chat-Redaktion: ganze aktuelle Lieferung und jedes Satzpaar/Token prüfen, exakte Deck-/Karten-/Sense-/Gruppenidentitäten mit aktueller Auswahl vergleichen, neue Alternativen gegen die **gesamte** noch offene Auswahl prüfen, dann vorhandener V2-Import. Ohne passende geprüfte Lieferung endet das Paket bei der Authoring-Übergabe. Kein autonomes Erzeugen fehlender Sätze.

**Zulässige neue Ablagen:** originale lokale Lieferung unter ihrem tatsächlichen Pfad erhalten; Prüfbelege `build/business_email_batch_<n>_checks/`; neue Ausgabe `pipeline/out/business_email_batch_<n>_v1/{pack.json,content.sqlite,finalization_report.json}`; `docs/business-email-batch-<n>-import.md`. Nach realem Import/Staging neue Kontextversion `pipeline/data/selection/business_email_batch_<n+1>_context_v1.json`, entsprechende `pipeline/data/words/en.business_email_batch_<n+1>_context_v1.json` und `pipeline/data/learning_groups/en.business_email_batch_<n+1>_context_v1.json`, danach genau eine nächste ZIP. Platzhalter `<n>`/`<n+1>` stehen für reale Batchnummern, keine fertigen hypothetischen Dateien.

**Schnittstellen:** `create_content`, `export_offline`, optional `apply_deck_display_patch`, `build_rows/check_sqlite`, `stageContentPack/verifyStagedPack`, danach `prepare_continuation/export/verify_zip`. Basis beim ersten Import `verbalphrasen_batch_2_v1`, später der tatsächlich abgeschlossene vorige Business-Pack. Alle alten JSON-Werte/SQL-Zeilen erhalten, außer neuer Release-/Registrymetadaten und ausdrücklich gebundener Anzeigepositionen nur des Business-Stapels. Die vier Formtabellen exakt unverändert. Alte Korrekturen, feste Sätze, IDs, Besitzer und Lerngruppen bleiben erhalten.

**Abnahme:** Liefermanifest/CRCs/Hashbindungen, alle aktuellen Ziele und vollständige Tokenannotation/Reviewhashes; neue Hinweise von geerbten trennen; vollständiger 22-Tabellen-Abgleich und Formdatenvergleich; vor Staging bytegleiche Sicherung des aktuellen Assets/Manifests; anschließend Verifier und bestehender echter Leser. Pro Batch alte Identitäten und Vorherhashes nachweisen. Final N/N, Partition N/0/0, Anzeigen 1..N, genau 14 Ansichten; produktive Übungen/Wörter neu messen. Keine Folge-ZIP nach Abschluss. Öffentliche Sprachfreigabe separat.

Befehlsmuster, ausschließlich mit tatsächlichen Pfaden/Hashes aus geprüfter Lieferung ausfüllen:

```text
pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --source <tatsaechliche-basis>/pack.json --create <gepruefte-lieferung>/editorial_content_v2.json --registry <aktueller-registry-kontext> --out <neuer-pack-ordner>
```

Ab Batch 2 zusätzlich vorhandenes `--display-patch <gepruefte-lieferung>/deck_display_patch.json`; keinen ungebundenen Patch erzeugen. Nach Prüfungen/Sicherung und autorisiertem internem Staging:

```text
dart run tool/stage_content_pack.dart --from <neuer-pack-ordner>
dart run tool/stage_content_pack.dart --verify
flutter test --no-pub test/data/real_pack_test.dart
dart run tool/report_learning_groups.dart <neuer-pack-ordner>/content.sqlite
pipeline/.venv-macos/bin/python -m pytest pipeline/tests -q
```

Relevante vorhandene Testdateien bleiben `pipeline/tests/test_editorial_import.py`, `pipeline/tests/test_normal_schema4_authoring.py`, `pipeline/tests/test_authoring_continuation.py` und `test/data/real_pack_test.dart`; keine App-/Testanpassung allein wegen eines zusätzlichen normalen Datenstapels. Die breite Pipeline-Abnahme gilt hier dem späteren realen Import, nicht diesem Dokumentationsschritt.

Normaler Folgebefehl, erst nach realem Import und Staging, mit konkreter nächster Nummer/Version:

```text
pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/business_email_v1.json --batch <naechste-nummer> --prepare-continuation business_email_batch_<naechste-nummer>_context_v1
```

Bei beschlossener Auswahlkorrektur stattdessen die tatsächlich gültige neue Initialauswahlversion angeben. Danach `--selection <neu-erzeugter-kontext> --batch <naechste-nummer> --out <neue-zip>` und gesondert `--verify-zip <neue-zip>`; nie eine Folge-ZIP auf einem nur erwarteten Pack.

## 8. Gegenlesen: Randfälle und Wiederanlauf

| Fall | Verbindliche Behandlung |
|---|---|
| Ziel bereits Karte/Bedeutung/Besitzer | Ausschließen mit konkreter Referenz; kein neuer Sense-Key zur Umgehung, keine Übernahme in Business. |
| Neue Phrase enthält bekannte Wörter | Nur ganze eigenständige Phrase reservieren; vorhandene Wörterbuchbindungen wiederverwenden; Semantik prüfen, keine Bestandteile als neue Ziele zählen. |
| Alias-/Alternativkollision | Vollständiger Scan einschließlich historischer Links und zukünftiger Auswahl. Keine pauschale Antwortfreigabe. Bei erst späterem Treffer versionierter Korrekturweg. |
| Gleiche Oberfläche, andere Formfunktion | Bestehende Formdaten/lexikalische Zählung erhalten; normaler Business-Vertrag gewährt keine weitere Ausnahme. |
| Vollständige E-Mail-Formel / Fragment | Natürliche vollständige Äußerung oder echte Satzeinbettung; Linter ist notwendige, nicht hinreichende Abnahme. Keine Erhöhung von Wortlimit oder getrennte Lücken. |
| Import stoppt vor Export | Basis unverändert; Fehler behandeln, keine Fortsetzung aus ungeprüftem In-Memory-Ergebnis. Vollständige Lieferung erneut validieren. |
| Abbruch während `export_offline` | Ausgabe kann unvollständig sein; `finalization_report.status` ist nur nach erfolgreichem Readback `ok`. Vorhandenen Ordner nie überschreiben oder als importiert zählen. Belege erhalten, neuen freien Ausgabeordner benutzen; gleiche Packversion nur, wenn kein erfolgreicher Pack dieser Version publiziert wurde. |
| Bereits vorhandener erfolgreicher Output | Nicht erneut importieren. Hashes, Report, 22 Tabellen und exakte Batchidentitäten prüfen und vorhandenes Artefakt weiterverwenden; bei Abweichung stoppen. |
| ZIP-Export unterbrochen | Normaler Export ist nicht atomar; unvollständige ZIP bleibt möglicherweise liegen und `x` sperrt Wiederholung. Diagnose erhalten, neuen freien Dateinamen verwenden; ausschließlich geschlossene, erneut geprüfte ZIP weitergeben. |
| Normale Snapshot-Erstellung unterbrochen | CLI schreibt drei Dateien nacheinander, keine transaktionale Veröffentlichung. `snapshot output exists` sperrt Wiederanlauf. Teilstände nicht überschreiben/verwenden; nach Prüfung neue eindeutige Kontextversion mit derselben echten Basis erstellen und alle drei Bindungen/ZIP erneut prüfen. |
| Teil eines Batches fehlt / Batchsprung | Kein erfolgreich abgeschlossener Batch; `existing target partition` muss scheitern. Keine willkürliche Anpassung von `authoring_batch` oder Quellenhash. |
| Quellen-/Manifest-/Registryhash weicht ab | Sofort abbrechen; echte aktuelle Basis erneut prüfen und neuen Kontext erstellen. Gelieferte Reviews/Displaypatch nicht stillschweigend umhashen; erneute gebundene Redaktion/Prüfung nötig. |
| Erneuter Lauf nach erfolgreichem Staging | Vorhandenen Pack und Stand prüfen; nächste Fortsetzung gegen diesen Stand. Kein zweiter Create derselben Identitäten. |
| 1500 sinnvolle neue Ziele nicht erreichbar | Tatsächliche kleinere Menge, Gründe und Themenzahlen dokumentieren; keine ähnlichen Phrasen ergänzen. |

Die zwei wichtigsten Grenzen sind ausdrücklich gegengeprüft: V2-Create allein erzwingt **keinen** Authoring-Batchumfang, und die normale Snapshot-/ZIP-Erstellung ist **nicht atomar**. Der Plan verlangt daher exakte Lieferumfangsprüfung und überprüfte Wiederverwendung/neue freie Ausgabeziele; er setzt keine nicht vorhandene Resume-/Force-Option voraus. Nach 2–3 gleichen Fehlschlägen neue Hypothese, nach fünf stoppen mit konkreter Fehlermeldung und kleinstem nächsten Schritt; keine gelockerten Checks.

## 9. Größter sinnvoller nächster Ausführungsauftrag

Nach gemeinsamer Planabnahme **Paket A und Paket B in einem Auftrag mit internem technischem Gate** umsetzen. Das liefert einen sinnvoll abgeschlossenen, tatsächlich nutzbaren Stand: technische Unterstützung, komplette semantisch geprüfte und reservierte Auswahl, erste geschlossene/verifizierte ZIP. Nicht lediglich eine Zahl ändern und mit einer ungeprüften Vorauswahl enden. Paket C bleibt an die danach im Chat redigierten Lieferungen gebunden.

Vorgeschlagener nächster Prompt:

> Setze Paket A und B aus docs/business-email-implementation-plan.md vollständig um. Erhöhe den normalen Gesamtkatalogvertrag additiv auf höchstens 1500, erhalte die gemischte 100er-Batchgrenze und alle übrigen Prüfungen. Nach bestandener technischer Abnahme erstelle die vollständige Business-&-E-Mail-Auswahl nach dem genehmigten Themenplan, globalem Dublettenabgleich und Mengenrichtwert einschließlich der E-Mail-Teilmenge. Reserviere nur die wirklich akzeptierten Gesamtziele, erhalte bestehende IDs/Besitzer/Gruppen/Formdaten und liefere ausschließlich die erste geschlossene und erfolgreich verifizierte Authoring-ZIP gegen den tatsächlichen gestagten Stand. Keine Sätze, Folge-ZIPs, Produktionsimporte oder Staging. Dokumentiere echte Prüfoutputs, Abweichungen und vollständigen Uploadpfad; NEXTSTEPS höchstens 25 Zeilen.

Keine zusätzliche konkrete Produkt-/Vertragsfrage ist derzeit ungelöst. Zur gemeinsamen Abnahme stehen diese Empfehlungen: 1500er-Gesamtgrenze, elf Hauptthemen, ca. 70 enthaltene E-Mail-Ziele, natürliche vollständige Formeln ohne Fragment-Ausnahme und Pakete A+B als nächster Umfang. Eine tatsächliche geringere Auswahlmenge ist bereits vorgesehen und erfordert keine technische Routine-Rückfrage.

## 10. Tatsächlich ausgeführte Prüfungen dieses Plans

Alle Nachweise neu unter `build/business_email_plan_checks/`. macOS ab Repository-Root; Python unter Windows PowerShell durch `.\pipeline\.venv\Scripts\python.exe` ersetzen. Dart-/Git-Befehle sind gleich. Der lokale Wrapper `run_check.py <logname> <befehl...>` protokolliert exakte Argumente, relevante unveränderte Ausgabe und Exitcode in `*.command.json`/`*.log`; keine Shell-Exitcodes durch nachfolgende Erfolgsbefehle verdeckt.

```text
pipeline/.venv-macos/bin/python build/business_email_plan_checks/baseline.py
baseline_files 2890; HEAD ef228e24bcb67053cf6354df4006761403803daa
Index leer; vorbestehender gemischter Arbeitsbaum erfasst.
Exit 0

dart run tool/stage_content_pack.dart --verify
Erster Lauf: SDK update_engine_version.sh: engine.stamp.tmp / engine.realm: Operation not permitted
Exit 1 (SDK-Cache/Sandbox, kein Inhaltsfehler)
Wiederholung mit lokalem SDK-Cachezugriff:
verified assets/content/en/content.sqlite
  version verbalphrasen_batch_2_v1, schema 4, 20152320 bytes
  sha256 f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6
  22 table counts match finalization_report.json
  INTERNES TEST-PACK: own devices and selected testers only, no public content release
Exit 0

pipeline/.venv-macos/bin/python build/business_email_plan_checks/read_only_audit.py
PASS: build_rows / check_sqlite: all 22 tables, source and asset, all row values; created_at excluded by existing comparator
REGISTRY 2979 bf311a26def8442871fbafa688b230af0456a9d462cf8c843997785e537b3ff8
GROUPS: actual 3189 cards /3177 groups; historical context3099+90
Exit 0

dart run tool/report_learning_groups.dart pipeline/out/verbalphrasen_batch_2_v1/content.sqlite
mixed: raw_words3156, learning_targets3075, lexical_words2804, form_memberships402
13 Ansichten; Verbalphrasen181, Verbenansichten jeweils134.
Exit 0 (kompakter Auszug aus projection.log; projection-summary.json)

pipeline/.venv-macos/bin/python pipeline/scripts/export_authoring_context.py --help
--selection, --out, --batch, --verify-zip, --prepare-continuation VERSION,
--historical, --source-pack, --source-sqlite, --definition-equivalences
--source-pack / --source-sqlite: Form continuation
Exit 0

pipeline/.venv-macos/bin/python pipeline/scripts/import_editorial_patch.py --help
--source, --patch, --corpus, --plan, --out, --single-sentence, --create,
--display-patch, --registry, --legacy, --finish
--create: schema-2/3 offline editorial create input (veralteter Beschreibungstext)
Exit 0

pipeline/.venv-macos/bin/python build/business_email_plan_checks/contract_probe.py
450 goals / batch90: PASS
451 goals / batch90: expected rejection: authoring: normal authoring selection size must be 1..450
1500 goals / batch100: expected rejection: authoring: normal authoring selection size must be 1..450
100 goals / batch100: PASS
101 goals / batch101: expected rejection: authoring: unmixed/oversize batch
EXISTING_FULL_FORMULAS: alltagssprache-v1-0261-s1, findings: []
No production candidates, sentences, exports or reservations created; synthetic metadata in memory only.
Exit 0
```

Der neue read-only Audit ruft exakt die bestehenden `build_rows`/`finalize_curation.check_sqlite` aus dem letzten Bericht auf. Das alte `check_completion.py` wird nicht erneut ausgeführt: Es schreibt historische Nachweise und erwartet den damaligen Vor-Staging-Assetstand. Stattdessen liegen alle neuen Outputs ausschließlich im neuen Prüfverzeichnis. Die gezielte Vertragsprobe verwendet vorhandene synthetische Fixture-Metadaten ausschließlich im Speicher und liest einen bestehenden Satz; kein Export und keine neue Satzgenerierung. Keine volle Pipeline-/Flutter-Suite für diesen Dokumentationsschritt.

Vollständiger tatsächlich geprüfter Tabellenumfang:

```text
languages1 lemmas4287 senses5906 cards3189 dictionary_forms7067 decks13
deck_cards3082 deck_words2978 word_aliases37 sentences3723 sentence_tokens40354
card_sentences3717 stories1 story_sentences6 exercises0 grammar_rules0 audio_assets0
content_releases1 lexical_targets134 card_lexical_targets406 form_targets402 deck_practice_targets402
```

Hashschutz, Rohbytes vor und nach der Planarbeit identisch (Endnachweis `final-check.json`):

| Datei | SHA256 |
|---|---|
| `pipeline/out/verbalphrasen_batch_2_v1/pack.json` | `308171f13f4ee479f80f4dfc5667cde63ece850fb2b813d1825f9b22c4715e56` |
| `pipeline/out/verbalphrasen_batch_2_v1/content.sqlite` | `f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6` |
| `assets/content/en/content.sqlite` | `f1a25d32fb18f4b6640628576b79f2d5577b2b0b2253b15517259f25c6204eb6` |
| `assets/content/en/content.manifest.json` | `748852813e408a2950bbf07bb8e3e79888f6bdeaa33effbd193a861358ea34b3` |

GitNexus vor Quell-/Dokumentarbeit verwendet: Konzeptquery liefert auch historische Kopien und war begrenzt; konkrete Symbole deshalb nach UID aufgelöst. `validate_context` und `lint_sentence` gefunden, `selectNewCards` gefunden. `validate_context`-Impact LOW: ein direkter Caller `prepare_continuation`, ein betroffenes Modul; Zusammenfassung ein Prozesseintrag, Detail zählt zehn zugehörige Prozesshits. Statischer Index vier Commits hinter HEAD; diese Zahlen sind kein vollständiger aktueller Aufrufernachweis. Der neue Plan ist nicht indexiert (UNKNOWN), NEXTSTEPS hat null aufgelöste Caller (UNKNOWN). Literalreferenzen/Dateiumfang ergänzend geprüft. Kein HIGH/CRITICAL-Befund und keine Funktion geändert; vor Paket A Impact erneut ausführen. Rohbelege `gitnexus.json`; kein Reindex, kein Commit, daher keine Commitfreigabe behauptet.

Bekannte repositoryweite Whitespace-Altbefunde bleiben getrennt: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153 und Arbeit-Bildung-Batch-1/-2-Berichte. Nicht erneut global geprüft oder bereinigt. Die folgenden gezielten Endchecks betreffen nur die zwei beauftragten Dokumente und den Bestandsschutz.


Abschließende tatsächlich ausgeführte Dokument-/Bestandschecks (Git plattformgleich):

```text
git diff --check -- docs/business-email-implementation-plan.md NEXTSTEPS.md
Keine Ausgabe; Exit 0

pipeline/.venv-macos/bin/python build/business_email_plan_checks/final_check.py
WHITESPACE PASS NEXTSTEPS.md: 25 Zeilen, CRLF 0
WHITESPACE PASS docs/business-email-implementation-plan.md: CRLF 0
PRESERVATION PASS 2890 files; only NEXTSTEPS.md changed; new plan/checks;
index and HEAD unchanged; protected four hashes unchanged
TOPICS PASS 11 topics;1430+70=1500;range1290..1500;no minimum obligation
Exit 0

git status --short
 M NEXTSTEPS.md
?? alltagssprache_redewendungen_batch_3/
?? alltagssprache_redewendungen_batch_4/
?? alltagssprache_redewendungen_batch_5/
?? docs/alltagssprache-redewendungen-batch-3-import.md
?? docs/alltagssprache-redewendungen-batch-4-import.md
?? docs/business-email-implementation-plan.md
?? docs/codebase-overview-planning.md
?? pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/learning_groups/en.alltagssprache_redewendungen_batch_5_context_v2.json
?? pipeline/data/selection/alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/selection/alltagssprache_redewendungen_batch_5_context_v2.json
?? pipeline/data/words/en.alltagssprache_redewendungen_batch_4_context_v2.json
?? pipeline/data/words/en.alltagssprache_redewendungen_batch_5_context_v2.json
?? verbalphrasen_batch_1/
?? "verbalphrasen_batch_2 2/"
Exit 0
```

Der direkte Whitespacecheck erfasst ausdrücklich auch den unversionierten neuen Plan. Beide bearbeiteten Dokumente haben LF; kein erhaltener CRLF-Fall, daher kein zusätzlicher `core.whitespace=cr-at-eol`-Lauf erforderlich. Der unveränderte Index war zu Beginn leer und ist weiterhin leer; HEAD unverändert `ef228e24bcb67053cf6354df4006761403803daa`. Alle vorbestehenden fremden Dateien und Änderungen bleiben erhalten. Einzige geänderte vorbestehende Datei: NEXTSTEPS.md; hinzu kommen dieser Plan und die angeforderten Prüfbelege. Kein Commit oder Push, keine Umsetzung, keine Business-Auswahl/Sätze/Reservierungen/Exporte, kein Staging und kein user.db-Zugriff.
