class_name DebugOverlay
extends CanvasLayer
## Kleine Messanzeige oben links für Tests am Gerät: Bildrate, Bildzeit, Draw Calls, Objekte.
## Soll im Release-Build abschaltbar sein (siehe docs/ENTWICKLUNGSPLAN.md).

const REFRESH_SECONDS := 0.25

var _label: Label
var _margin: MarginContainer
var _elapsed := 0.0


func _ready() -> void:
	layer = 100
	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)
	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("outline_size", 4)
	_margin.add_child(_label)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < REFRESH_SECONDS:
		return
	_elapsed = 0.0
	var draw_calls := RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME
	)
	var objects := RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME
	)
	_label.text = (
		"%d fps  %.1f ms\n%d draw calls  %d objects"
		% [Engine.get_frames_per_second(), delta * 1000.0, draw_calls, objects]
	)


func _apply_safe_area() -> void:
	var window := DisplayServer.window_get_size()
	var scale := 1.0
	if window.x > 0:
		scale = get_viewport().get_visible_rect().size.x / float(window.x)
	SafeArea.apply(_margin, window, DisplayServer.get_display_safe_area(), scale)
	_margin.add_theme_constant_override("margin_top", _margin.get_theme_constant("margin_top") + 8)
	_margin.add_theme_constant_override(
		"margin_left", _margin.get_theme_constant("margin_left") + 12
	)
