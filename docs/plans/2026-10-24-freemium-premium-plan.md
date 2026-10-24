# Freemium und Premium: verbindlicher Produktplan

Stand: 24. Oktober 2026. Entscheidungsvorlage für die Umsetzung und das spätere Paywall-Design.

**Beschluss: Die App erhält eine dauerhaft nutzbare kostenlose Einstiegsversion und genau ein Premium-Abo. Premium kostet 9,99 € monatlich oder 49,99 € jährlich. Verkauft werden freie Inhaltswahl, die vollständige veröffentlichte Bibliothek und das Lernen mit eigenen Texten. Fehler, Wiederholungen und bereits erarbeiteter Lernfortschritt werden niemals zur Bezahlschranke.**

Dieser Plan beschreibt die festgelegte zukünftige Ausgestaltung. Er behauptet weder, dass Billing bereits implementiert ist, noch dass alle genannten Inhalte schon veröffentlicht sind. Bestehende Produktregeln werden erst zusammen mit der Umsetzung ausdrücklich aktualisiert; insbesondere bleibt das bisherige Tagesziel eine Empfehlung. Diese Aufgabe verändert keinen App-Code und keine bestehenden Nutzerdaten.

## 1. Warum dieses Modell zur App passt

Die App verbindet Lesen, Wörter im Satz und zeitlich geplante Wiederholungen. Ihr Nutzen wächst dadurch, dass jemand interessante Inhalte findet, Wörter versteht und sie später wiedererkennt. Eine Strafmechanik bei Fehlern würde genau diese Schleife unterbrechen. Fehler sind ein notwendiger Teil des Lernens und bereits Anlass für sinnvolle Wiederholung.

Deshalb gibt es keine Herzen, keine Energie, keine Wartezeit nach falschen Antworten, keine Werbung und keinen käuflichen Schutz einer Lernserie. Premium wird nicht als Reparatur eines absichtlich unangenehmen Lernprozesses verkauft.

Die kostenlose Version beantwortet die Frage: „Hilft mir diese Art zu lernen?“ Premium beantwortet: „Kann ich damit regelmäßig genau das lernen, was mich interessiert?“ Der Kaufgrund ist die Freiheit über Material, Umfang und persönliche Relevanz. Übersetzungskosten werden technisch begrenzt, sind aber nicht die Hauptbotschaft der Werbung.

Die gesamte Bibliothek täglich kostenlos freizugeben und nur KI abzuklemmen wäre ebenfalls ungeeignet: Viele Inhalte besitzen bereits lokale Übersetzungen und würden Premium kaum noch einen eigenständigen Wert geben. Umgekehrt würde ein vollständiger Verschluss des Bereichs „Inhalte“ die Qualität vor dem Kauf verbergen. Deshalb bleibt in jedem tatsächlich veröffentlichten Bereich eine klar bezeichnete Probe nutzbar.

## 2. Was die App tatsächlich schon macht

Die Entscheidung basiert auf Produktdokumentation, GitNexus-Abfragen und der Prüfung der relevanten Implementierungen. Der Graph wurde für die Orientierung verwendet; aktuelle Quelldateien bestimmen den tatsächlichen Implementierungsstand.

| Bereich | Feststellung | Konsequenz für das Abo |
| --- | --- | --- |
| Worttraining und SRS | Bewertung, Wiederholung und Lernplanung laufen lokal und deterministisch. | Kein KI-Kontingent für normale Übungen; Wiederholungen bleiben kostenlos. |
| Story-Übersetzungen | Vorhandene Wort- und Satzübersetzungen werden aus dem Inhalt gelesen. | Nicht jeder Tap und nicht jede gelesene Story verursacht Tokens. |
| Fehlende Übersetzungen | Ein ausdrücklicher Nutzerauftrag kann über authentifizierte Supabase Edge Functions Anthropic aufrufen. | Eigene, serverseitig durchgesetzte KI-Grenze erforderlich. |
| Textimport | Einfügen und Speichern laufen lokal; derzeit maximal 5.000 Wörter je Text. | Import kostet nicht automatisch Tokens. Premium-Sperre ist eine Wertentscheidung; spätere Übersetzungen sind die Kostenstelle. |
| Laufzeit-Übersetzung | Kein dauerhafter gemeinsamer Ergebniscache im geprüften Pfad; dieselbe Anfrage kann erneut Kosten auslösen. | Cache und Anfrage-Deduplizierung gehören vor den öffentlichen Abo-Start. |
| Heutige Schutzlimits | 5 Anfragen je Nutzer/UTC-Minute, 20 je Nutzer/UTC-Tag, 1.000 global/UTC-Tag. | Interne Schutzlimits sind noch kein vermarktbares Premium-Kontingent. |
| Authentifizierung | Interne Inhaltsfreigabe und öffentliche Onboarding-Oberfläche sind noch kein vollständiges Kauf-/Kontosystem. | Öffentliche Kontoverknüpfung, Wiederherstellen und Entitlements müssen gebaut werden. |
| Abonnements | In den geprüften App-/Supabase-Pfaden keine fertige Premium- und Kaufverwaltung gefunden. | Keine Paywall mit funktionslosen Kaufbuttons veröffentlichen. |
| Inhalte, Audio, Sprache | Manche Bereiche und Interaktionen sind noch Muster oder Platzhalter. | Nur tatsächlich veröffentlichte und funktionierende Leistungen verkaufen. |

Wichtige Codebelege:

- [Produktregeln](../../PRODUCT.md), [Designregeln](../../DESIGN.md), [SRS](../srs.md).
- [Reader und Import-Einstieg](../../lib/screens/app_shell.dart), [lokale Importverwaltung](../../lib/presentation/providers/reading_providers.dart).
- [Laufzeit-Client](../../lib/data/runtime_translation_client.dart), [Übersetzungsdialog](../../lib/widgets/runtime_translation_sheet.dart).
- [Serverseitige Übersetzung](../../supabase/functions/_shared/runtime_translation.ts), [bestehende Limits](../../supabase/migrations/20261019000001_runtime_translation_limits.sql).
- [Dokumentierter Übersetzungsstand](../haiku-runtime-translations.md), [Direkt-API-Setup](../haiku-direct-api-setup.md).
- [Vorschaukatalog für Screens](../../lib/screens/previews/screen_previews_screen.dart).

Die vorhandene Dokumentation beschreibt noch ausstehende Verifikation des vollständigen Übersetzungswegs auf dem Gerät. Ein lokaler API-Smoke-Test ersetzt das nicht. Die Untersuchung hat weder eine Live-Kostenmessung noch eine Prüfung des produktiven Store-Accounts vorgenommen.

## 3. Kostenlos und Premium: die festgelegte Grenze

### 3.1 Die Leistungsmatrix

