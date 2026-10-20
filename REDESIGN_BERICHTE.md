> Historische Designkritik und Recherche vom 18.10.2026; der folgende Inhalt bleibt als damaliger Befund erhalten. Aktuelle Anforderungen stehen ausschließlich in [DESIGN.md](DESIGN.md) und den dort verlinkten Bildschirmregeln. Alte Bildschirmbeschreibungen und Vorschläge dieses Berichts sind keine Rückbauanweisung.

# Ich habe CHATGPT Reddit Posts und Youtube-Transkripte auswerten lassen. Du musst sie nicht blind befolgen, es dient nur als Inspiration.

# Bericht zu meiner aktuellen UI

# Welche Teile der Sprachapp nach AI Slop aussehen

Stand: 18. Oktober 2026. Bewertung der implementierten Oberfläche anhand der lokalen YouTube-Transkripte, Reddit-Diskussionen und Referenzbilder.

**Deine App hat eine erkennbare gestalterische Richtung, trägt aber auf den Übersichtsseiten noch deutlich die Struktur eines generischen Dashboards.** Am stärksten entsteht der AI-Slop-Eindruck durch die Menge der gleichzeitig sichtbaren Statistiken und Aktionen, durch wiederkehrende umrandete Karten und durch Cover, die Platzhalter bleiben. Der eigentliche Lerninhalt ist wesentlich spezifischer gestaltet: Satz, Lücke, Übersetzung und Wortinformationen haben einen nachvollziehbaren Bezug zum Sprachenlernen.

Ein bloßer Austausch von Violett, Schrift oder Eckenradien würde die wichtigsten Probleme deshalb kaum lösen. Entscheidend ist, welche Information zuerst erscheint, welche Handlung daraus folgt und welche sichtbaren Elemente tatsächlich etwas leisten.

## Grundlage und Grenzen

Zuerst habe ich die Sprachapp untersucht, danach die Materialien in `aislop`. Gelesen wurden alle 14 JSON-Dateien, die vier bereits vorhandenen Markdown-Dateien und das vollständige RTF mit acht Transkripten; außerdem habe ich die fünf Bilder betrachtet. Die Ordner `ui_prinzipien`, `ui_prinzipien2` und `onboarding` wurden nicht als Quellen gelesen. Die macOS-Datei `.DS_Store` enthält keine fachliche Quelle.

Der im Hauptordner vorhandene Bericht über `ui_prinzipien` wurde als bestehende Vorarbeit gelesen. **Seine Empfehlungen aus dem ausgeschlossenen Material werden für diese Bewertung nicht als Belege verwendet.** Gleiches gilt für entsprechende Passagen des alten App-Reviews. Die unten genannten Urteile stützen sich auf die ursprünglichen AI-Slop-Quellen und den aktuellen App-Code.

Geprüfter App-Stand: Arbeitsverzeichnis auf Commit `67386c7`, einschließlich vorhandener uncommitteter Änderungen. GitNexus ist an `sprachlernapp` gebunden; der Index vom 18. Oktober, 14:39 Uhr Berliner Zeit, nennt denselben Commit. Wegen der Arbeitskopie sind die direkt gelesenen Dateien für die konkreten Befunde maßgeblich.

Die Bewertung ist überwiegend **codebasiert**. Zwei vorhandene Testbilder wurden ergänzend betrachtet. Das Übungsbild nutzt laut Testcode Arial und Georgia als Ersatzschriften; das Settings-Bild zeigt Testschrift-Blöcke und ist zur ästhetischen Bewertung ungeeignet. Es lief kein Simulator, und ich habe keine neuen Simulator-Aufnahmen erzeugt. Aussagen über tatsächliche Blickverläufe, exakte sichtbare Zeilenanzahlen oder die Wirkung auf reale Nutzer sind daher Designhypothesen, keine Messergebnisse. Die im alten Review verlinkten `app_review_screenshots` sind im untersuchten Ordner nicht vorhanden.

„AI Slop“ bezeichnet hier die in deinen Quellen kritisierten Gestaltungsmuster. Es ist **kein Nachweis, dass ein bestimmtes Element von einer KI stammt**. Die Threads enthalten subjektive Urteile, Werbung und widersprüchliche Empfehlungen. Auch die vom unslop-ui-Autor behauptete große Reddit-Auswertung ist innerhalb dieser Sammlung nicht unabhängig überprüft.

## Die wichtigsten Befunde

| Bereich | Wie stark das kritisierte Muster zutrifft | Konkreter Grund |
|---|---|---|
| Home | Stark | Wochenübersicht und ausführliche Statistik kommen vor den konkreten Lerninhalten |
| Inhalte in der englischen Oberfläche | Stark | Vier gleich aufgebaute Kacheln mit Icon, Titel und Anzahl |
| Wortliste | Stark | Viele permanente Aktionen und Verwaltungsinformationen pro Wort |
| Stories | Stark | Wiederholte Platzhalter-Cover; aktuell werden alle Bibliotheksgeschichten als „Alltag“ einsortiert |
| Stapel-Details | Mittel bis stark | Mehrere Container und ähnlich benannte Lernaktionen; zusätzliche Überschriften um eine einzige Nebenfunktion |
| Profil und Leerzustände | Konkrete Funktions- und Textprobleme | Sichtbarer Profilknopf ohne Handlung; leere Wortliste als erfolglose Suche formuliert |
| Story-Karten im hellen Modus | Konkreter Darstellungsfehler | Dunkle Schrift auf weiterhin dunklem Cover |
| Farben, Schrift und Navigation | Nur eingeschränkt | Einige bekannte Formen, aber überwiegend nachvollziehbare Funktion und eigene Gestaltung |

Die Stärke bewertet die Übereinstimmung mit den Quellenmustern. Sie ist kein numerischer „KI-Anteil“.

## Home zeigt zuerst die Verwaltung des Lernens

Der Aufbau ist im [Home-Screen](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/home/home_screen.dart:68) klar festgelegt: Sprache und Kopfaktionen, Wochenkarte mit Tagesziel, Vokabelstatistik, aktive Stapel, zuletzt Stories. Die Statistik zeigt die verfügbaren Wiederholungen, einen segmentierten Balken und drei Zustandszeilen. Wenn die Wortstatistik vorliegt, kommen „Wörter“, „Davon bereits geübt“ und die Erklärung „Ein Wort kann mehrere Übungen haben“ hinzu. Siehe [VocabProgress](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/home/widgets/vocab_progress.dart:65).

**Das sieht nach einem zusammengestellten Fortschrittsdashboard aus, bevor es nach einer konkreten Lernsituation aussieht.** Es ist nicht exakt das Beispiel aus Video 5: Eine große Begrüßung und eine Reihe von Schnellaktionen fehlen. Die entscheidende Ähnlichkeit bleibt aber bestehen: Eine Zusammenfassung und zahlreiche Kennzahlen definieren den Einstieg, während die eigentliche Beschäftigung weiter unten folgt.

Video 2 kritisiert, dass KI-Oberflächen zusätzliche Informationen auf die oberste Ebene ziehen, um leistungsfähig auszusehen. Video 5 beschreibt die Standardkomposition mobiler Apps und die fehlende Gewichtung. Nick Babich verlangt in Video 4 und seinem Screenshot, dass ein Sprachlern-Home den nächsten Lernschritt erkennbar macht. Der Reddit-Kommentar von `Funny-Field-8268` kritisiert an einer anderen Lern-App ebenfalls die Überlagerung mehrerer Fortschrittsansichten. [V2, V4, V5, R6]

Bei dir sind die Zahlen fachlich sinnvoll. Das Problem ist ihre **gleichzeitige prominente Platzierung**. Die Unterscheidung zwischen Wörtern und Übungen muss stimmen; sie braucht jedoch nicht zwingend beim täglichen Einstieg fünf Statistikzeilen und eine Fußnote. Die Zeilen selbst sind bereits zurückhaltender gestaltet als fünf einzelne Statistik-Karten.

Hinzu kommt eine Trennung von Information und Handlung: „… Wiederholungen verfügbar“ ist im Widget Text, keine Aktion. Der Start liegt im zentralen Play-Knopf der Bottom-Bar. Dieser ist erreichbar und sichtbar, erklärt aber an seiner Position weniger konkret, was als Nächstes geübt wird. Das ist eine Priorisierungsfrage, kein Nachweis schlechter Bedienbarkeit.

**Passende Änderung:** Direkt beim Wiederholungsbedarf eine klar benannte Handlung anbieten, etwa „Jetzt wiederholen“. Die ausführliche Statistik über „Lernfortschritt“ erreichbar machen. Einen konkreten Lese- oder Lerninhalt früher zeigen. Einen zusätzlichen Statistikblock braucht man dann nur, wenn er die Entscheidung für den nächsten Schritt unterstützt. Zeitangaben sollten nur erscheinen, wenn die App sie belastbar bestimmen kann.

Das wäre auch näher an der eigenen Produktpositionierung: [PRODUCT.md](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/PRODUCT.md:31) beschreibt eine vom Lesen ausgehende Lernerfahrung. Auf Home steht diese Besonderheit derzeit hinter der Verwaltung.

## Das Inhalte-Raster ist der austauschbarste Screen

Für Englisch besteht „Inhalte“ aus Texte, Hören, Grammatik und Grammatikregeln. Jede Kachel verwendet dieselbe Bauform: mindestens 132 logische Pixel Höhe, 16 Pixel Innenabstand, 12 Pixel Radius, helle Oberfläche, Haarlinienrahmen, ein 28-Pixel-Icon oben und darunter Titel plus Anzahl. Die vier Einträge stammen aus [AppShell](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/app_shell.dart:78), die Gestaltung aus [_CategoryCard](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/content/content_dashboard_screen.dart:98).

