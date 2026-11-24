class_name SettingsMenu
extends CanvasLayer
## Einstellungsmenü: Kamera-Empfindlichkeit, Bildrate und Cartoon-Stil. Öffnet über den Menü-Knopf,
## hält das Spiel an und schreibt Änderungen sofort in `Settings`.

var _panel: PanelContainer
var _sensitivity_label: Label
var _fps_buttons: Dictionary = {}


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()
	EventBus.menu_requested.connect(open)


func open() -> void:
	_sync()
	visible = true
	get_tree().paused = true
	# Laufende Eingaben beenden, damit die Figur nach dem Schließen nicht weiterläuft
	EventBus.move_input.emit(Vector2.ZERO)


func close() -> void:
	visible = false
	get_tree().paused = false


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(420, 0)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := Label.new()
	title.text = tr("MENU_TITLE")
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)

	_sensitivity_label = Label.new()
	box.add_child(_sensitivity_label)
	var slider := HSlider.new()
	slider.name = "SensitivitySlider"
	slider.min_value = SettingsData.SENSITIVITY_MIN
	slider.max_value = SettingsData.SENSITIVITY_MAX
	slider.step = 0.05
	slider.custom_minimum_size = Vector2(0, 44)
	slider.value_changed.connect(_on_sensitivity)
	box.add_child(slider)

	var fps_label := Label.new()
	fps_label.text = tr("MENU_FPS")
	box.add_child(fps_label)
	var fps_row := HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", 8)
	box.add_child(fps_row)
	for fps in SettingsData.FPS_CHOICES:
		var b := Button.new()
		b.text = str(fps)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(0, 48)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(_on_fps.bind(fps))
		fps_row.add_child(b)
		_fps_buttons[fps] = b

	var cartoon := CheckButton.new()
	cartoon.name = "CartoonToggle"
	cartoon.text = tr("MENU_CARTOON")
	cartoon.custom_minimum_size = Vector2(0, 48)
	cartoon.toggled.connect(func(on: bool) -> void: Settings.update({"cartoon": on}))
	box.add_child(cartoon)

	var back := Button.new()
	back.text = tr("MENU_CLOSE")
	back.custom_minimum_size = Vector2(0, 52)
	back.pressed.connect(close)
	box.add_child(back)


## Zeigt die aktuellen Werte, ohne Änderungen auszulösen.
func _sync() -> void:
	var slider: HSlider = _panel.find_child("SensitivitySlider", true, false)
	slider.set_value_no_signal(Settings.data.sensitivity)
	_update_label()
	for fps in _fps_buttons:
		_fps_buttons[fps].button_pressed = fps == Settings.data.max_fps
	var cartoon: CheckButton = _panel.find_child("CartoonToggle", true, false)
	cartoon.set_pressed_no_signal(Settings.data.cartoon)


func _update_label() -> void:
	_sensitivity_label.text = (
		"%s: %d %%" % [tr("MENU_SENSITIVITY"), roundi(Settings.data.sensitivity * 100)]
	)


func _on_sensitivity(value: float) -> void:
	Settings.update({"sensitivity": value})
	_update_label()


func _on_fps(fps: int) -> void:
	Settings.update({"max_fps": fps})
	for key in _fps_buttons:
		_fps_buttons[key].button_pressed = key == fps
