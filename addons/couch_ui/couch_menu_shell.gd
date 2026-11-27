class_name CouchMenuShell
extends Control

## Einheitliche Hauptmenü- & Untermenü-Shell im ClanBomber-Stil für Couch-Multiplayer-Spiele.
## Bietet MAIN + Untermenüs (PLAYERS, ARENA, MATCH, SETTINGS, EXTRA) mit Gamepad-Focus & Touch-Support.

enum Page { MAIN, PLAYERS, ARENA, MATCH, SETTINGS, EXTRA }

signal start_requested
signal back_to_main
signal master_volume_changed(linear: float)
signal music_volume_changed(linear: float)
signal sfx_volume_changed(linear: float)
signal touch_toggled

var current_page: Page = Page.MAIN

var _title_lbl: Label
var _subtitle_lbl: Label
var _summary_lbl: Label

var _pages: Dictionary = {}
var _main_vbox: VBoxContainer
var _main_btns: Array[Button] = []
var _start_btn: Button
var _players_btn: Button
var _arena_btn: Button
var _match_btn: Button
var _settings_btn: Button
var _extra_btn: Button

var players_box: Control
var arena_box: VBoxContainer
var match_box: VBoxContainer
var settings_box: VBoxContainer
var extra_box: VBoxContainer

var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _fs_btn: Button
var _touch_btn: Button
var _back_btns: Dictionary = {}
var _page_first_focus: Dictionary = {}

func _init(game_title: String = "COUCH GAME", subtitle_text: String = "") -> void:
	name = "CouchMenuShell"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = CouchTheme.build()
	_build_shell(game_title, subtitle_text)

func _build_shell(game_title: String, subtitle_text: String) -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.03, 0.05, 0.10, 0.84)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(960, 580)
	center.add_child(card)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 12)
	card.add_child(root_vbox)

	_title_lbl = Label.new()
	_title_lbl.text = game_title
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_size_override("font_size", 36)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.28))
	root_vbox.add_child(_title_lbl)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.text = subtitle_text
	_subtitle_lbl.visible = subtitle_text != ""
	_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_lbl.add_theme_font_size_override("font_size", 16)
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.70, 0.82, 0.96))
	root_vbox.add_child(_subtitle_lbl)

	_summary_lbl = Label.new()
	_summary_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_summary_lbl.add_theme_font_size_override("font_size", 15)
	_summary_lbl.add_theme_color_override("font_color", Color(0.65, 0.95, 0.72))
	root_vbox.add_child(_summary_lbl)

	# --- MAIN PAGE ---
	var main_center := CenterContainer.new()
	main_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(main_center)
	_pages[Page.MAIN] = main_center

	_main_vbox = VBoxContainer.new()
	_main_vbox.custom_minimum_size = Vector2(420, 0)
	_main_vbox.add_theme_constant_override("separation", 10)
	main_center.add_child(_main_vbox)

	_start_btn = _add_main_btn("▶ SPIEL STARTEN", func() -> void: start_requested.emit())
	_players_btn = _add_main_btn("👥 SPIELER & STEUERUNG", func() -> void: show_page(Page.PLAYERS))
	_arena_btn = _add_main_btn("🏟️ ARENA", func() -> void: show_page(Page.ARENA))
	_match_btn = _add_main_btn("🏆 MATCH & REGELN", func() -> void: show_page(Page.MATCH))
	_settings_btn = _add_main_btn("⚙️ EINSTELLUNGEN", func() -> void: show_page(Page.SETTINGS))
	_extra_btn = _add_main_btn("📊 BESTENLISTE", func() -> void: show_page(Page.EXTRA))
	_extra_btn.visible = false
	_refresh_main_focus()

	# --- SUBPAGES ---
	players_box = _make_subpage(root_vbox, Page.PLAYERS, "SPIELER & STEUERUNG")
	arena_box = _make_subpage(root_vbox, Page.ARENA, "ARENA")
	match_box = _make_subpage(root_vbox, Page.MATCH, "MATCH & REGELN")
	settings_box = _make_subpage(root_vbox, Page.SETTINGS, "EINSTELLUNGEN")
	extra_box = _make_subpage(root_vbox, Page.EXTRA, "BESTENLISTE")

	_build_default_settings()
	show_page(Page.MAIN)

