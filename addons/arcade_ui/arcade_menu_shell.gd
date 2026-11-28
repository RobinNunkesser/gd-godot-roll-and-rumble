class_name ArcadeMenuShell
extends Control

const ArcadeTheme = preload("res://addons/arcade_ui/arcade_theme.gd")
const ArcadeNav = preload("res://addons/arcade_ui/arcade_nav.gd")
const ArcadeDefaults = preload("res://addons/arcade_ui/arcade_defaults.gd")
const ArcadeAudio = preload("res://addons/arcade_ui/arcade_audio.gd")

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
var auto_fullscreen: bool = true
var auto_lobby_music: bool = true
var audio: ArcadeAudio
var _focus_sfx_ready: bool = false

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
	name = "ArcadeMenuShell"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = ArcadeTheme.build()
	_build_shell(game_title, subtitle_text)

func _ready() -> void:
	audio = ArcadeAudio.new()
	add_child(audio)
	if auto_lobby_music:
		audio.start_lobby_music()
	var vp := get_viewport()
	if vp:
		vp.gui_focus_changed.connect(func(_c: Control) -> void:
			if _focus_sfx_ready and visible and audio:
				audio.play_sfx("move")
		)
	call_deferred("_enable_focus_sfx")

	if auto_fullscreen:
		ArcadeDefaults.apply_fullscreen()
		if _fs_btn:
			_fs_btn.text = "Vollbild: AN" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "Vollbild: AUS"

func _enable_focus_sfx() -> void:
	_focus_sfx_ready = true

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

	_start_btn = _add_main_btn("▶ SPIEL STARTEN", func() -> void:
		if audio:
			audio.play_sfx("confirm")
			if auto_lobby_music:
				audio.stop_lobby_music()
		start_requested.emit()
	)
	_players_btn = _add_main_btn("👥 SPIELER & STEUERUNG", func() -> void:
		if audio: audio.play_sfx("confirm")
		show_page(Page.PLAYERS)
	)
	_arena_btn = _add_main_btn("🏟️ ARENA", func() -> void:
		if audio: audio.play_sfx("confirm")
		show_page(Page.ARENA)
	)
	_match_btn = _add_main_btn("🏆 MATCH & REGELN", func() -> void:
		if audio: audio.play_sfx("confirm")
		show_page(Page.MATCH)
	)
	_settings_btn = _add_main_btn("⚙️ EINSTELLUNGEN", func() -> void:
		if audio: audio.play_sfx("confirm")
		show_page(Page.SETTINGS)
	)
	_extra_btn = _add_main_btn("📊 BESTENLISTE", func() -> void:
		if audio: audio.play_sfx("confirm")
		show_page(Page.EXTRA)
	)
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
	back_btn.pressed.connect(func() -> void:
		if audio: audio.play_sfx("back")
		show_page(Page.MAIN)
	)
	wrap.add_child(back_btn)
	_back_btns[page] = back_btn
	return content

func _build_default_settings() -> void:
	_master_slider = _make_slider_row(settings_box, "Master", 1.0, func(v: float) -> void:
		_set_bus_linear(&"Master", v)
		master_volume_changed.emit(v)
	)
	_music_slider = _make_slider_row(settings_box, "Musik", 0.85, func(v: float) -> void:
		_set_bus_linear(&"Music", v)
		music_volume_changed.emit(v)
	)
	_sfx_slider = _make_slider_row(settings_box, "SFX", 1.0, func(v: float) -> void:
		_set_bus_linear(&"SFX", v)
		sfx_volume_changed.emit(v)
	)

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
	var row_box := PanelContainer.new()
	row_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var sb_idle := StyleBoxFlat.new()
	sb_idle.bg_color = Color(0.10, 0.13, 0.21, 0.72)
	sb_idle.border_color = Color(0.24, 0.30, 0.45, 0.65)
	sb_idle.set_border_width_all(2)
	sb_idle.set_corner_radius_all(8)
	sb_idle.set_content_margin_all(8)
	var sb_focus := sb_idle.duplicate()
	sb_focus.bg_color = Color(0.17, 0.22, 0.35, 0.96)
	sb_focus.border_color = Color(1.0, 0.78, 0.2)
	sb_focus.set_border_width_all(3)
	row_box.add_theme_stylebox_override("panel", sb_idle)
	parent.add_child(row_box)

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(460, 34)
	row.add_theme_constant_override("separation", 12)
	row_box.add_child(row)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(120, 0)
	lbl.add_theme_font_size_override("font_size", 16)
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_ALL
	slider.value_changed.connect(cb)
	slider.focus_entered.connect(func() -> void:
		row_box.add_theme_stylebox_override("panel", sb_focus)
		lbl.text = "▶ " + label_text
		lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28))
	)
	slider.focus_exited.connect(func() -> void:
		row_box.add_theme_stylebox_override("panel", sb_idle)
		lbl.text = label_text
		lbl.remove_theme_color_override("font_color")
	)
	row.add_child(slider)
	return slider

