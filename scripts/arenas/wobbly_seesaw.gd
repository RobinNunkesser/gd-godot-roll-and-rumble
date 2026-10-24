class_name WobblySeesawArena
extends "res://scripts/arenas/base_arena.gd"

var tilting_platform: AnimatableBody3D
var base_pillar: StaticBody3D

var current_tilt_x: float = 0.0
var current_tilt_z: float = 0.0

func _init() -> void:
	arena_name = "WOBBLY SEESAW"
	arena_description = "Kipp-Plattform auf Mittellager: Spieler-Gewicht erzeugt gefährlichen Hangabtrieb!"

func _ready() -> void:
	_build_base_pillar()
	_build_tilting_platform()

func _build_base_pillar() -> void:
	base_pillar = StaticBody3D.new()
	base_pillar.name = "PivotBase"
	base_pillar.position = Vector3(0, -3.0, 0)
	
	var col = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 2.4
	cyl_shape.height = 4.0
	col.shape = cyl_shape
	base_pillar.add_child(col)
	
	var mesh = MeshInstance3D.new()
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = 2.2
	cyl_mesh.bottom_radius = 2.8
	cyl_mesh.height = 4.0
	mesh.mesh = cyl_mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.22, 0.26)
	mat.metallic = 0.8
	mat.roughness = 0.3
	mesh.material_override = mat
	base_pillar.add_child(mesh)
	add_child(base_pillar)

func _build_tilting_platform() -> void:
	tilting_platform = AnimatableBody3D.new()
	tilting_platform.name = "TiltingPlatform"
	tilting_platform.position = Vector3(0, 0, 0)
	
	var phys = PhysicsMaterial.new()
	phys.friction = RollConfig.ARENA_FRICTION * 0.95
	phys.bounce = 0.2
	tilting_platform.physics_material_override = phys
	
	var col = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = RollConfig.ARENA_RADIUS
	cyl_shape.height = RollConfig.ARENA_HEIGHT
	col.shape = cyl_shape
	col.position = Vector3(0, -RollConfig.ARENA_HEIGHT * 0.5, 0)
	tilting_platform.add_child(col)
	
	var mesh_inst = MeshInstance3D.new()
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = RollConfig.ARENA_RADIUS
	cyl_mesh.bottom_radius = RollConfig.ARENA_RADIUS
	cyl_mesh.height = RollConfig.ARENA_HEIGHT
	mesh_inst.mesh = cyl_mesh
	mesh_inst.position = col.position
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.68, 0.24, 0.28) # Alarmrot / Kupfer
	mat.metallic = 0.6
	mat.roughness = 0.35
	mesh_inst.material_override = mat
	tilting_platform.add_child(mesh_inst)
	
	# Zentraler Drehpunkt-Knauf
	var pivot_knob = MeshInstance3D.new()
	var knob_mesh = SphereMesh.new()
	knob_mesh.radius = 1.0
	knob_mesh.height = 2.0
	pivot_knob.mesh = knob_mesh
	pivot_knob.position = Vector3(0, 0.2, 0)
	var knob_mat = StandardMaterial3D.new()
	knob_mat.albedo_color = Color(0.95, 0.82, 0.25)
	knob_mat.metallic = 0.7
	pivot_knob.material_override = knob_mat
	tilting_platform.add_child(pivot_knob)
	
	add_child(tilting_platform)

func update_arena(delta: float, players: Array = []) -> void:
	var torque_x = 0.0
	var torque_z = 0.0
	
	for p in players:
		if is_instance_valid(p) and ("is_active" in p and p.is_active):
			var ppos = p.global_position if is_inside_tree() else p.position
			var r_dist = Vector2(ppos.x, ppos.z).length()
			if r_dist <= RollConfig.ARENA_RADIUS:
				torque_x += (ppos.z / RollConfig.ARENA_RADIUS) * 0.75
				torque_z -= (ppos.x / RollConfig.ARENA_RADIUS) * 0.75
	
	var max_tilt_rad = deg_to_rad(RollConfig.SEESAW_MAX_TILT_DEG)
	var target_tilt_x = clampf(torque_x, -max_tilt_rad, max_tilt_rad)
	var target_tilt_z = clampf(torque_z, -max_tilt_rad, max_tilt_rad)
	
	current_tilt_x = lerpf(current_tilt_x, target_tilt_x, delta * RollConfig.SEESAW_STIFFNESS)
	current_tilt_z = lerpf(current_tilt_z, target_tilt_z, delta * RollConfig.SEESAW_STIFFNESS)
	
	if tilting_platform:
		tilting_platform.rotation = Vector3(current_tilt_x, 0.0, current_tilt_z)

func reset_arena() -> void:
	current_tilt_x = 0.0
	current_tilt_z = 0.0
	if tilting_platform:
		tilting_platform.rotation = Vector3.ZERO