**Hier passt die Kritik an identischen Feature-Karten unmittelbar.** Video 4 nennt dieses Muster ausdrücklich. Video 5 kritisiert die immer gleiche Kombination aus Icon, Titel und Beschreibung sowie die gleiche Gewichtung aller Funktionen. `idolikeglitter` nennt auf Reddit Teaser-Boxen mit Icon oben links. [V4, V5, R2]

Die vier Kategorien sind sinnvoll und schnell erlernbar. Trotzdem verrät die Fläche wenig darüber, was man tatsächlich lesen, hören oder üben kann. Mit anderen Beschriftungen könnte dasselbe Raster eine Fitness-, Finanz- oder Produktivitäts-App organisieren. Die Zähler verstärken die Katalogwirkung: Sie zeigen den Umfang, aber keinen interessanten Inhalt.

**Passende Änderung:** Die Kategorien können bleiben, sollten aber einen echten Inhalt vermitteln: etwa den Titel einer verfügbaren Hörübung oder den nächsten Grammatikgegenstand. Eine kompakte Liste wäre eine mögliche Form; eine bewusst gewichtete Darstellung mit einem konkreten Vorschlag wäre eine andere. Vier Karten durch vier identische Zeilen zu ersetzen, ohne den Inhalt zu verbessern, wäre allein noch kein großer Gewinn.

Wichtig für den aktuellen Stand: Portugiesisch zeigt an dieser Stelle momentan einen Verfügbarkeitstext, nicht das Raster. Der Befund gilt daher nicht unverändert für beide Lernsprachen. Ein Buchstaben-Icon wie `textformat` ist außerdem nicht automatisch ein Stilbruch; es gehört hier zum gleichen Cupertino-Set und hat einen nachvollziehbaren Bezug zu Sprache.

## Die Wortliste macht jedes Wort zu einer kleinen Bedienkonsole

Ein Eintrag enthält die antippbare Erinnerungsstufe, das vorlesbare Wort, den vorlesbaren Beispielsatz, Metadaten über letzte Nutzung und Wiederholungen sowie rechts drei Schalter für Deaktivierung, Playlist und Favorit. Dazu kommt ein separater Detailpfeil. Es gibt also wesentlich mehr Interaktionsangebote als nur die vier auffälligen Symbole auf der rechten Seite. [WordListItem](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/words/widgets/word_list_item.dart:79)

Das trifft den zweiten Punkt aus Video 2 sehr genau: **Jede mögliche Aktion ist sofort sichtbar, obwohl nicht alle ständig benötigt werden.** Der Vergleich dort betrifft Auge- und Kopier-Symbole pro Tabellenzeile. Bei dir wird dieses Prinzip auf Vokabeln übertragen. Die Reddit-Kritik an vielen Icons und überladener Informationsarchitektur ergänzt diesen Befund. [V2, R2]

Die Oberfläche kann dadurch sorgfältig und funktionsreich wirken, zugleich aber wie eine automatisch vervollständigte Verwaltungsliste. Ein Nutzer muss bei jedem Wort mehrere identisch gewichtete Möglichkeiten übersehen, um einfach weiterzulesen. Die rechte Bedienfläche verringert zusätzlich den Platz für Wort und Beispielsatz. Die genauen Umbrüche hängen von Gerät, Inhalt und Schriftgröße ab.

**Positiv:** Die Einträge sind bereits echte Listenzeilen ohne umlaufenden Kartenrahmen. Das ist eine gute Entscheidung und sollte erhalten bleiben.

**Passende Änderung:** Vorlesen direkt lassen und anhand der tatsächlichen Nutzung höchstens eine weitere häufige Aktion prominent anbieten. Deaktivierung, Playlist-Verwaltung und ausführliche Lernhistorie können über die Details oder ein klar erkennbares Menü zugänglich sein. Welche Funktion herausgehoben wird, sollte aus der Nutzung folgen; „alle Icons weg“ wäre genauso pauschal wie „alle Icons sofort zeigen“.

## Die Story-Cover zeigen noch keine eigene redaktionelle Auswahl

Der stärkste konkrete Befund liegt vor dem Zeichnen der Karten: Der aktuelle [Bibliotheks-Provider](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/presentation/providers/story_learning_providers.dart:106) setzt bei jeder erzeugten Story `topic: 'Alltag'` und übergibt kein Cover. Dadurch landet die normale Bibliothek auf dem typografischen Ersatz-Cover. Die Gruppierung nach Themen in der Stories-Ansicht kann aus diesen Daten auch keine tatsächliche Themenvielfalt erzeugen.

Das [TypeCover](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/home/widgets/story_carousel.dart:138) verwendet drei dunkle Töne und setzt das Themenwort mit neun Prozent Textdeckkraft groß in eine absichtlich beschneidende Fläche. Die Karten sind fest 140 × 200 Pixel groß; der eigentliche Titel darf drei Zeilen, die Metazeile eine Zeile belegen.

**Der Effekt ist eine Reihe ähnlich aussehender Verpackungen, deren großer Bildbereich kaum etwas über die jeweilige Geschichte sagt.** Das ist die Verbindung von Wiederholung, Platzhalterinhalt und austauschbarer Komposition aus Video 5. Die Infografik nennt verwandte Muster als „repetitive patterns“ und „perfect but empty“. Video 6 empfiehlt konkrete Bilder als Gegenmittel; diese Empfehlung stammt allerdings aus einem werblichen Energy-Drink-Beispiel und ist kein Beweis, dass deine App Fotos braucht. [V5, V6, B1]

Eine absichtlich angeschnittene Schrift kann ein gutes redaktionelles Motiv sein. Hier wird sie problematisch, weil das wiederholte Themenwort den einzelnen Inhalt kaum unterscheidet und der Code das Element selbst als Übergangslösung beschreibt. **Das fehlende Bild ist weniger wichtig als die fehlende inhaltliche Unterscheidung.**

**Passende Änderung:** Zuerst die tatsächlichen Themen und Metadaten korrekt aus dem Inhalt beziehen. Dann eine endgültige Cover-Entscheidung treffen: individuelle typografische Titelgestaltung, ein kurzer Textauszug oder eine konsistente Bildsprache. Bis passende Bilder existieren, kann eine kleinere, titelbetonte Darstellung besser funktionieren als ein großer reservierter Coverbereich.

Bei Nachrichten ist das Flächenverhältnis besonders deutlich: [NewsCard](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/stories/widgets/news_carousel.dart:81) reserviert 60 Prozent einer 340 Pixel hohen Karte für Bild oder Ersatz-Cover. Bei fehlendem Bild erhält ein blasses Kategorienwort damit 204 Pixel Höhe. Das ist viel Aufmerksamkeit für wenig zusätzliche Information.

## Stapel-Details erklären eine einfache Auswahl mit vielen Bausteinen

Die Detailseite kombiniert Fortschritt, eine umrandete Schalterfläche „Stapel lernen“, den Primärbutton „Lerne mit diesem Stapel“, gegebenenfalls eine aufklappbare Fläche mit zuletzt geübten Formen und danach „Mehr davon“ samt Untertitel. Darunter folgt eine weitere Karte „Stapel-Revue“ mit Erklärung und eigenem umrandetem Button. [Seitenaufbau](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/decks/deck_details_screen.dart:94), [Revue-Karte](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/decks/deck_details_screen.dart:510)

Hier entsteht der Eindruck, jede kleine Information brauche einen eigenen fertig gestalteten Abschnitt. Das entspricht der Karten- und Rahmenkritik aus Video 1 und 2 sowie der Containerkritik aus Video 5. Es ist keine beliebig tiefe Verschachtelung von Karten; konkret liegt unter anderem ein umrandeter Button innerhalb einer umrandeten Karte. [V1, V2, V5]

Besonders unnötig wirkt die Hierarchie **„Mehr davon“ → „Inhalte rund um diesen Stapel“ → „Stapel-Revue“ → Erklärung → Button**. Der Abschnitt bietet im gelesenen Code eine einzelne Wiederholungsfunktion, keine Auswahl ergänzender Inhalte. Die zwei äußeren Texte geben ihr mehr redaktionelle Bedeutung, als der Inhalt einlöst. Das ist ein konkretes Beispiel für die überflüssigen Zwischenüberschriften und Untertitel aus Video 2.

Außerdem klingen „Stapel lernen“ und „Lerne mit diesem Stapel“ fast gleich, obwohl der Schalter die Teilnahme neuer Wörter an der gemischten Übung steuert und der Button eine Sitzung startet. Diese Unterscheidung ist fachlich berechtigt, sprachlich aber schlecht sichtbar.

**Passende Änderung:** Den Sofortstart „Jetzt mit diesem Stapel üben“ nennen und die Aktivierung als eigenständige Einstellung verständlich beschriften, etwa „Neue Wörter in die tägliche Übung aufnehmen“. Die Revue direkt als Nebenaktion mit kurzer Erklärung anbieten. Erst danach entscheiden, welche Flächen und Rahmen zur Gruppierung noch nötig sind.

## Kleine Funktionslücken lassen die Oberfläche wie einen Prototyp wirken

### Der Profilknopf hat kein Ziel

In [AppShell](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/app_shell.dart:143) ist `_notYetRouted()` leer. Der Home-Screen erhält genau diese Funktion als `onProfile`. Der sichtbare Knopf verspricht damit eine Handlung, die nicht stattfindet.

`idolikeglitter` nennt „Dead ctas“ ausdrücklich als typisches Detail. Video 5 kritisiert Oberflächen, die vollständig aussehen, aber die tatsächlichen Produktdetails auslassen. [R2, V5]

**Das ist ein belastbarer Funktionsbefund, keine Geschmacksfrage.** Bis es einen sinnvollen Profilbereich gibt, sollte das Icon verschwinden oder ein tatsächliches Ziel erhalten. Ein schöneres Profil-Icon würde hier nichts verbessern.

### Die leere Wortliste spricht von einer Suche

