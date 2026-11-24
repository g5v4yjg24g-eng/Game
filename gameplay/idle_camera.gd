class_name IdleCamera
extends RefCounted
## Regel für den Kamera-Schwenk im Stillstand: Steht die Figur und gibt es keine Eingabe, dreht sich
## die Kamera nach [constant ControlsConfig.IDLE_CAMERA_DELAY] Sekunden langsam um sie. Die erste
## Eingabe bricht den Schwenk schnell ab; die Kamera bleibt dort, wo sie steht. Reine Logik.

## Sekunden ohne Bewegung und Eingabe.
var idle_time := 0.0
## 0 = Schwenk aus, 1 = volle Geschwindigkeit (sanft ein- und ausgeblendet).
var strength := 0.0


## Eine Eingabe oder Bewegung: Zeit zurücksetzen.
func notify_activity() -> void:
	idle_time = 0.0


## Zählt weiter und liefert die Drehgeschwindigkeit der Kamera in Grad pro Sekunde.
## [param at_rest] steht die Figur still (am Boden, ohne Bewegung).
func update(delta: float, at_rest: bool) -> float:
	if at_rest:
		idle_time += delta
	else:
		idle_time = 0.0
	var wanted := 1.0 if idle_time >= ControlsConfig.IDLE_CAMERA_DELAY else 0.0
	var ramp := (
		ControlsConfig.IDLE_CAMERA_RAMP_IN
		if wanted > strength
		else ControlsConfig.IDLE_CAMERA_RAMP_OUT
	)
	strength = move_toward(strength, wanted, delta / maxf(ramp, 0.001))
	return smoothstep(0.0, 1.0, strength) * ControlsConfig.IDLE_CAMERA_SPEED
