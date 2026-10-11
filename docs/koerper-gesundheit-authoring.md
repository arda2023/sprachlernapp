# Körper & Gesundheit – Authoring-Vorbereitung

Stand: 10.10.2026. **249 neue eigenständige Lernziele** aus 427 geprüften Kandidaten; 178 Ausschlüsse. Drei Gruppen mit **83 / 83 / 83** Zielen, jeweils alle acht Themen. Keine neuen Übungssätze oder Tokenannotationen, kein Import und kein App-Staging.

Geprüfte ZIP: `/Users/ardasayar/Documents/FlutterProjekte/sprachapp/build/koerper_gesundheit_authoring_batch_1.zip`.

ZIP-SHA256: `170835257fa241e2f48948225fea6158c147a14eeb7d0bb077e83ce58e59188b`.
81 Dateien einschließlich Manifest; 80 Nutzdateihashes, sämtliche CRCs und Referenzen sowie alle Zeilen aller 18 SQLite-Tabellen nach erneutem Öffnen geprüft. Nach Verschieben auf den endgültigen Pfad ein zweites Mal bestanden. Partition: **0 importiert / 83 aktuell / 166 später**.

## Ausgangsbasis und Bestandsschutz

- `menschen_beziehungen_batch_3_v1`, Schema 3: 1495 Karten, 1380 primäre Lernziele in fünf Stapeln (160 / 489 / 241 / 245 / 245). Finalization-Report mit Status `ok`, Tabellenzahlen und SQLite-Hash bestätigt.
- Pack-SHA256: `080e7948e77552d3055b7569032f164c2d6c92640287a8622ced5a29a8cc2855`.
- SQLite-/App-Asset-SHA256: `9811bf3e0aa71b44d01e66a872b9a0981fd82e990f47571cd1e56ba2cd79a388`.
- 1391 bestehende Wortbesitzzeilen und 1495 Gruppenmitgliedschaften (1483 Gruppen über alle Karten) exakt übernommen. 249 neue Einzelköpfe nur reserviert; neue Registry insgesamt 1640 Wörter.
- Alle 16 historischen Wortregistrys, Kartenformen, Schreibaliasse, Satzalternativen und Wörterbuchformen an bereits gelernten Senses geprüft. Alte Gruppenentscheidungen und Besitzer bleiben unverändert.
- Ausgangsstatus und 1825 Datei-Hashes gesichert. Nach Abschluss sind 1824 Ausgangsdateien byteidentisch; allein NEXTSTEPS.md aktualisiert. Alle alten Packs, Registrys, Auswahlen, Gruppen, App-Assets und App-/Pipelinequellen unverändert.
- Keine echte user.db oder review_log gelesen, keine Lernstände verändert. Keine Cloud-/Modellaufrufe, Supabase-Aktionen, Commits oder Pushes. Flutter-Tests entfallen, da App und Assets unverändert sind.

## Neue Dateien und Vertrag

- `pipeline/data/selection/koerper_gesundheit_v1.json`: 249 stabile Identitäten mit deutschen Zielbedeutungen und expliziten englischen `target_definition_en`, Originalpositionen, drei Batches, Wörterbuchevidenz, Kontrastentscheidungen und 178 begründeten Ausschlüssen.
- `pipeline/data/words/en.koerper_gesundheit_v1.json`: separate Reservierung für `koerper-gesundheit`, unveränderter historischer Präfix.
- `pipeline/data/learning_groups/en.koerper_gesundheit_v1.json`: exakte Bestandsprojektion plus 249 reservierte Einzelköpfe.
- Dieser Bericht und NEXTSTEPS.md; Prüfskripte, Redaktionstabelle, Ausgangshashes und Logs ausschließlich unter `build/koerper_gesundheit_checks/`.
- `stable_id`, `bind_new_pack`, `index_registry`, `validate_selection`, `partition_selection`, `validate_learning`, `build_rows`, `validate_context` und der Exporter unverändert wiederverwendet. Keine Pipeline-Neuentwicklung.
- Bestehende Sense-Zeilen bleiben vollständig unverändert, auch bei historischen flektierten Glossen oder fehlender definition_de. Die präzise neue Zielbedeutung steht getrennt davon. Neue Senses haben explizite deutsche Definitionen; alle Ziele zusätzlich eine englische Definition.
- 150 Substantive, 60 Verben, 39 Adjektive. tweezers ist das lexikalisierte Pluralwort Pinzette, kein zusätzliches Flexionsziel eines vorhandenen Wortes. x-ray ist eine reguläre Bindestrichform; künstliche Formen wie blood-pressure wurden nicht reserviert.

## Themen und drei Gruppen

