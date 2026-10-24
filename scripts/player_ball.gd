class_name PlayerBall
extends RigidBody3D

const RollConfig = preload("res://scripts/config.gd")

enum ControlType {
	OFF,
	HUMAN_KB1,
	HUMAN_KB2,
	GAMEPAD_0,
	GAMEPAD_1,
	GAMEPAD_2,
	GAMEPAD_3,
	AI_BOT
}

@export var player_id: int = 1
@export var ball_color: Color = Color(0.9, 0.2, 0.2)
@export var control_type: ControlType = ControlType.HUMAN_KB1
@export var bot_difficulty: float = 1.0

var is_bot: bool:
	get:
		return control_type == ControlType.AI_BOT
	set(val):
		control_type = ControlType.AI_BOT if val else ControlType.HUMAN_KB1

var target_opponent: Node3D = null
var potential_targets: Array = []
var is_active: bool = true
var boost_cooldown_timer: float = 0.0
var last_hit_by_id: int = 0
var last_hit_timer: float = 0.0
var respawn_timer: float = 0.0
var initial_spawn_point: Vector3 = Vector3.ZERO

var _mesh_instance: MeshInstance3D
var _eyes_pivot: Node3D
var _pending_teleport: bool = false
var _teleport_target: Vector3 = Vector3.ZERO

signal fell_off(player_id: int, last_hitter_id: int)

func _ready() -> void:
	initial_spawn_point = global_position if is_inside_tree() else position
	mass = RollConfig.BALL_MASS
	linear_damp = 1.0
	angular_damp = 1.0
	
	# Physik-Material einrichten
	var phys_mat = PhysicsMaterial.new()
	phys_mat.bounce = RollConfig.BALL_BOUNCE
	phys_mat.friction = RollConfig.BALL_FRICTION
	physics_material_override = phys_mat
	
	contact_monitor = true
	max_contacts_reported = 4
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	_setup_collision()
	_setup_visuals()

func _setup_collision() -> void:
	if not has_node("CollisionShape3D"):
		var col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = RollConfig.BALL_RADIUS
		col.shape = sphere_shape
		add_child(col)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _pending_teleport:
		state.transform.origin = _teleport_target
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		_pending_teleport = false

func _setup_visuals() -> void:
	# Prüfen, ob bereits Visuals da sind (z. B. aus Szene)
	if not has_node("SphereMesh"):
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "SphereMesh"
		var sphere = SphereMesh.new()
		sphere.radius = RollConfig.BALL_RADIUS
		sphere.height = RollConfig.BALL_RADIUS * 2.0
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = ball_color
		mat.roughness = 0.25
		mat.metallic = 0.3
		_mesh_instance.mesh = sphere
		_mesh_instance.material_override = mat
		add_child(_mesh_instance)
	
	if not has_node("EyesPivot"):
		_eyes_pivot = Node3D.new()
		_eyes_pivot.name = "EyesPivot"
		add_child(_eyes_pivot)
		
		# Zwei Comic-Augen
		for eye_x in [-0.2, 0.2]:
			var eye = MeshInstance3D.new()
			var eye_mesh = SphereMesh.new()
			eye_mesh.radius = 0.12
			eye_mesh.height = 0.24
			eye.mesh = eye_mesh
			eye.position = Vector3(eye_x, 0.25, -0.48)
			
			var eye_mat = StandardMaterial3D.new()
			eye_mat.albedo_color = Color.WHITE
			eye.material_override = eye_mat
			_eyes_pivot.add_child(eye)
			
			# Pupille
			var pupil = MeshInstance3D.new()
			var pupil_mesh = SphereMesh.new()
			pupil_mesh.radius = 0.05
			pupil_mesh.height = 0.10
			pupil.mesh = pupil_mesh
			pupil.position = Vector3(0, 0, -0.09)
			var pupil_mat = StandardMaterial3D.new()
			pupil_mat.albedo_color = Color.BLACK
			pupil.material_override = pupil_mat
			eye.add_child(pupil)

