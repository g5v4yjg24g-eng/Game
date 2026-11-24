class_name SettingsData
extends RefCounted
## Einstellungen der Spielerin oder des Spielers mit Prüfung und Grenzen. Reine Logik, ohne Datei
## und Oberfläche (Speichern und Anwenden macht der Autoload `Settings`).

const FPS_CHOICES: Array[int] = [30, 60, 120]
const DEFAULT_FPS := 120
const SENSITIVITY_MIN := 0.5
const SENSITIVITY_MAX := 2.0

## Faktor auf die Standard-Empfindlichkeit der Kamera (1,0 = Standard).
var sensitivity := 1.0
var max_fps := DEFAULT_FPS
var cartoon := false


## Liest Werte aus einem Wörterbuch (z. B. aus der Datei). Ungültiges wird durch
## Standardwerte ersetzt, Zahlen werden auf den erlaubten Bereich begrenzt.
static func from_dict(values: Dictionary) -> SettingsData:
	var result := SettingsData.new()
	var s: Variant = values.get("sensitivity", 1.0)
	if (s is float or s is int) and not is_nan(float(s)):
		result.sensitivity = clampf(float(s), SENSITIVITY_MIN, SENSITIVITY_MAX)
	var f: Variant = values.get("max_fps", DEFAULT_FPS)
	if (f is float or f is int) and not is_nan(float(f)):
		result.max_fps = nearest_fps(roundi(float(f)))
	var c: Variant = values.get("cartoon", false)
	if c is bool:
		result.cartoon = c
	return result


## Der erlaubte Bildraten-Wert, der [param value] am nächsten liegt.
static func nearest_fps(value: int) -> int:
	var best := DEFAULT_FPS
	var best_distance := 1 << 30
	for choice in FPS_CHOICES:
		var distance := absi(choice - value)
		if distance < best_distance:
			best = choice
			best_distance = distance
	return best


func to_dict() -> Dictionary:
	return {"sensitivity": sensitivity, "max_fps": max_fps, "cartoon": cartoon}


## Kamera-Empfindlichkeit in Grad pro Pixel.
func look_deg_per_px() -> float:
	return ControlsConfig.LOOK_DEG_PER_PX * sensitivity
