class_name IceSlickArena
extends "res://scripts/arenas/base_arena.gd"

## Glatteis-Rutschbahn (Ice Slick)
## Extrem rutschige Eisfläche mit Reibung 0.02 und Eis-Säulen

var ice_pillars: Array[StaticBody3D] = []

func _init() -> void:
	arena_name = "ICE SLICK"
	arena_description = "Glatteis-Rutschbahn (Reibung 0.02): Unaufhaltsames Schlittern & extreme Drift-Physik!"

func _ready() -> void:
	_build_ice_surface()
	_build_ice_pillars()

func _build_ice_surface() -> void:
	var body = StaticBody3D.new()
	body.name = "IcePlatform"
	body.position = Vector3(0, -RollConfig.ARENA_HEIGHT * 0.5, 0)
	
	var phys = PhysicsMaterial.new()
	phys.friction = 0.02 # Extrem glatt!
	phys.bounce = 0.35
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
	mesh_inst.material_override = get_surface_material("ice")
	body.add_child(mesh_inst)
	
	# Frost-Metallrand
	var rim = MeshInstance3D.new()
	rim.name = "FrostRim"
	var torus = CylinderMesh.new()
	torus.top_radius = RollConfig.ARENA_RADIUS + 0.08
	torus.bottom_radius = RollConfig.ARENA_RADIUS + 0.08
	torus.height = RollConfig.ARENA_HEIGHT * 0.5
	rim.mesh = torus
	rim.position = Vector3(0, RollConfig.ARENA_HEIGHT * 0.3, 0)
	rim.material_override = get_surface_material("metal_rim")
	body.add_child(rim)
	
	add_child(body)

func _build_ice_pillars() -> void:
	ice_pillars.clear()
	var pillar_angles = [PI * 0.25, PI * 0.75, PI * 1.25, PI * 1.75]
	var dist = 3.6
	
	for i in range(pillar_angles.size()):
		var angle = pillar_angles[i]
		var pillar = StaticBody3D.new()
		pillar.name = "IcePillar_%d" % i
		pillar.position = Vector3(cos(angle) * dist, 0.6, sin(angle) * dist)
		
		var p_phys = PhysicsMaterial.new()
		p_phys.friction = 0.01
		p_phys.bounce = 0.6
		pillar.physics_material_override = p_phys
		
		var col = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(1.1, 1.2, 1.1)
		col.shape = box_shape
		pillar.add_child(col)
		
		var mesh_inst = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = box_shape.size
		mesh_inst.mesh = box_mesh
		mesh_inst.material_override = get_surface_material("ice", Color(0.9, 1.1, 1.2))
		pillar.add_child(mesh_inst)
		
		add_child(pillar)
		ice_pillars.append(pillar)

func reset_arena() -> void:
	pass
