class_name CameraRig
extends Node3D
## Kamera hinter der Figur. Folgt weich, wird per Wischen gedreht und weicht Hindernissen aus.

@export var target: Node3D

var yaw_deg := 0.0
var pitch_deg := ControlsConfig.START_PITCH_DEG

var _arm: SpringArm3D
var _camera: Camera3D


func _ready() -> void:
	# Die Kamera folgt der berechneten (geglätteten) Figurposition selbst und
	# braucht keine zusätzliche Glättung der Physik.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_arm = SpringArm3D.new()
	_arm.spring_length = ControlsConfig.CAMERA_DISTANCE
	_arm.collision_mask = 1
	_arm.margin = 0.25
	add_child(_arm)
	_camera = Camera3D.new()
	_camera.fov = 70.0
	_camera.near = 0.1
	_camera.far = 300.0
	_arm.add_child(_camera)
	_camera.make_current()
	EventBus.look_input.connect(_on_look_input)
	_apply_rotation()


func _process(delta: float) -> void:
	if target == null:
		return
	var goal := _target_position()
	global_position = global_position.lerp(
		goal, 1.0 - exp(-ControlsConfig.CAMERA_FOLLOW_SPEED * delta)
	)
	_apply_rotation()


## Blickrichtung (Gier) im Bogenmaß, für die Bewegung relativ zur Kamera.
func yaw_rad() -> float:
	return deg_to_rad(yaw_deg)


## Weltposition der Kamera (für Tests und Effekte).
func camera_position() -> Vector3:
	return _camera.global_position


## Setzt die Kamera sofort hinter das Ziel (ohne Gleiten).
func snap() -> void:
	if target != null:
		global_position = _target_position()
	_apply_rotation()


func _target_position() -> Vector3:
	return (
		target.get_global_transform_interpolated().origin
		+ Vector3(0.0, ControlsConfig.CAMERA_HEIGHT, 0.0)
	)


func _apply_rotation() -> void:
	rotation_degrees = Vector3(pitch_deg, yaw_deg, 0.0)


func _on_look_input(drag: Vector2) -> void:
	var look := CameraMath.apply_look(yaw_deg, pitch_deg, drag)
	yaw_deg = look.x
	pitch_deg = look.y
