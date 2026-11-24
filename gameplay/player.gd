class_name Player
extends CharacterBody3D
## Spielfigur (Platzhalter aus Grundformen). Läuft relativ zur Kamera, springt und schleicht.

@export var camera_rig: CameraRig

var _move_input := Vector2.ZERO
var _sneaking := false
var _jump_buffer := 0.0
var _spawn := Vector3.ZERO
var _model: Node3D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	_spawn = global_position
	_build_collision()
	_build_model()
	EventBus.move_input.connect(func(v: Vector2) -> void: _move_input = v)
	EventBus.jump_pressed.connect(func() -> void: _jump_buffer = ControlsConfig.JUMP_BUFFER_SECONDS)
	EventBus.sneak_changed.connect(_on_sneak_changed)


func _physics_process(delta: float) -> void:
	var yaw := camera_rig.yaw_rad() if camera_rig != null else 0.0
	var direction := MovementMath.world_direction(_move_input, yaw)
	var speed := MovementMath.target_speed(_move_input.length(), _sneaking)
	var wanted := direction.normalized() * speed if direction.length() > 0.001 else Vector3.ZERO

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = MovementMath.accelerate(horizontal, wanted, ControlsConfig.ACCELERATION, delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	_jump_buffer = maxf(_jump_buffer - delta, 0.0)
	if is_on_floor():
		velocity.y = 0.0
		if _jump_buffer > 0.0:
			velocity.y = ControlsConfig.JUMP_SPEED
			_jump_buffer = 0.0
	else:
		velocity.y -= ControlsConfig.GRAVITY * delta

	move_and_slide()

	if horizontal.length() > 0.2:
		var target_yaw := MovementMath.facing_yaw(horizontal)
		_model.rotation.y = MovementMath.turn_toward(
			_model.rotation.y, target_yaw, ControlsConfig.TURN_SPEED * delta
		)
	if global_position.y < ControlsConfig.FALL_RESET_Y:
		global_position = _spawn
		velocity = Vector3.ZERO


func _on_sneak_changed(active: bool) -> void:
	_sneaking = active
	if _model != null:
		_model.scale.y = 0.82 if active else 1.0


func _build_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.7
	var body := CollisionShape3D.new()
	body.shape = shape
	body.position.y = 0.85
	add_child(body)


## Platzhalterfigur: dunkler Körper mit Kapuze, rotem Schal und Schwert auf dem Rücken.
## Blickrichtung ist -Z. Wird später durch ein richtiges Modell ersetzt.
func _build_model() -> void:
	_model = Node3D.new()
	add_child(_model)
	var cloth := _material(Color(0.07, 0.08, 0.11), 0.9)
	var scarf := _material(Color(0.7, 0.12, 0.1), 0.8)
	var skin := _material(Color(0.82, 0.68, 0.55), 0.7)
	var steel := _material(Color(0.5, 0.52, 0.56), 0.4)

	var torso := CapsuleMesh.new()
	torso.radius = 0.3
	torso.height = 1.4
	_add_part(torso, cloth, Vector3(0, 0.8, 0), Vector3.ZERO)

	var head := SphereMesh.new()
	head.radius = 0.22
	head.height = 0.44
	_add_part(head, cloth, Vector3(0, 1.68, 0), Vector3.ZERO)

	var eyes := BoxMesh.new()
	eyes.size = Vector3(0.3, 0.07, 0.06)
	_add_part(eyes, skin, Vector3(0, 1.7, -0.19), Vector3.ZERO)

	var neck := BoxMesh.new()
	neck.size = Vector3(0.5, 0.12, 0.5)
	_add_part(neck, scarf, Vector3(0, 1.42, 0), Vector3.ZERO)

	var tail := BoxMesh.new()
	tail.size = Vector3(0.16, 0.08, 0.7)
	_add_part(tail, scarf, Vector3(0.1, 1.38, 0.5), Vector3(-12, 0, 0))

	var sword := BoxMesh.new()
	sword.size = Vector3(0.06, 0.06, 1.0)
	_add_part(sword, steel, Vector3(0.0, 1.0, 0.36), Vector3(0, 0, 35))


func _add_part(mesh: Mesh, material: Material, pos: Vector3, rot_deg: Vector3) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	instance.position = pos
	instance.rotation_degrees = rot_deg
	_model.add_child(instance)


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material
