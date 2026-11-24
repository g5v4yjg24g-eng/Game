# Changelog

## Unveröffentlicht – Ninja-Lauf (Branch `claude/ninja-lauf`)
- Wunsch Nutzer (Vorlage als Bild): beim Rennen Oberkörper stark nach vorn geneigt, beide Arme nach hinten gestreckt. Umgesetzt in `run_pose` (Wirbelsäule −30°, Brust −16°, Kopf +36° gegen die Neigung, Oberarme −78°, Unterarme fast gestreckt, nur leichter Armschwung). Beinzyklus unverändert.
- Gehen (Schleichen): Arme hängen locker und schwingen gegenläufig zu den Beinen, Ellbogen nur leicht gebeugt (vorher dauerhaft 84° angewinkelt). Wirkung am Gerät **[O]**.
- Aussehen am Gerät **[O]**; ob die Neigung noch stärker oder schwächer sein soll, entscheidet der Nutzer.

## Unveröffentlicht – Einstellungsmenü
- Neues Menü (Knopf „Menü“ oben rechts, ersetzt den Stil-Testknopf): Kamera-Empfindlichkeit per Schieberegler (50–200 %), Bildrate 30/60/120, Cartoon-Stil. Das Spiel pausiert, solange das Menü offen ist.
- Einstellungen liegen im Autoload `Settings` (`core/settings.gd`, Prüfung und Grenzen rein in `core/settings_data.gd`, Datei `user://settings.cfg`); Tests in `tests/test_settings_data.gd` und `sim_touch`.
- Wirkung am Gerät (Regler, Bildrate, Menü-Bedienung) ist **[O]**, bis der Nutzer es prüft.

## 2026-11-24 – Laufzyklus nachgebessert (Branch `claude/lauf-schritte`)
- Anlass: Nutzer meldet nach Build 8, das Laufen sehe aus wie Rückwärtslaufen; sonst passe alles (Figur, Kampfhaltung, Kamera-Schwenk).
- Ursache (aus dem Video und einer Laufvorschau mit Bodenmarken): zu kleine, zu schnelle Schritte bei zu wenig Fußhöhe, der Körper glitt über die Füße.
- Neuer Zyklus: 0,40 s, Fußweg 0,50 m, Bodenkontakt 0,12 s, Fußhöhe 8 cm, 20 % Gleiten erlaubt, Kniebeugung bis 93 Grad. Neue Vorschau im Blender-Skript: Lauf mit echtem Tempo an Bodenmarken vorbei.
- **Schleichen** auf denselben Schrittgenerator umgestellt: vorher bewegte sich der Standfuß nur mit 0,36 m/s bei 1,9 m/s Körpertempo (Gleiten); jetzt 1,61 m/s bei Soll 1,61, tiefe Hocke (Kniebeugung 29 bis 80 Grad), Zyklus 0,53 s.
- Sprung und Fallen: Arme nach oben und außen statt vor dem Gesicht.
- Neue Tests: Schleichtempo und Zyklusdauer von `sneak` im Blender-Skript gleich Spielwert und Modell.
- Nicht belegt: ob Lauf und Schleichen am iPhone natürlich aussehen.


## 2026-11-24 – Kampfhaltung und Kamera-Schwenk im Stillstand (Branch `claude/cartoon-vorbereitung`)
- Nutzer: Figur gefällt; Ruhepose soll die **Kampfhaltung** sein; nach 10 bis 15 Sekunden Stillstand soll die Kamera **um die Figur schwenken** wie in bekannten Spielen.
- Neue `idle`-Animation im Blender-Skript: breiter, tiefer Stand (Beine gespreizt, Knie gebeugt), Fäuste vor Brust und Kinn, Ellbogen nach außen, leichtes Atmen und Schwanken, Stirnband-Enden wehen leicht.
- Kamera-Schwenk: Regel als reine Logik (`gameplay/idle_camera.gd`, Wartezeit 12 s, 12 Grad/s, sanftes Anfahren, schnelles Abbrechen), eingebunden in `CameraRig`; `Player.is_at_rest()`; neues Signal `EventBus.activity` für jede Berührung.
- Tests: 98 Logik-Tests (neu: Schwenk-Regel), Simulation prüft, dass die Kamera vor der Wartezeit stehen bleibt, danach schwenkt und bei Eingabe stoppt.
- Nicht belegt: Wirkung und Gefühl am iPhone.


