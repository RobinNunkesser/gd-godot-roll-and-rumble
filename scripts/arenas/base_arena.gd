class_name BaseArena
extends Node3D

const RollConfig = preload("res://scripts/config.gd")

enum ArenaType {
	CLASSIC_RING,
	DIZZY_SPINNER,
	WOBBLY_SEESAW
}

var arena_name: String = "Base Arena"
var arena_description: String = "Standard Arena"

func get_spawn_positions(count: int) -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var dist = RollConfig.ARENA_RADIUS * 0.55
	for i in range(count):
		var angle = (float(i) / float(count)) * TAU
		spots.append(Vector3(cos(angle) * dist, RollConfig.BALL_RADIUS + 0.1, sin(angle) * dist))
	return spots

func reset_arena() -> void:
	pass

func update_arena(_delta: float, _players: Array = []) -> void:
	pass

## Universelle Material- & Textur-Factory
## Garantiert, dass spätere PBR-Texturen, Normal-Maps und Shader-Effekte
## an genau einer Stelle definiert werden und sofort auf alle Arenen wirken.
static func get_surface_material(mat_type: String = "wood", tint: Color = Color.WHITE) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	match mat_type:
		"wood":
			mat.albedo_color = Color(0.22, 0.42, 0.72) * tint
			mat.roughness = 0.5
		"metal_rim":
			mat.albedo_color = Color(0.18, 0.24, 0.32) * tint
			mat.metallic = 0.65
			mat.roughness = 0.35
		"hazard_rotor":
			mat.albedo_color = Color(0.95, 0.45, 0.15) * tint
			mat.metallic = 0.5
			mat.roughness = 0.3
		"pivot":
			mat.albedo_color = Color(0.2, 0.22, 0.26) * tint
			mat.metallic = 0.8
			mat.roughness = 0.3
		"accent_knob":
			mat.albedo_color = Color(0.95, 0.82, 0.25) * tint
			mat.metallic = 0.7
			mat.roughness = 0.25
		"stripe_dark":
			mat.albedo_color = Color(0.12, 0.12, 0.15) * tint
			mat.roughness = 0.7
		"seesaw_deck":
			mat.albedo_color = Color(0.68, 0.24, 0.28) * tint
			mat.metallic = 0.6
			mat.roughness = 0.35
		_:
			mat.albedo_color = tint
	return mat