Der leere Zustand verwendet [dieselben Worte unabhängig vom Suchbegriff](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/words/word_list_screen.dart:213): „Keine Wörter für …“. Bei leerer Suchanfrage ergibt sich „Keine Wörter für „““. Ein Nutzer ohne gespeicherte Wörter bekommt damit die Sprache eines Suchfehlers.

Das passt zur Kritik aus Video 5, dass plausible Oberflächen die tatsächlichen Zustände eines Produkts nicht sauber abbilden. **Passende Änderung:** Zwischen leerer Sammlung und erfolgloser Suche unterscheiden. Für eine leere Sammlung erklären, wie das erste Wort hineinkommt, und einen erreichbaren nächsten Schritt anbieten. Dafür braucht die App weder Maskottchen noch zusätzliche Dekoration.

### Nachrichten versprechen mehr Aktualität als der sichtbare Status hergibt

Die englische Oberfläche erhält in [AppShell](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/app_shell.dart:217) `sampleNews`. Die Überschrift lautet „Nachrichten · Demo“; unmittelbar darunter steht „Wöchentlich aktualisierte Nachrichten zu deinen Lieblingsthemen zusammengefasst“. [StoryLibraryScreen](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/stories/story_library_screen.dart:27)

Die Demo-Kennzeichnung ist ehrlich. Der Untertitel erzeugt dennoch eine Erwartung an Aktualität und Auswahl, die dieser Codepfad nicht belegt. Das ist eine stärkere Kritik als die Behauptung, das Wort „Demo“ selbst sei Slop. **Die Kennzeichnung nur zu entfernen würde das Problem verschlimmern.** Für Demo-Inhalte sollte auch die Beschreibung den Demo-Charakter korrekt wiedergeben. [V5, B1]

## Der helle Modus deckt eine unvollständig angepasste Komponente auf

Die Story-Karte verwendet einen fest dunklen Verlauf und dunkle Ersatz-Cover, während Titel und Metadaten über die aktuelle Palette eingefärbt werden. Im hellen Modus wird `textPrimary` zu `#202632`, also dunkel. Damit landet dunkle Schrift auf der weiterhin dunklen Bildfläche. [StoryCard](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/home/widgets/story_carousel.dart:90), [AppPalette](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/theme/app_theme.dart:15)

Das ist keine Abneigung gegen dunkle Cover. Es ist eine unvollständige Abstimmung zwischen einer festen Oberfläche und wechselnden Textfarben. Die Kritik von `beikbeikbeik` trifft den Eindruck gut: Einzelteile können sorgfältig gestaltet sein, während eine grundlegende Entscheidung danebenliegt. [R2]

**Passende Änderung:** Die Karten als in sich geschlossene dunkle Cover behandeln und dazu passende helle Textfarben beibehalten, oder Cover, Verlauf und Text gemeinsam für Hell und Dunkel gestalten. Anschließend beide Modi visuell prüfen.

Die Nachrichtenkarte ist davon zu unterscheiden: Ihr Titel sitzt auf einer eigenen, themenabhängigen Fläche unterhalb des Covers. Dort ist nicht derselbe Titelkontrastfehler belegt. Das blasse Masthead auf dem weiterhin dunklen Ersatz-Cover kann im hellen Modus allerdings noch weniger sichtbar werden.

## Rahmen und Statuszeichen erzeugen mehr UI als nötig

Eine aktive [Stapel-Kachel](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/home/widgets/deck_tile.dart:28) kombiniert getönten Hintergrund, orange Kontur, Icon im Fortschrittsring, Prozentangabe, drei Schwierigkeitsblitze und „Aktiv“. Jede Information hat einzeln eine Erklärung. In Kombination entsteht jedoch eine hohe Menge an visuellen Zeichen um einen einzigen Titel.

Die Wiederholung derselben Oberflächenform in Wochenkarte, Stapel-Kacheln, Inhaltskacheln, Weiterlesen-Kachel und Detailabschnitten verstärkt den Eindruck eines Baukastens. Das passt zu den Hinweisen auf übermäßige Rahmen, wiederkehrende Container und zu viele Details. [V1, V2, V5, R2]

Dabei sollten zwei Dinge nicht verwechselt werden: „Aktiv“ zusätzlich zur Farbe ist eine hilfreiche redundante Kennzeichnung. Und ein 52-Pixel-Ring um das Stapel-Icon beziehungsweise ein 72-Pixel-Ring um den Lernknopf ist **nicht automatisch der übergroße Fortschrittsring**, den Babich kritisiert.

Bei den Blitzen ist der Bedeutungsbezug schwächer. In der Kachel benennt nur die Screenreader-Beschreibung die Schwierigkeit; sichtbar stehen drei Blitze. Diese könnten ohne Vorkenntnis auch Energie oder Intensität bedeuten. Auf der Detailseite steht der ausgeschriebene Schwierigkeitsgrad dagegen daneben. [DifficultyBolts](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/widgets/difficulty_bolts.dart:14)

**Passende Änderung:** Für jeden Träger einzeln prüfen, ob sein Wegfall Information kostet. In der Stapelliste wäre ein sichtbares Niveau leichter zu verstehen als eine zusätzliche Symbolsprache. Bei Karten, die schon durch Abstand und Tonfläche klar getrennt sind, kann die umlaufende Kontur entfallen. Das rechtfertigt kein pauschales Verbot aller Rahmen.

## Die Texte sind überwiegend sachlich und stellenweise zu erklärend

Die typischen Marketingfloskeln aus Video 3 und 5 sind in den geprüften Kernoberflächen nicht das Hauptproblem. „Wortliste“, „Tagesziel“, konkrete Wortformen und Satzübersetzungen haben eine klare Funktion.

Eher fällt auf, dass die App an prominenten Stellen ihr eigenes System erklärt: die Wort/Übungs-Fußnote auf Home, der Aufbau um „Stapel-Revue“ und am Sitzungsende ein Absatz über neue Übungen, Stufen, Fehler und Hinweise. Die [Sitzungszusammenfassung](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/decks/deck_practice_screen.dart:705) nennt zudem „… zurück auf Stufe 1“.

Diese Texte sind konkret, also **keine leeren KI-Floskeln**. Die Verbindung zu Video 2 liegt in der Platzierung: Die vollständige Regelerklärung beansprucht Raum, obwohl der Nutzer gerade vor allem verstehen möchte, was er geübt hat und wie es weitergeht. Die Regeln können über eine Hilfe erreichbar bleiben. Eine knappe Ergebniszusammenfassung würde den tatsächlichen Lerninhalt stärker hervorheben. [V2]

Kleine Textdetails wie „1 Übungen gemeistert“ bleiben ebenfalls im aktuellen [Stapel-Fortschritt](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/decks/deck_details_screen.dart:281) möglich. Sie sind kein eigener Slop-Stil, verstärken aber den Eindruck, dass der Entwurf nicht durch alle Zustände hindurch ausgearbeitet wurde.

## Was ich ausdrücklich nicht als AI Slop bewerten würde

**Figtree und Source Serif 4 haben unterschiedliche Aufgaben.** Der Code trennt Bedienoberfläche und Lerninhalt. Das ist eine produktspezifische Entscheidung, nicht einfach „Serif plus Sans ist KI“. Die in Reddit besonders genannte Instrument Serif ist hier gar nicht die eingesetzte Schrift. [AppType](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/theme/app_theme.dart:93)

**Violett und Orange besitzen eine Bedeutung.** Sie markieren gemeisterte und aktive Inhalte. Die Reddit-Kritik an beliebigem Lila auf dunklem Grund lässt sich nicht unverändert darauf übertragen. Besonders der Rhystic-Tracker-Kommentar warnt davor, beim Entfärben nützliche Semantik zu verlieren. Ein Farbwechsel wäre für mich nachrangig. [R4, V5]

**Der dunkle Grund und 12-Pixel-Radien sind für sich unauffällig.** Kritisch wird die dauernde Wiederholung derselben Gruppierung, nicht der einzelne Radiuswert. Auch ein heller, cremefarbener Ersatzlook wäre nach den unslop-ui-Kommentaren keineswegs automatisch eigenständiger. [R7]

**Der Verlauf auf Story-Covern ist funktional gedacht.** Er soll Text vom Bild abheben. Deshalb wäre die Aussage des alten Reviews „keine Verläufe“ für den Code falsch. Der vorhandene Verlauf ist zugleich nicht das lila-blaue Dekorationsmuster aus den Quellen; sein konkretes Problem ist die unpassende Light-Mode-Schrift.

**Die Bottom-Bar braucht keine Neuerfindung.** Sie trennt vier Bereiche und hebt Lernen hervor. Ob der mittlere Play-Knopf ausreichend verständlich ist, lässt sich testen. Dass er rund ist und einen Fortschrittsring besitzt, macht ihn nicht schon zu Dekoration.

**Die Segmented Controls werden überwiegend im Kontext eingesetzt.** Video 2 kritisiert solche Controls als Hauptnavigation ganzer Websites. Daraus folgt kein Verbot der lokalen Filter und Ansichtswechsel deiner mobilen App.

**Reader und Satzübung haben einen konkreten Zweck.** Eine Lesefläche mit begrenzter Breite, Wortnachschlagen, Übersetzung und einer Lücke im Satz ist deutlich weniger austauschbar als das Inhalte-Raster. Das vorhandene Übungs-Testbild bestätigt die grundsätzliche Anordnung; der echte Schriftcharakter und alle Gerätezustände sind damit nicht geprüft. [Reader](/Users/ardasayar/Documents/FlutterProjekte/sprachapp/lib/screens/stories/story_reader_screen.dart:430)

## Reihenfolge der Verbesserungen

