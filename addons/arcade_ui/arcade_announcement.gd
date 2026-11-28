class_name ArcadeAnnouncement
extends Control

## Einblendbares In-Game-Banner für Spielereignisse ("TOR!", "FINAL LAP!", "NEW HIGHSCORE!").

var _panel: PanelContainer
var _title_lbl: Label
var _sub_lbl: Label
var _tween: Tween

func _init() -> void:
	name = "ArcadeAnnouncement"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.offset_top = 110
	center.offset_bottom = 230
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(vbox)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.add_theme_font_size_override("font_size", 15)
	_sub_lbl.add_theme_color_override("font_color", Color(0.84, 0.90, 0.98))
	vbox.add_child(_sub_lbl)

func show_banner(title: String, subtitle: String = "", accent: Color = Color(1.0, 0.78, 0.2), duration: float = 1.6) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.09, 0.16, 0.94)
	sb.border_color = accent
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	_panel.add_theme_stylebox_override("panel", sb)

	_title_lbl.text = title
	_title_lbl.add_theme_color_override("font_color", accent.lightened(0.15))
	_sub_lbl.text = subtitle
	_sub_lbl.visible = subtitle != ""
	visible = true
	move_to_front()

	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		return

	if _tween and _tween.is_valid():
		_tween.kill()
	_panel.pivot_offset = _panel.size * 0.5
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.88, 0.88)
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.14)
	_tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(duration)
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.22)
	_tween.tween_callback(func() -> void: visible = false)
