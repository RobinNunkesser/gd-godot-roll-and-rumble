class_name ArcadeArenaPicker
extends VBoxContainer

## Wiederverwendbare Turnier-/Arena-Auswahl mit Kategorie-/Tag-Filtern, Pool-Toggles und Vorschau.

const ArcadeNav = preload("res://addons/arcade_ui/arcade_nav.gd")

signal pool_changed(enabled_ids: Array[String])
signal arena_focused(arena_id: String)
signal action_pressed(action_id: String)
signal focus_layout_changed

var min_enabled: int = 1

var _arenas: Array[Dictionary] = []
var _extra_actions: Array[Dictionary] = []
var _active_filter: String = "ALLE"
var _selected_id: String = ""
var _accent_color: Color = Color(1.0, 0.78, 0.2)

var _split_box: BoxContainer
var _list_scroll: ScrollContainer
var _list_box: VBoxContainer
var _preview_panel: PanelContainer
var _preview_tex: TextureRect
var _preview_title: Label
var _preview_meta: Label
var _preview_pool: Label
var _toggle_btn: Button
var _action_row: HFlowContainer

var _filter_layer: CanvasLayer
var _filter_list: VBoxContainer
var _filter_modal_btns: Array[Button] = []
var _filter_close_btn: Button
var _filter_btn: Button

var _item_btns: Array[Button] = []
var _action_btns: Array[Button] = []
var _extra_btn_map: Dictionary = {}
var _back_control: Control = null

func _init() -> void:
	name = "ArcadeArenaPicker"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)

	_action_row = HFlowContainer.new()
	_action_row.add_theme_constant_override("h_separation", 8)
	_action_row.add_theme_constant_override("v_separation", 6)
	add_child(_action_row)

	_build_filter_modal()

	_split_box = BoxContainer.new()
	_split_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_split_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split_box.add_theme_constant_override("separation", 12)
	add_child(_split_box)

	_list_scroll = ScrollContainer.new()
	_list_scroll.follow_focus = true
	_list_scroll.custom_minimum_size = Vector2(320, 180)
	_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_split_box.add_child(_list_scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 4)
	_list_scroll.add_child(_list_box)

	_preview_panel = PanelContainer.new()
	_preview_panel.custom_minimum_size = Vector2(280, 180)
	_preview_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_preview_style()
	_split_box.add_child(_preview_panel)

	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 6)
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	_preview_panel.add_child(pv)

	_preview_title = Label.new()
	_preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_title.add_theme_font_size_override("font_size", 19)
	_preview_title.add_theme_color_override("font_color", _accent_color)
	pv.add_child(_preview_title)

	_preview_tex = TextureRect.new()
	_preview_tex.custom_minimum_size = Vector2(160, 100)
	_preview_tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_preview_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_preview_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pv.add_child(_preview_tex)

	_preview_meta = Label.new()
	_preview_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_meta.autowrap_mode = TextServer.AUTOWRAP_WORD
	_preview_meta.add_theme_font_size_override("font_size", 13)
	_preview_meta.add_theme_color_override("font_color", Color(0.76, 0.84, 0.96))
	pv.add_child(_preview_meta)

	_preview_pool = Label.new()
	_preview_pool.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_pool.add_theme_font_size_override("font_size", 13)
	_preview_pool.add_theme_color_override("font_color", Color(0.65, 0.92, 0.72))
	pv.add_child(_preview_pool)

	_toggle_btn = Button.new()
	_toggle_btn.custom_minimum_size = Vector2(200, 36)
	_toggle_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_toggle_btn.focus_mode = Control.FOCUS_ALL
	_toggle_btn.pressed.connect(func() -> void:
		if _selected_id != "":
			toggle_arena(_selected_id)
	)
	pv.add_child(_toggle_btn)

	resized.connect(_update_responsive)

func _update_responsive() -> void:
	var w := size.x
	if w <= 0.0:
		return
	_split_box.vertical = w < 620.0
	_list_scroll.custom_minimum_size.x = 240.0 if w < 620.0 else 320.0
	_preview_panel.custom_minimum_size.x = 240.0 if w < 620.0 else 280.0

