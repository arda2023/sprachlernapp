# Menschen & Beziehungen – Authoring-Vorbereitung

Stand: 10.10.2026. **245 eigenständige Lernziele** aus 295 geprüften Kandidaten; 50 Ausschlüsse. Drei Batches **82 / 82 / 81**, jeweils mit allen acht Themen. Keine Sätze erzeugt, kein Import oder Staging.

Geprüfte ZIP: `build/menschen_beziehungen_authoring_batch_1.zip`.
Absoluter Pfad: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/menschen_beziehungen_authoring_batch_1.zip`.
ZIP-SHA256: `54695ffb5b0cf4cdab3a046d8b62e2c0502e3270ef4419025475184a0e542249`.
81 Dateien einschließlich Manifest; 80 Nutzdateihashes, ZIP-CRCs und alle 18 SQLite-Tabellen zweimal nach erneutem Öffnen geprüft. Partition: **0 importiert / 82 aktuell / 163 später**.

## Basis und Schutzumfang

- Basis: `pipeline/out/arbeit_bildung_batch_3_v1/pack.json`, Schema 3, 1250 Karten und 1135 primäre Lernziele: 160 Allgemeine Sprache / 489 Reisen / 241 Alltag & Zuhause / 245 Arbeit & Bildung.
- Basis-Pack-SHA256: `d170e0ca41784fae6e888043b53e53af6ba0e5288b79ad1f91fd3e9f0983b3ba`.
- Basis-SQLite und unverändertes App-Asset: `4239a32d45354539ce5aee74a61ec8ed7ac20d39902ff060f2a0bc94e1fcaa91`.
- 1146 bisherige Wortreservierungen und sämtliche 1250 Karten-Gruppenbindungen aus der tatsächlichen Basis übernommen. 1238 Bestandsgruppen; 245 neue unabhängige Köpfe ausschließlich reserviert.
- 1414 von 1415 gesicherten Ausgangsdateien byteidentisch; einzig NEXTSTEPS.md aktualisiert. Historische Auswahlen/Registrys/Gruppen, Packs, Assets, App- und Pipelinecode unverändert.
- Keine echte user.db, Lernstände oder review_log geöffnet; keine Cloud-/Modellaufrufe, Veröffentlichung, Commits oder Pushes. Keine Flutter-Tests, weil App und Assets unverändert sind.

## Neue Snapshots und Verträge

- `pipeline/data/selection/menschen_beziehungen_v1.json`: alle 245 Identitäten, Definitionen, Originalpositionen, Batchnummern, Reviews, Wörterbuchbelege und 50 Ausschlüsse.
- `pipeline/data/words/en.menschen_beziehungen_v1.json`: 1391 Reservierungen, davon 1146 unveränderte Altzeilen und 245 neue für `menschen-beziehungen`.
- `pipeline/data/learning_groups/en.menschen_beziehungen_v1.json`: exakte Bestandsprojektion aus cards.learning und 245 reservierte Einzelköpfe.
- Titel: Menschen & Beziehungen. Alle Quellen-/Parent-/Registry-/Gruppenhashes validiert; bestehende `bind_new_pack`, `index_registry`, `validate_selection`, `partition_selection`, `validate_learning`, `build_rows` und `validate_context` unverändert verwendet.
- 115 Substantive, 60 Verben, 70 Adjektive. Keine zusätzliche gelernte Form, gelernte Lemma-/Sense-Bindung oder Satzalternative reserviert. Keine Plural-/Zeitformkarten. Lexikalisierte Gefühlsadjektive sind eigenständige ADJ-Ziele, keine weiteren Flexionen vorhandener Verbkarten.

## Themen und Batches

| Thema | Gesamt | Batch 1 | Batch 2 | Batch 3 |
|---|---:|---:|---:|---:|
| Familie und Verwandtschaft | 31 | 11 | 10 | 10 |
| Freundschaft und soziale Kontakte | 27 | 9 | 9 | 9 |
| Gefühle und Stimmungen | 33 | 11 | 11 | 11 |
| Persönlichkeit und Verhalten | 34 | 11 | 12 | 11 |
| Gespräche und gegenseitiges Verständnis | 33 | 11 | 11 | 11 |
| Partnerschaft und Nähe | 25 | 8 | 8 | 9 |
| Konflikte, Grenzen und Versöhnung | 29 | 10 | 10 | 9 |
| Unterstützung, Vertrauen und Zusammenleben | 33 | 11 | 11 | 11 |
| **Gesamt** | **245** | **82** | **82** | **81** |

Die Originalpositionen 1–295 wurden über Themen verschränkt und vor Ausschlüssen vergeben. Die 245 gewählten Positionen behalten die Ausschlusslücken. Authoring-Batches enthalten je Thema 8–12 Ziele. Batches und Anzeige sind keine Vorgabe für die Laufzeit-Lernreihenfolge.

Batch 1 verwendet Display 1–82. Geprüfte reine Mitgliedschaftssimulation: Batch 2 hängt 83–164 an und ordnet per bestehendem hashgebundenem Display-Patch auf 1–164; Batch 3 hängt 165–245 an und ordnet auf 1–245. Originalidentitäten, Definitionen und Registry-Positionen bleiben gleich. Die Simulation erzeugt keine Karten oder Sätze und wird nicht als Pack exportiert.

Die drei neuen Dateien sind der Initialsnapshot. Echte Fortsetzungssnapshots entstehen erst nach dem jeweiligen Satzimport gegen dessen tatsächlichen neuen Pack: `menschen_beziehungen_batch_2_context_v1` beziehungsweise `menschen_beziehungen_batch_3_context_v1` in selection/, words/ (Präfix en.) und learning_groups/ (Präfix en.). Keine vorgetäuschte Importbasis für spätere Batches angelegt. Die erste ZIP enthält bereits alle 245 Identitäten und alle drei kumulativen Anzeigemappings.

## Redaktionelle Entscheidungen

Alle Zieldefinitionen, Übersetzungen und Abgrenzungen wurden gegengelesen; dies ist keine unabhängige menschliche Sprachfreigabe. 245 statt erzwungener 250: nahe Synonyme und bereits vertretene Lernabsichten bleiben ausgeschlossen. 36 passende Wörterbuch-Senses werden exakt wiederverwendet; 209 tatsächlich fehlende Lemma-/POS-/Sense-Bindungen sind neu definiert.

- Wiederverwendete breite Bedeutungen werden nicht wegen eines neuen Satzkontexts aufgespalten: etwa belong, hurt, depend, feel und love. Historische flektierte Glossen bleiben unverändert; neue Lernübersetzungen stehen getrennt an den Zielkarten.
- club: alter Nachtclub-Beleg versus neue organisierte Interessengruppe/Verein. recognise: vorhandene offizielle Abschlussanerkennung versus Wiedererkennen. single: Einzelbett versus Beziehungsstatus. distant: räumliche/genealogische Entfernung versus emotionale Distanz. point: Prüfungspunkt versus Aussagekern.
- kind ist historisch trotz adjektivischem Beleg als NOUN geführt, relieved als VERB. Neue korrekt typisierte ADJ-Bindungen werden reserviert; alte Zeilen nicht repariert oder umetikettiert. Beide historischen Senses haben keine bestehende Lernkarte.
- Vier exakt gleiche deutsche Kartenglossen wurden anhand der Bedeutung getrennt: assume/accept (für wahr halten/Angebot annehmen), calm/quiet/peaceful (innere Ruhe/äußere Ruhe), couple/pair (Paarbeziehung/Zweierpaar von Dingen), deserve/earn (Anspruch/Geldverdienen). Keine reine Glossenumbenennung.
- alone/lonely: ohne Gesellschaft versus subjektiv einsam. ashamed/embarrassed/guilt/regret: Selbstbewertung, soziale Verlegenheit, Schuldgefühl und Bedauern. anxious/afraid: ungewisse Besorgnis versus Furcht; nervous nicht zusätzlich.
- sibling/grandparent entfallen neben brother/sister beziehungsweise grandfather/grandmother; konkrete Stief- und Schwiegerrollen sind neue Verwandtschaftsbeziehungen. boyfriend/girlfriend entfallen neben partner. Familie enthält auch adoptive/biological und verschiedene Lebensphasen; keine Geschlechts-/Schreibvariante zum Auffüllen.
- consent betrifft freiwillige Zustimmung der betroffenen Person; permission entfällt neben permit. breakup beendet die Paarbeziehung, divorce ist die rechtliche Eheauflösung. forgive kann einseitig sein, reconcile stellt die Beziehung wieder her, compromise erfordert Zugeständnisse.
- rival ist ein Konkurrent ohne notwendige Feindschaft, enemy feindlich gesinnt. blame weist Verantwortung zu, accuse behauptet eine Tat. bully beinhaltet wiederholte Machtasymmetrie, fight körperliche Auseinandersetzung; allgemeiner conflict/quarrel entfällt neben argument.
- empathy versteht fremdes Erleben, sympathy nimmt am Leid Anteil. comfort lindert Kummer, reassure nimmt Befürchtungen, encourage gibt Handlungsmut. support/rely/console entfallen neben help/assist, trust beziehungsweise comfort.
- self-esteem ist eigener Personenwert, confidence Zutrauen in Fähigkeiten; equality gleiche Rechte, just/fair gerechte Behandlung. respect achtet Würde/Rechte, appreciate schätzt einen Beitrag wert. Diese Unterschiede sind als Reviews und Kontrasttags in der Auswahl gespeichert.

Frequenz dient als Prüfsignal, nicht als automatische Bedeutungsentscheidung. 17 Zielformen liegen bei wordfreq 3.1.1 unter Zipf 3,5: reassure 3,3, ancestor 3,49, homesick 2,93, upbringing 3,43, stepmother 3,16, stepfather 3,24, stepchild 2,19, betray 3,42, chore 3,15, impulsive 3,27, grudge 3,33, newcomer 3,4, pessimistic 3,25, possessive 3,17, adoptive 3,22, rumour 3,38, exaggerate 3,19. Sie bezeichnen gebräuchliche Familienrollen, Gefühle und Handlungen; keine Fachbegriffe als Auffüllung. Die Satzkontextprüfung mit ihrer Zipf-Grenze folgt erst bei der Redaktion; keine CEFR-Zertifizierung behauptet.

Sieben Schreibaliasse reserviert: recognise/recognize, neighbourhood/neighborhood, rumour/rumor, favour/favor, wellbeing/well-being, breakup/break-up, barbecue/barbeque. Sechs nicht separat reservierte Synonymkandidaten: nervous, modest, faithful, console, smart, flatmate. Zusammen 258 eindeutige geplante Formen; keine Kollision mit bestehenden Formen, Aliassen, Satzalternativen, Wörterbuchformen an gelernten Senses oder den 13 historischen Wortregistrys. Keine dieser Varianten ist automatisch eine gültige Satzantwort; accepted und valid_alternatives entstehen erst satzbezogen bei der Redaktion.

## Alle Ausschlüsse

| Kandidat | Entscheidung |
|---|---|
| sibling | Geschlechtsneutraler Oberbegriff zu den bereits eingeführten brother/sister; keine weitere Geschwister-Lernposition. |
| conflict | Bestehendes argument deckt die zwischenmenschliche Auseinandersetzung ab; keine abstrakte Dublette. |
| support | Bestehende Gruppe help/assist umfasst Hilfe in schwierigen Lagen; nicht künstlich auf emotionale Hilfe abspalten. |
| clarify | Für diese Auswahl zu nah an bestehendem explain; keine künstliche Erklärungsteilbedeutung. |
| romance | Für diesen Stapel zu nah an love/relationship; keine zusätzliche romantische Beziehungsvariante. |
| boyfriend | Paarpartner bereits durch partner vertreten; keine weitere geschlechtsspezifische Variante ohne Ehestatus. |
| girlfriend | Paarpartner bereits durch partner vertreten; keine weitere geschlechtsspezifische Variante ohne Ehestatus. |
| chat | Informelles Sprechen bereits durch speak/conversation abgedeckt; keine zusätzliche Gesprächsvariante. |
| upset | Breiter emotionaler Sammelbegriff neben sad/angry/frustrated; keine weitere unscharfe Gefühlsaufgabe. |
| separate | Beziehungsende bereits durch gewähltes breakup; keine zusätzliche Verbalvariante. |
| gathering | Allgemeines Treffen neben meeting und den gewählten konkreten sozialen Anlässen nicht zusätzlich reserviert. |
| fiancé | Verlobtenrolle nicht zusätzlich zum gewählten engagement; keine Schreib-/Geschlechtsvarianten als neue Ziele. |
| cope | Schwierige Anforderungen bewältigen bereits über manage vertreten. |
| fair | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| praise | Überlappt ausgewähltes compliment als positive persönliche Äußerung; konservativ nur ein Ziel. |
| join | Als mitmachen/teilnehmen bereits zu nah an attend; keine auf Vereinsbeitritt verengte Ersatzdefinition. |
| acknowledge | Bestätigen/Anerkennen überschneidet sich mit confirm und dem ausgewählten appreciate; keine neue Teilaufgabe. |
| defend | Überschneidet sich in der Schutzabsicht mit protect; nur protect gewählt. |
| reconnect | Erneute Kontaktaufnahme neben contact; konservativ keine eigene Wiederholungsvariante. |
| hopeful | Für diese Auswahl zu nah an optimistic; keine zusätzliche positive Erwartungseigenschaft. |
| introduce | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| exclusive | Im Beziehungskontext entbehrliche Einschränkung neben commitment/consent; keine eng erfundene Zieldefinition. |
| contact | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| quarrel | Streiten bereits über argument vertreten. |
| family | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| companion | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| faithful | Überschneidung mit ausgewähltem loyal; keine zweite Treueeigenschaft. |
| reject | Ablehnen bereits über refuse vertreten. |
| willing | Zu nah am bestehenden breit glossierten ready; keine allein aus dem Reisesatz abgeleitete künstliche Bedeutungsgrenze. |
| relative | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| cuddle | Überlappt bestehendes hug; keine zusätzliche Umarmungsaufgabe. |
| apology | Entschuldigung bereits über apologise vertreten; keine zusätzliche Nominalisierung. |
| help | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| parent | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| permission | Bestehendes permit umfasst ausdrücklich offizielle Erlaubnis; keine weitere allgemeine Erlaubnisaufgabe. |
| rely | Sich auf jemanden verlassen bereits über trust vertreten. |
| infant | Überlappt baby; keine zweite Säuglingsaufgabe. |
| sincere | Überschneidung mit bestehendem honest; kein Ersatz durch umbenannte Glosse. |
| reply | Antworten bereits durch answer vertreten. |
| console | Überlappt ausgewähltes comfort im Trostkontext. |
| grandparent | Oberbegriff zu grandfather/grandmother; keine zusätzliche Großelternaufgabe. |
| modest | Überlappt ausgewähltes humble in der persönlichen Bescheidenheit. |
| advice | Rat/Empfehlung bereits durch recommendation abgedeckt. |
| nervous | Überlappt das ausgewählte anxious im alltagsbezogenen Besorgniskontext. |
| patient | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| confess | Überlappt ausgewähltes admit im Eingeständniskontext. |
| grow | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| delighted | Freudige Intensitätsvariante neben happy; kein weiteres Ziel. |
| reliable | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| miserable | Starke negative Stimmung neben sad; keine Intensitätsauffüllung. |

## Vollständige Auswahl nach Themen

**Familie und Verwandtschaft**: adult, teenager, toddler, boy, girl, man, woman, ancestor, generation, birth, childhood, parenthood, upbringing, stepmother, stepfather, stepchild, mother-in-law, father-in-law, sister-in-law, brother-in-law, daughter-in-law, son-in-law, adopt, orphan, biological, adoptive, age, pregnant, widow, death, alive.

**Freundschaft und soziale Kontakte**: friendship, acquaintance, stranger, guest, host, welcome, greet, social, community, club, member, reunion, party, barbecue, meet, recognise, interact, popular, outsider, newcomer, belong, invitation, event, neighbourhood, farewell, reputation, casual.

**Gefühle und Stimmungen**: emotion, mood, happy, sad, angry, afraid, anxious, calm, excited, lonely, homesick, bored, disappointed, relieved, proud, ashamed, embarrassed, jealous, grateful, frustrated, overwhelmed, regret, guilt, grief, surprise, disgust, nostalgia, feel, relax, alone, wish, stress, hate.

**Persönlichkeit und Verhalten**: kind, generous, selfish, shy, outgoing, rude, humble, stubborn, lazy, brave, sensitive, sensible, thoughtful, impatient, loyal, tolerant, mature, gentle, careful, impulsive, greedy, arrogant, optimistic, pessimistic, funny, personality, habit, attitude, intention, curious, serious, clever, open-minded, determined.

**Gespräche und gegenseitiges Verständnis**: communicate, interpret, assume, imply, hint, tone, gesture, expression, nod, whisper, shout, joke, tease, compliment, criticism, admit, deny, insist, detail, point, context, perspective, secret, rumour, truth, lie, exaggerate, formal, doubt, hesitate, aware, notice, expect.

**Partnerschaft und Nähe**: love, affection, attraction, relationship, couple, single, marry, divorce, engagement, bride, groom, anniversary, commitment, intimacy, consent, mutual, flirt, compatible, meaningful, distant, lifelong, propose, breakup, honeymoon, ex.

**Konflikte, Grenzen und Versöhnung**: blame, accuse, insult, forgive, reconcile, boundary, confront, avoid, ignore, threaten, bully, abuse, hurt, violence, manipulate, control, protect, betray, revenge, grudge, tension, awkward, possessive, punish, pressure, fight, cheat, rival, enemy.

**Unterstützung, Vertrauen und Zusammenleben**: care, comfort, encourage, reassure, empathy, sympathy, depend, volunteer, charity, donation, favour, burden, recover, wellbeing, equality, household, roommate, chore, contribute, sacrifice, balance, diversity, dignity, vulnerable, resilient, solidarity, promise, owe, repay, deserve, appreciate, thank, self-esteem.

## Ausgeführte Prüfungen

Interpreter macOS: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/pipeline/.venv-macos/bin/python` (Python 3.13.15). Windows-PowerShell-Entsprechung: `.\pipeline\.venv\Scripts\python.exe`. In den folgenden Befehlen steht `PYTHON` für den jeweiligen Interpreter; Repository-Root als Arbeitsverzeichnis.

