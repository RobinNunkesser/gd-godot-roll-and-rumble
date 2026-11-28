class_name PlayerInputSlot
extends RefCounted

enum DeviceType {
	NONE,
	KEYBOARD_WASD,
	KEYBOARD_ARROWS,
	KEYBOARD_IJKL,
	JOYPAD
}

var slot_index: int = 0
var device_type: DeviceType = DeviceType.NONE
var joypad_id: int = -1
var deadzone: float = 0.2

# Custom mapping overrides (Action -> Array of Keycodes / Joypad Buttons)
var custom_key_bindings: Dictionary = {}
var _prev_action_state: Dictionary = {}

func _init(p_slot: int = 0, p_type: DeviceType = DeviceType.NONE, p_joy_id: int = -1) -> void:
	slot_index = p_slot
	device_type = p_type
	joypad_id = p_joy_id

## Liefert den 2D-Bewegungsvektor (Analog-Stick oder WASD/Pfeile)
func get_move_vector() -> Vector2:
	return get_move_for_device(device_type, joypad_id, deadzone)

static func get_move_for_device(p_type: DeviceType, p_joy_id: int = -1, p_deadzone: float = 0.2) -> Vector2:
	var vec := Vector2.ZERO
	if p_type == DeviceType.JOYPAD and p_joy_id >= 0:
		var x := Input.get_joy_axis(p_joy_id, JOY_AXIS_LEFT_X)
		var y := Input.get_joy_axis(p_joy_id, JOY_AXIS_LEFT_Y)
		if absf(x) < p_deadzone:
			x = 0.0
		if absf(y) < p_deadzone:
			y = 0.0
		if x == 0.0 and y == 0.0:
			if Input.is_joy_button_pressed(p_joy_id, JOY_BUTTON_DPAD_LEFT): x -= 1.0
			if Input.is_joy_button_pressed(p_joy_id, JOY_BUTTON_DPAD_RIGHT): x += 1.0
			if Input.is_joy_button_pressed(p_joy_id, JOY_BUTTON_DPAD_UP): y -= 1.0
			if Input.is_joy_button_pressed(p_joy_id, JOY_BUTTON_DPAD_DOWN): y += 1.0
		vec = Vector2(x, y)
	elif p_type == DeviceType.KEYBOARD_WASD:
		if Input.is_key_pressed(KEY_A): vec.x -= 1.0
		if Input.is_key_pressed(KEY_D): vec.x += 1.0
		if Input.is_key_pressed(KEY_W): vec.y -= 1.0
		if Input.is_key_pressed(KEY_S): vec.y += 1.0
	elif p_type == DeviceType.KEYBOARD_ARROWS:
		if Input.is_key_pressed(KEY_LEFT): vec.x -= 1.0
		if Input.is_key_pressed(KEY_RIGHT): vec.x += 1.0
		if Input.is_key_pressed(KEY_UP): vec.y -= 1.0
		if Input.is_key_pressed(KEY_DOWN): vec.y += 1.0
	elif p_type == DeviceType.KEYBOARD_IJKL:
		if Input.is_key_pressed(KEY_J): vec.x -= 1.0
		if Input.is_key_pressed(KEY_L): vec.x += 1.0
		if Input.is_key_pressed(KEY_I): vec.y -= 1.0
		if Input.is_key_pressed(KEY_K): vec.y += 1.0

	if vec.length_squared() > 1.0:
		vec = vec.normalized()
	return vec

## Prüft standardisierte Aktionen ("primary", "secondary", "tertiary", "drift", "start")
func is_action_pressed(action_name: String) -> bool:
	return _check_action(action_name, 0)

func is_action_just_pressed(action_name: String) -> bool:
	return _check_action(action_name, 1)

func is_action_just_released(action_name: String) -> bool:
	return _check_action(action_name, 2)

func _check_action(action: String, mode: int) -> bool:
	var pressed := is_action_for_device(device_type, joypad_id, action)
	var key := "%d:%d:%s" % [int(device_type), joypad_id, action.to_lower()]
	var prev: bool = _prev_action_state.get(key, false)
	_prev_action_state[key] = pressed
	if mode == 1:
		return pressed and not prev
	elif mode == 2:
		return not pressed and prev
	return pressed

static func is_action_for_device(p_type: DeviceType, p_joy_id: int, action: String) -> bool:
	var act := action.to_lower()
	if p_type == DeviceType.JOYPAD and p_joy_id >= 0:
		match act:
			"primary", "jump", "fire", "gas", "select":
				return Input.is_joy_button_pressed(p_joy_id, JOY_BUTTON_A) or Input.get_joy_axis(p_joy_id, JOY_AXIS_TRIGGER_RIGHT) > 0.25
			"secondary", "special", "nitro", "bomb", "boost":
				return Input.is_joy_button_pressed(p_joy_id, JOY_BUTTON_B) or Input.is_joy_button_pressed(p_joy_id, JOY_BUTTON_RIGHT_SHOULDER)
			"tertiary", "brake", "dash":
				return Input.is_joy_button_pressed(p_joy_id, JOY_BUTTON_X) or Input.get_joy_axis(p_joy_id, JOY_AXIS_TRIGGER_LEFT) > 0.25
			"drift":
				return Input.is_joy_button_pressed(p_joy_id, JOY_BUTTON_RIGHT_SHOULDER)
			"start", "pause":
				return Input.is_joy_button_pressed(p_joy_id, JOY_BUTTON_START)
		return false

	var key := KEY_NONE
	if p_type == DeviceType.KEYBOARD_WASD:
		match act:
			"primary", "jump", "fire", "gas", "select": key = KEY_SPACE
			"secondary", "special", "nitro", "bomb", "boost": key = KEY_E
			"tertiary", "brake", "dash": key = KEY_Q
			"start", "pause": key = KEY_ESCAPE
		return (key != KEY_NONE and Input.is_key_pressed(key)) or (act in ["secondary", "special", "nitro", "bomb", "boost"] and Input.is_key_pressed(KEY_SHIFT))
	elif p_type == DeviceType.KEYBOARD_ARROWS:
		match act:
			"primary", "jump", "fire", "gas", "select": key = KEY_ENTER
			"secondary", "special", "nitro", "bomb", "boost": key = KEY_SHIFT
			"tertiary", "brake", "dash": key = KEY_PERIOD
			"start", "pause": key = KEY_ESCAPE
		return (key != KEY_NONE and Input.is_key_pressed(key)) or (act in ["secondary", "special", "nitro", "bomb", "boost"] and (Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_KP_ENTER)))
	elif p_type == DeviceType.KEYBOARD_IJKL:
		match act:
			"primary", "jump", "fire", "gas", "select": key = KEY_U
			"secondary", "special", "nitro", "bomb", "boost": key = KEY_O
			"tertiary", "brake", "dash": key = KEY_H
			"start", "pause": key = KEY_ESCAPE
		return key != KEY_NONE and Input.is_key_pressed(key)
	return false

## Singleplayer-Komforthelfer: kombiniert WASD + Pfeiltasten + Gamepad 0 (Stick & D-Pad).
static func get_singleplayer_move(dz: float = 0.2) -> Vector2:
	var v := get_move_for_device(DeviceType.KEYBOARD_WASD, -1, dz)
	if v == Vector2.ZERO:
		v = get_move_for_device(DeviceType.KEYBOARD_ARROWS, -1, dz)
	if v == Vector2.ZERO and Input.get_connected_joypads().size() > 0:
		v = get_move_for_device(DeviceType.JOYPAD, 0, dz)
	return v