func _apply_preview_style() -> void:
	if not _preview_panel:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.11, 0.19, 0.92)
	sb.border_color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.65)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	_preview_panel.add_theme_stylebox_override("panel", sb)

func set_arcade_accent(accent: Color) -> void:
	_accent_color = accent
	_apply_preview_style()
	if _preview_title:
		_preview_title.add_theme_color_override("font_color", accent.lightened(0.1))

func set_arenas(items: Array[Dictionary]) -> void:
	_arenas = []
	for item in items:
		_arenas.append(item.duplicate(true))
	if _selected_id == "" or _find_index(_selected_id) < 0:
		_selected_id = str(_arenas[0].get("id", "")) if not _arenas.is_empty() else ""
	_rebuild_all()

func set_extra_actions(actions: Array[Dictionary]) -> void:
	_extra_actions = actions.duplicate(true)
	_rebuild_actions()

func update_extra_action_label(action_id: String, new_label: String) -> void:
	var btn: Button = _extra_btn_map.get(action_id)
	if is_instance_valid(btn):
		btn.text = new_label

func set_filter(filter_name: String) -> void:
	_active_filter = filter_name
	_rebuild_all()

func get_enabled_ids() -> Array[String]:
	var out: Array[String] = []
	for a in _arenas:
		if bool(a.get("enabled", false)):
			out.append(str(a.get("id", "")))
	return out

func get_filtered_arenas() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for a in _arenas:
		if _active_filter == "ALLE":
			out.append(a)
		elif _active_filter == "AKTIV":
			if bool(a.get("enabled", false)):
				out.append(a)
		else:
			var tags: Array = a.get("tags", [])
			if tags.has(_active_filter):
				out.append(a)
	return out

func toggle_arena(arena_id: String) -> void:
	var idx := _find_index(arena_id)
	if idx < 0:
		return
	var cur := bool(_arenas[idx].get("enabled", false))
	if cur and get_enabled_ids().size() <= min_enabled:
		return
	_arenas[idx]["enabled"] = not cur
	_rebuild_all()
	pool_changed.emit(get_enabled_ids())

func set_filtered_enabled(enabled: bool) -> void:
	var filtered := get_filtered_arenas()
	var filtered_ids := {}
	for f in filtered:
		filtered_ids[str(f.get("id", ""))] = true
	for a in _arenas:
		var aid := str(a.get("id", ""))
		if filtered_ids.has(aid):
			if not enabled and get_enabled_ids().size() <= min_enabled:
				break
			a["enabled"] = enabled
	_rebuild_all()
	pool_changed.emit(get_enabled_ids())

func select_only(arena_id: String) -> void:
	if _find_index(arena_id) < 0:
		return
	for a in _arenas:
		a["enabled"] = (str(a.get("id", "")) == arena_id)
	_selected_id = arena_id
	_rebuild_all()
	pool_changed.emit(get_enabled_ids())

func enable_all() -> void:
	for a in _arenas:
		a["enabled"] = true
	_rebuild_all()
	pool_changed.emit(get_enabled_ids())

func set_back_control(ctrl: Control) -> void:
	_back_control = ctrl
	_wire_focus()

func _build_filter_modal() -> void:
	_filter_layer = CanvasLayer.new()
	_filter_layer.layer = 90
	_filter_layer.visible = false
	add_child(_filter_layer)

	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.03, 0.04, 0.08, 0.78)
	_filter_layer.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_filter_layer.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.11, 0.18, 0.98)
	sb.border_color = _accent_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	var hdr := Label.new()
	hdr.text = "FILTER WÄHLEN"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", _accent_color)
	vb.add_child(hdr)

	var sc := ScrollContainer.new()
	sc.follow_focus = true
	sc.custom_minimum_size = Vector2(320, 260)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(sc)

	_filter_list = VBoxContainer.new()
	_filter_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_list.add_theme_constant_override("separation", 6)
	sc.add_child(_filter_list)

	_filter_close_btn = Button.new()
	_filter_close_btn.text = "SCHLIESSEN"
	_filter_close_btn.custom_minimum_size = Vector2(200, 38)
	_filter_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_filter_close_btn.focus_mode = Control.FOCUS_ALL
	_filter_close_btn.pressed.connect(close_filter_menu)
	vb.add_child(_filter_close_btn)

