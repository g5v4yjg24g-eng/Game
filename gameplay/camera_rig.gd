class_name CameraRig
extends Node3D
## Kamera hinter der Figur. Folgt weich, wird per Wischen gedreht und weicht Hindernissen aus.

@export var target: Node3D

## Empfindlichkeit in Grad pro Pixel; kommt aus den Einstellungen.
var look_sensitivity := ControlsConfig.LOOK_DEG_PER_PX
var yaw_deg := 0.0
var pitch_deg := ControlsConfig.START_PITCH_DEG

var _arm: SpringArm3D
var _camera: Camera3D
var _idle := IdleCamera.new()


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
	_take_settings()
	Settings.changed.connect(_take_settings)
	# Jede Eingabe setzt den Stillstands-Schwenk zurück
	EventBus.activity.connect(_idle.notify_activity)
	EventBus.jump_pressed.connect(_idle.notify_activity)
	EventBus.sneak_changed.connect(func(_on: bool) -> void: _idle.notify_activity())
	EventBus.move_input.connect(
		func(v: Vector2) -> void:
			if v.length() > 0.01:
				_idle.notify_activity()
	)
	_apply_rotation()


func _process(delta: float) -> void:
	if target == null:
		return
	var at_rest: bool = target.has_method("is_at_rest") and target.is_at_rest()
	var orbit := _idle.update(delta, at_rest)
	if orbit > 0.0:
		yaw_deg = wrapf(yaw_deg + orbit * delta, -180.0, 180.0)
	var goal := _target_position()
	global_position = global_position.lerp(
		goal, 1.0 - exp(-ControlsConfig.CAMERA_FOLLOW_SPEED * delta)
	)
	_apply_rotation()


## Blickrichtung (Gier) im Bogenmaß, für die Bewegung relativ zur Kamera.
func yaw_rad() -> float:
	return deg_to_rad(yaw_deg)


## Wie stark die Kamera gerade im Stillstand schwenkt (0 bis 1, für Tests).
func idle_strength() -> float:
	return _idle.strength


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
	var look := CameraMath.apply_look(yaw_deg, pitch_deg, drag, look_sensitivity)
	yaw_deg = look.x
	pitch_deg = look.y


func _take_settings() -> void:
	look_sensitivity = Settings.data.look_deg_per_px()
