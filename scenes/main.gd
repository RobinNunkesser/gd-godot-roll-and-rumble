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
var player3: PlayerBall
var player4: PlayerBall
var players: Array[PlayerBall] = []
var camera: SharedArenaCamera

var ui_lobby_panel: Control
var ui_slot_labels: Array[Label] = []
var ui_timer_label: Label
var ui_score_labels: Dictionary = {}
var ui_status_label: Label
var ui_hud_container: Control

const SLOT_CONTROL_OPTIONS = [
	PlayerBall.ControlType.HUMAN_KB1,
	PlayerBall.ControlType.HUMAN_KB2,
	PlayerBall.ControlType.GAMEPAD_0,
	PlayerBall.ControlType.GAMEPAD_1,
	PlayerBall.ControlType.GAMEPAD_2,
	PlayerBall.ControlType.GAMEPAD_3,
	PlayerBall.ControlType.AI_BOT,
	PlayerBall.ControlType.OFF
]

func _ready() -> void:
	state_manager = RollStateManager.new()
	state_manager.state_changed.connect(_on_state_changed)
	state_manager.score_updated.connect(_on_score_updated)
	state_manager.timer_updated.connect(_on_timer_updated)
	state_manager.match_finished.connect(_on_match_finished)
	
	_build_scene()
	_build_ui()
	
	state_manager.enter_lobby(_get_active_player_ids())

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
	arena_mat.albedo_color = Color(0.2, 0.45, 0.75)
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
	
	# 4. 4 Spieler-Kugeln
	var p_configs = [
		{"id": 1, "name": "Player1_Red", "color": Color(0.95, 0.25, 0.25), "pos": Vector3(-5.0, RollConfig.BALL_RADIUS + 0.1, 0.0), "ctrl": PlayerBall.ControlType.HUMAN_KB1},
		{"id": 2, "name": "Player2_Blue", "color": Color(0.2, 0.55, 0.95), "pos": Vector3(5.0, RollConfig.BALL_RADIUS + 0.1, 0.0), "ctrl": PlayerBall.ControlType.AI_BOT},
		{"id": 3, "name": "Player3_Yellow", "color": Color(0.95, 0.85, 0.15), "pos": Vector3(0.0, RollConfig.BALL_RADIUS + 0.1, -5.0), "ctrl": PlayerBall.ControlType.OFF},
		{"id": 4, "name": "Player4_Green", "color": Color(0.25, 0.85, 0.35), "pos": Vector3(0.0, RollConfig.BALL_RADIUS + 0.1, 5.0), "ctrl": PlayerBall.ControlType.OFF}
	]
	
	players.clear()
	for cfg in p_configs:
		var p = PlayerBall.new()
		p.name = cfg["name"]
		p.player_id = cfg["id"]
		p.ball_color = cfg["color"]
		p.position = cfg["pos"]
		p.set_control_type(cfg["ctrl"])
		p.fell_off.connect(_on_player_fell_off)
		add_child(p)
		players.append(p)
	
	player1 = players[0]
	player2 = players[1]
	player3 = players[2]
	player4 = players[3]
	
	for p in players:
		p.potential_targets = players
	player1.target_opponent = player2
	player2.target_opponent = player1
	
	# 5. Shared Camera
	camera = SharedArenaCamera.new()
	camera.name = "SharedCamera"
	camera.position = Vector3(0, RollConfig.CAMERA_BASE_HEIGHT, RollConfig.CAMERA_MIN_DISTANCE)
	camera.target_nodes = players
	camera.current = true
	add_child(camera)