func is_filter_menu_open() -> bool:
	return is_instance_valid(_filter_layer) and _filter_layer.visible

func open_filter_menu() -> void:
	_rebuild_filter_modal()
	_filter_layer.visible = true
	var target: Control = _filter_close_btn
	for b in _filter_modal_btns:
		if str(b.get_meta("filter_tag", "")) == _active_filter:
			target = b
			break
	if is_instance_valid(target):
		target.grab_focus()

func close_filter_menu() -> void:
	if is_instance_valid(_filter_layer):
		_filter_layer.visible = false
	if is_instance_valid(_filter_btn) and _filter_btn.is_inside_tree():
		_filter_btn.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if is_filter_menu_open() and event.is_action_pressed("ui_cancel"):
		close_filter_menu()
		var vp := get_viewport()
		if vp:
			vp.set_input_as_handled()

func _filter_button_label() -> String:
	var count := get_filtered_arenas().size()
	return "FILTER: %s (%d)" % [_active_filter.to_upper(), count]

func get_primary_focus_control() -> Control:
	if not _item_btns.is_empty() and is_instance_valid(_item_btns[0]):
		return _item_btns[0]
	if not _action_btns.is_empty() and is_instance_valid(_action_btns[0]):
		return _action_btns[0]
	return _back_control

func get_focus_controls() -> Array[Control]:
	var out: Array[Control] = []
	for b in _item_btns:
		if is_instance_valid(b):
			out.append(b)
	if is_instance_valid(_toggle_btn):
		out.append(_toggle_btn)
	for b in _action_btns:
		if is_instance_valid(b):
			out.append(b)
	return out

func _find_index(arena_id: String) -> int:
	for i in range(_arenas.size()):
		if str(_arenas[i].get("id", "")) == arena_id:
			return i
	return -1

func _capture_focus_state() -> Dictionary:
	var vp := get_viewport()
	var owner: Control = vp.gui_get_focus_owner() if vp else null
	if owner == null or (owner != self and not is_ancestor_of(owner)):
		return {}
	if owner == _toggle_btn:
		return {"kind": "toggle"}
	var item_idx := _item_btns.find(owner)
	if item_idx >= 0:
		return {"kind": "item", "idx": item_idx, "id": str(owner.get_meta("arena_id", _selected_id))}
	var action_idx := _action_btns.find(owner)
	if action_idx >= 0:
		return {"kind": "action", "idx": action_idx}
	return {}

func _restore_focus_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	var kind := str(state.get("kind", ""))
	var target: Control = null
	if kind == "item":
		var wanted_id := str(state.get("id", _selected_id))
		for b in _item_btns:
			if str(b.get_meta("arena_id", "")) == wanted_id:
				target = b
				break
		if target == null and not _item_btns.is_empty():
			var idx := clampi(int(state.get("idx", 0)), 0, _item_btns.size() - 1)
			target = _item_btns[idx]
		if target == null:
			target = get_primary_focus_control()
	elif kind == "toggle":
		if is_instance_valid(_toggle_btn) and _toggle_btn.visible:
			target = _toggle_btn
		else:
			target = get_primary_focus_control()
	elif kind == "action":
		if not _action_btns.is_empty():
			target = _action_btns[clampi(int(state.get("idx", 0)), 0, _action_btns.size() - 1)]
		else:
			target = get_primary_focus_control()
	if is_instance_valid(target) and target.is_inside_tree():
		target.grab_focus()

func _clear_children(parent: Node) -> void:
	for ch in parent.get_children():
		parent.remove_child(ch)
		ch.queue_free()

func _rebuild_all() -> void:
	var focus_state := _capture_focus_state()
	_rebuild_list()
	_rebuild_actions()
	_refresh_preview()
	_wire_focus()
	_restore_focus_state(focus_state)
	focus_layout_changed.emit()

