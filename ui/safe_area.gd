class_name SafeArea
extends RefCounted
## Rechnet den sicheren Bereich (Dynamic Island, Rundungen, Home-Indikator) in Ränder um.
## Reine Logik ohne Zugriff auf das Display, damit sie testbar bleibt.


## Liefert die Abstände {left, top, right, bottom} in Pixeln des Fensters.
## [param window_size] Größe des Fensters, [param safe] sicherer Bereich in Fensterkoordinaten.
static func insets(window_size: Vector2i, safe: Rect2i) -> Dictionary:
	if window_size.x <= 0 or window_size.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return {"left": 0, "top": 0, "right": 0, "bottom": 0}
	return {
		"left": maxi(safe.position.x, 0),
		"top": maxi(safe.position.y, 0),
		"right": maxi(window_size.x - (safe.position.x + safe.size.x), 0),
		"bottom": maxi(window_size.y - (safe.position.y + safe.size.y), 0),
	}


## Wendet die Abstände auf einen Container an. Pixel des Fensters werden dabei in
## Pixel der Oberfläche umgerechnet ([param scale] = Oberfläche / Fenster).
static func apply(
	container: MarginContainer, window_size: Vector2i, safe: Rect2i, scale: float
) -> void:
	var i := insets(window_size, safe)
	container.add_theme_constant_override("margin_left", roundi(i["left"] * scale))
	container.add_theme_constant_override("margin_top", roundi(i["top"] * scale))
	container.add_theme_constant_override("margin_right", roundi(i["right"] * scale))
	container.add_theme_constant_override("margin_bottom", roundi(i["bottom"] * scale))
