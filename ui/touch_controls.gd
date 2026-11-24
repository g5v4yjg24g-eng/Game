class_name TouchControls
extends Control
## Touch-Steuerung: links schwebender Joystick, rechte Hälfte dreht die Kamera,
## Knöpfe für Sprung und Schleichen. Meldet alles über den EventBus.
## Die Aufteilung steht in [TouchLayout], die Joystick-Rechnung in [JoystickLogic].

const COLOR_BASE := Color(1, 1, 1, 0.14)
const COLOR_HINT := Color(1, 1, 1, 0.07)
const COLOR_KNOB := Color(1, 1, 1, 0.4)
const COLOR_BUTTON := Color(1, 1, 1, 0.18)
const COLOR_BUTTON_ON := Color(1.0, 0.55, 0.35, 0.5)
const COLOR_RING := Color(1, 1, 1, 0.45)

var _joystick := JoystickLogic.new()
var _look_finger := -1
var _jump_finger := -1
var _sneaking := false
var _insets := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_update_insets)
	_update_insets()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_on_press(touch.index, touch.position)
		else:
			_on_release(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		_on_drag(drag.index, drag.position, drag.relative)


func _notification(what: int) -> void:
	# Geht die App in den Hintergrund, kommen Loslass-Ereignisse nicht an.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_all()


func _draw() -> void:
	var area := get_viewport_rect().size
	var radius := ControlsConfig.JOYSTICK_RADIUS
	if _joystick.active:
		draw_circle(_joystick.origin, radius, COLOR_BASE)
		draw_arc(_joystick.origin, radius, 0.0, TAU, 64, COLOR_RING, 2.0, true)
		draw_circle(_joystick.origin + _joystick.knob, radius * 0.42, COLOR_KNOB)
	else:
		var hint := TouchLayout.joystick_hint(area, _insets)
		draw_arc(hint, radius, 0.0, TAU, 64, COLOR_HINT, 2.0, true)
	_draw_button(TouchLayout.Zone.JUMP, tr("HUD_JUMP"), _jump_finger != -1)
	_draw_button(TouchLayout.Zone.SNEAK, tr("HUD_SNEAK"), _sneaking)


func _draw_button(zone: TouchLayout.Zone, text: String, on: bool) -> void:
	var center := TouchLayout.button_center(zone, get_viewport_rect().size, _insets)
	var r := ControlsConfig.BUTTON_RADIUS
	draw_circle(center, r, COLOR_BUTTON_ON if on else COLOR_BUTTON)
	draw_arc(center, r, 0.0, TAU, 48, COLOR_RING, 2.0, true)
	var font := ThemeDB.fallback_font
	var font_size := 16
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(
		font,
		center + Vector2(-text_size.x * 0.5, text_size.y * 0.25),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(1, 1, 1, 0.9)
	)


func _on_press(index: int, position: Vector2) -> void:
	match TouchLayout.zone_at(position, get_viewport_rect().size, _insets):
		TouchLayout.Zone.JOYSTICK:
			if not _joystick.active:
				_joystick.begin(index, position)
		TouchLayout.Zone.LOOK:
			if _look_finger == -1:
				_look_finger = index
		TouchLayout.Zone.JUMP:
			if _jump_finger == -1:
				_jump_finger = index
				EventBus.jump_pressed.emit()
		TouchLayout.Zone.SNEAK:
			_sneaking = not _sneaking
			EventBus.sneak_changed.emit(_sneaking)
	queue_redraw()


func _on_release(index: int) -> void:
	if _joystick.end(index):
		EventBus.move_input.emit(Vector2.ZERO)
	if index == _look_finger:
		_look_finger = -1
	if index == _jump_finger:
		_jump_finger = -1
	queue_redraw()


func _on_drag(index: int, position: Vector2, relative: Vector2) -> void:
	if _joystick.active and index == _joystick.finger:
		EventBus.move_input.emit(_joystick.move(index, position))
		queue_redraw()
	elif index == _look_finger:
		EventBus.look_input.emit(relative)


func _release_all() -> void:
	if _joystick.active:
		_joystick.reset()
		EventBus.move_input.emit(Vector2.ZERO)
	_look_finger = -1
	_jump_finger = -1
	queue_redraw()


## Rechnet die Safe Area (Dynamic Island, Rundungen, Home-Indikator) in Oberflächenpixel um.
func _update_insets() -> void:
	var window := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	var scale := 1.0
	if window.x > 0:
		scale = get_viewport_rect().size.x / float(window.x)
	var raw := SafeArea.insets(window, safe)
	for key: String in raw:
		_insets[key] = float(raw[key]) * scale
	queue_redraw()
