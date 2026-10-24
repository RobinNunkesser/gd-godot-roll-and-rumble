class_name BaseArena
extends Node3D

const RollConfig = preload("res://scripts/config.gd")

enum ArenaType {
	CLASSIC_RING,
	DIZZY_SPINNER,
	WOBBLY_SEESAW,
	BUMPER_PINBALL,
	ICE_SLICK
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

const TEXTURE_WOOD_PATH = "res://assets/textures/wood_deck.jpg"
const TEXTURE_HAZARD_PATH = "res://assets/textures/hazard_rotor.jpg"
const TEXTURE_METAL_PATH = "res://assets/textures/metal_rim.jpg"
const TEXTURE_ICE_PATH = "res://assets/textures/ice_slick.jpg"

## Universelle Material- & Textur-Factory
## Garantiert, dass spätere PBR-Texturen, Normal-Maps und Shader-Effekte
## an genau einer Stelle definiert werden und sofort auf alle Arenen wirken.
static func get_surface_material(mat_type: String = "wood", tint: Color = Color.WHITE) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	match mat_type:
		"wood":
			if ResourceLoader.exists(TEXTURE_WOOD_PATH):
				mat.albedo_texture = load(TEXTURE_WOOD_PATH)
				mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
			mat.albedo_color = Color(1.0, 0.95, 0.9) * tint
			mat.roughness = 0.35
			mat.metallic = 0.1
		"metal_rim":
			if ResourceLoader.exists(TEXTURE_METAL_PATH):
				mat.albedo_texture = load(TEXTURE_METAL_PATH)
				mat.uv1_scale = Vector3(2.0, 2.0, 2.0)
			mat.albedo_color = Color(0.85, 0.9, 0.95) * tint
			mat.metallic = 0.75
			mat.roughness = 0.3
		"hazard_rotor":
			if ResourceLoader.exists(TEXTURE_HAZARD_PATH):
				mat.albedo_texture = load(TEXTURE_HAZARD_PATH)
				mat.uv1_scale = Vector3(3.0, 3.0, 3.0)
			mat.albedo_color = Color(1.0, 0.9, 0.8) * tint
			mat.metallic = 0.5
			mat.roughness = 0.25
			mat.emission_enabled = true
			mat.emission = Color(0.95, 0.45, 0.1)
			mat.emission_energy_multiplier = 0.25
		"pivot":
			if ResourceLoader.exists(TEXTURE_METAL_PATH):
				mat.albedo_texture = load(TEXTURE_METAL_PATH)
				mat.uv1_scale = Vector3(2.0, 2.0, 2.0)
			mat.albedo_color = Color(0.4, 0.45, 0.5) * tint
			mat.metallic = 0.85
			mat.roughness = 0.25
		"accent_knob":
			mat.albedo_color = Color(0.98, 0.85, 0.25) * tint
			mat.metallic = 0.85
			mat.roughness = 0.2
		"stripe_dark":
			mat.albedo_color = Color(0.12, 0.12, 0.15) * tint
			mat.roughness = 0.7
		"seesaw_deck":
			if ResourceLoader.exists(TEXTURE_WOOD_PATH):
				mat.albedo_texture = load(TEXTURE_WOOD_PATH)
				mat.uv1_scale = Vector3(4.0, 4.0, 4.0)
			mat.albedo_color = Color(0.9, 0.5, 0.5) * tint # Mahagoni / Rubin-gebeiztes Holz
			mat.metallic = 0.25
			mat.roughness = 0.35
		"ice":
			if ResourceLoader.exists(TEXTURE_ICE_PATH):
				mat.albedo_texture = load(TEXTURE_ICE_PATH)
				mat.uv1_scale = Vector3(3.0, 3.0, 3.0)
			mat.albedo_color = Color(0.85, 0.95, 1.0) * tint
			mat.roughness = 0.04
			mat.metallic = 0.15
			mat.clearcoat_enabled = true
			mat.clearcoat = 1.0
			mat.clearcoat_roughness = 0.05
		"bumper_ring":
			mat.albedo_color = Color(0.95, 0.2, 0.6) * tint # Neon-Magenta
			mat.metallic = 0.4
			mat.roughness = 0.2
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.15, 0.7)
			mat.emission_energy_multiplier = 1.5
		"bumper_cap":
			mat.albedo_color = Color(0.95, 0.85, 0.2) * tint # Golden Chrome
			mat.metallic = 0.9
			mat.roughness = 0.15
		_:
			mat.albedo_color = tint
	return mat