func _rebuild_filter_modal() -> void:
	_filter_modal_btns.clear()
	_clear_children(_filter_list)

	var tags: Array[String] = ["ALLE", "AKTIV"]
	for a in _arenas:
		for t in a.get("tags", []):
			var ts := str(t)
			if ts != "" and not tags.has(ts):
				tags.append(ts)

	var enabled_count := get_enabled_ids().size()
	for tag in tags:
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		btn.custom_minimum_size = Vector2(0, 36)
		btn.add_theme_font_size_override("font_size", 14)
		if tag == "ALLE":
			btn.text = "ALLE (%d)" % _arenas.size()
		elif tag == "AKTIV":
			btn.text = "AKTIV (%d)" % enabled_count
		else:
			var cnt := 0
			for a in _arenas:
				if (a.get("tags", []) as Array).has(tag):
					cnt += 1
			btn.text = "%s (%d)" % [tag.to_upper(), cnt]
		if tag == _active_filter:
			btn.add_theme_color_override("font_color", _accent_color)
		var t_copy := tag
		btn.set_meta("filter_tag", t_copy)
		btn.pressed.connect(func() -> void:
			set_filter(t_copy)
			close_filter_menu()
		)
		_filter_list.add_child(btn)
		_filter_modal_btns.append(btn)

	var modal_ctrls: Array = _filter_modal_btns.duplicate()
	modal_ctrls.append(_filter_close_btn)
	ArcadeNav.wire_vertical_focus(modal_ctrls, true)

func _rebuild_list() -> void:
	_item_btns.clear()
	_clear_children(_list_box)

	var filtered := get_filtered_arenas()
	if filtered.is_empty():
		var empty := Label.new()
		empty.text = "Keine Arenen in diesem Filter."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list_box.add_child(empty)
		return

	if _find_index(_selected_id) < 0 or not filtered.any(func(x): return str(x.get("id", "")) == _selected_id):
		_selected_id = str(filtered[0].get("id", ""))

	for a in filtered:
		var aid := str(a.get("id", ""))
		var on := bool(a.get("enabled", false))
		var btn := Button.new()
		btn.focus_mode = Control.FOCUS_ALL
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 34)
		btn.add_theme_font_size_override("font_size", 14)
		btn.text = "%s  %s" % ["[✓]" if on else "[  ]", str(a.get("title", aid))]
		btn.add_theme_color_override("font_color", Color(0.65, 0.95, 0.72) if on else Color(0.62, 0.68, 0.78))
		btn.set_meta("arena_id", aid)
		btn.focus_entered.connect(func() -> void:
			_selected_id = aid
			_refresh_preview()
			if is_instance_valid(_toggle_btn) and _toggle_btn.visible:
				_toggle_btn.focus_neighbor_left = _toggle_btn.get_path_to(btn)
			arena_focused.emit(aid)
		)
		btn.pressed.connect(func() -> void:
			_selected_id = aid
			toggle_arena(aid)
		)
		_list_box.add_child(btn)
		_item_btns.append(btn)

func _rebuild_actions() -> void:
	_action_btns.clear()
	_extra_btn_map.clear()
	_clear_children(_action_row)

	_filter_btn = Button.new()
	_filter_btn.text = _filter_button_label()
	_filter_btn.focus_mode = Control.FOCUS_ALL
	_filter_btn.custom_minimum_size = Vector2(0, 34)
	_filter_btn.add_theme_font_size_override("font_size", 13)
	_filter_btn.add_theme_color_override("font_color", _accent_color)
	_filter_btn.pressed.connect(open_filter_menu)
	_action_row.add_child(_filter_btn)
	_action_btns.append(_filter_btn)

	var specs := [
		{"label": "AN", "cb": func() -> void: set_filtered_enabled(true)},
		{"label": "AUS", "cb": func() -> void: set_filtered_enabled(false)},
	]
	for spec in specs:
		var b := Button.new()
		b.text = spec["label"]
		b.focus_mode = Control.FOCUS_ALL
		b.custom_minimum_size = Vector2(0, 34)
		b.add_theme_font_size_override("font_size", 13)
		b.pressed.connect(spec["cb"])
		_action_row.add_child(b)
		_action_btns.append(b)

	for extra in _extra_actions:
		var eid := str(extra.get("id", ""))
		var b := Button.new()
		b.text = str(extra.get("label", eid))
		b.focus_mode = Control.FOCUS_ALL
		b.custom_minimum_size = Vector2(0, 34)
		b.add_theme_font_size_override("font_size", 13)
		b.pressed.connect(func() -> void: action_pressed.emit(eid))
		_action_row.add_child(b)
		_action_btns.append(b)
		_extra_btn_map[eid] = b

