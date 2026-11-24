extends RefCounted
## Tests für ui/safe_area.gd


func run(t: Object) -> void:
	var window := Vector2i(2556, 1179)

	var none := SafeArea.insets(window, Rect2i(0, 0, 2556, 1179))
	t.check(none == {"left": 0, "top": 0, "right": 0, "bottom": 0}, "ohne Aussparung keine Ränder")

	# Querformat mit Dynamic Island links, Home-Indikator unten
	var island := SafeArea.insets(window, Rect2i(159, 0, 2238, 1146))
	t.check(island["left"] == 159, "Rand links = Aussparung")
	t.check(island["right"] == 159, "Rand rechts = Rest")
	t.check(island["bottom"] == 33, "Rand unten = Home-Indikator")
	t.check(island["top"] == 0, "kein Rand oben")

	var broken := SafeArea.insets(window, Rect2i(0, 0, 0, 0))
	t.check(broken["left"] == 0 and broken["bottom"] == 0, "leerer Bereich ergibt keine Ränder")

	var wild := SafeArea.insets(Vector2i(100, 100), Rect2i(-5, -5, 200, 200))
	t.check(wild["left"] == 0 and wild["right"] == 0, "Ränder werden nie negativ")
