class_name MainRollGame
extends Node3D

const RollConfig = preload("res://scripts/config.gd")
const RollStateManager = preload("res://scripts/state_manager.gd")
const PlayerBall = preload("res://scripts/player_ball.gd")
const MousetrapHazard = preload("res://scripts/mousetrap.gd")
const SharedArenaCamera = preload("res://scripts/shared_camera.gd")

var state_manager: RollStateManager
var player1: PlayerBall
var player2: PlayerBall
var camera: SharedArenaCamera

var ui_timer_label: Label
var ui_p1_label: Label
var ui_p2_label: Label
var ui_status_label: Label

func _ready() -> void:
	state_manager = RollStateManager.new()
	state_manager.state_changed.connect(_on_state_changed)
	state_manager.score_updated.connect(_on_score_updated)
	state_manager.timer_updated.connect(_on_timer_updated)
	state_manager.match_finished.connect(_on_match_finished)
	
	_build_scene()
	_build_ui()
	
	state_manager.reset_match()

func _build_scene() -> void:
	# 1. Umwelt & Licht
	var light = DirectionalLight3D.new()
	light.name = "SunLight"
	light.position = Vector3(10, 20, 10)
	light.rotation_degrees = Vector3(-50, 45, 0)
	light.shadow_enabled = true
	add_child(light)
	
	# 2. Arena-Plattform (Cylinder)
	var arena_body = StaticBody3D.new()
	arena_body.name = "ArenaPlatform"
	arena_body.position = Vector3(0, -RollConfig.ARENA_HEIGHT * 0.5, 0)
	
	var arena_phys = PhysicsMaterial.new()
	arena_phys.friction = RollConfig.ARENA_FRICTION
	arena_phys.bounce = 0.3
	arena_body.physics_material_override = arena_phys
	
	var col = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = RollConfig.ARENA_RADIUS
	cyl_shape.height = RollConfig.ARENA_HEIGHT
	col.shape = cyl_shape
	arena_body.add_child(col)
	
	var mesh_inst = MeshInstance3D.new()
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = RollConfig.ARENA_RADIUS
	cyl_mesh.bottom_radius = RollConfig.ARENA_RADIUS
	cyl_mesh.height = RollConfig.ARENA_HEIGHT
	mesh_inst.mesh = cyl_mesh
	
	var arena_mat = StandardMaterial3D.new()
	arena_mat.albedo_color = Color(0.2, 0.45, 0.75) # Cool blue arena
	arena_mat.roughness = 0.5
	mesh_inst.material_override = arena_mat
	arena_body.add_child(mesh_inst)
	add_child(arena_body)
	
	# 3. Vier Mausefallen
	var trap_angles = [0.0, PI * 0.5, PI, PI * 1.5]
	for i in range(trap_angles.size()):
		var angle = trap_angles[i]
		var trap = MousetrapHazard.new()
		trap.name = "Mousetrap_%d" % i
		var dist = RollConfig.ARENA_RADIUS * 0.65
		trap.position = Vector3(cos(angle) * dist, 0.075, sin(angle) * dist)
		trap.rotation.y = -angle
		add_child(trap)
	
	# 4. Spieler 1 (Rot) & Spieler 2 (Blau)
	player1 = PlayerBall.new()
	player1.name = "Player1_Red"
	player1.player_id = 1
	player1.is_bot = false
	player1.ball_color = Color(0.95, 0.2, 0.2)
	player1.position = Vector3(-4.5, RollConfig.BALL_RADIUS + 0.1, 0.0)
	player1.fell_off.connect(_on_player_fell_off)
	add_child(player1)
	
	player2 = PlayerBall.new()
	player2.name = "Player2_Blue"
	player2.player_id = 2
	player2.is_bot = true # Default: AI Bot für nahtlosen Single-Player Modus!
	player2.ball_color = Color(0.15, 0.5, 0.95)
	player2.position = Vector3(4.5, RollConfig.BALL_RADIUS + 0.1, 0.0)
	player2.fell_off.connect(_on_player_fell_off)
	add_child(player2)
	
	player1.target_opponent = player2
	player2.target_opponent = player1
	
	# 5. Shared Camera (Dynamische Nahansicht)
	camera = SharedArenaCamera.new()
	camera.name = "SharedCamera"
	camera.position = Vector3(0, RollConfig.CAMERA_BASE_HEIGHT, RollConfig.CAMERA_MIN_DISTANCE)
	camera.target_nodes = [player1, player2]
	camera.current = true
	add_child(camera)

