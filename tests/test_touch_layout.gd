extends RefCounted
## Tests für ui/touch_layout.gd


func run(t: Object) -> void:
	var size := Vector2(1280, 590)
	var none := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	var jump := TouchLayout.button_center(TouchLayout.Zone.JUMP, size, none)
	var sneak := TouchLayout.button_center(TouchLayout.Zone.SNEAK, size, none)

	t.check(
		TouchLayout.zone_at(jump, size, none) == TouchLayout.Zone.JUMP, "Mitte des Sprungknopfs"
	)
	t.check(
		TouchLayout.zone_at(sneak, size, none) == TouchLayout.Zone.SNEAK, "Mitte des Schleichknopfs"
	)
	t.check(sneak.x < jump.x and is_equal_approx(sneak.y, jump.y), "Schleichen links vom Sprung")
	t.check(
		TouchLayout.zone_at(Vector2(100, 300), size, none) == TouchLayout.Zone.JOYSTICK,
		"linke Hälfte ist Joystick"
	)
	t.check(
		TouchLayout.zone_at(Vector2(900, 100), size, none) == TouchLayout.Zone.LOOK,
		"rechte Hälfte ist Kamera"
	)
	t.check(
		TouchLayout.zone_at(jump + Vector2(-60, 0), size, none) == TouchLayout.Zone.JUMP,
		"Treffer knapp neben dem Knopf zählt (größere Fläche)"
	)

	var island := {"left": 59.0, "top": 0.0, "right": 59.0, "bottom": 21.0}
	var jump_safe := TouchLayout.button_center(TouchLayout.Zone.JUMP, size, island)
	t.check(jump_safe.x < jump.x and jump_safe.y < jump.y, "Safe Area schiebt Knöpfe nach innen")
	var hint := TouchLayout.joystick_hint(size, island)
	t.check(hint.x > 59.0 and hint.y < size.y - 21.0, "Joystick-Hinweis liegt in der Safe Area")

	# Testknopf für den Cartoon-Stil oben rechts
	var style := TouchLayout.button_center(TouchLayout.Zone.STYLE, size, none)
	t.check(
		TouchLayout.zone_at(style, size, none) == TouchLayout.Zone.STYLE, "Mitte des Stil-Knopfs"
	)
	t.check(style.x > size.x * 0.8 and style.y < size.y * 0.3, "Stil-Knopf sitzt oben rechts")
	t.check(
		TouchLayout.zone_at(style + Vector2(-200, 0), size, none) == TouchLayout.Zone.LOOK,
		"daneben bleibt die Kamerafläche"
	)
	var style_safe := TouchLayout.button_center(TouchLayout.Zone.STYLE, size, island)
	t.check(style_safe.x < style.x, "Safe Area schiebt den Stil-Knopf nach innen")
