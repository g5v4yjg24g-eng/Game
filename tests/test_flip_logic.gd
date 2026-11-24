extends RefCounted
## Tests für gameplay/flip_logic.gd


func run(t: Object) -> void:
	var f := FlipLogic.new()
	t.check(not f.active and f.angle_deg == 0.0, "Ohne Sprung keine Drehung")
	f.step(0.1, false)
	t.check(f.angle_deg == 0.0, "Schritt ohne Start ändert nichts")

	# Voller Sprung in der Luft: Winkel wächst gleichmäßig, am Ende wieder aufrecht
	f.start()
	var last := -1.0
	var monotonic := true
	var max_angle := 0.0
	var steps := int(ControlsConfig.FLIP_SECONDS / 0.01) - 2
	for i in steps:
		f.step(0.01, false)
		if f.angle_deg < last:
			monotonic = false
		last = f.angle_deg
		max_angle = maxf(max_angle, f.angle_deg)
	t.check(monotonic, "Winkel wächst ohne Rückschritt")
	t.check(max_angle > 330.0 and max_angle < 360.0, "kurz vor dem Ende fast eine volle Drehung")
	f.step(0.05, false)
	t.check(not f.active and f.angle_deg == 0.0, "nach einer vollen Drehung wieder aufrecht")

	# Salto ist vor der normalen Landung fertig
	var air := 2.0 * ControlsConfig.JUMP_SPEED / ControlsConfig.GRAVITY
	t.check(
		ControlsConfig.FLIP_SECONDS < air,
		"Drehung endet vor der Landung (%.2f < %.2f s)" % [ControlsConfig.FLIP_SECONDS, air]
	)

	# Bodenkontakt direkt nach dem Absprung wird ignoriert
	f.start()
	f.step(0.016, true)
	t.check(f.active and f.angle_deg > 0.0, "Bodenkontakt beim Abheben beendet den Salto nicht")

	# Frühe Landung kurz nach dem Absprung: wird aufgerichtet statt hängen zu bleiben
	f.start()
	for i in 6:
		f.step(0.02, false)
	var before := f.angle_deg
	for i in 10:
		f.step(0.02, true)
	t.check(
		before > 0.0 and not f.active and f.angle_deg == 0.0, "frühe Landung richtet die Figur auf"
	)

	# Frühe Landung fast am Ende der Drehung: gilt als fertig
	f.start()
	for i in 45:
		f.step(0.01, false)
	t.check(f.angle_deg >= FlipLogic.FINISH_ANGLE, "Winkel nahe am Ende (%.0f)" % f.angle_deg)
	f.step(0.01, true)
	t.check(not f.active and f.angle_deg == 0.0, "Landung kurz vor Ende beendet den Salto")

	f.start()
	f.cancel()
	t.check(not f.active and f.angle_deg == 0.0, "Abbrechen setzt zurück")
