extends Node3D
## Prototyp (Phase 3): Testwelt, Spielfigur, Kamera und Touch-Steuerung zusammensetzen.
## Die Teile kennen sich nicht gegenseitig, sondern sprechen über den EventBus.


func _ready() -> void:
	add_child(TestWorld.new())

	var rig := CameraRig.new()
	add_child(rig)

	var player := Player.new()
	player.position = Vector3(0, 0.05, 8)
	player.camera_rig = rig
	add_child(player)

	rig.target = player
	rig.snap()

	var hud := CanvasLayer.new()
	add_child(hud)
	hud.add_child(TouchControls.new())
	var style := CartoonStyle.new()
	style.root = self
	add_child(style)
	add_child(DebugOverlay.new())
