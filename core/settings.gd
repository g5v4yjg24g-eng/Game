extends Node
## Autoload `Settings`: lädt und speichert die Einstellungen auf dem Gerät (`user://`)
## und wendet sie an.
## Die Werte und ihre Prüfung stehen in [SettingsData]. Änderungen kommen über [method update].

## Wird nach jeder Änderung gemeldet (Kamera, Oberfläche und andere lesen dann neu).
signal changed

## Speicherort; Tests setzen einen eigenen Pfad, damit nichts auf dem Gerät verändert wird.
var path := "user://settings.cfg"
var data := SettingsData.new()


func _ready() -> void:
	# Das Menü pausiert das Spiel; die Einstellungen müssen trotzdem Änderungen annehmen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_from_disk()
	_apply_frame_rate()


## Liest die Datei; fehlt sie oder ist sie kaputt, gelten die Standardwerte.
func load_from_disk() -> void:
	var file := ConfigFile.new()
	var values := {}
	if file.load(path) == OK:
		for key in SettingsData.new().to_dict():
			values[key] = file.get_value("spiel", key, null)
	data = SettingsData.from_dict(values)


func save() -> void:
	var file := ConfigFile.new()
	var values := data.to_dict()
	for key in values:
		file.set_value("spiel", key, values[key])
	file.save(path)


## Ändert einzelne Werte (Schlüssel wie in [method SettingsData.to_dict]), prüft,
## speichert und meldet.
func update(partial: Dictionary) -> void:
	var before := data.to_dict()
	var merged := before.duplicate()
	merged.merge(partial, true)
	data = SettingsData.from_dict(merged)
	save()
	_apply_frame_rate()
	if data.cartoon != before["cartoon"]:
		EventBus.style_changed.emit(data.cartoon)
	changed.emit()


func _apply_frame_rate() -> void:
	Engine.max_fps = data.max_fps
