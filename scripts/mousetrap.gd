class_name MousetrapHazard
extends Area3D

const RollConfig = preload("res://scripts/config.gd")

## Mausefallen-Hazard für Roll & Rumble 3D
## Schnappt bei Überrollen zu und schleudert den Ball in die Höhe

@export var snap_force_y: float = RollConfig.TRAP_SNAP_IMPULSE_Y
@export var tilt_force: float = RollConfig.TRAP_TILT_IMPULSE

var is_ready: bool = true
var cooldown_timer: float = 0.0

var _base_mesh: MeshInstance3D
var _flap_mesh: MeshInstance3D

signal trap_triggered(body: Node3D)

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_setup_visuals()

func _setup_visuals() -> void:
	# Grundplatte (Holzoptik)
	_base_mesh = MeshInstance3D.new()
	var base_box = BoxMesh.new()
	base_box.size = Vector3(1.8, 0.15, 2.6)
	_base_mesh.mesh = base_box
	var wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.75, 0.5, 0.28)
	wood_mat.roughness = 0.8
	_base_mesh.material_override = wood_mat
	add_child(_base_mesh)

	# Schnappbügel (Metall)
	_flap_mesh = MeshInstance3D.new()
	var flap_box = BoxMesh.new()
	flap_box.size = Vector3(1.6, 0.08, 0.2)
	_flap_mesh.mesh = flap_box
	_flap_mesh.position = Vector3(0, 0.12, 0.8)
	var metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.85, 0.2, 0.2)
	metal_mat.metallic = 0.9
	_flap_mesh.material_override = metal_mat
	add_child(_flap_mesh)
	
	# Kollisionsform für Trigger
	var col = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1.8, 0.6, 2.6)
	col.shape = box_shape
	add_child(col)

func _process(delta: float) -> void:
	if not is_ready:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			is_ready = true
			if _flap_mesh:
				_flap_mesh.rotation_degrees.x = 0.0

func _on_body_entered(body: Node3D) -> void:
	if is_ready and body is RigidBody3D:
		is_ready = false
		cooldown_timer = RollConfig.TRAP_COOLDOWN
		
		# Visuelle Schnapp-Reaktion
		if _flap_mesh:
			_flap_mesh.rotation_degrees.x = -135.0
		
		# Physikalischer Katapult-Impuls
		var random_angle = randf() * TAU
		var tilt_dir = Vector3(cos(random_angle), 0, sin(random_angle))
		var impulse = Vector3.UP * snap_force_y + tilt_dir * tilt_force
		body.apply_central_impulse(impulse)
		
		trap_triggered.emit(body)