| Thema | Gesamt | Batch 1 | Batch 2 | Batch 3 |
|---|---:|---:|---:|---:|
| Körperteile und Organe | 49 | 17 | 16 | 16 |
| Sinne und körperliche Wahrnehmung | 32 | 10 | 11 | 11 |
| Bewegung und körperliche Fähigkeiten | 31 | 11 | 10 | 10 |
| Beschwerden und häufige Erkrankungen | 31 | 10 | 11 | 10 |
| Arztbesuch und Untersuchung | 29 | 10 | 9 | 10 |
| Behandlung, Pflege und Genesung | 27 | 9 | 9 | 9 |
| Schlaf, Erholung und Wohlbefinden | 25 | 8 | 9 | 8 |
| Verletzungen, Erste Hilfe und Hilfsmittel | 25 | 8 | 8 | 9 |
| **Gesamt** | **249** | **83** | **83** | **83** |

Originalpositionen wurden vor Ausschlüssen über die Themen verschränkt (1–427); die 249 gewählten Positionen behalten ihre Lücken und bleiben unveränderlich. Batch 1 hat Display 1–83. In der reinen Mitgliedschaftssimulation hängt Batch 2 auf 84–166 an und ordnet auf 1–166; Batch 3 hängt auf 167–249 an und ordnet auf 1–249. IDs, Definitionen und Originalpositionen ändern sich dabei nicht. Keine neuen Karten, Sätze oder Packdateien aus der Simulation erzeugt.

Die ZIP enthält alle 249 Identitäten und alle drei kumulativen Anzeigemappings. Echte Fortsetzungssnapshots werden erst nach dem jeweiligen Import gegen dessen tatsächliche neue Basis erstellt. Authoring-Reihenfolge und Displaypositionen bestimmen nicht die gruppenbewusste Laufzeit-Lernreihenfolge.

## Bedeutungen und redaktionelle Entscheidungen

**42 vorhandene Senses wiederverwendet, 207 neu definiert.** 249 statt einer erzwungenen runden Zahl: grip entfällt neben dem vorhandenen Halten, therapy neben treatment. Die Auswahl priorisiert Körperbenennung, alltägliche Beschwerden, Bewegungen und praktische Kommunikation bei Untersuchung/Behandlung. Kein seltenes Fachwort wurde zum Erreichen von 250 ergänzt.

- tired besitzt nur Wörterbuchbelege und kein bestehendes Lernziel, keine Reservierung und keine Gruppe. tired#muede wird wiederverwendet. pain und bandage sind dagegen vorhandene Ziele und bleiben ausgeschlossen.
- Gleiche deutsche Glossen sind kein Synonymbeweis: examine untersucht körperlich, investigate klärt durch Nachforschungen; splint stützt einen Körperteil, rail trägt Schienenfahrzeuge. Beide genauen Glossentreffer mit alten Karten sind als Review gespeichert. Historisches throat/neck heißt jeweils Hals; Racheninnenraum und äußerer Hals bleiben getrennt.
- chest bezeichnet den Brustkorb, breast das Milchdrüsenorgan; numb fehlendes Körperempfinden, deaf fehlendes Hören. sprain betrifft Bänder, strain Muskel/Sehne, fracture Knochen. migraine ist eine Erkrankung, headache ein Symptom.
- tired bezeichnet Erholungsbedarf, drowsy Einschlafneigung. acute/chronic betreffen Zeitverlauf, mild/severe Schweregrad. inflammation ist keine Gleichsetzung mit infection. Allgemeine Synonyme und bloße Intensitätsvarianten bleiben ausgeschlossen.
- heal betrifft die Reparatur verletzten Gewebes, recover im Bestand allgemeines Wiederzukräftekommen, rehabilitation den geplanten Wiederaufbau von Fähigkeiten. cure/recovery nicht zusätzlich reserviert.
- test#test ohne einschränkende Definition wird wiederverwendet, kein erfundener medizinischer Subsense. wake bleibt transitiv wecken, prevent bleibt jemanden an einer Handlung hindern, jeweils gemäß bestehender Definition. Breite passende Bedeutungen wie lower, roll, fall werden nicht künstlich auf den neuen Satzkontext aufgeteilt.
- Tatsächliche neue Bedeutungen bei vorhandenen Formen: sight Sinnesfähigkeit statt Sehenswürdigkeit; smooth Oberfläche statt gleichmäßiger Bewegung; squeeze Zusammendrücken statt ausdrücklich definierter Saftgewinnung; scan als Bild-Nomen statt Code-Einlesen; cast als Verband-Nomen statt Schatten-werfen-Verb. Alte Keys und Definitionen bleiben unberührt.
- Ober-/Unterbegriffe sind nicht automatisch synonym: scan/x-ray, illness/asthma, treatment/operation, bandage/plaster beschreiben verschiedene Reichweiten. Alle 30 Kontrastentscheidungen stehen vollständig in der Auswahl; Antworten werden später pro Satz geprüft.

