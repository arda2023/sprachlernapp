# Storybilder: gecachtes Assetmanifest

Nachweis vom 01.11.2026, Flutter 3.47.2 (`d3b14c8769`).

## Ursache

Home und Stories zeigten trotz vollständig gebündelter Bilder nur die typografischen Cover. Der frische Simulatorstart bestätigte korrekte Story-IDs und Bildpfade, aber jeder Manifest-`FutureBuilder` blieb dauerhaft in `ConnectionState.waiting`. Die Bilddecoder wurden dadurch überhaupt nicht gestartet.

`CachingAssetBundle.loadStructuredBinaryData` liefert nach erfolgreichem Laden einen `SynchronousFuture`. Das tritt beispielsweise auf, wenn Google Fonts das Assetmanifest bereits geladen hat. Die bisherige Kette in `StoryCover._assets` war:

```dart
AssetManifest.loadFromAssetBundle(bundle)
    .then((manifest) => manifest.listAssets().toSet())
    .catchError((Object _) => <String>{});
```

Im verwendeten Flutter-SDK gibt `SynchronousFuture.catchError` einen neuen, nie abgeschlossenen `Completer<T>().future` zurück, auch wenn das vorgelagerte Ergebnis erfolgreich war. Diesen hängenden Future speicherte der Cover-Cache. Deshalb konnten vorhandene Bilder nach einem warmen Manifestcache unbegrenzt unsichtbar bleiben.

Die 44 PNGs und ihre 44 Manifest-Einträge waren sowohl im Geräte- als auch im Simulatorbundle vorhanden. Alle 220 illustrierten Sprachvarianten ließen sich über die tatsächlichen gebündelten Story-IDs auflösen; der Defekt lag danach im Laden der Darstellung.

## Korrektur

`StoryCover._loadAssets` verwendet jetzt `async`/`await` mit `try`/`catch`. Der äußere Future liefert sowohl beim ersten Laden als auch beim synchron gecachten Manifest die Bildschlüssel. Die bisherige Manifestprüfung und der Kategorie-Fallback bei fehlenden oder ungültigen Bildern bleiben erhalten. Alle Storykarten auf Home, in der Bibliothek, in Inhalte und unter Weiterlesen nutzen dieselbe Komponente.

## Prüfung

- Die neue Regression lädt ein echtes Assetmanifest vor und bestätigt ausdrücklich den anschließenden `SynchronousFuture`. Mit der alten Kette scheiterte sie: `Expected: true / Actual: false / both art layers must decode automatically`.
- Mit der Korrektur bestehen die Fälle für ein kaltes und ein synchron gecachtes Manifest. Beide Bildschichten werden automatisch decodiert; ein Pixeltest prüft, dass die Illustration tatsächlich auf der Karte gemalt wird. Kein Vorladen durch `precacheImage`.
- Die Integration lädt die echten JSON-Bibliotheken über `bundledStoriesProvider`/`libraryStoriesProvider` und echte SQLite-Storyzusammenfassungen. Home und Stories zeigen damit für alle fünf Lernsprachen gemalte Illustrationen. Jeder Test erhält einen echten `PlatformAssetBundle`, damit Futures nicht zwischen den getrennten Testzeitzonen weiterleben.
- `flutter test test/story_cover_test.dart test/story_cover_integration_test.dart --reporter expanded`: **17 bestanden** (`00:05 +17: All tests passed!`). Die Testumgebung meldet zusätzlich fehlende Google-Fonts-Dateien bei deaktiviertem Netzladen; diese Meldungen sind keine fehlgeschlagenen Tests.
- Der koordinierende Durchlauf bestätigte nach Hot Restart sichtbare Illustrationen für „Building Claude“ und „How black holes grow“ im Simulator. Ein Hot Reload allein kann bereits hängende statische Cachewerte behalten.

GitNexus: Repository und Checkout `/Users/ardasayar/Documents/FlutterProjekte/sprachapp`, vollständiger Indexaufbau am 01.11.2026. Impact vor der Änderung: `StoryCover`, Risiko **LOW**, vier direkte Referenzen und ein erfasster Prozess; direkte Verbraucher sind das gemeinsame Karten-Cover und `ContinueReadingTile`.

## Korrigierte Geräteauslieferung und Premium-Testkonfiguration

Der vorherige Aufruf `flutter build ios --release --no-pub` hatte die vorhandene
lokale Konfiguration nicht übernommen. Die generierte Xcode-Konfiguration enthielt
keine Adapty-/Supabase-/Google-Anmeldedefines und keine Kauf-Flags. Das erklärte die
Meldung „Käufe sind in diesem Build noch nicht verfügbar.“; es war kein Beleg für
einen defekten Storekauf.

Die korrigierte Version wurde über `python3 tool/payment_build.py ios-profile
--device <geraete-id>` mit der bestehenden lokalen Konfiguration gebaut. Die
effektiven Defines wurden ohne Ausgabe ihrer Schlüsselwerte geprüft: SDK,
Serverzugriff und Google-Anmeldung vorhanden, Sandbox `true`, öffentliche
Rechtsfreigabe weiterhin `false`. Keine Kauf-Gates oder serverseitigen
Berechtigungen verändert. 17 Python-Buildhelfertests und 20 gezielte
Flutter-Kauf-/SDK-Adaptertests bestanden.

Auslieferung auf „iPhone von Claus (wireless)“ am 01.11.2026:

```text
Xcode build done. 89,2s
Installing and launching... 7,4s
Flutter exit code: 0
Status: build/payment/ios-profile-20261101T073216222221Z.json
```

Nach Trennen der Flutter-Anbindung bestätigte `devicectl` einen eigenständigen
Start von `com.ardasayar.linglossa`. Alle 44 PNG-Hashes stimmen auch im finalen
Profile-Bundle mit den Quelldateien überein. Keine Deinstallation oder
Lerndatenlöschung. Die sichtbare Bildanzeige wurde im Simulator geprüft; ein
erneuter tatsächlicher Apple-Sandbox-Kauf auf dem physischen iPhone wurde in
diesem Durchlauf nicht ausgeführt.