func _physics_process(delta: float) -> void:
	if not is_active:
		if respawn_timer > 0.0:
			respawn_timer -= delta
			if respawn_timer <= 0.0:
				respawn()
		return

	if boost_cooldown_timer > 0.0:
		boost_cooldown_timer -= delta
	
	if last_hit_timer > 0.0:
		last_hit_timer -= delta
		if last_hit_timer <= 0.0:
			last_hit_by_id = 0

	if is_bot:
		_handle_bot_ai(delta)
	else:
		_handle_input(delta)
	_clamp_speed()
	_check_out_of_bounds()

func _get_active_target() -> Node3D:
	if not potential_targets.is_empty():
		var my_pos = global_position if is_inside_tree() else position
		var best_target: Node3D = null
		var min_dist: float = 99999.0
		for t in potential_targets:
			if is_instance_valid(t) and t != self:
				var is_tgt_active = true
				if "is_active" in t:
					is_tgt_active = t.is_active
				if is_tgt_active:
					var t_pos = t.global_position if (is_inside_tree() and t.is_inside_tree()) else t.position
					var d = my_pos.distance_to(t_pos)
					if d < min_dist:
						min_dist = d
						best_target = t
		if best_target:
			return best_target
	if is_instance_valid(target_opponent):
		var is_tgt_active = true
		if "is_active" in target_opponent:
			is_tgt_active = target_opponent.is_active
		if is_tgt_active:
			return target_opponent
	return null

func _handle_bot_ai(_delta: float) -> void:
	var my_pos = global_position if is_inside_tree() else position
	var dist_from_center = Vector2(my_pos.x, my_pos.z).length()
	var steer_vec = Vector2.ZERO
	
	# 1. Edge-Avoidance: Wenn gefährlich nah am Rand, mit Top-Priorität zur Mitte steuern
	var danger_radius = RollConfig.ARENA_RADIUS * 0.68
	if dist_from_center > danger_radius:
		var to_center = -Vector2(my_pos.x, my_pos.z).normalized()
		steer_vec = to_center * 1.5
	else:
		# 2. Nächsten aktiven Gegner anvisieren (Seek & Ram)
		var current_target = _get_active_target()
		if current_target:
			var opp_pos = current_target.global_position if (is_inside_tree() and current_target.is_inside_tree()) else current_target.position
			var to_opp = Vector2(opp_pos.x - my_pos.x, opp_pos.z - my_pos.z)
			var opp_dist = to_opp.length()
			
			if opp_dist > 0.05:
				steer_vec = to_opp.normalized()
			
			# 3. Rammschub / Boost bei Ausrichtung und passender Distanz
			if opp_dist < 4.8 and opp_dist > 1.2 and boost_cooldown_timer <= 0.0:
				var move_dir_2d = Vector2(linear_velocity.x, linear_velocity.z)
				if move_dir_2d.length() > 1.0:
					var dot = move_dir_2d.normalized().dot(to_opp.normalized())
					if dot > 0.5: # schaut in Richtung des Gegners
						trigger_boost(to_opp.normalized())
	
	# 4. Kraft anwenden & Blickrichtung ausrichten
	if steer_vec.length_squared() > 0.01:
		steer_vec = steer_vec.normalized()
		var move_dir = Vector3(steer_vec.x, 0.0, steer_vec.y)
		apply_central_force(move_dir * RollConfig.DRIVE_FORCE * bot_difficulty)
		
		if _eyes_pivot:
			_eyes_pivot.rotation.y = atan2(-move_dir.x, -move_dir.z)

