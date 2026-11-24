# CLAUDE.md – Projektregeln (Spiel „Kagero“, Arbeitstitel)

Native iOS-Spiel mit **Godot 4.5.1** und **GDScript**. Verbindlich: **kein** WebApp-, PWA- oder HTML-Spiel.
Dieses Repo ist getrennt von `Angelkarte-Deutschland` (Fangpunkt) und `fangpunkt_webside`.
**In diesen beiden Repos wird für das Spiel nichts geändert.**

## Zusammenarbeit
- Keine grundlegenden Designentscheidungen ohne Zustimmung des Nutzers. Optionen mit Vor- und Nachteilen nennen und eine Empfehlung geben. Entscheidungen in `docs/ENTSCHEIDUNGEN.md` festhalten.
- Niemals behaupten, ein Build oder Test sei erfolgreich, wenn er nicht tatsächlich gelaufen ist. Ungeprüftes als **[O]** (offen) kennzeichnen.
- Neue Funktionen schrittweise; bestehende Mechaniken nach größeren Änderungen erneut testen.
- Keine unnötigen Abhängigkeiten. Externe Assets nur mit geprüfter kommerzieller Nutzungslizenz (Quelle und Lizenz je Paket unter `assets/<paket>/LICENSE.md`).
- Zugangsdaten, Zertifikate, Schlüssel nie ins Repo (nur GitHub-Secrets).

## Sprache
Spieltexte, Doku und Commit-Nachrichten **Deutsch**, Code-Bezeichner Englisch. Spieltexte nie fest im Code, sondern über `tr()` und `locale/` (Deutsch zuerst, weitere Sprachen vorbereitet).

## Architektur
- Spiellogik (`core/`, `gameplay/`), Oberfläche (`ui/`) und Daten (`data/`) getrennt; Kommunikation über Signale (`EventBus`).
- Reine Logik ohne Display- und Node-Zugriff halten, damit sie in `tests/` prüfbar ist.
- Renderer **Mobile**. Nur Godot-Funktionen, die mit dem iOS-Export funktionieren. Safe Areas und Dynamic Island über `ui/safe_area.gd`.
- Mobile-Budget beachten: stabile Bildrate, wenig Draw Calls, kleine Texturen (ASTC), Akku schonen.

## Testen ohne Gerät
- Reine Logik: `tests/test_*.gd` (läuft mit `--script`, kennt **keine Autoloads**, also nie `EventBus` oder Szenen laden).
- Zusammenspiel: Simulationen als Szene (`tests/sim_*.tscn`), mit Autoloads. Headless hat das Fenster die Größe 0; Touch-Ereignisse deshalb direkt an `TouchControls._input` schicken, nicht über `Input.parse_input_event`.
- **Echter Mobile-Renderer ohne GPU:** `apt-get install xvfb mesa-vulkan-drivers vulkan-tools`, dann `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.json xvfb-run -a godot --path . --rendering-method mobile --rendering-driver vulkan <Szene>` (Vulkan über llvmpipe). Shader-Fehler erscheinen als `SHADER ERROR` und lassen das Skript trotzdem durchlaufen, die Ausgabe muss ausgewertet werden (CI-Job `mobile-renderer`). **Draw Calls und Objekte** sind ein brauchbarer Maßstab, aber etwa 10 % zu hoch (Build 5: 145/221 hier gegen 130/206 am iPhone); **Bildraten und Akku sagt es nicht**.
- Screenshots: bevorzugt im Mobile-Renderer (siehe oben), nur im Notfall mit dem Compatibility-Renderer. Farben wirken im Compatibility-Renderer anders.
- Spielgefühl, Bildrate und Safe Area prüft nur der Nutzer am Gerät.

## Arbeitsweise
- Vor dem Abschluss: `gdformat --check`, `gdlint`, Import und Tests (siehe README). Ergebnisse ehrlich berichten.
- Branches: `main` stabil, Arbeit auf `claude/…`- oder `feature/…`-Branches. Auf `main` nur mit ausdrücklicher Anweisung pushen. Keine Pull Requests ohne Aufforderung.
- Wichtige Änderungen in `docs/CHANGELOG.md` eintragen, Abweichungen vom Plan im selben Commit in den Dokumenten nachziehen.
- Große Binärdateien (Modelle, Texturen, Audio) unter `assets/` laufen über Git LFS.
- Die Spielfigur (`assets/characters/ninja/ninja.glb`) nie von Hand ändern, sondern `tools/blender/build_ninja.py` anpassen und neu erzeugen (Anleitung dort). Neue Animationen in Skript und `gameplay/animation_logic.gd` eintragen.

## Befehle
```
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd
godot --headless --path . res://tests/sim_prototype.tscn
godot --headless --path . res://tests/sim_touch.tscn
gdformat --check core ui tests gameplay world data
gdlint core ui tests gameplay world data
```
