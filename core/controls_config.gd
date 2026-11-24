class_name ControlsConfig
extends RefCounted
## Zentrale Werte für Steuerung und Bewegung. Pixelwerte gelten in Einheiten der
## Oberfläche (nicht in Bildschirmpixeln des Geräts). Änderungen am Spielgefühl hier,
## nicht verstreut im Code.

# Touch-Steuerung
const JOYSTICK_RADIUS := 110.0
const JOYSTICK_DEADZONE := 0.12
## Standard-Empfindlichkeit der Kamera in Grad pro Pixel. Später per Regler in den Einstellungen.
const LOOK_DEG_PER_PX := 0.2
const SCREEN_SPLIT := 0.5
const BUTTON_RADIUS := 52.0
const BUTTON_MARGIN := 36.0
const BUTTON_GAP := 24.0
const BUTTON_HIT_SCALE := 1.25
## Kleiner Testknopf oben rechts (Cartoon-Stil an/aus), nur solange der Stil geprüft wird.
const STYLE_BUTTON_RADIUS := 30.0

# Kamera
const MIN_PITCH_DEG := -65.0
const MAX_PITCH_DEG := 25.0
const START_PITCH_DEG := -14.0
const CAMERA_DISTANCE := 5.0
const CAMERA_HEIGHT := 1.5
const CAMERA_FOLLOW_SPEED := 12.0

# Bewegung
const RUN_SPEED := 6.5
const SNEAK_SPEED := 2.4
const ACCELERATION := 38.0
const TURN_SPEED := 14.0
const JUMP_SPEED := 7.0
const GRAVITY := 22.0
const JUMP_BUFFER_SECONDS := 0.12
const FALL_RESET_Y := -20.0
