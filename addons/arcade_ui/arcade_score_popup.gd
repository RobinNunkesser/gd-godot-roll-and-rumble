class_name ArcadeScorePopup
extends Label

## Aufsteigender, ausfadender Punkte-/Kombo-Popup-Text.

static func spawn(parent: Node, pos: Vector2, text_value: String, color: Color = Color(1.0, 0.85, 0.25)) -> ArcadeScorePopup:
	var pop := ArcadeScorePopup.new()
	pop.text = text_value
	pop.position = pos
	pop.z_index = 50
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.add_theme_font_size_override("font_size", 24)
	pop.add_theme_color_override("font_color", color)
	pop.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.12))
	pop.add_theme_constant_override("outline_size", 5)
	parent.add_child(pop)

	if DisplayServer.get_name() != "headless" and pop.is_inside_tree():
		var tw := pop.create_tween().set_parallel(true)
		tw.tween_property(pop, "position:y", pos.y - 44.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(pop, "modulate:a", 0.0, 0.65).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(pop.queue_free)
	return pop
