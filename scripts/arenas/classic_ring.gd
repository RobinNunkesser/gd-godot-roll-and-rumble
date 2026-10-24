class_name ClassicRingArena
extends "res://scripts/arenas/base_arena.gd"

const MousetrapHazard = preload("res://scripts/mousetrap.gd")

var traps: Array[MousetrapHazard] = []

func _init() -> void:
	arena_name = "CLASSIC RING"
	arena_description = "Zylindrische Holzarena mit 4 Schnapp-Mausefallen am Rand"

func _ready() -> void:
	_build_platform()
	_build_traps()

func _build_platform() -> void:
	var body = StaticBody3D.new()
	body.name = "ClassicPlatform"
	body.position = Vector3(0, -RollConfig.ARENA_HEIGHT * 0.5, 0)
	
	var phys = PhysicsMaterial.new()
	phys.friction = RollConfig.ARENA_FRICTION
	phys.bounce = 0.3
	body.physics_material_override = phys
	
	var col = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = RollConfig.ARENA_RADIUS
	cyl_shape.height = RollConfig.ARENA_HEIGHT
	col.shape = cyl_shape
	body.add_child(col)
	
	var mesh_inst = MeshInstance3D.new()
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = RollConfig.ARENA_RADIUS
	cyl_mesh.bottom_radius = RollConfig.ARENA_RADIUS
	cyl_mesh.height = RollConfig.ARENA_HEIGHT
	mesh_inst.mesh = cyl_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.45, 0.75)
	mat.roughness = 0.5
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)
	add_child(body)

func _build_traps() -> void:
	traps.clear()
	var trap_angles = [0.0, PI * 0.5, PI, PI * 1.5]
	for i in range(trap_angles.size()):
		var angle = trap_angles[i]
		var trap = MousetrapHazard.new()
		trap.name = "Mousetrap_%d" % i
		var dist = RollConfig.ARENA_RADIUS * 0.65
		trap.position = Vector3(cos(angle) * dist, 0.075, sin(angle) * dist)
		trap.rotation.y = -angle
		add_child(trap)
		traps.append(trap)

func reset_arena() -> void:
	for t in traps:
		if is_instance_valid(t) and t.has_method("reset_trap"):
			t.reset_trap()
