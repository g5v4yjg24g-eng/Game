extends Node
## Globaler Ereignisbus. Trennt Spiellogik, Oberfläche und Daten über Signale.
## Neue Signale hier ergänzen, statt Knoten direkt miteinander zu verknüpfen.

## Der Spieler hat Schaden genommen (Menge, Quelle).
signal player_damaged(amount: int, source: Node)
## Ein Gegner hat den Spieler entdeckt.
signal player_spotted(by: Node)
## Der Spielstand soll gesichert werden.
signal save_requested

## Joystick-Eingabe (x rechts, y nach unten, Länge 0 bis 1).
signal move_input(vector: Vector2)
## Wischbewegung für die Kamera in Pixeln der Oberfläche.
signal look_input(drag: Vector2)
## Sprungknopf wurde gedrückt.
signal jump_pressed
## Schleichen wurde ein- oder ausgeschaltet.
signal sneak_changed(active: bool)

## Cartoon-Darstellung wurde ein- oder ausgeschaltet (Vorbereitung Phase 3c, Testknopf).
signal style_changed(cartoon: bool)

## Irgendeine Berührung des Bildschirms (setzt z. B. den Stillstands-Schwenk der Kamera zurück).
signal activity