func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "HUD"
	
	var ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui_root)
	
	# Timer
	ui_timer_label = Label.new()
	ui_timer_label.text = "60.0"
	ui_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_timer_label.position = Vector2(540, 20)
	ui_timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ui_timer_label.size = Vector2(200, 50)
	ui_timer_label.add_theme_font_size_override("font_size", 36)
	ui_root.add_child(ui_timer_label)
	
	# P1 Score (Left)
	ui_p1_label = Label.new()
	ui_p1_label.text = "P1 (Red): 0"
	ui_p1_label.position = Vector2(40, 20)
	ui_p1_label.add_theme_font_size_override("font_size", 28)
	ui_p1_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	ui_root.add_child(ui_p1_label)
	
	# P2 Score (Right)
	ui_p2_label = Label.new()
	ui_p2_label.position = Vector2(980, 20)
	ui_p2_label.add_theme_font_size_override("font_size", 28)
	ui_p2_label.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0))
	ui_root.add_child(ui_p2_label)
	_update_p2_label()
	
	# Bottom Hint (Singleplayer / Multiplayer & Controls)
	var ui_hint = Label.new()
	ui_hint.text = "[B] oder [Tab]: P2 AI-Bot ein/aus  |  [R]: Neustart  |  P1: WASD+Space"
	ui_hint.position = Vector2(40, 670)
	ui_hint.add_theme_font_size_override("font_size", 16)
	ui_hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.8))
	ui_root.add_child(ui_hint)
	
	# Status / Winner Banner
	ui_status_label = Label.new()
	ui_status_label.text = "READY..."
	ui_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_status_label.position = Vector2(440, 320)
	ui_status_label.size = Vector2(400, 80)
	ui_status_label.add_theme_font_size_override("font_size", 42)
	ui_root.add_child(ui_status_label)
	
	add_child(canvas)

func _process(delta: float) -> void:
	if state_manager:
		state_manager.update_logic(delta)
	
	if Input.is_action_just_pressed("restart"):
		restart_game()

func restart_game() -> void:
	player1.respawn(Vector3(-4.5, RollConfig.BALL_RADIUS + 0.1, 0.0))
	player2.respawn(Vector3(4.5, RollConfig.BALL_RADIUS + 0.1, 0.0))
	state_manager.reset_match()

func _on_player_fell_off(victim_id: int, kicker_id: int) -> void:
	state_manager.record_player_fall(victim_id, kicker_id)

func _on_state_changed(new_state: RollStateManager.MatchState) -> void:
	if not ui_status_label:
		return
	match new_state:
		RollStateManager.MatchState.WARMUP:
			ui_status_label.visible = true
			ui_status_label.text = "READY... GO!"
		RollStateManager.MatchState.PLAYING:
			ui_status_label.visible = false
		RollStateManager.MatchState.SUDDEN_DEATH:
			ui_status_label.visible = true
			ui_status_label.text = "🔥 SUDDEN DEATH! 🔥"
		RollStateManager.MatchState.MATCH_OVER:
			ui_status_label.visible = true
			var w = state_manager.get_winner()
			if w == 1:
				ui_status_label.text = "🏆 PLAYER 1 (RED) WINS! 🏆"
			elif w == 2:
				ui_status_label.text = "🏆 PLAYER 2 (BLUE) WINS! 🏆"
			else:
				ui_status_label.text = "DRAW! Press R to rematch"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B or event.keycode == KEY_TAB:
			toggle_p2_bot()

func toggle_p2_bot() -> void:
	if player2:
		player2.is_bot = not player2.is_bot
		_update_p2_label()

func _update_p2_label() -> void:
	if ui_p2_label:
		var mode_str = "AI Bot" if (player2 and player2.is_bot) else "Human"
		var score = state_manager.scores[2] if state_manager else 0
		ui_p2_label.text = "P2 (Blue - %s): %d" % [mode_str, score]

func _on_score_updated(player_id: int, new_score: int) -> void:
	if player_id == 1 and ui_p1_label:
		ui_p1_label.text = "P1 (Red): %d" % new_score
	elif player_id == 2:
		_update_p2_label()

func _on_timer_updated(time_remaining: float) -> void:
	if ui_timer_label:
		ui_timer_label.text = "%.1f" % time_remaining

func _on_match_finished(_winner_id: int) -> void:
	pass

