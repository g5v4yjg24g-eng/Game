extends RefCounted
## Tests für gameplay/animation_logic.gd


func run(t: Object) -> void:
	t.check(AnimationLogic.pick(true, 0, 0, false, 0, 0) == AnimationLogic.IDLE, "Stehen: idle")
	t.check(
		AnimationLogic.pick(true, 0, ControlsConfig.RUN_SPEED, false, 0, 0) == AnimationLogic.RUN,
		"Laufen: run"
	)
	t.check(
		(
			AnimationLogic.pick(true, 0, ControlsConfig.SNEAK_SPEED, true, 0, 0)
			== AnimationLogic.SNEAK
		),
		"Schleichen: sneak"
	)
	t.check(
		AnimationLogic.pick(true, 0, 0, true, 0, 0) == AnimationLogic.SNEAK_IDLE,
		"geduckt stehen: sneak_idle"
	)
	t.check(
		AnimationLogic.pick(true, 0, 0.2, false, 0, 0) == AnimationLogic.IDLE,
		"kaum Tempo gilt als Stehen"
	)

	t.check(
		AnimationLogic.pick(false, 7.0, 0, false, 0.05, 0) == AnimationLogic.JUMP, "Absprung: jump"
	)
	t.check(
		AnimationLogic.pick(false, 3.0, 0, false, 0.5, 0) == AnimationLogic.FALL,
		"nach der Sprunganimation: fall"
	)
	t.check(
		AnimationLogic.pick(false, -4.0, 0, false, 0.3, 0) == AnimationLogic.FALL, "Fallen: fall"
	)
	t.check(
		AnimationLogic.pick(false, -0.5, 5.0, false, 0.03, 0) == AnimationLogic.RUN,
		"kurz nach dem Verlassen des Bodens (Rampe): weiter run"
	)
	t.check(
		AnimationLogic.pick(false, -2.0, 5.0, false, 0.2, 0) == AnimationLogic.FALL,
		"von der Kante: fall"
	)

	t.check(AnimationLogic.pick(true, 0, 0, false, 0, 0.2) == AnimationLogic.LAND, "Landen: land")
	t.check(AnimationLogic.should_land(0.6, 0.5), "nach langem Flug im Stand: Landeanimation")
	t.check(not AnimationLogic.should_land(0.1, 0.5), "kurzer Hüpfer: keine Landeanimation")
	t.check(not AnimationLogic.should_land(0.6, 6.0), "Landen im Lauf: keine Landeanimation")

	t.check(
		is_equal_approx(
			AnimationLogic.playback_speed(AnimationLogic.RUN, ControlsConfig.RUN_SPEED), 1.0
		),
		"Lauftempo: Faktor 1"
	)
	t.check(
		AnimationLogic.playback_speed(AnimationLogic.RUN, 1.0) >= 0.45,
		"Laufen langsam: nicht zu langsam"
	)
	t.check(
		AnimationLogic.playback_speed(AnimationLogic.RUN, 20.0) <= 1.15, "Laufen schnell: begrenzt"
	)
	t.check(
		is_equal_approx(
			AnimationLogic.playback_speed(AnimationLogic.SNEAK, ControlsConfig.SNEAK_SPEED), 1.0
		),
		"Schleichtempo: Faktor 1"
	)
	t.check(
		is_equal_approx(AnimationLogic.playback_speed(AnimationLogic.IDLE, 0.0), 1.0),
		"Stehen: Faktor 1"
	)

	# Laufzyklus: Entwurfstempo im Blender-Skript muss zum Spiel passen, sonst rutschen die Füße
	var script_text := FileAccess.get_file_as_string("res://tools/blender/build_ninja.py")
	var regex := RegEx.create_from_string("(?m)^RUN_SPEED = ([0-9.]+)")
	var found := regex.search(script_text)
	t.check(found != null, "Blender-Skript nennt das Entwurfstempo RUN_SPEED")
	if found != null:
		t.check(
			is_equal_approx(found.get_string(1).to_float(), ControlsConfig.RUN_SPEED),
			"Entwurfstempo im Blender-Skript (%s) = RUN_SPEED im Spiel" % found.get_string(1)
		)

	# Importierte Animationen: Namen, Wiederholung und Länge des Laufzyklus
	var model := (load("res://assets/characters/ninja/ninja.glb") as PackedScene).instantiate()
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	t.check(player != null, "Modell enthält einen AnimationPlayer")
	if player != null:
		for clip in [&"idle", &"run", &"sneak", &"sneak_idle", &"jump", &"fall", &"land"]:
			t.check(player.has_animation(clip), "Animation '%s' ist im Modell" % clip)
		var run_clip := player.get_animation(&"run")
		t.check(run_clip.loop_mode == Animation.LOOP_LINEAR, "run wiederholt sich")
		var frames := RegEx.create_from_string("(?m)^RUN_FRAMES = ([0-9]+)").search(script_text)
		t.check(frames != null, "Blender-Skript nennt RUN_FRAMES")
		if frames != null:
			var expected := frames.get_string(1).to_float() / 30.0
			t.check(
				absf(run_clip.length - expected) < 0.01,
				(
					"run dauert RUN_FRAMES Bilder (%.3f s, erwartet %.3f s)"
					% [run_clip.length, expected]
				)
			)
		t.check(player.get_animation(&"jump").loop_mode == Animation.LOOP_NONE, "jump läuft einmal")
	model.free()
