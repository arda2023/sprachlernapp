# Redaktionelle Prüfung Pilot 60 v1 (04.10.2026)

## Ausgangslage und Prüfumfang

- `pipeline/out/pilot_60_v1.json`: 160 Karten, 480 Sätze, 480 Karten-Satz-Zuordnungen, 121 gespeicherte Alternativantworten (`valid_alternatives`).
- `pipeline/out/pos_check_v1.json` (nachträglicher POS-Lauf): 10 Karten, 30 Sätze, 5 Alternativantworten.
- Feste QA `pipeline/out/qa_content_v1/results.json`: 25/26 bestanden; `pilot60_s126_quiet_library_books` bleibt falsch akzeptiert. Erwartungswert und Fall bleiben unverändert.

**Bearbeitungsstand: vollständig.** Jeder der 480 Pilotsätze und 30 POS-Sätze wurde mit Lücke, deutscher Übersetzung, Kartenbedeutung (Glosse, Wortform) gelesen; jede der 121 + 5 Alternativen wurde wörtlich in die Lücke eingesetzt und gegen das Original gelesen. Grundlage war ein lokaler Auszug aus beiden Packs (Karte → Sätze → eingesetzte Alternativen). Keine Stichprobe.

Satzreferenzen (`s1` …) gelten nur innerhalb ihrer Quelldatei und werden daher immer mit Präfix angegeben: `pilot_60_v1/s126`, `pos_check_v1/s9`.

Bewertungsmaßstab: **korrigieren** = klarer Fehler (Grammatik, falsche Kartenbedeutung, unlogischer Satz, sachlich falsche Übersetzung). **Alternative entfernen** = eingesetzter Satz verschiebt die relevante Bedeutung. **Redaktionell entscheiden** = Prüffall oder Kartenfrage ohne eindeutiges Urteil. **Nur Stilhinweis** = korrekt, aber verbesserbar; kein Handlungsbedarf für ein Test-Pack. Formelle oder seltenere, aber korrekte Sprache (z. B. `but` = „nur“, `for` = „denn“, `thus`, `nay`, `comprehend`) gilt nicht als Fehler.

## Zahlen

| | Pilot 60 v1 | POS-Lauf | gesamt |
|---|---|---|---|
| geprüfte Karten | 160 | 10 | 170 |
| geprüfte Sätze | 480 | 30 | 510 |
| geprüfte Alternativen | 121 | 5 | 126 |
| Sätze „korrigieren“ (klare Fehler) | 9 | 0 | 9 |
| Alternativen „entfernen“ (klare Fehler) | 2 | 0 | 2 |
| Sätze „redaktionell entscheiden“ (Prüffälle) | 20 | 1 | 21 |
| Alternativen „redaktionell entscheiden“ (Prüffälle) | 6 | 0 | 6 |
| Karten „redaktionell entscheiden“ (Kartenebene) | 8 | 0 | 8 |
| Sätze „nur Stilhinweis“ | 22 | 2 | 24 |

## Befunde: korrigieren (klare Satzfehler)

| Quelle / Satz | Karte | Text | Begründung | Empfehlung |
|---|---|---|---|---|
| pilot_60_v1/s126 | `in\|in/ADV\|in#herein_drinnen` | Ben stayed in all afternoon to read quiet library books. / … um ruhige Bibliotheksbücher zu lesen. | Eigenschaft „quiet“ unsinnig den Büchern zugeordnet (bekannter Fall; QA-Fall weiter falsch akzeptiert). | Satz ersetzen, z. B. „… to read library books quietly.“ |
| pilot_60_v1/s399 | `at\|at/ADP\|at#zeit` | Mia takes her medicine at bedtime. / Mia nimmt ihre Medizin vor dem Schlafengehen. | Übersetzung verschiebt den Zeitbezug: „at bedtime“ = „beim Schlafengehen / zur Schlafenszeit“, nicht „vor“. Ursache der falsch bestätigten Alternative (siehe unten). | Übersetzung korrigieren („… zur Schlafenszeit“); Alternative `before` entfernen. |
| pilot_60_v1/s26 | `your\|your/DET\|your#ihr` | Is this nice photograph of your family, Rosa? | Ungrammatische bzw. unklare Struktur (fehlender Artikel: „Is this a nice photograph …“). | Satz ersetzen. |
| pilot_60_v1/s30 | `the\|the/ADV\|the#umso` | Did Emma enjoy this stormy walk outside all the more? | „all the more“ ohne Grund oder Vergleich; Satz ergibt keinen Sinn. | Satz ersetzen (Grund nennen: „… all the more because …“). |
| pilot_60_v1/s99 | `had\|have/VERB\|have#besitzen_partizip` | Maya has had that seat near the driver for hours. / Maya hat jenen Platz nahe beim Fahrer seit Stunden gehabt. | Deutsche Übersetzung grammatisch falsch („seit Stunden gehabt“). | Übersetzung korrigieren („Maya sitzt seit Stunden auf dem Platz …“ bzw. „hat … schon seit Stunden“). |
| pilot_60_v1/s153 | `about\|about/ADJ\|about#im_begriff` | Ali blew gently because he was about to blow out the candles. | Unlogisch: Er pustet, weil er im Begriff ist, auszupusten. | Satz ersetzen. |
| pilot_60_v1/s171 | `just\|just/ADV\|just#genau` | Is that seat next to Omar just big enough? / … genau groß genug? | „just big enough“ = „gerade so groß genug“, nicht die Kartenbedeutung „genau, exakt“; Übersetzung entsprechend falsch. | Satz ersetzen. |
| pilot_60_v1/s331 | `is\|be/AUX\|be#hilfsverb` | Leo liest gerade sein Englisches Buch im Klassenzimmer. | Rechtschreibfehler in der Übersetzung („englisches“). | Übersetzung korrigieren. |
| pilot_60_v1/s413 | `all\|all/ADV\|all#vollstaendig_adv` | Is Ben all right after the hard week with his family? / Geht es Ben … ganz gut? | „all right“ ist ein fester Ausdruck („in Ordnung“), keine verstärkende Verwendung „ganz, völlig“; Übersetzung verschiebt die Bedeutung. | Satz ersetzen (z. B. „all alone“, „all wet“). |

