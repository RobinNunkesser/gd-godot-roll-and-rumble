class_name BumperPinballArena
extends "res://scripts/arenas/base_arena.gd"

## Pinball Bumper Arena
## 5 reaktive Flipper-Pilze erzeugen chaotische Kettenreaktionen und Abpraller

const PinballBumper = preload("res://scripts/pinball_bumper.gd")

var bumpers: Array[PinballBumper] = []

func _init() -> void:
	arena_name = "PINBALL BUMPERS"
	arena_description = "5 federnde Flipper-Bumper im Ring: Extreme Kettenreaktionen und Querschläger!"

func _ready() -> void:
	_build_platform()
	_build_bumpers()

func _build_platform() -> void:
	var body = StaticBody3D.new()
	body.name = "PinballPlatform"
	body.position = Vector3(0, -RollConfig.ARENA_HEIGHT * 0.5, 0)
	
	var phys = PhysicsMaterial.new()
	phys.friction = RollConfig.ARENA_FRICTION * 0.8
	phys.bounce = 0.45
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
	mesh_inst.material_override = get_surface_material("wood")
	body.add_child(mesh_inst)
	
	# Dunkler Außenring
	var rim = MeshInstance3D.new()
	rim.name = "MetalRim"
	var torus = CylinderMesh.new()
	torus.top_radius = RollConfig.ARENA_RADIUS + 0.05
	torus.bottom_radius = RollConfig.ARENA_RADIUS + 0.05
	torus.height = RollConfig.ARENA_HEIGHT * 0.4
	rim.mesh = torus
	rim.position = Vector3(0, RollConfig.ARENA_HEIGHT * 0.35, 0)
	rim.material_override = get_surface_material("metal_rim")
	body.add_child(rim)
	
	add_child(body)

func _build_bumpers() -> void:
	bumpers.clear()
	# 1x Zentrum + 4x Ring
	var b_positions = [
		Vector3(0.0, 0.0, 0.0),
		Vector3(4.2, 0.0, 0.0),
		Vector3(-4.2, 0.0, 0.0),
		Vector3(0.0, 0.0, 4.2),
		Vector3(0.0, 0.0, -4.2)
	]
	
	for i in range(b_positions.size()):
		var b = PinballBumper.new()
		b.name = "Bumper_%d" % i
		b.position = b_positions[i]
		add_child(b)
		bumpers.append(b)

func get_spawn_positions(count: int) -> Array[Vector3]:
	# Spawne zwischen den Bumpern bei 45 Grad
	var spots: Array[Vector3] = []
	var dist = RollConfig.ARENA_RADIUS * 0.65
	for i in range(count):
		var angle = (float(i) / float(count)) * TAU + (PI * 0.25)
		spots.append(Vector3(cos(angle) * dist, RollConfig.BALL_RADIUS + 0.1, sin(angle) * dist))
	return spots

func reset_arena() -> void:
	pass
