class_name DizzySpinnerArena
extends "res://scripts/arenas/base_arena.gd"

var inner_spinner: AnimatableBody3D
var outer_ring: StaticBody3D
var spin_time: float = 0.0
var current_omega: float = 0.0

func _init() -> void:
	arena_name = "DIZZY SPINNER"
	arena_description = "Rotierende Zentrifugenscheibe (Radius 6m) mit periodischem Richtungswechsel"

func _ready() -> void:
	_build_outer_ring()
	_build_inner_spinner()

func _build_outer_ring() -> void:
	outer_ring = StaticBody3D.new()
	outer_ring.name = "OuterRing"
	outer_ring.position = Vector3(0, -RollConfig.ARENA_HEIGHT * 0.5, 0)
	
	var phys = PhysicsMaterial.new()
	phys.friction = RollConfig.ARENA_FRICTION * 1.15
	phys.bounce = 0.25
	outer_ring.physics_material_override = phys
	
	var num_segments = 16
	var outer_r = RollConfig.ARENA_RADIUS
	var inner_r = RollConfig.SPINNER_RADIUS + 0.05
	var seg_w = (outer_r - inner_r)
	var mid_r = (outer_r + inner_r) * 0.5
	var arc_len = (TAU * mid_r) / float(num_segments) * 1.08
	
	var ring_mat = get_surface_material("metal_rim")
	
	for i in range(num_segments):
		var angle = (float(i) / float(num_segments)) * TAU
		var col = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(seg_w, RollConfig.ARENA_HEIGHT, arc_len)
		col.shape = box_shape
		col.position = Vector3(cos(angle) * mid_r, 0, sin(angle) * mid_r)
		col.rotation.y = -angle
		outer_ring.add_child(col)
		
		var mesh_inst = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = box_shape.size
		mesh_inst.mesh = box_mesh
		mesh_inst.material_override = ring_mat
		mesh_inst.position = col.position
		mesh_inst.rotation.y = col.rotation.y
		outer_ring.add_child(mesh_inst)
		
	add_child(outer_ring)

func _build_inner_spinner() -> void:
	inner_spinner = AnimatableBody3D.new()
	inner_spinner.name = "InnerSpinner"
	inner_spinner.position = Vector3(0, -RollConfig.ARENA_HEIGHT * 0.5, 0)
	
	var phys = PhysicsMaterial.new()
	phys.friction = RollConfig.ARENA_FRICTION * 0.95
	phys.bounce = 0.3
	inner_spinner.physics_material_override = phys
	
	var col = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = RollConfig.SPINNER_RADIUS
	cyl_shape.height = RollConfig.ARENA_HEIGHT
	col.shape = cyl_shape
	inner_spinner.add_child(col)
	
	var mesh_inst = MeshInstance3D.new()
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = RollConfig.SPINNER_RADIUS
	cyl_mesh.bottom_radius = RollConfig.SPINNER_RADIUS
	cyl_mesh.height = RollConfig.ARENA_HEIGHT
	mesh_inst.mesh = cyl_mesh
	mesh_inst.material_override = get_surface_material("hazard_rotor")
	inner_spinner.add_child(mesh_inst)
	
	# 4 rotierende Kontraststreifen für optische Drehwahrnehmung
	var stripe_mat = get_surface_material("stripe_dark")
	for i in range(4):
		var stripe = MeshInstance3D.new()
		var s_mesh = BoxMesh.new()
		s_mesh.size = Vector3(RollConfig.SPINNER_RADIUS * 1.85, 0.04, 0.35)
		stripe.mesh = s_mesh
		stripe.position = Vector3(0, RollConfig.ARENA_HEIGHT * 0.5 + 0.02, 0)
		stripe.rotation_degrees = Vector3(0, i * 45.0, 0)
		stripe.material_override = stripe_mat
		inner_spinner.add_child(stripe)
		
	add_child(inner_spinner)

func update_arena(delta: float, _players: Array = []) -> void:
	spin_time += delta
	current_omega = RollConfig.SPINNER_MAX_OMEGA * cos(spin_time * TAU / RollConfig.SPINNER_PERIOD)
	if inner_spinner:
		inner_spinner.rotate_y(current_omega * delta)
		inner_spinner.constant_angular_velocity = Vector3(0, current_omega, 0)

func reset_arena() -> void:
	spin_time = 0.0
	current_omega = 0.0
	if inner_spinner:
		inner_spinner.rotation = Vector3.ZERO
		inner_spinner.constant_angular_velocity = Vector3.ZERO
