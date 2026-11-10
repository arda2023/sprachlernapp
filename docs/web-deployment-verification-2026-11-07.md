# Web-/Sync-Deployment: Abnahme vom 07.11.2026

Die Umsetzung wurde nach ausdrücklicher Freigabe auf das bestehende Supabase-Projekt und das angeschlossene iPhone angewendet. Cloudflare wurde nicht veröffentlicht; der Webbuild bleibt für den späteren Upload vorbereitet.

## Ausgeführter Stand

- Migration `20261107000001_learning_sync.sql` veröffentlicht. `npx supabase migration list --remote` zeigt `20261107000001` lokal und remote.
- Bestehende Edge Functions `lookup-word`, `translate-sentence`, `create-learning-card`, `generate-vocabulary`, `billing-sync` und `delete-account` mit der gemeinsamen CORS-Hülle veröffentlicht. Die sechs live ausgeführten `OPTIONS`-Anfragen lieferten jeweils HTTP 204. JWT-Prüfung bleibt aktiviert. Cachelöschung ist weiterhin `DELETE translate-sentence`.
- Aktualisierte iPhone-App über den vorhandenen `payment_build`-Profilbuild installiert und gestartet. Werkzeugausgabe: Xcode-Build **45,4 s**, `Installing and launching... 8.8s`.
- Bestehende angemeldete Browsersitzung neu geladen: „Lernstand abgeglichen“. Der vorhandene Premiumzugang mit Ablauf 03.11.2027 wurde korrekt angezeigt. Die Stapeloberfläche zeigte die übernommenen Fortschritte: Allgemeine Sprache **67 %**, unregelmäßige Verben **69 %**, Vergangenheitsformen **15 %**. Lokaler Bildnachweis: `build/qa/web-sync-live.jpg` (Buildartefakt, nicht versionierte Quelldatei).

## Unabhängige Datenbankprüfung

Prüfung über den vorhandenen Supabase-CLI-Login, ohne Ausgabe von Schlüsseln, Nutzerkennungen, Karteninhalten oder Importtexten:

- RLS für `app.learning_sync_rows` aktiviert; Lesepolicy ausschließlich `auth.uid() = user_id`.
- `anon`: keine Tabellenleserechte und keine Ausführungsrechte auf Push-/Pull-RPCs.
- `authenticated`: Tabellenlesen erlaubt, direkte Inserts/Updates/Deletes verboten; beide RPCs ausführbar.
- RPCs sind `SECURITY DEFINER` mit leerem `search_path`; Konto-ID kommt ausschließlich aus `auth.uid()`.
- Fremdschlüssel auf `auth.users(id)` mit `ON DELETE CASCADE` vorhanden.

Zusätzlich lief eine isolierte synthetische Transaktion gegen die tatsächlich veröffentlichten RPCs. Sie legte zufällige Testkonten mit `example.invalid`-Adressen an, wechselte für die Aufrufe in die Datenbankrolle `authenticated` und prüfte:

1. Erfolgreiches Schreiben und Lesen eines Kartenstands.
2. Neuerer Stand gewinnt; ältere Änderungen überschreiben ihn nicht.
3. Reviewzeilen können nicht nachträglich verändert werden.
4. Fehlende und unbestätigte Identitäten werden abgewiesen.
5. Ein anderes Konto sieht weder über RPC noch über direkten RLS-Lesezugriff die Testzeilen.
6. Direkte Schreibrechte fehlen auch für das eigene Konto.
7. Kontolöschung entfernt die gebundenen Synczeilen.

Ergebnis: `PASS: live authenticated push/pull, LWW, immutable reviews, verified identity, RLS isolation, write grants, deletion cascade; synthetic transaction rolled back`.

Die gesamte Transaktion wurde mit `ROLLBACK` beendet. Eine anschließende unabhängige Leseabfrage bestätigte **0 verbleibende synthetische Testkonten**. Echte Nutzerdaten wurden durch diese Prüfung nicht verändert.

## Tatsächlicher hochgeladener Lernstand

