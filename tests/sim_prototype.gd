extends Node
## Simulationstest: lädt den Prototyp, spielt Eingaben über den EventBus ein und prüft,
## ob die Figur sich bewegt, springt und die Kamera dreht. Läuft ohne Grafik.
## Aufruf: godot --headless --path . res://tests/sim_prototype.tscn

var _failed := 0


func _ready() -> void:
	# Testläufe dürfen die Einstellungen des Geräts nicht verändern
	Settings.path = "user://settings_test.cfg"
	Settings.data = SettingsData.new()
	var scene: Node = load("res://scenes/prototype.tscn").instantiate()
	add_child(scene)
	var bus := EventBus
	var player: Player = null
	var rig: CameraRig = null
	for child in scene.get_children():
		if child is Player:
			player = child
		elif child is CameraRig:
			rig = child
	_check(player != null and rig != null, "Prototyp enthält Spieler und Kamera")
	if player == null or rig == null:
		get_tree().quit(1)
		return

	# Ruhe: Figur fällt auf den Boden und bleibt stehen
	await _frames(40)
	_check(player.is_on_floor(), "Figur steht auf dem Boden")
	var rest := player.global_position
	_check(rest.y > -0.1 and rest.y < 0.3, "Figur liegt auf Bodenhöhe (y=%.2f)" % rest.y)
	_check(
		player.current_animation() == &"idle",
		"Stehen: Animation idle (%s)" % player.current_animation()
	)

	# Kameralage: hinter (+Z bei Blick nach -Z) und über der Figur, Abstand wie eingestellt
	var offset := rig.camera_position() - player.global_position
	_check(
		offset.z > 2.0 and offset.y > 1.5, "Kamera steht hinter und über der Figur (%s)" % offset
	)
	_check(
		absf(offset.length() - ControlsConfig.CAMERA_DISTANCE) < 1.6,
		"Kameraabstand passt (%.1f m)" % offset.length()
	)

	# Joystick nach oben: Kamera schaut nach -Z, Figur läuft nach -Z
	bus.move_input.emit(Vector2(0, -1))
	await _frames(60)
	var moved := player.global_position
	_check(
		moved.z < rest.z - 3.0, "Joystick hoch: Figur läuft vorwärts (dz=%.1f)" % (moved.z - rest.z)
	)
	_check(absf(moved.x - rest.x) < 0.5, "Joystick hoch: kaum seitliche Abweichung")
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	_check(absf(speed - ControlsConfig.RUN_SPEED) < 0.3, "Lauftempo erreicht (%.2f m/s)" % speed)
	_check(
		player.current_animation() == &"run",
		"Laufen: Animation run (%s)" % player.current_animation()
	)

	# Schleichen verlangsamt
	bus.sneak_changed.emit(true)
	await _frames(40)
	speed = Vector2(player.velocity.x, player.velocity.z).length()
	_check(absf(speed - ControlsConfig.SNEAK_SPEED) < 0.3, "Schleichtempo (%.2f m/s)" % speed)
	_check(
		player.current_animation() == &"sneak",
		"Schleichen: Animation sneak (%s)" % player.current_animation()
	)
	bus.sneak_changed.emit(false)

	# Stehen bleiben
	bus.move_input.emit(Vector2.ZERO)
	await _frames(40)
	_check(
		Vector2(player.velocity.x, player.velocity.z).length() < 0.1,
		"Ohne Eingabe bleibt die Figur stehen"
	)
	_check(
		player.current_animation() == &"idle",
		"Nach dem Laufen: wieder idle (%s)" % player.current_animation()
	)

	# Sprung (mit Salto): die Animationen flip, fall und land kommen der Reihe nach
	var ground_y := player.global_position.y
	var seen: Array[StringName] = []
	bus.jump_pressed.emit()
	var peak := ground_y
	var flip_max := 0.0
	var head_forward_max := 0.0
	for i in 100:
		await get_tree().physics_frame
		peak = maxf(peak, player.global_position.y)
		flip_max = maxf(flip_max, player.flip_angle_deg())
		head_forward_max = maxf(head_forward_max, player.head_forward())
		var name := player.current_animation()
		if seen.is_empty() or seen[-1] != name:
			seen.append(name)
	_check(peak - ground_y > 0.8, "Sprung hebt die Figur an (%.2f m)" % (peak - ground_y))
	_check(player.is_on_floor(), "Figur landet wieder")
	_check(flip_max > 300.0, "Sprung macht einen Salto vorwärts (%.0f Grad)" % flip_max)
	_check(
		head_forward_max > 0.9,
		"Der Kopf kippt nach vorn, nicht nach hinten (%.2f)" % head_forward_max
	)
	_check(
		not player.is_flipping() and absf(player.flip_angle_deg()) < 0.01,
		"Nach der Landung steht die Figur wieder aufrecht"
	)
	_check(
		seen.has(&"flip") and seen.has(&"fall") and seen.has(&"land"),
		"Sprung zeigt flip, fall und land: %s" % [seen]
	)
	_check(
		seen.find(&"flip") < seen.find(&"fall") and seen.find(&"fall") < seen.find(&"land"),
		"Reihenfolge flip, fall, land"
	)

	# Kamera: Wischen nach rechts dreht die Blickrichtung, Joystick hoch folgt ihr
	var yaw_before := rig.yaw_deg
	bus.look_input.emit(Vector2(250, 0))
	_check(
		rig.yaw_deg < yaw_before - 10.0,
		"Wischen nach rechts dreht die Kamera (yaw %.1f)" % rig.yaw_deg
	)
	var before_turn := player.global_position
	bus.move_input.emit(Vector2(0, -1))
	await _frames(60)
	var delta := player.global_position - before_turn
	var forward := Vector3(-sin(rig.yaw_rad()), 0.0, -cos(rig.yaw_rad()))
	_check(
		delta.normalized().dot(forward) > 0.9,
		"Laufrichtung folgt der Kamera (dot=%.2f)" % delta.normalized().dot(forward)
	)
	bus.move_input.emit(Vector2.ZERO)

	# Stillstands-Schwenk: Die Kamera dreht sich erst nach der Wartezeit und stoppt bei Eingabe
	rig.set_process(false)
	bus.move_input.emit(Vector2.ZERO)
	await _frames(60)
	var step := 1.0 / 60.0
	var yaw_start := rig.yaw_deg
	for i in int((ControlsConfig.IDLE_CAMERA_DELAY - 2.0) / step):
		rig._process(step)
	_check(
		absf(angle_difference(deg_to_rad(rig.yaw_deg), deg_to_rad(yaw_start))) < 0.01,
		"Vor der Wartezeit bleibt die Kamera stehen (yaw %.2f)" % rig.yaw_deg
	)
	for i in int(12.0 / step):
		rig._process(step)
	var turned := absf(angle_difference(deg_to_rad(rig.yaw_deg), deg_to_rad(yaw_start)))
	_check(
		turned > deg_to_rad(20.0),
		"Nach der Wartezeit schwenkt die Kamera (%.0f Grad)" % rad_to_deg(turned)
	)
	bus.look_input.emit(Vector2.ZERO)
	bus.activity.emit()
	for i in int(1.0 / step):
		rig._process(step)
	var yaw_stopped := rig.yaw_deg
	for i in int(1.0 / step):
		rig._process(step)
	_check(
		(
			absf(angle_difference(deg_to_rad(rig.yaw_deg), deg_to_rad(yaw_stopped))) < 0.01
			and rig.idle_strength() == 0.0
		),
		"Eine Eingabe stoppt den Schwenk"
	)
	rig.set_process(true)

	# Absturz: Figur kehrt zum Startpunkt zurück
	player.global_position = Vector3(0, -30, 0)
	await _frames(3)
	_check(player.global_position.y > -1.0, "Figur wird nach einem Absturz zurückgesetzt")

	print("Simulation: %s" % ("alles bestanden" if _failed == 0 else "%d Fehler" % _failed))
	get_tree().quit(1 if _failed > 0 else 0)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		_failed += 1
		printerr("  FEHLER ", description)
