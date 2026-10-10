# Plan: ein Lernwort – ein Übungssatz; Stapel und Story-Lernen

Stand 04.10.2026. **Paket A umgesetzt, Abnahme unten; Paket B offen.** Die verbindlichen Reviewkorrekturen sind in diesen Plan eingearbeitet. Abschnitt 2 dokumentiert den gesicherten Ausgangszustand vor Paket A, keine aktuelle Laufzeitbehauptung.

## 1. Beschlossene Regeln, erhaltene Verträge und Empfehlungen

**Neu vom Nutzer beschlossen:** Ein kuratierter Stapel mit 500 Lernwörtern hat 500 zugeordnete Übungssätze, genau einen je Wort; keine Rotation. Ein Wort besitzt genau einen kuratierten Eigentümerstapel. Bedeutungs- oder Schreibvarianten dürfen diese Zuordnung nicht umgehen. Tippen öffnet nur die Übersetzung; erst „Zum Lernen hinzufügen“ speichert. Hinzufügen bedeutet Box 0, keinen Review. Das Wort muss anschließend in Wortliste und Gemischt tatsächlich erreichbar sein, unabhängig von einer Aktivierung des ganzen Stapels. Redaktionelle Chat-Dateien werden vollständiger Offline-Zulieferweg; Gemini ist keine Voraussetzung.

**Erhalten:** Lernzustand gehört einer exakten Form in einer Bedeutung. Bestehende Karten-IDs, SRS-Intervalle, Antwortprüfung, Favoriten, Notizen, Playlist, Deaktivierungen und append-only Reviews bleiben. Zähler werden abgeleitet. Kuratierte Inhalte bleiben im vorhandenen schreibgeschützten content.sqlite, lokale Karten/eigene Kontexte in der vorhandenen user.db. Keine zweite Inhaltsdatenbank oder zweite SRS-Implementierung.

**Konkrete Empfehlungen dieses Plans:** Wortbesitz nach Sprache und normalisierter Form; eine reguläre Primärkarte je Wort, übrige vorhandene Bedeutungskarten als übbarer Altbestand. Redaktionelle Primärwahl nach gelesener Definition und vorhandenen Sätzen, mit versionierter Begründung für alle 53 Doppelgruppen. Schema-2-Inhalt mit kompatiblem Schema-1-Leser; additive user.db-v4-Migration ausschließlich in Paket B. Inhaltsvertrag und Leser sind in A implementiert; die user.db-v4-Migration bleibt ausschließlich B.

**Dokumente in A angeglichen:** PRODUCT, content-schema, pipeline und app-content-integration-plan verwenden jetzt genau einen aktiven Übungssatz; historische Laufabschnitte bleiben als solche erhalten. Die neue Nutzerentscheidung ersetzt diese Regel. PRODUCTs pauschaler Story-Hauptkontext wird präzisiert: bloßes Hinzufügen ersetzt keinen vorhandenen Übungssatz. ARCHITECTUREs „user.db enthält nie Inhaltstexte“ erhält die in user-schema bereits vorgesehenen Ausnahmen für local_only/card_contexts. Historische Laufberichte bleiben historisch; bestehende Dokumentation, tatsächlicher Code und neue Regeln nicht vermischen.

## 2. Gesicherter Ausgangszustand vor Paket A

### Read-only-Auswertung des tatsächlich gestagten Packs

SQLite mit URI `mode=ro` und `PRAGMA query_only=ON` geöffnet und geschlossen. SHA-256 vorher/nachher identisch: `bb71bd0ec9466e931500678b98c6838cf5208f67d82c6cd2cbd6f6fe3fcedf29`.

```text
version=chat_editorial_finish_v1; schema_version=1
cards=264; sentences=792; card_sentences=792
sentence-count distribution: 3 sentences -> 264 cards
distinct (lang, Python form_norm): 160
duplicate form groups=53; affected cards=157; extra sense cards=104
decks=1; deck_cards=264; every card has exactly 1 membership
forms belonging to multiple decks=0
stories=0; story_sentences=0
sentence_tokens=8474; dictionary_forms=2323
stored form_norm differs from Python form_norm: 0
```

Die 53 Gruppen sind **keine nachgewiesenen identischen Lernkarten**: verschiedene Bedeutungen/POS besitzen verschiedene IDs. Es sind Dopplungen für die neue wortbezogene Stapelauswahl: 107 einfache Formen + 53 mehrfach vertretene Formen = 160 Wörter; 107 + 157 = 264 Karten. Keine der 104 zusätzlichen Bedeutungskarten löschen oder mit anderen Lernständen zusammenlegen. Der Anhang nennt alle Gruppen.

Fünf normalisierte Lemmas enthalten mehrere Formen: a → a/an (3 Karten), be → are/be/been/is/was/were (13), have → had/has/have (10), i → i/me (3), they → their/they (4). Insgesamt 33 Karten, zehn zusätzliche Formen gegenüber je einer Form pro Lemma; diese Kategorie überlappt die Oberflächengruppen und darf nicht addiert werden.

`table` ist einmal vorhanden: `253982ff9b64b28ab49f9ef47e56b2ff`, Sense `table#tisch`, Stapelposition 200. Zusätzliche Karten für Table, tables, go, went und bank sind im aktuellen Pack nicht vorhanden; die Beispiele in Abschnitt 3 sind Prüffälle, keine Bestandsbehauptungen.

### Dokumentation gegenüber tatsächlicher Implementierung

| Bereich | Tatsächlicher lokaler Stand und Auswirkung |
|---|---|
| Satzanzahl/Rotation | `lib/data/content/drift_content_repository.dart::_checked` fordert genau Positionen 1,2,3. `lib/domain/content.dart::PracticeItem.sentenceForPass` rotiert modulo Satzanzahl nach Reviewanzahl. `DeckSessionController._showCurrent` fragt reviewCounts ab, auch für In-Session-Wiederholungen. |
| Pipeline | Drei-Satz-Annahmen in `cli.py::_process_card`, `generate.py::sentences` (Default count=3), `annotate.py::CARD_SCHEMA/annotate_card`, `pack.py::assemble_pack`, `curate.py::curate`, `scripts/complete_curation.py`, `scripts/finalize_curation.py`, `scripts/import_editorial_patch.py::validate_work`. Außerdem `quality.py::common_lemmas`, `review.py` und `prompts/annotate.md`. |
| Exportvalidator | `pack.py::build_rows` sperrt pending Curation und prüft Referenzen/Alternativen, enthält aber keine umfassende zentrale Genau-drei-Prüfung. `export.py::export_sqlite` nutzt build_rows. Künftige Kardinalität muss zentral vor jedem Export geprüft werden. |
| Wortbesitz | `curate.py` verlangt eine deck_cards-Zeile je Karte, nicht je Wort, und ordnet bislang global neu. `selection.py` vergleicht Form/Lemma/POS/Sense gegen Bestand; keine zentrale sprachübergreifende Eigentümer-Registry. |
| Neue Storykarten in Gemischt | `srs_state.dart::buildMixedQueue` stellt bekannte aktive origin-story-Box-0-Karten zuerst in den Kandidatenpool. selectNewCards kann sie durch bekannte Lemmas/4:1/Vielfalt wieder umordnen. Der Controller lädt nur im Content bekannte IDs: local_only ist nicht auflösbar. ensureCards ändert einen bestehenden origin-deck-Stand nicht. |
| Wortliste | `learning_providers.dart::wordListProvider` fordert box >= 1, nicht retired und known.contains(cardId). Es ist bisher eine Liste beantworteter Wörter. Box-0-Storykarten und lokale IDs fehlen. Deaktivierte bekannte Wörter bleiben sichtbar. |
| local_only | Spalte in UserCards und Flag im Domain-State vorhanden. Zähler zählen lokale Zustände bereits. Form/Glosse/lokale Bedeutung, Anlageweg und PracticeItem-Auflösung fehlen: Zählerunterstützung allein ergibt keine lernbare Karte. |
| card_contexts | In user-schema und srs dokumentiert, aber keine Drift-Tabelle, Repository-Funktion oder Nutzung im Übungsablauf. Tatsächliches user.db-Schema ist 3; Klassenkommentar „v2“ ist veraltet. |
| Persistenz | ensureCards: insert-or-ignore, Box 0, vorhandene Werte unverändert. recordReview: Transaktion, eindeutige Durchgangs-ID, Boxprüfung, append-only Trigger. Diesen Weg wiederverwenden. |
| Stories/Übersetzungen | app_shell, StoryReaderScreen.open und models/sample_content.dart verwenden Demo-Stories, sampleLookup, sampleWordMarks und sampleTranslateSentence. Lookup über Kleinschreibung/Headword ohne Sense-ID; fehlende Werte heißen „Übersetzung folgt“. Reader-Regex hält keine stabile Lernreferenz bereit. |
| Add-Button | story_reader_screen.dart::_lookUp setzt learningAvailable=false und onAdd leer. Sheet könnte nur lokal _mark setzen und hat synchronen VoidCallback; Labels bisher „Wird gelernt“/„Bereits gemeistert“. Keine Lernpersistenz. |
| Reale Übersetzung | widgets/sentence_translation_sheet.dart rendert übergebene Strings; Story liefert Demos. Echte Übungstokens kommen aus DriftContentRepository._tokens, verlieren beim UI-Mapping aber ihre Sense-/Lemma-/Karten-IDs. |
| Story-Export | schema.py kennt stories/story_sentences; build_rows transportiert sie bislang nicht aus Pack-Daten. Deshalb reicht ein neuer Story-Screen allein nicht. Das aktuelle Pack enthält null Storydaten. |

ARCHITECTURE bezeichnet noch große Teile pauschal als In-Memory-Zielarchitektur. Tatsächlich laufen Home, Gemischt, Wortliste und Stapel bereits über Drift/Riverpod; nur die hier benannten Storyteile sind Demos. Die Istfeststellung basiert auf Code, nicht auf veralteten Statusabschnitten.