func _refresh_preview() -> void:
	var idx := _find_index(_selected_id)
	var enabled_count := get_enabled_ids().size()
	if idx < 0:
		_preview_title.text = "KEINE ARENA"
		_preview_tex.texture = null
		_preview_meta.text = ""
		_preview_pool.text = "Im Pool: %d / %d" % [enabled_count, _arenas.size()]
		_toggle_btn.visible = false
		return

	var a := _arenas[idx]
	var on := bool(a.get("enabled", false))
	_preview_title.text = str(a.get("title", _selected_id))
	_preview_tex.texture = a.get("preview") as Texture2D
	_preview_tex.visible = _preview_tex.texture != null
	var sub := str(a.get("subtitle", ""))
	var tags: Array = a.get("tags", [])
	var tag_str := ", ".join(tags) if not tags.is_empty() else ""
	_preview_meta.text = "%s\n%s" % [sub, tag_str] if (sub != "" and tag_str != "") else (sub + tag_str)
	_preview_pool.text = "Im Pool: %d / %d" % [enabled_count, _arenas.size()]
	_toggle_btn.visible = true
	_toggle_btn.text = "IM POOL: AN" if on else "IM POOL: AUS"

func _wire_focus() -> void:
	ArcadeNav.wire_row_focus(_action_btns, true)
	ArcadeNav.wire_vertical_focus(_item_btns, false)

	# Oben -> Unten: _action_btns -> _item_btns -> _back_control
	if not _action_btns.is_empty() and not _item_btns.is_empty():
		for ab in _action_btns:
			ab.focus_neighbor_bottom = ab.get_path_to(_item_btns[0])
		_item_btns[0].focus_neighbor_top = _item_btns[0].get_path_to(_action_btns[0])

	if is_instance_valid(_toggle_btn) and _toggle_btn.visible:
		var selected_btn: Button = _item_btns[0] if not _item_btns.is_empty() else null
		for ib in _item_btns:
			ib.focus_neighbor_right = ib.get_path_to(_toggle_btn)
			if str(ib.get_meta("arena_id", "")) == _selected_id:
				selected_btn = ib
		if selected_btn != null:
			_toggle_btn.focus_neighbor_left = _toggle_btn.get_path_to(selected_btn)
		if not _action_btns.is_empty():
			_toggle_btn.focus_neighbor_top = _toggle_btn.get_path_to(_action_btns[0])
		if is_instance_valid(_back_control):
			_toggle_btn.focus_neighbor_bottom = _toggle_btn.get_path_to(_back_control)

	if is_instance_valid(_back_control):
		if not _item_btns.is_empty():
			var last_item := _item_btns[_item_btns.size() - 1]
			last_item.focus_neighbor_bottom = last_item.get_path_to(_back_control)
			_back_control.focus_neighbor_top = _back_control.get_path_to(last_item)
		elif not _action_btns.is_empty():
			for ab in _action_btns:
				ab.focus_neighbor_bottom = ab.get_path_to(_back_control)
			_back_control.focus_neighbor_top = _back_control.get_path_to(_action_btns[0])
		if not _action_btns.is_empty():
			_back_control.focus_neighbor_bottom = _back_control.get_path_to(_action_btns[0])
			for ab in _action_btns:
				ab.focus_neighbor_top = ab.get_path_to(_back_control)