## 2026-11-24 – Figur nach Referenz umgebaut (Branch `claude/cartoon-vorbereitung`)
- Anlass: Nutzer meldet, der Lauf sehe besser aus, aber die Knie gingen zu weit hoch, und schlägt vor, **zuerst die Figur wie angefordert neu zu bauen und dann die Animationen zu perfektionieren**.
- Neue Figur im Blender-Skript (Chibi, 1,45 m): großer Kopf, Kapuze mit Maske, große Augen mit zornigen Brauen, rotes Stirnband mit Spitzen und flatternden Enden, rote Schulterpolster, Gürtelknoten, Wickelkragen, rote Knieschützer, Fäuste, Stiefel, Schwert. Skelett weiter 21 Knochen (Schal-Kette heißt jetzt `band_1` bis `band_3`).
- Umriss: dünne Teile bekommen über die Vertexfarbe einen schmaleren Umriss (Stirnband-Enden, Schwert).
- Laufzyklus an die kürzeren Beine angepasst: Entwurfstempo 5,2 m/s, Zyklus 0,53 s, Kontakt 0,07 s, **Kniebeugung bis 73 Grad** (vorher 109), Standfuß gemessen 5,20 m/s (kein Rutschen), nichts gekürzt.
- Spielwerte der Größe angepasst (Vorschlag, zurückstellbar): Lauftempo 5,2, Schleichen 1,9, Kamera 4,0 m und Zielhöhe 1,15 m, Kollisionsform 1,45 m. Sprungstärke unverändert.
- Cartoon-Schattierung etwas gedämpft (Lichtstufe 0,7, Mittelstufe 0,38), weil die anthrazitfarbene Kleidung im Licht beige-grau wirkte.
- Tests von festen Tempo- und Bildzahlen gelöst (Entwurfstempo und Zyklusdauer werden aus dem Blender-Skript gelesen); 89 Tests, beide Simulationen und die Render-Prüfung im Mobile-Renderer grün.
- Nicht belegt: Aussehen am iPhone. Animationen sind **noch nicht perfektioniert** (nach Freigabe der Figur).


## 2026-11-24 – Laufanimation neu (Branch `claude/cartoon-vorbereitung`)
- Anlass: Nutzer meldet nach Build 6, dass die Laufanimation komisch aussieht. Befund aus den Aufnahmen: Schal stand fast senkrecht, Füße rutschten (Zyklus 0,6 s passte nicht zu 6,5 m/s), Gang wie ein Ausfallschritt ohne Flugphase.
- Neuer Laufzyklus im Blender-Skript: Fußführung per Zwei-Gelenk-Berechnung. Der Standfuß wandert exakt mit der Laufgeschwindigkeit nach hinten (gemessen 6,50 m/s bei Soll 6,5, also kein Rutschen), Zyklus 0,57 s, Bodenkontakt 0,11 s je Fuß mit Flugphase, Hüfte federt 3,5 bis 11 cm ein, Knie bis 109 Grad, Schal weht fast waagerecht, Arme gebeugt im Gegentakt, leichte Vorlage.
- Neue Prüfungen: Entwurfstempo im Blender-Skript muss `RUN_SPEED` im Spiel entsprechen; alle sieben Animationen und die Länge des Laufzyklus werden aus dem importierten Modell geprüft (88 Tests insgesamt).
- Nicht belegt: ob der Lauf am iPhone besser aussieht (nur der Nutzer kann das prüfen).


## 2026-11-24 – Vorbereitung Cartoon-Stil (Branch `claude/cartoon-vorbereitung`)
- Shader für Cartoon-Schattierung (drei Stufen) und Umriss (Inverted Hull), beide für den Mobile-Renderer; Standard **aus**.
- `CartoonStyle` schaltet Figur und Welt um; Figur mit eigenem Umriss-Mesh im Modell, statische Teile mit gemittelten Normalen (`SmoothNormals`, mit Tests).
- Testknopf „Stil“ oben rechts und Stilanzeige in der Messanzeige, damit der Nutzer am iPhone vergleichen kann.
- Prüfungen: 75 Logik-Tests, Simulation für Ein- und Ausschalten, neuer CI-Job `mobile-renderer` (echter Mobile-Renderer per Software-Vulkan, meldet Shader-Fehler).
- Stil-Leitfaden `docs/STIL_CARTOON.md` mit Regeln, Messungen (Draw Calls im Cartoon-Modus etwa 20 bis 45 % höher) und offenen Punkten.
- Bildratendeckel von 60 auf 120 fps angehoben (Test, weil der Nutzer „noch nicht so flüssig“ meldet; das Display kann 120 Hz, die App erlaubt es im Export).
- Noch nicht am iPhone gesehen; Figur und Welt sind noch nicht im Referenzstil umgebaut.

## 2026-11-24 – Ninja-Modell (Branch `claude/ninja-modell`)
- Neue Spielfigur statt Platzhalter: eigenes Modell aus `tools/blender/build_ninja.py` (Skelett mit 21 Knochen, Schal-Kette, etwa 7 000 Dreiecke).
- Sieben Animationen: `idle`, `run`, `sneak`, `sneak_idle`, `jump`, `fall`, `land`; Tempo der Schritte passt sich der Geschwindigkeit an, weiche Übergänge.
- `gameplay/animation_logic.gd` wählt die Animation (19 neue Tests, insgesamt 64); die Simulation prüft die Zuordnung und die Folge jump → fall → land.
- Die `.glb` liegt in Git LFS; Lizenzvermerk und Anleitung zum Neuerzeugen unter `assets/characters/ninja` und `tools/blender`.
- Noch nicht am iPhone gesehen.
- Zielrichtung für die Figur festgehalten (Referenzbild des Nutzers: Chibi-Cartoon-Ninja mit rotem Stirnband); Umbau nach dem Test dieses Zwischenstands.
- Entscheidung: Cartoon-Stil für das ganze Spiel, Story bleibt ernst, fiktive Figuren kommen später (docs/ENTSCHEIDUNGEN.md, docs/KONZEPT.md).

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