### Tatsächliche ID-Abhängigkeiten

`pipeline/src/sprachpipe/ids.py::KEY_FIELDS` bildet IDs aus Tabellenname und folgenden unveränderlichen Feldern (NFC, U+001F-Trennung, erste 16 SHA-256-Bytes als Hex; keine Kleinschreibung/Trimmung beim ID-Hash):

| Tabelle | Schlüssel in fester Reihenfolge |
|---|---|
| lemmas | lang, lemma, pos |
| senses | lemma_id, sense_key |
| cards | lang, form, sense_id |
| dictionary_forms | lang, form_norm, sense_id |
| sentences | lang, text |
| sentence_tokens | sentence_id, idx |
| card_sentences | card_id, sentence_id |
| decks / stories | lang, slug |
| deck_cards | deck_id, card_id |
| story_sentences | story_id, idx |

Damit ändern ein neuer Satztext oder eine andere Wortform/Bedeutung unterschiedliche Identitäten. Glossen/Übersetzungen gehören nicht zu den ID-Schlüsseln. Der neue normalisierte Besitzschlüssel ersetzt ausdrücklich keine dieser bestehenden Karten-IDs.

## 3. Wortidentität und Eigentümerstapel

### Zielvertrag

1. **Besitzschlüssel:** `(lang, form_norm(surface))`, mit bestehender Python-Normalisierung aus ids.py: NFC, lowercase, ’ → '. Rand-Leerzeichen in Inhaltsformen abweisen. Keine Akzententfernung, Lemmatisierung, Stammheuristik oder Übersetzung als Identität. Dart übernimmt identische Testvektoren; normalizeAnswer mit optional ignorierten Diakritika ist keine Identitätsfunktion.
2. **Ein Eigentümer je Wortschlüssel**, unabhängig von Lemma, POS und Bedeutung. Ein Wort in Reisen darf nicht als andere Bedeutung oder Table in Arbeit erneut reserviert werden. Vorkommen als Begleitwort in anderen Sätzen verbrauchen keinen Platz.
3. **Eine reguläre primäre Lernkarte je kuratiertem Wort**, mit einer ausgewählten Bedeutung und einem Satz. Vorhandene zusätzliche Bedeutungskarten bleiben lesbar/übbar als Altbestand, zählen aber nicht als weitere reguläre Stapelwörter. Eine andere belegte Story-Bedeutung darf einen separaten Lernstand haben.
4. **Lernidentität bleibt Form + Sinn.** Karten-IDs unverändert; gleiche Oberfläche ist eine Belegungssperre, kein Fortschritts-Merge. Case-Varianten dürfen nur bei passender Annotation zur vorhandenen Karte auflösen. Homographen/POS-Unterschiede bleiben getrennt.
5. **Orthografische Aliase** können ausdrücklich redaktionell im Wortbestand registriert werden. Reservierung prüft auch diese Aliase. Keine automatische Transliteration oder Gleichsetzung regionaler Schreibweisen; eine Alias-Beziehung ändert weder accepted noch die Antwortprüfung oder Lernstände. Bedeutungsrelevante Schreibunterschiede dürfen die Besitzsperre nicht umgehen und werden semantisch weiterhin getrennt.
6. **Sprachübergreifend:** lang ist immer Teil des Schlüssels, etwa EN gift ≠ DE Gift. Auch bei bedeutungsrelevanter Großschreibung kann eine normalisierte Kollisionsgruppe nicht heimlich auf mehrere Stapel verteilt werden; daraus folgt keine Gleichsetzung der Senses. Token- und Wortgrenzen liefert die jeweilige Sprachanalyse/Annotation.

| Prüffall | Besitz/Einführung | Lernzustand |
|---|---|---|
| table / Table | ein EN-Schlüssel, ein Eigentümer, keine zweite reguläre Position | passende Form/Sense wiederverwenden; Eigenname/andere Bedeutung nicht automatisch gleichsetzen |
| table / tables | zwei explizite Wortformen, je ein möglicher Platz/Satz | getrennte Karten; belegte Lemmafamilie nur für Formenhinweise |
| go / went | zwei Formen; je ein eindeutiger Eigentümer, dürfen bewusst verschiedenen Stapeln zugewiesen werden | getrennte Lernstände; keine Ableitung durch Endungsregeln |
| bank Geldinstitut/Ufer | ein Wortschlüssel/Eigentümer, eine reguläre Primärbedeutung | verschiedene Senses behalten getrennten Fortschritt; Story kann andere belegte Bedeutung hinzufügen |
| Wort in Reisen/Arbeit | zweite Reservierung blockiert vor Produktion; als Begleitwort erlaubt | Herkunft Story oder neuer Themenbezug kopiert keine Karte und verändert den Eigentümer nicht |

### Versionierter zentraler Wortbestand

**Neu in A:** `pipeline/data/words/en.v1.json`, `pipeline/src/sprachpipe/word_registry.py`. Bestand enthält format/version/lang/normalization_version, Quellhash und je Wort form_norm, display_form, aliases, owner_deck_ref, primary_card_ref/ID, vorhandene sense-card-IDs, Status, Herkunft/Begründung. Bedeutungsinventar bleibt Autorität für Senses; Registry ist Autorität für Wortbesitz. Kein Ändern vorhandener ids.KEY_FIELDS.

Vor jedem Satzgenerator oder redaktionellen Create-Import vollständige Auswahl gegen Registry prüfen. Konflikte mit beiden Positionen/Eigentümer/IDs melden; kein Skip, Umbenennen oder Ersatzwort. Gleiche Eingabe/Hashes ergeben gleiche Ausgabe. Reservierungen sind versionierte atomare Dateiänderungen mit erwartetem Basishash; konkurrierende/veraltete Vergaben scheitern.

Laufzeittransport in derselben Content-DB: **neue Tabelle deck_words** (id, lang, form_norm, deck_id, primary_card_id, position, Tombstones), aktive UNIQUE(lang, form_norm), eindeutige Primärkarte/Position pro Stapel. **Neue Tabelle word_aliases** mit eindeutigem sprachbezogenem Alias und Referenz auf deck_words. deck_cards bildet die aktiven primären Lernkarten ab. Weitere Sense-Karten haben denselben Eigentümer über den Wortschlüssel. Neue Tabellen bekommen neue Schlüsseldefinitionen, bestehende IDs bleiben unverändert.

### Datenerhaltender Übergang

- Registry aus dem hashgebundenen Ist-Pack: 160 Wörter, Eigentümer allgemeine-sprache. Alle 53 Doppelgruppen wurden anhand ihrer Definitionen und vorhandenen Sätze redaktionell entschieden. `en.v1.json` enthält Karten-ID, Sinn und Begründung. Die kleinste bisherige Gruppenposition bestimmt nur die Reihenfolge der Wörter, niemals die Primärbedeutung. Verbindlich: like#moegen, so#so_sehr, will#zukunft, the#bestimmter_artikel, and#und, can#koennen, time#zeit, in#in_raeumlich, of#genitiv_besitz, they#sie_plural.
- Alle **264 Karten** bleiben erhalten. 160 aktive Primärpositionen; 104 zusätzliche Senses als Altbestand mit Eigentümer. Deren alte deck_cards-Zeilen historisch/inaktiv (`removed_in` nur an Zuordnung, NICHT an cards), kein replaced_by auf eine andere Bedeutung. Keine Änderung an user.db.disabled/retired. „Eine aktive deck_cards-Zeile je Karte“ wird ersetzt durch Eigentümerpflicht und eine Primärzuordnung je Wort.
- Bestehende Box-1–5-Altstände bleiben in Wortliste, fälligem Gemischt und Vorab-Üben. Box-0-Nebenbedeutungen können allein beim Anzeigen entstanden sein: unverändert erhalten, ohne explizite Lernentscheidung weder automatisch einführen noch als verfügbare neue Wörter zählen. Belegte origin-story-Entscheidungen bleiben ausgenommen. Die separate Hinzufügen-Entscheidung folgt in B.
- Direkte Stapelübungen und Stapel-Revue verwenden ausschließlich die 160 Primärkarten. Gelernte Nebenbedeutungen bleiben in Wortliste und Gemischt erreichbar. deckCardIds liefert ausschließlich Primärpositionen; allCardIds behält alle 264 Lernidentitäten.
- Stapelumfang: **160 Lernwörter / 160 reguläre Übungssätze**. Globale SRS-Zähler bleiben sinnbezogen und können wegen erhaltener Nebenbedeutungsstände höher sein. Stapel-seen/mastered bezieht sich auf Primärkarten; Altstände bei Bedarf getrennt ausweisen. Kein Zusammenlegen, um Zähler künstlich passend zu machen.
- so#auf_diese_weise und like#fuellwort werden nicht wegen einer Rückstellungsempfehlung gelöscht/deaktiviert. Eine entfallende Primärposition folgt der allgemeinen neuen Wortregel; ihre vorhandenen Lernstände bleiben übbar.

## 4. Ein-Satz-Umstellung und Versionsgrenze

**Neu in A:** `pipeline/data/curation/single_sentence_v1.json`, gebunden an Quellhash. Für jede der 264 Karten: card_id, alte drei Satz-/Link-IDs, ausgewählte sentence_id, erwarteter Text/Gap/accepted/Alternativen, Begründung. Position 1 war Ausgangspunkt für die Lektüre, keine automatische fachliche Freigabe. Die versionierte Auswahl enthält für alle 264 Karten eine Begründung; 35 ausgewählte Sätze stammen von Position 2 oder 3. Strukturelle Ungültigkeit stoppt den Export. Keine Generierung, keine behauptete neue Modell-QA.

