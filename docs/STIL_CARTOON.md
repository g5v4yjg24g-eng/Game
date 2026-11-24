# Cartoon-Stil (Leitfaden, Phase 3c)

Entscheidung des Nutzers (2026-11-24): Der **Cartoon-Stil gilt für das ganze Spiel** (Figuren, Gegner,
Welt, Oberfläche), nach dem Referenzbild der Figur. Die **Story bleibt ernst**, der Ton entsteht über
Inhalt, Musik, Licht und Farbstimmung. Später kommen fiktive Figuren dazu. Dieses Dokument hält fest, was
technisch vorbereitet ist, was gemessen wurde und was noch zu entscheiden ist.

## Stilregeln (Vorschlag, mit dem Nutzer abzustimmen)
1. **Flächig:** drei Helligkeitsstufen (Schatten, Mitte, Licht) mit harten Kanten, keine Texturen auf Welt und Figuren, Verläufe nur im Himmel.
2. **Umriss:** dicke dunkle Linie um alle Figuren und wichtigen Objekte. Umrissfarbe nahezu schwarz mit Blaustich (`#0A0A12`), nie reines Schwarz. Breite etwa 4 bis 5 Pixel bei 1280 x 590 (0,05 m bei 5 m Abstand), bleibt am Bildschirm ähnlich dick.
3. **Farbe:** kräftige, gesättigte Grundfarben. Je Szene eine Grundstimmung, **ein Akzent** (Rot) für Wichtiges: Figur, Ziele, Gefahr.
4. **Ernster Ton trotz Cartoon:** gedämpfte, dunklere Paletten und Licht in ernsten Szenen; Nebel nur, wo er die Stimmung trägt (er senkt den Kontrast der Umrisse).
5. **Lesbarkeit:** Figuren heben sich klar vom Hintergrund ab (heller als der Boden oder durch Umriss und Akzentfarbe).
6. **Oberfläche:** runde Formen, dicke Umrisse, gleiche Palette wie die Welt.

## Farbrollen (Vorschlag, noch nicht entschieden)
| Rolle | Vorschlag |
|---|---|
| Kleidung Figur | Anthrazit `#3A3B45`, Tiefschwarz `#1B1C22` |
| Akzent | Rot `#D2342C` |
| Haut / Gesicht | warmes Gelb-Orange `#F0B070` |
| Stahl | helles Grau `#AEB3BC` |
| Umriss | `#0A0A12` |

## Figur nach Referenz (erste Version, 2026-11-24)
Gebaut mit `tools/blender/build_ninja.py`, 1,45 m groß, Chibi-Proportionen. Enthalten: großer runder Kopf (breiter als die Schultern), Kapuze mit Gesicht und Maske, **große Augen mit zornigen Brauen**, rotes Stirnband mit seitlichen Spitzen und flatternden Enden, rote Schulterpolster, Gürtel mit Knoten, überkreuzter Kragen, rote Knieschützer, Fäuste in Hautfarbe, Stiefel, Schwert auf dem Rücken.
Das Bild des Nutzers ist Stilvorlage, nicht Vorlage zum Kopieren; die Figur ist eine eigene Konstruktion. **Noch offen:** Feinschliff nach Rückmeldung (Proportionen, Farbe, Gesicht), Kampfhaltung als Ruhepose, Gesicht mit Textur statt reiner Flächen. Fiktive Figuren und Wesen folgen später derselben Formensprache und werden erst als Konzept abgestimmt.

## Was technisch vorbereitet ist
- **Shader** `assets/shaders/toon.gdshader` (drei Stufen) und `assets/shaders/outline.gdshader` (Inverted Hull, Breite wächst mit dem Abstand). Beide laufen im **Mobile-Renderer**.
- **`world/style/cartoon_style.gd`** schaltet den Stil über `EventBus.style_changed`. Aus: Materialien unverändert. An: Toon-Material und Umrisse.
- **Umrisse:** Die Figur bringt ein eigenes Umriss-Mesh mit (`NinjaUmriss`, geglättete Normalen, am selben Skelett). Dünne Teile (Stirnband-Enden, Schwert) tragen einen kleineren Breitenfaktor in der Vertexfarbe (Rot-Kanal), sonst wäre ihr Umriss unverhältnismäßig dick. Statische Teile bekommen ein Umriss-Netz mit gemittelten Normalen (`world/style/smooth_normals.gd`, mit Tests). Boden und Weg haben bewusst keinen Umriss, Umrisse weiter als 45 m werden nicht gezeichnet.
- **Testknopf „Stil“** oben rechts (nur für die Prüfphase), Anzeige „Stil: normal/Cartoon“ in der Messanzeige. Standard ist **aus**.
- **Prüfung:** Tests für die Normalen-Rechnung und den Knopf, Simulation für Ein- und Ausschalten, und ein CI-Job `mobile-renderer`, der den Prototyp mit Cartoon-Stil im echten Mobile-Renderer (Software-Vulkan) rendert und Shader-Fehler meldet.

## Messungen
Alle Zahlen vom **Mobile-Renderer in Software** (Vulkan über llvmpipe) auf dem Entwicklungsrechner, nicht vom iPhone.
Maßstab: Für denselben Stand (Build 5, Startansicht) meldete der Nutzer am iPhone 130 Draw Calls und 206 Objekte; der
Software-Mobile-Renderer zeigt dafür 145 und 221, also etwa 10 % mehr. Draw Calls und Objekte sind damit ein
brauchbarer, leicht zu hoher Maßstab, **Bildraten und Akku nicht** (Software). Aktueller Stand mit Ninja-Modell,
Startansicht, Stil aus: 142 Draw Calls, 241 Objekte.

| Ansicht | Draw Calls | Objekte |
|---|---|---|
| normal (gleicher Blickwinkel) | 89 | 184 |
| Cartoon, gleicher Blickwinkel | 110 (+24 %) | 211 |
| Cartoon, Blick auf viele Bäume | bis 157 | bis 258 |

Der Umriss kostet also grob **20 bis 45 % mehr Draw Calls** in den getesteten Ansichten. **Bildrate und Akku am iPhone sind offen [O]**:
Der Testknopf macht den Vergleich am Gerät möglich.

## Bekannte Grenzen
- Nebel und Dämmerlicht der Testwelt machen die Umrisse blass und die Szene matschig. Für den Stil braucht die Welt eine eigene Farb- und Lichtabstimmung (offen).
- Die Figur ist im Abend- und Nebellicht der Testwelt dunkel und klein; ohne eigene Licht- und Farbabstimmung der Welt liest sie sich im Cartoon-Modus schwach.
- Der Umriss der Figur verdoppelt die Skinning-Arbeit (3 844 Punkte zusätzlich), unkritisch, aber zu messen.
- Dünne Teile (Schal, Schwertscheide) bekommen eine gleich breite Linie und wirken dadurch kräftiger.
- Augen und Gesicht brauchen später eine kleine Textur oder eigene Geometrie; reine Flächenfarben reichen für den Ausdruck im Referenzbild nicht.

## Nächste Schritte
1. Am iPhone mit dem Testknopf vergleichen: Aussehen, Bildrate, Akku (nur der Nutzer kann das prüfen).
2. Entscheidungen: Nebel und Lichtstimmung, endgültige Palette, Umrissbreite.
3. Figur: erste Version steht; Feinschliff nach Rückmeldung, danach Animationen perfektionieren (Phase 3c).
4. Welt-Teile im Stil neu aufbauen (Gebäude, Bäume, Gelände).
5. Oberfläche im Stil.
6. Stil in die Einstellungen (Schalter) und Standard auf „an“ stellen, sobald er überzeugt.
