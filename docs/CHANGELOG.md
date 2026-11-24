# Changelog

## 2026-11-24 – Ninja-Modell (Branch `claude/ninja-modell`)
- Neue Spielfigur statt Platzhalter: eigenes Modell aus `tools/blender/build_ninja.py` (Skelett mit 21 Knochen, Schal-Kette, etwa 7 000 Dreiecke).
- Sieben Animationen: `idle`, `run`, `sneak`, `sneak_idle`, `jump`, `fall`, `land`; Tempo der Schritte passt sich der Geschwindigkeit an, weiche Übergänge.
- `gameplay/animation_logic.gd` wählt die Animation (19 neue Tests, insgesamt 64); die Simulation prüft die Zuordnung und die Folge jump → fall → land.
- Die `.glb` liegt in Git LFS; Lizenzvermerk und Anleitung zum Neuerzeugen unter `assets/characters/ninja` und `tools/blender`.
- Noch nicht am iPhone gesehen.
- Zielrichtung für die Figur festgehalten (Referenzbild des Nutzers: Chibi-Cartoon-Ninja mit rotem Stirnband); Umbau später (docs/ENTSCHEIDUNGEN.md).

## 2026-11-24 – Phase 3 (Prototyp), Branch `claude/phase-3-prototyp`
- Spielbarer Prototyp: Testwelt aus Code, Platzhalterfigur, Kamera mit Hinderniserkennung, Bewegung relativ zur Kamera, Sprung, Schleichen.
- Touch-Steuerung: schwebender Joystick (links), Kamera per Wischen (rechts), Knöpfe Sprung und Schleichen, Safe Area, Mehrfingerbedienung, Zurücksetzen beim Wechsel in den Hintergrund.
- Messanzeige oben links (fps, Bildzeit, Draw Calls, Objekte) für Tests am Gerät.
- Bildrate auf 60 fps begrenzt, Physik-Interpolation für ruhige Bewegung bei hoher Bildwiederholrate.
- 45 Logik-Tests und zwei Simulationen (Bewegung, Touch) lokal grün; beide Simulationen laufen in der CI.
- Erste Übersetzungsdatei `locale/de.po` für die Knopfbeschriftungen.
- Messwerte am iPhone 16 Pro Max (Build 5): konstant 60 fps, 130 Draw Calls, 206 Objekte.
- Am iPhone getestet (Build 5): Steuerung in Ordnung, Kamera auf Wunsch etwas schneller (0,2 Grad pro Pixel). Die Empfindlichkeit steckt jetzt im Kamera-Rig, damit später ein Schieberegler in den Einstellungen sie setzen kann.

## 2026-11-24 – Erster erfolgreicher iPhone-Build
- Lauf 4 des Workflows „iPhone-Build (TestFlight)“ auf `main`: alle Schritte grün (Zugangsdaten-Prüfung, Godot-Export, Archiv, Signieren und Upload).
- Ursache der früheren Fehler: nicht zusammenpassende App-Store-Connect-Zugangsdaten (Secrets neu gesetzt).
- Der Build wurde über TestFlight auf dem iPhone 16 Pro Max installiert und gestartet (Screenshot des Nutzers). **Phase 2 abgeschlossen.**

## 2026-11-24 – Zugangsdaten-Prüfung für den iOS-Build
- Erster iPhone-Build: Export und Archiv liefen, der Upload scheiterte an der Anmeldung bei App Store Connect (Auth error 1235).
- Neuer Schritt „Zugangsdaten bei Apple prüfen“ (`ios/check-asc.mjs`) vor dem Godot-Export, damit die Ursache früh und genau gemeldet wird.
- `docs/IOS_BUILD.md` mit den Ergebnissen des ersten Laufs aktualisiert.

## 2026-11-24 – Phase 2 (Grundgerüst), Branch `claude/phase-2-grundgeruest`
- Godot-4.5.1-Projekt „Kagero“ (Arbeitstitel): Mobile-Renderer, Querformat, Ordnerstruktur, Ereignisbus, Safe-Area-Logik mit Tests, Testszene mit Bildrate.
- `.gitignore` für Godot, Git LFS für große Dateien unter `assets/`.
- Prüf-Workflow (Linux): Format, Stil, Import, Tests, Start der Hauptszene.
- iOS-Workflow (macOS) für Build und TestFlight, noch nicht gelaufen.
- Export-Preset für iOS (`com.fangpunkt.game`); der Export zum Xcode-Projekt wurde unter Linux geprüft.
- Dokumente: Konzept, Entscheidungen, Entwicklungsplan, iOS-Build.
- Testgerät festgehalten: iPhone 16 Pro Max, iOS 27.2.1.
