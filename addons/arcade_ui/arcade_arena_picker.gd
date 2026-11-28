class_name ArcadeArenaPicker
extends VBoxContainer

## Wiederverwendbare Turnier-/Arena-Auswahl mit Kategorie-/Tag-Filtern, Pool-Toggles und Vorschau.

const ArcadeNav = preload("res://addons/arcade_ui/arcade_nav.gd")

signal pool_changed(enabled_ids: Array[String])
signal arena_focused(arena_id: String)
signal action_pressed(action_id: String)

var min_enabled: int = 1

var _arenas: Array[Dictionary] = []
var _extra_actions: Array[Dictionary] = []
var _active_filter: String = "ALLE"
var _selected_id: String = ""
var _accent_color: Color = Color(1.0, 0.78, 0.2)

var _filter_row: HFlowContainer
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

var _filter_btns: Array[Button] = []
var _item_btns: Array[Button] = []
var _action_btns: Array[Button] = []
var _extra_btn_map: Dictionary = {}

func _init() -> void:
	name = "ArcadeArenaPicker"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)

	_filter_row = HFlowContainer.new()
	_filter_row.add_theme_constant_override("h_separation", 6)
	_filter_row.add_theme_constant_override("v_separation", 6)
	add_child(_filter_row)

	_split_box = BoxContainer.new()
	_split_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_split_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split_box.add_theme_constant_override("separation", 12)
	add_child(_split_box)

	_list_scroll = ScrollContainer.new()
	_list_scroll.custom_minimum_size = Vector2(320, 210)
	_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_split_box.add_child(_list_scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 4)
	_list_scroll.add_child(_list_box)

	_preview_panel = PanelContainer.new()
	_preview_panel.custom_minimum_size = Vector2(280, 210)
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
	_preview_tex.custom_minimum_size = Vector2(180, 120)
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

	_action_row = HFlowContainer.new()
	_action_row.add_theme_constant_override("h_separation", 8)
	_action_row.add_theme_constant_override("v_separation", 6)
	add_child(_action_row)

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

func _rebuild_all() -> void:
	_rebuild_filters()
	_rebuild_list()
	_rebuild_actions()
	_refresh_preview()
	_wire_focus()

func _rebuild_filters() -> void:
	_filter_btns.clear()
	for ch in _filter_row.get_children():
		ch.queue_free()

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
		btn.custom_minimum_size = Vector2(0, 30)
		btn.add_theme_font_size_override("font_size", 13)
		if tag == "ALLE":
			btn.text = "ALLE (%d)" % _arenas.size()
		elif tag == "AKTIV":
			btn.text = "AKTIV (%d)" % enabled_count
		else:
			btn.text = tag.to_upper()
		if tag == _active_filter:
			btn.add_theme_color_override("font_color", _accent_color)
		var t_copy := tag
		btn.pressed.connect(func() -> void: set_filter(t_copy))
		_filter_row.add_child(btn)
		_filter_btns.append(btn)

func _rebuild_list() -> void:
	_item_btns.clear()
	for ch in _list_box.get_children():
		ch.queue_free()

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
		btn.focus_entered.connect(func() -> void:
			_selected_id = aid
			_refresh_preview()
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
	for ch in _action_row.get_children():
		ch.queue_free()

	var select_only_cb := func() -> void:
		if _selected_id != "":
			select_only(_selected_id)
	var specs := [
		{"label": "FILTER AN", "cb": func() -> void: set_filtered_enabled(true)},
		{"label": "FILTER AUS", "cb": func() -> void: set_filtered_enabled(false)},
		{"label": "NUR DIESE", "cb": select_only_cb},
		{"label": "ALLE AN", "cb": enable_all},
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
	ArcadeNav.wire_row_focus(_filter_btns, true)
	ArcadeNav.wire_vertical_focus(_item_btns, false)
	ArcadeNav.wire_row_focus(_action_btns, true)
	if not _item_btns.is_empty() and not _action_btns.is_empty():
		var last_item := _item_btns[_item_btns.size() - 1]
		last_item.focus_neighbor_bottom = last_item.get_path_to(_action_btns[0])
		for ab in _action_btns:
			ab.focus_neighbor_top = ab.get_path_to(last_item)
	if not _item_btns.is_empty() and not _filter_btns.is_empty():
		_item_btns[0].focus_neighbor_top = _item_btns[0].get_path_to(_filter_btns[0])
		for fb in _filter_btns:
			fb.focus_neighbor_bottom = fb.get_path_to(_item_btns[0])