## Befunde: Alternative entfernen (klare Fehler)

| Quelle / Satz | Karte | eingesetzter Satz | Begründung | Empfehlung |
|---|---|---|---|---|
| pilot_60_v1/s399 | `at\|at/ADP\|at#zeit` | Mia takes her medicine **before** bedtime. | Zeitpunkt → vorher; der Originalvergleich zeigt die Verschiebung, nur die (fehlerhafte) Übersetzung passte zu beiden. Bekannter Fall. | `before` aus `valid_alternatives` entfernen. |
| pilot_60_v1/s140 | `they\|they/PRON\|they#man_leute` | Do **you** make reliable laptops in that factory, Luis? | Mit Anrede „Luis“ bezieht sich „you“ auf Luis statt auf „die Leute“; Beteiligte verschoben. | `you` entfernen. |

## Befunde: redaktionell entscheiden (Prüffälle)

**Sätze**

| Quelle / Satz | Karte | Text | Begründung | Empfehlung |
|---|---|---|---|---|
| pilot_60_v1/s28 | `the\|the/ADV\|the#umso` | Lina arrived earlier, and her package was collected all the quicker. | Begründungszusammenhang für „all the quicker“ schwach. | Prüfen, ggf. ersetzen. |
| pilot_60_v1/s64 | `so\|so/ADV\|so#auf_diese_weise` | Luca holds the guitar so and strikes the strings. | „so“ = „auf diese Weise“ braucht eine vorgeführte Handlung; mitten im Satz unnatürlich. Gilt für die ganze Karte. | Satz ersetzen (Satzende: „… like so.“ bzw. vorgeführte Handlung). |
| pilot_60_v1/s118 | `his\|his/DET\|his#sein` | Eva repairs his broken laptop with small tools. | „his“ ohne Bezugsperson (Prompt-Regel 5). | Bezug ergänzen oder akzeptieren. |
| pilot_60_v1/s120 | `his\|his/DET\|his#sein` | Did Rosa find his warm jacket in the hall? | wie s118. | wie s118. |
| pilot_60_v1/s168 | `more\|more/ADV\|more#mehr_steigerung` | Ali feeds his cat slowly because it is more careful than his dog. | Begründung unlogisch. | Prüfen, ggf. ersetzen. |
| pilot_60_v1/s194 | `at\|at/ADP\|at#zustand` | David felt at fault for losing the package. | Üblich ist „was at fault“; „felt at fault“ selten. | Prüfen. |
| pilot_60_v1/s268 | `as\|as/ADV\|as#so_vergleich` | Mia hopes her soup will taste as good this evening. | Vergleichspartner fehlt (elliptisch). | Prüfen, ggf. „as good as yesterday“. |
| pilot_60_v1/s270 | `as\|as/ADV\|as#so_vergleich` | Eva thinks her team is just as fast. | wie s268. | wie s268. |
| pilot_60_v1/s271 | `out\|out/ADJ\|out#nicht_da` | Omar is out on holiday until next Monday. | Standard „away on holiday“; „out“ hier ungewöhnlich. | Prüfen. |
| pilot_60_v1/s273 | `out\|out/ADJ\|out#nicht_da` | Maya cannot try the new dress because she is out. | Begründung unklar. | Prüfen. |
| pilot_60_v1/s292 | `been\|be/AUX\|be#gewesen` | Mia has been tired after tennis training. | Present Perfect ohne passenden Zeitrahmen unnatürlich. | Prüfen, ggf. ersetzen. |
| pilot_60_v1/s294 | `been\|be/AUX\|be#gewesen` | Omar has already been busy with the laundry. | wie s292. | wie s292. |
| pilot_60_v1/s368 | `or\|or/CCONJ\|or#oder` | Noah cleans the green grass with a broom or a rake. | Ungewöhnlicher Kontext (Gras mit Besen säubern). | Prüfen. |
| pilot_60_v1/s390 | `on\|on/ADV\|on#weiter` | Why does David talk on about his old car? | Idiomatisch ist „go on about“; „talk on about“ selten. | Prüfen. |
| pilot_60_v1/s398 | `at\|at/ADP\|at#zeit` | Can you meet Noah at noon? / … um die Mittagszeit … | „at noon“ = „um zwölf Uhr mittags“, Übersetzung ungenauer. | Übersetzung präzisieren. |
| pilot_60_v1/s409 | `just\|just/ADJ\|just#gerecht` | Emma offered a just solution when the train platform became overcrowded. | Kollokation im Alltagskontext ungewöhnlich. | Prüfen. |
| pilot_60_v1/s442 | `will\|will/NOUN\|will#wille` | Ali showed a strong will while cutting down the dead tree. | Kontext gezwungen. | Prüfen. |
| pilot_60_v1/s444 | `will\|will/NOUN\|will#wille` | Without enough will to follow difficult recipes, David often ruins dinner. | Kontext gezwungen. | Prüfen. |
| pilot_60_v1/s466 | `you\|you/PRON\|you#man` | Can you take the bus across this big city, Amir? | Mit Anrede ist „you“ = Amir naheliegend, Karte verlangt „man“. | Prüfen, ggf. Anrede entfernen. |
| pilot_60_v1/s474 | `no\|no/DET\|no#kein` | Unfortunately, Noah wears no warm coat in winter. | Natürlicher: „doesn't wear a warm coat“. | Prüfen. |
| pos_check_v1/s9 | `which\|which/PRON\|which#fragepronomen` | Here are two birthday cakes, and Zoe chooses which tastes best. | „chooses which tastes best“ semantisch schief (wählen vs. feststellen). | Prüfen. |