- Jede erhaltene Karte einschließlich 104 Alt-Senses hat **einen aktiven Übungssatz**: 264 aktive Karte-Satz-Links, davon 160 reguläre Stapelübungen. Die übrigen 528 Links werden historisch; 792 Textzeilen/Token bleiben zunächst für Historien erhalten. Ein neuer 500-Wörter-Stapel hat genau 500 aktive Primärlinks/Sätze. Archive und Altstände sind kein zusätzlicher regulärer Stapelumfang.
- Karte unverändert → Karten-ID bleibt; ausgewählter Text unverändert → Satz-/Link-/Token-IDs bleiben. review_log.sentence_id bleibt unberührt. Historische Texte über eigene Read-only-Abfrage auflösen; WordListProvider trennt aktuellen Übungssatz von letztem tatsächlich gezeigtem Reviewsatz.
- Archivierung an card_sentences.removed_in, Text kann für Historie/Story aktiv lesbar bleiben. build_rows muss Tombstone-Felder wirklich aus Quellen transportieren (derzeit werden sie oft weggelassen). Inaktive Satz-/Stapelverknüpfung darf keine Karten-Retirierung auslösen. Kein Content-ID-Recycling.
- PracticeItem erhält `practiceSentence`, keine Moduloauswahl. Eine Sitzungswiederholung bindet denselben Satz wie der erste Durchgang. Eigener primärer Kontext wird nur in mixed/early benutzt; direkte Stapelübung verwendet den kuratierten Satz.

**Content-Schema 2** kennzeichnet Ein-Satz-Regel und Wortbesitz. Vor erstem Staging App-Leser/Installer/Stage-Werkzeug für **Schema 1 und 2** befähigen; höhere Versionen sichtbar ablehnen. Keine In-place-Migration alter Packs.

| Fall | Verhalten |
|---|---|
| Schema 1 lesen | Alte drei Positionen vollständig validieren, deterministisch Position 1 als Übung projizieren; alle drei historisch lesbar. Fehlendes deck_words über konservativen In-Memory-Adapter nach Form, Stapel-sort/slug, Position/ID auflösen; widersprüchlichen Altbesitz diagnostizieren, nicht als neue Exportfreigabe behandeln. Alle alten Kartenstände bleiben auflösbar. |
| Schema 2 lesen/schreiben | Genau eine aktive Position 1 je übbarer Karte; historische Links zählen nicht. Genau eine Primärkarte je deck_words. 0/2/4 aktive Sätze sind ungültig, keine allgemeine Lockerung auf mindestens eins. |
| Neue Exporte ab A | Jeder normale Generierungs-/Redaktions-Export erzeugt Schema 2 und durchläuft denselben Validator. Alte Schema-1-Artefakte bleiben read-only analysierbar; Legacy-Fixtures/Replays brauchen expliziten Kompatibilitätspfad, keinen stillen Default. |
| Rollout | Kompatibler Leser zuerst, frischer Packordner/ID-Diff/Readback, Tests, Assetbackup, bestehendes Stage-Werkzeug, Gerätetest auf Lernstandskopie. Rückkehr zum alten Pack bleibt möglich; user.db unverändert. A benötigt keine lokale Nutzer-DB-Migration. |

## 5. Redaktioneller Zulieferweg

Den vorhandenen `pipeline/scripts/import_editorial_patch.py` um versionierten Create-/Story-Modus erweitern; kein zweites Importprogramm. **Neu:** `pipeline/data/curation/editorial_content_v2.schema.json`. Eingabe: Registry-Version/Hash, Basis-Pack-Hash, Operation-ID, reservierte Form/Lemma/POS/Sense/Deck, genau ein Zieltext mit Übersetzung und eindeutiger Zielstelle, vollständige Tokenannotation/Formglossen und explizite Prüfnachweise. Neue Senses mit Definition getrennt von Formglosse. Story-Zulieferung enthält Story-ID/slug, geordnete Sätze/Absätze, Satzübersetzung, Tokenreferenzen und Freigabe selbständiger Lernkontexte.

Gemeinsamer Weg: Registry/Hash/ID → bestehende Curation (Create ergänzen) → lokale Spans/Referenzen → vollständiger bestehender Linter → belegte redaktionelle Sinn-/Übersetzungsprüfung → derive_dictionary → finalize/build_rows/export_sqlite/check_sqlite. Unvollständige Annotation/Prüfung bleibt Arbeitsstand. Alternativen nur nach expliziter Prüfung der wörtlich eingesetzten vollständigen Sätze, sonst leere Liste. QA als editorial_reviewed mit genauer Herkunft/checked-Tupel; keine erfundene Vertex-Prüfung. Keine global gelockerten Lintergrenzen.

Vertex bleibt optionaler Zulieferer desselben Vertrags. Seine Zielzahl/Annotationsgruppen werden auf eins umgestellt; Kandidatenzahl, Retrybudget und „bis zu drei Alternativen“ sind andere Konzepte und nicht blind zu ersetzen. Kein Cloud-Fallback für fehlende Redaktion/Glossen. Modelle/Budgets bleiben unverändert. Stories/story_sentences über denselben build_rows-/Schema-/Exportweg transportieren, keine separate Datenbank.

## 6. Story-Wörter bis zur tatsächlich übbaren Karte

### 6.1 Daten und read-only Worttippen

Ein neuer typisierter StoryDocument liefert Sprache, stabile Story-/Satz-ID, exakten Text/Übersetzung sowie je Token Index, Oberfläche, Offsets, lemma_id, sense_id beziehungsweise expliziten lokalen semantischen Anker, konkrete Formglosse und optionale card_id. Referenzen gegen Text und Inhaltsversion prüfen. Kartenmatch durch **Sprache + normalisierte konkrete Form + belegtes Lemma/Sense**, niemals nur Headword, ersten Dictionary-Treffer oder ähnliche Übersetzung. Eine vorhandene Token-card_id genauso prüfen; fehlt sie, exakt nach diesem Tupel suchen. Mehrdeutige Treffer sind ein sichtbarer Datenfehler.

Reader an vorhandene stories/story_sentences/sentences/sentence_tokens anschließen. Worttap benutzt gespeicherte Satz-ID und Tokenindex; Regex-Zerlegung allein ist keine Identität. Annotationmodell behält die IDs, statt sie wie das aktuelle SentenceToken-UI-Modell zu verlieren. Codepoint-Offsets aus Python einmal an der Repositorygrenze nach Dart-UTF-16 umrechnen; Emoji und kombinierte Zeichen testen. SQL lower() ist nicht die vollständige Unicode-Normalisierung: kanonischen form_norm verwenden.

Tap öffnet Übersetzung und liest den Add-Status **ohne Schreibzugriff**. Bekannte Übersetzung ohne eindeutige Sense darf erscheinen, aber Add erklärt „Bedeutung nicht eindeutig – noch nicht zum Lernen verfügbar“. Fehlende Glosse sichtbar, niemals „Übersetzung folgt“ speichern. Keine automatische Cloud-Nachfrage. Unannotierte Demo-Inhalte bleiben ausdrücklich Demos und nicht hinzufügbar.

Das aktuelle Pack hat null Stories. **B braucht mindestens einen redaktionell annotierten echten Storydatensatz** über den in A erweiterten Import. Vorhandener Text darf offline aufbereitet werden, ohne Neugenerierung. Das ist Teil der Inhaltsabnahme, nicht durch sampleLookup zu ersetzen. Kleine Schema-Fixtures prüfen beide Wege netzwerkfrei. Home, Story-Bibliothek und Reader müssen dieselben geladenen Storydaten verwenden; getrennt gekennzeichnete Demo-News erhalten keinen ungesicherten Lernbutton.

### 6.2 Weg A – vorhandene passende Lernkarte

1. Lookup liefert geprüften Kandidaten mit Packversion/Tokenreferenz und card_id. Vor Add revalidiert der Service unter gehaltenem Content-Repository-Lease denselben Inhalt.
2. Asynchroner Button → UserRepository-Transaktion: fehlt Zustand, Karte mit Box 0, due_at null, origin story anlegen. Bestehende Zeile **nicht** bezüglich Box/Fälligkeit/created_at/origin/Flags/Notiz überschreiben. Zusätzlich explizite Story-Lernentscheidung speichern; das funktioniert auch für bereits beim Stapelanzeigen angelegte origin-deck-Box-0-Karten.
3. Story-/Satz-/Tokenquelle speichern, **keinen primären eigenen Kontext setzen**. Der vorhandene kuratierte Übungssatz bleibt. Übersetzungstap erzeugt weder Zustand noch Herkunftszeile.
4. Erst bestätigter Commit → „Bereits hinzugefügt“. Neustart oder andere Story ergibt dieselbe Karte und denselben Status. Eine ausdrücklich gespeicherte weitere Quellenreferenz ist kein zweiter Lernstand.
5. Wortliste zeigt sofort „Ungelernt“, null Reviews. Gemischt berücksichtigt die explizite Box-0-Entscheidung auch bei ausgeschaltetem Eigentümerstapel. Erste Antwort geht unverändert über ReviewPass → recordReview → Leitner.

Ein ungeeigneter Storysatz verhindert A nicht, wenn seine Wortannotation sicher passt und die vorhandene Karte einen gültigen Übungssatz besitzt. Eine spätere Aktion „Diesen Satz zum Üben verwenden“ ist getrennt vom Add und braucht vollständige Kontextvalidierung wie B. Keine solche Kontextwahl beim bloßen Hinzufügen implizit ausführen.

### 6.3 Weg B – keine passende Lernkarte

Erforderlich sind belegte kontextuelle Bedeutung, Lemma/POS, konkrete Formglosse, exakter Storysatz und deutsche Satzübersetzung, gewählte Tokenstelle und Herkunft. Ein vorhandener Dictionary-Sense ohne Lernkarte wird wiederverwendet. Andernfalls muss die redaktionelle Story einen stabilen namespacierten semantischen Anker samt Definition liefern. Keine Bedeutung aus einer Übersetzungszeichenfolge erraten.