func _build_ui() -> void:
	var canvas = CanvasLayer.new()
	canvas.name = "UI"
	
	# --- In-Game HUD ---
	ui_hud_container = Control.new()
	ui_hud_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui_hud_container)
	
	# Timer
	ui_timer_label = Label.new()
	ui_timer_label.text = "60.0"
	ui_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_timer_label.position = Vector2(540, 20)
	ui_timer_label.size = Vector2(200, 50)
	ui_timer_label.add_theme_font_size_override("font_size", 36)
	ui_hud_container.add_child(ui_timer_label)
	
	# Player Scores (P1 Red, P2 Blue, P3 Yellow, P4 Green)
	var score_positions = [
		Vector2(40, 20), Vector2(980, 20),
		Vector2(40, 60), Vector2(980, 60)
	]
	var p_names = ["P1 (Red)", "P2 (Blue)", "P3 (Yellow)", "P4 (Green)"]
	var p_colors = [Color(1.0, 0.3, 0.3), Color(0.3, 0.6, 1.0), Color(0.95, 0.85, 0.2), Color(0.3, 0.9, 0.4)]
	
	ui_score_labels.clear()
	for i in range(4):
		var lbl = Label.new()
		lbl.text = "%s: 0" % p_names[i]
		lbl.position = score_positions[i]
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", p_colors[i])
		ui_hud_container.add_child(lbl)
		ui_score_labels[i + 1] = lbl
	
	# Status / Countdown Banner
	ui_status_label = Label.new()
	ui_status_label.text = "READY..."
	ui_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui_status_label.position = Vector2(340, 280)
	ui_status_label.size = Vector2(600, 100)
	ui_status_label.add_theme_font_size_override("font_size", 48)
	ui_hud_container.add_child(ui_status_label)
	
	var in_game_hint = Label.new()
	in_game_hint.text = "[R]: Neustart  |  [ESC]: Zurück zur Lobby  |  [B]: P2 Bot Toggle"
	in_game_hint.position = Vector2(40, 670)
	in_game_hint.add_theme_font_size_override("font_size", 16)
	in_game_hint.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 0.75))
	ui_hud_container.add_child(in_game_hint)
	
	# --- Pre-Match Lobby Panel ---
	ui_lobby_panel = Control.new()
	ui_lobby_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var bg_overlay = ColorRect.new()
	bg_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_overlay.color = Color(0.05, 0.08, 0.14, 0.88)
	ui_lobby_panel.add_child(bg_overlay)
	
	var title = Label.new()
	title.text = "ROLL & RUMBLE 3D — LOBBY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(240, 40)
	title.size = Vector2(800, 60)
	title.add_theme_font_size_override("font_size", 40)
	ui_lobby_panel.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Wähle Steuerung pro Slot ([1]-[4] drücken) & starte mit [SPACE / ENTER]"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(240, 100)
	subtitle.size = Vector2(800, 30)
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	ui_lobby_panel.add_child(subtitle)
	
	ui_slot_labels.clear()
	var col_width = 260
	var start_x = 80
	for i in range(4):
		var card = Panel.new()
		card.position = Vector2(start_x + i * (col_width + 20), 160)
		card.size = Vector2(col_width, 360)
		ui_lobby_panel.add_child(card)
		
		var p_title = Label.new()
		p_title.text = p_names[i]
		p_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p_title.position = Vector2(10, 15)
		p_title.size = Vector2(col_width - 20, 35)
		p_title.add_theme_font_size_override("font_size", 24)
		p_title.add_theme_color_override("font_color", p_colors[i])
		card.add_child(p_title)
		
		var slot_lbl = Label.new()
		slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_lbl.position = Vector2(10, 80)
		slot_lbl.size = Vector2(col_width - 20, 140)
		slot_lbl.add_theme_font_size_override("font_size", 22)
		slot_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
		card.add_child(slot_lbl)
		ui_slot_labels.append(slot_lbl)
		
		var key_hint = Label.new()
		key_hint.text = "Taste [%d] drücken\nzum Wechseln" % (i + 1)
		key_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_hint.position = Vector2(10, 260)
		key_hint.size = Vector2(col_width - 20, 60)
		key_hint.add_theme_font_size_override("font_size", 16)
		key_hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		card.add_child(key_hint)
	
	_update_lobby_ui()
	canvas.add_child(ui_lobby_panel)
	add_child(canvas)

func _update_lobby_ui() -> void:
	for i in range(players.size()):
		var p = players[i]
		var txt = _get_control_type_name(p.control_type)
		ui_slot_labels[i].text = txt
		
		# Score Label Sichtbarkeit
		if ui_score_labels.has(p.player_id):
			ui_score_labels[p.player_id].visible = (p.control_type != PlayerBall.ControlType.OFF)

func _get_control_type_name(ct: PlayerBall.ControlType) -> String:
	match ct:
		PlayerBall.ControlType.OFF:
			return "[ INAKTIV ]\n(OFF)"
		PlayerBall.ControlType.HUMAN_KB1:
			return "SPIELER\n(Tastatur 1: WASD + Space)"
		PlayerBall.ControlType.HUMAN_KB2:
			return "SPIELER\n(Tastatur 2: Pfeile + Enter)"
		PlayerBall.ControlType.GAMEPAD_0:
			return "SPIELER\n(Gamepad 1: Stick + A)"
		PlayerBall.ControlType.GAMEPAD_1:
			return "SPIELER\n(Gamepad 2: Stick + A)"
		PlayerBall.ControlType.GAMEPAD_2:
			return "SPIELER\n(Gamepad 3: Stick + A)"
		PlayerBall.ControlType.GAMEPAD_3:
			return "SPIELER\n(Gamepad 4: Stick + A)"
		PlayerBall.ControlType.AI_BOT:
			return "KI-BOT\n(Autonomes Steering)"
	return "UNKNOWN"

