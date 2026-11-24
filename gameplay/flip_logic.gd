class_name FlipLogic
extends RefCounted
## Salto vorwärts beim Springen: Drehwinkel über die Zeit. Reine Logik ohne Node-Zugriff.
## Die Drehung dauert [constant ControlsConfig.FLIP_SECONDS] und ist vor der Landung fertig
## (Sprungdauer 2 × JUMP_SPEED / GRAVITY). Landet die Figur früher, wird sie sauber aufgerichtet.

## Solange nach dem Absprung zählt der Bodenkontakt nicht (die Figur hebt gerade erst ab).
const TAKEOFF_GRACE := 0.08
## Ab diesem Winkel gilt der Salto bei früher Landung als fertig (der Rest ist kaum sichtbar).
const FINISH_ANGLE := 300.0
## Aufrichten bei früher Landung (Grad pro Sekunde).
const RECOVER_RATE := 1500.0

var active := false
## Aktueller Drehwinkel nach vorn in Grad (0 bis 360).
var angle_deg := 0.0

var _time := 0.0


func start() -> void:
	active = true
	angle_deg = 0.0
	_time = 0.0


func cancel() -> void:
	active = false
	angle_deg = 0.0


## Ein Zeitschritt. [param on_floor]: Figur steht am Boden (nach dem Absprung ohne Wirkung
## für die ersten [constant TAKEOFF_GRACE] Sekunden).
func step(delta: float, on_floor: bool) -> void:
	if not active:
		return
	_time += delta
	var landed := on_floor and _time > TAKEOFF_GRACE
	if landed and _time < ControlsConfig.FLIP_SECONDS:
		if angle_deg >= FINISH_ANGLE:
			cancel()
			return
		angle_deg = maxf(angle_deg - RECOVER_RATE * delta, 0.0)
		if angle_deg <= 0.0:
			cancel()
		return
	var x := clampf(_time / ControlsConfig.FLIP_SECONDS, 0.0, 1.0)
	angle_deg = 360.0 * smoothstep(0.0, 1.0, x)
	if x >= 1.0:
		cancel()
