class_name ArcadeTouchOverlay
extends CanvasLayer

## Gemeinsames Multi-Touch-Overlay für Tablets & WASM-Browser (Desktop standardmäßig aus).
## Unterstützt Analogstick (z. B. Roll & Rumble, Crazy Cage) und 4-Wege-D-Pad (z. B. ClanBomber).

enum StickMode { ANALOG, DPAD_4WAY }

signal primary_pressed
signal secondary_pressed
signal pause_pressed

@export var stick_mode: StickMode = StickMode.ANALOG
@export var primary_label: String = "BOOST"
@export var secondary_label: String = ""
@export var force_visible: bool = false
@export var stick_radius: float = 72.0
@export var deadzone: float = 0.15

var is_touch_active: bool = false
var is_gameplay_active: bool = false
var input_vector: Vector2 = Vector2.ZERO
var dpad_direction: Vector2i = Vector2i.ZERO
var primary_down: bool = false
var secondary_down: bool = false

var _stick_touch_id: int = -1
var _stick_center: Vector2 = Vector2.ZERO

var root_control: Control
var stick_base: Panel
var stick_knob: Panel
var _stick_style: StyleBoxFlat
var _knob_style: StyleBoxFlat
var _accent_color: Color = Color(1.0, 0.78, 0.2)
var primary_btn: Button
var secondary_btn: Button
var pause_btn: Button

func _ready() -> void:
	layer = 20
	detect_touch_device()
	_build_ui()
	_update_visibility()
	var vp := get_viewport()
	if vp and not vp.size_changed.is_connected(_on_viewport_resized):
		vp.size_changed.connect(_on_viewport_resized)

func detect_touch_device() -> void:
	if force_visible:
		is_touch_active = true
		return
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		is_touch_active = true
		return
	if OS.has_feature("web"):
		if OS.has_feature("web_android") or OS.has_feature("web_ios"):
			is_touch_active = true
			return
		if Engine.has_singleton("JavaScriptBridge"):
			var js = Engine.get_singleton("JavaScriptBridge")
			var touch_points = js.eval("('maxTouchPoints' in navigator) ? navigator.maxTouchPoints : 0")
			if touch_points != null and int(touch_points) > 0:
				is_touch_active = true
				return
		is_touch_active = false
		return
	is_touch_active = false

func toggle_touch_overlay() -> bool:
	is_touch_active = not is_touch_active
	_reset_stick()
	_update_visibility()
	return is_touch_active

func set_gameplay_active(active: bool) -> void:
	is_gameplay_active = active
	if not active:
		_reset_stick()
		primary_down = false
		secondary_down = false
	_update_visibility()

func _get_viewport_size() -> Vector2:
	var vp := get_viewport()
	if vp:
		return vp.get_visible_rect().size
	return Vector2(1280.0, 720.0)

func _update_visibility() -> void:
	if not is_instance_valid(root_control):
		return
	root_control.visible = is_touch_active
	var active := is_touch_active and is_gameplay_active
	if is_instance_valid(stick_base):
		stick_base.visible = active
	if is_instance_valid(primary_btn):
		primary_btn.visible = active
	if is_instance_valid(secondary_btn):
		secondary_btn.visible = active and secondary_label != ""
	if is_instance_valid(pause_btn):
		pause_btn.visible = active

func _build_ui() -> void:
	root_control = Control.new()
	root_control.name = "CouchTouchRoot"
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	stick_base = Panel.new()
	stick_base.name = "StickBase"
	stick_base.custom_minimum_size = Vector2(stick_radius * 2.0, stick_radius * 2.0)
	stick_base.size = stick_base.custom_minimum_size
	stick_base.mouse_filter = Control.MOUSE_FILTER_STOP
	stick_base.gui_input.connect(_on_stick_gui_input)
	_stick_style = StyleBoxFlat.new()
	_stick_style.set_corner_radius_all(int(stick_radius))
	_stick_style.bg_color = Color(0.08, 0.10, 0.16, 0.48)
	_stick_style.border_color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.75)
	_stick_style.set_border_width_all(3)
	stick_base.add_theme_stylebox_override("panel", _stick_style)
	root_control.add_child(stick_base)

	stick_knob = Panel.new()
	stick_knob.name = "StickKnob"
	stick_knob.custom_minimum_size = Vector2(56, 56)
	stick_knob.size = stick_knob.custom_minimum_size
	stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_knob_style = StyleBoxFlat.new()
	_knob_style.set_corner_radius_all(28)
	_knob_style.bg_color = Color(_accent_color.r, _accent_color.g, _accent_color.b, 0.85)
	stick_knob.add_theme_stylebox_override("panel", _knob_style)
	stick_base.add_child(stick_knob)

	primary_btn = _make_action_btn(primary_label, Color(0.95, 0.35, 0.20, 0.85), Vector2(110, 110))
	primary_btn.button_down.connect(func() -> void:
		primary_down = true
		primary_pressed.emit()
	)
	primary_btn.button_up.connect(func() -> void:
		primary_down = false
	)
	root_control.add_child(primary_btn)

	secondary_btn = _make_action_btn(secondary_label if secondary_label != "" else "ACT", Color(0.22, 0.65, 0.95, 0.85), Vector2(88, 88))
	secondary_btn.button_down.connect(func() -> void:
		secondary_down = true
		secondary_pressed.emit()
	)
	secondary_btn.button_up.connect(func() -> void:
		secondary_down = false
	)
	root_control.add_child(secondary_btn)

	pause_btn = _make_action_btn("II", Color(0.18, 0.22, 0.34, 0.85), Vector2(54, 54))
	pause_btn.pressed.connect(func() -> void: pause_pressed.emit())
	root_control.add_child(pause_btn)

	_layout_controls()

