class_name AnimationLogic
extends RefCounted
## Wählt die passende Animation der Spielfigur aus ihrem Zustand. Reine Logik ohne Szenenzugriff.

const IDLE := &"idle"
const RUN := &"run"
const SNEAK := &"sneak"
const SNEAK_IDLE := &"sneak_idle"
const JUMP := &"jump"
const FALL := &"fall"
const LAND := &"land"
## Salto vorwärts: Knie angezogen (Clip dauert so lange wie [constant ControlsConfig.FLIP_SECONDS]).
const FLIP := &"flip"

## Unter dieser Geschwindigkeit (m/s) gilt die Figur als stehend.
const MOVING_SPEED := 0.3
## So lange (s) bleibt die Sprunganimation nach dem Absprung, solange die Figur noch steigt.
const JUMP_SECONDS := 0.33
## Kurz nach dem Verlassen des Bodens (s) ohne Steigen wird noch nicht gefallen (Rampen, Kanten).
const COYOTE_SECONDS := 0.08
## Nur nach einem Luftflug von mindestens dieser Dauer (s) gibt es eine Landeanimation.
const LAND_MIN_AIR_SECONDS := 0.25
## Landen im Laufen (m/s) überspringt die Landeanimation.
const LAND_SKIP_SPEED := 2.0
const LAND_SECONDS := 0.3


## [param on_floor] steht die Figur, [param vertical_speed] Steig-/Fallgeschwindigkeit (m/s),
## [param speed] waagerechte Geschwindigkeit (m/s), [param air_time] Sekunden seit dem Verlassen
## des Bodens, [param land_left] Restzeit der Landeanimation, [param flipping] Salto läuft.
static func pick(
	on_floor: bool,
	vertical_speed: float,
	speed: float,
	sneaking: bool,
	air_time: float,
	land_left: float,
	flipping: bool = false
) -> StringName:
	if not on_floor:
		if flipping:
			return FLIP
		if vertical_speed > 0.5 and air_time < JUMP_SECONDS:
			return JUMP
		if vertical_speed <= 0.5 and air_time < COYOTE_SECONDS:
			return _on_ground(speed, sneaking)
		return FALL
	if land_left > 0.0:
		return LAND
	return _on_ground(speed, sneaking)


## Soll nach der Landung die Landeanimation laufen? ([param air_time] = Dauer des Flugs)
static func should_land(air_time: float, speed: float) -> bool:
	return air_time >= LAND_MIN_AIR_SECONDS and speed < LAND_SKIP_SPEED


## Abspielgeschwindigkeit, damit die Schritte zum Tempo passen (Faktor 1 = Entwurfstempo).
static func playback_speed(clip: StringName, speed: float) -> float:
	if clip == RUN:
		return clampf(speed / ControlsConfig.RUN_SPEED, 0.45, 1.15)
	if clip == SNEAK:
		return clampf(speed / ControlsConfig.SNEAK_SPEED, 0.5, 1.2)
	return 1.0


static func _on_ground(speed: float, sneaking: bool) -> StringName:
	if speed > MOVING_SPEED:
		return SNEAK if sneaking else RUN
	return SNEAK_IDLE if sneaking else IDLE