func cycle_player_slot(index: int) -> void:
	if index < 0 or index >= players.size():
		return
	var p = players[index]
	var cur_idx = SLOT_CONTROL_OPTIONS.find(p.control_type)
	var next_idx = (cur_idx + 1) % SLOT_CONTROL_OPTIONS.size()
	p.set_control_type(SLOT_CONTROL_OPTIONS[next_idx])
	_update_lobby_ui()

func toggle_p2_bot() -> void:
	if player2:
		if player2.control_type == PlayerBall.ControlType.AI_BOT:
			player2.set_control_type(PlayerBall.ControlType.HUMAN_KB2)
		else:
			player2.set_control_type(PlayerBall.ControlType.AI_BOT)
		_update_lobby_ui()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if state_manager.current_state == RollStateManager.MatchState.LOBBY:
			if event.keycode == KEY_1:
				cycle_player_slot(0)
			elif event.keycode == KEY_2:
				cycle_player_slot(1)
			elif event.keycode == KEY_3:
				cycle_player_slot(2)
			elif event.keycode == KEY_4:
				cycle_player_slot(3)
			elif event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				start_match_from_lobby()
		else:
			if event.keycode == KEY_ESCAPE:
				return_to_lobby()
			elif event.keycode == KEY_B:
				toggle_p2_bot()

func start_match_from_lobby() -> void:
	var active_ids = _get_active_player_ids()
	if active_ids.size() < 2:
		ui_status_label.text = "Mindestens 2 Spieler erforderlich!"
		return
	
	ui_lobby_panel.visible = false
	ui_hud_container.visible = true
	
	# Respawnen und physikalisch einfrieren für Warmup Countdown
	for p in players:
		if p.control_type != PlayerBall.ControlType.OFF:
			p.respawn(p.initial_spawn_point)
			p.freeze = true
	
	state_manager.start_match(active_ids)

func return_to_lobby() -> void:
	for p in players:
		p.freeze = true
	state_manager.enter_lobby(_get_active_player_ids())
	ui_lobby_panel.visible = true
	_update_lobby_ui()

func restart_game() -> void:
	for p in players:
		if p.control_type != PlayerBall.ControlType.OFF:
			p.respawn(p.initial_spawn_point)
			p.freeze = true
	state_manager.reset_match()

func _get_active_player_ids() -> Array:
	var ids: Array = []
	for p in players:
		if p.control_type != PlayerBall.ControlType.OFF:
			ids.append(p.player_id)
	return ids

func _process(delta: float) -> void:
	if state_manager:
		state_manager.update_logic(delta)
	
	if state_manager.current_state == RollStateManager.MatchState.WARMUP:
		var sec = int(ceil(state_manager.warmup_timer))
		if sec > 0:
			ui_status_label.text = str(sec)
		else:
			ui_status_label.text = "RUMBLE!"
	
	if Input.is_action_just_pressed("restart") and state_manager.current_state != RollStateManager.MatchState.LOBBY:
		restart_game()

func _on_player_fell_off(victim_id: int, kicker_id: int) -> void:
	state_manager.record_player_fall(victim_id, kicker_id)

func _on_state_changed(new_state: RollStateManager.MatchState) -> void:
	if not ui_status_label:
		return
	match new_state:
		RollStateManager.MatchState.LOBBY:
			ui_status_label.visible = false
			for p in players:
				p.freeze = true
		RollStateManager.MatchState.WARMUP:
			ui_status_label.visible = true
			ui_status_label.text = "3"
			for p in players:
				if p.control_type != PlayerBall.ControlType.OFF:
					p.freeze = true
		RollStateManager.MatchState.PLAYING:
			ui_status_label.visible = false
			# Unfreeze all active players!
			for p in players:
				if p.control_type != PlayerBall.ControlType.OFF:
					p.freeze = false
		RollStateManager.MatchState.SUDDEN_DEATH:
			ui_status_label.visible = true
			ui_status_label.text = "🔥 SUDDEN DEATH! 🔥"
		RollStateManager.MatchState.MATCH_OVER:
			ui_status_label.visible = true
			var w = state_manager.get_winner()
			if w > 0:
				ui_status_label.text = "🏆 PLAYER %d WINS! 🏆" % w
			else:
				ui_status_label.text = "DRAW! Press [R] to rematch"

func _on_score_updated(player_id: int, new_score: int) -> void:
	if ui_score_labels.has(player_id):
		var p_name = "P%d" % player_id
		if player_id <= players.size():
			var p = players[player_id - 1]
			var mode_tag = "AI" if p.is_bot else "Human"
			ui_score_labels[player_id].text = "%s (%s): %d" % [p_name, mode_tag, new_score]
		else:
			ui_score_labels[player_id].text = "%s: %d" % [p_name, new_score]

func _on_timer_updated(time_remaining: float) -> void:
	if ui_timer_label:
		ui_timer_label.text = "%.1f" % time_remaining

func _on_match_finished(_winner_id: int) -> void:
	pass