func _make_action_btn(label_text: String, bg: Color, sz: Vector2) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.custom_minimum_size = sz
	btn.size = sz
	btn.focus_mode = Control.FOCUS_NONE
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.set_corner_radius_all(int(sz.x * 0.5))
	st.border_color = Color(1, 1, 1, 0.6)
	st.set_border_width_all(2)
	btn.add_theme_stylebox_override("normal", st)
	btn.add_theme_stylebox_override("hover", st)
	btn.add_theme_stylebox_override("pressed", st)
	btn.add_theme_font_size_override("font_size", 18)
	return btn

func _layout_controls() -> void:
	_layout_controls_for_size(_get_viewport_size())

func _layout_controls_for_size(vp: Vector2) -> void:
	var margin := 16.0
	_stick_center = Vector2(
		maxf(stick_radius + margin, minf(130.0, vp.x * 0.24)),
		maxf(stick_radius + margin, vp.y - maxf(130.0, vp.y * 0.20))
	)
	if is_instance_valid(stick_base):
		stick_base.position = _stick_center - Vector2(stick_radius, stick_radius)
	_center_knob()
	if is_instance_valid(primary_btn):
		primary_btn.position = Vector2(
			maxf(margin, vp.x - primary_btn.size.x - margin),
			maxf(margin, vp.y - primary_btn.size.y - margin)
		)
	if is_instance_valid(secondary_btn):
		var secondary_y := primary_btn.position.y + (primary_btn.size.y - secondary_btn.size.y) * 0.5
		if vp.x < 640.0:
			secondary_y = maxf(margin + pause_btn.size.y + 12.0, primary_btn.position.y - secondary_btn.size.y - 12.0)
		var secondary_x := vp.x - secondary_btn.size.x - margin
		if vp.x >= 640.0:
			secondary_x = maxf(margin, primary_btn.position.x - secondary_btn.size.x - 16.0)
		secondary_btn.position = Vector2(secondary_x, secondary_y)
	if is_instance_valid(pause_btn):
		pause_btn.position = Vector2(vp.x - pause_btn.size.x - margin, margin)

func set_arcade_accent(accent: Color) -> void:
	_accent_color = accent
	if _stick_style:
		_stick_style.border_color = Color(accent.r, accent.g, accent.b, 0.75)
	if _knob_style:
		_knob_style.bg_color = Color(accent.r, accent.g, accent.b, 0.85)

func _on_viewport_resized() -> void:
	_layout_controls()

func _center_knob() -> void:
	if is_instance_valid(stick_knob):
		stick_knob.position = Vector2(stick_radius, stick_radius) - stick_knob.size * 0.5

func _reset_stick() -> void:
	_stick_touch_id = -1
	input_vector = Vector2.ZERO
	dpad_direction = Vector2i.ZERO
	_center_knob()

func _update_stick_from_local(local_pos: Vector2) -> void:
	var offset := local_pos - Vector2(stick_radius, stick_radius)
	var dist := offset.length()
	var clamped := offset if dist <= stick_radius else offset.normalized() * stick_radius
	if is_instance_valid(stick_knob):
		stick_knob.position = Vector2(stick_radius, stick_radius) + clamped - stick_knob.size * 0.5
	var norm := clamped / stick_radius
	if norm.length() < deadzone:
		input_vector = Vector2.ZERO
		dpad_direction = Vector2i.ZERO
		return
	input_vector = norm
	if absf(norm.x) > absf(norm.y):
		dpad_direction = Vector2i(1 if norm.x > 0.0 else -1, 0)
	else:
		dpad_direction = Vector2i(0, 1 if norm.y > 0.0 else -1)
	if stick_mode == StickMode.DPAD_4WAY:
		input_vector = Vector2(dpad_direction)

func _on_stick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _stick_touch_id == -1:
			_stick_touch_id = event.index
			_update_stick_from_local(event.position)
		elif not event.pressed and event.index == _stick_touch_id:
			_reset_stick()
	elif event is InputEventScreenDrag and event.index == _stick_touch_id:
		_update_stick_from_local(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_stick_touch_id = 0
			_update_stick_from_local(event.position)
		else:
			_reset_stick()
	elif event is InputEventMouseMotion and _stick_touch_id == 0 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		_update_stick_from_local(event.position)