**Alternativen**

| Quelle / Satz | Karte | eingesetzter Satz | Begründung | Empfehlung |
|---|---|---|---|---|
| pilot_60_v1/s18 | `that\|that/ADV\|that#so` | … the pain was not **too** bad. | „not that bad“ (weniger schlimm als erwartet) vs. „not too bad“ (ganz in Ordnung): leichte Verschiebung. | Entscheiden. |
| pilot_60_v1/s105 | `get\|get/VERB\|get#gelangen` | Can Noah **go** to the doctor without a car? | „get to“ = hingelangen (Fähigkeit), „go“ allgemeiner. | Entscheiden. |
| pilot_60_v1/s141 | `they\|they/PRON\|they#man_leute` | Mia knows that **you** keep old books on the top floor. | generisches „you“ möglich, aber als Anrede lesbar. | Entscheiden. |
| pilot_60_v1/s180 | `time\|time/VERB\|time#zeitlich_abstimmen` | Can Sara **plan** our break before the rain starts? | „plan“ verliert die zeitliche Abstimmung; Lesart „vor dem Regen planen“ möglich. | Entscheiden. |
| pilot_60_v1/s180 | `time\|time/VERB\|time#zeitlich_abstimmen` | Can Sara **arrange** our break before the rain starts? | wie `plan`. | Entscheiden. |
| pilot_60_v1/s221 | `like\|like/ADV\|like#fuellwort` | … Ali was **so to speak** totally surprised … | Füllwort „like“ ≠ „so to speak“; Stellung unnatürlich. | Entscheiden (abhängig von Kartenentscheidung C74). |

**Kartenebene**

