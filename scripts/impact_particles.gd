class_name RollImpactParticles
extends Node3D

## Visual Hit Juice & Spark Particle System
## Nutzt CPUParticles3D Object-Pooling für kollisionsgesteuerte Ramm-Funken und Boost-Dust.

var _spark_pool: Array[CPUParticles3D] = []
var _spark_pool_size: int = 6
var _current_spark_idx: int = 0

var _boost_pool: Array[CPUParticles3D] = []
var _boost_pool_size: int = 4
var _current_boost_idx: int = 0

func _init() -> void:
	name = "ImpactParticles"

func _ready() -> void:
	_setup_spark_pool()
	_setup_boost_pool()

func _setup_spark_pool() -> void:
	var spark_mesh = BoxMesh.new()
	spark_mesh.size = Vector3(0.12, 0.12, 0.12)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 3.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mesh.material = mat
	
	for i in range(_spark_pool_size):
		var p = CPUParticles3D.new()
		p.name = "Sparks_%d" % i
		p.emitting = false
		p.one_shot = true
		p.explosiveness = 1.0
		p.amount = 20
		p.lifetime = 0.45
		p.mesh = spark_mesh
		p.direction = Vector3.UP
		p.spread = 75.0
		p.gravity = Vector3(0, -18.0, 0)
		p.initial_velocity_min = 5.0
		p.initial_velocity_max = 9.0
		p.damping_min = 2.0
		p.damping_max = 5.0
		p.scale_amount_min = 0.6
		p.scale_amount_max = 1.2
		add_child(p)
		_spark_pool.append(p)

func _setup_boost_pool() -> void:
	var boost_mesh = SphereMesh.new()
	boost_mesh.radius = 0.08
	boost_mesh.height = 0.16
	
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.3, 0.8, 1.0, 0.8)
	b_mat.emission_enabled = true
	b_mat.emission = Color(0.3, 0.85, 1.0)
	b_mat.emission_energy_multiplier = 2.5
	b_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	boost_mesh.material = b_mat
	
	for i in range(_boost_pool_size):
		var bp = CPUParticles3D.new()
		bp.name = "Boost_%d" % i
		bp.emitting = false
		bp.one_shot = true
		bp.explosiveness = 0.8
		bp.amount = 14
		bp.lifetime = 0.35
		bp.mesh = boost_mesh
		bp.gravity = Vector3(0, -2.0, 0)
		bp.initial_velocity_min = 3.0
		bp.initial_velocity_max = 6.0
		bp.scale_amount_min = 0.5
		bp.scale_amount_max = 1.0
		add_child(bp)
		_boost_pool.append(bp)

## Rammfunken an Kontaktposition explodieren lassen
func spawn_sparks(pos: Vector3, force: float = 1.0) -> void:
	if _spark_pool.is_empty():
		return
	var p = _spark_pool[_current_spark_idx]
	_current_spark_idx = (_current_spark_idx + 1) % _spark_pool.size()
	
	if p.is_inside_tree():
		p.global_position = pos
		p.amount = int(clampf(force * 3.0, 10.0, 32.0))
		p.initial_velocity_min = clampf(force * 0.8, 4.0, 12.0)
		p.initial_velocity_max = clampf(force * 1.4, 6.0, 18.0)
		p.restart()
		p.emitting = true
	else:
		p.position = pos

## Boost-Staub / Plasma-Impuls am Kugelheck ausstoßen
func spawn_boost_burst(pos: Vector3, forward_dir: Vector3) -> void:
	if _boost_pool.is_empty():
		return
	var bp = _boost_pool[_current_boost_idx]
	_current_boost_idx = (_current_boost_idx + 1) % _boost_pool.size()
	
	if bp.is_inside_tree():
		bp.global_position = pos
		bp.direction = -forward_dir + Vector3(0, 0.3, 0) # Nach hinten/oben ausstoßen
		bp.restart()
		bp.emitting = true
	else:
		bp.position = pos

