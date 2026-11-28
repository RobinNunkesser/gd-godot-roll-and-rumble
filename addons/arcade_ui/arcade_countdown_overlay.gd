class_name ArcadeCountdownOverlay
extends Control

## Animierter "3 - 2 - 1 - GO!" Countdown für Match- und Rundenstarts.

signal countdown_finished

var _label: Label
var _running: bool = false
var _accent_color: Color = Color(1.0, 0.85, 0.25)

func _init() -> void:
	name = "ArcadeCountdownOverlay"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 88)
	_label.add_theme_color_override("font_color", _accent_color)
	_label.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.12))
	_label.add_theme_constant_override("outline_size", 10)
	center.add_child(_label)

func set_arcade_accent(accent: Color) -> void:
	_accent_color = accent
	if _label:
		_label.add_theme_color_override("font_color", accent)

func start(steps: Array[String] = ["3", "2", "1", "GO!"], step_duration: float = 0.65, audio = null) -> void:
	if _running or steps.is_empty():
		return
	if DisplayServer.get_name() == "headless" or not is_inside_tree():
		visible = false
		countdown_finished.emit()
		return
	_running = true
	visible = true
	move_to_front()
	_run_steps(steps, step_duration, audio)

func _run_steps(steps: Array[String], step_duration: float, audio) -> void:
	for i in range(steps.size()):
		if not is_inside_tree() or not _running:
			break
		var is_last := (i == steps.size() - 1)
		_label.text = steps[i]
		_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.55) if is_last else _accent_color)
		_label.pivot_offset = _label.size * 0.5
		_label.scale = Vector2(1.45, 1.45)
		_label.modulate.a = 1.0
		if audio and audio.has_method("play_sfx"):
			audio.play_sfx("confirm" if is_last else "move")
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_label, "scale", Vector2.ONE, step_duration * 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_label, "modulate:a", 0.15 if not is_last else 0.0, step_duration * 0.9)
		await get_tree().create_timer(step_duration).timeout
	_running = false
	visible = false
	countdown_finished.emit()