Aggregierte Leseabfrage am 07.11.2026 um 16:31 UTC: genau **ein Konto** mit synchronisierten Zeilen.

| Bestand | Anzahl |
|---|---:|
| Kartenstände | 225 |
| Reviews | 281 |
| Private Kartenkontexte | 10 |
| Generierte Stapelmitgliedschaften | 10 |
| Stapeleinstellungen | 4 |
| Sprachbezogene Lernpräferenzen | 1 |
| Reader-/Importdokumente einschließlich möglicher Löschmarker | 6 |

Das belegt echten historischen Lernstand auf dem Server, nicht nur einen erfolgreichen Abgleich eines leeren Kontos. Es gab keine Vorhermessung; eine konkrete Zunahme seit dem Handyupdate wird deshalb nicht behauptet.

## Umfang der Nachweise

Lokale Verifikation: gesamte Flutter-Suite **1031 bestanden, 9 übersprungen**; CORS- und Runtime-Translation-Prüfung **28 bestanden**. Separat wurden Zwei-Geräte-Sync, Kontentrennung, späte Netzwerkantworten, unveränderliche Reviews, Importlöschungen und Readerpersistenz geprüft.

Live belegt sind Deployment, Vorabanfragen, der initiale Upload vorhandener Handylerndaten, die angemeldete Browseranzeige unter https://linglossa.pages.dev und der bestehende Premiumzugang. Die sichtbaren Stapelfortschritte bestätigen zusätzlich die Nutzung des übernommenen Lernstands in der Browseroberfläche. Nicht zusätzlich ausgelöst wurde eine neue echte Wiederholung mit anschließender Prüfung auf beiden Geräten. Ein 20-Sekunden-Abgleich setzt eine laufende App voraus; angehaltene Handyprozesse und geschlossene Browser synchronisieren nicht weiter.

## Nachtrag: Sprachauswahl

Am selben Tag wurde die Sprachauswahl in Seitenleiste und mobilem Kopfbereich ergänzt und auf dem bestehenden Cloudflare-Pages-Projekt veröffentlicht (143/143 Dateien, Dashboard: „Success!“). Der Browser verwendet für die vier mehrsprachigen Format-2-Pakete jetzt dieselbe Releasevalidierung wie die native App; der strikte Format-1-Parser für das englische Bootstrap-Paket bleibt erhalten.

Nachweise: sechs Web-Widgettests einschließlich persistiertem Sprachwechsel und schmalem Layout bei doppelter Textgröße; fünf Manifestregressionen; native/Manifest-/Sprachwechselregressionen mit 20 bestandenen und zwei opt-in übersprungenen Tests. Analyse ohne Befunde, Releasebuild erfolgreich. Der echte Browser-Harness öffnete alle fünf SQLite-Pakete, las Stapel und Übungsdaten, öffnete Englisch anschließend erneut und bestätigte dauerhafte getrennte Kontospeicherung. Die lokale Oberfläche zeigte nach dem Wechsel portugiesische Stories. Sichtbarer Nachweis: `build/qa/web-all-languages-pass.jpg`.

Die abschließende Hostingprüfung ergänzte eine sechste Manifestregression: Ein SPA-Host kann für fehlende optionale Dateien HTML mit Status 200 liefern. Das englische Format-1-Paket wird deshalb vor einer Releaseabfrage direkt erkannt; der Browser fragt dessen nicht vorhandene Release-Datei nicht mehr an. Dieser Stand wurde erneut erfolgreich veröffentlicht; die englischen Stories einschließlich synchronisierter Lesepositionen wurden anschließend auf Cloudflare angezeigt.

Direkt im angemeldeten Livebrowser wurde danach Englisch → Portugiesisch → Englisch erfolgreich ausgeführt; portugiesische Storytitel und der Status „Lernstand abgeglichen“ waren sichtbar. Die ursprüngliche Auswahl Englisch wurde wiederhergestellt. Nachweise: `build/qa/web-portuguese-live.jpg` und `build/qa/web-language-picker-live.jpg`.