| Leistung | Kostenlos | Premium |
| --- | --- | --- |
| Onboarding, persönliches Ziel, Lernserie und Abschlussanimationen | Vollständig | Vollständig |
| Fehlerwiederholung und SRS bereits aufgenommener Wörter | Unbegrenzt | Unbegrenzt |
| Neuer Lernstoff aus freigegebenen Materialien | Ohne zusätzliches tägliches Wortlimit | Ohne zusätzliches tägliches Wortlimit |
| Themenstapel | Ein fest ausgewählter vollständiger Starterstapel je veröffentlichter Sprache | Alle veröffentlichten Themenstapel |
| Storys | 12 gekennzeichnete Starterstorys; höchstens eine neue Starterstory pro Tag freischalten | Alle veröffentlichten Storys sofort; kein tägliches Story-Limit |
| Bereits freigeschaltete Starterstorys | Dauerhaft erneut lesbar | Dauerhaft erneut lesbar |
| Vorschau gesperrter Storys | Titel, Niveau, Thema und ein kurzer Anfang | Vollständiger Text |
| Wörter aus erlaubten Storys lernen | Ja, soweit dafür eine gültige Lernkarte vorliegt | Ja, soweit dafür eine gültige Lernkarte vorliegt |
| Vorhandene Übersetzungen in zugänglichen Inhalten | Unbegrenzt | Unbegrenzt |
| Neue KI-Übersetzungen | Einmalig 5 erfolgreiche Anfragen nach Kontoverifikation | 500 erfolgreiche neue Anfragen je Abo-Monat |
| Eigene Texte neu importieren | Gesperrt; verständliche Vorschau verfügbar | Enthalten; maximal 5.000 Wörter je Text |
| Früher importierte eigene Texte nach Abo-Ende | Lesen, vorhandene Übersetzungen, Export und Löschen bleiben möglich | Zusätzlich neue Texte und KI-Kontingent |
| Inhalte: Textübungen | 2 fest ausgewählte vollständige Übungen je veröffentlichter Sprache | Alle veröffentlichten Übungen |
| Inhalte: Grammatik | 3 Regelkarten und 2 vollständige Übungen je veröffentlichter Sprache | Alle veröffentlichten Regeln und Übungen |
| Inhalte: Hören | 2 vollständige Proben, sobald der Bereich tatsächlich veröffentlicht wird | Alle veröffentlichten Höreinheiten |
| Statistiken und persönlicher Lernfortschritt | Vorhandene Basisfunktionen vollständig | Dieselben Basisfunktionen; kein künstlicher Statistikverschluss |
| Offline-Lernen | Freigegebene, lokal vorhandene Inhalte und Wiederholungen | Zusätzlich lokal vorhandene Premium-Inhalte während der Berechtigung |
| Werbung | Keine | Keine |

„Alle“ bedeutet alle tatsächlich veröffentlichten Inhalte in den unterstützten Sprachen. Es bedeutet weder unbegrenzte neue KI-Anfragen noch Zugang zu unfertigen Funktionen. Monats- und Jahresabo haben exakt denselben Funktionsumfang.

### 3.2 Die kostenlose Story-Regel im Detail

Die kostenlose Auswahl ist eine feste Starterkollektion mit 12 Storys je veröffentlichter Sprache. Sie deckt die angebotenen Einstiegsniveaus ab. Der Nutzer wählt daraus pro Tag eine bisher nicht freigeschaltete Story. Die tägliche Freischaltung gilt kontoweit über die Sprachen hinweg. Öffnen einer Vorschau verbraucht nichts; erst „Heute kostenlos lesen“ erteilt die dauerhafte Freigabe und verbraucht den Tagesplatz.

Bereits freigeschaltete Starterstorys können jederzeit erneut gelesen werden. Nach zwölf Freischaltungen bleibt diese Sammlung nutzbar. Es gibt dann keinen Anspruch auf täglich eine weitere kostenlose Story aus der Premium-Bibliothek. Das muss bereits bei der ersten Freischaltung und in der Vergleichsansicht klar sein: **„12 Starterstorys – täglich eine neue freischalten, danach dauerhaft wiederlesen.“** Nicht versprechen: „Jeden Tag eine kostenlose Story“, wenn das Angebot nach zwölf endet.

Der tägliche Wechsel folgt einer serverseitig gespeicherten Kontozone, anfangs Europe/Berlin für den deutschen Startmarkt. Ein Gerätezeitwechsel erzeugt keine zweite Freigabe. Die Oberfläche zeigt den nächsten Zeitpunkt lokal verständlich an. Eine neue Freischaltung braucht eine Verbindung; bereits freigegebene und heruntergeladene Storys funktionieren offline. Ohne Konto darf die App die Starterfunktion lokal anbieten; nach Kontoverknüpfung werden Freigaben zusammengeführt, nie aber KI-Guthaben mehrfach vergeben. Ein Restrisiko durch Neuinstallation beim kostenlosen Offline-Angebot wird akzeptiert und nicht durch invasive Geräteverfolgung bekämpft.

Eine gestartete, berechtigt geöffnete Lesesitzung wird weder um Mitternacht noch beim Abo-Ende mitten im Satz geschlossen. Nach Ende der Sitzung greifen die normalen Zugangsregeln wieder. Persönliche Notizen und aufgenommene Lernkarten bleiben erhalten.

### 3.3 Keine zusätzliche Wortbremse

Es gibt keine Grenze „nur fünf neue Wörter am Tag“. Das bestehende Tagesziel bleibt eine Empfehlung. Wer im kostenlosen Startermaterial weiterlernen möchte, darf das. Premium erweitert das verfügbare Material.

Die Berechtigung wird beim Hinzufügen neuen Lernstoffs geprüft, nicht beim Wiederholen. Eine rechtmäßig aus einer Starterstory aufgenommene Karte darf auch dann gelernt werden, wenn dieselbe Karte außerdem einem Premium-Themenstapel zugeordnet ist. Die gemeinsame Kartenidentität bleibt erhalten; es entstehen keine separaten Gratis-/Premium-Kopien.

Nach Kündigung bleiben alle bereits aufgenommenen Karten mit ihrem SRS-Zustand lernbar. Neue Karten aus gesperrten Materialien können nicht zusätzlich aufgenommen werden. Bestehende Nutzer erhalten bei der Einführung Bestandsschutz für bereits freigeschaltetes Material; bisher kostenlos zugesagter Zugang wird nicht stillschweigend entzogen.

## 4. Preise und konkrete Kaufargumente

### 4.1 Reguläre Preise im deutschen Store

| Tarif | Abrechnung | Darstellung |
| --- | --- | --- |
| Premium monatlich | 9,99 € jeden Monat | „9,99 € / Monat“ |
| Premium jährlich | 49,99 € einmal pro Jahr | „49,99 € / Jahr“, darunter „entspricht 4,17 € / Monat“ |
| Berechtigtes Willkommensangebot | 39,99 € für das erste Jahr | „39,99 € im ersten Jahr, danach 49,99 € / Jahr“ |

Das Jahresabo ist auf der Paywall vorausgewählt. Der monatliche Tarif bleibt direkt daneben auswählbar. Der tatsächliche Jahresbetrag ist größer und prominenter als sein rechnerischer Monatswert. Beide verlängern sich automatisch bis zur Kündigung. Der Store liefert den tatsächlichen lokalisierten Preis; keine hart codierten Europreise in internationalen Kaufdialogen.

49,99 € sind rund 58 % günstiger als zwölf Monatszahlungen von zusammen 119,88 €. Das darf so benannt werden: **„58 % gegenüber monatlicher Zahlung sparen.“** Es ist kein erfundener ehemaliger Preis. Der Jahrespreis ist eine bewusst günstige Einstiegspreispositionierung; er benötigt ausreichende Bindung und einen kontrollierten Kostenblock. Einen wirtschaftlich nachgewiesenen Optimalpreis behauptet dieser Plan nicht.

Es gibt zum Start kein Wochenabo, kein Lifetime-Angebot, keinen zweiten Premium-Level und keine automatisch verlängernde Gratis-Testphase. Die dauerhaft nutzbare Gratisversion ist die Produkterprobung. Dadurch bleiben Preis, Kaufzeitpunkt und Rabattlogik einfach. „Kostenlos testen“ darf nicht auf einem Button stehen, der sofort einen bezahlten Kauf auslöst.

### 4.2 Die drei zentralen Argumente

