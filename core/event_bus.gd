extends Node
## Globaler Ereignisbus. Trennt Spiellogik, Oberfläche und Daten über Signale.
## Neue Signale hier ergänzen, statt Knoten direkt miteinander zu verknüpfen.

## Der Spieler hat Schaden genommen (Menge, Quelle).
signal player_damaged(amount: int, source: Node)
## Ein Gegner hat den Spieler entdeckt.
signal player_spotted(by: Node)
## Der Spielstand soll gesichert werden.
signal save_requested
