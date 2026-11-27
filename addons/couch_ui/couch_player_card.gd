class_name CouchPlayerCard
extends PanelContainer

## Einheitliche Player-Slot-Karte für Couch-Multiplayer-Lobbies (Focus / Touch / Click, ohne Tastatur-Kürzel).

signal control_cycled(slot_index: int)
signal team_toggled(slot_index: int)
signal name_clicked(slot_index: int)

var slot_index: int = 0
var show_team_button: bool = false

var title_label: Label
var name_btn: Button
var team_btn: Button
var status_label: Label
var ctrl_btn: Button

func _init(idx: int = 0, border_color: Color = Color(0.2, 0.45, 0.7, 0.8), with_team: bool = false) -> void:
	slot_index = idx
	show_team_button = with_team
	name = "SlotCard%d" % idx

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.20, 0.94)
	sb.border_color = border_color
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(12)
	add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	title_label = Label.new()
	title_label.text = "SPIELER %d" % (slot_index + 1)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_label)

	name_btn = Button.new()
	name_btn.name = "SlotNameBtn%d" % slot_index
	name_btn.text = "✏️ P%d" % (slot_index + 1)
	name_btn.custom_minimum_size = Vector2(0, 34)
	name_btn.focus_mode = Control.FOCUS_ALL
	name_btn.pressed.connect(func() -> void: name_clicked.emit(slot_index))
	vbox.add_child(name_btn)

	team_btn = Button.new()
	team_btn.name = "SlotTeamBtn%d" % slot_index
	team_btn.text = "TEAM"
	team_btn.custom_minimum_size = Vector2(0, 38)
	team_btn.focus_mode = Control.FOCUS_ALL
	team_btn.visible = show_team_button
	team_btn.pressed.connect(func() -> void: team_toggled.emit(slot_index))
	vbox.add_child(team_btn)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(status_label)

	ctrl_btn = Button.new()
	ctrl_btn.name = "SlotCtrlBtn%d" % slot_index
	ctrl_btn.text = "STEUERUNG"
	ctrl_btn.custom_minimum_size = Vector2(0, 42)
	ctrl_btn.focus_mode = Control.FOCUS_ALL
	ctrl_btn.pressed.connect(func() -> void: control_cycled.emit(slot_index))
	vbox.add_child(ctrl_btn)

func set_title(text: String, color: Color = Color.WHITE) -> void:
	if title_label:
		title_label.text = text
		title_label.add_theme_color_override("font_color", color)

func set_player_name(p_name: String) -> void:
	if name_btn:
		name_btn.text = "✏️ %s" % p_name

func set_status(text: String, color: Color = Color(0.92, 0.95, 1.0)) -> void:
	if status_label:
		status_label.text = text
		status_label.add_theme_color_override("font_color", color)

func set_team_text(text: String) -> void:
	if team_btn:
		team_btn.text = text

func get_focus_controls() -> Array[Control]:
	var out: Array[Control] = []
	if show_team_button and is_instance_valid(team_btn):
		out.append(team_btn)
	if is_instance_valid(ctrl_btn):
		out.append(ctrl_btn)
	return out