func _set_bus_linear(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, linear <= 0.001)
	if linear > 0.001:
		AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

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
	_apply_vertical_focus(all_ctrls)

func wire_players_cards(cards: Array) -> void:
	var first := ArcadeNav.wire_player_cards(cards, _back_btns.get(Page.PLAYERS))
	if is_instance_valid(first):
		_page_first_focus[Page.PLAYERS] = first

func _apply_vertical_focus(all_ctrls: Array) -> void:
	ArcadeNav.wire_vertical_focus(all_ctrls, true)

func _refresh_main_focus() -> void:
	var visible_btns: Array = []
	for b in _main_btns:
		if b.visible:
			visible_btns.append(b)
	_apply_vertical_focus(visible_btns)

## Konfiguriert das Menü für Singleplayer- oder benutzerdefinierte Modi (blendet ungenutzte Tabs aus und passt Labels an).
func set_singleplayer_mode(enabled: bool, arena_label: String = "🏟️ LEVEL / MODUS", match_label: String = "⚙️ OPTIONEN", extra_label: String = "📊 HIGHSCORES") -> void:
	configure_profile({
		"show_players": not enabled,
		"arena_label": arena_label if enabled else "🏟️ ARENA",
		"match_label": match_label if enabled else "🏆 MATCH & REGELN",
		"extra_label": extra_label if enabled else "📊 BESTENLISTE",
		"show_extra": enabled
	})

func configure_profile(opts: Dictionary) -> void:
	if _players_btn and opts.has("show_players"):
		_players_btn.visible = bool(opts["show_players"])
	if _arena_btn:
		if opts.has("show_arena"):
			_arena_btn.visible = bool(opts["show_arena"])
		if opts.has("arena_label"):
			_arena_btn.text = str(opts["arena_label"])
	if _match_btn:
		if opts.has("show_match"):
			_match_btn.visible = bool(opts["show_match"])
		if opts.has("match_label"):
			_match_btn.text = str(opts["match_label"])
	if _extra_btn:
		if opts.has("show_extra"):
			_extra_btn.visible = bool(opts["show_extra"])
		if opts.has("extra_label"):
			_extra_btn.text = str(opts["extra_label"])
	_refresh_main_focus()

func show_page(page: Page) -> void:
	current_page = page
	for p in _pages:
		_pages[p].visible = (p == page)
	if page == Page.SETTINGS:
		if _master_slider:
			_master_slider.set_value_no_signal(ArcadeNav.get_bus_linear(&"Master", _master_slider.value))
		if _music_slider:
			_music_slider.set_value_no_signal(ArcadeNav.get_bus_linear(&"Music", _music_slider.value))
		if _sfx_slider:
			_sfx_slider.set_value_no_signal(ArcadeNav.get_bus_linear(&"SFX", _sfx_slider.value))
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
	if current_page != Page.MAIN and ArcadeNav.is_back(event):
		get_viewport().set_input_as_handled()
		show_page(Page.MAIN)
		return
	if current_page == Page.MAIN and ArcadeNav.is_start(event) and not (event is InputEventKey and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		start_requested.emit()
		return
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A and not event.is_action("ui_accept"):
		if ArcadeNav.activate_focused(get_viewport()):
			get_viewport().set_input_as_handled()
