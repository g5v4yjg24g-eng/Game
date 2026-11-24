extends RefCounted
## Tests für gameplay/idle_camera.gd


func run(t: Object) -> void:
	var idle := IdleCamera.new()
	var step := 1.0 / 60.0

	# Nach einer Eingabe: kein Schwenk, auch nach Sekunden nicht, solange die Figur nicht steht
	var speed := 0.0
	for i in 60 * 30:
		speed = idle.update(step, false)
	t.check(speed == 0.0 and idle.idle_time == 0.0, "in Bewegung: kein Schwenk, Zeit bleibt null")

	# Stillstand: vor der Wartezeit kein Schwenk
	for i in int(ControlsConfig.IDLE_CAMERA_DELAY * 60.0) - 5:
		speed = idle.update(step, true)
	t.check(
		speed == 0.0,
		"vor %.0f s Stillstand dreht die Kamera nicht" % ControlsConfig.IDLE_CAMERA_DELAY
	)

	# Nach der Wartezeit: Schwenk fährt sanft an
	for i in 30:
		speed = idle.update(step, true)
	t.check(
		speed > 0.0 and speed < ControlsConfig.IDLE_CAMERA_SPEED * 0.2,
		"Schwenk fährt sanft an (%.2f Grad/s)" % speed
	)
	for i in int(ControlsConfig.IDLE_CAMERA_RAMP_IN * 60.0) + 60:
		speed = idle.update(step, true)
	t.check(
		is_equal_approx(speed, ControlsConfig.IDLE_CAMERA_SPEED),
		"volle Geschwindigkeit nach dem Anfahren (%.2f Grad/s)" % speed
	)

	# Erste Eingabe: Zeit zurück, Schwenk wird schnell ausgeblendet
	idle.notify_activity()
	t.check(idle.idle_time == 0.0, "Eingabe setzt die Wartezeit zurück")
	var steps_to_stop := 0
	while idle.update(step, true) > 0.01 and steps_to_stop < 600:
		steps_to_stop += 1
	t.check(
		steps_to_stop < int((ControlsConfig.IDLE_CAMERA_RAMP_OUT + 0.1) * 60.0),
		"Schwenk stoppt schnell nach einer Eingabe (%d Schritte)" % steps_to_stop
	)

	# Bewegung unterbricht ebenfalls und die Wartezeit beginnt von vorn
	var fresh := IdleCamera.new()
	for i in int((ControlsConfig.IDLE_CAMERA_DELAY + 5.0) * 60.0):
		fresh.update(step, true)
	t.check(fresh.strength > 0.0, "nach der Wartezeit läuft der Schwenk")
	fresh.update(step, false)
	t.check(fresh.idle_time == 0.0, "Bewegung setzt die Wartezeit zurück")

	# Wartezeit liegt im gewünschten Bereich (Nutzer: 10 bis 15 Sekunden)
	t.check(
		ControlsConfig.IDLE_CAMERA_DELAY >= 10.0 and ControlsConfig.IDLE_CAMERA_DELAY <= 15.0,
		"Wartezeit liegt zwischen 10 und 15 Sekunden (%.0f)" % ControlsConfig.IDLE_CAMERA_DELAY
	)
