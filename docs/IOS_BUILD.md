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
- **[O] Ungeprüft:** `xcodebuild archive` und `-exportArchive` auf dem macOS-Runner, der TestFlight-Upload, der Start des Builds auf dem iPhone. Mögliche Stolpersteine: Name des Xcode-Schemas, Signieren ohne Ad-hoc-Berechtigungen, Gültigkeit der Export-Templates auf dem Runner. Der erste Lauf zeigt das; Fehler kommen in dieses Dokument.
- **Testgerät:** iPhone 16 Pro Max mit iOS 27.2.1. **[O] Mindest-iOS 15.0** ist vorläufig.
- **[O] Xcode auf dem Runner:** Apple verlangt für TestFlight-Uploads eine Mindestversion des iOS-SDK. Ob die auf `macos-15-intel` oder `macos-15` installierte Xcode-Version dafür reicht, zeigt erst der erste Lauf. Der Workflow wählt die neueste installierte Version.

## Release-Checkliste (später)
Datenschutzangaben, Altersfreigabe, Screenshots, Beschreibung, Exportcompliance (`ITSAppUsesNonExemptEncryption` steht auf `false`) – siehe Phase 9.
