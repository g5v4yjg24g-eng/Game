# iOS-Build und TestFlight

## Ablauf
1. **Godot-Export** (`--export-release "iOS"`, `application/export_project_only=true`) erzeugt ein Xcode-Projekt in `build/ios/`. Das geht auch unter Linux, braucht aber die Export-Templates der gleichen Godot-Version.
2. **Archiv** mit `xcodebuild archive` (unsigniert) – braucht **macOS und Xcode**.
3. **Signieren und Hochladen** mit `xcodebuild -exportArchive -allowProvisioningUpdates` und dem App-Store-Connect-API-Schlüssel (`ios/ExportOptions.plist`, `destination: upload`). Zertifikate und Provisioning Profile werden dabei automatisch erzeugt; es muss nichts von Hand angelegt werden.

Der Workflow `.github/workflows/ios.yml` macht das auf einem GitHub-macOS-Runner. Er läuft nur von Hand (Actions → „iPhone-Build (TestFlight)“ → Run workflow). Die Option „Zu TestFlight hochladen“ kann zum reinen Bauen abgeschaltet werden.

## Wer braucht was
| Schritt | Braucht |
|---|---|
| Spielcode, Tests, Linter | nur Linux, keine Apple-Daten |
| Xcode-Projekt aus Godot | Godot 4.5.1 + Export-Templates, `TEAM_ID` im Preset |
| Archiv, Signieren, Upload | macOS-Runner, Xcode, die vier Secrets |

## Einmalig eingerichtet (vom Nutzer)
- Bundle-ID `com.fangpunkt.game`
- App-Eintrag in App Store Connect
- Repository-Secrets `APPLE_TEAM_ID`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY`

Zugangsdaten stehen nie im Repo. Im Preset steht nur der Platzhalter `TEAM_ID`; der Workflow setzt die echte Team-ID zur Laufzeit ein.

## Geprüft und ungeprüft
- **Geprüft (2026-11-24, Linux, Godot 4.5.1):** Der Export erzeugt `build/ios/Kagero.xcodeproj` mit Bundle-ID `com.fangpunkt.game`, Team-ID, Mindest-iOS 15.0, nur iPhone, Querformat, App-Icon und gemeinsamem Schema `Kagero`.
- **Läufe auf GitHub (2026-11-24, `macos-15-intel`):**
  - Lauf 1 und 2 (alter Branch): Export und Archiv liefen, Signieren und Upload scheiterten mit `Auth error` (Code 1235, `No Accounts with App Store Connect Access`).
  - Lauf 3 (`main`): Der Prüfschritt zeigte, dass die Form der Werte stimmte, Apple die Zugangsdaten aber ablehnte (HTTP 401). Key-ID, Issuer-ID und `.p8` gehörten nicht zusammen. Der Nutzer hat einen neuen Teamschlüssel erstellt und alle drei Secrets ersetzt.
  - **Lauf 4 (`main`, Commit `b80ac6c`): alle Schritte grün**, auch „Für den App Store signieren und zu TestFlight hochladen“ (Dauer gesamt etwa 5 Minuten).
- **Zugangsdaten-Prüfung:** Der Schritt „Zugangsdaten bei Apple prüfen“ (`ios/check-asc.mjs`) läuft jetzt vor dem Godot-Export. Er prüft die Form der Werte, liest die `.p8`, fragt die App-Store-Connect-API nach der Bundle-ID und nennt die Ursache, ohne Schlüssel auszugeben.
- **Geprüft am Gerät (2026-11-24):** Der Build läuft über TestFlight auf dem iPhone 16 Pro Max (iOS 27.2.1). Screenshot des Nutzers: Querformat, Testszene mit „Kagero“ und Bildratenanzeige (81 fps in einer leeren Szene, Einzelwert ohne Messreihe). Safe Area und Dynamic Island sind im Screenshot nicht kritisch, das Layout ist mittig.
- **[O] Noch offen:** Leistungsmessung mit echten Inhalten (ab Phase 3), Verhalten auf älteren iPhones.
- **Testgerät:** iPhone 16 Pro Max mit iOS 27.2.1. **[O] Mindest-iOS 15.0** ist vorläufig.

## Release-Checkliste (später)
Datenschutzangaben, Altersfreigabe, Screenshots, Beschreibung, Exportcompliance (`ITSAppUsesNonExemptEncryption` steht auf `false`) – siehe Phase 9.