Wiederverwendete Ziele: treatment, tired, stretch, asleep, examine, wake, lean, test, bedtime, ear, mouth, lower, shiver, roll, throat, shake, neck, breathe, jump, back, climb, kick, chew, punch, mild, sterile, severe, bite, accident, knee, mobility, ankle, medical, heel, wheelchair, bitter, sweet, rough, sharp, prevent, healthy, fall.

Sechs Schreibaliasse: diarrhoea/diarrhea, anaesthetic/anesthetic, fibre/fiber, checkup/check-up, x-ray/xray, hiccup/hiccough. Vier nicht separat eingeplante Varianten: endurance, sleepy, disease, tweezer. Insgesamt 259 konfliktfreie geplante Zielformen und Varianten. Keine Variante wird automatisch accepted oder valid_alternatives; das bleibt satzbezogene Redaktion.

Frequenz ist ein Prüfsignal, keine CEFR-Einstufung oder automatische Ausschlussregel. 71 Formen liegen bei wordfreq 3.1.1 unter Zipf 3,5. Das betrifft viele gewöhnliche Körper-/Arztwörter sowie britische Schreibungen. Die neun Werte unter 2,7 sind sleepwalking 2.66, resuscitate 2.62, stethoscope 2.66, disinfect 2.55, physiotherapist 2.67, gargle 2.38, hoarse 2.66, optician 2.41, splint 2.66. Sie haben konkrete Alltagssituationen (Schlafverhalten, Wiederbelebung, Abhören, Desinfektion, Physiotherapie, Gurgeln, Heiserkeit, Brillenanpassung, Schiene), keine fachsystematische Auffüllung. Satzkontext-Linting folgt erst nach der Redaktion.

## Auswahl nach Themen

**Körperteile und Organe:** nose, ear, mouth, lip, tongue, throat, neck, shoulder, chest, back, stomach, heart, lung, brain, liver, kidney, bone, muscle, joint, elbow, wrist, finger, thumb, knee, ankle, toe, heel, forehead, cheek, chin, jaw, hip, waist, spine, rib, skull, blood, vein, artery, nerve, palm, nail, eyelash, eyebrow, nostril, scalp, intestine, bladder, breast.

**Sinne und körperliche Wahrnehmung:** tired, sight, hearing, blind, deaf, numb, dizzy, itch, tickle, tingle, shiver, sweat, breathe, inhale, exhale, sniff, sneeze, yawn, blink, swallow, chew, spit, hiccup, snore, bitter, sour, sweet, salty, smooth, rough, sharp, reflex.

**Bewegung und körperliche Fähigkeiten:** bend, stretch, twist, kneel, crawl, limp, lean, lower, roll, shake, jump, hop, jog, sprint, climb, cycle, kick, punch, squeeze, drag, coordination, posture, mobility, stamina, stiff, agile, steady, clumsy, upright, squat, fall.

**Beschwerden und häufige Erkrankungen:** illness, asthma, diabetes, cancer, arthritis, migraine, nausea, vomit, diarrhoea, constipation, rash, swelling, inflammation, cramp, contagious, chronic, acute, mild, severe, hoarse, runny, dehydration, indigestion, heartburn, flu, faint, obesity, underweight, breathless, healthy, insomnia.

**Arztbesuch und Untersuchung:** checkup, diagnosis, examine, test, scan, x-ray, ultrasound, sample, urine, stool, thermometer, height, stethoscope, referral, specialist, surgeon, physiotherapist, optician, midwife, paramedic, ward, medical, dental, oral, positive, negative, normal, monitor, consult.

**Behandlung, Pflege und Genesung:** treatment, heal, dose, antibiotic, painkiller, ointment, capsule, inhaler, vaccine, vaccinate, disinfect, sterile, rinse, gargle, compress, stitch, cast, splint, operation, anaesthetic, rehabilitation, prescribe, sedative, supplement, prevent, hygiene, isolation.

**Schlaf, Erholung und Wohlbefinden:** nap, asleep, wake, bedtime, dream, nightmare, sleepwalking, drowsy, restless, energy, alert, routine, rhythm, nutrition, nutrient, protein, fibre, carbohydrate, vitamin, mineral, appetite, hydration, diet, meditate, sauna.

**Verletzungen, Erste Hilfe und Hilfsmittel:** fracture, sprain, strain, concussion, scrape, bleed, choke, drown, rescue, resuscitate, unconscious, collapse, poison, sting, bite, accident, sling, crutch, wheelchair, walker, stretcher, plaster, tweezers, splinter, scar.

## Alle Ausschlüsse

