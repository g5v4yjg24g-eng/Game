class_name JoystickLogic
extends RefCounted
## Schwebender Joystick: Der Mittelpunkt liegt dort, wo der Daumen aufsetzt.
## Reine Logik ohne Eingabe- und Zeichencode.

var radius: float
var deadzone: float
var active := false
var finger := -1
var origin := Vector2.ZERO
## Auslenkung des Knopfes in Pixeln (für die Anzeige), nie länger als [member radius].
var knob := Vector2.ZERO
## Ausgabewert, Länge 0 bis 1 (x nach rechts, y nach unten wie am Bildschirm).
var value := Vector2.ZERO


func _init(
	p_radius: float = ControlsConfig.JOYSTICK_RADIUS,
	p_deadzone: float = ControlsConfig.JOYSTICK_DEADZONE
) -> void:
	radius = p_radius
	deadzone = p_deadzone


## Rechnet eine Auslenkung in einen Wert um: Totzone abziehen, auf Länge 1 begrenzen.
static func compute(offset: Vector2, p_radius: float, p_deadzone: float) -> Vector2:
	if p_radius <= 0.0:
		return Vector2.ZERO
	var length := minf(offset.length() / p_radius, 1.0)
	if length <= p_deadzone:
		return Vector2.ZERO
	var scaled := (length - p_deadzone) / (1.0 - p_deadzone)
	return offset.normalized() * scaled


func begin(p_finger: int, position: Vector2) -> void:
	active = true
	finger = p_finger
	origin = position
	knob = Vector2.ZERO
	value = Vector2.ZERO


## Aktualisiert den Wert, wenn der Finger zum Joystick gehört. Liefert den aktuellen Wert.
func move(p_finger: int, position: Vector2) -> Vector2:
	if not active or p_finger != finger:
		return value
	var offset := position - origin
	knob = offset.limit_length(radius)
	value = compute(offset, radius, deadzone)
	return value


## Beendet die Berührung. Liefert true, wenn der Finger zum Joystick gehörte.
func end(p_finger: int) -> bool:
	if not active or p_finger != finger:
		return false
	reset()
	return true


func reset() -> void:
	active = false
	finger = -1
	knob = Vector2.ZERO
	value = Vector2.ZERO