1. **Unvollständige Zustände schließen:** Profilknopf, leere Wortliste, Story-Kontrast im hellen Modus und Demo-Beschreibung. Diese Punkte haben eine konkrete sachliche Grundlage und benötigen keinen neuen visuellen Stil.
2. **Home auf den nächsten Lernschritt ausrichten:** Wiederholungen und Start zusammenbringen, Detailstatistik nachrangig machen, konkrete Inhalte früher zeigen. Das dürfte den Gesamteindruck stärker verändern als eine neue Palette.
3. **Stories inhaltlich unterscheidbar machen:** echte Themen übernehmen und die dauerhaften Platzhalter-Cover durch eine bewusste Darstellung ersetzen.
4. **Wortliste entlasten:** häufige Aktionen erhalten, seltenere in eine zweite Ebene verschieben; danach mit langen Wörtern, langen Sätzen und großer Schrift prüfen.
5. **Inhalte und Stapel-Details vereinfachen:** konkrete Lernangebote statt bloßer Funktionskacheln; verständliche Aktionsnamen; überflüssige Überschriften und Container entfernen.
6. **Erst danach die Formdetails abstimmen:** Konturen, Statusringe, Blitze und Abstände im Zusammenhang beurteilen.

Für die nächste visuelle Prüfung wären Home mit wenig und viel Lernfortschritt, eine gefüllte Wortliste, Stories in beiden Motiven und Stapel-Details besonders aussagekräftig. Der Vergleich sollte mit denselben Daten und derselben Schriftgröße erfolgen. Entscheidend sind einfache Aufgaben: den nächsten Lernschritt finden, eine Story auswählen, ein Wort anhören und den Unterschied zwischen Stapel-Aktivierung und Sitzungsstart verstehen.

## Quellen und Zuordnung

Die Kürzel beziehen sich auf die lokal gespeicherten Originaltexte. Aussagen über deine App sind meine Übertragung der dort beschriebenen Muster auf den verlinkten Code. Externe Links innerhalb der Exporte wurden nicht als zusätzliche Quellen geöffnet.

| Kürzel | Lokale Quelle | Für die Bewertung relevant |
|---|---|---|
| V1 bis V8 | [Vollständige Transkripte](/Users/ardasayar/Documents/aislop/transkripte_ueber_aislop.rtf) | V1 Rahmen und Feinarbeit; V2 Hierarchie und permanente Aktionen; V3 Schreibfloskeln; V4 Sprachlern-Home; V5 sieben UI-Muster; V6 Typografie, Farbe und Bilder; V7 Qualitätsmaßstab; V8 überprüfbare Produktfunktion. Die Datei vergibt „7“ zweimal; das letzte Video ist hier V8. |
| V4 Bilder | [Verbotsliste](</Users/ardasayar/Documents/aislop/Screenshots aus Video aus Transkript nr 4 (transkripte_ueber_aislop)/Bildschirmfoto 2026-10-17 um 20.13.19.png>) und [Referenzprinzipien](</Users/ardasayar/Documents/aislop/Screenshots aus Video aus Transkript nr 4 (transkripte_ueber_aislop)/Bildschirmfoto 2026-10-17 um 20.13.28.png>) | Konkretes Sprachlern-Beispiel von Nick Babich. Auch Ausgangsprompt und Adjektivliste wurden betrachtet. |
| R1 | [Beautiful UIs statt generic AI slop](/Users/ardasayar/Documents/aislop/How-are-people-actually-getting-Claude-to-build-beautiful-UIs-instead-.json) | Produktentscheidungen, Referenzen, visuelle Prüfung; deutliche Gegenstimmen zu automatischen Anti-Slop-Lösungen |
| R2 | [How can you tell a design is AI](/Users/ardasayar/Documents/aislop/How-can-you-tell-a-design-is-AI.json) | `idolikeglitter`: tote Aktionen und Teaser-Karten; `justynmx7`: Icons und unpassende Symbole; `beikbeikbeik`: gute Einzelteile bei schlechten Grundentscheidungen |
| R3 | [How do you make AI generated UI not look like AI slop](/Users/ardasayar/Documents/aislop/How-do-you-make-AI-generated-UI-not-look-like-AI-slop.json) | `Reign712` und `spacepiratekoko`: Informationshierarchie; Inhalte als Teil des Designs |
| R4 | [How to avoid AI default design](/Users/ardasayar/Documents/aislop/How-to-avoid-AI-default-design-Help-Please.json) | `Ok_Advertising_3952`: Dichte und semantische Farben; `RemarkableWish2508`: Nutzbarkeit vor Stiletikett |
| R5 | [How to break away from AI slop design](/Users/ardasayar/Documents/aislop/How-to-break-away-from-AI-slop-design-Real-practical-and-working-advic.json) | Feinarbeit, konsistente Icons; widersprüchliche Tool-Empfehlungen |
| R6 | [What are the signs of an AI slop UI](/Users/ardasayar/Documents/aislop/What-are-the-signs-of-an-ai-slop-ui.json) | `Funny-Field-8268`: überladene Lernübersicht; `ChckBroccoliAlfredo`: Rahmen und Kontrast |
| R7 | [unslop ui Diskussion](/Users/ardasayar/Documents/aislop/unslop-ui-a-Claude-skill-that-flags-and-removes-the-design-patterns-th.json) | Ein anderer Farb- und Schrifttrend löst Austauschbarkeit nicht automatisch |
| R8 | [Avoiding AI slop and consistent UIs](/Users/ardasayar/Documents/aislop/Avoiding-AI-slop-and-vibe-coding-aesthetic-and-consistent-UIs.md) | `geoffreybyers`: funktionaler Erfolg; `Stibi`: System plus tatsächliche Prüfung |
| R9 | [Mobbin ScreenDesign Refero](/Users/ardasayar/Documents/aislop/Mobbin-ScreenDesign-Refero-How-to-get-the-best-out-of-it-in-mobile-dev.json) | `nikhil_akki`: konsistentes System und Abläufe statt zusammenkopierter Screens |
| R10 | [Mobile app UI prototypes](/Users/ardasayar/Documents/aislop/How-to-create-mobile-app-UI-prototypes-and-avoid-an-AI-slop.json) | Sorge vor unterschiedlichen Stilen pro Bereich |
| R11 | [Mobbin MCP Workflow](/Users/ardasayar/Documents/aislop/Ive-been-using-Mobbin-MCP-with-Claude-for-a-week-Heres-how-it-fits-int.json) | Referenzen als Vergleichssignal, nicht als Beweis einer guten Entscheidung |
| R12 | [Mobbin users](/Users/ardasayar/Documents/aislop/Mobbin-users-How-to-use-it-properly.json) | Recherchewerkzeuge; keine eigenständige Evidenz für Fehler der Sprachapp |
| R13 | [UI got called AI slop](/Users/ardasayar/Documents/aislop/ui-got-called-ai-slop-I-am-redoing-it-by-hand-and-it-keeps-coming-out-.json) | Produktspezifität und Überarbeitung anhand konkreter Kritik |
| R14 | [AI is making me a sloppier UI designer](/Users/ardasayar/Documents/aislop/AI-is-quietly-making-me-a-sloppier-UI-designer---and-I-think-I-know-wh.json) | Nachlassende Detailprüfung als Erfahrungsbericht; keine belastbare Diagnose der Entstehung deiner App |
| B1 | [Infografik](</Users/ardasayar/Documents/aislop/Bildschirmfoto 2026-10-17 um 20.33.25.png>) | Wiederholung, leere Politur und unbelegte Aussagen; allgemeine Heuristik |

Die ebenfalls gelesene [SideStore-Diskussion](/Users/ardasayar/Documents/aislop/Potential-fix-for-recent-503-error-and-Sidestore-not-loading-error.json) betrifft Installationsprobleme und liefert keine UI-Kriterien. Die vorhandenen Berichte `BERICHT_AI_Slop.md`, `BERICHT_UI_Prinzipien_Sprachapp.md` und `BERICHT_App_Review_Sprachapp.md` wurden als Vorarbeiten gelesen, nicht als unabhängige Bestätigung gezählt.

**Mein Urteil:** Am meisten nach AI Slop sehen die Stellen aus, an denen dieselbe Karten- und Verwaltungslogik wichtiger wird als der konkrete Lerninhalt. Die App gewinnt am ehesten an Eigenständigkeit, wenn sie ihre bereits vorhandene Stärke sichtbarer macht: Wörter in sinnvollen Sätzen und Geschichten, mit klaren, unmittelbar verständlichen Lernhandlungen.


# Bericht zu einer guten UI

# Gute UI/UX für Mobile Apps: Auswertung der Videos und ergänzenden Diskussionen

Stand: 20. Oktober 2026. Grundlage: sämtliche Textinhalte aus `ui_prinzipien` und `ui_prinzipien2` – 31 nummerierte Video-Transkripte sowie 13 Reddit-Dateien. Die Videos bilden die Hauptquelle; Reddit ergänzt insbesondere Umsetzung, Spacing und Zusammenarbeit mit Entwicklern. Der separate Ordner `onboarding` gehört nicht zu dieser Auswertung.

**Die gemeinsame Kernaussage: Eine gute Mobile App macht ihre wichtigste Aufgabe leicht, erklärt ihren Zustand und wirkt über alle Screens hinweg wie ein bewusst gestaltetes Produkt.** Abstände, Farben, Typografie und Animationen unterstützen dieses Ziel. Eine attraktive Startseite allein reicht ebenso wenig wie eine Sammlung hübscher Komponenten.

Der erste Ordner behandelt überwiegend visuelles und interaktives Handwerk. Der zweite erweitert das um eine erkennbare Produktidee, vollständige Nutzerabläufe, Fehlerbehandlung, Onboarding und Wiederkehr. Einige Videos verfolgen dabei ausdrücklich das Ziel maximaler Bindung und Monetarisierung. Diese Zielsetzung ist nicht durchgehend mit guter UX gleichzusetzen.

## Leseschlüssel und Aussagekraft

- **A1–A16:** Nummern im [ersten Transkript](/Users/ardasayar/Documents/aislop/ui_prinzipien/allgemeine_ui_prinzipien_transkripte.rtf).
- **B1–B15:** Nummern im [zweiten Transkript](/Users/ardasayar/Documents/aislop/ui_prinzipien2/ui_und_tipps.rtf).
- **R1–R13:** Ergänzende Reddit-Dateien; vollständiges Verzeichnis am Ende.
- **Ableitung:** Meine Zusammenführung oder konkrete Anwendung der Quellen, keine wörtliche Vorgabe eines Videos.

