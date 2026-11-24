class_name CartoonStyle
extends Node
## Schaltet die Cartoon-Darstellung ein und aus (Entscheidung Nutzer 2026-11-24: Cartoon-Stil für
## das ganze Spiel). Aus: Materialien der Szene unverändert. An: flächige Schattierung
## (`toon.gdshader`) und dicke dunkle Umrisse (`outline.gdshader`). Der Zustand kommt über
## `EventBus.style_changed`. Die Figur bringt ihr Umriss-Mesh mit ("…Umriss"); statische Teile
## bekommen ein Umriss-Netz mit gemittelten Normalen als Kind. Vorbereitung (Phase 3c): Standard
## ist aus, bis der Stil am Gerät geprüft ist.

const TOON_SHADER := preload("res://assets/shaders/toon.gdshader")
const OUTLINE_SHADER := preload("res://assets/shaders/outline.gdshader")
## Umrisse weiter weg als so viele Meter werden nicht gezeichnet (spart Draw Calls).
const OUTLINE_RANGE := 45.0
## Metadaten-Schlüssel an Knoten, die keinen Umriss bekommen sollen (Boden, Wege).
const NO_OUTLINE := &"no_outline"
const OUTLINE_CHILD := "CartoonOutline"
const ORIGINAL_META := &"cartoon_original_override"

## Wurzel, unter der alle Netze umgestellt werden.
@export var root: Node

var enabled := false

var _toon_cache: Dictionary = {}
var _outline_material: ShaderMaterial


func _ready() -> void:
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = OUTLINE_SHADER
	EventBus.style_changed.connect(set_enabled)
	if root == null:
		root = get_parent()
	# Figur-Umrisse sind im Modell enthalten und müssen im Ausgangszustand verborgen sein.
	_apply(false)


func set_enabled(on: bool) -> void:
	if on == enabled:
		return
	enabled = on
	_apply(on)


func _apply(on: bool) -> void:
	if root == null:
		return
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if _is_outline(mi):
			continue
		_apply_materials(mi, on)
		if mi.get_meta(NO_OUTLINE, false):
			continue
		if mi.skin != null:
			continue  # Umriss kommt mit dem Modell (siehe unten)
		_apply_static_outline(mi, on)
	for node in root.find_children("*Umriss", "MeshInstance3D", true, false):
		var outline := node as MeshInstance3D
		outline.material_override = _outline_material if on else null
		outline.visible = on
		outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _apply_materials(mi: MeshInstance3D, on: bool) -> void:
	if mi.mesh == null:
		return
	# Netze mit eigenem `material_override` (Testwelt): Original merken und wiederherstellen.
	if mi.material_override != null or mi.has_meta(ORIGINAL_META):
		if on:
			if not mi.has_meta(ORIGINAL_META):
				mi.set_meta(ORIGINAL_META, mi.material_override)
			var base := mi.get_meta(ORIGINAL_META) as Material
			var toon := _toon_for(base)
			mi.material_override = toon if toon != null else base
		elif mi.has_meta(ORIGINAL_META):
			mi.material_override = mi.get_meta(ORIGINAL_META) as Material
			mi.remove_meta(ORIGINAL_META)
		return
	# Netze mit Materialien an den Flächen (Figur aus der .glb): Überschreibung je Fläche.
	for i in mi.mesh.get_surface_count():
		if on:
			mi.set_surface_override_material(i, _toon_for(mi.mesh.surface_get_material(i)))
		else:
			mi.set_surface_override_material(i, null)


func _toon_for(base: Material) -> ShaderMaterial:
	if not base is BaseMaterial3D:
		return null
	if _toon_cache.has(base):
		return _toon_cache[base]
	var toon := ShaderMaterial.new()
	toon.shader = TOON_SHADER
	toon.set_shader_parameter("albedo", (base as BaseMaterial3D).albedo_color)
	_toon_cache[base] = toon
	return toon


func _apply_static_outline(mi: MeshInstance3D, on: bool) -> void:
	var outline := mi.get_node_or_null(OUTLINE_CHILD) as MeshInstance3D
	if outline == null:
		if not on or mi.mesh == null:
			return
		outline = MeshInstance3D.new()
		outline.name = OUTLINE_CHILD
		outline.mesh = _smoothed_copy(mi.mesh)
		outline.material_override = _outline_material
		outline.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		outline.visibility_range_end = OUTLINE_RANGE
		mi.add_child(outline)
	outline.visible = on


func _is_outline(mi: MeshInstance3D) -> bool:
	return mi.name == OUTLINE_CHILD or str(mi.name).ends_with("Umriss")


## Kopie des Netzes mit gemittelten Normalen (geschlossene Hülle für den Umriss).
func _smoothed_copy(source: Mesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	for i in source.get_surface_count():
		var arrays := source.surface_get_arrays(i)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		if normals.size() == vertices.size():
			arrays[Mesh.ARRAY_NORMAL] = SmoothNormals.average(vertices, normals)
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result