- **Lokale Karten-ID:** `u:` + deterministischer Hash über Namensraum local-card-v1, lang, normalisierte konkrete Form und semantischen Anker. Bei Content-Sense ist der Anker dessen stabile ID (Lemma/POS eingeschlossen), sonst ein ausdrücklich definierter lokaler Sense-Schlüssel mit belegter Lemma/POS-Bindung. Story-ID, Satz, Glosse und Zeitstempel sind keine Karten-ID-Bestandteile. Glossenänderung erzeugt keine neue Karte; alte Content-IDs bleiben unberührt.
- **Eigener Kontext:** CardContexts-Zeile mit UUID-ID wie dokumentiert, card_id, Text, Übersetzung, gap_start/end, Quelle/Referenz, Tokenindex, Sprache, Status/Prüfherkunft und Kontextfingerprint. Mehrfach vorkommendes Zielwort: exakt angetippten Token verwenden, kein indexOf/erstes Vorkommen. Alle übrigen Vorkommen bleiben normaler Text. Identische Quelle/Token/Revision darf keinen zweiten Kontext erzeugen.
- **Ein Commit:** lokale Metadaten + local_only-Box-0-Zustand + gültiger erster Primärkontext + explizite Lernentscheidung + semantische Identitätsbindung in EINER Transaktion. Fehlende Angaben oder Schreibfehler dürfen kein halb gespeichertes „hinzugefügt“ hinterlassen. Keine Reviews beim Add.
- **Kontextqualität ohne Pflicht-KI:** Spans, Quellenintegrität und Länge lokal prüfen. Semantische Selbständigkeit, Übersetzung und ≤1 Nebensatz müssen durch eine gespeicherte redaktionelle Freigabe für genau diesen Text belegt sein; keine geratenen Dart-Nebensatzheuristiken. Dokumentierte Grenze ≤20 Wörter für eigene Kontexte beibehalten. Nicht freigegeben/ungeeignet → konkreter sichtbarer Grund, Add nicht erfolgreich darstellen. pending/failed ist kein übbarer Primärkontext. Kein automatisches Umschreiben; A bleibt bei passender Karte möglich.
- **Übung:** gemeinsamer PracticeItem-Resolver liefert lokale Metadaten, ausgewählten Kontext, accepted mit genau der belegten Zielwortform, leere valid_alternatives und ausschließlich belegte andere Formen an den vorhandenen Controller. Die Zielstelle muss nach derselben Formnormalisierung zur lokalen Karte passen; keine alternativen Antworten aus Dictionary-Glossen ableiten. review_log.sentence_id ist die card_contexts.id. SRS/Antwortprüfung unverändert.

### 6.4 Zustände und Wiederholungen

| Situation | Verbindliches Verhalten |
|---|---|
| Bereits Box 1–5 | „Bereits hinzugefügt“, vorhandene Fälligkeit/Flags/Notiz/Reviews unverändert; kein weiterer Review. |
| Bereits explizite Story-Box-0-Karte | gleicher Status/ID/Primärkontext, null Reviews. |
| Box 0 nur durch Stapelanzeige | Add darf explizite Storyentscheidung ergänzen; origin/Zustand unverändert. Danach unabhängig vom Stapelschalter übbar. |
| Deaktivierte passende Karte | „Deaktiviert“; gesondertes ausdrückliches Reaktivieren über setCardFlags. Add reaktiviert nicht still. |
| Retirierte/nicht mehr auflösbare passende Karte | „Nicht verfügbar/retiriert“, kein u:-Duplikat als Umgehung, kein Reset. Alte Zeile erhalten; fehlende Daten benennen. |
| Andere Story, gleiche Form/Sense | gleicher Lernstand; neue Quellenreferenz nur nach ausdrücklicher Aktion. Primärsatz nicht automatisch wechseln. |
| Gleiche Schreibung, andere belegte Bedeutung | eigene Lernidentität, klar dargestellte Bedeutung. Keine neue kuratierte Wortposition/Deckzuordnung. |
| Doppeltipp/zwei Sheets/Absturz nach Commit | await sperrt UI; Transaktion/Unique-Keys sind maßgeblich. Retry liest committed Ergebnis und liefert alreadyAdded. |
| Später passende kuratierte Karte zu u:-Karte | Keine ID-/Reviewumschreibung. Exakte persistierte Bindung verwendet für neue Story-Adds weiterhin die lokale Karte. Automatische neue Stapelwahl filtert die nachgewiesene Entsprechung heraus, statt zweiten Erstkontakt anzulegen. Lokaler Lernstand bleibt deckunabhängig. |
| Beide IDs haben bereits Lernstand | beide Zustände und Reviews erhalten, sichtbarer Identitätskonflikt; kein automatischer Sieger/Merge. Neue Adds benötigen eindeutige Bindung oder explizite Auswahl; fällige Altstände bleiben erreichbar. |
| Content fehlt/ist defekt | Vollständige lokale Karten bleiben ohne Content auflösbar. Kuratierte Karten zeigen Inhaltsfehler; lokale Wortliste/Queue dürfen nicht pauschal mit ausfallen. |

## 7. Lokale Daten, Schnittstellen und Queue

### Eine additive user.db-Migration v3 → v4 in B

In bestehender `lib/data/user/user_database.dart` plus erzeugter `user_database.g.dart`:

- Nullable lokale Metadaten an UserCards: form, form_norm, gloss_de, lemma, pos, lemma_identity, sense_identity/Namensraum; bei neuen local_only-Zeilen erforderlich, für bestehende Content-Zeilen leer. primary_context_id nullable; bestehende Karten bekommen keinen erfundenen Kontext.
- **Neue CardContexts** mit oben beschriebenen Feldern und eindeutiger Quellenrevision/context_fingerprint. Kontexte bleiben unveränderliche Revisionen. Notwendige Präzisierung gegenüber noch nicht umgesetztem user-schema-Entwurf: statt is_primary an historischen Zeilen ist user_cards.primary_context_id der einzige umschaltbare Zeiger. So werden alte Kontexte/Reviewreferenzen nicht umgeschrieben.
- **Neue StoryLearningAdditions:** card_id PK, explicit_added_at, unabhängig von origin der ersten Erstellung. **Neue StoryWordSources:** eindeutiger Schlüssel card_id + source_ref + sentence_ref + token_idx + source_revision, added_at. A benötigt keinen kopierten Storysatztext.
- **Neue LearningIdentityBindings:** UNIQUE(lang, form_norm, semantic_anchor), card_id. Bindungen ausschließlich mit exaktem Inhaltsnachweis. Während SQL-Migration kein automatisches Backfill nach Schreibweise; Resolver prüft vorhandene exakte Zustände vor Neuanlage. Kein INSERT OR REPLACE zur Konfliktunterdrückung.
- Migration addiert nullable/default-Spalten und leere Tabellen, keine Änderungen alter Werte/Reviews/Trigger, kein Netzwerk. Vorhandene unvollständige local_only-Zeilen, falls vorhanden, erhalten „Inhaltsdaten fehlen“ statt erfundener Texte oder globalem Migrationsfehler. Neue Writes erzwingen Vollständigkeit transaktional.
- changes()-Stream beobachtet neue Tabellen für Lookup/Wortliste/Zähler/Queue. Keine Server-Nutzermigration oder Synchronisationsfunktion in B.

### Konkrete Schnittstellen

Die folgende Tabelle dokumentiert den ursprünglichen API-Plan; der tatsächliche Paket-B-Stand und bewusst nicht eingeführte Kontextwahl sind in Abschnitt 11 dokumentiert.

| Bestehender/neuer Pfad | Erweiterung |
|---|---|
| `lib/domain/content.dart` | PracticeItem.practiceSentence statt Rotation; Tokenreferenzen erhalten. |
| **Neu** `lib/domain/story_learning.dart` | Reine Dart-Typen StoryDocument, AnnotatedStoryToken, semantische Identität, validierter Lernkandidat, Add-Ergebnisse; Form-/Spanprüfung und u:-IDs mit gemeinsamen Testvektoren. |
| `lib/domain/repositories.dart` / `lib/data/content/drift_content_repository.dart` | ContentRepository: ownedCardIds(deckId) inklusive Altbestand, storySummaries(), storyDocument(id), resolveAnnotatedWord(token) → exact/none/ambiguous/retired, historicalSentence(id). deckCardIds liefert Primär-Einführung, allCardIds alle auflösbaren Karten. |
| `repositories.dart` / `lib/data/user/drift_user_repository.dart` | storyLearningStatus(candidate), addStoryWord(validatedCandidate, now) → added/alreadyAdded/disabled/retired/unavailable/conflict, explicitStoryAdditions(), localPracticeItems(ids), cardContexts(cardId), choosePrimaryContext(cardId, contextId), identityBindings(). ensureCards und recordReview behalten ihre Schutzregeln. |
| **Neu** `lib/data/learning/practice_item_resolver.dart` | Gemeinsamer Resolver über die vorhandenen Repositories: selectionCards(ids), practiceItems(ids, mode), resolvableCardIds(). Kein neuer Store. Vollständige lokale Daten unabhängig vom Content; eigener Kontext nur in mixed/early. |
| **Neu** `lib/presentation/providers/story_learning_providers.dart` | Read-only Story-/Lookup-Provider und Async-Add-Controller; Content-Lease halten, Kandidat revalidieren, Transaktion, Status erst nach Commit. |
| `lib/presentation/providers/database_providers.dart` | Resolver mit denselben Repository-Owners registrieren; kein zweiter DB-Lebenszyklus. Inhaltsfehler quellbezogen behandeln. |

### Wortliste, Gemischt und Zähler verbindlich schließen

