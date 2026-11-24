class_name Player
extends CharacterBody3D
## Spielfigur. Läuft relativ zur Kamera, springt und schleicht; das Modell stammt aus
## `assets/characters/ninja` (erzeugt mit `tools/blender/build_ninja.py`).

const MODEL_PATH := "res://assets/characters/ninja/ninja.glb"

@export var camera_rig: CameraRig

var _move_input := Vector2.ZERO
var _sneaking := false
var _jump_buffer := 0.0
var _spawn := Vector3.ZERO
var _model: Node3D
var _flip_pivot: Node3D
var _flip := FlipLogic.new()
var _animation: AnimationPlayer
var _air_time := 0.0
var _land_left := 0.0
var _was_airborne := false


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
			_flip.start()
			_jump_buffer = 0.0
	else:
		velocity.y -= ControlsConfig.GRAVITY * delta

	move_and_slide()
	_update_animation(delta, horizontal.length())
	_update_flip(delta)

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


## Steht die Figur still (am Boden, ohne Eingabe und praktisch ohne Geschwindigkeit)?
func is_at_rest() -> bool:
	return is_on_floor() and _move_input.length() < 0.01 and velocity.length() < 0.1


## Name der laufenden Animation (für Tests).
func current_animation() -> StringName:
	return _animation.current_animation if _animation != null else &""


func _build_collision() -> void:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.45
	var body := CollisionShape3D.new()
	body.shape = shape
	body.position.y = 0.725
	add_child(body)


func _build_model() -> void:
	_model = Node3D.new()
	add_child(_model)
	var packed := load(MODEL_PATH) as PackedScene
	if packed == null:
		push_warning("Spielfigur nicht gefunden: %s" % MODEL_PATH)
		return
	# Drehpunkt in Körpermitte für den Salto; das Modell sitzt darunter und wird zurückversetzt
	_flip_pivot = Node3D.new()
	_flip_pivot.position.y = ControlsConfig.FLIP_CENTER_Y
	_model.add_child(_flip_pivot)
	var instance := packed.instantiate()
	instance.position.y = -ControlsConfig.FLIP_CENTER_Y
	_flip_pivot.add_child(instance)
	_animation = instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _animation != null:
		_animation.play(AnimationLogic.IDLE)


## Salto vorwärts: dreht das Modell um die Körpermitte. Die Figur schaut nach -Z, vorwärts
## heißt also negative Drehung um X (der Kopf kippt nach -Z).
func _update_flip(delta: float) -> void:
	_flip.step(delta, is_on_floor())
	if _flip_pivot != null:
		_flip_pivot.rotation.x = -deg_to_rad(_flip.angle_deg)


## Aktueller Salto-Winkel in Grad (für Tests).
func flip_angle_deg() -> float:
	return -rad_to_deg(_flip_pivot.rotation.x) if _flip_pivot != null else 0.0


## Wie weit der Kopf nach vorn (Blickrichtung des Modells) zeigt: -1 bis 1 (für Tests).
func head_forward() -> float:
	return -_flip_pivot.transform.basis.y.z if _flip_pivot != null else 0.0


## Dreht die Figur gerade einen Salto (für Tests)?
func is_flipping() -> bool:
	return _flip.active


func _update_animation(delta: float, speed: float) -> void:
	var on_floor := is_on_floor()
	if on_floor:
		if _was_airborne and AnimationLogic.should_land(_air_time, speed):
			_land_left = AnimationLogic.LAND_SECONDS
		_was_airborne = false
		_air_time = 0.0
	else:
		_was_airborne = true
		_air_time += delta
	if _animation == null:
		return
	var clip := AnimationLogic.pick(
		on_floor, velocity.y, speed, _sneaking, _air_time, _land_left, _flip.active
	)
	_land_left = maxf(_land_left - delta, 0.0)
	if _animation.current_animation != clip:
		_animation.play(clip, 0.15)
	_animation.speed_scale = AnimationLogic.playback_speed(clip, speed)
	if clip == AnimationLogic.FLIP:
		# Clip über genau die Dauer des Salto-Winkels spielen
		_animation.speed_scale = _animation.get_animation(clip).length / ControlsConfig.FLIP_SECONDS