func _handle_input(_delta: float) -> void:
	if control_type == ControlType.OFF or control_type == ControlType.AI_BOT:
		return
	
	var input_vec = Vector2.ZERO
	var boost_pressed = false
	
	match control_type:
		ControlType.HUMAN_KB1:
			if Input.is_action_pressed("p1_left") or Input.is_key_pressed(KEY_A):
				input_vec.x -= 1.0
			if Input.is_action_pressed("p1_right") or Input.is_key_pressed(KEY_D):
				input_vec.x += 1.0
			if Input.is_action_pressed("p1_up") or Input.is_key_pressed(KEY_W):
				input_vec.y -= 1.0
			if Input.is_action_pressed("p1_down") or Input.is_key_pressed(KEY_S):
				input_vec.y += 1.0
			boost_pressed = Input.is_action_just_pressed("p1_boost") or Input.is_key_pressed(KEY_SPACE)
			
		ControlType.HUMAN_KB2:
			if Input.is_action_pressed("p2_left") or Input.is_key_pressed(KEY_LEFT):
				input_vec.x -= 1.0
			if Input.is_action_pressed("p2_right") or Input.is_key_pressed(KEY_RIGHT):
				input_vec.x += 1.0
			if Input.is_action_pressed("p2_up") or Input.is_key_pressed(KEY_UP):
				input_vec.y -= 1.0
			if Input.is_action_pressed("p2_down") or Input.is_key_pressed(KEY_DOWN):
				input_vec.y += 1.0
			boost_pressed = Input.is_action_just_pressed("p2_boost") or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
			
		ControlType.GAMEPAD_0, ControlType.GAMEPAD_1, ControlType.GAMEPAD_2, ControlType.GAMEPAD_3:
			var dev = int(control_type) - int(ControlType.GAMEPAD_0)
			var raw_x = Input.get_joy_axis(dev, JOY_AXIS_LEFT_X)
			var raw_y = Input.get_joy_axis(dev, JOY_AXIS_LEFT_Y)
			if absf(raw_x) > 0.2:
				input_vec.x = raw_x
			if absf(raw_y) > 0.2:
				input_vec.y = raw_y
			boost_pressed = Input.is_joy_button_pressed(dev, JOY_BUTTON_A) or Input.is_joy_button_pressed(dev, JOY_BUTTON_RIGHT_SHOULDER)
	
	if input_vec.length_squared() > 0.01:
		input_vec = input_vec.normalized()
		var move_dir = Vector3(input_vec.x, 0.0, input_vec.y)
		apply_central_force(move_dir * RollConfig.DRIVE_FORCE)
		
		# Augen in Bewegungsrichtung orientieren
		if _eyes_pivot:
			_eyes_pivot.rotation.y = atan2(-move_dir.x, -move_dir.z)
	
	if boost_pressed and boost_cooldown_timer <= 0.0:
		trigger_boost(input_vec)

func set_control_type(new_type: ControlType) -> void:
	control_type = new_type
	if control_type == ControlType.OFF:
		is_active = false
		visible = false
		freeze = true
		collision_layer = 0
		collision_mask = 0
	else:
		is_active = true
		visible = true
		freeze = false
		collision_layer = 1
		collision_mask = 1

func trigger_boost(input_vec: Vector2) -> void:
	boost_cooldown_timer = RollConfig.BOOST_COOLDOWN
	var boost_dir = Vector3.FORWARD
	if input_vec.length_squared() > 0.01:
		boost_dir = Vector3(input_vec.x, 0.0, input_vec.y).normalized()
	elif linear_velocity.length_squared() > 0.1:
		boost_dir = Vector3(linear_velocity.x, 0.0, linear_velocity.z).normalized()
	
	apply_central_impulse(boost_dir * RollConfig.BOOST_IMPULSE)

func _clamp_speed() -> void:
	var horizontal_vel = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	if horizontal_vel.length() > RollConfig.MAX_LINEAR_SPEED:
		var clamped = horizontal_vel.normalized() * RollConfig.MAX_LINEAR_SPEED
		linear_velocity.x = clamped.x
		linear_velocity.z = clamped.z

func _check_out_of_bounds() -> void:
	var cur_y = global_position.y if is_inside_tree() else position.y
	if cur_y < RollConfig.OUT_OF_BOUNDS_Y:
		is_active = false
		fell_off.emit(player_id, last_hit_by_id)
		respawn_timer = RollConfig.RESPAWN_DELAY_SECONDS

func respawn(pos: Vector3 = initial_spawn_point) -> void:
	_teleport_target = pos + Vector3(0, 2.0, 0)
	if is_inside_tree():
		_pending_teleport = true
		global_position = _teleport_target
	else:
		position = _teleport_target
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	is_active = true
	last_hit_by_id = 0
	last_hit_timer = 0.0
	boost_cooldown_timer = 0.0

func _on_body_entered(body: Node) -> void:
	if body is PlayerBall and body != self:
		# Gegenseitiger Rammkontakt: Speichere Angreifer für 1.5s
		last_hit_by_id = body.player_id
		last_hit_timer = 1.5
