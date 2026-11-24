extends RefCounted
## Tests für gameplay/animation_logic.gd


func run(t: Object) -> void:
	t.check(AnimationLogic.pick(true, 0, 0, false, 0, 0) == AnimationLogic.IDLE, "Stehen: idle")
	t.check(AnimationLogic.pick(true, 0, 6.5, false, 0, 0) == AnimationLogic.RUN, "Laufen: run")
	t.check(
		AnimationLogic.pick(true, 0, 2.4, true, 0, 0) == AnimationLogic.SNEAK, "Schleichen: sneak"
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
		is_equal_approx(AnimationLogic.playback_speed(AnimationLogic.RUN, 6.5), 1.0),
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
		is_equal_approx(AnimationLogic.playback_speed(AnimationLogic.SNEAK, 2.4), 1.0),
		"Schleichtempo: Faktor 1"
	)
	t.check(
		is_equal_approx(AnimationLogic.playback_speed(AnimationLogic.IDLE, 0.0), 1.0),
		"Stehen: Faktor 1"
	)
