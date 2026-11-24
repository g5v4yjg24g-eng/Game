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
- **Erster Lauf auf GitHub (2026-11-24, Run 1, `macos-15-intel`, Branch `claude/phase-2-grundgeruest`):**
  - Erfolgreich: Secrets vorhanden, Godot und Export-Templates geladen, Import, Export zum Xcode-Projekt, Xcode gewählt, **Archiv gebaut** (`ARCHIVE SUCCEEDED`).
  - **Fehlgeschlagen:** „Für den App Store signieren und zu TestFlight hochladen“ mit `Auth error` (CDWebService Code 1235) und `No Accounts with App Store Connect Access`. Apple hat die API-Zugangsdaten abgelehnt. Das Spiel selbst ist nicht die Ursache.
  - Mögliche Ursachen (Prüfung siehe unten): Key-ID, Issuer-ID und `.p8` gehören nicht zusammen, ein Wert ist abgeschnitten oder hat Leerzeichen, es ist ein individueller statt ein Teamschlüssel, oder der Schlüssel hat zu wenig Rechte oder wurde widerrufen.
- **Zugangsdaten-Prüfung:** Der Schritt „Zugangsdaten bei Apple prüfen“ (`ios/check-asc.mjs`) läuft jetzt vor dem Godot-Export. Er prüft die Form der Werte, liest die `.p8`, fragt die App-Store-Connect-API nach der Bundle-ID und nennt die Ursache, ohne Schlüssel auszugeben.
- **[O] Noch ungeprüft:** der TestFlight-Upload selbst, der Start des Builds auf dem iPhone und ob die Xcode-Version des Runners für TestFlight reicht (das Archiv wurde damit gebaut, Apples Mindest-SDK-Prüfung kommt erst beim Upload).
- **Testgerät:** iPhone 16 Pro Max mit iOS 27.2.1. **[O] Mindest-iOS 15.0** ist vorläufig.

## Release-Checkliste (später)
Datenschutzangaben, Altersfreigabe, Screenshots, Beschreibung, Exportcompliance (`ITSAppUsesNonExemptEncryption` steht auf `false`) – siehe Phase 9.
