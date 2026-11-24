extends Control
## Testszene der Phase 2: zeigt Titel, Version und Bildrate. Gameplay folgt in Phase 3.

@onready var _margin: MarginContainer = $SafeMargin
@onready var _fps: Label = $SafeMargin/Layout/Fps


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


func _process(_delta: float) -> void:
	_fps.text = "%d fps" % Engine.get_frames_per_second()


func _apply_safe_area() -> void:
	var window := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	var scale := 1.0
	if window.x > 0:
		scale = get_viewport_rect().size.x / float(window.x)
	SafeArea.apply(_margin, window, safe, scale)
