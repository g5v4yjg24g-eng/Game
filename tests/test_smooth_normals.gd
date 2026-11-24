extends RefCounted
## Tests für world/style/smooth_normals.gd


func run(t: Object) -> void:
	# Zwei Eckpunkte an derselben Stelle mit verschiedenen Normalen (Quaderecke)
	var verts := PackedVector3Array([Vector3(1, 1, 1), Vector3(1, 1, 1), Vector3(1, 1, 1)])
	var normals := PackedVector3Array([Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)])
	var result := SmoothNormals.average(verts, normals)
	var diagonal := Vector3(1, 1, 1).normalized()
	t.check(result.size() == 3, "ein Ergebnis je Eckpunkt")
	t.check(
		result[0].is_equal_approx(diagonal) and result[2].is_equal_approx(diagonal),
		"Quaderecke: alle drei Normalen werden zur Diagonale"
	)
	t.check(is_equal_approx(result[0].length(), 1.0), "Ergebnis ist normalisiert")

	# Verschiedene Stellen bleiben unverändert
	var apart := SmoothNormals.average(
		PackedVector3Array([Vector3(0, 0, 0), Vector3(2, 0, 0)]),
		PackedVector3Array([Vector3(0, 1, 0), Vector3(0, 0, 1)])
	)
	t.check(
		apart[0].is_equal_approx(Vector3(0, 1, 0)) and apart[1].is_equal_approx(Vector3(0, 0, 1)),
		"getrennte Eckpunkte behalten ihre Normale"
	)

	# Fast gleiche Stellen (Rundungsrauschen) gelten als gleich
	var noisy := SmoothNormals.average(
		PackedVector3Array([Vector3(1, 1, 1), Vector3(1.00002, 1, 0.99998)]),
		PackedVector3Array([Vector3(1, 0, 0), Vector3(0, 1, 0)])
	)
	t.check(noisy[0].is_equal_approx(noisy[1]), "Rundungsrauschen wird zusammengefasst")

	# Gegenläufige Normalen löschen sich aus: die ursprüngliche Normale bleibt (kein Nullvektor)
	var opposite := SmoothNormals.average(
		PackedVector3Array([Vector3.ZERO, Vector3.ZERO]),
		PackedVector3Array([Vector3(1, 0, 0), Vector3(-1, 0, 0)])
	)
	t.check(opposite[0].length() > 0.99, "gegenläufige Normalen ergeben keinen Nullvektor")

	# Echtes Netz: ein Würfel hat nach dem Mitteln an jeder Ecke eine Diagonalnormale
	var cube := BoxMesh.new()
	var arrays := cube.surface_get_arrays(0)
	var smoothed := SmoothNormals.average(arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_NORMAL])
	var all_diagonal := true
	for n in smoothed:
		for component in [n.x, n.y, n.z]:
			if absf(absf(component) - 0.57735) > 0.001:
				all_diagonal = false
	t.check(all_diagonal, "BoxMesh: alle Ecken zeigen nach außen diagonal")
