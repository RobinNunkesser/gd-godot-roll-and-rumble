class_name CouchPauseOverlay
extends Control

## Einheitliches Pause- & Audio-Overlay für Couch-Multiplayer-Spiele (Gamepad + Tastatur).

signal resumed
signal restarted
signal returned_to_lobby
signal music_toggled(muted: bool)
signal sfx_toggled(muted: bool)

var music_muted: bool = false
var sfx_muted: bool = false

var _resume_btn: Button
var _restart_btn: Button
var _lobby_btn: Button
var _music_btn: Button
var _sfx_btn: Button
var _fs_btn: Button

func _init() -> void:
	name = "CouchPauseOverlay"
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	theme = CouchTheme.build()
	_build_ui()

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.03, 0.07, 0.78)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(360, 0)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "PAUSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(title)

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

	_lobby_btn = Button.new()
	_lobby_btn.text = "Zurück zur Lobby"
	_lobby_btn.pressed.connect(func() -> void:
		close()
		returned_to_lobby.emit()
	)
	vbox.add_child(_lobby_btn)

	_music_btn = Button.new()
	_music_btn.text = "Musik: AN"
	_music_btn.pressed.connect(func() -> void:
		music_muted = not music_muted
		_music_btn.text = "Musik: AUS" if music_muted else "Musik: AN"
		music_toggled.emit(music_muted)
	)
	vbox.add_child(_music_btn)

	_sfx_btn = Button.new()
	_sfx_btn.text = "SFX: AN"
	_sfx_btn.pressed.connect(func() -> void:
		sfx_muted = not sfx_muted
		_sfx_btn.text = "SFX: AUS" if sfx_muted else "SFX: AN"
		sfx_toggled.emit(sfx_muted)
	)
	vbox.add_child(_sfx_btn)

	_fs_btn = Button.new()
	_fs_btn.text = "Vollbild: AN" if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else "Vollbild: AUS"
	_fs_btn.pressed.connect(func() -> void:
		var is_fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
		_fs_btn.text = "Vollbild: AUS" if is_fs else "Vollbild: AN"
	)
	vbox.add_child(_fs_btn)

	CouchNav.wire_vertical_focus([_resume_btn, _restart_btn, _lobby_btn, _music_btn, _sfx_btn, _fs_btn], true)

	var hint := Label.new()
	hint.text = "[D-Pad / ↑↓] Wählen  |  [A / Enter] OK  |  [B / Esc] Weiter"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(hint)

func open() -> void:
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
