extends RefCounted
## Tests für core/settings_data.gd


func run(t: Object) -> void:
	var defaults := SettingsData.from_dict({})
	t.check(is_equal_approx(defaults.sensitivity, 1.0), "Standard: Empfindlichkeit 1,0")
	t.check(defaults.max_fps == 120, "Standard: 120 fps")
	t.check(not defaults.cartoon, "Standard: Cartoon-Stil aus")

	var low := SettingsData.from_dict({"sensitivity": 0.01})
	var high := SettingsData.from_dict({"sensitivity": 99})
	t.check(
		is_equal_approx(low.sensitivity, SettingsData.SENSITIVITY_MIN),
		"Empfindlichkeit nach unten begrenzt"
	)
	t.check(
		is_equal_approx(high.sensitivity, SettingsData.SENSITIVITY_MAX),
		"Empfindlichkeit nach oben begrenzt"
	)
	t.check(
		is_equal_approx(SettingsData.from_dict({"sensitivity": 1.5}).sensitivity, 1.5),
		"gültige Empfindlichkeit bleibt"
	)

	t.check(SettingsData.from_dict({"max_fps": 60}).max_fps == 60, "60 fps wird übernommen")
	t.check(
		SettingsData.from_dict({"max_fps": 45}).max_fps == 30, "45 fps wird zum nächsten Wert (30)"
	)
	t.check(
		SettingsData.from_dict({"max_fps": 90}).max_fps == 60, "90 fps wird zum nächsten Wert (60)"
	)
	t.check(SettingsData.from_dict({"max_fps": 999}).max_fps == 120, "999 fps wird 120")
	t.check(SettingsData.from_dict({"max_fps": 60.4}).max_fps == 60, "Kommazahl wird gerundet")

	# Ungültige Typen und Werte fallen auf Standard zurück, nichts stürzt ab
	var broken := SettingsData.from_dict(
		{"sensitivity": "viel", "max_fps": null, "cartoon": "ja", "unbekannt": 5}
	)
	t.check(
		is_equal_approx(broken.sensitivity, 1.0) and broken.max_fps == 120 and not broken.cartoon,
		"falsche Typen ergeben Standardwerte"
	)
	t.check(
		is_equal_approx(SettingsData.from_dict({"sensitivity": NAN}).sensitivity, 1.0),
		"NaN ergibt Standardwert"
	)
	t.check(SettingsData.from_dict({"cartoon": true}).cartoon, "Cartoon-Stil an wird übernommen")

	# Hin und zurück
	var original := SettingsData.from_dict({"sensitivity": 1.7, "max_fps": 30, "cartoon": true})
	var again := SettingsData.from_dict(original.to_dict())
	t.check(
		is_equal_approx(again.sensitivity, 1.7) and again.max_fps == 30 and again.cartoon,
		"Wörterbuch und zurück ergibt dieselben Werte"
	)

	# Kamera-Empfindlichkeit in Grad pro Pixel
	t.check(
		is_equal_approx(defaults.look_deg_per_px(), ControlsConfig.LOOK_DEG_PER_PX),
		"Standard-Empfindlichkeit entspricht der Vorgabe"
	)
	t.check(
		is_equal_approx(original.look_deg_per_px(), ControlsConfig.LOOK_DEG_PER_PX * 1.7),
		"Empfindlichkeit wirkt als Faktor"
	)
