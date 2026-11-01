class_name PureRingArena
extends "res://scripts/arenas/base_arena.gd"

func _init() -> void:
	arena_name = "SUMO RING"
	arena_description = "Frei schwebende Holzscheibe ohne Hindernisse – reiner Physik-Sumo Kugel gegen Kugel."

func _ready() -> void:
	_build_platform()

func _build_platform() -> void:
	var body = StaticBody3D.new()
	body.name = "PurePlatform"
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
	mesh_inst.material_override = get_surface_material("wood")
	body.add_child(mesh_inst)
	
	# Metallischer Randring zur optischen Betonung des Abgrunds
	var rim = MeshInstance3D.new()
	rim.name = "MetalRim"
	var rim_mesh = CylinderMesh.new()
	rim_mesh.top_radius = RollConfig.ARENA_RADIUS + 0.05
	rim_mesh.bottom_radius = RollConfig.ARENA_RADIUS + 0.05
	rim_mesh.height = RollConfig.ARENA_HEIGHT * 0.3
	rim.mesh = rim_mesh
	rim.position = Vector3(0, RollConfig.ARENA_HEIGHT * 0.35, 0)
	rim.material_override = get_surface_material("metal_rim")
	body.add_child(rim)
	
	# Zentraler Markierungsring (Sumo Dohyo Zentrum)
	var center_mark = MeshInstance3D.new()
	center_mark.name = "CenterRing"
	var center_mesh = CylinderMesh.new()
	center_mesh.top_radius = 2.2
	center_mesh.bottom_radius = 2.2
	center_mesh.height = 0.02
	center_mark.mesh = center_mesh
	center_mark.position = Vector3(0, RollConfig.ARENA_HEIGHT * 0.5 + 0.01, 0)
	center_mark.material_override = get_surface_material("stripe_dark")
	body.add_child(center_mark)
	
	add_child(body)

func reset_arena() -> void:
	pass