Bestandskollisionen enthalten in der JSON-Auswahl konkrete Karten-/Sense-/Registry-Referenzen. Zurückgestellt bedeutet keine behauptete Synonymie; nur die angegebenen Bedeutungsüberschneidungen sind semantische Ausschlüsse.

| Kandidat | Grund |
|---|---|
| head | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| pain | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| patient | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| sleep | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| bandage | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| hand | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| disease | Allgemeines Krankheitsziel durch illness beziehungsweise bestehendes sick abgedeckt; keine parallelen Allgemeinbegriffe. |
| appointment | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| treat | Neben treatment kein weiterer gleichbedeutender allgemeiner Behandlungskopf. |
| rest | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| injury | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| eye | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| disorder | Allgemeines Krankheitsziel durch illness beziehungsweise bestehendes sick abgedeckt; keine parallelen Allgemeinbegriffe. |
| wound | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| skin | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| examination | Diagnoseergebnis diagnosis und Untersuchungshandlung examine ausgewählt; keine zusätzlichen Wortfamilienvarianten. |
| cure | Recover bereits eigenständiges Lernziel; heal beschränkt auf Gewebereparatur, keine weitere allgemeine Genesungsvariante. |
| doze | Überschneidung mit nap; kurze Schlafepisode bereits vertreten. |
| burn | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| foot | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| vision | Seh-/Hörfähigkeit durch sight/hearing; Wahrnehmung bereits durch feel/notice und konkrete Sinneshandlungen abgedeckt; kein unscharfes zusätzliches Wahrnehmungsziel. |
| crouch | Überschneidung mit squat; keine nur fein umschriebene Hockvariante. |
| recovery | Recover bereits eigenständiges Lernziel; heal beschränkt auf Gewebereparatur, keine weitere allgemeine Genesungsvariante. |
| blister | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| arm | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| diagnose | Diagnoseergebnis diagnosis und Untersuchungshandlung examine ausgewählt; keine zusätzlichen Wortfamilienvarianten. |
| recover | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| awake | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| bruise | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| leg | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| medicine | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| tooth | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| medication | Bereits medicine im Bestand; kein zweiter Medikamenten-Allgemeinbegriff. |
| reach | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| lift | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| dosage | Neben Einzeldosis dose hier nicht zusätzlich eingeplant; Dosierungsschema kann später eigenständig geprüft werden. |
| cut | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| turn | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| sleepy | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| specimen | Im gewählten Untersuchungskontext durch sample abgedeckt. |
| scratch | Neben scrape und vorhandenem cut/wound kein weiteres oberflächliches Verletzungsziel in dieser Auswahl. |
| cream | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| tremble | Überschneidung mit shiver; kein weiteres unwillkürliches Zitterziel. |
| refreshed | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| bleeding | Statt Wortfamilienvarianten bleed, poison und unconscious gewählt. |
| breath | Weitere Sinnes-/Körperbegriffe zurückgestellt; keine Mengenauffüllung über die ausgewählten konkreten Fähigkeiten und Vorgänge hinaus. |
| temperature | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| drops | Pluralform und kontextabhängige Medikamentenform; keine zusätzliche Grundformkarte ohne eindeutige Bindung. |
| energetic | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| infection | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| skip | Geeignete spätere Bewegungserweiterungen; die aktuelle Auswahl deckt bereits 31 unterschiedliche Bewegungsziele ab. |
| fever | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| weight | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| symptom | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| vaccination | Impfhandlung vaccinate/Impfstoff vaccine, Betäubungsmittel anaesthetic und Hindern prevent decken die Auswahl ab; zusätzliche abstrakte Ableitungen zurückgestellt. |
| sluggish | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| allergy | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| blood-pressure | Keine künstlich mit Bindestrichen zusammengeschriebene Mehrwortform reservieren; echte Phrase gegebenenfalls separat planen. |
| lethargic | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| relax | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| conscious | Statt Wortfamilienvarianten bleed, poison und unconscious gewählt. |
| waiting-room | Keine künstlich mit Bindestrichen zusammengeschriebene Mehrwortform reservieren; echte Phrase gegebenenfalls separat planen. |
| disinfectant | Desinfektionshandlung disinfect, Keimfreiheitszustand sterile und Sauberkeitspraxis hygiene gewählt; eng benachbarte Varianten zurückgestellt. |
| calm | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| consciousness | Statt Wortfamilienvarianten bleed, poison und unconscious gewählt. |
| reception | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| antiseptic | Desinfektionshandlung disinfect, Keimfreiheitszustand sterile und Sauberkeitspraxis hygiene gewählt; eng benachbarte Varianten zurückgestellt. |
| relaxed | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| rested | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| shock | Mehrdeutig zwischen medizinischem Kreislaufzustand und emotionalem Erschrecken; für diesen alltagsnahen Stapel zurückgestellt. |
| grip | Neben bestehendem hold/festhalten kein zusätzlicher, nur intensiver formulierter Griff-Synonymkopf. |
| sterilise | Desinfektionshandlung disinfect, Keimfreiheitszustand sterile und Sauberkeitspraxis hygiene gewählt; eng benachbarte Varianten zurückgestellt. |
| drool | Weitere Sinnes-/Körperbegriffe zurückgestellt; keine Mengenauffüllung über die ausgewählten konkreten Fähigkeiten und Vorgänge hinaus. |
| grasp | Neben bestehendem hold/festhalten kein zusätzlicher, nur intensiver formulierter Griff-Synonymkopf. |
| sore | Schmerzbegriff durch vorhandenes pain/hurt abgedeckt; keine allgemeine Schmerzparaphrase als neues Ziel. |
| poisoning | Statt Wortfamilienvarianten bleed, poison und unconscious gewählt. |
| swollen | Nominales Ziel swelling bereits ausgewählt; keine bloße Ableitungsvariante. |
| tiredness | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| dressing | Überlappung mit vorhandenem bandage; konkrete Auflage compress und klebendes Wundpflaster plaster statt weiterem Verbands-Allgemeinbegriff. |
| fatigue | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| cough | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| balance | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| blocked | Blockierung ist unspezifisch; Ansteckbarkeit durch contagious abgedeckt. |
| exhaustion | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| smell | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| casualty | Verletztenrolle gegenüber konkreten Verletzungen hier zurückgestellt. |
| taste | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| receptionist | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| suture | Gleiches Nahtkonzept wie stitch; Fachsynonym ausgeschlossen. |
| first-aid | Keine künstlich mit Bindestrichen zusammengeschriebene Mehrwortform reservieren; echte Phrase gegebenenfalls separat planen. |
| touch | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| kit | Alltagsgeeignet, aber zugunsten der gewählten konkreten Verletzungen und Gehhilfen zurückgestellt. |
| hear | Seh-/Hörfähigkeit durch sight/hearing; Wahrnehmung bereits durch feel/notice und konkrete Sinneshandlungen abgedeckt; kein unscharfes zusätzliches Wahrnehmungsziel. |
| flexibility | Körperliche Bewegungsfähigkeit durch mobility/stiff/agile/stamina differenziert; zusätzliche Eigenschaftsableitungen nicht nötig. |
| surgery | Operationskonzept durch operation abgedeckt; keine parallelen Eingriffsziele. |
| see | Seh-/Hörfähigkeit durch sight/hearing; Wahrnehmung bereits durch feel/notice und konkrete Sinneshandlungen abgedeckt; kein unscharfes zusätzliches Wahrnehmungsziel. |
| loud | Weitere Sinnes-/Körperbegriffe zurückgestellt; keine Mengenauffüllung über die ausgewählten konkreten Fähigkeiten und Vorgänge hinaus. |
| endurance | Im gewählten körperlichen Sinn gleichbedeutend mit stamina. |
| cold | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| operate | Operationskonzept durch operation abgedeckt; keine parallelen Eingriffsziele. |
| strength | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| bright | Weitere Sinnes-/Körperbegriffe zurückgestellt; keine Mengenauffüllung über die ausgewählten konkreten Fähigkeiten und Vorgänge hinaus. |
| weak | Körperliche Bewegungsfähigkeit durch mobility/stiff/agile/stamina differenziert; zusätzliche Eigenschaftsableitungen nicht nötig. |
| overweight | Neben obesity und underweight kein weiterer naher Gewichtsstatus in dieser Auswahl. |
| consent | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| anaesthesia | Impfhandlung vaccinate/Impfstoff vaccine, Betäubungsmittel anaesthetic und Hindern prevent decken die Auswahl ab; zusätzliche abstrakte Ableitungen zurückgestellt. |
| dim | Weitere Sinnes-/Körperbegriffe zurückgestellt; keine Mengenauffüllung über die ausgewählten konkreten Fähigkeiten und Vorgänge hinaus. |
| history | Breite allgemeine Begriffe mit mehreren Verwendungen; konkrete Untersuchungsvorgänge werden bevorzugt. |
| therapy | Neben treatment kein weiterer gleichbedeutender allgemeiner Behandlungskopf. |
| thirst | Hunger/Durst bereits durch hungry/thirsty vertreten; keine reinen nominalen Ableitungen. |
| gauze | Alltagsgeeignet, aber zugunsten der gewählten konkreten Verletzungen und Gehhilfen zurückgestellt. |
| result | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| hunger | Hunger/Durst bereits durch hungry/thirsty vertreten; keine reinen nominalen Ableitungen. |
| flexible | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| ache | Schmerzbegriff durch vorhandenes pain/hurt abgedeckt; keine allgemeine Schmerzparaphrase als neues Ziel. |
| side-effect | Schreibungs-/Mehrwortentscheidung nicht für diese Auswahl priorisiert; nicht als künstliche Einzelwortform aufnehmen. |
| adhesive | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| soreness | Schmerzbegriff durch vorhandenes pain/hurt abgedeckt; keine allgemeine Schmerzparaphrase als neues Ziel. |
| prescription | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| icepack | Schreibungs-/Mehrwortentscheidung nicht für diese Auswahl priorisiert; nicht als künstliche Einzelwortform aufnehmen. |
| balanced | Ernährung nutrition, individuelle Kost diet und einzelne Nährstoffe ausgewählt; allgemeine positive Ernährungsbewertungen nicht als zusätzliche Ziele. |
| exhausted | Müdigkeit/Schläfrigkeit durch tired/drowsy, Energie durch energy; keine bloßen Intensitäts-, Ableitungs- oder Synonymziele. |
| abnormal | Gegenteil des bereits ausgewählten Befundbegriffs normal zurückgestellt, keine Mengenauffüllung. |
| nutritious | Ernährung nutrition, individuelle Kost diet und einzelne Nährstoffe ausgewählt; allgemeine positive Ernährungsbewertungen nicht als zusätzliche Ziele. |
| tourniquet | Spezialisierter als die gewählten allgemein benötigten Hilfsmittel; nicht zur Mengenauffüllung aufnehmen. |
| sideways | Geeignete spätere Bewegungserweiterungen; die aktuelle Auswahl deckt bereits 31 unterschiedliche Bewegungsziele ab. |
| nourishing | Ernährung nutrition, individuelle Kost diet und einzelne Nährstoffe ausgewählt; allgemeine positive Ernährungsbewertungen nicht als zusätzliche Ziele. |
| safety | Breite Schutzkonzepte bereits durch safe/protect abgedeckt; nicht spezifisch für diesen Stapel. |
| measure | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| prevention | Impfhandlung vaccinate/Impfstoff vaccine, Betäubungsmittel anaesthetic und Hindern prevent decken die Auswahl ab; zusätzliche abstrakte Ableitungen zurückgestellt. |
| fasting | Meditationshandlung meditate gewählt; Fasten nicht zur Zielzahl ergänzen. |
| helmet | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| tender | Weitere Sinnes-/Körperbegriffe zurückgestellt; keine Mengenauffüllung über die ausgewählten konkreten Fähigkeiten und Vorgänge hinaus. |
| rotate | Geeignete spätere Bewegungserweiterungen; die aktuelle Auswahl deckt bereits 31 unterschiedliche Bewegungsziele ab. |
| sick | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| detect | Breite allgemeine Begriffe mit mehreren Verwendungen; konkrete Untersuchungsvorgänge werden bevorzugt. |
| fast | Meditationshandlung meditate gewählt; Fasten nicht zur Zielzahl ergänzen. |
| brace | Alltagsgeeignet, aber zugunsten der gewählten konkreten Verletzungen und Gehhilfen zurückgestellt. |
| sensitive | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| straighten | Geeignete spätere Bewegungserweiterungen; die aktuelle Auswahl deckt bereits 31 unterschiedliche Bewegungsziele ab. |
| screen | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| prosthesis | Spezialisierter als die gewählten allgemein benötigten Hilfsmittel; nicht zur Mengenauffüllung aufnehmen. |
| pulse | Weitere Sinnes-/Körperbegriffe zurückgestellt; keine Mengenauffüllung über die ausgewählten konkreten Fähigkeiten und Vorgänge hinaus. |
| stumble | Geeignete spätere Bewegungserweiterungen; die aktuelle Auswahl deckt bereits 31 unterschiedliche Bewegungsziele ab. |
| unwell | Allgemeines Krankheitsziel durch illness beziehungsweise bestehendes sick abgedeckt; keine parallelen Allgemeinbegriffe. |
| sanitary | Desinfektionshandlung disinfect, Keimfreiheitszustand sterile und Sauberkeitspraxis hygiene gewählt; eng benachbarte Varianten zurückgestellt. |
| meditation | Meditationshandlung meditate gewählt; Fasten nicht zur Zielzahl ergänzen. |
| glasses | Alltagsgeeignet, aber zugunsten der gewählten konkreten Verletzungen und Gehhilfen zurückgestellt. |
| heartbeat | Weitere Sinnes-/Körperbegriffe zurückgestellt; keine Mengenauffüllung über die ausgewählten konkreten Fähigkeiten und Vorgänge hinaus. |
| trip | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| assess | Breite allgemeine Begriffe mit mehreren Verwendungen; konkrete Untersuchungsvorgänge werden bevorzugt. |
| wellbeing | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| contact-lens | Keine künstlich mit Bindestrichen zusammengeschriebene Mehrwortform reservieren; echte Phrase gegebenenfalls separat planen. |
| slip | Geeignete spätere Bewegungserweiterungen; die aktuelle Auswahl deckt bereits 31 unterschiedliche Bewegungsziele ab. |
| laboratory | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| wellness | Überschneidung mit bestehendem wellbeing/relax; kein zusätzlicher diffuser Wohlfühlbegriff. |
| hearing-aid | Keine künstlich mit Bindestrichen zusammengeschriebene Mehrwortform reservieren; echte Phrase gegebenenfalls separat planen. |
| sensation | Seh-/Hörfähigkeit durch sight/hearing; Wahrnehmung bereits durch feel/notice und konkrete Sinneshandlungen abgedeckt; kein unscharfes zusätzliches Wahrnehmungsziel. |
| contagiousness | Blockierung ist unspezifisch; Ansteckbarkeit durch contagious abgedeckt. |
| mask | Alltagsgeeignet, aber zugunsten der gewählten konkreten Verletzungen und Gehhilfen zurückgestellt. |
| awareness | Seh-/Hörfähigkeit durch sight/hearing; Wahrnehmung bereits durch feel/notice und konkrete Sinneshandlungen abgedeckt; kein unscharfes zusätzliches Wahrnehmungsziel. |
| swing | Geeignete spätere Bewegungserweiterungen; die aktuelle Auswahl deckt bereits 31 unterschiedliche Bewegungsziele ab. |
| daylight | Tageslicht ist thematisch randständig, Beschwerden und Belastung durch konkrete Ziele beziehungsweise stress vertreten. |
| glove | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| perceive | Seh-/Hörfähigkeit durch sight/hearing; Wahrnehmung bereits durch feel/notice und konkrete Sinneshandlungen abgedeckt; kein unscharfes zusätzliches Wahrnehmungsziel. |
| rub | Geeignete spätere Bewegungserweiterungen; die aktuelle Auswahl deckt bereits 31 unterschiedliche Bewegungsziele ab. |
| sunlight | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| tissue | Alltagsgeeignet, aber zugunsten der gewählten konkreten Verletzungen und Gehhilfen zurückgestellt. |
| sense | Seh-/Hörfähigkeit durch sight/hearing; Wahrnehmung bereits durch feel/notice und konkrete Sinneshandlungen abgedeckt; kein unscharfes zusätzliches Wahrnehmungsziel. |
| massage | Geeignete spätere Bewegungserweiterungen; die aktuelle Auswahl deckt bereits 31 unterschiedliche Bewegungsziele ab. |
| comfortable | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| shrug | Geeignete spätere Bewegungserweiterungen; die aktuelle Auswahl deckt bereits 31 unterschiedliche Bewegungsziele ab. |
| discomfort | Tageslicht ist thematisch randständig, Beschwerden und Belastung durch konkrete Ziele beziehungsweise stress vertreten. |
| scissors | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| wave | Bereits vorhandene Kartenform, Satzalternative oder Reservierung; kein zweiter Wortbesitz. |
| burnout | Tageslicht ist thematisch randständig, Beschwerden und Belastung durch konkrete Ziele beziehungsweise stress vertreten. |
| scab | Alltagsgeeignet, aber zugunsten der gewählten konkreten Verletzungen und Gehhilfen zurückgestellt. |
| safeguard | Breite Schutzkonzepte bereits durch safe/protect abgedeckt; nicht spezifisch für diesen Stapel. |

