class_name CouchNameModal
extends Control

## Couch-taugliche Namenseingabe (Gamepad D-Pad + A, Touch, Maus & Tastatur).

signal name_confirmed(slot_index: int, new_name: String)
signal cancelled

const KEYS := [
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
	"K", "L", "M", "N", "O", "P", "Q", "R", "S", "T",
	"U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3",
	"4", "5", "6", "7", "8", "9", "-", "_", "⌫", "OK"
]

var _slot_index: int = 0
var _line_edit: LineEdit
var _recent_row: HBoxContainer
var _key_btns: Array[Button] = []
var _cancel_btn: Button

func _init() -> void:
	name = "CouchNameModal"
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = CouchTheme.build()
	_build_ui()

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.03, 0.07, 0.85)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(640, 0)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "SPIELERNAME EINGEBEN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	_line_edit = LineEdit.new()
	_line_edit.max_length = 12
	_line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line_edit.add_theme_font_size_override("font_size", 24)
	_line_edit.text_submitted.connect(func(_t: String) -> void: _confirm())
	vbox.add_child(_line_edit)

	_recent_row = HBoxContainer.new()
	_recent_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_recent_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_recent_row)

	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(grid)

	_key_btns.clear()
	for k in KEYS:
		var btn := Button.new()
		btn.text = k
		btn.custom_minimum_size = Vector2(52, 42)
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_key_pressed.bind(k))
		grid.add_child(btn)
		_key_btns.append(btn)

	_cancel_btn = Button.new()
	_cancel_btn.text = "ABBRECHEN"
	_cancel_btn.custom_minimum_size = Vector2(200, 40)
	_cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_cancel_btn.focus_mode = Control.FOCUS_ALL
	_cancel_btn.pressed.connect(func() -> void:
		visible = false
		cancelled.emit()
	)
	vbox.add_child(_cancel_btn)

	call_deferred("_wire_grid_focus")

func _wire_grid_focus() -> void:
	var cols := 10
	var n := _key_btns.size()
	for i in range(n):
		var b := _key_btns[i]
		var r := i / cols
		var c := i % cols
		var left_i := r * cols + ((c + cols - 1) % cols)
		var right_i := r * cols + ((c + 1) % cols)
		b.focus_neighbor_left = b.get_path_to(_key_btns[left_i])
		b.focus_neighbor_right = b.get_path_to(_key_btns[right_i])
		if i - cols >= 0:
			b.focus_neighbor_top = b.get_path_to(_key_btns[i - cols])
		elif is_instance_valid(_cancel_btn):
			b.focus_neighbor_top = b.get_path_to(_cancel_btn)
		if i + cols < n:
			b.focus_neighbor_bottom = b.get_path_to(_key_btns[i + cols])
		elif is_instance_valid(_cancel_btn):
			b.focus_neighbor_bottom = b.get_path_to(_cancel_btn)
	if is_instance_valid(_cancel_btn) and n > 0:
		_cancel_btn.focus_neighbor_top = _cancel_btn.get_path_to(_key_btns[n - 1])
		_cancel_btn.focus_neighbor_bottom = _cancel_btn.get_path_to(_key_btns[0])

func _on_key_pressed(k: String) -> void:
	if k == "OK":
		_confirm()
	elif k == "⌫":
		if _line_edit.text.length() > 0:
			_line_edit.text = _line_edit.text.substr(0, _line_edit.text.length() - 1)
	else:
		if _line_edit.text.length() < _line_edit.max_length:
			_line_edit.text += k

func _confirm() -> void:
	var out := _line_edit.text.strip_edges()
	if out == "":
		out = "P%d" % (_slot_index + 1)
	visible = false
	name_confirmed.emit(_slot_index, out)

func open(slot_idx: int, current_name: String, recent_names: Array = []) -> void:
	_slot_index = slot_idx
	_line_edit.text = current_name
	for child in _recent_row.get_children():
		child.queue_free()
	var shown := 0
	for rn in recent_names:
		if shown >= 5:
			break
		var s := str(rn)
		var chip := Button.new()
		chip.text = s
		chip.custom_minimum_size = Vector2(90, 34)
		chip.focus_mode = Control.FOCUS_ALL
		chip.pressed.connect(func() -> void:
			_line_edit.text = s
			_confirm()
		)
		_recent_row.add_child(chip)
		shown += 1
	visible = true
	if not _key_btns.is_empty():
		_key_btns[0].call_deferred("grab_focus")

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if CouchNav.is_back(event):
		get_viewport().set_input_as_handled()
		visible = false
		cancelled.emit()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A and not event.is_action("ui_accept"):
		if CouchNav.activate_focused(get_viewport()):
			get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		get_viewport().set_input_as_handled()
		_confirm()
