extends RefCounted
## Tests für die Figurdatei: enthält nur die Figur, keine Vorschau-Hilfsobjekte.


func run(t: Object) -> void:
	var packed := load("res://assets/characters/ninja/ninja.glb") as PackedScene
	t.check(packed != null, "ninja.glb lässt sich laden")
	if packed == null:
		return
	var root := packed.instantiate()
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	var names: Array[String] = []
	var biggest := Vector3.ZERO
	for node in meshes:
		var mi := node as MeshInstance3D
		names.append(str(mi.name))
		var size := mi.get_aabb().size
		biggest = Vector3(maxf(biggest.x, size.x), maxf(biggest.y, size.y), maxf(biggest.z, size.z))
	t.check(names.size() == 2, "genau zwei Netze (Figur und Umriss): %s" % [names])
	t.check(
		names.any(func(n: String) -> bool: return n.ends_with("Umriss") or n.contains("Umriss")),
		"Umriss-Netz vorhanden"
	)
	for n in names:
		t.check(
			not (n.contains("Boden") or n.contains("Marke") or n.contains("Kamera")),
			"kein Vorschau-Objekt in der Figur (%s)" % n
		)
	# Eine Figur von etwa 1,5 m darf keine große Fläche mitbringen
	t.check(biggest.x < 2.5 and biggest.z < 2.5, "Figur bleibt klein: %s" % [biggest])
	t.check(root.find_children("*", "Light3D", true, false).is_empty(), "kein Licht in der Figur")
	t.check(
		root.find_children("*", "Camera3D", true, false).is_empty(), "keine Kamera in der Figur"
	)
	root.free()