Die Transkripte enthalten keine durchgängig verlässlichen Videotitel, Zeitmarken oder Original-URLs. Deshalb sind die unten vergebenen Themenbezeichnungen beschreibend. Ausgewertet wurde der vollständige Text; im Video gezeigte, aber nicht ausgesprochene Maße lassen sich daraus nicht rekonstruieren. Verlinkte externe Screenshots wurden nicht als eigenständige Bildquellen untersucht.

Die genannten Wachstumszahlen, Studien und Kausalbehauptungen wurden nicht unabhängig geprüft. Zahlreiche Videos enthalten Sponsoring oder Werbung für die eigene Agentur. Aussagen wie „diese Animation erzeugt mehr Umsatz“ oder „diese Mechanik erklärt den Erfolg einer App“ sind deshalb Argumente der jeweiligen Autoren, keine hier nachgewiesenen Wirkungen. Auch Reddit ist eine Sammlung teils widersprüchlicher Erfahrungen.

## 1. Vor dem Aussehen muss die Aufgabe klar sein

A9 und B11 beginnen mit der Absicht des Nutzers. Bei einer Unterkunftssuche braucht er zunächst Ort, Datum und Reisende. Eine zusätzliche Überschrift oder ein dekoratives Hintergrundbild verbessert diese Aufgabe nicht automatisch. B5 geht weiter: Das Produkt braucht eine konkrete Haltung, die seine Entscheidungen zusammenhält. Im Beispiel eines Weckers prägt „sanft aufwachen“ Farben, Sprache und Übergänge; die eigentliche Funktion muss außerdem das reale Aufstehen unterstützen.

Für Mobile bedeutet das: Nicht zuerst ein Dashboard mit allen verfügbaren Daten entwerfen. Zuerst festlegen, was jemand in diesem Moment erledigen möchte, welche Informationen dafür erforderlich sind und welcher nächste Schritt naheliegt. A1 formuliert dafür „ein Screen, eine Aufgabe“, mit der Startseite als ausdrücklicher Ausnahme. Gemeint ist ein dominanter Zweck, nicht buchstäblich nur ein einziges Bedienelement.

B2 und B7 ergänzen einen wichtigen Punkt: Gewohnte Produktkonzepte dürfen hinterfragt werden. Eine Sprachapp kann bewusst das tatsächliche Sprechen statt eines kurzen Punktespiels in den Mittelpunkt stellen. Eine neue Eingabemöglichkeit kann den Hauptablauf verändern, statt nur als zusätzlicher Button an einen alten Ablauf angehängt zu werden.

**Ableitung für deine Sprachapp:** Eine geeignete Leitidee wäre beispielsweise „schnell in verständliche Sprache eintauchen und bei Bedarf Hilfe bekommen“. Dann müssten Text, Audio und verständliche Hilfen das Zentrum bilden. Statistiken, Belohnungen und Auswahlmenüs müssten ihren Platz aus dieser Aufgabe begründen. Das ist eine mögliche Anwendung, keine erneute Bewertung des aktuellen App-Codes.

## 2. Mobile braucht eine eigene Informationsarchitektur

### Weniger gleichzeitig zeigen, ausreichend groß bleiben

A1 warnt ausdrücklich davor, eine Desktop-Oberfläche einfach zu verkleinern. Trotz kleinerem Display bleiben Schrift und Abstände ähnlich groß oder werden sogar größer. Das Transkript nennt als Vergleich 17 für die iOS-Basisschrift und 13 für macOS; daraus folgt keine Pflichtschriftgröße für jede App.

Pro Inhaltsabschnitt sollte eine klare Leserichtung erkennbar sein: etwa eine vertikale Liste oder eine horizontal durchblätterbare Reihe. A1 formuliert das sehr streng als eine Richtung pro Abschnitt. **Meine Einordnung:** Das ist eine Vereinfachung zur Vermeidung überladener Desktop-Dashboards; kein generelles Verbot zweispaltiger mobiler Kataloge.

### Zusatzfunktionen im richtigen Kontext öffnen

Bottom Sheets sind laut A1 besonders geeignet, wenn eine untergeordnete Auswahl zur aktuellen Aufgabe gehört: etwa eine Vorlage auswählen, ohne den Editor gedanklich zu verlassen. Eine eigenständige Aufgabe kann eine eigene Seite bekommen. Kontextbezogene Aktionen dürfen wechseln: Im Editor werden andere Werkzeuge benötigt als in der Übersicht.

A9 nennt das Prinzip der schrittweisen Offenlegung: Zuerst das Nötige zeigen, weitere Details bei Bedarf. Die Oberfläche soll weder alles gleichzeitig präsentieren noch wichtige Funktionen unauffindbar verstecken.

### Karten nur verwenden, wenn sie etwas gruppieren

A1 beschreibt Karten als nützliche mobile Bausteine, warnt aber vor mehrfach verschachtelten Karten. Außenabstand, Karten-Padding und inneres Karten-Padding verbrauchen schnell einen großen Teil der Breite. A13 zeigt, dass eine Fläche manchmal durch eine dezente Kontur ersetzt werden kann. Oft genügen Abstand und Typografie.

**Ableitung:** Eine Karte braucht einen erkennbaren Grund: zusammengehörige Informationen, ein eigenständig auswählbares Objekt oder eine abgesetzte Ebene. Nicht jede Überschrift und jede Zahl benötigt ihren eigenen Container.

## 3. Spacing: Beziehungen sichtbar machen

Die stärkste gemeinsame Empfehlung ist ein kleines, wiederverwendbares Abstandssystem. A4 beschreibt ein 4er-Raster, B14 ein 8er-Raster mit 4er-Zwischenschritten. R10 und R13 unterstützen diesen Ansatz. Der Nutzen liegt in Konsistenz und leichteren Entscheidungen, nicht darin, dass eine durch acht teilbare Zahl von sich aus schöner wäre.

Die räumliche Beziehung ist wichtiger als der einzelne Wert:

- **Innerhalb einer Gruppe enger:** Titel und zugehörige Erklärung; Icon und Label; Eingabefeld und Fehlermeldung.
- **Zwischen Gruppen weiter:** Zwei Aufgabenbereiche oder zwei inhaltlich getrennte Abschnitte.
- **Gemeinsame Kanten:** Überschriften, Listen und Aktionen folgen nachvollziehbaren Ausrichtungen.
- **Wiederkehrende Komponenten gleich behandeln:** Identische Karten bekommen dieselben Innenabstände.

A8 kritisiert zu enge Layouts; A12 kritisiert zu große Abstände zwischen zusammengehörigen Abschnitten. Das ist kein Widerspruch: Gute Abstände zeigen Zusammenhang. „Mehr Whitespace“ ist allein noch keine Lösung.

### Ein brauchbares Startsystem – meine Ableitung

Die folgende Zuordnung ist ein Vorschlag auf Basis der Quellen, keine dort fertig vorgegebene Spezifikation. Werte sind als logische Layout-Einheiten zu verstehen.

| Rolle | Startwert | Beispiel |
|---|---:|---|
| Sehr enger Zusammenhang | 4 | Icon und kurzer Statushinweis |
| Enger Zusammenhang | 8 | Titel und Metadaten |
| Kompakte Komponente | 12 | Innenabstand eines kleinen Blocks |
| Normaler Innenabstand | 16 | Liste, Karte, kleiner Bildschirmrand |
| Größere Trennung | 24 | Abstand zwischen Inhaltsgruppen; großzügiger Bildschirmrand |
| Deutlicher Abschnittswechsel | 32 | Abstand zwischen größeren Bereichen |

Nicht auf jedem Screen alle Werte verwenden. Den Bildschirmrand beispielsweise auf 16 oder 24 festlegen und innerhalb desselben Layouttyps konsistent halten. Ein kleines Icon darf einen kleinen sichtbaren Umriss haben, braucht aber weiterhin eine ausreichend große Trefferfläche.

**Nicht die gesamte Oberfläche proportional zur Displaybreite skalieren.** Als Ableitung aus A1, A11 und R2: Inhalte und Spalten passen sich an den verfügbaren Platz an; Text bleibt lesbar und Interaktionsflächen bleiben benutzbar. Ein für 440 breite Screens entworfenes Layout darf auf einem schmaleren Gerät nicht einfach samt Schrift und Buttons schrumpfen.

A4 erlaubt ausdrücklich Abweichungen vom Raster. Auch R13 nennt feinere Werte wie 1, 2 oder 6. Eine Kontur oder optische Korrektur muss deshalb nicht acht Einheiten breit sein. Entscheidend ist eine begründete Ausnahme statt ständig neuer Zufallswerte.

## 4. Typografie schafft die wichtigste Hierarchie

A4, A12 und B14 empfehlen wenige, klar unterscheidbare Textrollen. Eine Schriftfamilie reicht häufig. Hierarchie entsteht zusätzlich durch Gewicht, Größe, Position und Kontrast. Zwei Schriften können sinnvoll sein, wenn sie verschiedene Aufgaben erfüllen; sie sind keine Voraussetzung für einen hochwertigen Eindruck.

Wichtig ist die Unterscheidung zwischen **Größe**, **Gewicht** und **vollständigem Textstil**. Ein Stil enthält auch Zeilenhöhe, Laufweite und gegebenenfalls Farbe. R2 kritisiert ständig neue, fast identische Varianten, die Entwicklung und Konsistenz erschweren.

Die Größenbegrenzungen unterscheiden sich: Ein Reddit-Kommentar fordert höchstens drei Größen pro Screen, B14 zeigt vier Größen und zwei Gewichte, A4 nennt höchstens sechs Größen für Websites und Landingpages. **Die sinnvolle gemeinsame Regel lautet: wenige benannte Rollen mit klaren Aufgaben.** Keine dieser Zahlen ist eine universelle Obergrenze.

