# Kagero (Arbeitstitel)

Atmosphärisches Ninja-Action-Adventure für das iPhone, gebaut mit **Godot 4** (GDScript) als native iOS-App.
Kein Web-Spiel, keine PWA.

**Stand:** Phase 3 – spielbarer Prototyp (Testgelände, Platzhalterfigur, Touch-Steuerung), noch nicht am iPhone geprüft. Siehe [docs/ENTWICKLUNGSPLAN.md](docs/ENTWICKLUNGSPLAN.md).

## Dokumente
- [Spielkonzept](docs/KONZEPT.md)
- [Entscheidungen](docs/ENTSCHEIDUNGEN.md) (was entschieden und was noch offen ist)
- [Entwicklungsplan](docs/ENTWICKLUNGSPLAN.md)
- [iOS-Build und TestFlight](docs/IOS_BUILD.md)
- [Changelog](docs/CHANGELOG.md)

## Lokal arbeiten
1. Godot **4.5.1** (Standardversion, nicht .NET) installieren.
2. Projekt öffnen oder `godot --path .` ausführen.
3. Prüfungen (wie in der CI):
   ```
   pip install "gdtoolkit==4.*"
   gdformat --check core ui tests gameplay world data && gdlint core ui tests gameplay world data
   godot --headless --path . --import
   godot --headless --path . --script res://tests/run_tests.gd
   godot --headless --path . res://tests/sim_prototype.tscn   # Bewegung und Kamera
   godot --headless --path . res://tests/sim_touch.tscn       # Touch-Oberfläche
   ```
4. Git LFS einrichten (`git lfs install`), bevor Assets unter `assets/` hinzukommen.

## Struktur
| Ordner | Inhalt |
|---|---|
| `core/` | Ereignisbus, später Speichern und Einstellungen (ohne Oberfläche) |
| `gameplay/` | Spieler, Gegner-KI, Kampf, Schleichen |
| `world/` | Welt, Beleuchtung, Wetter, Interaktion |
| `ui/` | HUD, Menüs, Safe-Area-Logik |
| `data/` | Waffen, Gegner, Missionen als Ressourcen |
| `assets/` | Modelle, Texturen, Audio (Git LFS), je Paket mit Quelle und Lizenz |
| `locale/` | Übersetzungen (Deutsch zuerst) |
| `scenes/` | Szenen |
| `tests/` | Tests der Spiellogik |
| `ios/` | Icon und Export-Einstellungen für iOS |

## Steuerung (Touch)
- **Links** irgendwo aufsetzen und ziehen: schwebender Joystick, die Figur läuft relativ zur Kamera.
- **Rechte Hälfte** wischen: Kamera drehen und neigen.
- **Knöpfe rechts unten:** Sprung, Schleichen (Umschalter).
- Werte (Empfindlichkeit, Tempo, Totzone, Knopfgrößen) stehen gesammelt in `core/controls_config.gd`.
- Am Mac/PC lässt sich mit der Maus testen (`emulate_touch_from_mouse`).

## Regeln
Siehe [CLAUDE.md](CLAUDE.md).
