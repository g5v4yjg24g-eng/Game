extends RefCounted
## Tests für ui/joystick_logic.gd


func run(t: Object) -> void:
	t.check(
		JoystickLogic.compute(Vector2(5, 0), 100.0, 0.12) == Vector2.ZERO, "Totzone ergibt null"
	)
	var full := JoystickLogic.compute(Vector2(300, 0), 100.0, 0.12)
	t.check(is_equal_approx(full.length(), 1.0), "über dem Radius wird auf Länge 1 begrenzt")
	var half := JoystickLogic.compute(Vector2(0, -56), 100.0, 0.12)
	t.check(
		half.y < 0.0 and absf(half.length() - ((0.56 - 0.12) / 0.88)) < 0.0001,
		"Wert nach Abzug der Totzone skaliert"
	)
	t.check(
		JoystickLogic.compute(Vector2(10, 10), 0.0, 0.12) == Vector2.ZERO, "Radius null ist sicher"
	)

	var j := JoystickLogic.new(100.0, 0.1)
	j.begin(3, Vector2(200, 400))
	t.check(j.active and j.value == Vector2.ZERO, "Beginn: aktiv, Wert null")
	t.check(j.move(7, Vector2(300, 400)) == Vector2.ZERO, "fremder Finger wird ignoriert")
	var v := j.move(3, Vector2(300, 400))
	t.check(v.x > 0.99 and absf(v.y) < 0.001, "Auslenkung nach rechts")
	t.check(j.knob == Vector2(100, 0), "Knopf bleibt im Radius")
	j.move(3, Vector2(200, 250))
	t.check(j.value.y < 0.0, "Auslenkung nach oben ist negatives y")
	t.check(not j.end(7), "fremder Finger beendet nichts")
	t.check(j.end(3) and not j.active and j.value == Vector2.ZERO, "Ende setzt zurück")