1. **Wortliste:** auflösbare Zustände ab Box 1 oder explizit hinzugefügte Story-Box-0-Karten (inklusive kompatibler origin-story-Zeilen). Bloß angezeigte deck-origin-Box-0-Karten bleiben sonst unsichtbar. Resolver statt known.contains. Deaktivierte sichtbar; retired/unauflösbare gesondert nicht übbar mit bekannten Metadaten, ohne erfundene Wörter. Box 0: „Ungelernt“, 0 Reviews, „Hinzugefügt“ statt falschem „Zuletzt geübt“. Flags/Notizen am selben card_id.
2. **Gemischt:** fällige auflösbare aktive Zustände → explizite Story-Box-0-Karten nach ältester Lernentscheidung → neue Primärwörter aktiver Stapel → Vorab-Üben. Einträge nach card_id deduplizieren; exakte IdentityBindings verhindern nur zusätzliche Neuanlagen/Ersteinführungen. Zwei bereits existierende fällige Zustände bleiben erreichbar, auch bei nachgewiesener Identitätskollision. Nie pauschal nach Oberfläche bei fälligen Senses deduplizieren.
3. Story-Priorität darf nicht nur die Reihenfolge eines danach umsortierten Kandidatenpools sein. Plätze für explizite Storyentscheidungen zuerst reservieren; 4:1 gilt für automatische neue Stapelwörter. Für neue Plätze weiterhin höchstens eine Form/ein Lemma je Sitzung; Konflikt bleibt für nächste Sitzung vorgemerkt. Reservierte Schlüssel an selectNewCards weiterreichen. Keine dauerhafte Sperre eines Storywortes, weil sein Lemma bereits durch Box 0 als bekannt gilt.
4. Tagesziel bleibt weich und ausschließlich reviewbasiert. Add verändert weder Ziel-Fortschritt noch Streak. Fällige Reviews dürfen eine Session füllen; noch nicht gewählte Storywörter bleiben Box 0 und kommen in späteren Sessions an die Reihe.
5. Direkte Stapelsitzung und Revue: ausschließlich Primärkarten; fällige Nebenbedeutungen bleiben Gemischt vorbehalten. Lokale Storykarte aktiviert keinen Deck-Schalter und wird nicht in die Stapelsitzung kopiert. Gesehene Karten bleiben bei deaktiviertem Stapel in Gemischt fällig.
6. Controller lädt Metadaten/PracticeItems über Resolver. ensureCards(origin deck) nur für tatsächlich neue Stapelkarten; Story-Zustand existiert schon atomar. Vorhandene Herkunft nicht überschreiben. ReviewPass/recordReview/scheduleReview/withRepeat bleiben gemeinsamer Lernweg; Wiederholung behält Satz und erzeugt keinen zweiten Review.
7. deriveVocabBreakdown/deck_providers verwenden denselben auflösbaren Vorrat wie Queue. Unvollständige alte lokale Zeilen sind sichtbar als Problem, zählen aber nicht als verfügbare Übung. Explizite Box 0 zählt einmal zu „Noch nicht angezeigt“, ohne aktiven Deck. Exact IdentityBindings verhindern einen zusätzlichen unbekannten Primärplatz für eine bereits vorhandene lokale Lernidentität. Keine gespeicherten Zähler; Eigentümerstapel bleibt unabhängig von Storyherkunft.
8. Bei späterem kuratiertem Gegenstück bleibt der Wortplatz im Eigentümerstapel bestehen. Ausschließlich eine belegte exakte Bindung darf dessen seen/mastered-Anzeige aus dem bestehenden lokalen Zustand ableiten; Kennzeichnung „Über Story gelernt“. Das ist eine Leseprojektion, keine Übertragung von ID, Zustand oder Reviews. Ohne eindeutige Bindung keine Fortschrittsübernahme. Direkte Stapelsitzung legt hierfür keinen zweiten Zustand an; die bestehende Karte bleibt über Gemischt übbar. Box 0 bleibt ungelernt; deaktivierte/retirierte Bindungen werden nicht als verfügbare Übung gezählt und nicht durch eine neue Karte umgangen. Diesen Fall mit Queue, Wortliste und allen Zählern gemeinsam prüfen.

## 8. Zwei zusammenhängende Umsetzungspakete

### A – Inhaltsvertrag, Wortbesitz und kompatible Ein-Satz-Umstellung

Reihenfolge: gemeinsamer Vertrag/Registry → Schema-1/2-Leser/feste Satzwahl → versionierte Primär-/Satzwahl/Archivtransport → redaktioneller Create-/Story-Transport → zentraler Exportvalidator/Readback → Tests/Backup/Staging. Keine user.db-Migration.

**Bestehende Dateien:** PRODUCT.md, ARCHITECTURE.md, docs/content-schema.md, docs/pipeline.md, docs/app-content-integration-plan.md, docs/srs.md; `pipeline/src/sprachpipe/selection.py`, `ids.py` (nur neue Tabellenkeys), `schema.py`, `pack.py`, `curate.py`, `cli.py`, `generate.py`, `annotate.py`, `quality.py`, `review.py`, `pipeline/prompts/annotate.md`; `pipeline/scripts/import_editorial_patch.py`, `complete_curation.py`, `finalize_curation.py`, `merge_everyday.py`; `lib/domain/content.dart`, `repositories.dart`; `lib/data/content/content_database.dart`, `content_database.g.dart`, `drift_content_repository.dart`, `content_pack_installer.dart`; `lib/presentation/practice/deck_session_controller.dart`, `lib/presentation/providers/deck_providers.dart`, `learning_providers.dart`; `tool/stage_content_pack.dart`.

**Neue Dateien:** `pipeline/data/words/en.v1.json`, `pipeline/src/sprachpipe/word_registry.py`, `pipeline/src/sprachpipe/content_contract.py` (gemeinsamer Ownership-/Kardinalitätsvalidator), `pipeline/data/curation/single_sentence_v1.json`, `pipeline/data/curation/editorial_content_v2.schema.json`; `supabase/migrations/20261004000003_deck_word_ownership.sql` als Inhaltsschema-Spiegel (Name bei Umsetzung gegen vorhandene Migrationen prüfen, keine Anwendung/Uploads). Keine zweite Pipeline.

**Tests:** bestehende `pipeline/tests/test_selection.py`, `test_pack_db_export.py`, `test_curate.py`, `test_complete_curation.py`, `test_finalize_curation.py`, `test_editorial_import.py`, `test_cost_schema.py`; neue `pipeline/tests/test_word_registry.py`, `test_content_contract.py`. Dart: `test/data/content_repository_test.dart`, `stage_content_pack_test.dart`, `real_pack_test.dart`, `test/domain/review_pass_test.dart`, `test/deck_flow_test.dart`, `test/learning_integration_test.dart` und Fixtures. Generator-/Annotations-/Berichtstests vertragsabhängig anpassen, echte Drei-Satz-Legacy-Fixture behalten.

**Abnahme A:**

- 500 registrierte neue Primärwörter → 500 aktive Zielkarten und 500 aktive Primärlinks. Zweiter Eigentümer, Case-/Alias-Umgehung und Nebenbedeutungs-Dopplung scheitern vor Produktion und Export.
- Alle 264 vorhandenen Karten-IDs erhalten; 160 reguläre Wortplätze + 104 auflösbare Alt-Senses, 264 aktive Ein-Satz-Links + 528 historische Links, 792 Texte erhalten. ID-Mengen/Archivstatus protokolliert. Bloß angezeigte Box-0-Nebenbedeutungen bleiben ausgeschlossen; gelernte Nebenbedeutungen und historische Satzauflösung bleiben erreichbar, ohne Original-Userwrites.
- Schema 1 funktioniert mit festem Satz 1; Schema 2 fordert genau einen. Wiederholte Reviews/In-Session-Repeat zeigen denselben Satz. 0/2/4 aktive Sätze werden abgewiesen.
- Editorial Create kann mindestens eine reservierte Karte und einen annotierten Storydatensatz ohne LLM-Client/ADC einlesen, validieren und exportieren. Fehlende Annotation/Prüfung bleibt gesperrt, keine erfundene QA.
- SQLite-Readback sämtlicher Tabellen, Manifest/Hash/Stage, DB-Kopienvergleich. Kompatibler Leser vor neuem Asset; Rollback zum alten Pack möglich, Reviews unverändert.

### B – Story-Button, Persistenz, Wortliste und Gemischt

Reihenfolge: additive v4-Migration/Transaktionen → Identitäts-/PracticeItem-Resolver → echte Storydaten/Provider → Reader/Lookup → Box-0-Wortliste/Queue/Zähler → beide End-to-End-Wege. Keine erneute Grundsatzplanung.

**Bestehende Dateien:** docs/user-schema.md, docs/srs.md, PRODUCT.md, ARCHITECTURE.md, DESIGN.md (beschlossene Labels/Status); `lib/domain/repositories.dart`, `content.dart`, `srs_state.dart`, `new_card_selection.dart`; `lib/data/user/user_database.dart`, `user_database.g.dart`, `drift_user_repository.dart`; `lib/data/content/drift_content_repository.dart`; `lib/presentation/providers/database_providers.dart`, `learning_providers.dart`, `deck_providers.dart`; `lib/presentation/practice/deck_session_controller.dart`; `lib/screens/app_shell.dart`, `lib/screens/home/home_screen.dart`, `lib/screens/stories/story_library_screen.dart`, `story_reader_screen.dart`, `widgets/word_lookup_sheet.dart`, `lib/screens/words/word_list_screen.dart`, `widgets/word_details_sheet.dart`; `lib/models/story_models.dart`, `word_list_models.dart`; `lib/widgets/sentence_translation_sheet.dart`.

**Neue Dateien:** `lib/domain/story_learning.dart`, `lib/data/learning/practice_item_resolver.dart`, `lib/presentation/providers/story_learning_providers.dart`; `pipeline/data/curation/story_learning_seed_v1.json` für explizit redaktionell aufbereiteten vorhandenen Storytext über denselben Import. Kein stilles Produktions-Seed aus Beispieldaten. Fehlende Freigabe bleibt sichtbar; Fixture-Erfolg ersetzt keine reale Story-Abnahme.

