extends SceneTree
## Einfacher Testläufer ohne Fremdabhängigkeit.
## Aufruf: godot --headless --path . --script res://tests/run_tests.gd
## Neue Testdateien (tests/test_*.gd) werden automatisch gefunden. Jede Datei hat
## eine Methode `run(t: Object)`; `t.check(bedingung, "Beschreibung")` meldet Ergebnisse.

var _failed := 0
var _passed := 0


func _init() -> void:
	var dir := DirAccess.open("res://tests")
	var files: Array[String] = []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(f)
	files.sort()
	for f in files:
		print("== ", f)
		var script: GDScript = load("res://tests/" + f)
		script.new().run(self)
	print("Ergebnis: %d bestanden, %d fehlgeschlagen" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("  ok   ", description)
	else:
		_failed += 1
		printerr("  FEHLER ", description)
