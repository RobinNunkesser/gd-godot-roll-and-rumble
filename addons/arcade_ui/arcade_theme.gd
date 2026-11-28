class_name ArcadeTheme
extends RefCounted

## Einheitliches Arcade-Dark-Theme mit klarem Gamepad-Focus-Rahmen für Couch-Multiplayer-Menüs.

enum Preset { RETRO_GOLD, CYBER_CYAN, NEON_GREEN, SPORTS_BLUE, CRIMSON }

static func preset_accent(preset: Preset) -> Color:
	match preset:
		Preset.CYBER_CYAN:
			return Color(0.18, 0.90, 1.0)
		Preset.NEON_GREEN:
			return Color(0.32, 0.95, 0.48)
		Preset.SPORTS_BLUE:
			return Color(0.35, 0.68, 1.0)
		Preset.CRIMSON:
			return Color(1.0, 0.34, 0.38)
		_:
			return Color(1.0, 0.78, 0.2)

static func preset_name(preset: Preset) -> String:
	match preset:
		Preset.CYBER_CYAN:
			return "CYBER CYAN"
		Preset.NEON_GREEN:
			return "NEON GREEN"
		Preset.SPORTS_BLUE:
			return "SPORTS BLUE"
		Preset.CRIMSON:
			return "CRIMSON"
		_:
			return "RETRO GOLD"

static func build_preset(preset: Preset) -> Theme:
	return build(preset_accent(preset))

static func build(accent: Color = Color(1.0, 0.78, 0.2)) -> Theme:
	var theme := Theme.new()

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.14, 0.22, 0.94)
	normal.border_color = Color(0.28, 0.34, 0.50, 0.9)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(10)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.18, 0.22, 0.34, 0.98)
	hover.border_color = accent

	var focus := normal.duplicate()
	focus.bg_color = Color(0.20, 0.25, 0.38, 1.0)
	focus.border_color = accent
	focus.set_border_width_all(3)
	focus.shadow_color = Color(accent.r, accent.g, accent.b, 0.42)
	focus.shadow_size = 8

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.08, 0.10, 0.16, 1.0)
	pressed.border_color = accent

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("focus", "Button", focus)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_color("font_color", "Button", Color(0.95, 0.97, 1.0))
	theme.set_color("font_focus_color", "Button", accent)
	theme.set_color("font_hover_color", "Button", accent)
	theme.set_font_size("font_size", "Button", 18)

	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.07, 0.08, 0.14, 0.95)
	panel.border_color = accent
	panel.set_border_width_all(3)
	panel.set_corner_radius_all(14)
	panel.set_content_margin_all(20)
	panel.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	panel.shadow_size = 14
	theme.set_stylebox("panel", "PanelContainer", panel)

	var slider_bg := StyleBoxFlat.new()
	slider_bg.bg_color = Color(0.18, 0.22, 0.34, 0.95)
	slider_bg.set_corner_radius_all(5)
	slider_bg.set_content_margin_all(5)
	var slider_fill := StyleBoxFlat.new()
	slider_fill.bg_color = Color(0.55, 0.68, 0.92, 0.95)
	slider_fill.set_corner_radius_all(5)
	var slider_fill_hi := StyleBoxFlat.new()
	slider_fill_hi.bg_color = accent
	slider_fill_hi.set_corner_radius_all(5)
	theme.set_stylebox("slider", "HSlider", slider_bg)
	theme.set_stylebox("grabber_area", "HSlider", slider_fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", slider_fill_hi)
	theme.set_icon("grabber", "HSlider", _make_grabber_icon(Color(0.85, 0.90, 1.0), Color(0.25, 0.32, 0.48)))
	theme.set_icon("grabber_highlight", "HSlider", _make_grabber_icon(accent, Color.WHITE))

	return theme

static func _make_grabber_icon(fill: Color, border: Color) -> ImageTexture:
	var img := Image.create(16, 22, false, Image.FORMAT_RGBA8)
	for y in range(22):
		for x in range(16):
			var edge := (x <= 1 or x >= 14 or y <= 1 or y >= 20)
			img.set_pixel(x, y, border if edge else fill)
	return ImageTexture.create_from_image(img)