Für große Überschriften nennt A4 eine engere Laufweite von ungefähr −2 bis −3 Prozent und eine Zeilenhöhe von 110–120 Prozent. R13 nennt ungefähr 130 Prozent für Absatztext. Diese Werte hängen von Schrift und Inhalt ab. Sie sind keine pauschale Einstellung für kleine Labels oder längere Lesetexte. Gerade eine Sprachapp sollte ihre Lesetypografie am tatsächlichen Lernmaterial prüfen.

A12 empfiehlt etwas mehr Laufweite für kleine Großbuchstaben-Labels und vermeidet einen unnötig laut wirkenden CTA in Versalien. B14 zeigt eine besondere Behandlung großer Zahlen und kleinerer Nachkommastellen. Auch das ist ein kontextabhängiges Beispiel, kein allgemeiner Auftrag zur Monospace-Schrift.

## 5. Farbe soll Bedeutung und Gewicht vermitteln

A4, A13–A16 und B14 laufen auf drei Rollen hinaus: ruhige Grundflächen, eine erkennbare Marken- beziehungsweise Aktionsfarbe und semantische Farben für Zustände. Hintergrund, Metadaten und Navigation sollten nicht genauso laut sein wie die wichtigste Aktion.

### Was 60–30–10 tatsächlich bedeutet

Die Videos verwenden 60–30–10 als Verteilungsidee: ein dominanter Grundton, eine ergänzende Flächenfarbe und sparsame Akzente. A15 nennt ausdrücklich Ausnahmen, dunkle Oberflächen und auch stark farbige Grundflächen. Die Bezeichnungen für „primär“ und „sekundär“ wechseln zwischen den Autoren.

**Ableitung:** Nicht Bildschirm-Pixel zählen, sondern Aufmerksamkeit verteilen. Die wichtigste Aktion soll erkennbar bleiben. Fotos, Diagramme und notwendige Statusfarben machen eine Palette nicht automatisch falsch. Ebenso muss eine App nicht auf exakt drei Hex-Werte reduziert werden: Zustände und Themes brauchen Abstufungen.

### Hell und dunkel getrennt gestalten

A13 warnt vor bloßer Farbinvertierung. A14 verwendet die Umkehr der Helligkeit lediglich als Ausgangspunkt und korrigiert anschließend die Flächenhierarchie. In dunklen Oberflächen können etwas hellere Flächen eine höhere Ebene anzeigen; in hellen Oberflächen unterstützen dezente Schatten die Trennung.

Sekundärer Text darf zurücktreten, muss aber lesbar bleiben. Dass ein Element inaktiv ausgewählt ist, bedeutet nicht, dass es deaktiviert wäre: Ein ungewählter Navigationstab bleibt ein benutzbares Ziel.

A14 erklärt HSL und OKLCH als Hilfen beim Erstellen von Abstufungen. Die gesprochenen Chroma-Zahlen sind im Transkript uneindeutig und werden hier deshalb nicht als technische Grenzwerte übernommen. Entscheidend ist die Prüfung der tatsächlichen Kombination aus Vorder- und Hintergrund. Die pauschalen Farbassoziationen in A16 – etwa Blau als vertrauenswürdig – ersetzen diese Prüfung nicht.

## 6. Navigation muss verständlich und erreichbar sein

A11 behandelt die untere Navigation ausführlich. Sie soll die wichtigsten, häufig genutzten Bereiche enthalten, nicht beliebige Funktionen. Logout, Rechtstexte und seltene Hilfeziele gehören normalerweise nicht auf diese knappe Fläche.

A1 bevorzugt drei bis vier Ziele und nennt fünf als Grenze. A11 empfiehlt drei bis fünf, erwähnt aber auch maximal sechs. Für einen mobilen Ausgangsentwurf ist **drei bis fünf** der gemeinsame, vorsichtige Bereich. Mehr Ziele erfordern eine bewusst andere Struktur.

Icons sollten vertraut sein und dieselbe visuelle Sprache verwenden. A11 empfiehlt kurze Labels sowie einen gut erkennbaren aktiven Zustand, zum Beispiel gefülltes Icon plus veränderte Schriftstärke. Die dort verlangten „mindestens zwei Änderungen“ sind eine Gestaltungsheuristik. Das Ziel ist eine eindeutige Positionsanzeige.

A8 lässt bekannte Icons ohne Beschriftung zu; A11 macht dies von der Zielgruppe abhängig. **Meine Ableitung:** Für Kernnavigation zunächst Icon und Text vorsehen. Gerade bei app-spezifischen Bedeutungen ist ein Symbol allein oft weniger eindeutig, als es dem Ersteller erscheint.

Die Navigation muss vom Inhalt unterscheidbar bleiben, etwa durch eine andere Fläche, eine feine Linie oder einen zurückhaltenden Schatten. Nicht jede dieser Methoden ist gleichzeitig nötig. Badges sollen relevante neue Informationen anzeigen; ständige rote Punkte verlieren ihren Informationswert.

A1 und A11 erlauben eine hervorgehobene Erstellen-Aktion im unteren Bereich. **Meine Ergänzung:** Ein Zielwechsel und eine Aktion sollten trotzdem erkennbar verschieden bleiben. „Bibliothek“ führt in einen Bereich; „Aufnehmen“ startet einen Vorgang.

## 7. Eingaben, Suche und Inhalt auf echte Nutzung auslegen

A10 unterscheidet einmalige Einrichtung von häufiger, präziser Eingabe. Ein begrenzter Auswahlbereich kann einen Picker rechtfertigen. Wer dagegen oft exakte Zahlen eintippt, soll nicht jedes Mal lange durch ein Rad scrollen müssen. Entscheidend sind Präzision und Wiederholung, nicht die optische Attraktivität des Controls.

Smart Defaults aus A7 reduzieren Arbeit, wenn sie tatsächlich passen und änderbar bleiben. Eine Suche kann letzte Suchanfragen und hilfreiche Vorschläge zeigen, statt nach dem Antippen zunächst nur eine leere Fläche zu liefern. Vorschläge dürfen eine konkrete Eingabe aber nicht verdrängen.

A9 und A12 verlangen realistische Inhalte: lange Titel, helle und dunkle Fotos, unterschiedliche Datenmengen. Ein Icon direkt auf einem Foto muss auch nach einem Bildwechsel sichtbar bleiben. Bilder sollten als zusammengehörige Serie funktionieren, nicht nur einzeln gut aussehen.

R2 ergänzt besonders relevante mobile Fälle: andere Gerätegrößen, größere Systemschrift, deutsche und japanische Texte, ungewöhnliche Bildformate sowie Listen mit null, einem oder sehr vielen Einträgen. Dafür braucht es definierte Umbrüche und flexible Layouts. Ein perfekt passender Beispieltext beweist noch kein funktionierendes Design.

## 8. Gute Zustände machen Qualität im Alltag spürbar

B1 ist dafür die wichtigste Ergänzung aus dem zweiten Ordner. Der Autor beschreibt hochwertige UX als vollständige Betreuung des Ablaufs: Was ist gerade passiert? Kann ich es zurücknehmen? Was kann ich jetzt tun? Ein Screen kann hervorragend aussehen und trotzdem genau diese Antworten schuldig bleiben.

A4 und A8 fordern direktes Feedback auf Interaktionen. Auf Touchgeräten ist insbesondere der gedrückte Zustand relevant; ein Hover-Zustand ersetzt ihn nicht. Lade-, Erfolgs- und Fehlerzustände müssen zum jeweiligen Vorgang passen.

| Situation | Was die Oberfläche vermitteln sollte | Quellen |
|---|---|---|
| Erster Start ohne Inhalte | Warum ist die Ansicht leer, und wie beginne ich? | A1, A5 |
| Suche ohne Treffer | Was wurde nicht gefunden, und wie ändere ich die Suche? | A1 |
| Laufender Vorgang | Wurde die Aktion angenommen, und was passiert gerade? | A4, A8 |
| Erfolgreiche Aktion | Was wurde tatsächlich gespeichert, hinzugefügt oder abgeschlossen? | A4, A6 |
| Fehler | Was ist betroffen, und welcher nächste Schritt hilft? | B1 |
| Erreichtes Kontingent | Wie viel wurde genutzt, und wann wird es erneuert? | B1 |
| Rückkehr nach Pause | Wo kann ich wieder einsteigen? | A10, B15 |

Im Kontingent-Beispiel aus B1 ist „2 von 2 Sitzungen genutzt; erneuert sich am …“ hilfreicher als zwei unterschiedliche Screens mit derselben unspezifischen Sperrmeldung. Im Aufnahmebeispiel reicht „zu kurz“ nicht aus, wenn der Nutzer gerade die Funktion ausprobiert und anschließend ohne Ergebnis dasteht.

B1 empfiehlt, gezielt schlechte Bedingungen auszuprobieren: Verbindung mitten im Ablauf unterbrechen, Listen leeren, Fehler provozieren. **Meine Ableitung:** Auch erhaltene Eingaben, Wiederholen ohne Doppelaktion und ein verständlicher Rückweg gehören in die Prüfung.

R8 empfiehlt Skeletons für das Laden von Inhalten, unterscheidet diese aber vom Absenden eines Formulars. Daraus folgt kein allgemeines Spinner-Verbot. Der Ladezustand soll zur Aufgabe passen und keinen falschen Fortschritt darstellen.

## 9. Motion, Haptik und Persönlichkeit gezielt einsetzen

A2 erklärt gute Bewegung über Beschleunigung, Abbremsen, Richtung und Kontinuität. Eine Karte kann nachvollziehbar in ihre Detailansicht übergehen. Ein Sheet kommt von unten und verschwindet wieder dorthin. Die Bewegung soll zeigen, wie Ansichten zusammenhängen.

