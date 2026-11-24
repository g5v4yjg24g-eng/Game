# Entwicklungsplan

Jede Phase endet mit einem getesteten Stand und einem Eintrag im [Changelog](CHANGELOG.md).

| Phase | Inhalt | Stand |
|---|---|---|
| 1 Konzeption | Idee, Story, Stil, Gameplay | Entwurf ([KONZEPT.md](KONZEPT.md)), Details offen |
| 2 Grundgerüst | Repo, Godot-Projekt, Struktur, CI, iOS-Export und TestFlight-Weg | **abgeschlossen** (2026-11-24) |
| 3 Prototyp | Testwelt, Ninja, Bewegung, Kamera, Touch-Steuerung | **in Arbeit** (gebaut und simuliert, Gerätetest offen) |
| 4 Kampf | Angriff, Verteidigung, Ausweichen, Gegner-KI, Animationen | offen |
| 5 Spielwelt | Landschaft, Gebäude, NPCs, interaktive Objekte | offen |
| 6 Fortschritt | Missionen, Inventar, Fähigkeiten, Speichern | offen |
| 3c Cartoon-Stil (neu, 2026-11-24) | Umrisse und flächige Schattierung als Shader, Figur nach Referenz umbauen, Welt anpassen; Kosten für Bildrate und Akku am Gerät messen | **Vorbereitung gebaut** (Shader, Schalter, Prüfungen; Branch `claude/cartoon-vorbereitung`); **Figur erste Version nach Referenz gebaut** (2026-11-24), Feinschliff und Test am Gerät offen; danach Animationen perfektionieren. Siehe [STIL_CARTOON.md](STIL_CARTOON.md) |
| 7 Design und Sound | Oberfläche (inkl. Einstellungen mit Kamera-Schieberegler), Effekte, Musik, Geräusche | offen |
| 8 TestFlight | Native Builds, Performance, Fehler, Gerätetests | offen |
| 9 Veröffentlichung | App-Store-Vorbereitung | offen |

## Phase 2 – Abnahme
- [x] Godot-Projekt mit Struktur, Mobile-Renderer, Querformat, Safe-Area-Logik
- [x] `.gitignore`, Git LFS für `assets/`
- [x] Tests und Linter laufen lokal (Godot 4.5.1 headless)
- [x] CI-Workflow auf Linux angelegt
- [ ] CI-Workflow auf GitHub gelaufen und grün (erst nach dem Push prüfbar)
- [x] iOS-Export als Xcode-Projekt unter Linux erzeugt und geprüft (siehe [IOS_BUILD.md](IOS_BUILD.md))
- [x] iOS-Workflow auf macOS gelaufen (Lauf 4, alle Schritte grün, 2026-11-24)
- [x] Build über TestFlight auf dem iPhone 16 Pro Max gestartet (Screenshot des Nutzers, 2026-11-24: Testszene „Kagero“ mit Bildratenanzeige)

## Phase 3 – Abnahme
- [x] Testwelt aus Code (Torii, Weg, Hütte, Plattformen, Rampe, Bäume, Abendlicht, Nebel)
- [x] Platzhalterfigur aus Grundformen, läuft relativ zur Kamera, springt, schleicht
- [x] Kamera hinter der Figur, per Wischen drehbar, weicht Hindernissen aus
- [x] Touch-Steuerung: schwebender Joystick links, Kamera rechts, Knöpfe Sprung und Schleichen, Safe Area
- [x] Logik-Tests (45) und zwei Simulationen (Bewegung, Touch) laufen lokal grün
- [ ] CI auf GitHub grün (nach dem Push prüfen)
- [x] Am iPhone getestet (Nutzer 2026-11-24, Build 5): „sieht alles gut aus“; Kamera darf etwas schneller sein (umgesetzt: 0,2 statt 0,16)
- [x] Messwerte am Gerät (Nutzer 2026-11-24, Build 5, iPhone 16 Pro Max): konstant 60 fps, 130 Draw Calls, 206 Objekte. Safe Area: „sieht alles gut aus“.
- [ ] Spielgefühl nach Rückmeldung nachjustieren (Werte in `core/controls_config.gd`)

Nachtrag Phase 3b (Branch `claude/ninja-modell`):
- [x] Eigenes Ninja-Modell (Blender-Skript) mit Skelett, Schal-Kette und sieben Animationen: Stehen, Laufen, Schleichen, geduckt Stehen, Sprung, Fall, Landung
- [x] Animationsauswahl als reine Logik mit Tests (`gameplay/animation_logic.gd`), Anbindung an die Figur, Simulation prüft idle/run/sneak und jump → fall → land
- [ ] Am iPhone gesehen und bewertet (Aussehen, Animationen, Bildrate mit Modell) – nur der Nutzer kann das prüfen

- [x] Laufanimation überarbeitet (2026-11-24, siehe Changelog); am Gerät zu prüfen

Bewusst noch nicht enthalten: Gehen (nur Laufen und Schleichen), Lock-on-Kamera, Kampf (Phase 4), Gesichts- und Stoffdetails, Texturen. Die Figur ist ein stilisiertes Modell aus glatten Grundformen, keine Charakterkunst in Studioqualität.

## Messwerte
| Datum | Stand | Gerät | fps | Draw Calls | Objekte |
|---|---|---|---|---|---|
| 2026-11-24 | Prototyp, Build 5 (60-fps-Deckel) | iPhone 16 Pro Max, iOS 27.2.1 | konstant 60 | 130 | 206 |

| 2026-11-24 | Prototyp mit Ninja-Modell, Build 6 (60-fps-Deckel), 3 Bildschirmaufnahmen des Nutzers | iPhone 16 Pro Max, iOS 27.2.1 | 59 bis 61 | 35 bis 149 (je nach Blickrichtung) | 109 bis 225 |

**Auswertung der Aufnahmen (2026-11-24):** Bildabstände konstant 16,7 ms, in der längsten Aufnahme (5,6 s) ändert sich jedes Bild, die Kamerabewegung ist gleichmäßig (Abweichung von der glatten Bewegung unter 0,3 Pixel). Stillstände von 250 bis 400 ms in zwei Aufnahmen fallen mit iOS-Einblendungen zusammen (Fokus-Schalter am Anfang, Aufnahme-Ende), nicht mit dem Spiel. Ruckeln lässt sich aus den Aufnahmen nicht belegen. Nicht erfassbar: das Gefühl auf dem 120-Hz-Display (Aufnahmen sind auf 60 fps begrenzt), Eingabeverzögerung und die Wirkung der Animationen. Hypothese: Der Deckel von 60 fps wirkt neben dem 120-Hz-System weniger flüssig; Test mit 120 fps.

Hinweis: Wegen des 60-fps-Deckels sagt „konstant 60“ nur, dass das Ziel erreicht ist, nicht wie viel Reserve bleibt. Für die Reserve und für ältere iPhones braucht es später einen Test ohne Deckel oder mit GPU-Zeit (Debug-Schalter, geplant). Die Draw Calls (130) weichen von den 158 im Software-Screenshot am PC ab (anderer Renderer, anderer Blickwinkel); die Ursache ist nicht untersucht. Die Bäume lassen sich später mit MultiMesh bündeln.

## Qualität und Performance (ab Phase 3 messen)
Ziel 60 fps (Sparmodus 30), Frame-Zeit-Overlay im Debug-Build, Draw-Call- und Speicherbudget, ASTC-Texturen, LODs, Streaming der Weltabschnitte. Messen kann nur der Nutzer am Gerät; Claude wertet die Rückmeldung aus.