## Prüfbefehle und tatsächliche Outputs

Interpreter macOS: `pipeline/.venv-macos/bin/python`; Windows PowerShell: `.\pipeline\.venv\Scripts\python.exe`. `PYTHON` in den folgenden Beispielen steht für den jeweiligen Interpreter. Alle Befehle laufen im Repository-Root.

```text
PYTHON build/koerper_gesundheit_checks/prepare.py
PASS: 249 selected / 178 excluded; 83/83/83; 42 existing_senses / 207 new_senses
PASS: index_registry, validate_selection, partition_selection, validate_learning, build_rows, validate_context
Exit 0
PYTHON build/koerper_gesundheit_checks/final_review.py
PASS 249 explicit German and English target definitions; 178 exclusions; 42 reused and 207 new senses
PASS same-gloss comparisons examine/investigate and splint/rail; historical neck/throat definitions preserved
Exit 0
PYTHON build/koerper_gesundheit_checks/audit.py
BASE PASS: schema 3 / menschen_beziehungen_batch_3_v1 / 1495 cards / 1380 primary targets / 5 decks
SQLITE_FULL_ROWS {'languages': 1, 'lemmas': 2570, 'senses': 3898, 'cards': 1495, 'dictionary_forms': 4502, 'decks': 5, 'deck_cards': 1495, 'deck_words': 1391, 'word_aliases': 22, 'sentences': 2029, 'sentence_tokens': 22174, 'card_sentences': 2023, 'stories': 1, 'story_sentences': 6, 'exercises': 0, 'grammar_rules': 0, 'audio_assets': 0, 'content_releases': 1}
BATCH 1 partitions {'imported': 0, 'current': 83, 'future': 166} display 1..83 topics 8
BATCH 2 partitions {'imported': 83, 'current': 83, 'future': 83} display 1..166 topics 8
BATCH 3 partitions {'imported': 166, 'current': 83, 'future': 0} display 1..249 topics 8
PASS membership-only display simulation batch 2 append 84..166 display 1..166
PASS membership-only display simulation batch 3 append 167..249 display 1..249
PASS 427 candidates / 249 selected / 178 excluded; 1391 old owners and 1495 old group members preserved; zero generated sentences
PASS original identities, positions and definitions immutable across all 3 batches; base SQLite and asset hash unchanged
Exit 0
PYTHON -m pytest pipeline/tests/test_selection.py pipeline/tests/test_word_registry.py pipeline/tests/test_learning_groups.py pipeline/tests/test_authoring_context.py pipeline/tests/test_authoring_schema3.py pipeline/tests/test_authoring_continuation.py pipeline/tests/test_deck_display.py -q
68 passed, 19 subtests passed in 1.62s
Exit 0
PYTHON pipeline/scripts/export_authoring_context.py --selection pipeline/data/selection/koerper_gesundheit_v1.json --batch 1 --out build/koerper_gesundheit_checks/staging/koerper_gesundheit_authoring_batch_1.zip
export: PASS; files: 81
Exit 0
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/koerper_gesundheit_checks/staging/koerper_gesundheit_authoring_batch_1.zip
zip_verification: PASS; hashed_files: 80; sqlite_tables: 18; sqlite_cards: 1495
Exit 0
```

