class_name PowerUpToken
extends Area3D

## Schwebendes 3D-Pickup-Token für Roll & Rumble 3D (Phase 3)
## Bietet kontinuierliche Bobbing- & Dreh-Animation, distinct PBR-Meshes für alle 6 Archetypen
## und ein 3D-Billboard-Label für maximale Erkennbarkeit.

const RollConfig = preload("res://scripts/config.gd")
const RollSoundManager = preload("res://scripts/sound_manager.gd")
const LeaderboardManager = preload("res://scripts/leaderboard_manager.gd")

enum Type {
	ANVIL,          # 1. 🪨 Amboss (3x Masse, Dampfwalze)
	SPIKE_WHEEL,    # 2. ⚡ Stachelkugel (2x Stoßimpuls)
	NITRO_JET,      # 3. 🚀 Nitro-Jet (3 Sofort-Boosts ohne Cooldown)
	GHOST_PHASE,    # 4. 👻 Geisterkugel (Phasing durch Hindernisse)
	ICE_TRAIL,      # 5. ❄️ Frost-Aura (Glatteis-Spur)
	GRAVITY_MAGNET  # 6. 🧲 Gravitations-Magnet (Zieht Gegner an)
}

@export var powerup_type: Type = Type.ANVIL

var _bob_timer: float = 0.0
var _base_y: float = 0.85
var _mesh_node: Node3D
var _label: Label3D

func _init(type: Type = Type.ANVIL) -> void:
	name = "PowerUpToken_%s" % _get_type_name(type)
	powerup_type = type

func _ready() -> void:
	_base_y = position.y if position.y > 0.1 else 0.85
	_setup_collision()
	_setup_visuals()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _setup_collision() -> void:
	if not has_node("CollisionShape3D"):
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var sphere = SphereShape3D.new()
		sphere.radius = RollConfig.POWERUP_TOKEN_RADIUS
		col.shape = sphere
		add_child(col)

func _setup_visuals() -> void:
	_mesh_node = Node3D.new()
	_mesh_node.name = "TokenMeshPivot"
	add_child(_mesh_node)
	
	var inst = MeshInstance3D.new()
	var mat = StandardMaterial3D.new()
	
	match powerup_type:
		Type.ANVIL:
			var box = BoxMesh.new()
			box.size = Vector3(0.55, 0.45, 0.55)
			inst.mesh = box
			mat.albedo_color = Color(0.18, 0.20, 0.24)
			mat.metallic = 0.95
			mat.roughness = 0.18
		Type.SPIKE_WHEEL:
			var prism = BoxMesh.new()
			prism.size = Vector3(0.48, 0.48, 0.48)
			inst.mesh = prism
			inst.rotation_degrees = Vector3(45, 45, 0)
			mat.albedo_color = Color(1.0, 0.25, 0.15)
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.3, 0.1)
			mat.emission_energy_multiplier = 2.5
			mat.roughness = 0.2
		Type.NITRO_JET:
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.16
			cyl.bottom_radius = 0.26
			cyl.height = 0.52
			inst.mesh = cyl
			mat.albedo_color = Color(0.15, 0.75, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.2, 0.85, 1.0)
			mat.emission_energy_multiplier = 3.0
		Type.GHOST_PHASE:
			var sph = SphereMesh.new()
			sph.radius = 0.28
			sph.height = 0.56
			inst.mesh = sph
			mat.albedo_color = Color(0.65, 0.95, 1.0, 0.65)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.emission_enabled = true
			mat.emission = Color(0.5, 0.9, 1.0)
			mat.emission_energy_multiplier = 2.0
		Type.ICE_TRAIL:
			var prism = BoxMesh.new()
			prism.size = Vector3(0.42, 0.42, 0.42)
			inst.mesh = prism
			inst.rotation_degrees = Vector3(30, 45, 60)
			mat.albedo_color = Color(0.75, 0.92, 1.0)
			mat.roughness = 0.05
			mat.metallic = 0.4
			mat.emission_enabled = true
			mat.emission = Color(0.6, 0.85, 1.0)
			mat.emission_energy_multiplier = 1.8
		Type.GRAVITY_MAGNET:
			var cyl = CylinderMesh.new()
			cyl.top_radius = 0.32
			cyl.bottom_radius = 0.32
			cyl.height = 0.18
			inst.mesh = cyl
			mat.albedo_color = Color(0.85, 0.2, 0.95)
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.2, 1.0)
			mat.emission_energy_multiplier = 3.0
	
	inst.material_override = mat
	_mesh_node.add_child(inst)
	
	# 3D Billboard Label
	_label = Label3D.new()
	_label.text = _get_display_name()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 32
	_label.pixel_size = 0.007
	_label.position = Vector3(0, 0.65, 0)
	_label.modulate = _get_type_color()
	add_child(_label)

func _process(delta: float) -> void:
	_bob_timer += delta * 2.8
	if _mesh_node:
		_mesh_node.position.y = sin(_bob_timer) * 0.14
		_mesh_node.rotation.y += delta * 2.2
	if _label:
		_label.position.y = 0.65 + sin(_bob_timer) * 0.14

func _get_type_name(t: Type) -> String:
	match t:
		Type.ANVIL: return "ANVIL"
		Type.SPIKE_WHEEL: return "SPIKE_WHEEL"
		Type.NITRO_JET: return "NITRO_JET"
		Type.GHOST_PHASE: return "GHOST_PHASE"
		Type.ICE_TRAIL: return "ICE_TRAIL"
		Type.GRAVITY_MAGNET: return "GRAVITY_MAGNET"
	return "UNKNOWN"

func _get_display_name() -> String:
	match powerup_type:
		Type.ANVIL: return "🪨 AMBOSS"
		Type.SPIKE_WHEEL: return "⚡ STACHEL"
		Type.NITRO_JET: return "🚀 NITRO"
		Type.GHOST_PHASE: return "👻 GEIST"
		Type.ICE_TRAIL: return "❄️ EISSPUR"
		Type.GRAVITY_MAGNET: return "🧲 MAGNET"
	return "POWER-UP"

func _get_type_color() -> Color:
	match powerup_type:
		Type.ANVIL: return Color(0.8, 0.85, 0.9)
		Type.SPIKE_WHEEL: return Color(1.0, 0.35, 0.2)
		Type.NITRO_JET: return Color(0.3, 0.85, 1.0)
		Type.GHOST_PHASE: return Color(0.6, 0.95, 1.0)
		Type.ICE_TRAIL: return Color(0.7, 0.9, 1.0)
		Type.GRAVITY_MAGNET: return Color(0.95, 0.35, 1.0)
	return Color.WHITE

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_powerup"):
		body.apply_powerup(powerup_type, RollConfig.POWERUP_DURATION_SECONDS)
		if RollSoundManager.instance:
			RollSoundManager.instance.play_powerup()
		if "player_id" in body and LeaderboardManager.instance:
			LeaderboardManager.instance.record_powerup_collected(body.player_id)
		queue_free()