| Quelle / Karte | Sätze | Befund | Empfehlung |
|---|---|---|---|
| pilot_60_v1 `your\|your/DET\|your#ihr` | s25, s26, s27 | Englisch unterscheidet „Ihr/dein/euer“ nicht; Übersetzung erzwingt „Sie“ mit Vornamen („Haben Sie …, Omar?“). Die Bedeutung ist im Lückensatz nicht erkennbar. | Entscheiden, ob `your#ihr`/`your#dein`/`your#euer` getrennte Karten bleiben. |
| pilot_60_v1 `your\|your/DET\|your#dein` | s145, s146, s147 | wie oben (Satz selbst korrekt). | wie oben. |
| pilot_60_v1 `your\|your/DET\|your#euer` | s244, s245, s246 | wie oben; s245 „Nina, are these flowers in your garden?“ spricht nur Nina an, „euer“ nicht begründet. | wie oben. |
| pilot_60_v1 `they\|they/PRON\|they#singular_they` | s229, s230, s231 | Übersetzungen mit Schrägstrich („sie/er“) als Lerntext ungeeignet; singular they bei Namen mit typischer Geschlechtszuordnung. | Entscheiden (Karte behalten, Übersetzungskonvention festlegen oder ausschließen). |
| pilot_60_v1 `like\|like/ADV\|like#fuellwort` | s220, s221, s222 | Bereits offener Punkt; s220 „quasi zwanzig Minuten“ trifft „for like twenty minutes“ (≈ „so etwa“) nicht. | Entscheiden (offener Punkt like#fuellwort). |
| pilot_60_v1 `that\|that/PRON\|that#das` | s58, s59, s60 | Glosse vermischt Demonstrativ- und Relativpronomen; s58/s60 relativ, s59 demonstrativ. | Bedeutung trennen oder Glosse präzisieren (Inventar, separates Inkrement). |
| pilot_60_v1 `have\|have/VERB\|have#besitzen` | s184, s185, s186 | Glosse „Vollverb in der 3. Person Singular“ an der Grundform `have` (gemeinsame Glosse mit `has`). | Glosse formneutral fassen. |
| pilot_60_v1 `will\|will/NOUN\|will#testament` | s109, s110, s111 | Bereits offener Punkt (seltene Bedeutung für Anfänger). | Entscheiden (offener Punkt). |

## Befunde: nur Stilhinweis (kein Handlungsbedarf für ein Test-Pack)

pilot_60_v1: s7 („überhaupt nicht wärmer“ stärker als „no warmer“), s14 (Zeitform „Where is … after Elias washed it?“), s68 (Wortstellung „stieg … aus außer Elias“), s74 („zittert vor Zugluft“ → „wegen der Zugluft“), s97 („schon sehr lange gehabt“), s173 („die Zeit messen, wie lange …“), s206 (ungewöhnlicher Kontext Öl/Roboter), s256 und s258 („welche/welcher“ steif), s283 („zu dem“ → „zum“), s327 („when she travels abroad“ logisch schief), s378 („fine you“ ohne „dir“ übersetzt), s380 („nachdem sie … beenden“ → „beendet haben“), s384 („heavy letter“), s403, s404, s405 („jener“ steif), s410 (Satzbau), s436 („cold weather of December“), s439 („alles davon“), s459 („so fast“ ohne Folge), s477 (Verneinung „does not pay … twice a month“ ungewöhnlich).
pos_check_v1: s23 („welches“ steif), s29 („genau jetzt“).

## POS-Lauf: Zuordnung zu Pilotkarten

Neue AUX-Identitäten laut `docs/be-pos-correction.md`. Nichts zusammengeführt, keine Referenz ersetzt.

| pos_check_v1 Karte | Sätze | Verhältnis zum Pilot | Befunde |
|---|---|---|---|
| `are\|be/AUX\|be#sein_vollverb` (neu, `08470372ea71b7c40444c2b7bc738766`) | s1–s3 | ergänzt (im Pilot fehlend) | keine |
| `was\|be/AUX\|be#sein_vollverb` (neu, `319aa2e30453222cf8a74fad14b00e91`) | s10–s12 | ergänzt (im Pilot fehlend) | keine |
| `be\|be/AUX\|be#sein_existieren` (neu, `7be993be34e9d87e7156cfc02256dc0f`) | s19–s21 | ergänzt (im Pilot fehlend) | keine |
| `be\|be/AUX\|be#befinden` (neu, `d2ef9df94be5dd1c9ec9e98860c00764`) | s28–s30 | ersetzt `pilot_60_v1` `be\|be/VERB\|be#befinden` (s196–s198) | s29 Stilhinweis |
| `which\|which/PRON\|which#fragepronomen` | s7–s9 | ergänzt (im Pilot fehlend) | s9 Prüffall |
| `was\|be/AUX\|be#hilfsverb` | s4–s6 | gleiche Referenz wie pilot s49–s51; alternative Satzmenge | s5 fast identisch mit pilot s50 („Yesterday, a package was delivered to Noah by …“) |
| `are\|be/AUX\|be#sein_hilfsverb` | s13–s15 | gleiche Referenz wie pilot s163–s165 | s13 ähnlich pilot s163 |
| `which\|which/DET\|which#determiner_auswahl` | s16–s18 | gleiche Referenz wie pilot s199–s201 | s17 ähnlich pilot s200 |
| `which\|which/PRON\|which#relativpronomen` | s22–s24 | gleiche Referenz wie pilot s256–s258 | s23 Stilhinweis |
| `be\|be/AUX\|be#hilfsverb` | s25–s27 | gleiche Referenz wie pilot s328–s330 | keine |

Bei einer späteren Zusammenführung je Karte genau eine Satzmenge wählen; Beinahe-Duplikate (pilot s50 / pos s5) nicht gemeinsam übernehmen.

## Korrekturhinweise

- Korrekturen werden nur vorgeschlagen; die Packs bleiben unverändert. Keine manuelle Änderung einzelner Texte im JSON.
- Jede Textänderung (Satz oder Übersetzung) erfordert anschließend konsistent neu erzeugte Satz-ID (aus dem Text abgeleitet), Lücken-Offsets und Tokenannotation (`sentence_tokens`); Alternativen und QA-Bericht des Satzes sind neu zu prüfen.
- Das Entfernen einer Alternative ändert nur `card_sentences.valid_alternatives`, nicht die Satz-ID.

## Abschlussentscheidung

**Bis zu einem kuratierten Test-Pack fehlen:**
1. 9 Satzkorrekturen (6 Sätze ersetzen: s26, s30, s126, s153, s171, s413; 3 Übersetzungen korrigieren: s99, s331, s399) einschließlich neuer Satz-ID, Lücke und Annotation.
2. 2 Alternativen entfernen (s399 `before`, s140 `you`).
3. Entscheidungen zu den 8 Kartenfragen; bis dahin diese Karten nicht in das Test-Pack aufnehmen oder ausdrücklich als vorläufig markieren.
4. Entscheidung über die 21 Satz- und 6 Alternativ-Prüffälle (übernehmen oder ersetzen).
5. Je Karte genau eine Satzmenge aus Pilot oder POS-Lauf wählen; `be|be/VERB|be#befinden` durch die AUX-Karte ersetzen, die vier fehlenden Karten aus dem POS-Lauf ergänzen. Veröffentlichungsstatus alter VERB-IDs bleibt ungeklärt (Tombstones ggf. vor Veröffentlichung).

**Systematische Pipelinebefunde (kein Einzelfall):**
- Übersetzungsprüfung: `translation_ok` prüft Bedeutungsgleichheit, aber nicht die Korrektheit des Deutschen (s99, s331) und übersah eine Zeitbezugsverschiebung in der Übersetzung selbst (s399).
- Ganzsatz-Plausibilität: unlogische oder falsch zugeordnete Aussagen passieren `language_ok` (s126 trotz `meaning-check-v6` live weiter akzeptiert; s30, s153).
- Feste Ausdrücke statt Kartenbedeutung: s171 („just big enough“), s413 („all right“) wurden als Kartenbedeutung akzeptiert.
- Alternativprüfung: Verschiebung der Beteiligten durch Anrede (s140) und Zeitbezug (s399, vor `alternative-check-v3`).
- Inventar: Bedeutungen, die im englischen Lückensatz nicht unterscheidbar sind (your#ihr/dein/euer, singular they), sowie formabhängige Texte in geteilten Glossen (have#besitzen) und vermischte Glossen (that#das).

Empfehlung: keine neue Generierung oder Modellumstellung allein wegen dieser Einzelfälle. Nächster Schritt ist ein kleines Kurationsinkrement, das redaktionelle Ersetzungen und Alternativ-Entfernungen als versionierte Liste anwendet und Satz-ID, Lücke und Annotation mit den vorhandenen Pipelinefunktionen neu erzeugt.

## Anhang: vollständige Liste geprüfter Karten

Spalte „Befund“: K = korrigieren, A = Alternative entfernen, R = redaktionell entscheiden, S = Stilhinweis, – = ohne Befund.

### pilot_60_v1 (160 Karten)

| Karte | Sätze | Alternativen | Befund |
|---|---|---|---|
| `out\|out/ADJ\|out#erloschen` | s1, s2, s3 | 1 | – |
| `but\|but/ADV\|but#nur` | s4, s5, s6 | 2 | – |
| `no\|no/ADV\|no#nicht` | s7, s8, s9 | 0 | s7 S |
| `not\|not/PART\|not#nicht` | s10, s11, s12 | 0 | – |
| `it\|it/PRON\|it#es_ding` | s13, s14, s15 | 0 | s14 S |
| `that\|that/ADV\|that#so` | s16, s17, s18 | 2 | s18 R |
| `will\|will/AUX\|will#zukunft` | s19, s20, s21 | 0 | – |
| `it\|it/PRON\|it#unpersoenlich` | s22, s23, s24 | 0 | – |
| `your\|your/DET\|your#ihr` | s25, s26, s27 | 0 | s25 R, s26 KR, s27 R |
| `the\|the/ADV\|the#umso` | s28, s29, s30 | 0 | s28 R, s30 K |
| `to\|to/ADP\|to#bis_zeit` | s31, s32, s33 | 0 | – |
| `her\|she/PRON\|she#sie_akkusativ` | s34, s35, s36 | 0 | – |
| `by\|by/ADP\|by#mit_mittel` | s37, s38, s39 | 0 | – |
| `of\|of/ADP\|of#teil_menge` | s40, s41, s42 | 0 | – |
| `his\|his/PRON\|his#seiner` | s43, s44, s45 | 0 | – |
| `her\|she/PRON\|she#ihr_dativ` | s46, s47, s48 | 0 | – |
| `was\|be/AUX\|be#hilfsverb` | s49, s50, s51 | 0 | – |
| `as\|as/SCONJ\|as#waehrend_zeit` | s52, s53, s54 | 3 | – |
| `just\|just/ADV\|just#nur` | s55, s56, s57 | 2 | – |
| `that\|that/PRON\|that#das` | s58, s59, s60 | 2 | s58 R, s59 R, s60 R |
| `in\|in/ADP\|in#in_zeitlich` | s61, s62, s63 | 0 | – |
| `so\|so/ADV\|so#auf_diese_weise` | s64, s65, s66 | 5 | s64 R |
| `but\|but/ADP\|but#ausser` | s67, s68, s69 | 5 | s68 S |
| `at\|at/ADP\|at#richtung` | s70, s71, s72 | 0 | – |
| `from\|from/ADP\|from#ursache` | s73, s74, s75 | 0 | s74 S |
| `up\|up/ADJ\|up#wach` | s76, s77, s78 | 3 | – |
| `but\|but/CCONJ\|but#aber` | s79, s80, s81 | 2 | – |
| `what\|what/DET\|what#welcher` | s82, s83, s84 | 3 | – |
| `more\|more/PRON\|more#mehr_pronomen` | s85, s86, s87 | 0 | – |
| `up\|up/ADV\|up#hinauf` | s88, s89, s90 | 0 | – |
| `me\|I/PRON\|i#mich` | s91, s92, s93 | 0 | – |
| `what\|what/PRON\|what#relativpronomen` | s94, s95, s96 | 0 | – |
| `had\|have/VERB\|have#besitzen_partizip` | s97, s98, s99 | 0 | s97 S, s99 K |
| `if\|if/SCONJ\|if#ob` | s100, s101, s102 | 3 | – |
| `get\|get/VERB\|get#gelangen` | s103, s104, s105 | 2 | s105 R |
| `get\|get/VERB\|get#bekommen` | s106, s107, s108 | 3 | – |
| `will\|will/NOUN\|will#testament` | s109, s110, s111 | 0 | s109 R, s110 R, s111 R |
| `like\|like/ADP\|like#wie` | s112, s113, s114 | 0 | – |
| `on\|on/ADP\|on#auf` | s115, s116, s117 | 0 | – |
| `his\|his/DET\|his#sein` | s118, s119, s120 | 0 | s118 R, s120 R |
| `as\|as/SCONJ\|as#da_grund` | s121, s122, s123 | 6 | – |
| `in\|in/ADV\|in#herein_drinnen` | s124, s125, s126 | 4 | s126 K |
| `that\|that/SCONJ\|that#dass` | s127, s128, s129 | 0 | – |
| `just\|just/ADV\|just#gerade_eben` | s130, s131, s132 | 0 | – |
| `with\|with/ADP\|with#zusammen_mit` | s133, s134, s135 | 0 | – |
| `you\|you/PRON\|you#du_sie_ihr` | s136, s137, s138 | 0 | – |
| `they\|they/PRON\|they#man_leute` | s139, s140, s141 | 3 | s140 A, s141 R |
| `on\|on/ADP\|on#an_zeitlich` | s142, s143, s144 | 1 | – |
| `your\|your/DET\|your#dein` | s145, s146, s147 | 0 | s145 R, s146 R, s147 R |
| `what\|what/PRON\|what#fragepronomen` | s148, s149, s150 | 0 | – |
| `about\|about/ADJ\|about#im_begriff` | s151, s152, s153 | 0 | s153 K |
| `has\|have/VERB\|have#besitzen` | s154, s155, s156 | 0 | – |
| `by\|by/ADP\|by#bis_spaetestens` | s157, s158, s159 | 0 | – |
| `as\|as/ADP\|as#als_funktion` | s160, s161, s162 | 0 | – |
| `are\|be/AUX\|be#sein_hilfsverb` | s163, s164, s165 | 0 | – |
| `more\|more/ADV\|more#mehr_steigerung` | s166, s167, s168 | 0 | s168 R |
| `just\|just/ADV\|just#genau` | s169, s170, s171 | 1 | s171 K |
| `time\|time/VERB\|time#stoppen` | s172, s173, s174 | 1 | s173 S |
| `we\|we/PRON\|we#wir` | s175, s176, s177 | 0 | – |
| `time\|time/VERB\|time#zeitlich_abstimmen` | s178, s179, s180 | 5 | s180 R |
| `have\|have/VERB\|have#einnehmen` | s181, s182, s183 | 0 | – |
| `have\|have/VERB\|have#besitzen` | s184, s185, s186 | 0 | s184 R, s185 R, s186 R |
| `for\|for/CCONJ\|for#denn_grund` | s187, s188, s189 | 0 | – |
| `with\|with/ADP\|with#mittels` | s190, s191, s192 | 0 | – |
| `at\|at/ADP\|at#zustand` | s193, s194, s195 | 0 | s194 R |
| `be\|be/VERB\|be#befinden` | s196, s197, s198 | 0 | – |
| `which\|which/DET\|which#determiner_auswahl` | s199, s200, s201 | 0 | – |
| `on\|on/ADJ\|on#an_eingeschaltet` | s202, s203, s204 | 1 | – |
| `can\|can/NOUN\|can#dose` | s205, s206, s207 | 0 | s206 S |
| `for\|for/ADP\|for#fuer_zweck_empfaenger` | s208, s209, s210 | 0 | – |
| `time\|time/NOUN\|time#mal` | s211, s212, s213 | 0 | – |
| `had\|have/VERB\|have#besitzen_past` | s214, s215, s216 | 0 | – |
| `like\|like/VERB\|like#moegen` | s217, s218, s219 | 0 | – |
| `like\|like/ADV\|like#fuellwort` | s220, s221, s222 | 5 | s220 R, s221 R, s222 R |
| `and\|and/CCONJ\|and#um_zu` | s223, s224, s225 | 2 | – |
| `if\|if/SCONJ\|if#wenn` | s226, s227, s228 | 0 | – |
| `they\|they/PRON\|they#singular_they` | s229, s230, s231 | 0 | s229 R, s230 R, s231 R |
| `all\|all/DET\|all#alle_det` | s232, s233, s234 | 0 | – |
| `who\|who/PRON\|who#der_die` | s235, s236, s237 | 1 | – |
| `from\|from/ADP\|from#unterscheidung` | s238, s239, s240 | 0 | – |
| `no\|no/INTJ\|no#nein` | s241, s242, s243 | 0 | – |
| `your\|your/DET\|your#euer` | s244, s245, s246 | 0 | s244 R, s245 R, s246 R |
| `to\|to/PART\|to#infinitivpartikel` | s247, s248, s249 | 0 | – |
| `do\|do/VERB\|do#reichen` | s250, s251, s252 | 6 | – |
| `when\|when/SCONJ\|when#als_wenn` | s253, s254, s255 | 0 | – |
| `which\|which/PRON\|which#relativpronomen` | s256, s257, s258 | 0 | s256 S, s258 S |
| `when\|when/ADV\|when#in_dem` | s259, s260, s261 | 0 | – |
| `from\|from/ADP\|from#von_ausgangspunkt` | s262, s263, s264 | 0 | – |
| `by\|by/ADP\|by#neben_ort` | s265, s266, s267 | 4 | – |
| `as\|as/ADV\|as#so_vergleich` | s268, s269, s270 | 1 | s268 R, s270 R |
| `out\|out/ADJ\|out#nicht_da` | s271, s272, s273 | 4 | s271 R, s273 R |
| `been\|be/VERB\|be#besucht` | s274, s275, s276 | 0 | – |
| `an\|a/DET\|a#ein` | s277, s278, s279 | 0 | – |
| `my\|my/DET\|my#mein` | s280, s281, s282 | 0 | – |
| `to\|to/ADP\|to#nach_richtung` | s283, s284, s285 | 0 | s283 S |
| `for\|for/ADP\|for#seit_lang_dauer` | s286, s287, s288 | 0 | – |
| `and\|and/CCONJ\|and#und` | s289, s290, s291 | 0 | – |
| `been\|be/AUX\|be#gewesen` | s292, s293, s294 | 0 | s292 R, s294 R |
| `of\|of/ADP\|of#ueber_bezug` | s295, s296, s297 | 1 | – |
| `who\|who/PRON\|who#wer` | s298, s299, s300 | 0 | – |
| `were\|be/AUX\|be#waere_konjunktiv` | s301, s302, s303 | 0 | – |
| `out\|out/ADV\|out#hinaus` | s304, s305, s306 | 0 | – |
| `is\|be/AUX\|be#sein_vollverb` | s307, s308, s309 | 0 | – |
| `more\|more/ADV\|more#wieder_noch` | s310, s311, s312 | 0 | – |
| `with\|with/ADP\|with#mit_eigenschaft` | s313, s314, s315 | 0 | – |
| `do\|do/AUX\|do#hilfsverb` | s316, s317, s318 | 0 | – |
| `of\|of/ADP\|of#material_herkunft` | s319, s320, s321 | 0 | – |
| `have\|have/VERB\|have#muessen` | s322, s323, s324 | 1 | – |
| `can\|can/AUX\|can#koennen` | s325, s326, s327 | 0 | s327 S |
| `be\|be/AUX\|be#hilfsverb` | s328, s329, s330 | 0 | – |
| `is\|be/AUX\|be#hilfsverb` | s331, s332, s333 | 0 | s331 K |
| `about\|about/ADV\|about#ungefaehr` | s334, s335, s336 | 7 | – |
| `this\|this/PRON\|this#dies_stellvertretend` | s337, s338, s339 | 0 | – |
| `in\|in/ADP\|in#in_raeumlich` | s340, s341, s342 | 0 | – |
| `with\|with/ADP\|with#bei` | s343, s344, s345 | 0 | – |
| `get\|get/VERB\|get#werden` | s346, s347, s348 | 2 | – |
| `up\|up/ADP\|up#entlang` | s349, s350, s351 | 0 | – |
| `a\|a/DET\|a#ein` | s352, s353, s354 | 0 | – |
| `her\|her/DET\|her#ihr_possessiv` | s355, s356, s357 | 0 | – |
| `so\|so/ADV\|so#ebenfalls` | s358, s359, s360 | 0 | – |
| `to\|to/ADP\|to#fuer_empfaenger` | s361, s362, s363 | 0 | – |
| `there\|there/ADV\|there#dort` | s364, s365, s366 | 0 | – |
| `or\|or/CCONJ\|or#oder` | s367, s368, s369 | 0 | s368 R |
| `have\|have/AUX\|have#hilfsverb` | s370, s371, s372 | 0 | – |
| `the\|the/DET\|the#bestimmter_artikel` | s373, s374, s375 | 0 | – |
| `or\|or/CCONJ\|or#andernfalls` | s376, s377, s378 | 3 | s378 S |
| `they\|they/PRON\|they#sie_plural` | s379, s380, s381 | 0 | s380 S |
| `has\|have/VERB\|have#muessen` | s382, s383, s384 | 0 | s384 S |
| `out\|out/ADP\|out#heraus_aus` | s385, s386, s387 | 3 | – |
| `on\|on/ADV\|on#weiter` | s388, s389, s390 | 1 | s390 R |
| `about\|about/ADP\|about#ueber_thema` | s391, s392, s393 | 1 | – |
| `had\|have/AUX\|have#hilfsverb` | s394, s395, s396 | 0 | – |
| `at\|at/ADP\|at#zeit` | s397, s398, s399 | 1 | s398 R, s399 KA |
| `has\|have/AUX\|have#hilfsverb` | s400, s401, s402 | 0 | – |
| `that\|that/DET\|that#jener` | s403, s404, s405 | 0 | s403 S, s404 S, s405 S |
| `were\|be/AUX\|be#sein_vergangenheit` | s406, s407, s408 | 0 | – |
| `just\|just/ADJ\|just#gerecht` | s409, s410, s411 | 3 | s409 R, s410 S |
| `all\|all/ADV\|all#vollstaendig_adv` | s412, s413, s414 | 0 | s413 K |
| `time\|time/NOUN\|time#zeit` | s415, s416, s417 | 0 | – |
| `so\|so/CCONJ\|so#deshalb` | s418, s419, s420 | 0 | – |
| `i\|I/PRON\|i#ich` | s421, s422, s423 | 0 | – |
| `their\|they/PRON\|they#ihr_plural` | s424, s425, s426 | 0 | – |
| `by\|by/ADP\|by#von_urheber` | s427, s428, s429 | 0 | – |
| `this\|this/DET\|this#dieser_begleitend` | s430, s431, s432 | 0 | – |
| `more\|much/DET\|much#mehr_menge` | s433, s434, s435 | 0 | – |
| `of\|of/ADP\|of#genitiv_besitz` | s436, s437, s438 | 0 | s436 S |
| `all\|all/PRON\|all#alles_pron` | s439, s440, s441 | 0 | s439 S |
| `will\|will/NOUN\|will#wille` | s442, s443, s444 | 1 | s442 R, s444 R |
| `at\|at/ADP\|at#ort` | s445, s446, s447 | 0 | – |
| `there\|there/PRON\|there#es_gibt` | s448, s449, s450 | 0 | – |
| `get\|get/VERB\|get#verstehen` | s451, s452, s453 | 7 | – |
| `he\|he/PRON\|he#er` | s454, s455, s456 | 0 | – |
| `so\|so/ADV\|so#so_sehr` | s457, s458, s459 | 0 | s459 S |
| `me\|I/PRON\|i#mir` | s460, s461, s462 | 0 | – |
| `no\|no/NOUN\|no#nein-stimme` | s463, s464, s465 | 2 | – |
| `you\|you/PRON\|you#man` | s466, s467, s468 | 2 | s466 R |
| `when\|when/ADV\|when#wann` | s469, s470, s471 | 0 | – |
| `no\|no/DET\|no#kein` | s472, s473, s474 | 0 | s474 R |
| `a\|a/ADP\|a#pro` | s475, s476, s477 | 0 | s477 S |
| `do\|do/VERB\|do#tun` | s478, s479, s480 | 3 | – |

### pos_check_v1 (10 Karten)

| Karte | Sätze | Alternativen | Befund |
|---|---|---|---|
| `are\|be/AUX\|be#sein_vollverb` | s1, s2, s3 | 0 | – |
| `was\|be/AUX\|be#hilfsverb` | s4, s5, s6 | 0 | – |
| `which\|which/PRON\|which#fragepronomen` | s7, s8, s9 | 2 | s9 R |
| `was\|be/AUX\|be#sein_vollverb` | s10, s11, s12 | 0 | – |
| `are\|be/AUX\|be#sein_hilfsverb` | s13, s14, s15 | 0 | – |
| `which\|which/DET\|which#determiner_auswahl` | s16, s17, s18 | 0 | – |
| `be\|be/AUX\|be#sein_existieren` | s19, s20, s21 | 0 | – |
| `which\|which/PRON\|which#relativpronomen` | s22, s23, s24 | 3 | s23 S |
| `be\|be/AUX\|be#hilfsverb` | s25, s26, s27 | 0 | – |
| `be\|be/AUX\|be#befinden` | s28, s29, s30 | 0 | s29 S |
