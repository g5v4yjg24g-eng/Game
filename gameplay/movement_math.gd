class_name MovementMath
extends RefCounted
## Bewegungsrechnung ohne Szenenzugriff. Blickrichtung der Figur ist -Z.


## Wandelt die Joystick-Eingabe (x rechts, y nach unten) in eine Weltrichtung um,
## bezogen auf die Blickrichtung der Kamera ([param yaw_rad], 0 = Blick nach -Z).
static func world_direction(input: Vector2, yaw_rad: float) -> Vector3:
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw_rad)


## Zielgeschwindigkeit in m/s: Auslenkung (0 bis 1) mal Lauf- oder Schleichtempo.
static func target_speed(input_length: float, sneaking: bool) -> float:
	var top := ControlsConfig.SNEAK_SPEED if sneaking else ControlsConfig.RUN_SPEED
	return top * clampf(input_length, 0.0, 1.0)


## Gierwinkel, bei dem die Figur (Blick -Z) in [param direction] schaut.
static func facing_yaw(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


## Dreht [param current] auf dem kürzesten Weg höchstens [param max_step] zu [param target].
static func turn_toward(current: float, target: float, max_step: float) -> float:
	return current + clampf(angle_difference(current, target), -max_step, max_step)


## Beschleunigt die waagerechte Geschwindigkeit gleichmäßig zum Ziel.
static func accelerate(current: Vector3, target: Vector3, rate: float, delta: float) -> Vector3:
	return current.move_toward(target, rate * delta)