**UI:** bestehendes Sheet/Buttons/Theme wiederverwenden. Übersetzungstap speichert nicht. Add: „Wird hinzugefügt …“, Button während await gesperrt; erst Commit → exakt „Bereits hinzugefügt“. Fehler: „Nicht gespeichert – erneut versuchen“. Markierung aus persistierter konkreter Lernidentität, nicht lokalem Headword-Mark. Status für Screenreader verfügbar, Fokus erhalten. Deaktiviert/retired erkennbar; Reaktivieren eigene Aktion. Kein vermeintlicher Erfolg aus VoidCallback.

**Tests:** neue `test/domain/story_learning_test.dart`, `test/data/story_learning_repository_test.dart`, `test/story_learning_flow_test.dart`; bestehende `test/data/preferences_migration_test.dart`, `review_flow_test.dart`, `test/domain/new_card_selection_test.dart`, `vocab_breakdown_test.dart`, `test/learning_integration_test.dart`, `test/widget_test.dart`. SQLite-Fixtures mit echten Token-/Sense-Referenzen; sampleLookup ist kein Annotationsnachweis.

**Abnahme B:**

- Tap/Übersetzung → null Userwrites. A: neue passende Karte → Box 0, null Reviews, sofort Wortliste/Gemischt auch bei inaktivem Deck, Übungssatz unverändert; erster sauberer Review → Box 3.
- B: keine Lernkarte, aber belegte Bedeutung → atomare u:-Karte/Kontext; Neustart gleiche ID/Glosse/Lücke; Wortliste → Gemischt → echter Review mit Kontext-ID. Bereits vollständige lokale Karte funktioniert ohne Content. Content-Datei bleibt unverändert.
- Doppeladd/zweites Sheet/andere Story/Commit-Retry → ein Zustand, kein Add-Review. Fehler vor/nach Commit und konkurrierende Aufrufe getestet; keine verlorenen Flags/Notizen/Fälligkeiten.
- bank-Senses getrennt; table/Table mit derselben belegten Sense idempotent; tables/went nicht auf Grundform-Fortschritt abbilden. Mehrfachvorkommen/Unicode verwenden genau den getippten Token.
- Disabled/retired, späteres kuratiertes Gegenstück, bereits doppelte Zustände, fehlende Bedeutung/Glosse/Übersetzung und ungeeigneter Kontext haben überprüfbare sichtbare Ergebnisse, keinen Erfolg ohne Übbarkeit.
- v1/v2/v3 → v4 auf DB-Kopien: alle bisherigen Spaltenwerte/Reviews unverändert, Trigger wirksam, keine erfundenen Inhalte. Neustart/Emulator auf Kopie; iOS nur als geprüft nennen, wenn ausgeführt.
- Explizite Story-Box-0-Karten werden nicht vom Stapelschalter, known-ID-Filter oder dauerhaften Mixfilter ausgesperrt. Globale Zählersumme entspricht auflösbarem Vorrat; Add ändert weder Tagesziel noch Streak.

## 9. Gegenprüfung und wirklich offene Fragen

| Risiko | Im Plan geschlossen durch |
|---|---|
| Fortschrittsverlust durch Dedup | Wortbesitz getrennt von Lern-ID; 104 Alt-Senses bleiben auflösbar; keine Userupdates in A, kein Sinn-Merge |
| Alte Review-Sätze verschwinden | 528 archivierte Links plus Texte/Token, historische Read-only-Abfrage, keine Reviewumschreibung |
| Gespeichert, aber nie übbar | Add-Tabelle, lokaler Resolver, reservierte Storyplätze, separate explizite Lernentscheidung statt automatischer Box-0-Fortsetzung |
| Nur optischer Button/Duplikate | await Commit, Unique-Keys/Transaktion, persistierter Status, Form/Sense statt Headword |
| Heimlicher Kontextwechsel | eigener Primärzeiger nur ausdrücklich, A behält kuratierten Satz, Repeat bindet Satz |
| Drei-Sätze-Reste | zentraler Schema-2-Validator plus Liste aller betroffenen Generierungs-/Annotations-/Kurations-/Berichts-/App-Pfade; Legacy isoliert |
| Unnötige Cloudpflicht | Editorial Create/Story-Import im vorhandenen Adapter; fehlende Daten blockieren sichtbar ohne AI-Reparaturzwang |

**Keine blockierende Produktfrage für A/B.** Die konkreten Regeln oben sind Umsetzungsempfehlungen aus dem Auftrag. Eine spätere freiwillige Zusammenführung zweier schon gelernter, nachweislich identischer lokaler/kuratierter Karten bleibt außerhalb: Empfehlung, beide Verläufe bis zu einer eigenen ausdrücklichen Entscheidung erhalten. Spätere fachliche Änderungen an der begründeten Primärbedeutungswahl bleiben versionierte Inhaltsentscheidungen, keine neue Grundsatzplanung. Ein freigegebener annotierter Storydatensatz fehlt heute tatsächlich; er ist Liefer-/Abnahmevoraussetzung von B.

Die ursprüngliche Planung führte keine Builds aus. Paket A umfasst jetzt Implementierung, Offline-Export, Tests, Staging und Gerätetest auf Lernstandskopie; tatsächliche Abnahme siehe unten. Keine Cloud-Aufrufe oder Remote-Migrationen.

### Reproduzierbare read-only Auswertung

Ab Repository-Root; folgendes Pythonprogramm über stdin ausführen (keine Skriptdatei nötig):

```python
from pathlib import Path
import collections, hashlib, sqlite3
from sprachpipe.ids import form_norm
p = Path('assets/content/en/content.sqlite').resolve()
sha = hashlib.sha256(p.read_bytes()).hexdigest()
c = sqlite3.connect(p.as_uri() + '?mode=ro', uri=True)
c.execute('PRAGMA query_only=ON')
print(c.execute('SELECT version,schema_version FROM content_releases').fetchall())
for t in ('cards','sentences','card_sentences','decks','deck_cards','stories','story_sentences'):
    print(t, c.execute('SELECT count(*) FROM '+t).fetchone()[0])
print('sentences/card', c.execute('SELECT n,count(*) FROM (SELECT card_id,count(*) n FROM card_sentences GROUP BY card_id) GROUP BY n').fetchall())
g = collections.defaultdict(list)
for lang, form, cid in c.execute('SELECT lang,form,id FROM cards WHERE removed_in IS NULL'):
    g[lang, form_norm(form)].append(cid)
d = {k:v for k,v in g.items() if len(v)>1}
print('forms/groups/affected/excess', len(g),len(d),sum(map(len,d.values())),sum(len(v)-1 for v in d.values()))
for k,v in sorted(d.items()): print(k,len(v),v)
c.close()
assert hashlib.sha256(p.read_bytes()).hexdigest() == sha
print('unchanged SHA256', sha)
```

Windows PowerShell: Code in einfach zitierten Here-String (`@'` … `'@`) setzen und an `.\pipeline\.venv\Scripts\python.exe -X utf8 -` pipen. macOS Terminal: denselben Code über `pipeline/.venv/bin/python - <<'PY'` … `PY` übergeben. Windows-Auswertung tatsächlich ausgeführt, Exit 0; macOS hier nicht ausgeführt. Ergebnisse siehe Abschnitt 2.

Beide Systeme: `git diff --check`, `git diff --stat`, `git status --short`. Neuer Plan ist untracked; normales diff --stat zeigt ihn deshalb nicht, Umfang separat ausweisen. Keine Commits/Pushes.

## 10. Tatsächliche Abnahme Paket A — 04.10.2026

Implementiert und lokal als internes Pack gestagt: `single_sentence_v1`, Content-Schema 2. Direkte Stapelübungen und Revue zeigen ausschließlich 160 Primärwörter. Gemischt/Wortliste erhalten gelernte Nebenbedeutungen. Bloß angezeigte Box-0-Nebenbedeutungen bleiben gespeichert, werden aber ohne explizite Lernentscheidung nicht neu eingeführt oder als verfügbar gezählt. Die vorhandene origin-story-Ausnahme bleibt; separate Add-Persistenz ist B.

Alle 53 Doppelgruppen wurden mit vorhandenen Definitionen/Sätzen ausgewählt und in `pipeline/data/words/en.v1.json` begründet, einschließlich aller zehn verbindlichen Entscheidungen. Alle 264 festen Sätze sind in `pipeline/data/curation/single_sentence_v1.json` begründet; 35 stammen von Position 2/3. Keine neuen Sätze, Definitionen oder Modellprüfungen erfunden. `so#auf_diese_weise` bleibt kontextabhängiger Altbestand, kein Primärwort; sein vorhandener Lernstand bleibt erhalten.

```text
reproducible_transition: true
cards / preserved card IDs: 264
deck_words / active primary deck_cards: 160
preserved secondary cards / historical deck_cards: 104
active card_sentences: 264
historical card_sentences: 528
preserved sentence texts: 792
preserved sentence_tokens: 8474
SQLite readback: all rows of all 18 tables equal build_rows
lint errors: 0
AI calls: 0; AI cost: 0 USD
```

Neue Artefakte: `pipeline/out/single_sentence_v1/{pack.json,content.sqlite,finalization_report.json}`. SHA-256 der neuen SQLite-Datei: `00f99bb021499a4e2faeec832df22c2b047f79afb3d3025111a7dcf96c0fc4b9`; 4.169.728 Bytes. Gestagt nach `assets/content/en/`, Manifest nennt Version, Hash, Herkunft und internen Status. Alte out-Artefakte und redaktionelle Quellen bleiben unverändert. Rollback: `build/single_sentence_v1/rollback/{content.sqlite,content.manifest.json}`, ursprünglicher SHA-256 `bb71bd0ec9466e931500678b98c6838cf5208f67d82c6cd2cbd6f6fe3fcedf29`. Zum Asset-Rollback diese beiden gesicherten Dateien gemeinsam nach assets/content/en zurückkopieren; keine user.db verändern. Prüfprotokolle/Backups unter build und Packs unter out/assets bleiben gemäß bestehenden Ignore-Regeln lokal.

