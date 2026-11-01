# Spracheingabe in Stapelübungen – Auslieferung 01.11.2026

> Korrektur nach Nutzerprüfung: Der unten dokumentierte erste Release-Build
> enthielt die Bilder, zeigte sie wegen eines Manifestcache-Fehlers aber nicht
> zuverlässig an. Außerdem fehlten ihm die vorhandenen Dart-Defines für Käufe,
> Anmeldung und Serverzugriff. Installation und Start waren erfolgreich;
> daraus ließ sich keine funktionierende Bildanzeige oder Kaufkonfiguration
> ableiten. Der Bildfehler ist in [Story-Cover-Cache-Fix](story-cover-cache-fix.md)
> dokumentiert. Für die korrigierte Geräteauslieferung wird der vorhandene
> Profile-Buildhelfer mit vollständiger lokaler Konfiguration verwendet;
> siehe [Setup](setup.md#bestehende-iphone-testinstallation-aktualisieren).

## Verhalten

Neben dem Lautsprecher steht bei unbeantworteten Karten eine Mikrofontaste. Die erste Betätigung fordert die Systemberechtigungen an. Die erkannte Antwort ersetzt den Inhalt des Eingabefelds; sie bleibt editierbar und wird nicht automatisch bewertet oder abgeschickt. Erneutes Tippen beendet das Zuhören und lässt noch das abschließende Erkennungsergebnis zu.

Die Erkennung verwendet die Lernsprache der aktuellen Karte: Englisch, Spanisch, Italienisch, Norwegisch oder brasilianisches Portugiesisch. Eine fehlende passende Erkennungssprache führt zu einem Hinweis, nicht zu einer Erkennung in einer beliebigen anderen Sprache. Die Verfügbarkeit hängt vom Gerät und dem installierten Systemdienst ab.

Die Umsetzung nutzt `speech_to_text` 7.5.0 mit den Systemdiensten von iOS und Android. Es entstehen keine eigenen KI-API-Gebühren. Offlinebetrieb ist nicht garantiert: Der Systemdienst kann abhängig von Gerät und Sprache Server verwenden. Die App speichert keine Audioaufnahmen. Bluetooth wird für diese Funktion nicht angefordert.

Manuelles Tippen, Prüfen, Aufdecken, Kartenwechsel, Verlauf, Verlassen des Screens und Wechsel in den Hintergrund brechen die aktuelle Erkennung ab. Verspätete Ergebnisse dürfen keine neue Karte oder manuell korrigierte Antwort überschreiben. Vor dem Zuhören wird eine laufende Sprachausgabe beendet. Nach dem Diktieren kann die Sprachausgabe ihre Audio-Konfiguration erneut setzen.

## Überprüfungen

Die folgenden Flutter-Befehle sind unter macOS Terminal und Windows PowerShell identisch:

```text
flutter test --no-pub test/device_dictation_test.dart test/practice_dictation_test.dart
28 tests passed

flutter analyze --no-pub lib/presentation/audio/device_dictation.dart lib/presentation/audio/device_speech_playback.dart lib/screens/decks/deck_practice_screen.dart lib/screens/decks/widgets/practice_chrome.dart lib/screens/decks/widgets/practice_input.dart test/device_dictation_test.dart test/practice_dictation_test.dart
No issues found! (ran in 2.7s)

flutter build apk --debug --no-pub
Built build/app/outputs/flutter-apk/app-debug.apk
```

Zusätzlich auf macOS mit Xcode:

```text
flutter build ios --release --no-pub
Built build/ios/iphoneos/Runner.app (317.3MB)
```

Der iOS-Build enthält die Mikrofon- und Spracherkennungszwecktexte sowie die native Plugin-Registrierung. Alle 44 PNG-Dateien aus `assets/story_covers` wurden per SHA-256 mit dem tatsächlichen Release-Bundle verglichen: alle identisch.

Beim Android-Build kollidierten die vorhandenen Backup-Konfigurationsattribute mit Adapty 4.1.0. Die App verwendet jetzt explizit ihre eigenen Regeln und übernimmt zusätzlich den Ausschluss `AdaptySDKPrefs.xml`. Die bisherigen Ausschlüsse für Flutter Secure Storage bleiben erhalten. Die XML-Dateien und die Ausschlüsse des SDK wurden geprüft; der anschließende Build war erfolgreich.

Die gezielten Tests prüfen unter anderem verzögerte Ergebnisse, fehlende Berechtigungen, einen vom System still abgelehnten Start, Sprachwahl, manuelle Korrekturen, Kartenwechsel, Hintergrundwechsel und die Toolbar bei 320 Pixel Breite mit doppelter Textgröße. Eine echte akustische Erkennung mit gesprochenem Wort wurde nicht automatisiert nachgewiesen. Android wurde gebaut, aber nicht auf einem physischen Android-Gerät getestet.

## Bereits vorhandene Testfehler

Die gesamte ältere Testsammlung ist nicht grün. Vier beobachtete Fehler wurden zusätzlich in einem isolierten, unveränderten Checkout von `79ab365722ca2de13d874fdd2452de54990654da` reproduziert. Die geprüften Testdateien waren bytegleich zum Ausgangsstand:

- `practice_error_feedback_test.dart:167`: erwarteter Review fehlt.
- `practice_ui_test.dart:200`: erwartete Input-Formatierer fehlen.
- `practice_polish_test.dart:55`: „Weiter“ fehlt; anschließend hängt das Test-Cleanup.
- `presentation/device_speech_test.dart:210`: erwartet „Mia … home.“, erhält „It takes … an hour.“.

Diese Tests setzen eine bestimmte erste Karte voraus. Die bereits vorhandene stabile Mischung liefert jedoch zuerst „about“ statt „walks“. Dadurch schlagen die festen Antwort- und Satzannahmen fehl. Die Tests wurden in dieser Aufgabe nicht geändert. Die übrigen neun Tests der Audio-Testdatei bestanden im aktuellen Arbeitsstand.

## Installation

Nach erfolgreichen Builds wurde die Release-App über die drahtlose Geräteverbindung auf „iPhone von Claus“ aktualisiert. Kein Deinstallieren und kein absichtliches Zurücksetzen der Nutzerdaten.

```text
App installed:
bundleID: com.ardasayar.linglossa
databaseSequenceNumber: 16756

Launched application with com.ardasayar.linglossa bundle identifier.
```

Die Installation enthält den gesamten aktuellen Arbeitsstand einschließlich der Story-Bilder und der bereits zuvor umgesetzten Funktionen. Der Bericht bestätigt Build, Tests, Bundle-Inhalt, Installation und Start; er behauptet keinen vollständigen manuellen Durchlauf aller bisherigen Funktionen.
