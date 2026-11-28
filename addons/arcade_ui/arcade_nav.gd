class_name ArcadeNav
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

static func wire_player_cards(cards: Array, back_btn: Control = null) -> Control:
	var card_cols: Array[Array] = []
	for card in cards:
		if is_instance_valid(card) and card.has_method("get_focus_controls"):
			var ctrls: Array = card.get_focus_controls()
			if not ctrls.is_empty():
				card_cols.append(ctrls)
	if card_cols.is_empty():
		return null

	var num_cards := card_cols.size()
	var rows := card_cols[0].size()
	for r in range(rows):
		var row_ctrls: Array = []
		for c in range(num_cards):
			if r < card_cols[c].size():
				row_ctrls.append(card_cols[c][r])
		wire_row_focus(row_ctrls, true)

	for c in range(num_cards):
		var col: Array = card_cols[c].duplicate()
		if is_instance_valid(back_btn):
			col.append(back_btn)
		wire_vertical_focus(col, true)

	if is_instance_valid(back_btn):
		back_btn.focus_mode = Control.FOCUS_ALL
		var first_col: Array = card_cols[0]
		back_btn.focus_neighbor_top = back_btn.get_path_to(first_col[first_col.size() - 1])
		back_btn.focus_neighbor_bottom = back_btn.get_path_to(first_col[0])
	return card_cols[0][card_cols[0].size() - 1]

static func activate_focused(vp: Viewport) -> bool:
	if vp == null:
		return false
	var focused := vp.gui_get_focus_owner()
	if focused is BaseButton and not focused.disabled:
		focused.pressed.emit()
		return true
	return false

static func get_bus_linear(bus_name: StringName, fallback: float = 1.0) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return fallback
	if AudioServer.is_bus_mute(idx):
		return 0.0
	return clampf(db_to_linear(AudioServer.get_bus_volume_db(idx)), 0.0, 1.0)

static func pop_in(ctrl: Control, duration: float = 0.16) -> void:
	if not is_instance_valid(ctrl):
		return
	if DisplayServer.get_name() == "headless" or not ctrl.is_inside_tree():
		ctrl.modulate.a = 1.0
		ctrl.scale = Vector2.ONE
		return
	ctrl.pivot_offset = ctrl.size * 0.5
	ctrl.modulate.a = 0.0
	ctrl.scale = Vector2(0.94, 0.94)
	var tw := ctrl.create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(ctrl, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func attach_button_juice(btn: BaseButton) -> void:
	if not is_instance_valid(btn) or btn.get_meta("_arcade_juice", false):
		return
	btn.set_meta("_arcade_juice", true)
	btn.focus_entered.connect(func() -> void:
		if DisplayServer.get_name() == "headless" or not btn.is_inside_tree():
			return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2(1.03, 1.03), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	btn.focus_exited.connect(func() -> void:
		if DisplayServer.get_name() == "headless" or not btn.is_inside_tree():
			return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.08)
	)
	btn.pressed.connect(func() -> void:
		if DisplayServer.get_name() == "headless" or not btn.is_inside_tree():
			return
		btn.pivot_offset = btn.size * 0.5
		btn.scale = Vector2(0.96, 0.96)
		var tw := btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_property(btn, "scale", Vector2(1.03, 1.03) if btn.has_focus() else Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