Tatsächlich ausgeführte Outputs (Windows):

```text
pytest -q pipeline/tests: 340 passed in 10.58s
flutter test: +219: All tests passed!
flutter analyze: No issues found! (ran in 2.0s)
real_pack_test.dart against staged schema 2: +1: All tests passed!
stage_content_pack.dart --verify: version single_sentence_v1, schema 2
18 table counts match finalization_report.json
SINGLE_SENTENCE_SMOKE PASS phase=first
SINGLE_SENTENCE_SMOKE PASS phase=restart
primary=160 cards=264 active_sentences=264 fixed_repeat=ok
secondary_mixed=ok display_box0=excluded archive_links=528
historical_reviews=17 preexisting_missing=2 clone_states=22
```

Logs: `build/single_sentence_v1/{python-tests.txt,flutter-tests.txt,flutter-analyze.txt,real-pack-tests.txt,staging.txt,stage-verify.txt,android-first-log.txt,android-restart-log.txt,transition-verification.json,device-verification.json}`. Fehler während Entwicklung wurden behoben: alte Testannahmen (Rotation/Schema-2-Ablehnung), acht Klammer-Stilhinweise. Der erste Gerätesmoke deckte die unten belegten zwei vorbestehenden Referenzlücken auf; der anschließende Test prüft ausdrücklich sämtliche 528 Archive und alle zuvor auflösbaren Reviews. Keine Schutzprüfung abgeschaltet.

Android `emulator-5554`: Original mit 20 user_cards und 19 Reviews vorab bytegesichert; ausschließlich eine Kopie um zwei gezielte Nebenbedeutungszustände und einen Review ergänzt. Alle bereits kopierten Tabellenzeilen bleiben feldgleich. Zweiter echter Prozessstart bestätigt den vollständigen gespeicherten Kopienzustand. Wiederholung erzeugt keinen zweiten Review. Provider belegen 160 Stapelwörter und die gelernte Nebenbedeutung in der Wortliste. Normale App aus `lib/main.dart` wieder gebaut/installiert und gestartet, keine Deinstallation. Original-user.db auch danach byteidentisch: `8bed6d7f0d05f65874c300fc90257a670bab75cbc757e93ed629d32723c3c0ad`. Kein user.db-Schemawechsel, keine SRS-Regeländerung. iOS/macOS nicht ausgeführt.

**Vorbestehender Befund, unverändert erhalten:** Zwei der 19 Gerätereviews besitzen bereits im gesicherten chat_editorial_finish_v1 keine auflösbare Satzverknüpfung. Kein zusätzlicher Verlust durch A; 17/17 zuvor verfügbare Referenzen und alle 528 neuen Archive sind lesbar. Review-ID `86a8d9af-ed08-48fd-b540-59883b8cc1a2`: Karte `0f8456704a8b09be994c320a0d22eb58`, Satz `6f88aa235d3f4bd28edbe487af7692b0`. Review-ID `bdb17e7e-b74e-4039-9e90-ad417d628612`: Karte `8c4ff8b225bdf270519c5e557737aa74`, Satz `b0f90fe8ff222c01d7a5bc47e76c8b5e`. Voller Alt/Neu-Vergleich: `build/single_sentence_v1/preexisting-review-reference-gaps.json`. Die Wortliste fällt in diesen beiden Altfällen auf den aktuellen Satz zurück; fehlende historische Texte wurden nicht erfunden und Reviews nicht umgeschrieben.

**B bleibt konkret offen:** additive user.db-v4-Migration mit separater expliziter Hinzufügen-Entscheidung und lokalen Kontexten; Token-/Sense-Identitäten bis zum Reader/Resolver; persistenter Add-Button, Box-0-Wortliste und Storypriorität in Gemischt; ein redaktionell freigegebener vollständig annotierter Storydatensatz. Create-/Story-Transport ist mit synthetischer Fixture geprüft, aber das echte App-Pack enthält weiterhin null Stories. Keine Umsetzung von B, keine Cloud-Aufrufe, Remote-Migrationen, Commits oder Pushes.

## Anhang: vollständige tatsächliche Doppelgruppen

53 Gruppen normalisierter EN-Formen, sämtlich derzeit in allgemeine-sprache. Keine Stichprobe; zusätzliche Karten sind verschiedene Lernidentitäten, nicht automatisch löschbare Duplikate.

| Form | Karten | Vorhandene Sense-Schlüssel |
|---|---:|---|
| a | 2 | `a#ein`, `a#pro` |
| about | 3 | `about#im_begriff`, `about#ueber_thema`, `about#ungefaehr` |
| all | 3 | `all#alle_det`, `all#alles_pron`, `all#vollstaendig_adv` |
| and | 2 | `and#um_zu`, `and#und` |
| are | 2 | `be#sein_hilfsverb`, `be#sein_vollverb` |
| as | 4 | `as#als_funktion`, `as#da_grund`, `as#so_vergleich`, `as#waehrend_zeit` |
| at | 4 | `at#ort`, `at#richtung`, `at#zeit`, `at#zustand` |
| be | 3 | `be#befinden`, `be#hilfsverb`, `be#sein_existieren` |
| been | 2 | `be#besucht`, `be#gewesen` |
| but | 3 | `but#aber`, `but#ausser`, `but#nur` |
| by | 4 | `by#bis_spaetestens`, `by#mit_mittel`, `by#neben_ort`, `by#von_urheber` |
| can | 2 | `can#dose`, `can#koennen` |
| do | 3 | `do#hilfsverb`, `do#reichen`, `do#tun` |
| for | 3 | `for#denn_grund`, `for#fuer_zweck_empfaenger`, `for#seit_lang_dauer` |
| from | 3 | `from#unterscheidung`, `from#ursache`, `from#von_ausgangspunkt` |
| get | 4 | `get#bekommen`, `get#gelangen`, `get#verstehen`, `get#werden` |
| had | 3 | `have#besitzen_partizip`, `have#besitzen_past`, `have#hilfsverb` |
| has | 3 | `have#besitzen`, `have#hilfsverb`, `have#muessen` |
| have | 4 | `have#besitzen`, `have#einnehmen`, `have#hilfsverb`, `have#muessen` |
| her | 3 | `her#ihr_possessiv`, `she#ihr_dativ`, `she#sie_akkusativ` |
| his | 2 | `his#sein`, `his#seiner` |
| if | 2 | `if#ob`, `if#wenn` |
| in | 3 | `in#herein_drinnen`, `in#in_raeumlich`, `in#in_zeitlich` |
| is | 2 | `be#hilfsverb`, `be#sein_vollverb` |
| it | 2 | `it#es_ding`, `it#unpersoenlich` |
| just | 4 | `just#genau`, `just#gerade_eben`, `just#gerecht`, `just#nur` |
| like | 3 | `like#fuellwort`, `like#moegen`, `like#wie` |
| me | 2 | `i#mich`, `i#mir` |
| more | 4 | `more#mehr_pronomen`, `more#mehr_steigerung`, `more#wieder_noch`, `much#mehr_menge` |
| no | 4 | `no#kein`, `no#nein`, `no#nein-stimme`, `no#nicht` |
| of | 4 | `of#genitiv_besitz`, `of#material_herkunft`, `of#teil_menge`, `of#ueber_bezug` |
| on | 4 | `on#an_eingeschaltet`, `on#an_zeitlich`, `on#auf`, `on#weiter` |
| or | 2 | `or#andernfalls`, `or#oder` |
| out | 4 | `out#erloschen`, `out#heraus_aus`, `out#hinaus`, `out#nicht_da` |
| so | 4 | `so#auf_diese_weise`, `so#deshalb`, `so#ebenfalls`, `so#so_sehr` |
| that | 4 | `that#das`, `that#dass`, `that#jener`, `that#so` |
| the | 2 | `the#bestimmter_artikel`, `the#umso` |
| there | 2 | `there#dort`, `there#es_gibt` |
| they | 3 | `they#man_leute`, `they#sie_plural`, `they#singular_they` |
| this | 2 | `this#dies_stellvertretend`, `this#dieser_begleitend` |
| time | 4 | `time#mal`, `time#stoppen`, `time#zeit`, `time#zeitlich_abstimmen` |
| to | 4 | `to#bis_zeit`, `to#fuer_empfaenger`, `to#infinitivpartikel`, `to#nach_richtung` |
| up | 3 | `up#entlang`, `up#hinauf`, `up#wach` |
| was | 2 | `be#hilfsverb`, `be#sein_vollverb` |
| were | 2 | `be#sein_vergangenheit`, `be#waere_konjunktiv` |
| what | 3 | `what#fragepronomen`, `what#relativpronomen`, `what#welcher` |
| when | 3 | `when#als_wenn`, `when#in_dem`, `when#wann` |
| which | 3 | `which#determiner_auswahl`, `which#fragepronomen`, `which#relativpronomen` |
| who | 2 | `who#der_die`, `who#wer` |
| will | 3 | `will#testament`, `will#wille`, `will#zukunft` |
| with | 4 | `with#bei`, `with#mit_eigenschaft`, `with#mittels`, `with#zusammen_mit` |
| you | 2 | `you#du_sie_ihr`, `you#man` |
| your | 3 | `your#dein`, `your#euer`, `your#ihr` |

## 11. Paket B umgesetzt und geprüft (04.10.2026)

