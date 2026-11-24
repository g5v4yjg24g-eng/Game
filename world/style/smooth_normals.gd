class_name SmoothNormals
extends RefCounted
## Mittelt die Normalen aller Eckpunkte, die an derselben Stelle liegen.
## Ein Quader hat an jeder Ecke drei Eckpunkte mit drei verschiedenen Normalen. Für einen Umriss,
## der entlang der Normalen aufgebläht wird, reißt das Netz dort auf. Mit gemittelten Normalen
## bleibt die Hülle geschlossen. Reine Logik, wird in `tests/` geprüft.


## Liefert je Eckpunkt die gemittelte, normalisierte Normale aller Eckpunkte an seiner Stelle.
static func average(
	vertices: PackedVector3Array, normals: PackedVector3Array, precision: float = 0.0001
) -> PackedVector3Array:
	var sums := {}
	for i in vertices.size():
		var key := _key(vertices[i], precision)
		sums[key] = sums.get(key, Vector3.ZERO) + normals[i]
	var result := PackedVector3Array()
	result.resize(vertices.size())
	for i in vertices.size():
		var sum: Vector3 = sums[_key(vertices[i], precision)]
		result[i] = sum.normalized() if sum.length_squared() > 0.000001 else normals[i]
	return result


static func _key(v: Vector3, precision: float) -> Vector3i:
	return Vector3i(roundi(v.x / precision), roundi(v.y / precision), roundi(v.z / precision))
