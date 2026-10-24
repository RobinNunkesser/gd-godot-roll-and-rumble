class_name PinballBumper
extends Node3D

## Aktiver Flipper-Pilz (Pinball Bumper)
## Stößt Bälle bei Kontakt mit explosivem Radialimpuls ab und federt optisch ein.

const RollConfig = preload("res://scripts/config.gd")
const BaseArena = preload("res://scripts/arenas/base_arena.gd")
const PlayerBall = preload("res://scripts/player_ball.gd")

signal bumper_hit(ball: PlayerBall, hit_pos: Vector3)

var bumper_radius: float = 1.0
var bounce_impulse: float = 26.0

var _mesh_pivot: Node3D
var _ring_mesh: MeshInstance3D
var _cap_mesh: MeshInstance3D
var _squash_timer: float = 0.0

func _init() -> void:
	name = "PinballBumper"

func _ready() -> void:
	_build_visuals()
	_build_physics()

func _build_visuals() -> void:
	_mesh_pivot = Node3D.new()
	_mesh_pivot.name = "MeshPivot"
	add_child(_mesh_pivot)
	
	# Bumper-Ring (Glow-Zylinder)
	_ring_mesh = MeshInstance3D.new()
	_ring_mesh.name = "BumperRing"
	var cyl = CylinderMesh.new()
	cyl.top_radius = bumper_radius * 0.95
	cyl.bottom_radius = bumper_radius * 1.15
	cyl.height = 0.65
	_ring_mesh.mesh = cyl
	_ring_mesh.position = Vector3(0, 0.35, 0)
	_ring_mesh.material_override = BaseArena.get_surface_material("bumper_ring")
	_mesh_pivot.add_child(_ring_mesh)
	
	# Bumper-Kappe (Glänzende Halbkugel)
	_cap_mesh = MeshInstance3D.new()
	_cap_mesh.name = "BumperCap"
	var sphere = SphereMesh.new()
	sphere.radius = bumper_radius * 0.85
	sphere.height = 0.5
	_cap_mesh.mesh = sphere
	_cap_mesh.position = Vector3(0, 0.65, 0)
	_cap_mesh.material_override = BaseArena.get_surface_material("bumper_cap")
	_mesh_pivot.add_child(_cap_mesh)

func _build_physics() -> void:
	# Fester Kern
	var body = StaticBody3D.new()
	body.name = "BumperBody"
	var col = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = bumper_radius
	cyl_shape.height = 0.8
	col.shape = cyl_shape
	col.position = Vector3(0, 0.4, 0)
	body.add_child(col)
	add_child(body)
	
	# Sensor-Zone für explosiven Repel-Impuls
	var area = Area3D.new()
	area.name = "BumperTrigger"
	var area_col = CollisionShape3D.new()
	var area_shape = CylinderShape3D.new()
	area_shape.radius = bumper_radius + 0.35
	area_shape.height = 1.0
	area_col.shape = area_shape
	area_col.position = Vector3(0, 0.5, 0)
	area.add_child(area_col)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

func _process(delta: float) -> void:
	if _squash_timer > 0.0:
		_squash_timer -= delta
		var t = clampf(_squash_timer / 0.15, 0.0, 1.0)
		if _mesh_pivot:
			_mesh_pivot.scale = Vector3(1.0 + t * 0.25, 1.0 - t * 0.35, 1.0 + t * 0.25)
	else:
		if _mesh_pivot:
			_mesh_pivot.scale = Vector3.ONE

func _on_body_entered(body: Node) -> void:
	if body is PlayerBall:
		var bpos = body.global_position if is_inside_tree() else body.position
		var mpos = global_position if is_inside_tree() else position
		var dir = Vector3(bpos.x - mpos.x, 0.15, bpos.z - mpos.z)
		if dir.length_squared() < 0.001:
			dir = Vector3(randf_range(-1.0, 1.0), 0.15, randf_range(-1.0, 1.0))
		dir = dir.normalized()
		
		# Kugel wegkatapultieren
		body.apply_central_impulse(dir * bounce_impulse)
		_squash_timer = 0.15
		bumper_hit.emit(body, mpos + Vector3(0, 0.5, 0))
