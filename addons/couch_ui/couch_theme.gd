class_name CouchTheme
extends RefCounted

## Einheitliches Arcade-Dark-Theme mit klarem Gamepad-Focus-Rahmen für Couch-Multiplayer-Menüs.

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
	theme.set_stylebox("panel", "PanelContainer", panel)

	return theme
