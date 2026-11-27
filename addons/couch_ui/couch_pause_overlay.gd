class_name CouchPauseOverlay
extends Control

## Einheitliches Pause- & Audio-Overlay für Couch-Multiplayer-Spiele (Gamepad + Tastatur + Touch).

signal resumed
signal restarted
signal returned_to_lobby
signal master_volume_changed(linear: float)
signal music_volume_changed(linear: float)
signal sfx_volume_changed(linear: float)
signal music_toggled(muted: bool)
signal sfx_toggled(muted: bool)

var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _resume_btn: Button
var _restart_btn: Button
var _lobby_btn: Button
var _fs_btn: Button
var _custom_box: VBoxContainer
var _custom_btns: Array[Button] = []
var _hint_lbl: Label

func _init() -> void:
	name = "CouchPauseOverlay"
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	theme = CouchTheme.build()
	_build_ui()

func _make_slider_row(parent: VBoxContainer, label_text: String, initial: float, on_change: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(90, 0)
	lbl.add_theme_font_size_override("font_size", 15)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(180, 26)
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return slider

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.03, 0.07, 0.78)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(390, 0)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

	_master_slider = _make_slider_row(vbox, "Master", 1.0, func(v: float) -> void:
		master_volume_changed.emit(v)
	)
	_music_slider = _make_slider_row(vbox, "Musik", 0.85, func(v: float) -> void:
		music_volume_changed.emit(v)
		music_toggled.emit(v <= 0.001)
	)
	_sfx_slider = _make_slider_row(vbox, "SFX", 1.0, func(v: float) -> void:
		sfx_volume_changed.emit(v)
		sfx_toggled.emit(v <= 0.001)
	)

	_resume_btn = Button.new()
	_resume_btn.text = "Fortsetzen"
	_resume_btn.pressed.connect(close)
	vbox.add_child(_resume_btn)

	_restart_btn = Button.new()
	_restart_btn.text = "Neustart"
	_restart_btn.pressed.connect(func() -> void:
		close()
		restarted.emit()
	)
	vbox.add_child(_restart_btn)

	_custom_box = VBoxContainer.new()
	_custom_box.add_theme_constant_override("separation", 8)
	vbox.add_child(_custom_box)

	_fs_btn = Button.new()
	_fs_btn.text = "Vollbild: AN" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "Vollbild: AUS"
	_fs_btn.pressed.connect(func() -> void:
		var is_fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
		_fs_btn.text = "Vollbild: AUS" if is_fs else "Vollbild: AN"
	)
	vbox.add_child(_fs_btn)

	_lobby_btn = Button.new()
	_lobby_btn.text = "Zurück zur Lobby"
	_lobby_btn.pressed.connect(func() -> void:
		close()
		returned_to_lobby.emit()
	)
	vbox.add_child(_lobby_btn)

	_hint_lbl = Label.new()
	_hint_lbl.text = "[D-Pad / ↑↓] Wählen  |  [←→] Regler  |  [A] OK  |  [B/Esc] Weiter"
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_lbl.add_theme_font_size_override("font_size", 11)
	_hint_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(_hint_lbl)

	call_deferred("refresh_focus")

func add_custom_button(label_text: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.pressed.connect(cb)
	if _custom_box:
		_custom_box.add_child(btn)
	_custom_btns.append(btn)
	call_deferred("refresh_focus")
	return btn

func set_touch_mode(is_touch: bool) -> void:
	if _hint_lbl:
		_hint_lbl.visible = not is_touch

func refresh_focus() -> void:
	var order: Array = [_master_slider, _music_slider, _sfx_slider, _resume_btn, _restart_btn]
	for b in _custom_btns:
		if is_instance_valid(b):
			order.append(b)
	order.append(_fs_btn)
	order.append(_lobby_btn)
	CouchNav.wire_vertical_focus(order, true)

func open() -> void:
	if _master_slider:
		_master_slider.set_value_no_signal(CouchNav.get_bus_linear(&"Master", _master_slider.value))
	if _music_slider:
		_music_slider.set_value_no_signal(CouchNav.get_bus_linear(&"Music", _music_slider.value))
	if _sfx_slider:
		_sfx_slider.set_value_no_signal(CouchNav.get_bus_linear(&"SFX", _sfx_slider.value))
	visible = true
	get_tree().paused = true
	if _resume_btn:
		_resume_btn.call_deferred("grab_focus")

func close() -> void:
	visible = false
	get_tree().paused = false
	resumed.emit()

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if CouchNav.is_back(event) or CouchNav.is_start(event):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A and not event.is_action("ui_accept"):
		if CouchNav.activate_focused(get_viewport()):
			get_viewport().set_input_as_handled()
