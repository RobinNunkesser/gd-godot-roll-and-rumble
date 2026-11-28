class_name ArcadeDefaults
extends RefCounted

## Smarte Controller- und Spieler-Defaults für Couch-Multiplayer-Spiele.
## 1 Gamepad -> P1=Gamepad 0, P2..P4=Bots. N Gamepads -> P1..PN=Gamepad 0..N-1. 0 Gamepads -> P1=KB1, P2..P4=Bots.

## Für Messe-/Werbeauftritte zentral auf true setzen und per sync_addons.py verteilen.
const SHOW_BRANDING_BY_DEFAULT: bool = false

static func detect_slot_modes(slot_count: int = 4) -> Array[Dictionary]:
	var pads: Array[int] = Input.get_connected_joypads()
	var result: Array[Dictionary] = []
	for i in range(slot_count):
		if i < pads.size():
			result.append({"kind": "gamepad", "device": pads[i]})
		elif i == 0 and pads.is_empty():
			result.append({"kind": "keyboard", "device": 0})
		else:
			result.append({"kind": "bot", "device": -1})
	return result

static func apply_fullscreen() -> void:
	if DisplayServer.get_name() == "headless" or OS.has_feature("embedded"):
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