Diese Reihenfolge gilt auf der allgemeinen Paywall:

1. **Lies, was dich interessiert.** Alle veröffentlichten Storys und Themen ohne tägliches Story-Limit.
2. **Lerne mit deinen eigenen Texten.** Texte importieren und passende Wörter im Zusammenhang üben.
3. **Verstehe fehlende Stellen direkt.** 500 neue KI-Übersetzungen pro Abo-Monat; vorhandene Übersetzungen ohne Limit.

Darunter kann eine kurze Ergänzung stehen: „Alle veröffentlichten Grammatik-, Text- und Höreinheiten inklusive.“ Hören wird erst genannt, wenn es wirklich verfügbar ist. Begriffe wie „alle Sprachen“, „KI-Sprachlehrer“, „unbegrenzte Übersetzungen“, garantierte Lernerfolge oder vollständige Synchronisation sind ohne entsprechende Leistung unzulässig für unsere Kommunikation.

Die Überschrift lautet allgemein **„Mehr lesen. Deine eigenen Wörter lernen.“** Nicht „Entfalte dein volles Potenzial“. Konkrete Arbeit mit interessanten Texten ist der Unterschied der App.

## 5. Paywalls: Ort, Zeitpunkt und genaue Botschaft

### 5.1 Nach dem Onboarding

Nach der echten Wortdemo erscheint einmal eine schließbare Premium-Vorstellung zum regulären Preis. Sie wird nicht vor das erste Erfolgserlebnis gestellt. Bestehende Angaben wie Thema und Lernziel dürfen die erste Nutzenzeile anpassen; es werden keine zusätzlichen Fragen ausschließlich zur Erzeugung von Kaufdruck eingeführt.

Der Bildschirm zeigt die drei Argumente, beide Tarife, den Gesamtpreis und gut sichtbar **„Kostenlos weiterlernen“**. Beim Schließen geht es direkt in die nutzbare App. Es erscheint keine zweite Paywall hinterher und kein sofortiger Rabatt.

### 5.2 Kontextabhängige Einstiege

| Auslöser | Überschrift / erster Nutzen | Verhalten |
| --- | --- | --- |
| Weitere Starterstory am selben Tag | „Heute weiterlesen“ – mehrere neue Storys ohne Tageslimit | Die bereits freigeschaltete Story bleibt verfügbar; nächster Gratiszeitpunkt wird genannt. |
| Premium-Story | „Lies diese Story vollständig“ | Titel und Niveau der gewählten Story übernehmen; nach Kauf genau diese Story öffnen. |
| Gesperrter Themenstapel | „Lerne mehr über [Thema]“ | Beispiel zeigen, gesamten Themenumfang als Nutzen erklären. |
| Import-Button | „Mach deinen Text zu deinem Lernstoff“ | Eigene Texte als erstes Argument; eingetippter Entwurf bleibt erhalten. |
| Gesperrte Inhaltsübung | „Übe [konkretes Thema] weiter“ | Zum gewählten Inhalt zurückführen. |
| Fünf kostenlose KI-Anfragen verbraucht | „Weitere Stellen direkt verstehen“ | 500 Anfragen/Monat und freie Inhalte erklären; vorhandene Übersetzungen bleiben nutzbar. |
| Premium-Kontingent verbraucht | Keine Kauf-Paywall | Verbrauch und Resetdatum zeigen. Ein zweites Abo erhöht das Limit nicht. |
| Einstellungen → Premium | Allgemeine Vergleichsansicht | Preise, enthaltene Leistungen, Kauf wiederherstellen und Abo verwalten. |

Eine Paywall wird durch eine eindeutige Nutzeraktion geöffnet. Ein Schloss mit verständlichem Label macht die Einschränkung schon vor dem Tap erkennbar. Keine überraschende Sperre nach mehrminütiger Eingabe und kein Verlust von Inhalt beim Schließen.

### 5.3 Momente, in denen keine automatische Paywall erscheint

Keine automatische Kaufunterbrechung nach einem Fehler, während einer Übung, bei geöffneter Tastatur, während einer Story, in der Stern-/Flammenanimation oder direkt beim Erreichen einer Lernserie. Ein Abschluss gehört zuerst dem Lernenden. Auf Home kann danach eine passende, freiwillig antippbare Karte erscheinen.

Es gibt zum Start keine Rabatt-Push-Nachrichten und keine automatischen Rabatt-E-Mails. Diese Kanäle sind kein notwendiger Bestandteil des Modells.

## 6. Angebote: echte, seltene Anlässe statt Dauer-Sonderpreis

### 6.1 Das Willkommensangebot

Einmalig 39,99 € für das erste Jahr, danach 49,99 € jährlich. Die Kommunikation lautet **„20 % auf dein erstes Premium-Jahr“**. Die Ersparnis beträgt 10 € gegenüber dem regulären Jahrespreis; Rundung erklärt die minimale Abweichung von exakt 20 %.

Berechtigt wird ein Nutzer erst, wenn alle Bedingungen erfüllt sind:

- Mindestens 24 Stunden seit abgeschlossener Einführung.
- Aktivität an mindestens zwei verschiedenen Tagen.
- Mindestens eine echte Lern- oder Lesesitzung abgeschlossen.
- Reguläre Paywall bereits gesehen und ohne Kauf geschlossen.
- Mindestens eine bewusste Premium-Absicht: gesperrte Story, Import oder gesperrter Stapel angetippt.
- Noch nie bezahlt und dieses Angebot noch nie erhalten.

Damit ist 24 Stunden eine Mindestzeit, kein blind ausgelöster Verkaufsalarm. Wer ausschließlich zufrieden kostenlos wiederholt, erhält keinen Rabatt nur wegen des Kalenderablaufs.

Das Angebot wird als ruhige Karte auf Home oder in der passenden Bibliothek angeboten. Es läuft ungefähr eine Woche; maßgeblich ist das echte, serverseitig gespeicherte und vom Store unterstützte Enddatum. Es gibt keinen Sekunden-Countdown. Nach Ablauf entsteht nicht am nächsten Tag dieselbe „letzte Chance“.

### 6.2 Technisch wichtiger Unterschied zwischen den Stores

Auf iOS lässt sich ein gewöhnliches Einführungsangebot nicht beliebig pro Nutzer im eigenen UI an- und ausschalten: Berechtigte Käufer können es vom Store automatisch erhalten. Deshalb wird der verzögerte Willkommensrabatt **nicht** als reguläres Introductory Offer am Jahresprodukt eingerichtet.

Festgelegte Lösung: individuelle, einmal einlösbare Apple Subscription Offer Codes für neue Abonnenten; Ausgabe erst nach serverseitiger Berechtigung, Einlösung über den unterstützten Store-Ablauf. Angebot und Folgepreis bleiben vor der Einlösung sichtbar. Codevorrat, tatsächliche Ablaufdaten, Berechtigung und Einlösebestätigung müssen vor Auslieferung getestet sein. Das Serverdatum wird aus der tatsächlichen Codekampagne übernommen; keine fiktive sekundengenaue Frist. Ein nicht verfügbarer Code erzeugt kein Rabattversprechen.

Android verwendet ein developer-determined Angebot mit erster vergünstigter Jahresphase und anschließender regulärer Jahresabrechnung. Der Server entscheidet über die Ausgabe; die Store-Transaktion entscheidet über den Kauf. Falls ein Store den geplanten Rabatt noch nicht zuverlässig unterstützt, wird dort bis zur Fertigstellung ausschließlich der reguläre Tarif angeboten, kein irreführender Rabattbutton.

