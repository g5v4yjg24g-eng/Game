class_name CameraMath
extends RefCounted
## Kamerarechnung ohne Szenenzugriff.


## Wendet eine Wischbewegung (Pixel) auf Gier- und Neigungswinkel (Grad) an.
## Wischen nach rechts dreht den Blick nach rechts, Wischen nach oben schaut nach oben.
## Rückgabe: Vector2(yaw, pitch). Neigung ist begrenzt, Gier bleibt in -180 bis 180.
static func apply_look(
	yaw_deg: float,
	pitch_deg: float,
	drag: Vector2,
	sensitivity: float = ControlsConfig.LOOK_DEG_PER_PX
) -> Vector2:
	var new_yaw := wrapf(yaw_deg - drag.x * sensitivity, -180.0, 180.0)
	var new_pitch := clampf(
		pitch_deg - drag.y * sensitivity, ControlsConfig.MIN_PITCH_DEG, ControlsConfig.MAX_PITCH_DEG
	)
	return Vector2(new_yaw, new_pitch)
