class_name TestWorld
extends Node3D
## Testgelände für den Prototyp: Abendstimmung, Nebel, Torii, Hütte, Plattformen, Bäume.
## Wird aus Code gebaut (Platzhalter ohne Fremd-Assets). Kollisionsebene 1 = Welt.

var _rng := RandomNumberGenerator.new()
var _materials: Dictionary = {}


func _ready() -> void:
	_rng.seed = 20261124
	_build_environment()
	_build_ground()
	_build_path()
	_build_torii(Vector3(0, 0, -14))
	_build_hut(Vector3(-13, 0, -6))
	_build_platforms()
	_build_ramp(Vector3(-10, 0, 8))
	_build_trees(34)


func _build_environment() -> void:
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.13, 0.17, 0.32)
	sky_material.sky_horizon_color = Color(0.92, 0.55, 0.38)
	sky_material.ground_horizon_color = Color(0.92, 0.55, 0.38)
	sky_material.ground_bottom_color = Color(0.1, 0.1, 0.14)
	var sky := Sky.new()
	sky.sky_material = sky_material

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_energy = 0.7
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.78, 0.6, 0.55)
	environment.fog_density = 0.012
	environment.fog_sky_affect = 0.35

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-16.0, -35.0, 0.0)
	sun.light_color = Color(1.0, 0.72, 0.5)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)


func _build_ground() -> void:
	_add_box(
		Vector3(0, -0.5, 0), Vector3(140, 1, 140), _material("moss", Color(0.2, 0.27, 0.15), 1.0)
	)


## Heller Weg vom Start zum Torii (nur Optik, keine Kollision).
func _build_path() -> void:
	var stone := _material("path", Color(0.45, 0.4, 0.34), 1.0)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(3.0, 0.04, 30.0)
	var strip := MeshInstance3D.new()
	strip.mesh = mesh
	strip.material_override = stone
	strip.position = Vector3(0, 0.02, -2.0)
	strip.set_meta(CartoonStyle.NO_OUTLINE, true)
	add_child(strip)


func _build_torii(origin: Vector3) -> void:
	var red := _material("lacquer", Color(0.62, 0.1, 0.08), 0.6)
	var black := _material("beam", Color(0.08, 0.07, 0.08), 0.7)
	for side: float in [-2.2, 2.2]:
		_add_cylinder(origin + Vector3(side, 3.0, 0), 0.3, 6.0, red)
	_add_box(origin + Vector3(0, 4.7, 0), Vector3(5.6, 0.3, 0.4), red, false)
	_add_box(origin + Vector3(0, 6.15, 0), Vector3(7.6, 0.5, 0.7), black, false)
	var lantern := OmniLight3D.new()
	lantern.position = origin + Vector3(0, 3.0, 2.0)
	lantern.light_color = Color(1.0, 0.65, 0.35)
	lantern.light_energy = 1.2
	lantern.omni_range = 9.0
	add_child(lantern)


func _build_hut(origin: Vector3) -> void:
	_add_box(
		origin + Vector3(0, 1.5, 0), Vector3(5, 3, 4), _material("wood", Color(0.3, 0.2, 0.13), 0.9)
	)
	var roof := PrismMesh.new()
	roof.size = Vector3(6.6, 1.8, 5.2)
	var roof_instance := MeshInstance3D.new()
	roof_instance.mesh = roof
	roof_instance.material_override = _material("tile", Color(0.14, 0.14, 0.17), 0.8)
	roof_instance.position = origin + Vector3(0, 3.9, 0)
	add_child(roof_instance)
	var lantern := OmniLight3D.new()
	lantern.position = origin + Vector3(2.8, 2.0, 2.6)
	lantern.light_color = Color(1.0, 0.65, 0.35)
	lantern.light_energy = 1.0
	lantern.omni_range = 7.0
	add_child(lantern)


## Zwei Plattformen zum Üben des Springens (0,5 m und 1,0 m hoch).
func _build_platforms() -> void:
	var stone := _material("platform", Color(0.36, 0.35, 0.37), 0.9)
	_add_box(Vector3(10, 0.25, 4), Vector3(3, 0.5, 3), stone)
	_add_box(Vector3(13, 0.5, 4), Vector3(3, 1.0, 3), stone)
	_add_box(Vector3(10, 0.75, 8), Vector3(3, 1.5, 1), stone)


func _build_ramp(center: Vector3) -> void:
	var wood := _material("ramp", Color(0.4, 0.3, 0.2), 0.9)
	var ramp := _add_box(center + Vector3(0, 0.55, 0), Vector3(6, 0.3, 4), wood)
	ramp.rotation_degrees = Vector3(0, 0, -12)


func _build_trees(count: int) -> void:
	var trunk := _material("trunk", Color(0.2, 0.14, 0.1), 1.0)
	var leaves := [
		_material("leaf_red", Color(0.62, 0.18, 0.1), 0.9),
		_material("leaf_orange", Color(0.78, 0.4, 0.12), 0.9),
		_material("leaf_green", Color(0.2, 0.34, 0.16), 0.9),
	]
	for i in count:
		var angle := _rng.randf() * TAU
		var radius := _rng.randf_range(16.0, 55.0)
		var pos := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		var body := StaticBody3D.new()
		body.position = pos
		add_child(body)
		var shape := CylinderShape3D.new()
		shape.radius = 0.35
		shape.height = 4.0
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.position.y = 2.0
		body.add_child(collider)
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.25
		trunk_mesh.bottom_radius = 0.38
		trunk_mesh.height = 4.0
		trunk_mesh.radial_segments = 8
		var trunk_instance := MeshInstance3D.new()
		trunk_instance.mesh = trunk_mesh
		trunk_instance.material_override = trunk
		trunk_instance.position.y = 2.0
		body.add_child(trunk_instance)
		var crown_mesh := CylinderMesh.new()
		crown_mesh.top_radius = 0.0
		crown_mesh.bottom_radius = _rng.randf_range(1.8, 2.6)
		crown_mesh.height = _rng.randf_range(3.5, 5.0)
		crown_mesh.radial_segments = 10
		var crown := MeshInstance3D.new()
		crown.mesh = crown_mesh
		crown.material_override = leaves[_rng.randi() % leaves.size()]
		crown.position.y = 4.0 + crown_mesh.height * 0.4
		body.add_child(crown)


func _add_box(pos: Vector3, size: Vector3, material: Material, solid: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	body.add_child(instance)
	if solid:
		var shape := BoxShape3D.new()
		shape.size = size
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
	add_child(body)
	return body


func _add_cylinder(pos: Vector3, radius: float, height: float, material: Material) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	body.add_child(instance)
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)


func _material(key: String, color: Color, roughness: float) -> StandardMaterial3D:
	if _materials.has(key):
		return _materials[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	_materials[key] = material
	return material
