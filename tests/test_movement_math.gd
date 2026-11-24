extends RefCounted
## Tests für gameplay/movement_math.gd und gameplay/camera_math.gd


func run(t: Object) -> void:
	# Blick nach -Z (yaw 0): Joystick nach oben = vorwärts = -Z
	var forward := MovementMath.world_direction(Vector2(0, -1), 0.0)
	t.check(forward.is_equal_approx(Vector3(0, 0, -1)), "yaw 0: hoch = nach -Z")
	var right := MovementMath.world_direction(Vector2(1, 0), 0.0)
	t.check(right.is_equal_approx(Vector3(1, 0, 0)), "yaw 0: rechts = +X")
	# Kamera um 90 Grad nach links gedreht (Blick -X): vorwärts = -X
	var turned := MovementMath.world_direction(Vector2(0, -1), deg_to_rad(90.0))
	t.check(turned.is_equal_approx(Vector3(-1, 0, 0)), "yaw 90: hoch = nach -X")

	t.check(
		is_equal_approx(MovementMath.target_speed(1.0, false), ControlsConfig.RUN_SPEED),
		"volle Auslenkung = Lauftempo"
	)
	t.check(
		is_equal_approx(MovementMath.target_speed(1.0, true), ControlsConfig.SNEAK_SPEED),
		"Schleichen ist langsamer"
	)
	t.check(
		is_equal_approx(MovementMath.target_speed(0.5, false), ControlsConfig.RUN_SPEED * 0.5),
		"halbe Auslenkung = halbes Tempo"
	)
	t.check(
		is_equal_approx(MovementMath.target_speed(3.0, false), ControlsConfig.RUN_SPEED), "begrenzt"
	)

	# Figur schaut in die Bewegungsrichtung
	var yaw := MovementMath.facing_yaw(Vector3(0, 0, -1))
	t.check(absf(yaw) < 0.0001, "Blick nach -Z = yaw 0")
	var face_x := MovementMath.facing_yaw(Vector3(-1, 0, 0))
	t.check(
		is_equal_approx(face_x, deg_to_rad(90.0)),
		"Blick nach -X = yaw 90 (gleiche Drehrichtung wie die Kamera)"
	)

	t.check(is_equal_approx(MovementMath.turn_toward(0.0, 1.0, 0.25), 0.25), "Drehung ist begrenzt")
	t.check(is_equal_approx(MovementMath.turn_toward(0.0, 0.1, 0.25), 0.1), "kein Überschwingen")
	var wrap := MovementMath.turn_toward(deg_to_rad(170.0), deg_to_rad(-170.0), 1.0)
	t.check(wrap > deg_to_rad(170.0), "Drehung nimmt den kurzen Weg über 180 Grad")

	var acc := MovementMath.accelerate(Vector3.ZERO, Vector3(6, 0, 0), 38.0, 0.1)
	t.check(is_equal_approx(acc.x, 3.8), "Beschleunigung je Zeitschritt")
	t.check(
		MovementMath.accelerate(Vector3(5.9, 0, 0), Vector3(6, 0, 0), 38.0, 0.1).x == 6.0,
		"erreicht das Ziel genau"
	)

	# Kamera
	var look := CameraMath.apply_look(0.0, 0.0, Vector2(100, 0), 0.2)
	t.check(is_equal_approx(look.x, -20.0), "Wischen nach rechts: Blick nach rechts (yaw sinkt)")
	var up := CameraMath.apply_look(0.0, 0.0, Vector2(0, -50), 0.2)
	t.check(is_equal_approx(up.y, 10.0), "Wischen nach oben: Blick nach oben")
	var clamp_hi := CameraMath.apply_look(0.0, 20.0, Vector2(0, -1000), 0.2)
	t.check(is_equal_approx(clamp_hi.y, ControlsConfig.MAX_PITCH_DEG), "Neigung oben begrenzt")
	var clamp_lo := CameraMath.apply_look(0.0, -60.0, Vector2(0, 1000), 0.2)
	t.check(is_equal_approx(clamp_lo.y, ControlsConfig.MIN_PITCH_DEG), "Neigung unten begrenzt")
	var wrapped := CameraMath.apply_look(179.0, 0.0, Vector2(-100, 0), 0.2)
	t.check(wrapped.x < 0.0 and wrapped.x > -180.0, "Gier läuft über 180 Grad weiter")