func _add_main_btn(label_text: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(420, 48)
	btn.focus_mode = Control.FOCUS_ALL
	btn.pressed.connect(cb)
	_main_vbox.add_child(btn)
	_main_btns.append(btn)
	return btn

func _make_subpage(parent: VBoxContainer, page: Page, header_text: String) -> VBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.add_theme_constant_override("separation", 12)
	wrap.visible = false
	parent.add_child(wrap)
	_pages[page] = wrap

	var hdr := Label.new()
	hdr.text = header_text
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 22)
	hdr.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	wrap.add_child(hdr)

	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	wrap.add_child(content)

	var back_btn := Button.new()
	back_btn.text = "← ZURÜCK"
	back_btn.custom_minimum_size = Vector2(240, 44)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.focus_mode = Control.FOCUS_ALL
	back_btn.pressed.connect(func() -> void: show_page(Page.MAIN))
	wrap.add_child(back_btn)
	_back_btns[page] = back_btn
	return content

func _build_default_settings() -> void:
	_master_slider = _make_slider_row(settings_box, "Master", 1.0, func(v: float) -> void: master_volume_changed.emit(v))
	_music_slider = _make_slider_row(settings_box, "Musik", 0.85, func(v: float) -> void: music_volume_changed.emit(v))
	_sfx_slider = _make_slider_row(settings_box, "SFX", 1.0, func(v: float) -> void: sfx_volume_changed.emit(v))

	_fs_btn = Button.new()
	_fs_btn.custom_minimum_size = Vector2(360, 44)
	_fs_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_fs_btn.text = "Vollbild: AN" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "Vollbild: AUS"
	_fs_btn.pressed.connect(func() -> void:
		var is_fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
		_fs_btn.text = "Vollbild: AUS" if is_fs else "Vollbild: AN"
	)
	settings_box.add_child(_fs_btn)

	_touch_btn = Button.new()
	_touch_btn.custom_minimum_size = Vector2(360, 44)
	_touch_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_touch_btn.text = "Touch-Buttons umschalten"
	_touch_btn.pressed.connect(func() -> void: touch_toggled.emit())
	settings_box.add_child(_touch_btn)

	wire_subpage_focus(Page.SETTINGS, [_master_slider, _music_slider, _sfx_slider, _fs_btn, _touch_btn])

func _make_slider_row(parent: VBoxContainer, label_text: String, initial: float, cb: Callable) -> HSlider:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(460, 34)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(100, 0)
	lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(cb)
	row.add_child(slider)
	return slider

func enable_extra_page(button_label: String) -> void:
	_extra_btn.text = button_label
	_extra_btn.visible = true
	_refresh_main_focus()

func set_summary(text: String) -> void:
	if _summary_lbl:
		_summary_lbl.text = text

func get_back_button(page: Page) -> Button:
	return _back_btns.get(page)

func wire_subpage_focus(page: Page, controls: Array) -> void:
	var all_ctrls: Array = controls.duplicate()
	var back_btn: Button = _back_btns.get(page)
	if is_instance_valid(back_btn):
		all_ctrls.append(back_btn)
	if not all_ctrls.is_empty():
		_page_first_focus[page] = all_ctrls[0]
	call_deferred("_apply_vertical_focus", all_ctrls)

func _apply_vertical_focus(all_ctrls: Array) -> void:
	CouchNav.wire_vertical_focus(all_ctrls, true)

func _refresh_main_focus() -> void:
	var visible_btns: Array = []
	for b in _main_btns:
		if b.visible:
			visible_btns.append(b)
	call_deferred("_apply_vertical_focus", visible_btns)

func show_page(page: Page) -> void:
	current_page = page
	for p in _pages:
		_pages[p].visible = (p == page)
	if page == Page.SETTINGS:
		if _master_slider:
			_master_slider.set_value_no_signal(CouchNav.get_bus_linear(&"Master", _master_slider.value))
		if _music_slider:
			_music_slider.set_value_no_signal(CouchNav.get_bus_linear(&"Music", _music_slider.value))
		if _sfx_slider:
			_sfx_slider.set_value_no_signal(CouchNav.get_bus_linear(&"SFX", _sfx_slider.value))
	if page == Page.MAIN:
		back_to_main.emit()
		if is_instance_valid(_start_btn):
			_start_btn.call_deferred("grab_focus")
	else:
		var target: Control = _page_first_focus.get(page, _back_btns.get(page))
		if is_instance_valid(target):
			target.call_deferred("grab_focus")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if current_page != Page.MAIN and CouchNav.is_back(event):
		get_viewport().set_input_as_handled()
		show_page(Page.MAIN)
		return
	if current_page == Page.MAIN and CouchNav.is_start(event) and not (event is InputEventKey and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		start_requested.emit()
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A and not event.is_action("ui_accept"):
		if CouchNav.activate_focused(get_viewport()):
			get_viewport().set_input_as_handled()
