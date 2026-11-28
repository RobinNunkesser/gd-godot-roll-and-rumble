class_name ArcadeMatchOverOverlay
extends Control

const ArcadeTheme = preload("res://addons/arcade_ui/arcade_theme.gd")
const ArcadeNav = preload("res://addons/arcade_ui/arcade_nav.gd")

## Einheitlicher Match-/Cup-Abschluss-Screen für Couch-Multiplayer-Spiele (Gamepad + Touch + Maus).

signal rematch_pressed
signal lobby_pressed

var winner_label: Label
var score_label: Label
var custom_box: VBoxContainer
var rematch_btn: Button
var lobby_btn: Button

func _init() -> void:
	name = "ArcadeMatchOverOverlay"
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	theme = ArcadeTheme.build()
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
	card.custom_minimum_size = Vector2(480, 0)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	winner_label = Label.new()
	winner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner_label.add_theme_font_size_override("font_size", 30)
	winner_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	vbox.add_child(winner_label)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(score_label)

	custom_box = VBoxContainer.new()
	custom_box.add_theme_constant_override("separation", 6)
	vbox.add_child(custom_box)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 14)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	rematch_btn = Button.new()
	rematch_btn.text = "▶ REMATCH"
	rematch_btn.custom_minimum_size = Vector2(200, 48)
	rematch_btn.pressed.connect(func() -> void:
		visible = false
		rematch_pressed.emit()
	)
	btn_row.add_child(rematch_btn)

	lobby_btn = Button.new()
	lobby_btn.text = "ZURÜCK ZUR LOBBY"
	lobby_btn.custom_minimum_size = Vector2(200, 48)
	lobby_btn.pressed.connect(func() -> void:
		visible = false
		lobby_pressed.emit()
	)
	btn_row.add_child(lobby_btn)

	ArcadeNav.wire_row_focus([rematch_btn, lobby_btn], true)

func open(winner_text: String, score_text: String = "", rematch_text: String = "▶ REMATCH") -> void:
	if winner_label:
		winner_label.text = winner_text
	if score_label:
		score_label.text = score_text
		score_label.visible = score_text != ""
	if rematch_btn:
		rematch_btn.text = rematch_text
	visible = true
	if rematch_btn:
		rematch_btn.call_deferred("grab_focus")

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if ArcadeNav.is_back(event):
		get_viewport().set_input_as_handled()
		visible = false
		lobby_pressed.emit()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A and not event.is_action("ui_accept"):
		if ArcadeNav.activate_focused(get_viewport()):
			get_viewport().set_input_as_handled()
