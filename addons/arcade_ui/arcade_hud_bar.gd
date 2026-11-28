class_name ArcadeHudBar
extends Control

## Einheitliche 1–4-Spieler-Topbar für Couch-Multiplayer & Singleplayer (Score, Meter, Timer).

var _hbox: HBoxContainer
var _slots: Array[Dictionary] = []
var _center_panel: PanelContainer
var _center_lbl: Label
var _center_style: StyleBoxFlat
var _accent_color: Color = Color(1.0, 0.78, 0.2)

func _init() -> void:
	name = "ArcadeHudBar"
	set_anchors_preset(Control.PRESET_TOP_WIDE)
	offset_left = 18
	offset_right = -18
	offset_top = 12
	offset_bottom = 86
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_hbox = HBoxContainer.new()
	_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hbox.add_theme_constant_override("separation", 12)
	_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hbox)

func setup_slots(names: Array[String], colors: Array[Color], active_count: int = 4) -> void:
	_clear_children()
	var count := clampi(active_count, 1, mini(names.size(), colors.size()))
	var mid := count / 2
	for i in range(count):
		if i == mid:
			_add_center_badge()
		_add_slot_panel(names[i], colors[i])
	if count == 1:
		_add_center_badge()

func setup_singleplayer(player_name: String, color: Color = Color(0.25, 0.72, 1.0)) -> void:
	setup_slots([player_name], [color], 1)

func _clear_children() -> void:
	_slots.clear()
	_center_panel = null
	_center_lbl = null
	for ch in _hbox.get_children():
		ch.queue_free()

func _add_center_badge() -> void:
	_center_panel = PanelContainer.new()
	_center_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.14, 0.90)
	sb.border_color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_center_panel.add_theme_stylebox_override("panel", sb)
	_center_style = sb
	_hbox.add_child(_center_panel)

	_center_lbl = Label.new()
	_center_lbl.text = "00:00"
	_center_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_lbl.custom_minimum_size = Vector2(96, 0)
	_center_lbl.add_theme_font_size_override("font_size", 22)
	_center_lbl.add_theme_color_override("font_color", _accent_color.lightened(0.12))
	_center_panel.add_child(_center_lbl)

func set_arcade_accent(accent: Color) -> void:
	_accent_color = accent
	if _center_style:
		_center_style.border_color = Color(accent.r, accent.g, accent.b, 0.85)
	if _center_lbl:
		_center_lbl.add_theme_color_override("font_color", accent.lightened(0.12))

func _add_slot_panel(p_name: String, color: Color) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.10, 0.17, 0.88)
	sb.border_color = color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", sb)
	_hbox.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top)

	var name_lbl := Label.new()
	name_lbl.text = p_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.add_theme_color_override("font_color", color.lightened(0.25))
	top.add_child(name_lbl)

	var score_lbl := Label.new()
	score_lbl.text = "0"
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_lbl.add_theme_font_size_override("font_size", 20)
	score_lbl.add_theme_color_override("font_color", Color.WHITE)
	top.add_child(score_lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 1.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 7)
	bar.visible = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)
	vbox.add_child(bar)

	_slots.append({"name": name_lbl, "score": score_lbl, "bar": bar, "last_score": 0})

func set_score(slot_idx: int, score: int) -> void:
	if slot_idx < 0 or slot_idx >= _slots.size():
		return
	var s := _slots[slot_idx]
	var lbl: Label = s["score"]
	lbl.text = str(score)
	if score != int(s["last_score"]) and DisplayServer.get_name() != "headless" and lbl.is_inside_tree():
		lbl.pivot_offset = lbl.size * 0.5
		lbl.scale = Vector2(1.28, 1.28)
		var tw := lbl.create_tween()
		tw.tween_property(lbl, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	s["last_score"] = score

func set_meter(slot_idx: int, ratio: float, show: bool = true) -> void:
	if slot_idx < 0 or slot_idx >= _slots.size():
		return
	var bar: ProgressBar = _slots[slot_idx]["bar"]
	bar.visible = show
	bar.value = clampf(ratio, 0.0, 1.0)

func set_timer(seconds: float) -> void:
	var total := maxi(0, int(ceilf(seconds)))
	set_center_text("%02d:%02d" % [total / 60, total % 60])

func set_center_text(text: String) -> void:
	if _center_lbl:
		_center_lbl.text = text