**Ergebnis:** echte Story „The Open Pocket“ / „Die offene Tasche“ aus dem Content-Repository; Worttap liest nur, explizites Hinzufügen speichert atomar und wartet auf Commit. Bestehende exakte Karten werden wiederverwendet; neue lokale Karten haben vollständige Metadaten und einen unveränderlichen Kontext. Wortliste, Zähler und Gemischt verwenden denselben Resolver. Vollständige lokale Karten funktionieren ohne Content-Pack. Keine zweite SRS-/Antwortimplementierung, keine Kontextwahl, kein Sync.

### Pack und Redaktion
- `pipeline/data/curation/story_learning_seed_v1.json` enthält die sechs gelieferten Sätze, vollständige Tokenannotation und konkrete redaktionelle Kontextfreigaben für backpack (Satz 2) und platform (Satz 6, Bahnsteig).
- Vorhandene passende Karten bestätigt: table `253982ff9b64b28ab49f9ef47e56b2ff`, ticket `e4b05d00f7a0804f7f5e700cb1aea1cc`. Keine Content-Karten für backpack/platform; somit tatsächlich lokaler Hinzufügeweg.
- Frischer Export: `pipeline/out/story_learning_v1/pack.json`, `content.sqlite`, `finalization_report.json`; Asset `assets/content/en/content.sqlite` mit `content.manifest.json` gestagt.
- Version **story_learning_v1**, Content-Schema **2**, **4.190.208 Bytes**, SHA256 **b8231bbc7d1fe834b13ee81b901ad2d96dc06ac3dfbcdf72422718a68bb5e59b**.
- Alle 264 Karten, 792 Satzlinks (264 aktiv, 528 historisch), 264 historische Stapelzuordnungen und 160 Eigentümerplätze unverändert. Alle bisherigen 792 Sätze/8474 Token erhalten; nun 798 Sätze/8532 Token, 1 Story mit 6 Satzlinks. Sechs neue Lemmas, acht neue Senses/Formglossen. Vollständiger Zeilenvergleich in `build/story_learning_v1/transition-verification.json`.
- Freigabe ist redaktionelle Chat-Zulieferung für interne Tester; keine behauptete menschliche/externe Modellprüfung. Modellaufrufe **0**, Kosten **0 USD**. Nicht alle Story-Wörter sind als neue lokale Lernkontexte freigegeben: ohne passende Karte oder geprüften Kontext bleibt Add verständlich gesperrt.

### Persistenz und Konflikte
`user.db` v4 ergänzt lokale Metadaten, `card_contexts`, `story_learning_additions`, `story_word_sources`, `learning_identity_bindings`. Optionale Repository-Fähigkeiten stehen in `domain/story_learning.dart`; bestehende Content-/User-Schnittstellen bleiben verwendbar. Kontext-/Review-Trigger verhindern Umschreiben/Löschen. Exakte Sprache/Form/Sense bindet Identitäten, nicht die Übersetzung. Ein späterer Content-Gegenpart wird nicht automatisch neu eingeführt; zwei vorhandene Zustände bleiben getrennt mit sichtbarem Hinweis. Nicht auflösbare alte Zustände erscheinen als Inhaltsbefund, ohne erfundene Worttexte.
Explizite Story-Box-0-Karten stehen nach fälligen Karten vor dem automatischen 4:1-Mix. Vielfalt gilt für neue Karten pro Sitzung, nicht als dauerhafter Ausschluss vorhandener Box-0-Zeilen. Kein Stapelschalter/-besitz wird beim Add geändert.

### Tatsächlicher Prüfoutput
```text
python -m pytest -q pipeline/tests: 345 passed in 12.11s
flutter test: +235: All tests passed!
flutter analyze: No issues found! (ran in 2.1s)
dart run build_runner build: Built with build_runner/aot in 12s; wrote 148 outputs.
flutter test test/data/real_pack_test.dart: +1: All tests passed!
pack story_learning_v1 (schema 2, internal: true); deck "Allgemeine Sprache":
160 cards, 264 card sentences, 34 with valid_alternatives, 264 cards in the pack
stage_content_pack.dart --verify: verified; 18 table counts match finalization_report.json
PRAGMA integrity_check: ok; PRAGMA foreign_key_check: []
```
Protokolle: `build/story_learning_v1/` (`python-test.txt`, `flutter-test.txt`, `analyze.txt`, `codegen.txt`, `real-pack-test.txt`, `staging.txt`, `stage-verify.txt`). Synthetische Tests prüfen Transaktionsrollback, parallelen Doppeladd, andere Story, Form/Sense-Unterscheidung, spätere Gegenkarte/Konflikt, deaktiviert/retiriert, Migration ab v1/v2/v3, Prozess-/Dateineuöffnung, gleiche Wortvorkommen nach Emoji mit Codepoint→UTF-16, Add-Lade-/Fehlerzustände und lokalen Controller ohne Pack. Der echte Pack-Widgettest prüft Reader → Table/Backpack → Box-0-Wortliste/Zähler.

### Android-Gerätebefund, getrennt von Fixtures
Auf Android-Emulator `emulator-5554` ausgeführter temporärer Probe-Einstieg verwendete **das echte gestagte Pack und eine Kopie** der Original-user.db (`files/story_learning_v1_smoke/user.db`). Die automatisierten Geräteschritte nutzen Produktions-Repositories, Story-Service und Gemischt-Controller; UI/Lookup/Wortliste wurden zusätzlich am Emulator geöffnet und visuell geprüft. Dies ist keine iOS-Prüfung und keine ausschließlich manuelle Tap-Abnahme.
1. Table-Übersetzungsabfrage schreibt nichts; Doppeladd erzeugt eine Entscheidung, deaktivierter Eigentümerstapel bleibt deaktiviert. Karte und alter Übungssatz `7d5a6e37c575acc6f3d270e26e22e29b` bleiben erhalten. Beide neuen Entscheidungen sind in Wortliste und Gemischt erreichbar.
2. Backpack erzeugt lokale Karte `u:94206413fbee9311f38ddac676f11e0fdebd8904fd0a2a97168bbd1142070ccd`, Box 0, keine Reviews, genau den freigegebenen Satz 2. Kontext-ID auf dieser Testkopie: `836f5b21-cf03-4f99-8298-23bedf4778f0`.
3. Vollständiger App-Prozessneustart erhält Karte/Box/Kontext. Zur Isolation wurden nur auf der Kopie die anderen Karten deaktiviert. Normaler Gemischt-Controller: `backpak` bleibt unvollständig, `backpack` bucht exakt einen Review mit Box 3 und derselben Kontext-ID. Erneuter Add erzeugt keinen weiteren Review.
4. Der Fall gleicher Schreibweise mit verschiedenen Bedeutungen ist durch Repository-/Domain-Tests abgedeckt; dafür wurde keine weitere echte Story erfunden und keine solche Geräteabnahme behauptet.
Geräteoutput: `device-verification.json`, `android-first-log.txt`, `android-restart-log.txt`; Aufnahmen `backpack-added.png`, `word-list-box0.png` in `build/story_learning_v1/`. Zwei Prüf-APKs/Buildprotokolle (temporärer Einstieg und normaler `lib/main.dart`). Normaler Einstieg wieder installiert; keine Deinstallation/Datenrücksetzung.

### Originaldaten und Rollback
Während der Kopientests Original-user.db byteidentisch, SHA256 `8bed6d7f0d05f65874c300fc90257a670bab75cbc757e93ed629d32723c3c0ad`. Nach Wiederherstellung und Start der normalen App erwartete additive Migration 3→4: alle alten Spaltenwerte in 20 Kartenständen/19 Reviews, Einstellungen und Schutztrigger exakt erhalten, neue Story-Tabellen leer. Danach SHA256 `65549da8680f42a8d16ec88a0d19c5e2e854bc55269ef60bf6c67629aff32709`; Nachweis `original-preservation.json` und `user_before.db`/`user_after.db`. Die zwei bereits in Abschnitt 10 dokumentierten alten fehlenden Satzreferenzen bleiben Altbefunde.
Assetrollback von single_sentence_v1 unter `build/story_learning_v1/rollback/`. Keine alten out-Artefakte überschrieben; keine Cloud-Aufrufe, Remote-Migration, Commits oder Pushes. `git diff --check` ohne Fehler; `git status --short` zeigt lokale Änderungen einschließlich des erhaltenen Paket-A-Arbeitsstands.

### Manuelle Kontrolle
Story „The Open Pocket“ über Home oder Stories öffnen → **backpack in Satz 2** antippen → „Zum Lernen hinzufügen“ → „Bereits hinzugefügt“ abwarten → Wortliste („Ungelernt“) → Gemischt. Table folgt demselben Weg mit seiner vorhandenen Karte; ein deaktivierter Eigentümerstapel verhindert diese explizite Lernentscheidung nicht. Priorität in Gemischt: zuerst vorhandene fällige Karten, dann die neuen Story-Wörter. Vorhandene normale Lernstände nicht für Testübungen verwenden; der dokumentierte Gerätetest nutzt die separate Kopie.

## Ergänzung Lerngruppen v1 (06.10.2026)
Content-Schema 3 ergänzt `cards.learning`; Schema 1/2 bleibt lesbar. `LearningGroups` in der reinen Domain projiziert Einführung und Fortschritt über alle Quellen. `PracticeItemResolver` ordnet lokale Karten nur anhand exakter Identitäten zu; beide Drift-Repositories transportieren die Metadaten beziehungsweise verwenden sie beim atomaren Story-Add. Bestehende gelernte Gruppenmitglieder bleiben eigenständige Reviewziele. Gemeinsame Auswahl verteilt neue Themen, die Session behält ihre einmalige Reihenfolge. Satzbezogene geprüfte Synonyme sind neutrale erneute Versuche; keine user.db-Migration. Verbindliche Regeln und Tests: `docs/learning-groups-v1.md` (im docs-Ordner: `learning-groups-v1.md`).
