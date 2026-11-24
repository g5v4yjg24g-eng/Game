class_name TouchLayout
extends RefCounted
## Aufteilung des Bildschirms: Knöpfe rechts unten, links schwebender Joystick,
## rechte Hälfte steuert die Kamera. Reine Logik, berücksichtigt die Safe Area.

enum Zone { JOYSTICK, LOOK, JUMP, SNEAK, MENU }


## Mittelpunkt eines Knopfes. [param insets] = {left, top, right, bottom} in Oberflächenpixeln.
static func button_center(button: Zone, size: Vector2, insets: Dictionary) -> Vector2:
	var r := ControlsConfig.BUTTON_RADIUS
	var jump := Vector2(
		size.x - float(insets["right"]) - ControlsConfig.BUTTON_MARGIN - r,
		size.y - float(insets["bottom"]) - ControlsConfig.BUTTON_MARGIN - r
	)
	if button == Zone.JUMP:
		return jump
	if button == Zone.SNEAK:
		return jump - Vector2(2.0 * r + ControlsConfig.BUTTON_GAP, 0.0)
	if button == Zone.MENU:
		var s := ControlsConfig.MENU_BUTTON_RADIUS
		return Vector2(
			size.x - float(insets["right"]) - ControlsConfig.BUTTON_MARGIN - s,
			float(insets["top"]) + ControlsConfig.BUTTON_MARGIN + s
		)
	return Vector2.ZERO


## Mittelpunkt des unscheinbaren Hinweises, wo der Joystick zu finden ist.
static func joystick_hint(size: Vector2, insets: Dictionary) -> Vector2:
	return Vector2(
		float(insets["left"]) + ControlsConfig.BUTTON_MARGIN + ControlsConfig.JOYSTICK_RADIUS,
		(
			size.y
			- float(insets["bottom"])
			- ControlsConfig.BUTTON_MARGIN
			- ControlsConfig.JOYSTICK_RADIUS
		)
	)


## Bestimmt, welche Funktion eine Berührung an [param position] auslöst.
static func zone_at(position: Vector2, size: Vector2, insets: Dictionary) -> Zone:
	for button: Zone in [Zone.JUMP, Zone.SNEAK, Zone.MENU]:
		var radius := (
			ControlsConfig.MENU_BUTTON_RADIUS
			if button == Zone.MENU
			else ControlsConfig.BUTTON_RADIUS
		)
		if (
			position.distance_to(button_center(button, size, insets))
			<= radius * ControlsConfig.BUTTON_HIT_SCALE
		):
			return button
	if position.x < size.x * ControlsConfig.SCREEN_SPLIT:
		return Zone.JOYSTICK
	return Zone.LOOK
