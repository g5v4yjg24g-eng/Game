# Entwicklungsplan

Jede Phase endet mit einem getesteten Stand und einem Eintrag im [Changelog](CHANGELOG.md).

| Phase | Inhalt | Stand |
|---|---|---|
| 1 Konzeption | Idee, Story, Stil, Gameplay | Entwurf ([KONZEPT.md](KONZEPT.md)), Details offen |
| 2 Grundgerüst | Repo, Godot-Projekt, Struktur, CI, iOS-Export und TestFlight-Weg | **in Arbeit** (siehe unten) |
| 3 Prototyp | Testwelt, Ninja, Bewegung, Kamera, Touch-Steuerung | offen |
| 4 Kampf | Angriff, Verteidigung, Ausweichen, Gegner-KI, Animationen | offen |
| 5 Spielwelt | Landschaft, Gebäude, NPCs, interaktive Objekte | offen |
| 6 Fortschritt | Missionen, Inventar, Fähigkeiten, Speichern | offen |
| 7 Design und Sound | Oberfläche, Effekte, Musik, Geräusche | offen |
| 8 TestFlight | Native Builds, Performance, Fehler, Gerätetests | offen |
| 9 Veröffentlichung | App-Store-Vorbereitung | offen |

## Phase 2 – Abnahme
- [x] Godot-Projekt mit Struktur, Mobile-Renderer, Querformat, Safe-Area-Logik
- [x] `.gitignore`, Git LFS für `assets/`
- [x] Tests und Linter laufen lokal (Godot 4.5.1 headless)
- [x] CI-Workflow auf Linux angelegt
- [ ] CI-Workflow auf GitHub gelaufen und grün (erst nach dem Push prüfbar)
- [x] iOS-Export als Xcode-Projekt unter Linux erzeugt und geprüft (siehe [IOS_BUILD.md](IOS_BUILD.md))
- [ ] iOS-Workflow auf macOS gelaufen, Build in TestFlight (nur der Nutzer kann ihn auslösen)

## Qualität und Performance (ab Phase 3 messen)
Ziel 60 fps (Sparmodus 30), Frame-Zeit-Overlay im Debug-Build, Draw-Call- und Speicherbudget, ASTC-Texturen, LODs, Streaming der Weltabschnitte. Messen kann nur der Nutzer am Gerät; Claude wertet die Rückmeldung aus.
