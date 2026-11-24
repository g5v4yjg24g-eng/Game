extends Node
## Simulationstest: lädt den Prototyp, spielt Eingaben über den EventBus ein und prüft,
## ob die Figur sich bewegt, springt und die Kamera dreht. Läuft ohne Grafik.
## Aufruf: godot --headless --path . res://tests/sim_prototype.tscn

var _failed := 0


func _ready() -> void:
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

	# Sprung: die Animationen jump, fall und land kommen der Reihe nach
	var ground_y := player.global_position.y
	var seen: Array[StringName] = []
	bus.jump_pressed.emit()
	var peak := ground_y
	for i in 100:
		await get_tree().physics_frame
		peak = maxf(peak, player.global_position.y)
		var name := player.current_animation()
		if seen.is_empty() or seen[-1] != name:
			seen.append(name)
	_check(peak - ground_y > 0.8, "Sprung hebt die Figur an (%.2f m)" % (peak - ground_y))
	_check(player.is_on_floor(), "Figur landet wieder")
	_check(
		seen.has(&"jump") and seen.has(&"fall") and seen.has(&"land"),
		"Sprung zeigt jump, fall und land: %s" % [seen]
	)
	_check(
		seen.find(&"jump") < seen.find(&"fall") and seen.find(&"fall") < seen.find(&"land"),
		"Reihenfolge jump, fall, land"
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