Gesten brauchen Erkennbarkeit und erreichbare Alternativen. A2 nennt ausdrücklich Swipe plus Button oder Menü. A8 entfernt dagegen manche Pfeile als redundant. **Ableitung:** Erst prüfen, ob eine Bedienmöglichkeit wirklich überflüssig ist. Eine unsichtbare Geste ist kein Ersatz für einen verständlichen Zugang.

A5 setzt sehr viel Animation und Haptik ein, bis hin zu fast jedem Button. A9 fordert dagegen, Bewegung müsse Klarheit oder Funktion hinzufügen. Das sind unterschiedliche Gestaltungspositionen. Für eine häufig genutzte Mobile App ist ein zurückhaltender gemeinsamer Nenner sinnvoll: sofortige Rückmeldung, nachvollziehbare Übergänge und einzelne besondere Momente.

A3 und A6 zeigen, wie kleine Erfolge, ein freundlicher Ton und ein bewusst gestalteter Abschluss Persönlichkeit vermitteln. Ein Maskottchen ist nur eine Möglichkeit. Auch präzise Sprache, gute Icons und ein ruhiger Abschluss können Charakter schaffen. Nicht jede Aktion braucht Konfetti.

**Meine technische Ergänzung:** Bewegungsreduktion und Nutzerpräferenzen berücksichtigen; Information nicht ausschließlich über Vibration oder Animation transportieren. A5 spricht selbst mögliche Accessibility-Probleme an, behandelt sie jedoch nicht systematisch. Feste Animationswartezeiten sollten keine häufigen Aktionen ausbremsen.

## 10. Onboarding: den Nutzen erleben lassen

B13 empfiehlt einen frühen, echten Nutzenmoment. Die Beispiele reichen von einer unmittelbar begonnenen Atemübung bis zu einem geführten Sudoku. A7 argumentiert ebenfalls dafür, zunächst etwas Brauchbares zu liefern, bevor Registrierung oder Bezahlung gefordert werden.

Das bedeutet nicht, dass jede App dasselbe kurze Tutorial braucht. B13 unterscheidet erklärende Schritte, aktives Ausprobieren und persönliche Einstellungen. Gute Fragen wirken sich auf die anschließende Erfahrung aus – etwa Stimme und Lesegeschwindigkeit. Fortschrittsanzeigen machen einen begrenzten Ablauf verständlich.

B6 lobt dagegen lange Fragebögen und scheinbar individuelle Ergebnisse als Bindungsmechanik. B13 empfiehlt bei langen Abläufen teilweise, die Schrittanzahl nicht anzuzeigen. **Meine Bewertung:** Für gute UX sollte die Länge aus notwendiger Einrichtung entstehen. Ein künstlich langer Fragebogen oder verborgenes Ende ist kein Qualitätsmerkmal. Bereits erledigte Schritte dürfen zählen; erfundener Fortschritt sollte nicht als echter Fortschritt erscheinen.

## 11. Wiederkehr: wirklicher Fortschritt statt Beschäftigung

B8–B10 betrachten soziale Vergleiche, lokale Wettbewerbe, variable Belohnungen und Streaks. B4 beschreibt zeitgesteuerte Ereignisse, die auch bei geschlossener App weiterlaufen. Diese Videos erklären Mechaniken der Bindung; sie sind keine neutrale Liste von UX-Best-Practices.

B9 liefert dabei die nützlichste Unterscheidung: Fortschritt sollte zeigen, dass jemand in der eigentlichen Sache besser wird, statt lediglich häufig die App zu öffnen. Eine Rangliste ohne sinnvolle Aktivität dahinter bleibt eine Liste. Zu viele Spielsysteme können die eigentliche Tätigkeit überlagern.

B15 ergänzt zwei Ansätze: die Nutzung an eine vorhandene Alltagsroutine knüpfen und den Wiedereinstieg nach einer Unterbrechung gestalten. Die Beispiele reichen von Pausenmodi bis zu verschiebbaren Zielen. B7 zeigt außerdem eine Produktpositionierung ohne Schuldgefühle als Gegenentwurf zum üblichen Leistungsdruck.

**Ableitung für eine Sprachapp:** Verständnis, bewältigte Inhalte und nutzbare sprachliche Fähigkeiten sind aussagekräftiger als bloße Tippzahlen. Nach einer Pause sollte der Einstieg leicht bleiben. Ein hilfreicher Vorschlag für den nächsten Tag genügt; der erfolgreiche Abschluss einer Lerneinheit darf tatsächlich ein Ende sein.

### Welche Empfehlungen ich nicht als gute UX übernehmen würde

| Aussage beziehungsweise Beispiel aus den Videos | Einordnung für diesen Bericht |
|---|---|
| Dateiverlust mit Countdown und beschämendem Ablehnen-Text als Upgrade-Anreiz, A7 | Druckaufbau; kein allgemeines UX-Vorbild |
| Generische Ergebnisse nach langem Quiz wie persönlich ermittelt erscheinen lassen, B6 | Scheingenauigkeit und vorgetäuschte Personalisierung |
| Nie einen abschließbaren Zustand anbieten, B10 | Ziel der Dauerbindung; widerspricht selbstbestimmtem Abschluss |
| Verfall und soziale Sichtbarkeit gezielt nutzen, um Wegbleiben schmerzhaft zu machen, B4/B10 | Kann Wiederkehr erzeugen, aber auch Belastung |
| Weniger beziehungsweise versteckte Tarifoptionen steigern den Umsatz, B3 | Ein Conversion-Ergebnis beweist keine bessere Entscheidung für Nutzer |

Die konstruktive Alternative aus denselben Quellen lautet: verständliche Auswahl, echte Personalisierung, transparenter Fortschritt, Anerkennung und ein einfacher Wiedereinstieg. B3 selbst kritisiert das Zurückhalten eigener Nutzerergebnisse hinter einer unscharfen Paywall. Nicht einmal innerhalb des zweiten Ordners ergibt sich deshalb eine einheitliche Empfehlung für aggressive Bindung.

## 12. Konkrete Maße und technische Hinweise aus dem Material

Die Videos sagen oft „Pixel“, ohne Plattform und Pixeldichte sauber zu unterscheiden. Die Zahlen unten bleiben deshalb ausdrücklich Quellenangaben. **Für eine Umsetzung müssen sie in die logischen Maße des verwendeten UI-Systems übersetzt werden; nicht als physische Displaypixel behandeln.** Diese Tabelle ist keine unabhängig geprüfte Plattform- oder Accessibility-Spezifikation.

| Thema | Tatsächlich genannter Wert / Rat | Quelle und sinnvolle Grenze |
|---|---|---|
| Abstandsraster | Vielfache von 4 oder 8; etwa 12 statt 11, 24 statt 25 | A4, B14; Konsistenzhilfe, keine Pflicht für jeden Messwert |
| Absatzausrichtung | Gemeinsamer Rand, Beispiel 24 | A12; Beispiel für einen Screen |
| Listen-Padding | Horizontal 16 dp, vertikal 8 dp | R7; konkreter Kommentar, keine allgemeine Norm |
| Zeilenhöhenraster | Auf 4er- oder 8er-Schritte abstimmen | R10; Lesbarkeit der Schrift hat Vorrang |
| Button-Padding | Horizontal ungefähr doppelt so viel wie vertikal | A4; bezieht sich auf Padding, nicht auf das Seitenverhältnis des Buttons |
| Touchfläche | Mindestens 44 × 44 im Sprachgebrauch der Videos | A1, A11; Icongröße und Trefferfläche getrennt behandeln |
| Navigations-Icon | Ungefähr 24 | A11; optisch mit Text und Iconfamilie abstimmen |
| Icons neben Text | An dessen Zeilenhöhe orientieren; Beispiel 24 | A4; kein Zwang für Illustrationen |
| Navigationslabels | Ungefähr 10–12 | A11; nicht unkritisch bei großer Systemschrift festschreiben |
| Unterer Systembereich | Ungefähr 34 im iPhone-Beispiel | A11; tatsächliche Safe Area verwenden, keine pauschale Konstante |
| Anzahl Hauptziele | Meist 3–5 | A1/A11; Quellen nennen unterschiedliche Höchstwerte |
| Geräteprüfung | Zwei bis drei mobile Breiten | A11; R2 ergänzt Schriftgröße, Sprache und weitere Gerätevarianten |
| Große Überschriften | Laufweite ungefähr −2 bis −3 %, Zeilenhöhe 110–120 % | A4; schriftabhängig, nicht pauschal auf Bodytext anwenden |
| Absatz-Zeilenhöhe | Ungefähr 130 % | R13; Reddit-Richtwert, kein universeller Lesetextstandard |
| Anzahl Schriftgrößen | 4 Größen und 2 Gewichte im gezeigten Beispiel | B14; andere Quellen nennen andere Grenzen |
| Dashboard-Schrift | Im Regelfall nicht größer als 24 | A4; ausdrücklich dichter Dashboard-Kontext |
| Komponentenradius | 10 für kleinere Komponenten im Redesign | A8; konsistente Wahl im Beispiel, kein universeller App-Radius |
| Kontrast | 3:1 für grafische UI-Elemente im Video genannt | A11; keine pauschale Freigabe für kleinen Text |
| Bewegungsdauer | 200 ms als Kommentarvorschlag; pauschale 300 ms werden anderswo hinterfragt | R6/R8; Videos geben keine einheitliche Dauer vor |
| Flächen und Schatten | Zurückhaltende Schatten; höhere dunkle Flächen etwas heller | A4, A13, A14; keine einheitlichen numerischen Schatten-Tokens |
| Assets | Einheitliche Iconfamilie, SVG im Designexport | A8; konkrete Einbindung hängt von der App-Technik ab |

## 13. Was davon in ein kleines Designsystem gehört

