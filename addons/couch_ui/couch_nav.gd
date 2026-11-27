class_name CouchNav
extends RefCounted

## Einheitliche Eingabe-Helfer für Gamepad- und Tastatur-Menüführung in Couch-Multiplayer-Spielen.

static func is_confirm(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_A
	return false

static func is_back(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ESCAPE
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_B
	return false

static func is_start(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode == KEY_ESCAPE
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_START
	return false

static func is_nav_left(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_LEFT, KEY_A]
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_DPAD_LEFT
	return false

static func is_nav_right(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_RIGHT, KEY_D]
	if event is InputEventJoypadButton and event.pressed:
		return event.button_index == JOY_BUTTON_DPAD_RIGHT
	return false

static func wire_vertical_focus(controls: Array, wrap: bool = true) -> void:
	var valid: Array[Control] = []
	for c in controls:
		if is_instance_valid(c) and c is Control:
			c.focus_mode = Control.FOCUS_ALL
			valid.append(c)
	var n := valid.size()
	for i in range(n):
		if i > 0:
			valid[i].focus_neighbor_top = valid[i].get_path_to(valid[i - 1])
		elif wrap and n > 1:
			valid[i].focus_neighbor_top = valid[i].get_path_to(valid[n - 1])
		if i < n - 1:
			valid[i].focus_neighbor_bottom = valid[i].get_path_to(valid[i + 1])
		elif wrap and n > 1:
			valid[i].focus_neighbor_bottom = valid[i].get_path_to(valid[0])

static func wire_row_focus(controls: Array, wrap: bool = true) -> void:
	var valid: Array[Control] = []
	for c in controls:
		if is_instance_valid(c) and c is Control:
			c.focus_mode = Control.FOCUS_ALL
			valid.append(c)
	var n := valid.size()
	for i in range(n):
		if i > 0:
			valid[i].focus_neighbor_left = valid[i].get_path_to(valid[i - 1])
		elif wrap and n > 1:
			valid[i].focus_neighbor_left = valid[i].get_path_to(valid[n - 1])
		if i < n - 1:
			valid[i].focus_neighbor_right = valid[i].get_path_to(valid[i + 1])
		elif wrap and n > 1:
			valid[i].focus_neighbor_right = valid[i].get_path_to(valid[0])

static func activate_focused(vp: Viewport) -> bool:
	if vp == null:
		return false
	var focused := vp.gui_get_focus_owner()
	if focused is BaseButton and not focused.disabled:
		focused.pressed.emit()
		return true
	return false
