# Entscheidungen

**Entschieden** = ausdrücklich vom Nutzer. **Vorläufig** = Vorschlag, vom Nutzer am 2026-11-24 mit „Passt erstmal alles“ angenommen, später änderbar. **Offen** = noch zu klären.

| Thema | Stand | Inhalt |
|---|---|---|
| Engine, Sprache, Plattform | Entschieden | Godot 4 (GDScript), native iOS-App, kein Web/PWA |
| Godot-Version | Entschieden (Claude, technisch) | 4.5.1 stable; Update später nach Prüfung |
| Bundle-ID | Entschieden | `com.fangpunkt.game` |
| Repository | Entschieden | Alles unter `g5v4yjg24g-eng/Game`; Angelkarte-Deutschland und fangpunkt_webside bleiben unberührt |
| Story | Entschieden | Auftragsmörder: erst blinder Gehorsam, dann wachsendes Hinterfragen des Auftraggebers (2026-11-24) |
| Zielrichtung Figur | Entschieden als Richtung (Nutzer 2026-11-24, Referenzbild), Umbau **nach dem Test des Zwischenstands** | Siehe Abschnitt „Zielrichtung Figur“ unten. Die jetzige Figur ist eine Zwischenstufe. |
| Spielfigur | Vorläufig (Vorschlag von Claude, Nutzer prüft im Test) | Eigenes stilisiertes Modell (etwa 7 000 Dreiecke, dunkelblauer Stoff, roter Schal und Gürtel, Schwert auf dem Rücken), per Skript in Blender erzeugt, ersetzt die Platzhalterfigur. Nur Version 1: Proportionen, Farben und Details sind änderbar. |
| Stil-Testknopf „Stil“ | Vorläufig (Claude, nur für die Prüfphase) | Kleiner Knopf oben rechts schaltet den Cartoon-Stil an und aus, damit der Nutzer am Gerät vergleichen kann. Standard aus; verschwindet, sobald der Stil in den Einstellungen liegt. |
| Touch-Steuerung | Entschieden (Nutzer 2026-11-24: „wie geplant“) | Schwebender Joystick links (Mitte dort, wo der Daumen aufsetzt), Kamera per Wischen in der rechten Hälfte |
| Sprung- und Schleichknopf | Vorläufig | Knöpfe rechts unten; Schleichen ist ein Umschalter (Vorschlag von Claude) |
| Kamera-Empfindlichkeit | Entschieden (Nutzer 2026-11-24) | Standardwert etwas höher (0,2 statt 0,16 Grad pro Pixel, nach dem Test am iPhone). Später stellt der Nutzer sie selbst per **Schieberegler in den Einstellungen** ein. |
| Bildrate | Vorläufig | Seit 2026-11-24 Deckel **120 fps** (`run/max_fps`), vorher 60. Anlass: Der Nutzer meldet „läuft noch nicht so flüssig“; die Aufnahmen zeigen konstante 60 fps ohne Ruckler, das Display kann aber 120 Hz. Test am Gerät offen; später einstellbar (30/60/120), Akku und Wärme beobachten. |
| Arbeitstitel | Vorläufig | „Kagero“ |
| Umfang Start | Vorläufig | Vertical Slice (Dorf, Wald, Festung) |
| Kamera | Vorläufig | Geführte Third-Person mit Lock-on |
| Grafikstil | **Entschieden** (Nutzer 2026-11-24) | **Cartoon-Stil für das ganze Spiel** (Figuren, Gegner, Welt, Oberfläche), nach dem Referenzbild der Figur: flächige Schattierung, dicke dunkle Umrisse, kräftige Farben. Die **Story bleibt ernst**: der Stil ändert nicht den Ton (Auftragsmörder, wachsender Zweifel). Später kommen auch **fiktive Figuren** dazu. |
| Weltaufbau | Vorläufig | Hubs mit Missionsgebieten |
| Kampfsystem | Vorläufig | Hybrid aus Schleichen und Parieren |
| Assets | Vorläufig | Start mit freien (CC0-)Paketen, Lizenz vorher prüfen |
| Offline/Online | Vorläufig | Offline |
| Speichern | Vorläufig | Automatisch lokal |
| Monetarisierung | **Offen** | Einmalkauf oder Gratis-Demo mit Vollversion |
| Name des Spiels | **Offen** | Endgültiger Titel |
| Auftraggeber, Spielziel, Enden | **Offen** | Folgt im Konzept (Phase 1) |
| Skilltree, Waffen, Fähigkeiten | **Offen** | Folgt vor Phase 4/6 |
| Testgerät | Entschieden | iPhone 16 Pro Max, iOS 27.2.1 (2026-11-24). Leistungsziele werden an diesem Gerät gemessen; ältere Geräte später prüfen |
| Mindest-iOS | **Offen** | Preset steht vorläufig auf iOS 15.0; endgültiger Wert hängt von der Zielgruppe ab |
| Zusammenarbeit mit weiteren Entwicklern | **Offen** | Bestimmt Branch-Schutz und Review-Regeln |

## Zielrichtung Figur (Referenzbild des Nutzers, 2026-11-24)
Der Nutzer wünscht sich, dass die Ninja-Figur in Zukunft **ähnlich wie ein Referenzbild** aussieht; umgebaut wird erst später. Das Bild ist eine Stimmungs- und Stilvorlage, **kein Vorbild zum Kopieren** und liegt nicht im Repo (Rechte unbekannt). Merkmale des Bildes:
- **Chibi-/Cartoon-Proportionen:** großer Kopf, kompakter Körper, kräftige Hände (Fäuste), breite Kampfhaltung.
- **Kapuze mit Maske** über Nase und Mund, **große, ausdrucksstarke Augen** (zusammengezogene Brauen).
- **Rotes Stirnband** mit flatternden Enden, dazu rote Akzente: **Schulterpolster, Gürtel, Knieschützer**.
- Dunkelgraue bis schwarze Kleidung, überkreuzter Wickel-Kragen.
- **Flächiger Cartoon-Look** mit dicken dunklen Umrissen und wenigen Schattenstufen.

Folgen und offene Fragen (noch nicht entschieden):
- Entschieden (Nutzer 2026-11-24): Der Cartoon-Stil gilt für das **ganze Spiel**, nicht nur für die Figur. Er ersetzt den ursprünglichen Wunsch „stilisiert-realistisch“. Die Story bleibt ernst; der Ton entsteht über Inhalt, Musik, Licht und Farbstimmung, nicht über den Zeichenstil.
- Folgen: Welt, Gegner, Waffen und Oberfläche werden an den Stil angepasst (gleiche Umrisse, gleiche Schattierung). Die jetzige Testwelt ist noch nicht im Cartoon-Stil.
- **Offen:** Welche fiktiven Figuren und Wesen später vorkommen (Nutzer nennt das als Richtung, Einzelheiten folgen); Farbpalette und Lichtstimmung für ernste Szenen.
- Technisch möglich (Godot, Mobile): Umrisse (Zusatznetz oder Nachbearbeitung) und flächige Schattierung per Shader. Kosten für Bildrate und Akku sind am Gerät zu messen.
- Umbau im Blender-Skript: Proportionen, Stirnband mit Schweif, Schulter- und Knieschützer, größere Augen (Gesicht als eigene Form oder einfache Textur), Fäuste.
