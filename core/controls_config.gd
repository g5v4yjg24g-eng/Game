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
const MENU_BUTTON_RADIUS := 30.0

# Kamera
const MIN_PITCH_DEG := -65.0
const MAX_PITCH_DEG := 25.0
const START_PITCH_DEG := -14.0
const CAMERA_DISTANCE := 4.0
const CAMERA_HEIGHT := 1.15
const CAMERA_FOLLOW_SPEED := 12.0
## Kamera-Schwenk im Stillstand (Wunsch Nutzer: nach 10 bis 15 Sekunden ohne Bewegung).
const IDLE_CAMERA_DELAY := 12.0
## Drehgeschwindigkeit um die Figur in Grad pro Sekunde (ein voller Kreis dauert 30 Sekunden).
const IDLE_CAMERA_SPEED := 12.0
## Sanftes Anfahren und schnelles Abbrechen bei der ersten Eingabe (Sekunden).
const IDLE_CAMERA_RAMP_IN := 2.5
const IDLE_CAMERA_RAMP_OUT := 0.35

# Bewegung
## Entwurfstempo des Laufzyklus: gleich RUN_SPEED in tools/blender/build_ninja.py (Test prüft das).
const RUN_SPEED := 5.2
const SNEAK_SPEED := 1.9
const ACCELERATION := 38.0
const TURN_SPEED := 14.0
const JUMP_SPEED := 7.0
const GRAVITY := 22.0
const JUMP_BUFFER_SECONDS := 0.12
const FALL_RESET_Y := -20.0