Apple Promotional Offers für bestehende oder ehemalige Abonnenten sind nicht mit diesen Neukunden-Codes zu verwechseln. Quellen: [Apple Offer Codes](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-subscription-offer-codes), [Apple Promotional Offers](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-promotional-offers-for-auto-renewable-subscriptions), [RevenueCat zu automatischen Intro-Angeboten](https://www.revenuecat.com/docs/subscription-guidance/subscription-offers), [Google-Angebote](https://support.google.com/googleplay/android-developer/answer/12154973?hl=en-EN).

### 6.3 Rückkehrangebot und Begrenzung

Ein ehemaliger Abonnent kann frühestens 30 Tage nach tatsächlichem Ende der Berechtigung bei einer aktiven Rückkehr ein Angebot für 39,99 € für ein Rückkehrjahr erhalten; danach 49,99 € jährlich. Voraussetzung: erneute Premium-Absicht. Höchstens ein solches Rückkehrangebot innerhalb von zwölf Monaten, keine Kombination mit anderen Rabatten. iOS verwendet dafür ein korrekt signiertes Promotional Offer, Android ein passendes Entwicklerangebot.

Zum Start gibt es keine weiteren saisonalen, zufälligen oder durch Schließen ausgelösten Rabatte. Aktive Abonnenten sehen keine Neukundenangebote. Kündigung allein löst keinen Druckdialog aus; die bezahlte Leistung bleibt bis zum bestätigten Ablauf erhalten.

## 7. Entscheidungslogik für Call-to-Actions

Es braucht anfangs keinen lernenden Verkaufsalgorithmus. Ein erklärbares Regelwerk mit wenigen Ereignissen reicht. Es nutzt Absicht und bereits erlebten Nutzen, keine vermutete Verletzlichkeit, sensorbasierte Stimmung oder individuelle Zahlungsfähigkeit.

### 7.1 Zustände und Prioritäten

Die App unterscheidet `free`, `premium_active`, `premium_grace`, `premium_expired`, `purchase_pending` und `billing_unknown`. Angebotseignung ist ein separater Zustand; sie verleiht noch keinen Premium-Zugang.

Reihenfolge bei jeder CTA-Entscheidung:

1. Laufende Zahlung, Wiederherstellung oder unbekannter Abostatus: Status klären, keine neue Verkaufseinblendung.
2. Aktives Premium beziehungsweise bestätigte Kulanzzeit: Premium-Inhalt erlauben, KI-Kontingent separat prüfen.
3. Ausdrücklicher Tap auf gesperrte Funktion: passende Paywall mit berechtigtem Preisangebot öffnen.
4. Einmalige Onboarding-Vorstellung: reguläre Paywall, sofern noch nie gezeigt und Einführung beendet.
5. Berechtigtes Willkommens-/Rückkehrangebot: freiwillige Karte am passenden Ort.
6. Normale Premium-Karte nach erlebtem Nutzen: erst ab zwei aktiven Tagen und einem abgeschlossenen Lernvorgang.
7. Sonst keine Kaufansprache.

### 7.2 Frequenz und Unterdrückung

- Automatisch geöffnete modale Verkaufsansicht: ausschließlich die einmalige Onboarding-Vorstellung.
- Proaktive Karten: höchstens eine neue Einblendung pro 24 Stunden, insgesamt höchstens drei innerhalb von sieben Tagen; über Home und Bibliotheken gemeinsam gezählt.
- Weggewischte normale Premium-Karte: sieben Tage Ruhe.
- Weggewischene Rabattkarte: für dieses Angebot nicht erneut proaktiv anzeigen. Manuell bleibt das noch gültige Angebot unter Premium aufrufbar.
- Mehrfaches Tippen auf dieselbe Sperre: nach Schließen innerhalb von zehn Minuten eine kurze Erklärung mit bewusstem Button „Premium ansehen“, keine ständig erneut aufspringende Paywall.
- Selbst aufgerufene Preisansichten bleiben immer erreichbar und verbrauchen keine proaktive Einblendung.
- Fehlerzustand, Offline-Problem, Kaufabbruch, laufende Übung und Abschlussanimation unterdrücken proaktive Werbung.

### 7.3 Beispielablauf

Tag 1: Einführung und echte Übung → einmal reguläre Paywall → Nutzer schließt → Starterstapel und erste Starterstory bleiben zugänglich. Tippt er eine zweite Story an, sieht er die Tagesgrenze und kann bewusst Premium ansehen.

Tag 2: Rückkehr nach mindestens 24 Stunden, Lernvorgang vorhanden, vorher Premium-Interesse gezeigt → Home darf eine einmalige Angebotskarte zeigen. Ohne Premium-Interesse erscheint kein Rabatt. Ein Klick führt zu 39,99 € im ersten Jahr mit klarer Verlängerung zu 49,99 €.

Nach Kauf: Die App kehrt zum ursprünglichen Vorhaben zurück. Sie öffnet beispielsweise die gewählte Story. Sie sendet nicht automatisch einen privaten Text an die KI; dafür bleibt die ausdrückliche Übersetzungsentscheidung erforderlich.

Nach Kündigung: Bis zum Ablauf unveränderte Leistung. Danach bleiben Karten, Starterfreigaben und eigene Texte erhalten; neue Premium-Inhalte und neue Importe sind gesperrt. Eine bereits laufende Sitzung darf abgeschlossen werden.

## 8. Psychologische Begründung

**Erlebter Nutzen vor Preis.** Eine echte Wortdemo und eine brauchbare Gratisversion machen den Nutzen überprüfbar. Das ist besonders wichtig, weil eine unbekannte Lern-App noch kein Vertrauen durch eine große Marke besitzt.

**Relevanz statt abstrakter Funktionsliste.** Wer einen Text importieren wollte, sieht zuerst „dein Text“, nicht Grammatik. Inhalt und Ziel der Paywall passen zur gerade sichtbaren Absicht. Die Reihenfolge der Argumente wechselt, die Leistung und der Preis nicht.

**Autonomie.** Ein sichtbarer kostenloser Weg und eine klare Schließen-Funktion reduzieren die Sorge, in ein Abo gedrängt zu werden. Fehler werden nicht monetarisiert. Langfristige Wiederkehr zählt mehr als ein versehentlicher Kauf.

**Wenige Entscheidungen.** Ein Leistungsumfang und zwei Zahlungsintervalle sind leicht vergleichbar. Jahreszahlung ist hervorgehoben, weil kontinuierliches Lernen und Jahresumsatz zusammenpassen; monatliche Zahlung bleibt ein gleichwertig verständlicher Ausweg bei geringer Bindungsbereitschaft.

**Nachvollziehbarer Preisanker.** 119,88 € aus zwölf Monatszahlungen sind ein realer Vergleich zu 49,99 €. Erfundene Streichpreise, nicht existente Nutzerzahlen und angebliche Beliebtheit werden nicht verwendet. „Empfohlen“ ist zulässig als eigene Empfehlung, „am beliebtesten“ erst nach echten Daten.

**Begrenzte, wahrheitsgemäße Gelegenheit.** Das Angebot hat einen echten Zeitraum und klare Eignung. Es wird nicht an jedes Schließen gekoppelt. Andernfalls lernt der Nutzer, dass der reguläre Preis lediglich eine Verhandlungsstufe ist.

**Besitz und Vertrauen.** Erarbeitete Karten und eigene Texte bleiben erhalten. Das ist Teil des Produkts, nicht nur eine Kündigungsbotschaft. Ein Jahresabo soll wegen regelmäßigem Nutzen erneuert werden, nicht wegen Angst vor Datenverlust.

Dies sind begründete Designhypothesen, keine garantierten Conversion-Effekte. Der nachfolgende Messplan prüft, ob sie für diese App tatsächlich funktionieren.

## 9. KI-Kontingent und Wirtschaftlichkeit

### 9.1 Abrechnungseinheit

Eine Einheit ist eine erfolgreich gelieferte neue Wort- oder Satzübersetzung. Bestehende redaktionelle Übersetzungen und gültige Cachetreffer verbrauchen keine Einheit. Eine Story zu öffnen, einen Text einzufügen oder eine lokale Übung zu beantworten verbraucht ebenfalls keine Einheit.

Kostenlos: fünf Einheiten einmalig pro verifiziertem Konto. Premium: 500 Einheiten je Abo-Monat, auch beim Jahresabo monatlich freigegeben. Kein Ansparen und keine 6.000 Einheiten am ersten Tag. Der Reset folgt dem ursprünglichen Kaufdatum mit sauberer Behandlung kurzer Monate; die Oberfläche zeigt das konkrete nächste Datum. Tarifwechsel und Wiederherstellen setzen das Kontingent nicht zusätzlich zurück.

Zusätzliche Schutzlimits: fünf Anfragen pro Minute und 50 pro Tag je Konto. Diese Grenzen gelten sprach- und endpointübergreifend. Sie werden nicht als „unbegrenzt“ verkauft. Das tägliche Limit und die Monatsgrenze werden in der Detailinformation genannt; bei Erreichen wird der nächste Freigabezeitpunkt angezeigt. Kein automatischer kostenpflichtiger Mehrverbrauch und kein Zusatzpaket zum Start.

### 9.2 Serverablauf

1. Identität, Berechtigung und gültige Eingabe prüfen.
2. Redaktionelles Ergebnis beziehungsweise erlaubten Cache prüfen.
3. Eindeutige Anfrage-ID und atomare Reservierung gegen alle relevanten Limits.
4. Modell aufrufen; bestehende Begrenzung auf kurze Satzanfragen beibehalten.
5. Erfolgreiches, validiertes Ergebnis speichern und Nutzereinheit endgültig belasten.
6. Bei Fehler oder Timeout die Nutzereinheit wieder freigeben; möglicherweise trotzdem entstandene Providerkosten intern weiter erfassen.

Parallele Geräte dürfen dieselbe Einheit nicht mehrfach ausgeben. Ein erneuter Tap bei laufender Anfrage verwendet dieselbe Anfrage-ID. Auch ein Modellfehler ist kein Anlass, automatisch weitere Modelle zu probieren.

Für eigene Texte bleibt der Cache kontogebunden; keine privaten Textstellen in einem öffentlich zugänglichen gemeinsamen Cache. Gemeinsames Caching ist nur für freigegebenes, redaktionelles Material vorgesehen. Schlüssel enthalten Sprache, normalisierte Anfrage und Version der Übersetzungslogik. Rohtexte gehören nicht in Analytics-Ereignisse. Lösch- und Aufbewahrungsregeln müssen vor Einführung des serverseitigen Caches festgelegt werden.

Es bleibt bei direktem Anthropic ausschließlich hinter authentifizierten Edge Functions. Keine Client-Schlüssel, kein direkter Client-KI-Aufruf und kein Gemini-/Vertex-Fallback. Die vier Vokabelzähler bleiben aus Karten und Fälligkeiten abgeleitet; ein separates KI-Verbrauchsledger ersetzt diese Zähler nicht.

### 9.3 Was Tokens hier voraussichtlich kosten

Die am Recherchedatum geprüfte offizielle Preisseite nennt für Haiku 5.5 bei kurzen Kontexten 0,10 US-Dollar pro Million Input- und 0,50 US-Dollar pro Million Output-Tokens. Das ist eine veränderliche Anbieterangabe, keine für die Zukunft garantierte Einkaufskondition. Quelle: [Anthropic-Preise](https://platform.claude.com/docs/en/about-claude/pricing).

| Rechenfall, kein gemessener App-Verbrauch | Eine neue Anfrage | 500 Anfragen |
| --- | --- | --- |
| 1.000 Input + 150 Output | 0,000175 US-Dollar | 0,0875 US-Dollar |
| 2.000 Input + 384 Output | 0,000392 US-Dollar | 0,196 US-Dollar |
| Zweiter Fall mit zehnfachem Preis-/Aufwandsfaktor | 0,00392 US-Dollar | 1,96 US-Dollar |

Systemprompt und strukturierte Antwort zählen mit. Die Beispiele ersetzen weder Tokenmessung noch eine Kalkulation mit tatsächlich abgerechneten Requests. Infrastruktur, Support, Redaktion, Zahlungsgebühren, Steuern, Akquisition und Erstattungen kommen hinzu. Euro und US-Dollar werden hier bewusst nicht ohne Wechselkurs gleichgesetzt.

**Schlussfolgerung:** Bei kurzen, begrenzten Übersetzungen ist nach diesen Listenpreisen nicht jede Story ein großer Kostenblock. Das größere Risiko sind unbegrenzte Aufrufe, Missbrauch, unnötige Wiederholungen und ein zu dünner Inhaltswert. Deshalb wird Premium über Inhalte und persönliche Texte verkauft, während die Kosten technisch kontrolliert werden.

### 9.4 Erlösmodell als Planungsrechnung

Nur Modellannahme: deutscher Bruttopreis, 19 % enthaltene Umsatzsteuer, anschließend 15 % beziehungsweise 30 % Storeabzug. Das ist keine Aussage über den tatsächlich für dieses Konto geltenden Vertrag oder eine Steuerabrechnung. Tatsächliche Store-Proceeds müssen die Annahmen vor Freigabe ersetzen.

| Bruttopreis | Rest bei 15 % Abzug nach angenommener Steuer | Monatlicher Vergleich bei Jahreszahlung | Rest bei 30 % Abzug nach angenommener Steuer |
| --- | --- | --- | --- |
| 9,99 € monatlich | 7,14 € / Monat | 7,14 € | 5,88 € / Monat |
| 49,99 € jährlich | 35,71 € / Jahr | 2,98 € | 29,41 € / Jahr |
| 39,99 € erstes Jahr | 28,56 € / Jahr | 2,38 € | 23,52 € / Jahr |

Der Rabatt kostet in der 15-%-Rechnung etwa 7,14 € Jahreserlös. Er lohnt sich nicht allein deshalb, weil mehr Menschen auf den Button klicken. Entscheidend ist zusätzlicher Nettoerlös gegenüber Käufen, die auch zum regulären Preis erfolgt wären.

Interne Startgrenzen: KI-Ausgaben je zahlendem Nutzer im Durchschnitt unter 0,30 € pro Monat anstreben; Gesamt-KI-Tagesbudget zunächst 10 € mit Warnungen bei 50 % und 80 %. Das sind operative Startwerte, keine Schätzung der erreichbaren Nutzerzahl. Vor Erreichen der Grenze muss der Betreiber Kapazität und Betrug prüfen. Ein globaler Schutzstopp wird als technische Einschränkung kommuniziert, niemals als Aufforderung an zahlende Nutzer, erneut zu kaufen. Er ersetzt keine ausreichend dimensionierte Versorgung der zugesagten Kontingente. Die bisherige globale Grenze von 1.000 Anfragen pro Tag muss vor öffentlicher Auslieferung anhand aktiver Nutzer und Reservierungen angepasst werden.

## 10. Abotechnik und Zugangsmodell

Festgelegt: native Käufe über App Store und Google Play, eingebunden über RevenueCat und dessen Flutter-SDK; eigene Paywall im vorhandenen Designsystem. Das reduziert selbst zu pflegende Store-Zustände. Anbietergebühren werden vor Integration separat in die Wirtschaftlichkeit aufgenommen. [Flutter-Integration](https://www.revenuecat.com/docs/getting-started/installation/flutter).

Ein gemeinsames Entitlement `premium`, ein Monatsprodukt, ein Jahresprodukt. Angebote verändern den Preis, nicht die enthaltenen Features. Öffentliche Store-Konfiguration darf in die App, geheime Server-/Provider-Schlüssel nicht.

Kostenloses Lernen braucht kein Konto. Vor einem neuen Kauf wird ein kurzes, echtes Konto angelegt beziehungsweise verknüpft, damit KI-Kontingent und beide Plattformen eindeutig zugeordnet werden können. Derselbe Account gilt für KI-Testeinheiten. Der Kaufdialog erklärt den Zweck; er führt nicht erneut durch das Onboarding. Wiederherstellen bestehender Käufe bleibt von der Paywall aus erreichbar. Eine Konfliktbehandlung verhindert, dass ein Storekauf unbemerkt einem fremden App-Konto zugeordnet wird.

Der Server verwaltet bestätigte Entitlements, Kaufereignisse, Angebotsberechtigungen und KI-Nutzung. Webhooks werden authentifiziert und idempotent verarbeitet; verspätete Ereignisse und periodischer Abgleich werden berücksichtigt. Ein lokales `isPremium=true` ist keine Erlaubnis für kostenpflichtige Backend-Aufrufe. [RevenueCat-Webhooks](https://www.revenuecat.com/docs/integrations/webhooks).

Offline dürfen zuletzt bestätigte lokale Premium-Inhalte bis zum bestätigten Ablaufzeitpunkt genutzt werden. Bei länger laufendem Abo wird der Status beim nächsten möglichen Kontakt aktualisiert. KI benötigt ohnehin Verbindung und serverseitige Berechtigung. Bei unklarem Kaufstatus darf ein Netzwerkfehler weder einen zweiten Kauf erzwingen noch vorhandene Karten löschen.

Kündigung, Ablauf, Erstattung, Widerruf der Berechtigung, Abrechnungsprobleme, Kulanzzeit und wartende Käufe sind getrennte Zustände. Ein abgebrochenes Kaufblatt ist kein Fehlerdialog und kein Rabatt-Trigger. Im Einstellungsbereich gibt es „Abo verwalten“, „Käufe wiederherstellen“ und die gültigen Kontingentdaten.

## 11. Briefing für das Paywall-Design

### 11.1 Aufbau

1. Sichtbare Schließen-/Zurück-Funktion.
2. Eine passende Überschrift, bei Storys mit Bezug zum gewählten Material.
3. Drei kurze Nutzenzeilen; keine lange Featurewand.
4. Jahres- und Monatstarif, Jahr vorausgewählt, Gesamtpreis dominant.
5. Eindeutiger Button: „Premium abonnieren“; beim Angebot „Jahresangebot nutzen“.
6. Direkt beim Button Preis, Laufzeit und Verlängerung. Zum Beispiel: „39,99 € für das erste Jahr, danach 49,99 € jährlich. Automatische Verlängerung; im Store kündbar.“
7. Kostenloser Weg, Wiederherstellen, Nutzungsbedingungen und Datenschutz zugänglich.

Eine kleine Vergleichsansicht darf Details aufklappen, aber entscheidende Einschränkungen und Abrechnung dürfen nicht darin versteckt werden. Das KI-Kontingent steht spätestens in den sichtbaren Nutzenzeilen und der Vergleichsansicht, nicht erst in Rechtstexten.

Apple fordert eine verständliche Darstellung der Gegenleistung und der wiederkehrenden Zahlung; der tatsächlich zu zahlende Betrag muss klar sein. Google verlangt ebenfalls transparente Abokonditionen und einen nicht irreführenden Kaufablauf. Die abschließende Store-Prüfung verwendet die dann aktuellen Regeln. Quellen: [Apple-Abonnements](https://developer.apple.com/app-store/subscriptions/), [Google-Aborichtlinie](https://support.google.com/googleplay/android-developer/answer/9900533?hl=en).

### 11.2 Benötigte Designzustände

- Reguläre Onboarding-Paywall, schließbar.
- Story-Limit und konkrete Premium-Story.
- Import und gesperrte Übung/Themenstapel.
- KI-Testkontingent beendet.
- Angebotskarte und Angebots-Paywall mit Ablaufdatum und Folgepreis.
- Angebot abgelaufen oder nicht berechtigt.
- Kauf läuft, ausstehend, abgebrochen, fehlgeschlagen und erfolgreich.
- Wiederherstellung, bereits aktives Abo und Kontokonflikt.
- Premium-Kontingent ausgeschöpft ohne zusätzliche Kaufaufforderung.
- Abo abgelaufen, kostenlose Nutzung weiterhin möglich.

Alle Zustände werden in den vorhandenen Screen-Vorschaukatalog aufgenommen, einschließlich realistisch langer Preise, großer Schrift und kleinem iPhone. Vorschaukäufe verwenden Fake-Store-Zustände und lösen nie echte Zahlungen aus. Der vorhandene Kommentar zur Aufnahme neuer besonderer Screens gilt auch für diese Paywalls.

## 12. Messplan und Experimente

### 12.1 Erfolg definieren

Primäre Kennzahl ist der **Nettoerlös pro neuem aktivierten Nutzer nach 60 Tagen**, nach Erstattungen und variablen KI-Kosten. Aktiviert bedeutet: mindestens eine echte Übung oder Story abgeschlossen. Zusätzlich wird dieselbe Kennzahl pro Installation berichtet, damit eine veränderte Aktivierungsquote nicht verborgen bleibt.

Frühe Orientierung: Kauf innerhalb von 35 Tagen, getrennt nach Einstieg, Store, Tarif und Angebotsberechtigung. Langfristig: aktive Lernende nach 30/90 Tagen, Kündigung, Erstattungen und tatsächliche Jahresverlängerung. Eine Jahresverlängerungsquote lässt sich erst nach realem Ablauf des ersten Jahres beobachten; vier Monate Umsatz sind dafür kein Beleg.

Schutzkennzahlen: Abschlussrate der ersten Übung, kostenlose Wiederkehr nach sieben Tagen, Paywall-Abbrüche, Supportbeschwerden, technische Übersetzungsfehler und Anteil aktiver Premium-Nutzer, die am Kontingent scheitern. Als Alarm gelten beispielsweise mehr als 10 % relative Verschlechterung der kostenlosen D7-Wiederkehr oder mehr als 2 Prozentpunkte zusätzliche Erstattungen gegenüber einer vergleichbaren Kontrollgruppe. Diese Schwellen sind Startregeln, keine statistische Signifikanzbehauptung.

### 12.2 Ereignisse

`onboarding_completed`, `learning_session_completed`, `story_unlock_requested`, `story_unlocked`, `premium_intent`, `paywall_viewed`, `paywall_dismissed`, `plan_selected`, `purchase_started`, `purchase_verified`, `purchase_pending`, `restore_completed`, `offer_eligible`, `offer_shown`, `offer_redeemed`, `entitlement_expired`, `translation_cache_hit`, `translation_succeeded`, `translation_failed`, `quota_reached`.

Metadaten: anonymer beziehungsweise pseudonymer Nutzerbezug, Zeit, Plattform, UI-Kontext, Produkt-ID, Angebots-ID, Experimentgruppe und Abostatus. Kein vollständiger importierter Text, keine eingegebenen Antworten und keine Übersetzungsinhalte im Analytics-Payload. Preise und Währungen werden passend zum tatsächlichen Storeprodukt protokolliert. Ein ausgeführter Button-Tap ist noch kein bestätigter Umsatz.

### 12.3 Festgelegte Experimentreihenfolge

1. **Verständlichkeit:** allgemein formulierte gegen kontextbezogene erste Nutzenzeile; Preise und Umfang identisch.
2. **Onboarding-Platzierung:** einmalige schließbare Vorstellung gegen ausschließlich kontextbezogene Ansprache. Gratisangebot bleibt identisch.
3. **Rabatt-Inkrementalität:** Unter berechtigten Nutzern erhalten 80 % das Willkommensangebot, 20 % eine neutrale Kontrollgruppe ohne Rabatt. Verteilung stabil pro Nutzer; nur tatsächlich ausgegebene Angebote werden versprochen.

Zum Start laufen nicht drei Experimente gleichzeitig. Pro Test werden eine Hypothese, eine Hauptkennzahl, Laufzeit und Auswertungsregel vorher festgehalten. Für die 35-Tage-Kaufkennzahl müssen Kohorten volle 35 Tage beobachtet werden. Stichprobenbedarf wird aus der gemessenen Ausgangsrate und dem relevanten Mindestunterschied berechnet. Bei zu wenig Daten gibt es kein künstliches Siegeretikett.

Die 9,99 €/49,99 € und die Leistungsgrenzen sind die Startentscheidung. Tests an Formulierung und Platzierung ändern sie nicht beiläufig. Für eine spätere Preisanpassung braucht es eine neue ausdrückliche Produktentscheidung und korrekte Behandlung bestehender Abonnenten.

## 13. Erkenntnisse aus dem bereitgestellten Paywall-Material

Inventar: 10 Markdown-Dateien, 21 JSON-Dateien und eine RTF-Sammlung mit 17 Transkripten. Inhaltliche Beiträge, Kommentare, Artikelpassagen und relevante Transkriptabschnitte wurden ausgewertet. Nicht jede Datei enthält einen vollständigen Artikel; einige sind Teaser oder Scraping-Reste. Die Sammlung ist wertvoll für Hypothesen, aber kein einheitlicher Datensatz kontrollierter Experimente.

| Material im Ordner `aislop/paywall` | Erkenntnis | Entscheidung für diese App |
| --- | --- | --- |
| `Things-that-actually-changed-our-conversion-rate-just-with-the-paywall.json` | Selbstbericht zu vielen Tests; Reihenfolge, konkrete Überschrift und Klarheit waren wichtiger als reine Dekoration. | Kontextbezogener Hauptnutzen, einfache Preise, strukturierte Tests. Genannte Steigerungen sind keine Prognose. |
| `Hard-paywalls-convert-5x-better-than-freemium-I-was-about-to-do-the-op.json` und `Hard-paywall-vs-soft-paywall-in-iOS-apps-worth-trying.json` | Unterschiedliche App-Typen und Auswahl der Nutzer verzerren Vergleiche; Berichte widersprechen sich. | Kein harter Startverschluss allein aufgrund eines Branchenmittelwerts. |
| `I-switched-from-a-soft-paywall-to-a-hard-paywall-and-my-MRR-doubled-in.json` | Kleine Ausgangsbasis und wenige Tage Beobachtung. | Verdopplung ist ohne Volumen und Dauer kein belastbarer Beleg. |
| `Switched-from-a-soft-paywall-to-a-hard-paywall-Conversions-spiked-like.json` | Onboarding und Paywall zugleich geändert. | Änderungen getrennt testen; Aktivierung und Bindung mitmessen. |
| `One-small-paywall-TEXT-change-took-my-app-from-100-to-700-MRR.json` | Mehrdeutige „Try“-Formulierung kann wie eine kostenlose Probe wirken. | Eindeutiger Kaufbutton; kein Gratisversprechen bei sofortiger Zahlung. |
| `Bad-reviews-from-users-offended-by-a-paywall-for-an-app-marked-with-in.json` | Storehinweis „In-App-Käufe“ erklärt die tatsächlichen Gratisgrenzen nicht. | Starterumfang und Premium-Schlösser vor einer langen Interaktion offenlegen. |
| `Use-Commitment-Psychology-to-Soften-Your-Paywall.json` sowie die Datei mit `(1)` | Nahezu doppelte werbliche Darstellung; nicht zwei unabhängige Belege. | Vorhandene Ziele aufgreifen, keine künstlich verlängerte Fragenstrecke. |
| `This-is-How-I-Scaled-My-App-to-35K-in-Just-4-Months.json` | Beitragstext beschreibt kleinere Zahlen als der Dateiname suggeriert; Akquisitions-/API-Kosten und Beobachtungszeit sind wichtig. | Nettobeitrag statt MRR-Screenshot; keine vorschnelle Aussage über Jahresverlängerungen. |
| `50-Paywall-Examples-and-the-Strategies-Behind-Them.md`, `Mobile-App-Onboarding-5-Paywall-Optimization-Strategies.md` | Klarheit, echte Produktprobe und verständlicher Kontext. | Vergleichsmatrix und passende Einstiege; kein Kopieren fremder Erfolgszahlen. |
| `How-to-personalize-app-onboarding-and-paywalls.md` | Relevante Personalisierung und Experimente statt Kosmetik. | Nur Thema, Ziel und bewusst gewählte Funktion verwenden; keine kleinteilige Preismanipulation. |
| `5-Paywall-Patterns-Used-By-Million-Dollar-Apps.md`, `Paywall-Design-The-Overlooked-Engine-Behind-Every-Winning-Subscription.md` | Anbieterbeispiele, Muster und Umsatzschätzungen; keine isolierten Wirkungsnachweise. | Nutzenstruktur übernehmen, Glücksrad und künstliche Dringlichkeit verwerfen. |
| `Moments-Over-Screens-Timing-Psychology-For-Trials-Paywalls-Push.md` | Zeitpunkt kann relevant sein; Quelle verkauft entsprechende Technologie. | Einfache Produkt-Ereignisse reichen; kein zusätzlicher Sensor-/Stimmungs-SDK. |
| `Best-paywall-subscription-strategy-for-iOS-apps-Weekly-vs-Monthly-vs-Y.json`, `Fast-question-For-paywalls-Is-it-better-to-give-free-trial-or-not.json` | Keine allgemeingültige Laufzeit oder Trial-Regel. | Monat/Jahr passend zur Lerngewohnheit; zum Start permanente Gratisprobe statt Abo-Trial. |
| `Mobile-App-Paywall-2026-Guide-Types-Benchmarks.md`, `What-does-a-high-performing-paywall-look-like-in-2026.md` | Kennzahlen und Nenner werden teilweise vermischt; pauschale Storebehauptungen nicht ausreichend belegt. | Offizielle Regeln und sauber definierte eigene Kennzahlen haben Vorrang. |
| `Launching-a-Free-App-with-Premium-Screens-and-Paywall-blocks-while-wai.json` | Erwartungsschaden durch unfertige Käufe oder nachträglich überraschende Sperren. | Fertiges Billing und Bestandsschutz vor Monetarisierungsstart. |
| `Paywall_transkripte.rtf`, insbesondere Gespräche 12, 16 und 17 | Kontextbezogene Angebote, Warnung vor sofortigen Rabatten und langfristige Bindung; unterschiedliche Trial-Erfahrungen. | Kein Rabatt nach jedem Schließen; Rückkehr und Nettoerlös messen. Interviewaussagen bleiben Erfahrungsberichte. |

Die Dateien `3-psychology-principles-to-run-paywall-experiments.md` und `Freemium-vs-Hard-Paywall-rAppBusiness.md` enthalten zu wenig substanzielle Information für eigenständige Schlussfolgerungen. Reddit-Kommentare zu Storezulässigkeit ersetzen keine offizielle Store-Dokumentation. Nicht sichtbare Designbilder werden nicht als geprüfte Referenz behandelt.

Einordnung mit externer Primärquelle: RevenueCat berichtet im State of Subscription Apps 2026 mediane D35-Download-zu-Kauf-Raten von 10,7 % bei Hard Paywalls und 2,1 % bei Freemium. Das ist eine Beobachtung unterschiedlicher Apps, kein randomisierter Nachweis, dass dieselbe Lern-App mit einer Hard Paywall fünfmal besser würde. Es handelt sich zudem nicht um Trial-zu-Kauf. Daraus folgt für dieses Projekt kein Verzicht auf die kostenlose Lernschleife. [RevenueCat-Bericht](https://www.revenuecat.com/state-of-subscription-apps/).

Lokale Quellen: [Paywall-Materialordner](/Users/ardasayar/Documents/aislop/paywall), [Erfahrungen zu Paywall-Tests](/Users/ardasayar/Documents/aislop/paywall/Things-that-actually-changed-our-conversion-rate-just-with-the-paywall.json), [Onboarding und Personalisierung](/Users/ardasayar/Documents/aislop/paywall/How-to-personalize-app-onboarding-and-paywalls.md), [Transkriptsammlung](/Users/ardasayar/Documents/aislop/paywall/Paywall_transkripte.rtf).

## 14. Umsetzung und Freigabekriterien

### Schritt 1: Inhaltswert absichern

Vor dem ersten Verkauf je beworbener Sprache bereitstellen: 12 vollständige Starterstorys und mindestens 36 zusätzliche Premium-Storys, ein vollständiger Starterstapel und mindestens vier zusätzliche Themenstapel. Für einen veröffentlichten Bereich Textübungen beziehungsweise Grammatik mindestens sechs zusätzliche Premium-Übungen über die Gratisprobe hinaus. Die Mengen sind Freigabeschwellen, keine Behauptung über den aktuellen Bestand.

Eine redaktionelle Veröffentlichung von mindestens vier zusätzlichen Storys pro Monat je aktiv verkaufter Sprache wird intern eingeplant und finanziert. Erst nach nachgewiesenem Produktionsablauf darf diese Frequenz als öffentliches Versprechen verwendet werden. Sprachen und Audioangebote, die diese Qualitätsprüfung nicht bestehen, werden nicht im Premium-Versprechen geführt. Kein Verkauf aufgrund von Platzhaltern.

### Schritt 2: Berechtigungen und Bestandsschutz

Materialfreigaben, Kartenaufnahme, kostenlose Tagesfreischaltung und bestehende Nutzerrechte modellieren. Migration vorsehen. Rechte an aufgenommenen Karten und eigenen Texten unabhängig vom aktuellen Abo speichern; die vier Vokabelzähler weiterhin berechnen. Öffentlichen Accountflow fertigstellen.

### Schritt 3: Kaufverwaltung

Storeprodukte, RevenueCat, verifizierte Serverberechtigung, Wiederherstellung, Kontoverknüpfung, Abostatus, Erstattungen und Offline-Verhalten implementieren. Reguläre Tarife zuerst vollständig testen. Rabattkampagnen erst aktivieren, wenn Codeeinlösung und Folgepreise verifiziert sind.

### Schritt 4: KI-Schutz

Kostenlose Testeinheiten, Monatsledger, Cache, Anfrage-IDs, Fehlererstattung und globale Budgetüberwachung implementieren. Reale Input-/Output-Tokens mit nicht privaten Testfällen messen. Limits im UI sichtbar machen und Lastfälle mit mehreren Geräten prüfen.

### Schritt 5: Oberfläche und Vorschauen

Alle Paywalls, Vergleichsansichten, Sperren, Einstellungen und CTA-Regeln gemäß diesem Plan gestalten. Die Screen-Preview-Buttons um jeden neuen Zustand ergänzen. Große Schrift, VoiceOver/TalkBack, Tastatur und kleine Geräte berücksichtigen. Kaufen darf keine Voraussetzung sein, einen Dialog wieder zu verlassen.

### Schritt 6: Kontrollierter Start

Zunächst Sandbox/TestFlight beziehungsweise interne Play-Tests, anschließend begrenzte Veröffentlichung mit überwachten Kennzahlen. Erst nach korrekter Ereignis- und Umsatzzuordnung beginnt das erste Formulierungsexperiment. Keine parallele Änderung von Preis, Gratismenge und Paywall-Platzierung.

### Abnahmeszenarien

- Kostenloser Nutzer macht beliebig viele Fehler: Wiederholung bleibt ohne Kauf möglich.
- Erste Starterstory freigeschaltet; zweite am selben Tag gesperrt; erste bleibt wiederlesbar; am nächsten Kontotag genau eine neue Freigabe.
- Alle zwölf Starterstorys erworben: dauerhaft zugänglich, keine fälschliche tägliche Gratiszusage.
- Zwei Geräte schicken gleichzeitig die letzte KI-Anfrage: genau eine gültige zusätzliche Belastung, keine Überziehung.
- Cachetreffer verbraucht nichts; fehlgeschlagene Anfrage gibt die Nutzereinheit frei.
- Monatswechsel, 29./30./31. als Kaufdatum und Tarifwechsel erzeugen kein doppeltes Guthaben.
- Abo läuft während einer Übung oder Lesesitzung ab: Sitzung abschließbar, Karten bleiben erhalten.
- Kündigung löscht weder Importe noch Lernfortschritt; Export eigener Texte bleibt möglich.
- Kauf wird unterbrochen, bestätigt sich verzögert oder wurde schon auf anderem Gerät gekauft: kein Doppelkauf-Druck.
- Rabatt wird geschlossen oder läuft ab: kein Neustart der Frist; falsche Berechtigung zeigt keine falschen Preise.
- iOS-Codeeinlösung und Android-Angebot buchen den erwarteten ersten Preis und zeigen den korrekten Folgepreis.
- Aktiver Premium-Nutzer erreicht 500 Anfragen: Resetinformation statt neuer Kaufaufforderung.
- Offline-Start und verspäteter Webhook: bestehende lokale Rechte bleiben konsistent, Server-KI bleibt geschützt.
- Jeder Paywall-Zustand ist im Vorschaukatalog ohne echte Zahlung aufrufbar.

## 15. Verbindlicher Beschluss für Produkt und Design

Umgesetzt wird ein großzügiger, aber begrenzter kostenloser Einstieg: vollständiger Starterstapel, zwölf nach und nach freischaltbare Starterstorys, echte Inhaltsproben und dauerhaft freie Wiederholungen. Premium öffnet die veröffentlichte Bibliothek, alle Themen und Übungen sowie eigene Texte. KI bleibt mit fünf einmaligen Gratisanfragen und 500 monatlichen Premium-Anfragen verständlich begrenzt.

Der Preis lautet **9,99 € monatlich oder 49,99 € jährlich**. Ein gezieltes Angebot reduziert ausschließlich das erste berechtigte Jahr auf **39,99 €**, mit anschließend klar ausgewiesenen **49,99 € jährlich**. Die Hauptargumente sind freie Inhaltswahl, persönliche Texte und direktes Verstehen. Die App verdient an mehr relevantem Lernstoff und wiederkehrendem Nutzen, während Fehler, Fortschritt und eigene Daten geschützt bleiben.
