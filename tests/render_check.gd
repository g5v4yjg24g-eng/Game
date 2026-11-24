extends Node
## Rendert den Prototyp mit dem echten Mobile-Renderer (in der CI per Software-Vulkan) und schaltet
## den Cartoon-Stil ein und aus. So fallen Shader-Fehler auf, die im Headless-Modus unsichtbar sind.
## Aufruf: godot --path . --rendering-method mobile --rendering-driver vulkan
##   res://tests/render_check.tscn


func _ready() -> void:
	var method := RenderingServer.get_current_rendering_method()
	if method != "mobile":
		printerr("FEHLER Renderer ist '%s', erwartet 'mobile'" % method)
		get_tree().quit(1)
		return
	add_child(load("res://scenes/prototype.tscn").instantiate())
	await _frames(40)
	EventBus.style_changed.emit(true)
	await _frames(40)
	EventBus.style_changed.emit(false)
	await _frames(10)
	print("Render-Prüfung (%s): alles bestanden" % method)
	get_tree().quit()


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