```text
PYTHON build/menschen_beziehungen_checks/prepare.py
PASS: 245 selected, 50 excluded; 82/82/81; all 8 topics per batch
PASS: index_registry, validate_selection, partition_selection, validate_learning, build_rows, validate_context
Exit 0
PYTHON build/menschen_beziehungen_checks/final_review.py
PASS full editorial review: 245 targets, 50 exclusions; 4 exact German-gloss overlaps resolved by meaning; no open binding.
Exit 0
PYTHON build/menschen_beziehungen_checks/audit.py
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2252, 'senses': 3510, 'cards': 1250, 'dictionary_forms': 4002, 'decks': 4, 'deck_cards': 1250, 'deck_words': 1146, 'word_aliases': 15, 'sentences': 1784, 'sentence_tokens': 19121, 'card_sentences': 1778, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
BATCH 1 partitions {'imported': 0, 'current': 82, 'future': 163} display 1..82 topics 8
BATCH 2 partitions {'imported': 82, 'current': 82, 'future': 81} display 1..164 topics 8
BATCH 3 partitions {'imported': 164, 'current': 81, 'future': 0} display 1..245 topics 8
PASS membership-only display simulation batch 2 append 83..164 display 1..164
PASS membership-only display simulation batch 3 append 165..245 display 1..245
PASS 295 candidates / 245 selected / 50 excluded; 1146 old owners and 1250 old group members preserved; zero generated sentences
PASS original identities, positions and definitions immutable across all 3 batches; base SQLite and asset hash unchanged
Exit 0
PYTHON -m pytest pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
68 passed, 19 subtests passed in 2.19s
Exit 0
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/menschen_beziehungen_v1.json --batch 1 --out build/menschen_beziehungen_checks/staging/menschen_beziehungen_authoring_batch_1.zip
export: PASS; files: 81
Exit 0
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/menschen_beziehungen_checks/staging/menschen_beziehungen_authoring_batch_1.zip
zip_verification: PASS; hashed_files: 80; sqlite_tables: 18; sqlite_cards: 1250
Exit 0
```

