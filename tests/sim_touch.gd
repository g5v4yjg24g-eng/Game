extends Node
## Simulationstest der Touch-Oberfläche: Touch-Ereignisse gehen durch TouchControls,
## den EventBus und bis zur Figur und Kamera. Läuft ohne Grafik.
## Die Ereignisse gehen direkt an das Widget: Im Headless-Modus hat das Fenster die Größe 0,
## und Godot würde die Koordinaten über den Fenster-Viewport verzerren.
## Aufruf: godot --headless --path . res://tests/sim_touch.tscn

var _failed := 0
var _controls: TouchControls
var _scene: Node


func _ready() -> void:
	# Testläufe dürfen die Einstellungen des Geräts nicht verändern
	Settings.path = "user://settings_test.cfg"
	Settings.data = SettingsData.new()
	_scene = load("res://scenes/prototype.tscn").instantiate()
	var scene := _scene
	add_child(scene)
	var player: Player = null
	var rig: CameraRig = null
	for child in scene.get_children():
		if child is Player:
			player = child
		elif child is CameraRig:
			rig = child
		elif child is CanvasLayer:
			for inner in child.get_children():
				if inner is TouchControls:
					_controls = inner
	await _frames(40)
	var size := _controls.get_viewport_rect().size
	var none := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}

	# Joystick: links aufsetzen und nach oben ziehen
	var start := Vector2(200, 400)
	var before := player.global_position
	_touch(0, start, true)
	_drag(0, start + Vector2(0, -60), Vector2(0, -60))
	_drag(0, start + Vector2(0, -130), Vector2(0, -70))
	await _frames(60)
	_check(
		player.global_position.z < before.z - 3.0,
		"Joystick per Touch: Figur läuft (dz=%.1f)" % (player.global_position.z - before.z)
	)
	_touch(0, start + Vector2(0, -130), false)
	await _frames(40)
	_check(
		Vector2(player.velocity.x, player.velocity.z).length() < 0.1,
		"Loslassen: Figur bleibt stehen"
	)

	# Kamera: rechte Hälfte wischen, gleichzeitig der Joystick (zwei Finger)
	var yaw_before := rig.yaw_deg
	_touch(1, Vector2(900, 200), true)
	_drag(1, Vector2(1000, 200), Vector2(100, 0))
	_check(rig.yaw_deg < yaw_before - 5.0, "Kamera per Touch gedreht (yaw %.1f)" % rig.yaw_deg)
	var pos_one := player.global_position
	_touch(0, start, true)
	_drag(0, start + Vector2(0, -120), Vector2(0, -120))
	_drag(1, Vector2(1020, 200), Vector2(20, 0))
	await _frames(30)
	_check(
		player.global_position.distance_to(pos_one) > 1.0,
		"Zwei Finger gleichzeitig: Laufen und Umsehen"
	)
	_touch(0, start, false)
	_touch(1, Vector2(1020, 200), false)
	await _frames(40)

	# Sprungknopf
	var jump_center := TouchLayout.button_center(TouchLayout.Zone.JUMP, size, none)
	var ground_y := player.global_position.y
	_touch(2, jump_center, true)
	var peak := ground_y
	for i in 40:
		await get_tree().physics_frame
		peak = maxf(peak, player.global_position.y)
	_touch(2, jump_center, false)
	_check(peak - ground_y > 0.8, "Sprungknopf: Figur springt (%.2f m)" % (peak - ground_y))

	# Schleichknopf schaltet um
	var sneak_center := TouchLayout.button_center(TouchLayout.Zone.SNEAK, size, none)
	await _frames(60)
	_touch(3, sneak_center, true)
	_touch(3, sneak_center, false)
	_touch(0, start, true)
	_drag(0, start + Vector2(0, -130), Vector2(0, -130))
	await _frames(40)
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	_check(
		absf(speed - ControlsConfig.SNEAK_SPEED) < 0.3, "Schleichknopf: langsam (%.2f m/s)" % speed
	)
	_touch(3, sneak_center, true)
	_touch(3, sneak_center, false)
	await _frames(40)
	speed = Vector2(player.velocity.x, player.velocity.z).length()
	_check(
		absf(speed - ControlsConfig.RUN_SPEED) < 0.3,
		"Schleichknopf erneut: wieder Lauftempo (%.2f m/s)" % speed
	)
	_touch(0, start, false)

	# Menü-Knopf öffnet die Einstellungen; Stil und Empfindlichkeit wirken sofort
	var menu_center := TouchLayout.button_center(TouchLayout.Zone.MENU, size, none)
	var style: CartoonStyle = null
	var menu: SettingsMenu = null
	for child in scene.get_children():
		if child is CartoonStyle:
			style = child
		if child is SettingsMenu:
			menu = child
	_check(style != null and not style.enabled, "Cartoon-Stil ist zu Beginn aus")
	_check(_toon_count() == 0, "Zu Beginn kein Toon-Material (%d)" % _toon_count())
	_check(menu != null and not menu.visible, "Menü ist zu Beginn geschlossen")
	_touch(4, menu_center, true)
	_touch(4, menu_center, false)
	await _frames(2)
	_check(
		menu.visible and scene.get_tree().paused, "Menü-Knopf öffnet das Menü und hält das Spiel an"
	)
	Settings.update({"cartoon": true})
	await _frames(3)
	_check(style.enabled, "Einstellung schaltet den Cartoon-Stil ein")
	_check(_toon_count() > 50, "Toon-Material an Figur und Welt (%d Netze)" % _toon_count())
	_check(_visible_outlines() > 50, "Umrisse sichtbar (%d)" % _visible_outlines())
	Settings.update({"cartoon": false})
	await _frames(3)
	_check(not style.enabled, "Einstellung schaltet den Cartoon-Stil wieder aus")
	Settings.update({"sensitivity": 2.0})
	var rig_node: CameraRig = null
	for child in scene.get_children():
		if child is CameraRig:
			rig_node = child
	_check(
		is_equal_approx(rig_node.look_sensitivity, ControlsConfig.LOOK_DEG_PER_PX * 2.0),
		"Kamera übernimmt die Empfindlichkeit"
	)
	Settings.update({"sensitivity": 1.0})
	menu.close()
	_check(not scene.get_tree().paused, "Menü schließen setzt das Spiel fort")
	_check(_toon_count() == 0, "Nach dem Ausschalten kein Toon-Material mehr (%d)" % _toon_count())
	_check(
		_visible_outlines() == 0,
		"Nach dem Ausschalten keine sichtbaren Umrisse (%d)" % _visible_outlines()
	)

	print("Touch-Simulation: %s" % ("alles bestanden" if _failed == 0 else "%d Fehler" % _failed))
	get_tree().quit(1 if _failed > 0 else 0)


func _touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	_controls._input(event)


func _drag(index: int, position: Vector2, relative: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	event.relative = relative
	_controls._input(event)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok   ", description)
	else:
		_failed += 1
		printerr("  FEHLER ", description)


func _toon_count() -> int:
	var count := 0
	for node in _scene.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.material_override is ShaderMaterial and mi.name != "CartoonOutline":
			if not str(mi.name).ends_with("Umriss"):
				count += 1
				continue
		for i in mi.get_surface_override_material_count():
			if mi.get_surface_override_material(i) is ShaderMaterial:
				count += 1
				break
	return count


func _visible_outlines() -> int:
	var count := 0
	for node in _scene.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var is_outline := mi.name == "CartoonOutline" or str(mi.name).ends_with("Umriss")
		if is_outline and mi.visible:
			count += 1
	return count
