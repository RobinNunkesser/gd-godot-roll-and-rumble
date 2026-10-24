class_name SharedArenaCamera
extends Camera3D

const RollConfig = preload("res://scripts/config.gd")
const PlayerBall = preload("res://scripts/player_ball.gd")

## Shared Dynamic Arena Camera für Couch-Multiplayer
## Berechnet Bounding-Box und Schwerpunkt aller aktiven Bälle

@export var target_nodes: Array = []

var trauma: float = 0.0
var max_shake_offset: float = 0.4

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	update_camera(delta)

func update_camera(delta: float) -> void:
	var active_positions: Array[Vector3] = []
	for node in target_nodes:
		if is_instance_valid(node):
			if node is PlayerBall and not node.is_active:
				continue
			var pos = node.global_position if (is_inside_tree() and node.is_inside_tree()) else node.position
			active_positions.append(pos)
	
	if active_positions.is_empty():
		return
	
	# 1. Schwerpunkt (Centroid) berechnen
	var centroid = Vector3.ZERO
	for pos in active_positions:
		centroid += pos
	centroid /= float(active_positions.size())
	
	# 2. Maximale Ausdehnung (Span) berechnen
	var max_dist: float = 0.0
	for i in range(active_positions.size()):
		for j in range(i + 1, active_positions.size()):
			var dist = active_positions[i].distance_to(active_positions[j])
			if dist > max_dist:
				max_dist = dist
	
	# 3. Zieldistanz und Höhe anpassen (Kompakte, dynamische Rahmung)
	var dist_factor = clampf(max_dist / 12.0, 0.0, 1.0)
	var desired_distance = lerpf(RollConfig.CAMERA_MIN_DISTANCE, RollConfig.CAMERA_MAX_DISTANCE, dist_factor)
	var desired_height = lerpf(RollConfig.CAMERA_BASE_HEIGHT, RollConfig.CAMERA_BASE_HEIGHT + 3.5, dist_factor)
	
	var desired_position = centroid + Vector3(0.0, desired_height, desired_distance)
	
	# Juiciness: Trauma-basierter Screenshake (nichtlinear: Trauma^2)
	if trauma > 0.0:
		var shake = trauma * trauma
		var offset = Vector3(
			(randf() * 2.0 - 1.0) * max_shake_offset * shake,
			(randf() * 2.0 - 1.0) * max_shake_offset * shake,
			0.0
		)
		desired_position += offset
		trauma = maxf(0.0, trauma - delta * 1.8)
	
	# 4. Weiche Interpolation (Smoothing)
	if is_inside_tree():
		global_position = global_position.lerp(desired_position, delta * RollConfig.CAMERA_LERP_SPEED)
		if global_position != centroid:
			look_at(centroid, Vector3.UP)
	else:
		position = position.lerp(desired_position, delta * RollConfig.CAMERA_LERP_SPEED)