Erst nach dieser Prüfung wurde die vollständig geschlossene ZIP auf den endgültigen Pfad verschoben. Anschließend:

```text
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/menschen_beziehungen_authoring_batch_1.zip
zip_verification: PASS
zip_sha256: 54695ffb5b0cf4cdab3a046d8b62e2c0502e3270ef4419025475184a0e542249
hashed_files: 80; sqlite_tables: 18; sqlite_cards: 1250
Exit 0
git diff --check
Exit 2: vorhandene CRLF-/Whitespace-Altbefunde
git -c core.whitespace=cr-at-eol diff --check
Exit 2: sieben unveränderte Altbefunde in DESIGN.md und drei alten Import-/Fortsetzungsberichten
git status --short
Exit 0; vollständiger Zustand in build/menschen_beziehungen_checks/git-status-after.txt
```

Eigene Änderungen wurden gegen die gesicherte Ausgangsdatei beziehungsweise /dev/null separat geprüft: keine Whitespace-Befunde. `git diff --no-index --check` liefert dabei Exit 1 für unterschiedliche Dateien, ohne Fehlerdiagnostik; der prüfende Wrapper Exit 0. Keine Bereinigung der Altbefunde.

Prüfoutput, Ausgangshashes, Original-NEXTSTEPS, Redaktionstabelle und auftragsspezifische Hilfsskripte liegen unter `build/menschen_beziehungen_checks/`; keine neue generische Testsuite. Ein zunächst langsamer Vorbereitungslauf wurde vor Dateiausgabe abgebrochen und die lokale Wörterbuchsuche indiziert. Danach wurden zwei fehlende Redaktionsnotizen (bored/farewell) ergänzt; die endgültige Vorbereitung und alle Inhaltsprüfungen bestanden. Kein Vertragscheck umgangen, kein Exporter geändert.

## Nächster Schritt

Satzredaktion im Chat anhand der geprüften Batch-1-ZIP: nur die 82 aktuellen Ziele aus authoring_context.json, genau ein fester Satz je Karte, vollständige Annotation und einzeln geprüfte Alternativen. Die übrigen 163 Ziele bleiben reserviert. Noch kein Content-Import oder App-Staging für Menschen & Beziehungen.