Danach wurde die geschlossene ZIP ohne Überschreiben einer vorhandenen Lieferung an ihren endgültigen Ort verschoben. Zusätzlicher Readback: 249 englische Definitionen in allen Identitäten, davon 83 in der aktuellen Gruppe.

```text
PYTHON pipeline/scripts/export_authoring_context.py --verify-zip build/koerper_gesundheit_authoring_batch_1.zip
zip_verification: PASS; hashed_files: 80; sqlite_tables: 18; sqlite_cards: 1495
zip_sha256: 170835257fa241e2f48948225fea6158c147a14eeb7d0bb077e83ce58e59188b
Exit 0
git diff --check
Exit 2: vorhandene CRLF-/Whitespace-Altbefunde
git -c core.whitespace=cr-at-eol diff --check
Exit 2: sieben vorhandene Stellen
git status --short
Exit 0; vollständiger Output in build/koerper_gesundheit_checks/git-status-after.txt
```

Die sieben unveränderten Altbefunde: DESIGN.md:162–164, docs/alltag-zuhause-continuation.md:148/153, docs/arbeit-bildung-batch-1-import.md:127, docs/arbeit-bildung-batch-2-import.md:121. Rohoutput des normalen Checks umfasst 322644114 Bytes und wird komprimiert gespeichert; kein globales Whitespace-Aufräumen. Eigene neue Dateien und NEXTSTEPS gegen Sicherung gesondert geprüft: keine Diagnostik, prüfender Wrapper Exit 0. `--no-index --check` kann bei unterschiedlichen Dateien ohne Fehlerdiagnostik Exit 1 liefern.

Drei auftragsspezifische Vorbereitungsfehler wurden vor dem Export behoben: zwei noch nicht begründete Ausschlüsse ergänzt; Hilfsskript inspect.py wegen Überschattung des Python-Standardmoduls in inspect_senses.py umbenannt; Audit erwartete zunächst PASS statt des tatsächlich dokumentierten Finalization-Status ok. Tabellenzahlen stimmten bereits überein. Keine Datenreparatur und kein Umgehen eines Vertragschecks. Die endgültigen Prüfungen und beide ZIP-Readbacks bestehen.

## Nächster Schritt

Satzredaktion für ausschließlich die 83 aktuellen Ziele aus authoring_context.json: genau ein fester Übungssatz pro Ziel, spätere vollständige Tokenannotation und einzeln geprüfte Alternativen. Die weiteren 166 Ziele bleiben reserviert. Noch kein Körper-&-Gesundheit-Pack installiert. Keine ungeklärten Bedeutungs-, Besitz-, Alias- oder Gruppenbindungen in dieser Auswahl.
