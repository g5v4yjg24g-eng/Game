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

## Arbeitsweise
- Vor dem Abschluss: `gdformat --check`, `gdlint`, Import und Tests (siehe README). Ergebnisse ehrlich berichten.
- Branches: `main` stabil, Arbeit auf `claude/…`- oder `feature/…`-Branches. Auf `main` nur mit ausdrücklicher Anweisung pushen. Keine Pull Requests ohne Aufforderung.
- Wichtige Änderungen in `docs/CHANGELOG.md` eintragen, Abweichungen vom Plan im selben Commit in den Dokumenten nachziehen.
- Große Binärdateien (Modelle, Texturen, Audio) unter `assets/` laufen über Git LFS.

## Befehle
```
godot --headless --path . --import
godot --headless --path . --script res://tests/run_tests.gd
gdformat --check core ui tests gameplay world data
gdlint core ui tests gameplay world data
```