A8 und A9 verlangen wiederverwendbare Styles, Variablen und Komponenten. R2 ergänzt die möglichst direkte Entsprechung zwischen Designkomponente und Implementierung. Die gemeinsame Sprache ist wichtiger als ein bestimmtes Benennungsschema.

**Meine daraus abgeleitete technische Struktur:**

- **Spacing-Tokens:** wenige Werte und dokumentierte Rollen, etwa kompakter Abstand, Karten-Padding und Abschnittsabstand.
- **Textrollen:** Titel, Fließtext, Label, Metadaten; jeweils mit Größe, Gewicht, Zeilenhöhe und Laufweite.
- **Semantische Farben:** Hintergrund, Oberfläche, Haupttext, Nebentext, primäre Aktion, Fehler, Erfolg und Kontur – mit passenden hellen und dunklen Werten.
- **Komponentenvarianten:** gleiche Buttons, Suchfelder, Listeneinträge und Sheets inklusive ihrer Zustände.
- **Interaktionsregeln:** Öffnen, Schließen, Zurück, Laden, Erfolg, Fehler und Wiederholen.
- **Inhaltsregeln:** lange Titel, leere Listen, große Schrift, Bilder und Zahlenformate.

Für Flutter ist das eine fachliche Struktur für Theme, gemeinsame Widgets und Layoutwerte, keine Aufforderung zum Austausch des Frameworks. Die Reddit-Nennung von `flutter_animate`, Skeletonizer, Lottie oder Rive ist eine Werkzeugempfehlung einzelner Autoren. Keines dieser Pakete macht die UX automatisch gut, und ihre aktuelle technische Eignung wurde hier nicht geprüft.

R1 und R6 betonen Plattformkonventionen; R2 lässt gleichzeitig bewusst individuelle Komponenten zu. **Ableitung:** Eine eigene Markenoberfläche kann mit erwartbaren Navigations- und Systemabläufen zusammengehen. Nicht jedes Android-Detail sollte eine iOS-Kopie sein, und ein individuelles Iconset rechtfertigt keinen überraschenden Zurück-Ablauf.

## 14. Ein sinnvoller Arbeitsablauf für die Umsetzung

Aus A8, A9, B1, B5, B11, B14 und R2 ergibt sich folgende Reihenfolge:

1. **Produktabsicht festhalten:** Für wen ist die App, welches konkrete Ergebnis soll sie erleichtern, und wie soll sie sich anfühlen?
2. **Kernablauf skizzieren:** Einstieg, Aktion, Ergebnis, Rückweg; zusätzlich Abbruch, Fehler und leere Zustände.
3. **Echte Inhalte einsetzen:** Bereits im groben Layout lange Titel, typische Texte und realistische Datenmengen verwenden.
4. **Visuelle Hierarchie lösen:** Zuerst Reihenfolge, Gruppen und dominante Aktion; danach Farben und Effekte.
5. **Ein kleines System festlegen:** Abstände, Typografie, Farben und wiederverwendbare Komponenten.
6. **Interaktion durchgestalten:** Feedback, Übergänge und gezielte besondere Momente, ohne den Ablauf zu verlangsamen.
7. **Auf dem Gerät prüfen:** Kleine Breite, große Schrift, Tastatur, Safe Areas, Touchflächen und ungünstige Zustände.
8. **Den gesamten Ablauf beobachten:** Können Nutzer beginnen, abschließen, Fehler verstehen und nach einer Pause wieder einsteigen?

B5 warnt davor, immer mehr Referenzen und Regeln ohne gemeinsame Richtung zusammenzukippen. R12 empfiehlt entsprechend, zuerst das Layout zu lösen, statt früh einzelne Buttons endlos zu polieren. B1 fordert die Prüfung über viele Screens hinweg: Eine App wird als zusammenhängendes Produkt erlebt.

**Abnahmekriterium als eigene Zusammenführung:** Ein Nutzer erkennt die Hauptaufgabe, kann sie mit realen Inhalten erledigen, versteht die Rückmeldungen und findet nach Fehlern oder Unterbrechungen weiter. Erst darauf baut die besondere visuelle und emotionale Ausarbeitung auf.

## Quellenverzeichnis

### Video-Transkripte

Die Nummern entsprechen der Reihenfolge in den beiden RTF-Dateien; die Themenbezeichnungen sind von mir vergeben.

| Quelle | Thema |
|---|---|
| A1 | Mobile Grundlagen: Layout, Karten, Sheets, Gesten, leere Zustände |
| A2 | Swipe-Interaktionen, Übergänge und räumliche Kontinuität |
| A3 | Emotionales Design anhand Duolingo, Phantom und Revolut |
| A4 | Grundlagen: Hierarchie, Typografie, Farbe, Feedback und Tiefe |
| A5 | Individuelle App-Ausarbeitung: Animation, Illustrationen, Haptik, Icons |
| A6 | Bewusste Höhepunkte, Abschlüsse und negative Nutzungsmomente |
| A7 | Defaults, Fortschritt, Gegenseitigkeit, Investition und Verlustangst |
| A8 | Anfängerfehler anhand einer Rezept-App |
| A9 | Nutzerabsicht, Content, Offenlegung und Designsysteme |
| A10 | Personalisierung, Suche, Statusdarstellung, Kategorien und Eingaben |
| A11 | Untere Navigation im Detail |
| A12 | Produktdetailseite: 15 Fehler und drei zusätzliche Verbesserungen |
| A13 | Farbrollen, Kontrast, Zustände sowie helles und dunkles Theme |
| A14 | Farbskalen mit HSL/OKLCH, Flächenhierarchie und Schatten |
| A15 | Die 60–30–10-Heuristik und ihre Ausnahmen |
| A16 | Farben im tatsächlichen Layout ausprobieren und als Styles verwenden |
| B1 | Hochwertige Produkterfahrung durch Zustände, Konsistenz und Fehlerhilfe |
| B2 | Verborgene Annahmen einer Produktkategorie hinterfragen |
| B3 | Struktur und Auswahl auf Paywalls |
| B4 | Zeitbasierte Bindungsmechaniken |
| B5 | Vier Gestaltungsstufen mit AI und die Rolle einer klaren Richtung |
| B6 | Scheinbare und echte Personalisierung, Identität und Teilen |
| B7 | Spezifische Zielgruppen, neue Eingaben und alternative Produktkonzepte |
| B8 | Soziale Vergleiche, lokale Gruppen und Anerkennung |
| B9 | Grenzen von Punkten und Badges; Kompetenz und sinnvolle Progression |
| B10 | Unvorhersehbare Belohnungen, endlose Progression und Statusbindung |
| B11 | Drei Ebenen: Kernablauf, visuelle Führung und emotionale Ausarbeitung |
| B12 | Wiederkehrende Reibung entfernen, Entdeckung personalisieren |
| B13 | Nutzenorientiertes, interaktives Onboarding |
| B14 | Copywriting, Raster, Typografie und Entwicklung vom Screen zum Ablauf |
| B15 | Alltagsroutinen und Wiedereinstieg nach verpassten Tagen |

### Ergänzende Reddit-Dateien

Alle folgenden Dateien wurden gelesen. Nicht jede enthält fachlich verwertbare Empfehlungen; R5 enthält etwa nur eine einzelne Framework-Antwort, R9 überwiegend Hilfsangebote. Solche Inhalte wurden nicht zu allgemeinen Regeln aufgewertet.

- **R1:** [Best way to Approach designing a consumer mobile app](/Users/ardasayar/Documents/aislop/ui_prinzipien/Best-way-to-Approach-designing-a-consumer-mobile-app.json)
- **R2:** [How best to prepare design layouts of mobile app for developers?](/Users/ardasayar/Documents/aislop/ui_prinzipien/How-best-to-prepare-design-layouts-of-mobile-app-for-developers.md)
- **R3:** [How can I improve my app’s UI Design?](/Users/ardasayar/Documents/aislop/ui_prinzipien/How-can-I-improve-my-apps-UI-Design.json)
- **R4:** [How do I make the UI feel more premium, still fun?](/Users/ardasayar/Documents/aislop/ui_prinzipien/How-do-I-make-the-UI-feel-more-premium-still-fun.json)
- **R5:** [How do you decide spacing and sizing in real mobile apps?](/Users/ardasayar/Documents/aislop/ui_prinzipien/How-do-you-decide-spacing-and-sizing-in-real-mobile-apps-React-Native-.json)
- **R6:** [How do you improve Android UI/UX quality?](/Users/ardasayar/Documents/aislop/ui_prinzipien/How-do-you-improve-Android-UIUX-quality-Why-does-iOS-still-feel-smooth.json)
- **R7:** [How do you make UI beautiful?](/Users/ardasayar/Documents/aislop/ui_prinzipien/How-do-you-make-UI-beautiful-Tips-tricks-hacks-and-your-process-and-ri.json)
- **R8:** [How to create an app with great UI/UX as a developer?](/Users/ardasayar/Documents/aislop/ui_prinzipien/How-to-create-a-app-with-great-UiUx-as-a-developer.md)
- **R9:** [Looking for Help to Improve the UI/UX of My Mobile App](/Users/ardasayar/Documents/aislop/ui_prinzipien/Looking-for-Help-to-Improve-the-UIUX-of-My-Mobile-App.json)
- **R10:** [Sizing & spacing essential need-to-knows](/Users/ardasayar/Documents/aislop/ui_prinzipien/Sizing-spacing-essential-need-to-knows.md)
- **R11:** [How to design UI of an app?](/Users/ardasayar/Documents/aislop/ui_prinzipien/How-to-design-UI-of-an-app.md)
- **R12:** [Struggling with UI Design: How Can I Improve My App Interfaces?](/Users/ardasayar/Documents/aislop/ui_prinzipien/Struggling-with-UI-Design-How-Can-I-Improve-My-App-Interfaces.json)
- **R13:** [Tips for getting better at visual/UI design](/Users/ardasayar/Documents/aislop/ui_prinzipien/Tips-for-getting-better-a-visualUI-design.json)
